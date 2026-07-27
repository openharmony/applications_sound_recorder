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
import avSession from '@ohos.multimedia.avsession';
import { PlayManager} from '../../../..';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { BusinessError, screenLock } from '@kit.BasicServicesKit';
import { AnonymousUtil, CommonConstants, DFXEnumConstants, HiSysEventName, HiSysEventUtil,
  RecordData,
  Util } from '@ohos/common';

/**
 * 播放逻辑处理，与AVSession交互类
 */
const TAG = 'SoundRecorder_AvSessionManager';

export class AvSessionManager {
  private session?: avSession.AVSession;

  private currentState: avSession.AVPlaybackState = {
    state: avSession.PlaybackState.PLAYBACK_STATE_PAUSE
  }

  /* instrument ignore next */
  public getCurrentState(): avSession.AVPlaybackState {
    return this.currentState;
  }

  private static instance?: AvSessionManager;
  private static lock = false;
  private isSessionActive: boolean = true;

  private constructor() {
  }

  /* instrument ignore next */
  public static getInstance(): AvSessionManager {
    if (!AvSessionManager.instance) {
      while (AvSessionManager.lock) {
      }
      AvSessionManager.lock = true;
      if (!AvSessionManager.instance) {
        AvSessionManager.instance = new AvSessionManager();
      }
      AvSessionManager.lock = false;
    }
    return AvSessionManager.instance;
  }

  public async updatePlaybackState(currentTimePlay: number, speed: number, state: string, tag: string): Promise<void> {
    let realSpeed = this.switchToAvSessionSpeed(speed);
    LogUtil.info(TAG + ' updatePlaybackState, ' + currentTimePlay + ' : ' + realSpeed + ' : ' + state + ',tag:' + tag);
    let playState = ['playing'].includes(state) ?
    avSession.PlaybackState.PLAYBACK_STATE_PLAY :
    avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
    this.currentState = {
      state: playState,
      position: {
        elapsedTime: currentTimePlay,
        updateTime: new Date().getTime(),
      },
      speed: realSpeed,
    };
    // instrument ignore if
    if (!this.isSessionActive) {
      LogUtil.info(`${TAG} updatePlaybackState avsession not active, skip.`);
      return;
    }
    await this.session?.setAVPlaybackState(this.currentState);
  }

  /* instrument ignore next */
  public async setSpeed(currentTimePlay: number, speed: number): Promise<void> {
    LogUtil.info(TAG + 'setSpeed, currentTimePlay: ' + currentTimePlay + ', speed: ' + speed);
    this.currentState.speed = this.switchToAvSessionSpeed(speed);
    this.currentState.position = {
      elapsedTime: currentTimePlay,
      updateTime: new Date().getTime(),
    };
    if (!this.isSessionActive) {
      LogUtil.info(`${TAG} setSpeed avsession not active, skip.`);
      return;
    }
    await this.session?.setAVPlaybackState(this.currentState);
  }

  public async seek(seek: number): Promise<void> {
    LogUtil.info(TAG + ' seek: ' + seek);
    this.currentState.position = {
      elapsedTime: seek,
      updateTime: new Date().getTime(),
    };
    // instrument ignore if
    if (!this.isSessionActive) {
      LogUtil.info(`${TAG} seek avsession destroying, skip.`);
      return;
    }
    await this.session?.setAVPlaybackState(this.currentState);
  }

