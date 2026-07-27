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
import router from '@ohos.router';
import call from '@ohos.telephony.call';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import { BusinessError } from '@ohos.base';
import notificationManager from '@ohos.notificationManager';
import {
  CommonConstants,
  ConfigData,
  DeviceUtil,
  GlobalContext,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  NotificationConstants,
  NotificationManagerUtil,
  NotificationUtil,
  Props,
  ActionBarButton,
  RecorderActionBar,
  Util,
  WindowUtil
} from '@ohos/common';
import { RecordManager } from '../controller/RecordManager';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { MarkListComponent } from '../components/MarkListComponent';
import { Wave } from '../components/Wave';
import RecordNotification from '../notification/RecordNotification';
import geoLocationManager from '@ohos.geoLocationManager';
import { ButtonModifier, ColorMetrics, Configuration, curves } from '@kit.ArkUI';
import { MarkDataGroup, RouterParams } from '@ohos/common/src/main/ets/model/RecordData';
import { WaveCommand } from '../components/WaveView';
import window from '@ohos.window';
import display from '@ohos.display';
import { BaseViewModel } from '../viewModel/BaseViewModel';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import { FileManager } from '@ohos/fileManager';
import { audio } from '@kit.AudioKit'
import Want from '@ohos.app.ability.Want';
import RecordStateManager from '../audiokit/manager/RecordStateManager';
import Settings from '@ohos.settings';

const TAG = 'SoundRecorder_RecordingPage';
const AUDIO_TRANS_DURATION_LIMIT = 1000 * 60 * 60 * 2;

export const RECORDING_PAGE: string = 'RecordingPage';

