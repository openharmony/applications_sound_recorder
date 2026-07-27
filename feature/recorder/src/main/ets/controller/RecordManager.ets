/*
 * Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import media from '@ohos.multimedia.media';
import fs from '@ohos.file.fs';
import { AsyncCallback, BusinessError, Callback } from '@ohos.base';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { ArrayList, JSON } from '@kit.ArkTS';
import SampleUtil from '@ohos/common/src/main/ets/utils/SampleUtil';
import { DATA_TIME_INTERVAL, LINES_PRE_SECOND } from '../components/WaveView';
import { CommonConstants, ContinuousTask, GlobalContext } from '@ohos/common';
import commonEventManager from '@ohos.commonEventManager';
import { statfs } from '@kit.CoreFileKit';
import { BaseViewModel } from '../viewModel/BaseViewModel';
import { audio } from '@kit.AudioKit';
import RecordStateManager from '../audiokit/manager/RecordStateManager';
import { GlobalRecordState } from '../audiokit/constant/AudioConstant';
import AudioSDKManager from '../audiokit/manager/AudioSDKManager';

const TAG = 'SoundRecorder_RecordManager';

let shutdownSubscriber: commonEventManager.CommonEventSubscriber | undefined;
let languageChangeSubscriber: commonEventManager.CommonEventSubscriber | undefined;

interface ICommonEventData {
  faultDescription: string;
  faultSuggestion: string;
  publisherBundleName: string;
}

export class RecordManager {
  public avRecorder?: media.AVRecorder;
  private avRecorderState: string = '';
  private recorderStateCallbackMap: Map<string, Callback<string>> = new Map();
  private onErrorCallbackMap: Map<string, Callback<BusinessError>> = new Map();
  private config?: media.AVRecorderConfig;
  private openedFileFd?: number;
  private avRecorderResetFlag: boolean = false;
  private currentFilePath?: string;
  private recorderDuration: number = 0;
  private callState: number = -1;
  private isPausedByCall: boolean = false;
  // 振幅缓存
  private amplitudeBuffer: ArrayList<number> = new ArrayList();
  // 振幅缓存用于计算插值
  private amplitudeInterBuffer: ArrayList<number> = new ArrayList();
  // 采样后的振幅数据
  private realTimeSamples: ArrayList<number> = new ArrayList();
  // 实时的波形图数据
  private realTimeWaves: ArrayList<number> = new ArrayList();
  // 下次采样的时间
  private nextSampleTime: number = 0;
  private sampleTimerId: number = 0;
  // 波形图采样的时间间隔
  private sampleInterval: number = 1000 / LINES_PRE_SECOND;
  private timeDelay: number = CommonConstants.RECORDER_PREPARED_TO_STARTED_DELAY;
  private recordTime: number = 0;
  private recordStartTime: number = 0;
  private subscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [commonEventManager.Support.COMMON_EVENT_SHUTDOWN]
  };
  private languageSubscribeInfo: commonEventManager.CommonEventSubscribeInfo = {
    events: [commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED]
  };
  public audioCapture?: audio.AudioCapturer;
  private audioCaptureState: audio.AudioState = audio.AudioState.STATE_INVALID;
  // 关机广播回调
  /* instrument ignore next */
  private shutdownCallBack: AsyncCallback<commonEventManager.CommonEventData> =
    async (err: BusinessError, data: commonEventManager.CommonEventData) => {
      if (err) {
        LogUtil.info(TAG + `shutDownCallback error:` + JSON.stringify(err));
      } else {
        let context = GlobalContext.getUIAbilityContext();
        context.eventHub.emit('isShutdown', true);
        LogUtil.info(TAG + 'shutDownCallback current state is: ' + this.avRecorderState);
        if (this.avRecorderState === CommonConstants.STARTED || this.avRecorderState === CommonConstants.PAUSED) {
          if (this.avRecorder) {
            LogUtil.info(TAG + 'release recorder, current state is: ' + this.avRecorderState);
            try {
              await this.avRecorder.release();
            } catch (e) {
              LogUtil.error(TAG + ' shutDownCallback release recorder error: ' + e);
            }
          }
        }
      }
    }
  // 创建广播订阅者
  private createSubscribeCB = (err: BusinessError, commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    // instrument ignore else
    if (!err) {
      shutdownSubscriber = commonEventSubscriber;
    }
    try {
      commonEventManager.subscribe(shutdownSubscriber, (args1, args2) => {
        this.shutdownCallBack(args1, args2)
      });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(`subscribe failed, code is ${err.code}, message is ${err.message}`);
    }
    LogUtil.info(`createSubscribeCB success`);
  }
  // 创建语言变更广播订阅者
  private languageSubscribeCB = (err: BusinessError,
    commonEventSubscriber: commonEventManager.CommonEventSubscriber) => {
    // instrument ignore else
    if (!err) {
      languageChangeSubscriber = commonEventSubscriber;
    }
    try {
      commonEventManager.subscribe(languageChangeSubscriber,
        (err: BusinessError, data: commonEventManager.CommonEventData) => {
          this.languageChangeCallBack(err, data)
        });
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(TAG + ` Language change subscription failed, code is ${err.code}, message is ${err.message}`);
    }
    LogUtil.info(TAG + ` Language change subscription successful`);
  }
  // 系统语言变更公共事件订阅回调
  /* instrument ignore next */
  private languageChangeCallBack: AsyncCallback<commonEventManager.CommonEventData> =
    async (err: BusinessError, data: commonEventManager.CommonEventData) => {
      if (err) {
        LogUtil.error(TAG + ' Public event callback failed, failure information: ' + JSON.stringify(err));
        return;
      }

      if (data.event !== commonEventManager.Support.COMMON_EVENT_LOCALE_CHANGED) {
        LogUtil.info(TAG + ' Non-system language subscription changes, no action taken.');
        return;
      }

      LogUtil.info(TAG + ' System language change callback successful.');
    }
  // 音频振幅Callback
  private amplitudeCallback: AsyncCallback<number> = (_, data) => {
    // instrument ignore if
    if (this.amplitudeInterBuffer.length < 2) {
      LogUtil.info(TAG + ` amplitudeInterBuffer length invalid, return.`);
      return;
    }
    // instrument ignore else
    if (data) {
      this.amplitudeInterBuffer[1] = data;
    }
    // 用平均值进行插值
    let avgData = (this.amplitudeInterBuffer[0] + this.amplitudeInterBuffer[1]) / 2;
    // 移除旧值，只保留最新值
    this.amplitudeInterBuffer = this.amplitudeInterBuffer.subArrayList(1, 2);
    // 使用插值更新数据
    this.addAmplitudeData(avgData);
  }
  private addAmplitudeData = (data: number) => {
    this.amplitudeBuffer.add(data);
    let diffTime: number = this.getRecordTime() - this.nextSampleTime;
    // instrument ignore else
    if (diffTime > 0) {
      let maxSample: number = this.readMaxFromBuffer();
      this.realTimeSamples.add(maxSample);
      this.realTimeWaves.add(SampleUtil.sampleToWaveLine(maxSample));
      this.nextSampleTime += this.sampleInterval;
    }
  }
  private static instance?: RecordManager;
  private static lock = false;

  /* instrument ignore next */
  private constructor() {
    LogUtil.info(TAG + ` set RecordController singleton, create an instance.`);
  }

  // 公共事件的订阅
  public commonEventSubscribe() {
    LogUtil.info(TAG + ` System Public Event Subscription.`);
    try {
      commonEventManager.createSubscriber(this.subscribeInfo, this.createSubscribeCB);
      commonEventManager.createSubscriber(this.languageSubscribeInfo, this.languageSubscribeCB);
    } catch (error) {
      let err: BusinessError = error as BusinessError;
      LogUtil.error(`createSubscriber failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  // 公共事件的取消订阅
  public commonEventUnSubscribe() {
    LogUtil.info(TAG + ` Unsubscribe from System Public Events.`);
    try {
      commonEventManager.unsubscribe(shutdownSubscriber, (err: BusinessError) => {
        if (err) {
          LogUtil.error(TAG + ` Failed to cancel subscription due to device restart event.
            Code is ${err.code}, message is ${err.message}`);
          return;
        }
        // subscriber不再使用时需要将其置为undefined，避免内存泄露
        shutdownSubscriber = undefined;
        LogUtil.info(TAG + ` The device restart event successfully unsubscribed.`);
      });
      commonEventManager.unsubscribe(languageChangeSubscriber, (err: BusinessError) => {
        if (err) {
          LogUtil.error(TAG + ` Language change event subscription cancellation failed.
            Code is ${err.code}, message is ${err.message}`);
          return;
        }
        // subscriber不再使用时需要将其置为undefined，避免内存泄露
        languageChangeSubscriber = undefined;
        LogUtil.info(TAG + ` Language change event subscription canceled successfully.`);
      });
    } catch (error) {
      LogUtil.error(TAG + ` unsubscriber failed, error info is ${JSON.stringify(error)}`);
    }
  }


  /* instrument ignore next */
  public static getInstance(): RecordManager {
    if (!RecordManager.instance) {
      while (RecordManager.lock) {
      }
      RecordManager.lock = true;
      if (!RecordManager.instance) {
        RecordManager.instance = new RecordManager();
      }
      RecordManager.lock = false;
    }
    return RecordManager.instance;
  }

  public async initAvRecorder(): Promise<void> {
    // instrument ignore else
    if (!this.avRecorder || this.avRecorder.state === 'released') {
      this.avRecorder = await media.createAVRecorder();
    }
    this.setAVRecorderCallback(this.avRecorder);
  }


  /* instrument ignore next */
  async createAudioCapturer(): Promise<void> {
    let audioStreamInfo: audio.AudioStreamInfo = {
      samplingRate: audio.AudioSamplingRate.SAMPLE_RATE_16000, // 采样率。
      channels: audio.AudioChannel.CHANNEL_1, // 通道。
      sampleFormat: audio.AudioSampleFormat.SAMPLE_FORMAT_S16LE, // 采样格式。
      encodingType: audio.AudioEncodingType.ENCODING_TYPE_RAW // 编码格式。
    };

    let audioCapturerInfo: audio.AudioCapturerInfo = {
      source: audio.SourceType.SOURCE_TYPE_MIC, // 音源类型：Mic音频源。根据业务场景配置，参考SourceType。
      capturerFlags: 0 // 音频采集器标志。
    };
    let audioCapturerOptions: audio.AudioCapturerOptions = {
      streamInfo: audioStreamInfo,
      capturerInfo: audioCapturerInfo
    };

    try {
      this.audioCapture = await audio.createAudioCapturer(audioCapturerOptions);
    } catch (error) {
      LogUtil.error(TAG + `create capture fail:
        ${(error as BusinessError).code}, ${(error as BusinessError).message}`)
    }
  }


  private notifyRecorderStateChanged(): void {
    this.recorderStateCallbackMap.forEach((value, key) => {
      LogUtil.info(TAG + ' playState change callback for ' + key);
      let callback: Callback<string> = value;
      // instrument ignore else
      if (callback) {
        callback(this.avRecorderState);
      }
    });
  }

  /**
   * 添加回调监听
   *
   * @param key
   * @param callback
   */
  public addRecorderStateListeners(key: string, callback: Callback<string>): void {
    this.recorderStateCallbackMap.set(key, callback);
  }

  /**
   * 添加失败回调监听
   *
   * @param key
   * @param callback
   */
  /* instrument ignore next */
  public addErrorCallbackListeners(key: string, callback: Callback<BusinessError>): void {
    this.onErrorCallbackMap.set(key, callback);
  }

  /**
   * 移除回调监听
   *
   * @param key
   */
  /* instrument ignore next */
  public removeRecorderStateListeners(key: string): void {
    this.recorderStateCallbackMap.delete(key);
  }

  /* instrument ignore next */
  private getFreeSize(): void {
    let context = GlobalContext.getUIAbilityContext();
    let path = context.filesDir;
    let freeSizeThreshold = 1024 * 1024 * 500;
    statfs.getFreeSize(path, (err: BusinessError, number: number) => {
      if (err) {
        LogUtil.error(`${TAG} getFreeSize failed, code is ${err.code}, message is ${err.message}`);
      } else {
        if (number < freeSizeThreshold) {
          LogUtil.error(`${TAG} FreeSize is insufficient, size: ${number}`);
          // 拉起弹框
          this.pullUpIntelligentDetectionDialog();
        }
      }
    });
  }

  /* instrument ignore next */
  private pullUpIntelligentDetectionDialog() {
    let data: ICommonEventData = {
      faultDescription: '845010023',
      faultSuggestion: '545010023',
      publisherBundleName: 'com.ohos.soundrecorder' // 发送者自己的包名
    };
    let options: commonEventManager.CommonEventPublishData = {
      bundleName: 'com.hmos.hiviewcare',
      data: JSON.stringify(data)
    };

    commonEventManager.publish('hicare.event.SMART_NOTIFICATION', options, (err: BusinessError) => {
      if (err) {
        LogUtil.error(`${TAG} pullUpIntelligentDetectionDialog publish failed, err.code: ${err.code},
        err.message: ${err.message}`);
      } else {
        LogUtil.error(`${TAG} pullUpIntelligentDetectionDialog pushlish success`);
      }
    });
  }

  /**
   * 录音报错时，尝试保存录音文件
   *
   * @returns
   */
  /* instrument ignore next */
  private async trySaveRecordFile(recordTime: number): Promise<void> {
    LogUtil.info(TAG + ' trySaveRecordFile start. recordTime=' + recordTime);
    let tempDuration = recordTime;
    if (tempDuration < 0) {
      if (this.openedFileFd) {
        // 获取准确的音频时间，UI用的倒计时计算的时间有误差
        let extractor = await media.createAVMetadataExtractor();
        extractor.fdSrc = { fd: this.openedFileFd };
        let metaData = await extractor.fetchMetadata();
        if (metaData.duration) {
          tempDuration = Number(metaData.duration);
          LogUtil.info(TAG + ' trySaveRecordFile fix real recordTime to : ' + tempDuration);
        }
      }
    }
    if (tempDuration > 0) {
      this.getFreeSize();
      // 保存文件
      await this.saveAudioFile();
      // 分发状态，并停止振幅倒计时
      this.notifyRecorderStateChanged();
      this.stopAmplitudeTimer();
      // 检查RELEASE状态
      if (this.avRecorderState !== CommonConstants.RELEASED) {
        LogUtil.info(TAG + ' trySaveRecordFile resend release.');
        this.avRecorderState = CommonConstants.RELEASED;
        this.notifyRecorderStateChanged();
      }
      LogUtil.info(TAG + ' trySaveRecordFile success.');
    } else {
      // 删除无效录音文件，防止重启录音机时再次被导入
      if (this.currentFilePath) {
        try {
          fs.unlinkSync(this.currentFilePath);
        } catch (e) {
          LogUtil.warn(TAG + ': trySaveRecordFile delete. ' + JSON.stringify(e));
        }
        LogUtil.info(TAG + ': trySaveRecordFile delete. Delete invalid recordings succeeded.');
      }
      // 分发状态，并停止振幅倒计时
      this.notifyRecorderStateChanged();
      this.stopAmplitudeTimer();
    }
    LogUtil.info(TAG + ' trySaveRecordFile end.');
  }

  /* instrument ignore next */
  private setAVRecorderCallback(avRecorder: media.AVRecorder): void {
    let context = GlobalContext.getUIAbilityContext();
    if (!avRecorder) {
      LogUtil.error(TAG + ` setAVRecorderCallback error, avRecorder is null`);
      return;
    }
    avRecorder.on('error', async (err: BusinessError) => {
      LogUtil.error(TAG + ` Invoke avRecorder failed, code is ${err.code}, message is ${err.message}`);
      this.onErrorCallbackMap.forEach((value, key) => {
        LogUtil.info(TAG + ' onErrorCallback for ' + key);
        let callback: Callback<BusinessError> = value;
        if (callback) {
          callback(err);
        }
      });
    });
    // 'idle' | 'prepared' | 'started' | 'paused' | 'stopped' | 'released' | 'error';
    avRecorder.on('stateChange', async (state: string, reason: media.StateChangeReason) => {
      LogUtil.info(TAG + ' avRecorder state changed to ' + state + ' reason: ' + reason);
      this.avRecorderState = state;
      this.calculateRecordTime(state);
      switch (state) {
        case 'idle':
          if (this.avRecorderResetFlag) {
            LogUtil.info(TAG + ' avRecorder state is idle, avRecorderResetFlag ' + this.avRecorderResetFlag);
            this.avRecorderResetFlag = false;
            avRecorder.prepare(this.config);
          }
          break;
        case 'prepared':
          this.notifyRecorderStateChanged();
          break;
        case 'started':
          this.isPausedByCall = false;
          this.startAmplitudeTimer();
          this.notifyRecorderStateChanged();
          ContinuousTask.startRecordTask(context);
          break;
        case 'paused':
          this.notifyRecorderStateChanged();
          ContinuousTask.stopContinuousTask(context, state);
          break;
        case 'stopped':
          break;
        case 'released':
          ContinuousTask.startRecordTask(context);
          await this.trySaveRecordFile(this.recorderDuration);
          ContinuousTask.stopContinuousTask(context, state);
          avRecorder.off('stateChange');
          avRecorder.off('error');
          break;
        case 'error':
          await avRecorder.reset();
          await this.trySaveRecordFile(this.recorderDuration);
          ContinuousTask.stopContinuousTask(context, state);
          avRecorder.off('stateChange');
          avRecorder.off('error');
          break;
        default:
          LogUtil.info(TAG + ' avRecorder state unknown. ');
          break;
      }
    })
  }


  /**
   * 设置定时器
   *
   * @param callback 回调处理
   * @param delay 延时时间
   * @param 定时器Id
   */
  public static delayExecute(callback: () => void, delay: number): number {
    let timeoutId: number = setTimeout(() => {
      callback();
      clearTimeout(timeoutId);
    }, delay);
    return timeoutId;
  }


  // 当前是否正在录音态
  public static isRecordingStatus(curRecordStatus: number) {
    return curRecordStatus === audio.AudioState.STATE_RUNNING;
  }

  // 获取当前是否录音状态
  public get getCurRecordStatus() {
    return this.audioCaptureState;
  }

  // 暂停audioCapture录音
  public stopAudioCapture() {
    this.audioCapture?.stop().then(() => {
      LogUtil.info(TAG + ' audioCapture stop success');
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + `stop capture error: ${err?.code}, msg: ${err?.message}`);
    })
  }

  // 开始or继续audioCapture录音
  public startAudioCapture() {
    this.audioCapture?.start().then(() => {
      LogUtil.info(TAG + ' audioCapture start success');
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + `start capture error: ${err?.code}, msg: ${err?.message}`);
    })
  }

  /**
   * 统计录音时间
   *
   * @param state
   */
  public calculateRecordTime(state: string): void {
    if (state === CommonConstants.PREPARED || state === CommonConstants.RELEASED || state === CommonConstants.ERROR) {
      this.recorderDuration = this.getRecordTime();
      LogUtil.info(TAG + ': calculateRecordTime. recordTime = ' + this.recorderDuration);
      this.recordTime = 0;
      this.recordStartTime = 0;
      this.timeDelay = CommonConstants.RECORDER_PREPARED_TO_STARTED_DELAY;
      return;
    }
    if (state === CommonConstants.STARTED) {
      setTimeout(() => this.recordStartTime = Date.now(), this.timeDelay);
    } else if (this.recordStartTime !== 0) {
      this.recordTime += Date.now() - this.recordStartTime;
      this.recordStartTime = 0;
      this.timeDelay = CommonConstants.RECORDER_PAUSE_TO_STARTED_DELAY;
    }
  }

  /**
   * 获取当前的录音时间
   * AvRecorder没有提供实时录音时间的接口，
   * 这个时间是上层自己统计的，不一定准确，有小误差，
   * 但比单纯的用定时器累加计算的误差小得多。
   *
   * @returns
   */
  public getRecordTime(): number {
    let time: number =
      (this.recordStartTime === 0) ? this.recordTime : (Date.now() - this.recordStartTime + this.recordTime);
    return time;
  }

  /* instrument ignore next */
  public setRecordTime(time: number): void {
    this.recordTime = time;
  }

  /* instrument ignore next */
  public addRecordTime(time: number): void {
    this.recordTime += time;
  }

  /**
   * 保存录音文件（录音 + 波形图数据 -> File）
   */
  /* instrument ignore next */
  public async saveAudioFile() {
    try {
      if (this.openedFileFd) {
        // 获取准确的音频时间，UI用的倒计时计算的时间有误差
        let extractor = await media.createAVMetadataExtractor();
        extractor.fdSrc = { fd: this.openedFileFd };
        let metaData = await extractor.fetchMetadata();
        if (metaData.duration) {
          this.recorderDuration = Number(metaData.duration);
        }
        LogUtil.info(`${TAG} saveAudioFile recorderDuration is : ${this.recorderDuration}`);
        let tmpFd = this.openedFileFd;
        if (tmpFd !== -1) {
          this.openedFileFd = -1;
          await fs.close(tmpFd);
        }
        await this.trySaveSamples();
        this.currentFilePath = undefined;
      } else {
        LogUtil.info(TAG + ' release avRecorder file fd null.');
      }
      this.avRecorder = undefined;
      this.audioCapture = undefined;
    } catch (e) {
      LogUtil.error(TAG + ' saveAudioFile: ' + e);
    }
  }

  /**
   * 获取录音的时长，该时长从生成的录音文件获取，避免误差
   *
   * @returns 录音时长
   */
  public getRecorderDuration(): number {
    return this.recorderDuration;
  }

  /* instrument ignore next */
  public setRecorderDuration(duration: number): void {
    this.recorderDuration = duration;
  }

  /**
   * 保存采样数据到录音文件中
   */
  /* instrument ignore next */
  private async trySaveSamples() {
    LogUtil.info(TAG + ': trySaveSamples start.');
    if (this.currentFilePath) {
      // AVRecorder结束需要销毁资源等，状态切换没有上层UI那么迅速，所以最好再检查下时间和采样数据是否对应，不对应则增加些波形数据
      let samples: number[] = await SampleUtil.fixSamples(this.recorderDuration, this.realTimeSamples.convertToArray());
      SampleUtil.writeWaveSamplesToFile(this.currentFilePath, samples);
      LogUtil.info(TAG + ': trySaveSamples success.');
    }
    this.realTimeSamples.clear();
    LogUtil.info(TAG + ': trySaveSamples end.');
  }

  /* instrument ignore next */
  public async setAvRecorderConfig(tag: string, fileFd: number, filePath: string, config: media.AVRecorderConfig,
    recorderStateCallback: Callback<string>, baseRecorderStateCallback: Callback<string>,
    onErrorCallback?: Callback<BusinessError>) {
    LogUtil.info(TAG + ' setAvRecorderConfig: ' + JSON.stringify(config));
    if (!this.avRecorder) {
      LogUtil.error(TAG + ' setAvRecorderConfig error: avRecorder is null');
      return;
    }
    this.recorderDuration = 0;
    this.currentFilePath = filePath;
    this.config = config;
    this.openedFileFd = fileFd;
    this.recorderStateCallbackMap.set(tag, recorderStateCallback);
    this.recorderStateCallbackMap.set('baseViewModel', baseRecorderStateCallback);
    onErrorCallback ? this.onErrorCallbackMap.set(tag, onErrorCallback) : '';

    LogUtil.info(TAG + ' start to recorder, avRecorder current state ' + this.avRecorder.state);
    if (this.avRecorder.state === 'idle') {
      this.avRecorder.prepare(config);
    } else {
      this.avRecorderResetFlag = true;
      this.avRecorder.reset();
    }
  }

  /* instrument ignore next */
  public async start() {
    try {
      LogUtil.info(TAG + ' start recorder command.');
      if (this.avRecorder) {
        LogUtil.info(TAG + ' start to record, current state is: ' + this.avRecorderState);
        RecordStateManager.changeRecordState(GlobalRecordState.COMMON_RECORDING);
        await this.avRecorder.start();
      }
      this.audioCapture?.start().then(() => {
        LogUtil.info(TAG + ' audioCapture start success');
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG + `start capture error: ${err.code}, msg: ${err.message}`);
      })
    } catch (e) {
      LogUtil.error(TAG + ' start recorder error: ' + e);
    }
  }

  /* instrument ignore next */
  public async pause(): Promise<number> {
    try {
      LogUtil.info(TAG + ' pause recorder command.');
      if (this.avRecorder) {
        LogUtil.info(TAG + ' pause recording, current state is: ' + this.avRecorderState);
        await this.avRecorder.pause();
      }
      this.audioCapture?.stop().then(() => {
        LogUtil.info(TAG + ' audioCapture stop success');
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG + `stop capture error: ${err.code}, msg: ${err.message}`);
      })
    } catch (e) {
      LogUtil.error(TAG + ' pause recording error: ' + e);
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  /* instrument ignore next */
  public async resume(): Promise<number> {
    try {
      LogUtil.info(TAG + ' resume recorder command.');
      if (this.avRecorder) {
        LogUtil.info(TAG + ' resume to record, current state is: ' + this.avRecorderState);
        await this.avRecorder.resume();
      }
      this.audioCapture?.start().then(() => {
        LogUtil.info(TAG + ' audioCapture start success');
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG + `start capture error: ${err.code}, msg: ${err.message}`);
      })
    } catch (e) {
      LogUtil.error(TAG + ' resume recorder error: ' + e);
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  /* instrument ignore next */
  public async release(): Promise<number> {
    try {
      LogUtil.info(TAG + ' release recorder command.');
      if (this.audioCapture !== undefined) {
        this.audioCapture.release()
          .then(() => {
            LogUtil.info(TAG + ' audioCapture release success');
          })
          .catch((err: BusinessError) => {
            LogUtil.error(TAG + `release capture error: ${err.code}, msg: ${err.message}`);
          })
          .finally(() => {
            this.avRecordRelease();
          })
      } else {
        this.avRecordRelease();
      }
    } catch (e) {
      LogUtil.error(TAG + ' release recorder error: ' + e);
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  /* instrument ignore next */
  public async avRecordRelease(): Promise<void> {
    if (this.avRecorder !== undefined) {
      LogUtil.info(TAG + ' release recorder, current state is: ' + this.avRecorderState);
      await this.avRecorder.release();
      RecordStateManager.changeRecordState(GlobalRecordState.IDLE);
    }
  }

  /* instrument ignore next */
  public async reset() {
    try {
      LogUtil.info(TAG + ' reset recorder command.');
      if (this.avRecorder) {
        LogUtil.info(TAG + ' reset to record, current state is: ' + this.avRecorderState);
        await this.avRecorder.reset();
      }
    } catch (e) {
      LogUtil.error(TAG + ' reset recorder error: ' + e);
    }
  }

  /* instrument ignore next */
  public async stop() {
    try {
      LogUtil.info(TAG + ' stop recorder command.');
      if (this.avRecorder) {
        LogUtil.info(TAG + ' stop to record, current state is: ' + this.avRecorderState);
        await this.avRecorder.stop();
      }
    } catch (e) {
      LogUtil.error(TAG + ' stop recorder error: ' + e);
    }
  }

  /**
   * 获取单次的振幅（会在绘制中频繁调用，不打印日志）
   *
   * @param callback 振幅回调
   */
  public getAmplitude(callback: AsyncCallback<number>) {
    // instrument ignore else
    if (this.avRecorder?.state == 'started') {
      this.avRecorder?.getAudioCapturerMaxAmplitude(callback);
    }
  }

  /**
   * 通话时记录CallState
   *
   * @param state
   */
  /* instrument ignore next */
  public updateCallState(state: number): void {
    LogUtil.info(TAG + ': updateCallState state=' + state);
    this.callState = state;
    this.tryPauseRecorder();
    this.tryResumeWhenCallEnd();
  }

  /**
   * 当通话状态更新时, 尝试暂停录音
   */
  /* instrument ignore next */
  private tryPauseRecorder(): void {
    LogUtil.info(TAG + ': tryPauseRecorder start');
    if (this.callState === CommonConstants.CALL_STATE_BEFORE_IN_CALL &&
      this.avRecorder?.state === CommonConstants.STARTED) {
      this.pause();
      this.isPausedByCall = true;
      LogUtil.info(TAG + ': tryPauseRecorder success');
    }
  }

  /**
   * 当通话状态更新时, 尝试恢复因通话而暂停的录音
   */
  /* instrument ignore next */
  private tryResumeWhenCallEnd(): void {
    LogUtil.info(TAG + ': tryResumeWhenCallEnd start');
    if (this.isPausedByCall && this.callState === CommonConstants.CALL_STATE_DISCONNECTED) {
      LogUtil.info(TAG + ': tryResumeWhenCallEnd success');
      this.resume();
    }
  }

  /**
   * 开启振幅定时器
   */
  public startAmplitudeTimer(): void {
    LogUtil.info(TAG + ': Amplitude Timer start.');
    if (this.sampleTimerId) {
      LogUtil.info(TAG + ': Amplitude Timer already start.');
      return;
    }
    this.amplitudeBuffer.clear();
    this.amplitudeInterBuffer.clear();
    this.amplitudeInterBuffer.add(0);
    this.amplitudeInterBuffer.add(0);
    this.realTimeSamples.clear();
    this.realTimeWaves.clear();
    this.nextSampleTime = 0;
    this.sampleTimerId = setInterval(() => {
      if (this.avRecorder?.state !== 'started') {
        return;
      }
      if (this.amplitudeInterBuffer.length === 1) {
        // 本次不调用接口，使用最近的接口值更新数据
        this.addAmplitudeData(this.amplitudeInterBuffer[0]);
        this.amplitudeInterBuffer.add(0);
      } else {
        RecordManager.getInstance().getAmplitude(this.amplitudeCallback);
      }
    }, DATA_TIME_INTERVAL);
  }

  /**
   * 停止获取振幅的定时器
   */
  public stopAmplitudeTimer(): void {
    // instrument ignore else
    if (this.sampleTimerId) {
      clearInterval(this.sampleTimerId);
      this.sampleTimerId = 0;
    }
  }

  /**
   * 从缓存区读取最大振幅（会在绘制中频繁调用，需减少日志打印）
   *
   * @returns 一段时间内的最大振幅
   */
  /* instrument ignore next */
  private readMaxFromBuffer(): number {
    if (this.amplitudeBuffer.isEmpty()) {
      return 0;
    }
    let sample: number = 0;
    if (this.amplitudeBuffer.length === 1) {
      sample = this.amplitudeBuffer[0];
    } else {
      sample = Math.max(...this.amplitudeBuffer.convertToArray());
    }
    this.amplitudeBuffer.clear();
    return sample;
  }

  /**
   * 获取实时的波形图数据
   */
  public getRealtimeWaves(): ArrayList<number> {
    return this.realTimeWaves;
  }

  /**
   * 判断是否在通话中
   *
   * @returns
   */
  /* instrument ignore next */
  public isInCall(): boolean {
    return this.callState >= 0 && this.callState !== CommonConstants.CALL_STATE_DISCONNECTED;
  }

  /**
   * 尝试保存录音文件，用在Ability销毁时
   */
  /* instrument ignore next */
  public trySaveRecord(): void {
    LogUtil.info(TAG + ': trySaveRecord start.');
    if (this.avRecorderState === CommonConstants.STARTED || this.avRecorderState === CommonConstants.PAUSED) {
      if (this.currentFilePath) {
        let result: boolean = SampleUtil.saveSamplesEmergency(this.currentFilePath, this.realTimeSamples);
        LogUtil.info(TAG + `: trySaveRecord ${result ? 'success' : 'failed'}.`);
      } else {
        LogUtil.info(TAG + ': trySaveRecord skip. The current file path is null.');
      }
    } else {
      LogUtil.info(TAG + ': trySaveRecord skip. Destroy without recording.');
    }
  }

  /**
   * 获取到当前的录制状态
   * @returns 'idle' | 'prepared' | 'started' | 'paused' | 'stopped' | 'released' | 'error';
   */
  /* instrument ignore next */
  public async getAvRecorderState(): Promise<string> {
    return this.avRecorderState;
  }

  /* instrument ignore next */
  public getRecordStartTime(): number {
    return this.recordStartTime;
  }

  /* instrument ignore next */
  public setRecordStartTime(time: number): void {
    this.recordStartTime = time;
  }
}