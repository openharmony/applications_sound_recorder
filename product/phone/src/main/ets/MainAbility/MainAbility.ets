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
import AbilityConstant from '@ohos.app.ability.AbilityConstant';
import {
  CommonConstants,
  ContinuousTask,
  DatabaseManager,
  DFXEnumConstants,
  GlobalContext,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  Props,
  Util
} from '@ohos/common';
import UIAbility from '@ohos.app.ability.UIAbility';
import Want from '@ohos.app.ability.Want';
import media from '@ohos.multimedia.media';
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import hiAppEvent from '@ohos.hiviewdfx.hiAppEvent';
import display from '@ohos.display';
import { Configuration } from '@ohos.app.ability.Configuration';
import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';
import { BaseViewModel, FoldStateListener, MediaController, RecordManager } from '@ohos/recorder';
import call from '@ohos.telephony.call';
import { abilityAccessCtrl, ApplicationStateChangeCallback, EnvironmentCallback } from '@kit.AbilityKit';
import { FileManager } from '@ohos/fileManager';
import * as RecordingPage from '@ohos/recorder/src/main/ets/pages/RecordingPage';
import i18n from '@ohos.i18n';
import { systemParameterEnhance } from '@kit.BasicServicesKit';
import { rpc } from '@kit.IPCKit';
import { ChmodAudioFile } from '@ohos/fileManager/src/main/ets/service/callrecord/ChmodAudioFile';
import { FormsManager } from '@ohos/recorderFA';

const TAG: string = 'SoundRecorder_MainAbility'
const FOLD_PRODUCT_TYPE = 'const.window.foldscreen.type';
const TRIPLE_FOLD = '6,1,0,0';
const DEFAULTS_FOLD_TYPE = '0,0,0,0';

export default class MainAbility extends UIAbility {
  private windowStage?: window.WindowStage;
  private enterTimer: number = new Date().getTime();
  private windowObj?: window.Window;
  private curBp: string = '';
  private lastMode = -1;
  private lastDirection = -1;
  private envCallbackId: number = 0;
  /* instrument ignore next */
  private envCallback: EnvironmentCallback = {
    onConfigurationUpdated(config: Configuration) {
      LogUtil.info(TAG + ': onConfigurationUpdated isRtl : ' + i18n.isRTL(config.language));
      AppStorage.set('isLtr', !i18n.isRTL(config.language));
      AppStorage.setOrCreate(Props.LANGUAGE, config.language);
    },
    onMemoryLevel() {
    }
  };

  /* instrument ignore next */
  private updateBreakpoint(windowWidth: number): void {
    // 将长度的单位由px换算为vp
    try {
      let displayId = this.windowObj?.getWindowProperties().displayId;
      let windowWidthVp = windowWidth / display.getDisplayByIdSync(displayId).densityPixels;
      let newBp: string = '';
      if (windowWidthVp < 320) {
        newBp = 'xs';
      } else if (windowWidthVp < 600) {
        newBp = 'sm';
      } else if (windowWidthVp < 840) {
        newBp = 'md';
      } else {
        newBp = 'lg';
      }
      if (this.curBp !== newBp) {
        this.curBp = newBp;
        // 使用状态变量记录当前断点值
        AppStorage.setOrCreate('currentBreakpoint', this.curBp);
      }
      LogUtil.info(TAG + ' phone current breakpoint is ' + this.curBp);
    } catch (err) {
      LogUtil.error(`${TAG} getDefaultDisplay of densityPixels failed, code: ${err.code}, message: ${err.message}}`);
    }
  }