@Entry({ routeName: RECORDING_PAGE })
@Component
export default struct RecordingPage {
  private isLemSmallFold = DeviceUtil.isSmallFoldLem();
  private page: string = 'RecordingPage';
  @Prop @Watch('onCurrentTimePlayChange') currentTimePlay: number;
  @StorageProp('navigationMode') navMode: number = 0;
  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean = false;
  @StorageLink('clickDelay') clickDelay: boolean = false;
  @StorageProp('screenShowState') screenShowState: string = CommonConstants.SCREEN_FULL;
  @StorageLink('screenWidthSplitState') screenWidthSplitState: string = CommonConstants.SCREEN_WIDTH_FULL;
  @State @Watch('onStateChanged') state: string = 'idle'
  @State recordState: string = 'recording'
  @State avType: string = 'record'
  @State countNum: number = 0;
  @State @Watch('onMarkListChange') markList: MarkDataGroup = new MarkDataGroup();
  @StorageLink('recordingMarkListHeightOpen') @Watch('onMarkListChanged') recordingMarkListHeightOpen: boolean = false;
  @State @Watch('onMarkOpacityChange') markOpacity: number = 1;
  @State playOrPauseOpacity: number = 1;
  @State recordWaveList: number[] = []
  @State isReleaseByNotification: boolean = false;
  @State recordingTimeUpdateTimer: number = 0;
  private lastMarkTime: number = 0;
  @State recorderProcessCheckTimer: number = -1;
  @StorageProp('isScreenOn') @Watch('onScreenChange') isScreenOn: boolean = true;
  @StorageProp('foldDisplayMode') @Watch('onFoldModeChange') foldDisplayMode: number = 0;
  @StorageLink('recorderColorMode') @Watch('updateRecorderColorMode') recorderColorMode: number = 1;
  @State locationData: Array<geoLocationManager.GeoAddress> = [];
  @StorageLink('backFromRecordingPage') backFromRecordingPage: boolean = false;
  @StorageLink('WindowStatusType') windowStatusType: number = 1;
  @StorageLink('callType') callType: number = -1;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('navigatorBarHeight') navigatorBarHeight: number = 0;
  @StorageLink('windowClass') windowClass: window.Window | undefined = undefined;
  @StorageLink('windowHeight') @Watch('isFloatingStatus') windowHeight: number = 0;
  @StorageLink('screenHeight') screenHeight: number = 0;
  @StorageLink('jumpFromDoubleXEnd') @Watch('doubleXEndRecord') jumpFromDoubleXEnd: boolean = false;
  @StorageLink('recordingFromLock') @Watch('onRecordingFromLockChange') recordingFromLock: boolean = false;
  @StorageProp('jumpFromDoubleX') jumpFromDoubleX: boolean = false;
  @StorageLink('xTapCount') xTapCount: number = 0;
  @StorageLink('shortCutStartRecord') @Watch('onShortCutStartRecordChange') shortCutStartRecord: boolean = false;
  @StorageLink('shortCutRecordList') @Watch('onShortCutRecordListChange') shortCutRecordList: boolean = false;
  // 分屏配置
  @State contentHeight: number = 400;
  // Locale
  @StorageLink('isLtr') isLtr: boolean = Configuration.getLocale().dir === 'ltr';
  @StorageProp(Props.IS_IN_BACKGROUND) isInBackground: boolean = false;
  // 发送命令，控制波形图
  @Provide waveCommand: WaveCommand = WaveCommand.RESET;
  @StorageLink('RecordBindSheet') isShowRecord: boolean = false;
  @StorageLink('RecordTime') time: number = 0;
  @StorageLink('RecordObj') obj: Record<string, Array<number>> = {};
  @State isMarkShowTips: boolean = false;
  @State isStopShowTips: boolean = false;
  @State isPauseShowTips: boolean = false;
  private waveEffect: TransitionEffect = TransitionEffect.OPACITY
    .animation({ duration: 250, curve: Curve.Sharp })
  @StorageLink('isRecordingSaveDone') isRecordingSaveDone: boolean = false;
  @StorageProp('isSmallFoldVer') isSmallFoldVer: boolean = false;
  @State isReadTitle: boolean = false;
  @State isFloating: boolean = WindowUtil.isFloating();
  @State want: Want = {};
  @Consume isFromLockScreenRecord: boolean;
  @State transHeight: string = ConfigData.QH_0_VP;
  @StorageLink('isSmallFoldSplit') isSmallFoldSplit: boolean = false;
  private markListSubscription: (tag: string, markList: MarkDataGroup) => void = (tag, newMarkList) => {
    // instrument ignore if
    if (tag === TAG) {
      return;
    }
    this.markList.content.updateAllData(newMarkList.content.getAll());
    this.recordingMarkListHeightOpen = this.markList.content.getAll().length > 0;
  };
  private markButton: ActionBarButton = new ActionBarButton({
    id: 'markBtn',
    baseIcon: $r('sys.symbol.bookmark'),
    iconFillColor: ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary')),
    onClick: () => {
      // instrument ignore if
      if (this.lastMarkTime !== 0 && this.currentTimePlay - this.lastMarkTime < CommonConstants.TIME_1000) {
        // checkCanInsertMark方法判断是否可以新增标签依赖于markList的更新，
        // 但markList的更新传递到当前组件需要一定的时间，
        // 因此快速点击时可能导致标记在1s内新增多个，所以补充当前检查逻辑，防止出错
        LogUtil.warn(TAG + '：The interval for clicking the mark button is too short.');
        return;
      }
      LogUtil.info(TAG + ' click to add insert mark.');
      this.markOpacity = 0.4;
      this.waveCommand = WaveCommand.MARK;
      getContext(this)?.eventHub?.emit('insertMark',
        BaseViewModel.getInstance().getRecordingData().getFilePath());
      this.lastMarkTime = this.currentTimePlay;
      BaseViewModel.getInstance().broadcastWhenUpdateMarkList();
    },
    enabled: true,
    accessibilityText: $r('app.string.mark'),
    hoverTips: $r('app.string.mark'),
  })
  markButtons: Array<ActionBarButton> = [this.markButton];
  private resumeButton: ActionBarButton = new ActionBarButton({
    id: 'resumeBtn',
    baseIcon: $r('sys.symbol.pause'),
    iconFillColor: ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary')),
    onClick: () => {
      // instrument ignore if
      if (this.playOrPauseOpacity !== 1) {
        return;
      }
      LogUtil.info(TAG + ' click play or pause button, state: ' + this.state);
      const recordManager = RecordManager.getInstance();
      const context = GlobalContext.getUIAbilityContext();
      if (this.state === 'started') {
        recordManager.pause().then((value) => {
          HiSysEventUtil.eventDotting(HiSysEventName.PAUSE_RECORD, { VALUE: value, FROM: 'AudioCapturer' });
        }).catch((err: BusinessError) => {
          HiSysEventUtil.eventDotting(HiSysEventName.PAUSE_RECORD, { VALUE: err.code, FROM: 'AudioCapturer' });
        });
      } else if (this.state === 'paused') {
        // instrument ignore if
        if (recordManager.isInCall() && !DeviceUtil.isPC()) {
          Util.showToast($r('app.string.has_call_hint'), false, this.isInBackground);
        } else {
          recordManager.resume().then((value) => {
            HiSysEventUtil.eventDotting(HiSysEventName.RESUME_RECORD, { VALUE: value, FROM: 'AudioCapturer' });
          }).catch((err: BusinessError) => {
            HiSysEventUtil.eventDotting(HiSysEventName.RESUME_RECORD, { VALUE: err.code, FROM: 'AudioCapturer' });
          });
        }
      }
      AccessibilityUtil.sendAnnounceAccessibilityEvent(context === null ? '' : (this.state === 'started' ?
        context?.resourceManager.getStringSync($r('app.string.pause')) :
        context?.resourceManager.getStringSync($r('app.string.resume'))));
    },
    enabled: true,
    accessibilityText: $r('app.string.pause'),
  }, new ButtonModifier().accessibilityNextFocusId('recordingTitle'))
  resumeButtons: Array<ActionBarButton> = [this.resumeButton];
  private endRecordingButton: ActionBarButton = new ActionBarButton({
    id: 'recordBtn',
    baseIcon: $r('sys.symbol.square_fill'),
    iconFillColor: ColorMetrics.resourceColor(Color.White),
    shadowStyle: ShadowStyle.OUTER_DEFAULT_XS,
    onClick: async () => {
      LogUtil.info(TAG + ' stop recording clicked.');
      // instrument ignore else
      if (DeviceUtil.isPhoneNotFold() && !this.clickDelay) {
        return;
      }
      this.isShowRecord = false;
      // instrument ignore else
      if (this.state === 'started' || this.state === 'paused') {
        this.backFromRecordingPage = true;
        await RecordManager.getInstance().release();
        this.waveCommand = WaveCommand.MARK;
      } else {
        BaseViewModel.getInstance().startRecording(TAG, getContext(this),
          this.recorderStateCallback, this.onErrorCallback);
      }
    },
    backgroundColor: ColorMetrics.rgba(251, 101, 78),
    enabled: true,
    accessibilityText: ' ',
    accessibilityDescription: ' ',
    hoverTips: GlobalContext.getUIAbilityContext() === null ? '' :
      GlobalContext.getUIAbilityContext()?.resourceManager.getStringSync($r('app.string.end')) +
        GlobalContext.getUIAbilityContext()?.resourceManager.getStringSync($r('app.string.titles'))
  }, new ButtonModifier()
    .accessibilityRole(this.isReadTitle ? AccessibilityRoleType.BUTTON : AccessibilityRoleType.ROLE_NONE)
    .accessibilityDefaultFocus(true)
  )

