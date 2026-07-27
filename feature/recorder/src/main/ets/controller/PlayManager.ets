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
import { CommonConstants, ContinuousTask, LogUtil, Helps } from '@ohos/common';
import SampleUtil from '@ohos/common/src/main/ets/utils/SampleUtil';
import { BusinessError, Callback } from '@ohos.base';
import userFileManager from '@ohos.filemanagement.userFileManager';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import { RecordData } from '@ohos/common/src/main/ets/model/RecordData';
import { AvSessionManager } from './AvSessionManager';
import audio from '@ohos.multimedia.audio';
import { ArrayList } from '@kit.ArkTS';

const TAG = 'SoundRecorder_PlayManager';
const CALL_RECORD_FILE_PREFIX = 'file://';
// 跳过静音阈值，小于阈值，则不进行跳过静音处理
const SKIP_MUTE_THRESHOLD = 100;

interface SetDataSourceArgs {
  tag: string;
  recordData: RecordData;
}

export class MuteSection {
  public start: number = 0;
  public end: number = 0;

  /* instrument ignore next */
  public constructor(start: number, end: number) {
    this.start = start;
    this.end = end;
  }
}

export class PlayManager {
  private audioPlayer?: media.AVPlayer;
  private playerState: string = '';
  private playStateCallback?: Callback<string>;
  private onErrorCallback?: Callback<BusinessError>;
  private timeUpdateCallback?: Callback<number>;
  private durationCallback?: Callback<number>;
  private openedFileFd: number = -1;
  private openedFileName?: string;
  private openedFileDuration?: number;
  private currentTimePlay: number = 0;
  private resetFlag: boolean = false;
  private resetSpeedFlag: boolean = false;
  private isInterrupt: boolean = false;
  private playSpeed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  private currentSamples: number[] = [];
  private samplesListener?: Callback<number[] | 'new_record_flag'>;
  private recordData?: RecordData;
  private static instance?: PlayManager;
  private static lock = false;
  private isSkipMuteMode: boolean = false;
  private muteSections: ArrayList<MuteSection> = new ArrayList();
  private isSeeking: boolean = false;

  private constructor() {
    LogUtil.info(TAG + ` set PlayManager singleton, create an instance.`);
  }

  /* instrument ignore next */
  public static getInstance(): PlayManager {
    if (!PlayManager.instance) {
      while (PlayManager.lock) {
      }
      PlayManager.lock = true;
      if (!PlayManager.instance) {
        PlayManager.instance = new PlayManager();
        PlayManager.instance.initPlayManager();
      }
      PlayManager.lock = false;
    }
    return PlayManager.instance;
  }

  /* instrument ignore next */
  public async initPlayManager(): Promise<void> {
    if (this.audioPlayer) {
      return;
    }

    try {
      this.audioPlayer = await media.createAVPlayer();
      this.setAVPlayerCallback(this.audioPlayer);
      LogUtil.info(`${TAG} initPlayManager success.`);
    } catch (e) {
      LogUtil.error(`${TAG} failed to create the AVPlayer, code: ${e.code}, message: ${e.message}`);
    }
  }

  private seekDoneListener = (seekDoneTime: number) => {
    LogUtil.info(TAG + ` AVPlayer seek succeeded, seek time is ${seekDoneTime}`);
    AvSessionManager.getInstance().seek(seekDoneTime);
    getContext().eventHub.emit('seekDone', seekDoneTime);
    // instrument ignore if
    if (this.playerState !== 'playing' && this.timeUpdateCallback) {
      this.timeUpdateCallback(seekDoneTime);
    }
  }
  /* instrument ignore next */
  private errorListener = (err: BusinessError) => {
    LogUtil.error(TAG + ` Invoke avPlayer failed, code is ${err.code}, message is ${err.message}`);
    if (this.onErrorCallback) {
      this.onErrorCallback(err);
    }
    this.audioPlayer?.reset();
  }
  /* instrument ignore next */
  private timeUpdateListener = (time: number) => {
    this.currentTimePlay = time;
    // 暂停播放后恢复播放，会在paused状态下收到一个不太准确的播放时间，这个时间一般慢于实际的播放进度
    // 丢弃暂停状态下的这个时间，能解决暂停恢复播放时，进度条和波形图回退的问题，且不影响其他功能（Seek & 拖动波形图）
    // instrument ignore else
    if (this.timeUpdateCallback && this.playerState !== CommonConstants.PAUSED) {
      this.timeUpdateCallback(time);
    }

    //跳过静音
    if (this.isSeeking) {
      return;
    }
    if (this.isSkipMuteMode && this.muteSections.length !== 0 && time !== this.openedFileDuration) {
      let nextNonMuteTime = this.findnextNonMuteTime(time);
      if (this.openedFileDuration !== undefined) {
        nextNonMuteTime = Math.min(nextNonMuteTime, this.openedFileDuration)
      }
      if ((nextNonMuteTime - time) > SKIP_MUTE_THRESHOLD) {
        this.isSeeking = true;
        this.seek(nextNonMuteTime).then(() => {
          this.isSeeking = false;
        });
      }
    }
  }