  /**
   * 初始化AVSession数据
   */
  /* instrument ignore next */
  public async updateMetadata(params: Record<string, number | RecordData | string>, tag: string): Promise<void> {
    LogUtil.info(TAG + ' updateMetadata tag = ' + tag);
    try {
      let item = params.item as RecordData;
      let metadata: avSession.AVMetadata = {
        assetId: '1', // 由应用指定，用于标识应用媒体库里的媒体
        title: item.name,
        subtitle: Util.getDateAndTimeFormat(item.date),
        duration: item.duration,
      };

      LogUtil.info(TAG + ` session is invalid ` + !this.session);
      if (!this.isSessionActive) {
        LogUtil.info(`${TAG} updateMetadata avsession not active.`);
        return;
      }
      this.session?.setAVMetadata(metadata).then(() => {
        LogUtil.info(TAG + ` SetAVMetadata successfully`);
      }).catch((err: BusinessError) => {
        LogUtil.error(`${TAG} SetAVMetadata BusinessError: code: ${err.code}, message: ${err.message}`);
      })

      let playState = params.playState as string;
      let currentTimePlay = params.currentTimePlay as number;
      let speed = params.speed as number;
      LogUtil.info(TAG + ` SetAVMetadata setAVPlaybackState currentTimePlay：` + currentTimePlay);
      this.updatePlaybackState(currentTimePlay, speed, playState, TAG).then(() => {
        LogUtil.info(TAG + ` SetAVPlaybackState successfully`);
      }).catch((err: BusinessError) => {
        LogUtil.error(`${TAG} SetAVPlaybackState BusinessError: code: ${err.code}, message: ${err.message}`);
      })
    } catch (e) {
      LogUtil.info(TAG + ` metadata is invalid ` + e);
    }
  }

  /**
   * 用户重命名之后，更新重名之后的名字到播控中心和通知栏
   * @param title
   * @param tag
   */
  /* instrument ignore next */
  public updateTitle(title: string, tag?: string): void {
    LogUtil.info(TAG + ' updateTitle tag = ' + tag);
    try {
      let metadata: avSession.AVMetadata = {
        assetId: '1', // 由应用指定，用于标识应用媒体库里的媒体
        title: title,
      };
      if (!this.isSessionActive) {
        LogUtil.info(`${TAG} updateTitle avsession not active.`);
        return;
      }
      this.session?.setAVMetadata(metadata).then(() => {
        LogUtil.info(TAG + ` updateTitle successfully`);
      }).catch((err: BusinessError) => {
        LogUtil.error(`${TAG} updateTitle BusinessError: code: ${err.code}, message: ${err.message}`);
      })
    } catch (e) {
      LogUtil.info(TAG + ` updateTitle is invalid ` + e);
    }
  }

  /* instrument ignore next */
  private switchToAvSessionSpeed(speed: number) {
    AppStorage.setOrCreate(CommonConstants.CURRENT_SPEED, speed);
    LogUtil.info(TAG + ` switchToAvSessionSpeed oringin speed : ` + speed);
    switch (speed) {
      case CommonConstants.SPEED_FORWARD_0_50_X:
        return 0.5;
      case CommonConstants.SPEED_FORWARD_1_00_X:
        return CommonConstants.SPEED_FORWARD_1_00_X;
      case CommonConstants.SPEED_FORWARD_1_50_X:
        return 1.5;
      case CommonConstants.SPEED_FORWARD_2_00_X:
        return 2;
      default:
        return CommonConstants.SPEED_FORWARD_1_00_X;
    }
  }

  /**
   * 创建AVSession
   * tag:传入当前需要使用此方法的类名，以便从log中统计调用次数和区分，避免多次创建导致状态错乱
   */
  /* instrument ignore next */
  public async createAVSession(tag: string): Promise<void> {
    LogUtil.info(`${TAG} create an av session, tag: ${tag}`);
    if (this.session) {
      LogUtil.info(`${TAG} repeated to create an av session.`);
      return;
    }
    try {
      this.session = await avSession.createAVSession(getContext(this), 'SoundRecorderAVSession', 'audio');
      await this.registerSessionListener();
      // 激活接口要在元数据、控制命令注册完成之后再执行
      await this.session.activate();
      this.isSessionActive = true;
      LogUtil.info(`${TAG} the av session is created, sessionId: ${AnonymousUtil.anonymous(this.session.sessionId)}`);
    } catch (err) {
      LogUtil.info(`${TAG} failed to create the av session, code: ${err.code}, message: ${err.message} `);
    }
  }