  /* instrument ignore next */
  public updateRecorderColorMode() {
    LogUtil.info(TAG + ' doUpdateRecordOnLive because color mode change.');
    NotificationManagerUtil.getInstance().darkMode = this.recorderColorMode;
  }

  private onMarkListChange() {
    this.recordingMarkListHeightOpen = this.markList.content.totalCount() > 0;
  }

  private onMarkOpacityChange() {
    this.markButton.enabled = this.markOpacity === 1;
  }

  private onStateChanged() {
    this.resumeButton.baseIcon = this.state === 'started' ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill');
    this.resumeButton.accessibilityText = this.state === 'started' ? $r('app.string.pause') : $r('app.string.resume');
    this.resumeButton.hoverTips = this.state === 'started' ? $r('app.string.pause') : $r('app.string.resume');
  }

  private recorderStateCallback = async (state: string) => {
    LogUtil.info(TAG + ' av recorder state changed to ' + state);
    this.state = state;
    const recordManager = RecordManager.getInstance();
    switch (state) {
      case 'prepared':
        recordManager.start();
        break;
      case 'started':
        this.recordingTimeUpdateTimer = await this.startUpdateRecordingTime();
        this.playOrPauseOpacity = 1;
        this.xTapCount = 0;
        const context = GlobalContext.getUIAbilityContext();
        let isScreenReaderEnabled =
          Settings.getValueSync(context, 'accessibility_screenreader_enabled', '') === '1';
        if (isScreenReaderEnabled) {
          setTimeout(() => {
            this.isReadTitle = true;
            this.endRecordingButton.accessibilityText = context === null ? '' :
              context?.resourceManager.getStringSync($r('app.string.end'));
            this.endRecordingButton.buttonModifier?.accessibilityRole(AccessibilityRoleType.BUTTON);
            this.endRecordingButton.accessibilityDescription = context === null ? '' :
              context?.resourceManager.getStringSync($r('app.string.accessibility_double_click'))
          }, 1000);
        }
        break;
      case 'paused':
        clearInterval(this.recordingTimeUpdateTimer);
        break;
      case 'released':
        clearInterval(this.recordingTimeUpdateTimer);
        AppStorage.setOrCreate('shortCutStartRecord', false);
        AppStorage.setOrCreate('recordingFromLock', false);
        this.isShowRecord = false;
        this.isFromLockScreenRecord = false;
        // router中有参数，从主页面点击开始的录音；无参数，直接跳转到录音页面
        // instrument ignore if
        if (router.getParams()) {
          if (DeviceUtil.isExpanded() || DeviceUtil.isTabletOrTripleGStatus() || DeviceUtil.isPC()) {
            router.back();
          }
        }
        break;
      default:
        break;
    }
    LogUtil.info(TAG + ' play state changed, state = ' + state);
    this.doUpdateRecordOnGoing();
    this.updateWaveState();
  };