  private durationUpdateListener = (duration: number) => {
    LogUtil.info(TAG + 'start duration update');
    this.openedFileDuration = duration;
    // instrument ignore if
    if (this.durationCallback) {
      this.durationCallback(duration);
    }
  }

  private async updateAvSession(state: string): Promise<void> {
    switch (state) {
      case 'playing':
        setTimeout(async () => {
          LogUtil.error(TAG + ` updateAvSession currentTimePlay ` + this.currentTimePlay);
          // instrument ignore else
          if (this.recordData && this.audioPlayer) {
            let params: Record<string, number | RecordData | string> = {
              'item': this.recordData,
              'currentTimePlay': this.currentTimePlay,
              'speed': this.playSpeed,
              'playState': 'playing'
            };
            await AvSessionManager.getInstance().updateMetadata(params, 'playing')
          }
        }, 100);
        break;
      case 'paused':
        await AvSessionManager.getInstance()
          .updatePlaybackState(this.currentTimePlay, this.playSpeed, 'pause', 'pause');
        break;
      case 'idle':
      case 'completed':
      case 'released':
        ContinuousTask.stopTask(getContext());
        await AvSessionManager.getInstance().destroyAvSession();
        break;
      default:
    }
  }

  /* instrument ignore next */
  private stateChangeListener = async (state: string, reason: media.StateChangeReason) => {
    if (!this.audioPlayer) {
      LogUtil.error(TAG + ` setAVPlayerCallback error, avplayer is null`);
      return;
    }
    LogUtil.info(TAG + ' AVPlayer state changed to ' + state + ' reason: ' + reason);
    this.playerState = state;
    if (!this.isInterrupt) {
      await this.updateAvSession(state);
    } else {
      this.isInterrupt = false;
    }
    switch (state) {
      case 'idle':
        if (this.resetFlag) {
          LogUtil.info(TAG + ' resetFlag: ' + this.resetFlag);
          this.resetFlag = false;
          this.setPlayerUrl(this.audioPlayer, this.openedFileName);
        }
        if (this.playStateCallback) {
          this.playStateCallback(state);
        }
        break;
      case 'initialized':
        this.audioPlayer.audioRendererInfo = {
          content: audio.ContentType.CONTENT_TYPE_MUSIC,
          usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
          rendererFlags: 0
        };
        this.audioPlayer.prepare();
        break;
      case 'playing':
        ContinuousTask.startPlayTask(getContext());
        if (this.playStateCallback) {
          this.playStateCallback(state);
        }
        break;
      case 'prepared':
        if (this.resetSpeedFlag) {
          this.setSpeed(CommonConstants.SPEED_FORWARD_1_00_X);
        }
        this.resetSpeedFlag = false;
      case 'paused':
      case 'completed':
        if (this.playStateCallback) {
          this.playStateCallback(state);
        }
        break;
      case 'stopped':
      case 'released':
        this.closeFile(this.openedFileFd);
        break;
      default:
        this.closeFile(this.openedFileFd);
        break;
    }
  }

  private speedDoneListener = (speed: number) => {
    LogUtil.info(TAG + ' avplayer speed change done, speed is: ' + speed);
    this.playSpeed = speed;
    AvSessionManager.getInstance().setSpeed(this.currentTimePlay, speed);
  }