  /* instrument ignore next */
  async isLocationPermission(): Promise<void> {
    MediaController.checkAccessToken('ohos.permission.LOCATION').then((value) => {
      if (value.toString() === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED.toString() &&
        AppStorage.get('shortCutStartRecord')) {
        this.windowStage?.loadContentByName(RecordingPage.RECORDING_PAGE);
      }
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` Failed to verify the playback control center,
      code: ${err?.code}, message: ${err?.message}`);
    })
  }

  /* instrument ignore next */
  private applicationStateChangeCallback: ApplicationStateChangeCallback = {
    onApplicationForeground() {
      LogUtil.info(TAG + ' onApplicationForeground callback');
      AppStorage.setOrCreate<boolean>(Props.IS_IN_BACKGROUND, false);
    },
    onApplicationBackground() {
      LogUtil.info(TAG + ' onApplicationBackground callback');
      AppStorage.setOrCreate<boolean>(Props.IS_IN_BACKGROUND, true);
    }
  }

  private registerApplicationStateChangeCallback(): void {
    let applicationContext = this.context.getApplicationContext();
    // instrument ignore else
    if (applicationContext != undefined) {
      applicationContext.on('applicationStateChange', this.applicationStateChangeCallback);
    }
  }

  /* instrument ignore next */
  private unRegisterApplicationStateChangeCallback(): void {
    let applicationContext = this.context.getApplicationContext();
    if (applicationContext != undefined) {
      try {
        applicationContext.off('applicationStateChange');
      } catch (err) {
        LogUtil.error(TAG + ` unRegisterApplicationStateChangeCallback off err,
        code: ${err?.code}, message: ${err?.message}`);
      }
    }
  }

  /* instrument ignore next */
  private registerHiAppEvent(): void {
    hiAppEvent.addWatcher({
      // 观察者名称，用于唯一标识观察者。
      name: 'watcher',
      // 订阅过滤条件，在需要对订阅事件进行过滤时传入。
      appEventFilters: [{
        domain: 'recorder_ue'
      }],
      // 订阅回调触发条件，需要与回调函数一同传入才会生效。
      triggerCondition: {
        row: 1
      },
      // 订阅回调函数，需要与回调触发条件一同传入才会生效，函数入参说明如下：
      onTrigger: (curRow, curSize, holder) => {
        if (!holder) {
          hilog.error(0x0000, 'textTag', 'HiAppEvent holder is null');
          return;
        }
        LogUtil.info('curRow: ' + curRow + ' curSize: ' + curSize);
        let eventPkg: hiAppEvent.AppEventPackage | null = null;
        while ((eventPkg = holder.takeNext()) != null) {
          hilog.info(0x0000, 'textTag', 'HiAppEvent eventPkg.packageId=%{public}d', eventPkg.packageId);
          hilog.info(0x0000, 'textTag', 'HiAppEvent eventPkg.row=%{public}d', eventPkg.row);
          hilog.info(0x0000, 'textTag', 'HiAppEvent eventPkg.size=%{public}d', eventPkg.size);
          for (const eventInfo of eventPkg.data) {
            hilog.info(0x0000, 'testTag', `HiAppEvent eventPkg.info=%{public}s`, eventInfo);
          }
        }
      }
    })
  }

  /* instrument ignore next */
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    FileManager.track();

    AppStorage.setOrCreate('enterTimer', this.enterTimer);
    //监听卡片点击事件
    GlobalContext.setUIAbilityContext(this.context);
    this.registerFaCardCallee();
    // 调起通话录音设置录音文件权限
    ChmodAudioFile.getInstance().tryStart();
    DatabaseManager.init(this.context);

    this.setIsTripleFold();
    let isDarkMode = this.context.config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    LogUtil.info(TAG + ' MainAbility onCreate isDarkMode: ' + isDarkMode);
    AppStorage.setOrCreate('isDarkMode', isDarkMode);
    let fonSizeScale = this.context.config.fontSizeScale;
    if (fonSizeScale) {
      AppStorage.setOrCreate('fontSizeScale', fonSizeScale);
    }
    if (want?.parameters !== undefined && want?.parameters !== null) {
      this.initEnterSource(want.parameters);
      AppStorage.setOrCreate('isFirstEnter', true);
      let jumpFromDoubleX =
        want?.parameters['ohos.aafwk.param.callerBundleName'] === 'com.hmos.hwquickaccessmenu';
      LogUtil.info(TAG + ' double-tap click X key jump SoundRecorder app: ' + jumpFromDoubleX);
      AppStorage.setOrCreate('jumpFromDoubleX', jumpFromDoubleX);
    } else {
      LogUtil.error(`${TAG} want.parameters is undefined`);
    }
    LogUtil.info(TAG + ' MainAbility onCreate');
    AppStorage.setOrCreate('recorderColorMode', this.context.config.colorMode);
    let isPortrait = this.context.config.direction === ConfigurationConstant.Direction.DIRECTION_VERTICAL;
    AppStorage.setOrCreate('isPortrait', isPortrait)
    AppStorage.setOrCreate('isSmallFoldVer', this.isSmallFoldVer());
    this.getFoldDisplayMode();
    this.registerApplicationStateChangeCallback();
    this.registerHiAppEvent();
    HiSysEventUtil.userDataDotting();
  }

  /* instrument ignore next */
  private registerFaCardCallee(): void {
    try {
      this.callee.on('FaCardCallback', (data: rpc.MessageSequence) => {
        return FormsManager.getInstance().faCardCall(data);
      });
      this.callee.on('FaCardMarkCallback', (data: rpc.MessageSequence) => {
        return FormsManager.getInstance().faCardMark(data);
      });
      this.callee.on('FaCardResumeCallback', (data: rpc.MessageSequence) => {
        return FormsManager.getInstance().faCardResume(data);
      });
      FormsManager.getInstance();
      LogUtil.info(TAG + ' registerFaCardCallee success');
    } catch (err) {
      LogUtil.error(TAG + ` registerFaCardCallee failed, code: ${err?.code}, message: ${err?.message}`);
    }
  }
  /* instrument ignore next */
  async onConfigurationUpdated(config: Configuration) {
    if (this.lastDirection !== config.direction) {
      LogUtil.info(TAG + 'current direction is ' + config.direction);
      this.lastDirection = Number(config.direction);
      let isPortrait = config.direction === ConfigurationConstant.Direction.DIRECTION_VERTICAL;
      AppStorage.setOrCreate('isPortrait', isPortrait)
    }
    // darkMode：0， lightMode：1
    if (this.lastMode !== config.colorMode) {
      LogUtil.info(TAG + 'current mode is ' + config.colorMode);
      AppStorage.setOrCreate('recorderColorMode', config.colorMode);
      this.lastMode = config.colorMode as number;
    }
    let windowClass: window.Window = await window.getLastWindow(this.context);
    if (config.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      LogUtil.info(TAG + ' isDrakMode set SystemBar ContentColor to white');
      windowClass.setWindowSystemBarProperties({
        // 状态栏文字颜色白色
        statusBarContentColor: '#FFFFFF'
      });
    } else {
      LogUtil.info(TAG + ' isLightMode set SystemBar ContentColor to black');
      windowClass.setWindowSystemBarProperties({
        // 设置状态栏文字颜色黑色
        statusBarContentColor: '#000000'
      });
    }
    this.onBackGroundColorChange();
  }

  /* instrument ignore next */
  onBackGroundColorChange() {
    let isDarkMode: boolean = AppStorage.get('isDarkMode') || false;
    let backGroundColor: string = '';
    if (isDarkMode) {
      backGroundColor =
        '#' + this.context.resourceManager.getColorSync($r('sys.color.ohos_id_color_sub_background_dark')).toString(16);
    } else {
      backGroundColor =
        '#' + this.context.resourceManager.getColorSync($r('sys.color.ohos_id_color_sub_background')).toString(16);
    }
    this.windowStage?.getMainWindowSync().setWindowBackgroundColor(backGroundColor);
  }

  /* instrument ignore next */
  onNewWant(want: Want) {
    LogUtil.info(TAG + ' onNewWant.');
    if (want?.parameters === undefined || want?.parameters === null) {
      LogUtil.error(`${TAG} want.parameters is undefined or null`);
      return;
    }
    this.initEnterSource(want?.parameters);
    AppStorage.setOrCreate('isFirstEnter', false);
    let jumpFromDoubleXEnd =
      want?.parameters['ohos.aafwk.param.callerBundleName'] === 'com.hmos.hwquickaccessmenu';
    LogUtil.info(TAG + ' onNewWant. double-tap click X key jump SoundRecorder app End: ' + jumpFromDoubleXEnd);
    AppStorage.setOrCreate('jumpFromDoubleXEnd', jumpFromDoubleXEnd);
    this.context.eventHub.emit('newWantJumpFromLock');
  }

  /* instrument ignore next */
  onConfigurationUpdate(newConfig: Configuration): void {
    let isDarkMode = newConfig.colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    LogUtil.info(TAG + ' onConfigurationUpdate isDarkMode: ' + isDarkMode);
    AppStorage.setOrCreate('isDarkMode', isDarkMode);
    let fontSizeScale = newConfig.fontSizeScale;
    LogUtil.info(`${TAG}, onConfigurationUpdate, current fontSizeScale: ${fontSizeScale}`);
    AppStorage.setOrCreate('fontSizeScale', fontSizeScale);
    // PafUiWidget.configurationUpdate(newConfig);
    this.updateBreakpoint(AppStorage.get('windowWidthOri') as number);
  }

  /* instrument ignore next */
  onDestroy() {
    this.context.eventHub.emit('updateFaFileNameWhenKill', '');
    try {
      this.callee.off('FaCardCallback');
      this.callee.off('FaCardResumeCallback');
      this.callee.off('FaCardMarkCallback');

    } catch (err) {
      LogUtil.error(TAG + ` onDestroy Failed to unRegister callee on. code: ${err?.code}, message: ${err?.message}`);
    }
    const recordManager = RecordManager.getInstance();
    BaseViewModel.getInstance().restoreRingMode();
    recordManager.trySaveRecord();
    // 销毁数据库连接
    DatabaseManager.destroy();
    LogUtil.error(TAG + ' MainAbility onDestroy');
    ChmodAudioFile.getInstance().release();
    this.unRegisterApplicationStateChangeCallback();
    this.unRegisterFoldStatusListener();
  }

  /* instrument ignore next */
  private updateStatusBarHeight(height: number) {
    try {
      const vpHeight = Math.ceil(height / display.getDefaultDisplaySync().densityPixels);
      AppStorage.setOrCreate<number>('statusBarHeight', vpHeight);
    } catch {
      LogUtil.info(TAG + ' updateStatusBarHeight error');
      AppStorage.setOrCreate<number>('statusBarHeight', 36);
    }
  }

  /* instrument ignore next */
  private updateScreenRect(): void {
    try {
      const dy = display.getDefaultDisplaySync();
      AppStorage.setOrCreate<number>('screenHeight', dy.height);
    } catch (err) {
      LogUtil.error(`${TAG} failed to updateScreenRect, code: ${err.code}, message: ${err.message}`);
    }
  }

  /* instrument ignore next */
  async onWindowStageCreate(windowStage: window.WindowStage) {
    // PafUiWidget.init(windowStage, this.context);
    try {
      call.on('callDetailsChange', (data: call.CallAttributeOptions) => {
        AppStorage.setOrCreate<number>('callType', data.callType);
        AppStorage.setOrCreate<number>('callState', data.callState);
      })
    } catch (err) {
      LogUtil.error(`${TAG} open call of callDetailsChange failed, code: ${err.code}, message: ${err.message}}`);
    }

    window.getLastWindow(this.context, async (err: BusinessError, win: window.Window) => {
      this.initAvoidArea(win);
      this.updateScreenRect();
      AppStorage.setOrCreate('windowClass', win);
      await win.setWindowLayoutFullScreen(true);
      AppStorage.setOrCreate<number>('windowWidth', Math.round(px2vp(win.getWindowProperties().windowRect.width)));
      AppStorage.setOrCreate<number>('windowWidthOri', win.getWindowProperties().windowRect.width);
      AppStorage.setOrCreate<number>('windowHeight', win.getWindowProperties().windowRect.height);
      AppStorage.setOrCreate<number>('screenHeight', win.getWindowProperties().windowRect.height);
      AppStorage.setOrCreate(CommonConstants.CURRENT_SPEED, media.PlaybackSpeed.SPEED_FORWARD_1_00_X);
      AppStorage.setOrCreate<number>('WindowStatusType', win.getWindowStatus() || window.WindowStatusType.FULL_SCREEN);
      win.on('windowStatusChange', (windowStatusType) => {
        AppStorage.setOrCreate<number>('WindowStatusType', windowStatusType || 1)
      })
      win.on('windowSizeChange', (data) => {
        this.updateScreenRect();
        AppStorage.setOrCreate<number>('windowWidth', Math.round(px2vp(data.width)));
        AppStorage.setOrCreate<number>('windowWidthOri', data.width);
        AppStorage.setOrCreate<number>('windowHeight', data.height);
        AppStorage.setOrCreate<boolean>('windowSizeChangeFlag', !AppStorage.get('windowSizeChangeFlag'));
      })
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          this.updateStatusBarHeight(data?.area?.topRect?.height);
        }
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          let bottomAvoidAreaHeight = data.area.bottomRect.height;
          AppStorage.setOrCreate('bottomAvoidAreaHeight', bottomAvoidAreaHeight)
        }
      })
    });

    // Main window is created, set main page for this ability
    LogUtil.info(TAG + ' MainAbility onWindowStageCreate.');
    this.windowStage = windowStage;
    const mainWindow = this.windowStage?.getMainWindowSync();
    mainWindow.setWindowLayoutFullScreen(true);

    /* instrument ignore next */
    this.windowStage?.loadContent('pages/Index', (err: BusinessError, data) => {
      if (err.code) {
        LogUtil.error(`Failed to load the content. code: ${err?.code}, message: ${err?.message}`);
        return;
      }
      this.windowStage?.getMainWindow().then((data) => {
        this.windowObj = data;
        AppStorage.setOrCreate<number>('windowHeight', data.getWindowProperties().windowRect.height);
        this.updateBreakpoint(data.getWindowProperties().windowRect.width);
        this.windowObj.on('windowSizeChange', (windowSize) => {
          LogUtil.info(TAG + ' getMainWindow windowSizeChange (' + windowSize.width + ', ' + windowSize.height + ')');
          this.updateBreakpoint(windowSize.width);
        })
        const navAvoidArea: window.AvoidArea =
          data.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
        if (navAvoidArea) {
          // 设置导航条高度
          const navigatorBarHeight = Math.ceil(px2vp(navAvoidArea?.bottomRect?.height));
          AppStorage.setOrCreate<number>('navigatorBarHeight', navigatorBarHeight);
          LogUtil.info(`${TAG} navigatorBarHeight ${navigatorBarHeight}`);
        }
        this.windowObj.on('avoidAreaChange', (data) => {
          if (window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR === data.type) {
            const navigatorBarHeight = Math.ceil(px2vp(data?.area?.bottomRect?.height))
            AppStorage.setOrCreate<number>('navigatorBarHeight', navigatorBarHeight);
            LogUtil.info(`${TAG} navigatorBarHeight ${navigatorBarHeight}`);
          }
        })
        AppStorage.setOrCreate<window.Window>('mainWindow', data);
      }).catch((err: BusinessError) => {
        LogUtil.error(` GetMainWindow Failed, code: ${err?.code}, message: ${err?.message}`);
      });
      this.onBackGroundColorChange();
      LogUtil.error(TAG + ' Succeeded in loading the content. Data: %{public}s' + JSON.stringify(data) ?? '');
    });

    this.envCallbackId = this.context.getApplicationContext().on('environment', this.envCallback);
  }

  /**
   * 避让区域设置
   * @param win
   */
  /* instrument ignore next */
  private initAvoidArea(win: window.Window): void {
    try {
      const systemArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const statusBarHeight = Math.ceil(px2vp(systemArea.topRect.height));
      AppStorage.setOrCreate<number>('statusBarHeight', statusBarHeight);
    } catch (e) {
      LogUtil.info(TAG + ' init systemArea error');
      AppStorage.setOrCreate<number>('statusBarHeight', 36);
    }
    try {
      const navigatorArea: window.AvoidArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const navigatorBarHeight = Math.ceil(px2vp(navigatorArea.bottomRect.height));
      AppStorage.setOrCreate<number>('navigatorBarHeight', navigatorBarHeight);
    } catch (e) {
      LogUtil.info(TAG + ' init navigatorArea error');
      AppStorage.setOrCreate<number>('navigatorBarHeight', 32);
    }
  }

  /* instrument ignore next */
  onWindowStageDestroy() {
    // Main window is destroyed, release UI related resources
    LogUtil.error(TAG + ' MainAbility onWindowStageDestroy ' + this.windowObj);
    this.context.getApplicationContext().off('environment', this.envCallbackId);
  }

  /* instrument ignore next */
  onForeground() {
    // Ability has brought to foreground
    LogUtil.info(TAG + ' MainAbility onForeground.')
    AppStorage.setOrCreate(Props.IS_IN_BACKGROUND, false);
    RecordManager.getInstance().getAvRecorderState().then((state) => {
      if (state === CommonConstants.STARTED || state === CommonConstants.PAUSED) {
        this.context.eventHub.emit('refreshRecordLiveView');
      }
    });
    // 在录音机处于前台时检查全局datashare连接实例
    setTimeout(() => {
      DatabaseManager.checkDataShareHelper(this.context);
    }, 150)
  }

  /* instrument ignore next */
  onBackground() {
    // Ability has back to background
    LogUtil.info(TAG + ' MainAbility onBackground.')
    RecordManager.getInstance().getAvRecorderState().then((state) => {
      LogUtil.info(`${TAG} MainAbility onBackground RECORD_BACK.` + state);
      if (state === 'started') {
        const context = GlobalContext.getUIAbilityContext();
        ContinuousTask.startRecordTask(context);
        HiSysEventUtil.eventDotting(HiSysEventName.RECORD_BACK);
      }
    });
    AppStorage.setOrCreate('shortCutStartRecord', false);
    AppStorage.setOrCreate('recordingFromLock', false);
    AppStorage.setOrCreate('shortCutRecordList', false);
    AppStorage.setOrCreate(Props.IS_IN_BACKGROUND, true);
  }

  /* instrument ignore next */
  private initEnterSource(params: Record<string, Object>) {
    AppStorage.setOrCreate('callAPPId', params?.id);
    LogUtil.error(`${TAG} initEnterSource, callAPPId: ${params?.id}`);
    // 通话跳转权限判断
    let jumpFromContacts = params[CommonConstants.CALLER_ABILITY_NAME] === CommonConstants.ABILITY_NAME_CONTACTS &&
      params[CommonConstants.CALLER_APP_IDENTIFIER] === CommonConstants.CONTACTS_APP_IDENTIFIER;
    LogUtil.info(TAG + ' contacts app jump SoundRecorder app: ' + jumpFromContacts);
    AppStorage.setOrCreate('jumpFromContacts', jumpFromContacts);

    let jumpFromVoice = params[CommonConstants.CALLER_BUNDLE_NAME] === CommonConstants.BUNDLE_NAME_VASSISTANT &&
      params[CommonConstants.CALLER_APP_IDENTIFIER] === CommonConstants.VASSISTANT_APP_IDENTIFIER;
    LogUtil.info(TAG + ' voice jump SoundRecorder app: ' + jumpFromVoice);
    AppStorage.setOrCreate('jumpFromVoice', jumpFromVoice);

    let jumpFromSceneBoard = params[CommonConstants.CALLER_BUNDLE_NAME] === CommonConstants.BUNDLE_NAME_SCENEBOARD;
    LogUtil.info(TAG + ' scene board jump SoundRecorder app : ' + jumpFromSceneBoard);
    AppStorage.setOrCreate('jumpFromSceneBoard', jumpFromSceneBoard);

    let jumpFromNotification = params?.type === 'callrecorder' && jumpFromSceneBoard;
    LogUtil.info(TAG + ' notification jump SoundRecorder app : ' + jumpFromNotification);
    AppStorage.setOrCreate('jumpFromNotification', jumpFromNotification);

    let jumpFromAudioManager =
      params[CommonConstants.CALLER_BUNDLE_NAME] === CommonConstants.BUNDLE_NAME_AUDIOACCESSORYMANAGER &&
        params[CommonConstants.CALLER_APP_IDENTIFIER] === CommonConstants.AUDIO_ACCESSORY_APP_IDENTIFIER;
    LogUtil.info(TAG + ' headset app jump SoundRecorder app: ' + jumpFromAudioManager);
    AppStorage.setOrCreate('jumpFromAudioManager', jumpFromAudioManager);

    if (params.shortCutPar === 'shortCutStartRecord') {
      LogUtil.info(TAG + ' scene board shortCut start Record . ');
      this.context.eventHub.emit('closePrivacyDialog');
      AppStorage.setOrCreate('shortCutStartRecord', true);
    }
    if (params.shortCutPar === 'shortCutRecordList') {
      LogUtil.info(TAG + ' scene board shortCut view Record list. ');
      this.context.eventHub.emit('closePrivacyDialog');
      AppStorage.setOrCreate('shortCutRecordList', true);
    }
    if (!params.params) {
      return;
    }

    try {
      let pages: Record<string, Object> = JSON.parse(params.params as string);
      let recordingFromLock = pages.targetPage as string === RecordingPage.RECORDING_PAGE;
      AppStorage.setOrCreate('recordingFromLock', recordingFromLock);
      LogUtil.info(TAG + ' jump from lockScreen ' + recordingFromLock);
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtil.error(`${TAG} JSON parse fail, code: ${code}, msg: ${message}`);
    }
  }

  /**
   * 进入app方式
   * @returns dfx打点使用数据，详情请看DFXEnumConstants.EnterAppWays
   */
  /* instrument ignore next */
  private getEnterAppSource(): number {
    let source = DFXEnumConstants.EnterAppWays.CLICK_ICON;
    if (AppStorage.get('jumpFromContacts') as boolean) {
      source = DFXEnumConstants.EnterAppWays.CALL_RECORD;
    } else if (AppStorage.get('jumpFromSceneBoard') as boolean) {
      source = DFXEnumConstants.EnterAppWays.SHORTCUT;
    } else if (AppStorage.get('jumpFromVoice') as boolean) {
      source = DFXEnumConstants.EnterAppWays.VOICE_TRIGGER;
    } else if (AppStorage.get('jumpFromDoubleX') as boolean) {
      source = DFXEnumConstants.EnterAppWays.X_KEY;
    }
    return source;
  }

  /**
   /**
    * 判断当前设备是否是三折叠
   *
   * @returns true:是三折叠设备
   */
  /* instrument ignore next */
  private isTripleFold(): boolean {
    let foldType = '';
    try {
      foldType = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE, '');
      LogUtil.info(TAG + `get foldType: ${foldType}`);
    } catch (err) {
      LogUtil.info(TAG + `get foldType err: ${err?.code}`);
    }
    return TRIPLE_FOLD === foldType;
  }

  /**
   * 存储是否是GRL设备
   */
  private setIsTripleFold(): void {
    AppStorage.setOrCreate<boolean>(CommonConstants.IS_TRIPLE_FOLD_DEVICE, this.isTripleFold());
  }

  /**
   * 是否小折叠新产品VXXX
   * @returns
   */
  public isSmallFoldVer(): boolean {
    try {
      let productValue: string = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE, DEFAULTS_FOLD_TYPE);
      let result: string[] = productValue?.split(',');
      if (result.length > 0) {
        return Number.parseInt(result[0]) === 4;
      } else {
        return false;
      }
    } catch (error) {
      LogUtil.error(TAG + ` getSync error, code: ${error?.code}, message: ${error?.message}`);
      return false;
    }
  }

  /* instrument ignore next */
  getFoldDisplayMode() {
    try {
      if (display.isFoldable()) {
        AppStorage.setOrCreate('foldDisplayMode', display.getFoldStatus());
      }
    } catch (error) {
      LogUtil.error(TAG + ' display error : ' + error);
    }
    this.registerFoldStatusListener();
  }

  /* instrument ignore next */
  registerFoldStatusListener() {
    let foldCallback: Callback<display.FoldDisplayMode> = (data: display.FoldDisplayMode) => {
      LogUtil.info(TAG + ' onFoldModeChange: ' + JSON.stringify(data));
      AppStorage.setOrCreate('foldDisplayMode', data);
    };
    FoldStateListener.registerFoldStatusListener(foldCallback);
  }

  /* instrument ignore next */
  unRegisterFoldStatusListener() {
    FoldStateListener.unRegisterFoldStatusListener();
  }
};