  /**
   * 发送命令，控制波形图的启动与暂停
   */
  private updateWaveState(): void {
    switch (this.state) {
      case CommonConstants.PAUSED:
        this.waveCommand = WaveCommand.PAUSE;
        break;
      case CommonConstants.RELEASED:
        this.waveCommand = WaveCommand.STOP;
        break;
      case CommonConstants.STARTED:
        this.waveCommand = WaveCommand.START;
        break;
      default:
        break;
    }
  }

  // instrument ignore next
  private onErrorCallback = (error: BusinessError) => {
    LogUtil.info(TAG + ' av recorder onErrorCallback, error msg: ' + error);
    const context = GlobalContext.getUIAbilityContext();
    switch (error.code) {
      case 5400107:
        if (this.state !== 'started') {
          let message: string = context.resourceManager.getStringSync($r('app.string.has_screen_hint'));
          Util.showToast(message, DeviceUtil.isPC(), true);
        }
        try {
          LogUtil.info(TAG + ' audio interrupted.');
          this.markOpacity = 0.4;
          this.playOrPauseOpacity = 0.4;
        } catch (e) {
          LogUtil.error(TAG + ' remove record file error, reason: ' + e);
        }
        this.clearAllStatusByError();
        break;
      default:
        break;
    }
    RecordManager.getInstance().reset();
  };
  private clearAllStatusByError = () => {
    NotificationManagerUtil.getInstance().cancelNotification();
  }

  /* instrument ignore next */
  private checkCanInsertMark(): boolean {
    if (this.markList.content.getAll().length === 0) {
      return true;
    }
    if (this.currentTimePlay < this.markList.content.getData(0).markDuration - 1000) {
      return true;
    }
    if (this.markList.content.getData(this.markList.content.getAll().length - 1).markDuration + 1000 <
      this.currentTimePlay) {
      return true;
    }

    for (let i = 0, j = i + 1; j < this.markList.content.getAll().length; i++, j++) {
      if (this.markList.content.getData(i).markDuration + 1000 < this.currentTimePlay &&
        this.currentTimePlay < this.markList.content.getData(j).markDuration - 1000) {
        return true;
      }
    }
    return false;
  }

  private onCurrentTimePlayChange(): void {
    this.markOpacity = this.checkCanInsertMark() ? 1 : 0.4;
  }

  /* instrument ignore next */
  onBackPress() {
    LogUtil.info(TAG + ' click back icon to return index page.');
    this.isShowRecord = false;
    this.backFromRecordingPage = true;
    RecordManager.getInstance().release();
    this.waveCommand = WaveCommand.MARK;
    return true;
  }