  private deviceChangeCallback = (data: audio.AudioStreamDeviceChangeInfo) => {
    switch (data.changeReason) {
      case audio.AudioStreamDeviceChangeReason.REASON_NEW_DEVICE_AVAILABLE:
        LogUtil.info(TAG + ' New device.');
        break;
      case audio.AudioStreamDeviceChangeReason.REASON_OVERRODE:
        LogUtil.info(TAG + ' Switch device.');
        break;
      case audio.AudioStreamDeviceChangeReason.REASON_OLD_DEVICE_UNAVAILABLE:
      case audio.AudioStreamDeviceChangeReason.REASON_UNKNOWN:
        if (this.getAVPlayerState() === 'playing') {
          this.pause();
        }
        break;
      default:
        break;
    }
  }

  // instrument ignore next
  private setAVPlayerCallback(avPlayer: media.AVPlayer): void {
    avPlayer.on('seekDone', this.seekDoneListener);
    avPlayer.on('error', this.errorListener);
    avPlayer.on('audioInterrupt', async (interruptEvent) => {
      LogUtil.info(TAG + ' avPlayer audioInterrupt : ' + JSON.stringify(interruptEvent));
      this.audioInterruptProcessing(interruptEvent);
    });
    avPlayer.on('timeUpdate', this.timeUpdateListener);
    avPlayer.on('durationUpdate', this.durationUpdateListener);
    avPlayer.on('stateChange', this.stateChangeListener);
    avPlayer.on('speedDone', this.speedDoneListener);
    avPlayer.on('audioOutputDeviceChangeWithInfo', this.deviceChangeCallback);
  }

  /**
   * 音频焦点打断问题的处理方式，目前只支持系统操作的pause和stop，其余保留
   * @param interruptEvent
   */
  /* instrument ignore next */
  private audioInterruptProcessing(interruptEvent: audio.InterruptEvent): void {
    // 由系统进行操作，强制打断音频渲染，应用需更新自身状态及显示内容等
    switch (interruptEvent.hintType) {
      case audio.InterruptHint.INTERRUPT_HINT_PAUSE:
        // 音频流已被暂停，临时失去焦点，待可重获焦点时会收到resume对应的interruptEvent
      case audio.InterruptHint.INTERRUPT_HINT_STOP:
        // 音频流已被停止，永久失去焦点，若想恢复渲染，需用户主动触发
        LogUtil.info(TAG + ' Pause or stop the focus interrupt status.');
        AvSessionManager.getInstance().destroyAvSession();
        this.isInterrupt = true;
        this.pause();
        break;
      case audio.InterruptHint.INTERRUPT_HINT_RESUME:
        // 提示音频恢复，音频流被暂停后重启获取焦点会触发此事件
        LogUtil.info(TAG + ' Prompt for audio recovery');
        if (this.playerState === 'paused') {
          this.play();
        }
        break;
      case audio.InterruptHint.INTERRUPT_HINT_DUCK:
        // 音频流已被降低音量渲染
      case audio.InterruptHint.INTERRUPT_HINT_UNDUCK:
        // 音频流已被恢复正常音量  渲染
      default:
        LogUtil.info(TAG + ' No operation is performed when the focus is interrupted.');
        break;
    }
  }

  /* instrument ignore next */
  private unsetAVPlayerCallback(avPlayer: media.AVPlayer): void {
    if (!avPlayer) {
      LogUtil.error(TAG + ` unsetAVPlayerCallback error, avplayer is null`);
      return;
    }
    this.timeUpdateCallback = undefined;
    this.playStateCallback = undefined;
    this.onErrorCallback = undefined;
    this.durationCallback = undefined;
    avPlayer.off('seekDone');
    avPlayer.off('error');
    avPlayer.off('timeUpdate');
    avPlayer.off('durationUpdate');
    avPlayer.off('stateChange');
    avPlayer.off('speedDone');
    avPlayer.off('audioOutputDeviceChangeWithInfo');
  }