  /**
   * 注册Session回调
   * 请按需注册，如果当前不支持该指令请不要注册
   * audio类型的session，请实现进度条、收藏、上下一首、播放暂停和循环模式回调，如暂不支持请off接口或不要注册
   * video类型的session，请实现快进快退，上下一集，播放暂停回调，如暂不支持请off接口或不要注册
   */
  /* instrument ignore next */
  private async registerSessionListener(): Promise<void> {
    LogUtil.info(`${TAG} register the av session listener, the session is existed: ${!!this.session}`);
    if (!this.session) {
      return;
    }

    // 播放指令处理
    this.session.on('play', async () => {
      const player = PlayManager.getInstance();
      const state = player.getAVPlayerState();
      LogUtil.info(TAG + ' on play. AVPlayerState is ' + state);
      //状态为idle时需要先执行setDataSource等状态变为prepare后再播放
      let delayTime = state === 'idle' ? 50 : 0;
      setTimeout(async () => {
        await player.play().then((value) =>{
          LogUtil.info(TAG + ' The playback is successful.');
          this.hiSysEventSend(DFXEnumConstants.RecordPlayOperations.RESUME, value);
        }).catch((err: BusinessError) =>{
          LogUtil.error(TAG + ` Playback control operation failed. code: ${err?.code}, message: ${err?.message}`);
          this.hiSysEventSend(DFXEnumConstants.RecordPlayOperations.RESUME, err.code);
        });
      }, delayTime)

      if (state === 'idle') {
        const item = AppStorage.get(CommonConstants.CURRENT_FOCUS_RECORD) as RecordData;
        LogUtil.info(TAG + ' getItem:' + AnonymousUtil.anonymous(item?.title));
        player.setDataSource('AvSessionManager_play', item);
      }
    });

    // 暂停指令处理
    this.session.on('pause', async () => {
      LogUtil.info(TAG + ' on pause. ' );
      await PlayManager.getInstance().pause().then((value) =>{
        LogUtil.info(TAG + ' The playback control operation is paused successfully.');
        this.hiSysEventSend(DFXEnumConstants.RecordPlayOperations.PAUSE, value);
      }).catch((err: BusinessError) =>{
        LogUtil.error(TAG + ` Playback control operation failed. code: ${err?.code}, message: ${err?.message}`);
        this.hiSysEventSend(DFXEnumConstants.RecordPlayOperations.PAUSE, err.code);
      });
    });

    // 进度条拖动指令处理
    this.session.on('seek', async (position) => {
      LogUtil.info(TAG + ' on seek: seek to ' + position);
      await PlayManager.getInstance().seek(position);
      this.currentState.position = {
        elapsedTime: position,
        updateTime: Date.now(),
      };
      if (!this.isSessionActive) {
        LogUtil.info(`${TAG} seekListener avsession not active.`);
        return;
      }
      this.session?.setAVPlaybackState(this.currentState);
    });
   }

  /* instrument ignore next */
  private hiSysEventSend(state: number, status: number) {
    let isLock: boolean = screenLock.isLocked();
    HiSysEventUtil.eventDotting(HiSysEventName.BACK_PLAY_PAUSE, { STATE: state, SUCCESS: status,
      ENTRANCE: isLock ? DFXEnumConstants.PlaybackControlSource.LOCK_SCREEN_NOTIFICATION_BAR
        : DFXEnumConstants.PlaybackControlSource.PLAYBACK_CONTROL });
  }

  /**
   * 取消注册Session回调
   */
  /* instrument ignore next */
  public async destroyAvSession() {
    LogUtil.info(`${TAG} destroyAvSession.`);
    if (!this.session) {
      return;
    }

    this.session.off('play');
    this.session.off('pause');
    this.session.off('seek');

    try {
      this.isSessionActive = false;
      await this.session.destroy();
      this.session = undefined;
    } catch (err) {
      LogUtil.info(`${TAG} failed to destroy the av session , code: ${err.code}, message: ${err.message}`);
    }
  }
}