  /* instrument ignore next */
  async aboutToAppear() {
    LogUtil.info(TAG + ' aboutToAppear.');
    BaseViewModel.getInstance().subscribeMarkList(this.markListSubscription);
    this.recordingMarkListHeightOpen = false;
    const context = GlobalContext.getUIAbilityContext();
    if (await this.checkCallState()) {
      let message: string = context.resourceManager.getStringSync($r('app.string.has_call_hint'));
      Util.showToast(message, false, true);
      return;
    }
    this.recorderColorMode = AppStorage.get('recorderColorMode') as number;
    NotificationManagerUtil.getInstance().darkMode = this.recorderColorMode;
    this.jumpFromDoubleXEnd = false;
    getContext()?.eventHub?.on('backPress', async () => {
      LogUtil.info(TAG + ' emit event to return index page.');
      this.onBackPress();
    });
    RecordManager.getInstance().commonEventSubscribe();
    let currentState = await RecordManager.getInstance().getAvRecorderState();
    LogUtil.info(TAG + ` aboutToAppear currentState: ${JSON.stringify(currentState)}`);
    if (currentState === 'started' || currentState === 'paused') {
      this.recordingTimeUpdateTimer = await this.startUpdateRecordingTime();
      RecordManager.getInstance().addRecorderStateListeners(TAG, this.recorderStateCallback);
      RecordManager.getInstance().addErrorCallbackListeners(TAG, this.onErrorCallback);
      this.state = currentState;
      this.currentTimePlay = RecordManager.getInstance().getRecordTime();
      if (currentState === 'paused') {
        this.waveCommand = WaveCommand.FORM_PAUSE;
      }
      this.doUpdateRecordOnGoing();
    } else {
      await this.initRecord();
    }

    let filePath = BaseViewModel.getInstance().getRecordingData().getFilePath();
    if (filePath) {
      FileManager.setRecordingFilepath(filePath);
      let arr = await DatabaseManager.queryTagByRecord(filePath);
      this.markList.content.updateAllData(arr)
      if (arr.length > 0) {
        this.recordingMarkListHeightOpen = true;
      }
    }

    getContext().eventHub.on('deleteMarkList', this.deleteMarkList);
  }

  /**
   * 判断当前通话状态
   *
   * @returns true:通话中 false:非通话或可忽略场景
   */
  private async checkCallState(): Promise<boolean> {
    try {
      const callState: call.CallState = await call.getCallState();
      if (DeviceUtil.isPC()) {
        // PC端忽略通话判断
        LogUtil.info(`${TAG} checkCallState: is PC, ingnore call state`);
        return false;
      }
      if (callState === call.CallState.CALL_STATE_RINGING || callState === call.CallState.CALL_STATE_OFFHOOK) {
        LogUtil.info(`${TAG} checkCallState: is calling`);
        return true;
      }
      return false;
    } catch (e) {
      LogUtil.error(`${TAG} checkCallState fail: ${e?.message}`);
      return false;
    }
  }

  /* instrument ignore next */
  async aboutToDisappear() {
    LogUtil.info(TAG + ' aboutToDisappear.');
    this.markList = new MarkDataGroup();
    BaseViewModel.getInstance().clearRecorderProcessTimer();
    this.xTapCount = 1;
    AppStorage.setOrCreate('jumpFromDoubleXEnd', false);
    this.isRecordingSaveDone = true;
    getContext()?.eventHub?.off('backPress');
    getContext().eventHub.off('deleteMarkList', this.deleteMarkList);
    BaseViewModel.getInstance().unsubscribeMarkList(this.markListSubscription);
    RecordManager.getInstance().commonEventUnSubscribe();
  }

  async startUpdateRecordingTime(): Promise<number> {
    clearInterval(this.recordingTimeUpdateTimer);
    return setInterval(() => {
      let recordedTime = RecordManager.getInstance().getRecordTime();
      if (recordedTime !== 0) {
        this.currentTimePlay = recordedTime;
        if (this.currentTimePlay > AUDIO_TRANS_DURATION_LIMIT) {
          let inBackground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
          Util.showToast($r('app.string.record_timeout'), DeviceUtil.isPC(), inBackground);
        }
      }
    }, 90);
  }

  private deleteMarkList = () => {
    this.markList.content.deleteAll();
  }

  async initRecord() {
    await RecordManager.getInstance().initAvRecorder();
    LogUtil.info(TAG + ' initRecord. ');
    await BaseViewModel.getInstance().startRecording(TAG, getContext(this),
      this.recorderStateCallback, this.onErrorCallback);
    let routerParams: RouterParams = router.getParams() as RouterParams;
    // instrument ignore if
    if (routerParams) {
      this.currentTimePlay = routerParams?.currentTimePlay as number;
    }
    // 从列表进入录音页面的时延
    let startTime = this.time;
    let timeCost: number = new Date().getTime() - startTime;
    HiSysEventUtil.eventDotting(HiSysEventName.ADD_RECORD, { DURATION: timeCost, FROM: 'AudioCapturer' });
  }