  /* instrument ignore next */
  private async openCallRecord(filePath: string): Promise<number> {
    let mgr = userFileManager.getUserFileMgr(getContext());
    let predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
    predicates.equalTo('uri', filePath);
    let fetchOptions: userFileManager.FetchOptions = {
      fetchColumns: [],
      predicates: predicates
    };
    let fetchResult: userFileManager.FetchResult<userFileManager.FileAsset> = await mgr.getAudioAssets(fetchOptions);
    let fd = -1;
    LogUtil.info(TAG + ' fetch call record Result size: ' + fetchResult.getCount());
    if (fetchResult.getCount() !== 0) {
      let fileAsset: userFileManager.FileAsset = await fetchResult.getFirstObject();
      fd = await fileAsset.open('rw');
    }
    return fd;
  }

  /* instrument ignore next */
  private async setPlayerUrl(audioPlayer: media.AVPlayer, filePath: string | undefined): Promise<void> {
    this.currentSamples = [];
    if (!filePath) {
      LogUtil.error(TAG + ' setPlayerUrl error, filePath invalid. ');
      return;
    }
    try {
      if (!fs.accessSync(filePath)) {
        LogUtil.error(TAG + ' file access fail, please check file path.');
        getContext().eventHub.emit('fileDeleted');
        return;
      }
      let fd: number;
      if (filePath.startsWith(CALL_RECORD_FILE_PREFIX)) {
        LogUtil.info(TAG + ' open call record.');
        fd = await this.openCallRecord(filePath);
      } else {
        LogUtil.info(TAG + ' open normal record.');
        let file = await fs.open(filePath);
        fd = file.fd;
      }
      LogUtil.error(TAG + ' set player url, current state: ' + this.audioPlayer?.state);
      audioPlayer.url = 'fd://' + fd;
      this.openedFileName = filePath;
      this.openedFileFd = fd;
      this.currentSamples = await SampleUtil.readWaveSamplesFromFile(filePath);
      if (this.samplesListener) {
        this.samplesListener(this.currentSamples);
      }
      LogUtil.info(TAG + ' open record file success, file fd is: ' + this.openedFileFd);
    } catch (e) {
      LogUtil.error(TAG + ' AVPlayer set url error, reason ' + e);
    }
  }

  /* instrument ignore next */
  private async closeFile(fileFd: number) {
    try {
      let tmpFd = this.openedFileFd
      if (tmpFd !== -1) {
        this.openedFileFd = -1;
        await fs.close(tmpFd);
      }
    } catch (error) {
      LogUtil.error(TAG + ' close file error: ' + error);
    }
  }

  public getAVPlayerState(): media.AVPlayerState {
    // instrument ignore else
    return this.audioPlayer ? this.audioPlayer.state : 'error';
  }

  public getAVPlayerCurrentPlayTime(): number {
    return this.currentTimePlay;
  }

  // setDataSource防抖外壳
  /* instrument ignore next */
  public setDataSourceDebounce =
    Helps.debounce((args: SetDataSourceArgs) => void this.setDataSource(args.tag, args.recordData), 50);

  /* instrument ignore next */
  public async setDataSource(tag: string, recordData: RecordData) {
    let filePath = recordData._data;
    this.recordData = recordData;
    LogUtil.info(TAG + ' setDataSource, tag: ' + tag);
    if (!this.audioPlayer) {
      LogUtil.error(TAG + ' setDataSource error: audioPlayer is null');
      return;
    }

    this.setSpeed(CommonConstants.SPEED_FORWARD_1_00_X);

    if (this.samplesListener) {
      this.samplesListener('new_record_flag');
    }

    LogUtil.info(TAG + ' start to play a new record, player current state ' + this.audioPlayer.state);
    if (this.openedFileName && this.openedFileName !== filePath) {
      LogUtil.info(TAG + ' start to play a new record, close the last opened record.');
      await this.closeFile(this.openedFileFd);
    }

    if (this.audioPlayer.state === 'idle') {
      LogUtil.info(TAG + 'start setPlayerUrl');
      this.setPlayerUrl(this.audioPlayer, filePath);
    } else {
      this.openedFileName = filePath;
      this.resetFlag = true;
      await this.audioPlayer.reset();
    }
  }

  public setPlayStateCallback(tag: string, playStateCallback: Callback<string>): void {
    if (this.playStateCallback) {
      return;
    }
    LogUtil.info(`${TAG} setPlayStateCallback for ${tag}`);
    this.playStateCallback = playStateCallback;
    // instrument ignore else
    if (playStateCallback) {
      playStateCallback(this.getAVPlayerState());
    }
  }