  /* instrument ignore next */
  private doubleXEndRecord(): void {
    if (this.jumpFromDoubleXEnd && this.state === 'started') {
      if (this.xTapCount % 2 === 1) {
        this.isShowRecord = false;
        this.backFromRecordingPage = true;
        this.isRecordingSaveDone = false;
        RecordManager.getInstance().release();
      }
      this.jumpFromDoubleXEnd = false;
    } else if (this.jumpFromDoubleXEnd && this.state === 'paused') {
      this.xTapCount = 0;
      RecordManager.getInstance().resume();
      this.jumpFromDoubleXEnd = false;
    }
  }

  /* instrument ignore next */
  getSize(name: string): number {
    let context = getContext(this) as common.UIAbilityContext;
    let pathDir = context.filesDir;
    let curpathDir = pathDir + '/' + name;
    let stat = fs.statSync(curpathDir);
    return stat.size
  }

  /* instrument ignore next */
  private onShortCutStartRecordChange(): void {
    if (this.shortCutStartRecord && this.state === 'paused') {
      RecordManager.getInstance().resume();
    }
  }

  // 暂停，通过锁屏卡片打开录音机后，继续录音
  /* instrument ignore next */
  private onRecordingFromLockChange(): void {
    if (this.recordingFromLock && this.state === 'paused') {
      RecordManager.getInstance().resume();
    }
  }

  /* instrument ignore next */
  private onShortCutRecordListChange(): void {
    if (this.shortCutRecordList) {
      this.isShowRecord = false;
      this.backFromRecordingPage = true;
      RecordManager.getInstance().release();
    }
  }

  onDarkModeChange(): void {
    LogUtil.info(`${TAG} onDarkModeChange isDarkMode : ${this.isDarkMode}`);
    this.markButton.iconFillColor = ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary'))
    this.resumeButton.iconFillColor = ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary'))
  }

  onMarkListChanged() {
    animateTo({ curve: curves.interpolatingSpring(0, 1, 131, 23) }, () => {
      if (this.markList.content.getAll().length) {
        this.recordingMarkListHeightOpen = true;
      } else {
        this.recordingMarkListHeightOpen = false;
      }
    })
  }

  @Builder
  /* instrument ignore next */
  NavDestinationTitleBar() {
    Row() {
      Text($r('app.string.titles'))
        .fontColor($r('sys.color.ohos_id_color_titlebar_text'))
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontWeight(FontWeight.Bold)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .flexGrow(1)
        .flexShrink(100)
        .id('recordingTitle')

      Row() {
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .id('backIconInNavDestinationTitleBar')
            .fontSize($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            .draggable(false)
        }
        .accessibilityText(GlobalContext.getUIAbilityContext() === null ? '' :
          GlobalContext.getUIAbilityContext()?.resourceManager.getStringSync($r('app.string.detailDialog_close')))
        .width($r('app.float.distance_40'))
        .height($r('app.float.distance_40'))
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .onClick(() => {
          this.onBackPress();
        })
        .draggable(false)
      }
      .id('BackButton')
      .width(40)
      .height(40)
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
    }
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor($r('app.color.bind_sheet_background'))
    .height($r('app.float.wh_value_56'))
    .margin({ top: $r('app.float.margin_size_8') })
    .width('100%')
    .padding({
      left: DeviceUtil.isPC() ? $r('app.float.margin_size_24') : $r('app.float.margin_size_16'),
      right: DeviceUtil.isPC() ? $r('app.float.margin_size_24') : $r('app.float.margin_size_16')
    })
  }