  /* instrument ignore next */
  public unsetPlayStateCallback(tag: string): void {
    LogUtil.info(TAG + ' unSetPlayStateCallback for ' + tag);
    this.playStateCallback = undefined;
  }

  public setTimeUpdateCallback(tag: string, timeUpdateCallback: Callback<number>): void {
    LogUtil.info(TAG + ' setTimeUpdateCallback for ' + tag);
    this.timeUpdateCallback = timeUpdateCallback;
  }

  /* instrument ignore next */
  public unsetTimeUpdateCallback(tag: string): void {
    LogUtil.info(TAG + ' unTimeUpdateCallback for ' + tag);
    this.timeUpdateCallback = undefined;
  }

  /* instrument ignore next */
  public setOnErrorCallback(tag: string, onErrorCallback: Callback<BusinessError>): void {
    LogUtil.info(TAG + ' setOnErrorCallback for ' + tag);
    this.onErrorCallback = onErrorCallback;
  }

  /* instrument ignore next */
  public unsetOnErrorCallback(tag: string): void {
    LogUtil.info(TAG + ' unsetOnErrorCallback for ' + tag);
    this.onErrorCallback = undefined;
  }

  public setDurationCallback(tag: string, durationCallback: Callback<number>): void {
    LogUtil.info(TAG + ' setDurationCallback for ' + tag);
    this.durationCallback = durationCallback;
    // instrument ignore else
    if (durationCallback) {
      durationCallback(this.openedFileDuration);
    }
  }

  /* instrument ignore next */
  public unsetDurationCallback(tag: string): void {
    LogUtil.info(TAG + ' unsetDurationCallback for ' + tag);
    this.durationCallback = undefined;
  }

  /* instrument ignore next */
  public getAudioFileDuration(): number {
    LogUtil.info(TAG + ' getAudioFileDuration: ' + this.openedFileDuration);
    return this.openedFileDuration || 0;
  }