  @Builder
  SymbolPlayAndPauseButton() {
    SymbolGlyph(this.state === 'started' ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
      .rotate({
        x: 0,
        y: 1,
        z: 0,
        angle: Configuration.getLocale().dir === 'rtl' ? 180 : 0
      })
      .direction(Configuration.getLocale().dir === 'rtl' ? Direction.Rtl : Direction.Ltr)
      .draggable(false)
      .width('24vp')
      .height('24vp')
      .fontSize('24vp')
      .fontColor(this.isDarkMode ? new Array($r('sys.color.ohos_id_color_primary')) : new Array('#040000'))
      .symbolEffect(new AppearSymbolEffect(EffectScope.WHOLE), true)
  }

  @Builder
  WaveCardComponent() {
    Column() {
      Wave({
        avType: this.avType,
        recordState: this.state,
        currentTimePlay: this.currentTimePlay,
        recordWaveList: this.recordWaveList,
        markList: this.markList,
        contentHeight: this.contentHeight,
      })
        .transition(this.waveEffect)
    }
    .zIndex(10)
    .width('100%')
    .layoutWeight(1)
    // 手机1/3屏（不包含三折叠全展开）工具高度栏大于0或小折叠下不展示
    .visibility(this.screenShowState === CommonConstants.SCREEN_ONE_THREE &&
      (DeviceUtil.isPhone() && !DeviceUtil.isTripleFoldGStatus() &&
        this.navigatorBarHeight > 0 || this.isSmallFoldVer) ?
      Visibility.None : Visibility.Visible)
  }

  /* instrument ignore next */
  @Builder
  MarkAndBtnComponent() {
    Column() {
      MarkListComponent({
        markList: this.markList,
        markOpacity: this.markOpacity,
        state: this.state,
        currentTimePlay: this.currentTimePlay,
        page: this.page
      })
        .width('100%')
        .height(this.recordingMarkListHeightOpen ? $r('app.float.wh_value_40') : 0)
        .margin(this.recordingMarkListHeightOpen ? { top: $r('app.float.margin_size_12') } : {})
        .visibility((this.screenShowState === CommonConstants.SCREEN_ONE_THREE ||
          (this.screenShowState === CommonConstants.SCREEN_HALF &&
            this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_FULL) ||
          (this.isSmallFoldVer && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) ||
          this.isWidthHalfVerOrbar() || (DeviceUtil.isPhone() && this.isFloating)) ? Visibility.None :
          Visibility.Visible)

      Column() {
        Row() {
          WithTheme({
            colorMode: ThemeColorMode.SYSTEM
          }) {
            RecorderActionBar({
              startButtons: this.markButtons,
              primaryButton: this.endRecordingButton,
              endButtons: this.resumeButtons,
              isExpand: true
            })
          }
        }
      }
      .backgroundColor($r('app.color.bind_sheet_background'))
      .width('100%')
      .justifyContent(FlexAlign.End)
      .height($r('app.float.distance_60'))
      .margin({
        top: (this.isSmallFoldVer && this.screenShowState === CommonConstants.SCREEN_HALF ||
          (DeviceUtil.isBarPhone() || this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) &&
            this.windowStatusType === window.WindowStatusType.SPLIT_SCREEN) ?
          $r('app.float.margin_size_12') : $r('app.float.margin_size_24'),
        bottom: this.getToolBarComponentBottom()
      })
    }
    .margin({
      bottom: (DeviceUtil.isPhoneNotFold() || this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED ||
        (DeviceUtil.isExpanded() && this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF)) ?
        this.navigatorBarHeight : 0
    })
    .width('100%')
  }

  /* instrument ignore next */
  getToolBarComponentBottom() {
    if (this.isSmallFoldVer && this.windowStatusType === window.WindowStatusType.FLOATING) {
      return $r('app.float.margin_size_16');
    }
    //Verde与直板机左右分屏
    if (this.isWidthHalfVerOrbar()) {
      return $r('app.float.margin_size_8');
    }
    return (DeviceUtil.isPhoneNotFold() || this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED ||
      (DeviceUtil.isExpanded() && this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF)) ?
      (DeviceUtil.isSmallFoldVer() ? this.navigatorBarHeight + 8 : $r('app.float.margin_size_8')) :
      DeviceUtil.isPC() ? $r('app.float.margin_size_24') :
        (DeviceUtil.isSmallFoldVer() ? this.navigatorBarHeight + 8 : $r('app.float.margin_size_16'))
  }

  //是否直板机或者小折叠XX 分屏
  isWidthHalfVerOrbar(): boolean {
    return this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF &&
      (DeviceUtil.isBarPhone() || this.isSmallFoldVer || DeviceUtil.isFolded());
  }

  @Builder
  /* instrument ignore next */
  AudioContentComponent() {
    Column() {
      this.WaveCardComponent();
      // todo 加上this.isShowQuickTrans销毁小于组件吗(已验证，会销毁组件)，首次打开之后不能销毁
      this.MarkAndBtnComponent();
    }
    .padding({
      left: DeviceUtil.isPC() ? $r('app.float.margin_size_24') : $r('app.float.margin_size_16'),
      right: DeviceUtil.isPC() ? $r('app.float.margin_size_24') : $r('app.float.margin_size_16')
    })
    .width('100%')
    .layoutWeight(1)
    .justifyContent(DeviceUtil.isPhone() && this.screenShowState === CommonConstants.SCREEN_ONE_THREE &&
      this.navigatorBarHeight > 0 ? FlexAlign.End : FlexAlign.Start)
  }

  /* instrument ignore next */
  build() {
    Navigation() {
      this.NavDestinationTitleBar();
      this.AudioContentComponent();
    }
    .mode(NavigationMode.Stack)
    .hideTitleBar(true)
    .height('100%')
    .title($r('app.string.titles'))
    .titleMode(NavigationTitleMode.Mini)
    .backgroundColor($r('app.color.bind_sheet_background'))
    .onAreaChange((_, newValue) => {
      this.contentHeight = Number(newValue.height);
      this.displayChangeCallback();
    })
    .gesture(GestureGroup(GestureMode.Sequence, PanGesture()))
  }

  /* instrument ignore next */
  async displayChangeCallback(): Promise<void> {
    try {
      // 直板机或全折叠分屏
      if ((DeviceUtil.isBarPhone() || this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) &&
        this.windowStatusType === window.WindowStatusType.SPLIT_SCREEN) {
        if (this.screenShowState === CommonConstants.SCREEN_ONE_THREE ||
          (this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED && DeviceUtil.isLandscape())) {
          // 1/3屏，折叠态横屏
          this.transHeight = '0vp';
        } else if (this.screenShowState === CommonConstants.SCREEN_HALF) {
          // 2/3屏
          this.transHeight = ConfigData.QH_105_VP;
        } else {
          this.transHeight = ConfigData.QH_150_VP;
        }
      }
    } catch (error) {
      LogUtil.error(TAG + ' displayChangeCallback failed.');
    }
  }

  /* instrument ignore next */
  async doUpdateRecordOnGoing() {
    const duration = RecordManager.getInstance().getRecordTime();
    if (this.isLemSmallFold) {
      let state = this.state;
      LogUtil.info(TAG + ' onRecordStateChange .... state = ' + state + ', duration=' + duration)
      RecordNotification.updateNotification(getContext(this), state, duration);
    }
    // 发送录音横幅通知
    await NotificationManagerUtil.getInstance().updateNotification(
      getContext(this),
      NotificationConstants.UpdateNotificationMode.UPDATE_BY_STATE,
      this.state,
      duration,
      this.onLiveViewButtonResponse
    );
  }
  //处理通知栏，点击按钮的回调
  private onLiveViewButtonResponse = (id: number, option: notificationManager.ButtonOptions) => {
    LogUtil.info(TAG + ` onLiveViewButtonResponse id=${id}, buttonName=${option.buttonName}`);
    const recordManager = RecordManager.getInstance();
    const buttonName: string = option.buttonName;
    if (buttonName === CommonConstants.STOPPED) {
      this.isReleaseByNotification = true;
      this.isShowRecord = false;
      this.backFromRecordingPage = true;
      recordManager.release().then(() => {
        this.waveCommand = WaveCommand.MARK;
      });
      return;
    }
    if (buttonName === CommonConstants.STARTED) {
      recordManager.pause()
      return;
    }
    if (buttonName === CommonConstants.PAUSED) {
      if (recordManager.isInCall() && !DeviceUtil.isPC()) {
        Util.showToast($r('app.string.has_call_hint'), false, this.isInBackground);
        return;
      }
      recordManager.resume()
    }
  }
  /* instrument ignore next */
  onScreenChange() {
    LogUtil.info(TAG + ' onScreenChange, isScreenOn=' + this.isScreenOn);
    this.doUpdateRecordOnGoing();
  }

  /* instrument ignore next */
  onFoldModeChange() {
    LogUtil.info(TAG + ' onFoldModeChange, foldDisplayMode=' + this.foldDisplayMode);
    NotificationUtil.setDisplayMode(this.foldDisplayMode);
    this.doUpdateRecordOnGoing();
  }

  /* instrument ignore next */
  isFloatingStatus() {
    // 根据窗口高度变化判断是否悬浮
    this.isFloating = WindowUtil.isFloating();
  }
}