  /* instrument ignore next */
  public async play(): Promise<number> {
    try {
      LogUtil.info(TAG + ' play command.');
      if (this.audioPlayer) {
        LogUtil.info(TAG + ' start to play, current state is: ' + this.playerState);
        await AvSessionManager.getInstance().createAVSession('SoundRecorder_Play');
        await this.audioPlayer.play();
      }
    } catch (e) {
      LogUtil.error(TAG + ' play error: ' + e);
      this.audioPlayer?.reset();
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  public async pause(): Promise<number> {
    try {
      LogUtil.info(TAG + ' pause command.');
      // instrument ignore else
      if (this.audioPlayer) {
        LogUtil.info(TAG + ' start to pause, current state is: ' + this.playerState);
        await this.audioPlayer.pause();
      }
    } catch (e) {
      LogUtil.error(TAG + ' pause error: ' + e);
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  /* instrument ignore next */
  public async release(): Promise<void> {
    try {
      LogUtil.info(TAG + ' release command.');
      // instrument ignore else
      if (this.audioPlayer) {
        LogUtil.info(TAG + ' start to release, current state is: ' + this.playerState);
        this.unsetAVPlayerCallback(this.audioPlayer);
        this.resetSpeedFlag = false;
        await this.audioPlayer.release();
        // Release后清空变量，否则将导致PC热启动无法正常初始化AVPlayer
        this.audioPlayer = undefined;
      }
    } catch (e) {
      LogUtil.error(TAG + ' release error: ' + e);
    }
  }

  /* instrument ignore next */
  public async seek(seekTime: number): Promise<number> {
    try {
      LogUtil.info(TAG + ' seek command.');
      // instrument ignore else
      if (this.audioPlayer) {
        LogUtil.info(TAG + ' start to seek, seek to: ' + seekTime);
        this.currentTimePlay = seekTime;
        this.audioPlayer.seek(seekTime, media.SeekMode.SEEK_NEXT_SYNC);
        if (AppStorage.get('sliderSeekTo') !== undefined) {
          AppStorage.set('sliderSeekTo', seekTime);
        }
      }
    } catch (e) {
      LogUtil.error(TAG + ' seek error: ' + e);
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  //设置倍速
  /* instrument ignore next */
  public async setSpeed(value: media.PlaybackSpeed): Promise<number> {
    LogUtil.info(TAG + ' this.playerState : ' + this.playerState + ', avplay.state : ' + this.audioPlayer?.state);
    let allowStates: media.AVPlayerState[] = [
      'prepared',
      'playing',
      'paused',
      'completed'
    ];
    if (this.audioPlayer === undefined || allowStates.indexOf(this.audioPlayer.state) === -1) {
      LogUtil.info(TAG + ' set play speed, skip.');
      return CommonConstants.FAILURE;
    }
    try {
      LogUtil.info(TAG + ' set play speed, value: ' + value);
      if (this.audioPlayer) {
        this.playSpeed = value;
        this.audioPlayer.setSpeed(value);
        AppStorage.setOrCreate(CommonConstants.CURRENT_SPEED, value);
      }
    } catch (e) {
      LogUtil.error(TAG + ' setSpeed error: ' + e);
      return (e as BusinessError).code;
    }
    return CommonConstants.SUCCESS;
  }

  // 获取倍速设置
  /* instrument ignore next */
  public getSpeed() {
    return this.playSpeed;
  }

  /**
   * 获取速度值
   *
   * @returns 0.5、1、1.5、2.0
   */
  /* instrument ignore next */
  public getSpeedValue(): number {
    switch (this.playSpeed) {
      case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
        return 0.75;
      case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
        return 1;
      case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
        return 1.25;
      case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
        return 1.75;
      case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
        return 2;
      case CommonConstants.SPEED_FORWARD_0_50_X:
        return 0.5;
      case CommonConstants.SPEED_FORWARD_1_50_X:
        return 1.5;
      default:
        return 1;
    }
  }

  // 停止播放
  /* instrument ignore next */
  public async reset() {
    try {
      LogUtil.info(TAG + ' reset command.');
      if (this.audioPlayer) {
        this.resetSpeedFlag = true;
        await this.audioPlayer.reset();
      }
    } catch (e) {
      LogUtil.error(TAG + ' reset error: ' + e);
    }
  }

  /**
   * 注册波形图采样数据监听
   *
   * @param callback 数据回调
   */
  public registerSamplesListener(callback: Callback<number[] | 'new_record_flag'>) {
    LogUtil.info(TAG + ': registerSamplesListener.')
    this.samplesListener = callback;
    // 没有波形数据也需要Callback
    callback(this.currentSamples);
  }

  /**
   * 取消波形图采样数据监听
   */
  /* instrument ignore next */
  public unRegisterSamplesListener() {
    LogUtil.info(TAG + ': unRegisterSamplesListener.')
    this.currentSamples = [];
    this.samplesListener = undefined;
  }

  /**
   * 获取当前正在播放音频的波形图
   *
   * @returns 波形图
   */
  /* instrument ignore next */
  public getSamples(): number[] {
    return this.currentSamples;
  }

  /**
   * 如果用户重命名的是当前正在播放的录音，那么需要同时更新录音文件名称到播控中心
   * @param name
   */
  public updateCurrentPlayedRecordName(name: string, tag?: string): void {
    // instrument ignore else
    if (this.recordData) {
      this.recordData.name = name;
    }
    AvSessionManager.getInstance().updateTitle(name, tag);
  }

  /**
   * 获取下一个非静音的时间点
   * @param currentTime 当前时间点
   * @returns 下一个非静音的时间点
   */
  /* instrument ignore next */
  private findnextNonMuteTime(currentTime: number): number {
    for (let section of this.muteSections) {
      let endTime = Math.floor(section.end * 1000 / 6);
      if ((currentTime >= section.start * 1000 / 6) && (currentTime < endTime)) {
        return endTime;
      }
    }
    return currentTime;
  }

  /**
   * 关闭静音模式，恢复相关默认值
   */
  /* instrument ignore next */
  public clearMuteSections() {
    this.muteSections = new ArrayList();
    this.isSkipMuteMode = false;
    this.isSeeking = false;
  }

  /**
   * 录音文件是否有波形
   * @returns 录音文件是否有波形
   */
  /* instrument ignore next */
  public hasSamples(): boolean {
    return this.currentSamples.length > 0;
  }
}
