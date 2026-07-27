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
// instrument ignore file

import {
  AnonymousUtil,
  AuditLogManager,
  CommonConstants,
  ConfigData,
  DeviceUtil,
  DFXEnumConstants,
  FileUtil,
  flexBox,
  HiSysEventName,
  HiSysEventUtil,
  HoverTextTipsStyle,
  HoverTextTipsUtil,
  LogUtil,
  LongPressDialogView,
  MarkData,
  PathUtil,
  RenameDialog,
  ShareModalParams,
  ShareUtil,
  TextTipsPopup,
  ActionBarButton,
  ActionBarStyle,
  ActionBarStyleOptions,
  RecorderActionBar,
  RecordType,
  RecordData
} from '@ohos/common';
import { AccessibilityUtil, Util } from '@ohos/common/src/main/ets/utils/Util';
import { BusinessError } from '@ohos.base';
import common from '@ohos.app.ability.common';
import fs from '@ohos.file.fs';
import fileUri from '@ohos.file.fileuri';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import util from '@ohos.util';
import media from '@ohos.multimedia.media';
import relationalStore from '@ohos.data.relationalStore';
import { MarkListComponent, PlayManager, ProgressBarComponent} from '../../../../index';
import { MarkDataGroup, RecordDataGroupArray } from '@ohos/common/src/main/ets/model/RecordData';
import { RecorderState } from '../enums/RecorderState';
import { WaveCommand, WaveView } from '../components/WaveView';
import { ColorMetrics, ComponentContent, Configuration, display, LengthMetrics } from '@kit.ArkUI';
import { JSON } from '@kit.ArkTS';
import ContactsManagerUtil from '@ohos/common/src/main/ets/utils/ContactsManagerUtil';
import { SideBarMode } from '../components/SideBarComponent';
import { RecordTag, TransferData } from '@ohos/common/src/main/ets/model/TransferData';
import { uriPermissionManager, wantConstant } from '@kit.AbilityKit';
import { PreferencesUtil } from '@ohos/common/src/main/ets/utils/PreferencesUtil';
import { BaseViewModel } from '../viewModel/BaseViewModel';
import { AlertDialog } from '@ohos.arkui.advanced.Dialog';

const TAG: string = 'SoundRecorder_RecordPlayPage';
const MENU_DEFAULT_WIDTH: number = 224;
const XIAOYI_BUNDLE = 'com.hmos.vassistant';

const mainTitleFontSize: flexBox.RangeLimit = { max: 30, min: 18 };

const subTitleFontSize: flexBox.RangeLimit = { max: 20, min: 10 };

const narrowScreenMainTitleMaxFontSize: flexBox.SizeBreakpointMap = { sm: mainTitleFontSize.min, md: 24, lg: 24 };

const narrowScreenSubTitleMaxFontSize: flexBox.SizeBreakpointMap = { sm: subTitleFontSize.min, md: 12, lg: 12 };

const wideScreenMainTitleMaxFontSize: flexBox.SizeBreakpointMap = { sm: 20, md: 20, lg: mainTitleFontSize.max };

const wideScreenSubTitleMaxFontSize: flexBox.SizeBreakpointMap = { sm: 12, md: 12, lg: subTitleFontSize.max };

@Component
export struct RecordPlayPage {
  @StorageProp('currentBreakpoint') curBp: string = 'sm';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('navigatorBarHeight') @Watch('calcLayout') navigatorBarHeight: number = 0;
  @StorageProp('isDarkMode') @Watch('onDarkModeChange') isDarkMode: boolean = false;
  @StorageProp('isScreenLock') @Watch('onScreenLockChange') isScreenLock: boolean = false;
  @StorageLink('screenWidthSplitState') screenWidthSplitState: string = CommonConstants.SCREEN_WIDTH_FULL;
  @Consume pathStack: NavPathStack;
  @State focusRecordDuration: number = 0;
  @Consume('offsetBottom') offsetBottom: number;
  @Consume @Watch('onPlaybackStateChange') state: string;
  @Link @Watch('updateMarkOpacity') currentTimePlay: number;
  @Consume selectedRecordList: Array<RecordData>;
  @StorageLink('recordPlayMarkListHeightOpen') @Watch('onMarkListChanged') recordPlayMarkListHeightOpen: boolean =
    false;
  @State @Watch('onMarkListChanged') markList: MarkDataGroup = new MarkDataGroup();
  @State markDuration: number = 0
  @State @Watch('onMarkOpacityChanged') markOpacity: number = 1
  @State @Watch('onSpeedChanged') speed: media.PlaybackSpeed =
    AppStorage.get(CommonConstants.CURRENT_SPEED) || media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  @Consume @Watch('onFocusRecordChanged') focusRecord: RecordData;
  @Link recordDataGroupList: RecordDataGroupArray;
  @State tranState: number = -1;
  @StorageProp('navigationMode') navMode: number = 0;
  private page: string = 'RecordPlayPage';
  @State transferData: TransferData | undefined = undefined;
  @State proxy: UIExtensionProxy | undefined = undefined;
  @StorageLink('RecordPlayBindSheet') isShowRecordPlay: boolean = false;
  @StorageLink('RecordTranslateState') @Watch('calcLayout') recordTransState: boolean = false;
  @StorageLink('DigestSheet') isShowDigest: boolean = false;
  @StorageLink('windowFocused') isWindowFocused: boolean = true;
  @State isSplitStatus: boolean = false;
  @State transOpacity: number = 0;
  @State transImageOpacity: number = (this.tranState === 1 || this.tranState === 2) ? 0 : 1;
  @State want: Want = {};
  @State wantParametersDone: boolean = false;
  // 标记是否在查询过程中，查询过程中没必要去保存录音数据
  private inMarkQuery: boolean = false;
  private jsonObject: Object | null = null;
  private recordTags: RecordTag[] = [];
  @State recordTagsDone: boolean = false;
  @State isShowMenu: boolean = false;
  @Consume isRenameFlag: boolean;
  private convertIconEffect: TransitionEffect =
    TransitionEffect.asymmetric(
      TransitionEffect.opacity(1).animation({ duration: 150, curve: Curve.Sharp }),
      TransitionEffect.IDENTITY
    )
  private convertContentEffect: TransitionEffect = TransitionEffect.OPACITY
    .animation({ duration: 300, curve: Curve.Sharp })
  @Consume @Watch('onsideFolderNameFlagChange') sideFolderNameFlag: number;
  @Consume loading: boolean;
  // 倍速数值
  private playSpeedNumberList = [
    CommonConstants.SPEED_FORWARD_0_50_X,
    CommonConstants.SPEED_FORWARD_1_00_X,
    CommonConstants.SPEED_FORWARD_1_50_X,
    CommonConstants.SPEED_FORWARD_2_00_X
  ];
  // media.PlaybackSpeed枚举值和倍速的关系
  private playSpeedMap: Record<media.PlaybackSpeed, number> = {
    0: 0.75,
    1: 1,
    2: 1.25,
    3: 1.75,
    4: 2,
    5: 0.5,
    6: 1.5,
    7: 3,
    8: 0.25,
    9: 0.125
  };
  // 倍速图标
  private playSpeedIconList: Resource[] = [
    $r('sys.symbol.speed_50percent'),
    $r('sys.symbol.speed_100percent'),
    $r('sys.symbol.speed_150percent'),
    $r('sys.symbol.speed_200percent'),
  ];
  @State speedIcon: Resource = this.playSpeedIconList[1];
  @StorageLink('isEditMode') isEditMode: boolean = false;
  @State disAbleSpeed: boolean = false
  @State @Watch('onWaveMove') waveMoveTime: number = 0
  private validMarkIndex: number = 0;
  @StorageLink('isExistRecordPlayPage') @Watch('onExistRecordPlayPageChange') isExistRecordPlayPage: boolean = false;
  private playTimeBeforeRename: number = 0;
  private recordDataBeforeRename: RecordData = new RecordData();
  private needInitElapsedTime: boolean = false;
  @StorageProp('jumpFromDoubleXEnd') jumpFromDoubleXEnd: boolean = true;
  @StorageProp('shortCutRecordList') shortCutRecordList: boolean = false; //查看录音文件列表
  // 发送命令，控制波形图
  @Provide waveCommand: WaveCommand = WaveCommand.RESET;
  private isAudioCompleted = false;
  @State canvasIsReady: boolean = false;
  // 分屏配置
  private customDialogViewController?: CustomDialogController;
  private rsc = getContext().resourceManager;
  @StorageLink('fontSizeScale') fontSizeScale: number = CommonConstants.TEXT_SIZE_NORMAL;
  private defaultDP: number = Util.getDefaultDensityPixels(getContext());
  @StorageProp('foldDisplayMode') @Watch('onFoldModeChange') foldDisplayMode: number = 0;
  @State lastDate: number = 0;
  @State lastDuration: number = 0;
  @State lastName: string = '';
  @State lastIndex: number = -1;
  @Consume isSearchMode: boolean;
  @State isMoreShowTips: boolean = false;
  @State isRecordToTextShowTips: boolean = false;
  @State isMarkShowTips: boolean = false;
  @State isPlayShowTips: boolean = false;
  @State isSpeedShowTips: boolean = false;
  @State isShowLoadingProgress: boolean = false;
  @Consume isExitTopAction: boolean;
  @StorageLink('displaySizeScale') displaySizeScale: number = CommonConstants.PAD_DISPLAY_SIZE_SCALE_NORMAL;
  @Consume isShowSideBar: boolean;
  @State transcriptionTime: number = 0;
  @StorageProp('isSmallFoldVer') isSmallFoldVer: boolean = false;
  @Consume detailRecord: RecordData;
  // flex boxes for layout
  @State @Watch('calcLayout') h1: number = 0;
  private titleHeight: number = DeviceUtil.isPC() ? 64 : 56;
  @State h1Box: flexBox.FlexBox = {};
  @State h2Box: flexBox.FlexBox = {};
  @State aBox: flexBox.FlexBox = {};
  @State progressTimeMaxFontSize: number = mainTitleFontSize.min;
  @State durationTimeMaxFontSize: number = subTitleFontSize.min;
  @State waveBox: flexBox.FlexBox = {};
  @State translateTextBox: flexBox.FlexBox = {};
  @State markListBox: flexBox.FlexBox = { height: 40, flexShrink: 0, margin: { top: 12 } };
  @State progressBarBox: flexBox.FlexBox = { height: 28, flexShrink: 0 };
  @State actionBarBox: flexBox.FlexBox = { height: 60, flexShrink: 0 };
  @Link isSkipMute: boolean;
  @State isSkipMuteShowTips: boolean = false;
  @StorageProp('hasSamples') hasSamples: boolean = false;
  @State isPrimaryIconChanged: boolean = false;
  @StorageLink('isAgreeQuickTrans') isAgreeQuickTrans: boolean = false;
  private markButton: ActionBarButton = new ActionBarButton({
    id: 'playMark',
    baseIcon: $r('sys.symbol.bookmark'),
    iconFillColor: ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary')),
    onClick: () => {
      this.markOpacity = 0.4;
      if (!FileUtil.exists(this.focusRecord?._data)) {
        LogUtil.error(TAG + ' record file is invalid, can not insert tag');
        return;
      }
      this.calculatingMarkerPositions();
      LogUtil.info(TAG + ' click insert mark button to insert mark at position: ' + this.validMarkIndex);
      if (this.recordTransState && this.transferData) {
        getContext(this).eventHub.emit('insertMark', this.focusRecord?._data, this.validMarkIndex, true);
      } else {
        getContext(this).eventHub.emit('insertMark', this.focusRecord?._data, this.validMarkIndex);
      }
      BaseViewModel.getInstance().broadcastWhenUpdateMarkList();
    },
    enabled: this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS,
    accessibilityText: $r('app.string.mark'),
    hoverTips: $r('app.string.mark'),
  })
  private markButtons: Array<ActionBarButton> = [this.markButton];
  private speedButton: ActionBarButton = new ActionBarButton({
    id: this.disAbleSpeed ? 'disableDoubleSpeed' : 'doubleSpeed',
    baseIcon: this.playSpeedIconList[1],
    iconFillColor: ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary')),
    onClick: () => {
      this.processSpeedClick();
    },
    enabled: this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS,
    accessibilityText: this.playSpeedMap[this.speed ?? 1].toString()
      .concat(getContext().resourceManager.getStringSync($r('app.string.speed_play'))),
    hoverTips: $r('app.string.speed_play'),
  })
  private speedButtons: Array<ActionBarButton> = [this.speedButton];
  private playPauseButton: ActionBarButton = new ActionBarButton({
    id: 'playPause',
    baseIcon: this.state === 'playing' ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'),
    altIcon: $r('sys.symbol.pause'),
    iconFillColor: ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary')),
    backgroundColor: ColorMetrics.resourceColor($r('sys.color.interactive_click')),
    shadowStyle: ShadowStyle.OUTER_DEFAULT_XS,
    onClick: () => {
      if (this.state === 'playing') {
        PlayManager.getInstance().pause().then(() => {
          HiSysEventUtil.eventDotting(HiSysEventName.PLAY_DETAIL_PAUSE0, { VALUE: CommonConstants.SUCCESS });
        }).catch(() => {
          HiSysEventUtil.eventDotting(HiSysEventName.PLAY_DETAIL_PAUSE0, { VALUE: CommonConstants.FAILURE });
        });
      } else {
        if (PlayManager.getInstance().getAVPlayerState() === CommonConstants.COMPLETED) {
          this.currentTimePlay = 0;
        }
        PlayManager.getInstance().play().then(() => {
          HiSysEventUtil.eventDotting(HiSysEventName.PLAY_DETAIL_PLAY0, { VALUE: CommonConstants.SUCCESS });
        }).catch(() => {
          HiSysEventUtil.eventDotting(HiSysEventName.PLAY_DETAIL_PLAY0, { VALUE: CommonConstants.FAILURE });
        });
      }
      AccessibilityUtil.sendAnnounceAccessibilityEvent(this.getPlayStatusText());
    },
    accessibilityText: this.rsc.getStringSync($r('app.string.pause'))
  })

  /**
   * 计算标记插入的位置
   */
  private calculatingMarkerPositions() {
    this.validMarkIndex = 0;
    let markListTemp: MarkData[] = this.markList.content.getAll();
    if (markListTemp.length === 0 || (this.currentTimePlay < markListTemp[0].markDuration - 1000)) {
      return;
    }

    if (markListTemp[markListTemp.length - 1].markDuration + 1000 <
      this.currentTimePlay && this.currentTimePlay < this.focusRecordDuration) {
      this.validMarkIndex = markListTemp.length;
      return;
    }

    for (let i = 0, j = i + 1; j < markListTemp.length; i++, j++) {
      if (markListTemp[i].markDuration + 1000 < this.currentTimePlay &&
        this.currentTimePlay < markListTemp[j].markDuration - 1000) {
        this.validMarkIndex = j;
        return;
      }
    }
  }

  /**
   * 计算布局
   * 1. 宽屏左右分栏
   * 2. 模态框
   */
  private calcLayout(): void {
    LogUtil.info(`${TAG} h1: ${this.h1}`);

    const isSplitMode = this.navMode === NavigationMode.Split;
    isSplitMode ? this.calcWideScreenLayout() : this.calcNarrowScreenLayout();

    this.calcH2BoxLayout(isSplitMode);
  }

  /**
   * 计算h2布局
   * @param isSplitMode
   */
  private calcH2BoxLayout(isSplitMode: boolean): void {
    const aBoxFactor = isSplitMode ? 0.26 : 0.34;
    const h2Height = this.calcH2BoxHeight(isSplitMode);
    this.h2Box.height = h2Height;

    if (this.aBox.visible) {
      if (this.waveBox.visible) {
        const finalABoxHeight = Math.max((h2Height - 18) * aBoxFactor, 52);
        this.aBox.height = finalABoxHeight;
        this.waveBox.height = h2Height - finalABoxHeight;
      } else {
        this.aBox.height = h2Height;
        this.waveBox.height = 0;
      }
    } else {
      this.aBox.height = 0;
      this.waveBox.height = h2Height;
    }

    this.h2Box.flexShrink = h2Height <= 128 ? 0 : 1;
  }

  /**
   * 计算窄屏布局
   * 1. 全屏、2/3屏
   * 2. 1/2屏
   * 3. 1/3屏 -- 小折叠
   */
  private calcNarrowScreenLayout(): void {
    this.actionBarBox.visible = true;

    const bp = flexBox.getNarrowScreenHeightBreakpoint(this.h1);
    if (bp === flexBox.HeightBreakpoint.LG) {
      this.h2Box.visible = true;
      this.aBox.visible = true;
      this.waveBox.visible = true;
      this.translateTextBox.visible = this.translateTextVisible();
      this.markListBox.visible = this.markList.content.totalCount() > 0;
      this.progressBarBox.visible = true;
    } else if (bp === flexBox.HeightBreakpoint.MD) {
      this.translateTextBox.visible =
        DeviceUtil.isSmallFoldVer() && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED ?
          false : this.translateTextVisible();
      this.h2Box.visible = !this.translateTextBox.visible;
      this.aBox.visible = this.h2Box.visible;
      this.waveBox.visible = this.h2Box.visible;
      this.markListBox.visible = false;
      this.progressBarBox.visible = true;
    } else if (bp === flexBox.HeightBreakpoint.SM) {
      this.h2Box.visible = true;
      this.aBox.visible = true;
      this.waveBox.visible = false;
      this.translateTextBox.visible = false;
      this.markListBox.visible = false;
      this.progressBarBox.visible = false;
    }

    if (this.translateTextBox.visible) {
      this.progressTimeMaxFontSize = mainTitleFontSize.min;
      this.durationTimeMaxFontSize = subTitleFontSize.min;
    } else {
      this.progressTimeMaxFontSize = narrowScreenMainTitleMaxFontSize[bp];
      this.durationTimeMaxFontSize = narrowScreenSubTitleMaxFontSize[bp];
    }

    this.h2Box.margin = { top: 8 };
    this.translateTextBox.margin = { top: this.h2Box.visible ? 12 : 8 };
    this.progressBarBox.margin = { top: 12 };
    this.actionBarBox.margin = { top: 12 };
  }

  /**
   * 计算宽屏布局
   * 1. 全屏、2/3屏
   * 2. 1/2屏
   * 3. 1/3屏
   */
  private calcWideScreenLayout(): void {
    this.actionBarBox.visible = true;
    this.h2Box.margin = { top: 16 };

    this.translateTextBox.visible = this.translateTextVisible();

    const bp = flexBox.getWideScreenHeightBreakpoint(this.h1);
    if (bp === flexBox.HeightBreakpoint.LG) {
      this.h2Box.visible = true;
      this.aBox.visible = true;
      this.waveBox.visible = true;
      this.markListBox.visible = this.markList.content.totalCount() > 0;
      this.progressBarBox.visible = true;
      this.progressBarBox.margin = { top: 40 };
      this.actionBarBox.margin = { top: 48 };
    } else if (bp === flexBox.HeightBreakpoint.MD) {
      this.h2Box.visible = true;
      this.aBox.visible = true;
      this.waveBox.visible = true;
      this.markListBox.visible = this.markList.content.totalCount() > 0;
      this.progressBarBox.visible = true;
      this.progressBarBox.margin = { top: 20 };
      this.actionBarBox.margin = { top: 24 };
    } else if (bp === flexBox.HeightBreakpoint.SM) {
      this.h2Box.visible = !this.translateTextBox.visible;
      this.aBox.visible = this.h2Box.visible;
      this.waveBox.visible = this.h2Box.visible;
      this.markListBox.visible = false;
      this.progressBarBox.visible = true;
      this.progressBarBox.margin = { top: 12 };
      this.actionBarBox.margin = { top: 12 };
    }

    if (this.translateTextBox.visible) {
      this.progressTimeMaxFontSize = mainTitleFontSize.min;
      this.durationTimeMaxFontSize = subTitleFontSize.min;
    } else {
      this.progressTimeMaxFontSize = wideScreenMainTitleMaxFontSize[bp];
      this.durationTimeMaxFontSize = wideScreenSubTitleMaxFontSize[bp];
    }

    this.translateTextBox.margin = { top: this.h2Box.visible ? 12 : 16 };
  }

  /**
   * 计算 h2 高度
   * @returns
   */
  private calcH2BoxHeight(isSplitMode: boolean): number {
    if (this.translateTextBox.visible) {
      return 128;
    }
    const fixedBoxes = [this.markListBox, this.progressBarBox, this.actionBarBox];
    const fixedBoxHeight = fixedBoxes.reduce((result, curBox) => result + flexBox.getLayoutHeight(curBox), 0);
    const h2BoxMarginTop = this.h2Box.margin?.top ?? 0;
    const statusBarHeight = isSplitMode ? this.statusBarHeight : 0;
    return this.h1 - statusBarHeight - this.titleHeight - h2BoxMarginTop - fixedBoxHeight - this.offsetBottom;
  }

  private translateTextVisible(): boolean {
    return this.recordTransState || this.focusRecord.tranState === 1 || this.focusRecord.tranState === 2;
  }

  onFoldModeChange() {
    if (this.foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_FULL ||
      this.foldDisplayMode === 5 || !DeviceUtil.isTripleFoldFStatus()) {
    } else {
      // 退出
      LogUtil.info(TAG + ' onFoldModeChange to : ' + this.foldDisplayMode);
      if (this.isSmallFoldVer && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) {
        return;
      }
      this.isExistRecordPlayPage = true;
    }
  }

  private getPx(vpValue: number): string {
    return `${vpValue * this.defaultDP}px`;
  }

  private onExistRecordPlayPageChange(): void {
    if (this.isExistRecordPlayPage) {
      LogUtil.info(TAG + ' exist record play page.');
      this.isShowRecordPlay = false;
      this.pathStack.pop(false);
      this.waveCommand = WaveCommand.STOP;
    }
  }

  private handleStateIsIdle(): void {
    if (this.isExistRecordPlayPage) {
      LogUtil.info(TAG + ' handleStateIsIdle exist record play page.');
      AppStorage.setOrCreate(CommonConstants.CURRENT_FOCUS_RECORD, this.focusRecord);
      this.isExistRecordPlayPage = false;
    }
    this.waveCommand = WaveCommand.PAUSE;
  }

  private handleStateIsPlaying(): void {
    this.isAudioCompleted = false;
    this.updateMarkOpacity();
    if (this.canvasIsReady) {
      this.canvasIsReady = false;
    }
  }

  private handleStateIsPrepared(): void {
    // 两种情况的查询标记：1、split分栏模式不走aboutToApper 2、半模态播放其他音频时，通话录音跳转
    LogUtil.info(TAG + ' prepared to play new record, query mark for: ' +
      AnonymousUtil.anonymous(this.focusRecord.title));
    this.recordPlayMarkListHeightOpen = false;
    this.queryMarkList();

    if (this.needInitElapsedTime) {
      LogUtil.info(TAG + ' recover play time before rename: ' + this.playTimeBeforeRename);
      PlayManager.getInstance().seek(this.playTimeBeforeRename);
      this.currentTimePlay = this.playTimeBeforeRename;
      this.needInitElapsedTime = false;
    }
  }

  private handleStateIsCompleted(): void {
    this.isAudioCompleted = true;
    this.updateMarkOpacity();
  }

  private syncDbEndCallback = async (focusRecord: RecordData) => {
    LogUtil.info(TAG + ' sync db success.');
    // after create a new record from RecordingPage and back index page, default select it.
    this.focusRecord = focusRecord;
    if (this.navMode === NavigationMode.Split && this.focusRecord) {
      LogUtil.info(TAG + ' navMode is split, notify RecordPlayPage to play: ' +
        AnonymousUtil.anonymous(this.focusRecord.title));
      this.focusRecord.isNeedPlay = false;
      PlayManager.getInstance().setDataSource('syncDbEnd', this.focusRecord);
    }
  }

  private checkCanInsertMark(): boolean {
    // 播放完成后不允许添加标记
    if (this.isAudioCompleted) {
      return false;
    }
    if (this.markList.content.getAll().length === 0) {
      this.validMarkIndex = 0;
      return true;
    }

    if (this.currentTimePlay < this.markList.content.getData(0).markDuration - 1000) {
      this.validMarkIndex = 0;
      return true;
    }

    if (this.markList.content.getData(this.markList.content.getAll().length - 1).markDuration + 1000 <
      this.currentTimePlay && this.currentTimePlay <
      this.focusRecordDuration) {
      this.validMarkIndex = this.markList.content.getAll().length;
      return true;
    }

    for (let i = 0, j = i + 1; j < this.markList.content.getAll().length; i++, j++) {
      if (this.markList.content.getData(i).markDuration + 1000 < this.currentTimePlay &&
        this.currentTimePlay < this.markList.content.getData(j).markDuration - 1000) {
        this.validMarkIndex = j;
        return true;
      }
    }
    return false;
  }

  private updateMarkOpacity(): void {
    this.markOpacity = this.checkCanInsertMark() ? 1 : 0.4;
  }

  private async updatePlaySpeedAndOutputDevice() {
    const speedList = this.playSpeedNumberList;
    const currentPlaySpeedIndex = speedList.indexOf(this.speed);
    this.speedIcon = this.playSpeedIconList[currentPlaySpeedIndex];
    LogUtil.info(TAG + ' play speed: ' + this.speed);
  }

  /* instrument ignore next */
  private onsideFolderNameFlagChange() {
    LogUtil.info(TAG + ' onSideFolderNameFlagChange.');
    if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
      this.markButton.enabled = false;
      this.speedButton.enabled = false;
    } else {
      this.markButton.enabled = this.markOpacity === 1;
      this.speedButton.enabled = true;
    }
  }

  private onFocusRecordChanged(): void {
    LogUtil.info(TAG + ` onFocusRecordChanged ` + AnonymousUtil.anonymous(this.focusRecord.name));
    // 重命名标识符，由于重命名会反复多次进入此方法，故加上时延取消重命名标识
    if (this.isRenameFlag) {
      let timeOutId = setTimeout(() => {
        this.isRenameFlag = false;
        clearTimeout(timeOutId);
      }, 200)
      return;
    }
    if (DeviceUtil.isPhoneNotFold() ||
      (this.lastDate === this.focusRecord.date && this.lastDuration === this.focusRecord.duration &&
        this.lastName === this.focusRecord.name)) {
      LogUtil.error(TAG + ` onFocusRecordChanged Duration: ` + this.focusRecord.duration +
        ' lastDuration: ' + this.lastDuration);
      return;
    }
    this.lastDate = this.focusRecord.date;
    this.lastDuration = this.focusRecord.duration;
    this.lastName = this.focusRecord.name;
    this.lastIndex = this.focusRecord.index;
    this.jsonObject = null;
    this.recordTagsDone = false;
    this.wantParametersDone = false;
    this.transferData = undefined;
    this.recordTransState = (this.focusRecord.tranState === 1 || this.focusRecord.tranState === 2) ? true : false;
    this.transImageOpacity = this.recordTransState ? 0 : 1;
    this.transOpacity = this.recordTransState ? 0 : 1;
    this.speed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
    this.updatePlaySpeedAndOutputDevice();
    this.want = {
      bundleName: 'com.hmos.vassistant',
      abilityName: 'RecordTransAbility',
      parameters: {
        'ability.want.params.uiExtensionType': 'sys/commonUI',
        'recordId': 'recordId',
        'recordDuration': this.focusRecordDuration,
        'type': 'recordTranscriptionSceneSelect'
      }
    }
    this.recordTags = [];
  }

  /**
   * 保存标记数据（退出页面时，重命名录音前，重命名录音后，播放新录音时）
   *
   * @param item 标记需要保存在哪个录音文件，如果为null，
   * @param shouldClearOld 是否应该清空旧数据（退出页面、播放新录音时需要清空，其他清空不需要清空）
   */
  private async saveMarkData(item: RecordData | null = null, shouldClearOld: boolean) {
    LogUtil.info(TAG + ' exit record play page and save mark data. markList length=' +
      this.markList.content.getAll().length);
    let recordItem: RecordData = item === null ? this.focusRecord : item;
    if (this.inMarkQuery) {
      LogUtil.info(TAG + ': saveMarkData skip inMarkQuery.');
      return;
    }
    let markBucket = this.markList.content.getAll().map(item => {
      let mark: relationalStore.ValuesBucket = {
        'type': 1,
        'time_in_session': item.markDuration,
        'content': item.title,
        '_data': recordItem._data,
        'countNum': item.count,
      }
      return mark;
    });
    if (shouldClearOld && !this.isExistRecordPlayPage) {
      LogUtil.info(TAG + ': saveMarkData and clear old markList.');
      this.markList.content.deleteAll();
      this.markList.content.reload();
    }
    let count = await DatabaseManager.batchInsertTag(recordItem._data, markBucket);
    LogUtil.info(TAG + ' save mark data success, count: ' + count);
  }

  onMarkListChanged(): void {
    // 如果是新添加的标记，可以立即执行更新操作，因为他场景单一，不会使MarkList频繁更新
    LogUtil.info(`${TAG} onMarkListChanged list length: ${this.markList.content.getAll().length}`);
    this.calcLayout();
  }

  onMarkOpacityChanged() {
    this.markButton.enabled =
      (this.markOpacity === 1 && this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS);
  }

  onSpeedChanged() {
    switch (this.speed) {
      case this.playSpeedNumberList[0]:
        this.speedButton.baseIcon = this.playSpeedIconList[0]
        break;
      case this.playSpeedNumberList[1]:
        this.speedButton.baseIcon = this.playSpeedIconList[1]
        break;
      case this.playSpeedNumberList[2]:
        this.speedButton.baseIcon = this.playSpeedIconList[2]
        break;
      case this.playSpeedNumberList[3]:
        this.speedButton.baseIcon = this.playSpeedIconList[3]
        break;
      default:
        break;
    }
    this.speedButton.accessibilityText = this.playSpeedMap[this.speed ?? 1].toString()
      .concat(getContext().resourceManager.getStringSync($r('app.string.speed_play')));
  }

  onDarkModeChange(): void {
    LogUtil.info(`${TAG} onDarkModeChange isDarkMode : ${this.isDarkMode}`);
    this.playPauseButton.iconFillColor = ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary'))
    this.markButton.iconFillColor = ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary'))
    this.speedButton.iconFillColor = ColorMetrics.resourceColor($r('sys.color.ohos_id_color_primary'))
    this.playPauseButton.backgroundColor =
      this.isDarkMode ? ColorMetrics.resourceColor($r('sys.color.ohos_id_color_button_normal')) :
        ColorMetrics.resourceColor($r('sys.color.interactive_click'));
  }

  onScreenLockChange(): void {
    LogUtil.info(TAG + ' screenStateChange, isScreenLock=' + this.isScreenLock);
    if (!this.isScreenLock && this.isSmallFoldVer &&
      this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) {
      this.renameDialogController.close();
      getContext().eventHub.emit('detailDialogClose');
    }
  }

  clearWaveTimer() {
    this.waveCommand = WaveCommand.RESET;
  }

  @Builder
  ShareMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.voice_share') })
        .padding({ left: 16 })
        .onClick(() => {
          this.showShareModal();
        })
        .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
      MenuItem({ content: $r('app.string.file_rename') })
        .padding({ left: 16 })
        .onClick(async () => {
          LogUtil.info(TAG + ': save old data before rename - saveMarkData');
          this.renameDialogController.open()
          HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TRACK_ON_PLAYING)
        })
        .enabled(this.transferData?.state !== 0 && this.transferData?.state !== 1)
        .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
        .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
      MenuItem({ content: $r('app.string.delete') })
        .padding({ left: 16 })
        .onClick(() => {
          getContext(this).eventHub.emit('openDeleteDialog', 'playPageDelete');
          HiSysEventUtil.eventDotting(HiSysEventName.DELETE_TRACK_ON_PLAYING)
        })
        .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
        .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
      MenuItem({ content: $r('app.string.voice_retail') })
        .padding({ left: 16 })
        .onClick(() => {
          try {
            this.detailRecord = this.focusRecord;
            getContext().eventHub.emit('detailDialogOpen');
            HiSysEventUtil.eventDotting(HiSysEventName.ENTER_ABOUT_PAGE_ON_PLAYING, { VALUE: CommonConstants.SUCCESS });
          } catch (e) {
            HiSysEventUtil.eventDotting(HiSysEventName.ENTER_ABOUT_PAGE_ON_PLAYING, { VALUE: CommonConstants.FAILURE })
          }
        })
        .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
        .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
    }
    .menuItemDivider(DeviceUtil.isPC() ? undefined : {
      color: $r('sys.color.comp_divider'),
      strokeWidth: LengthMetrics.px(1),
      endMargin: LengthMetrics.vp(16),
      startMargin: LengthMetrics.vp(16),
    })
    .width(MENU_DEFAULT_WIDTH)
    .borderRadius(DeviceUtil.isPC() ? $r('sys.float.corner_radius_level4') : undefined)
  }

  async displayChangeCallback(): Promise<void> {
    try {
      this.isSplitStatus = await DeviceUtil.isSplitStatus();
    } catch (error) {
      LogUtil.error(TAG + ' displayChangeCallback failed.');
    }
  }

  private addDisplayChangeListener(): void {
    try {
      display.on('change', this.displayChangeCallback);
    } catch (err) {
      LogUtil.error(`${TAG} failed on display change event, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  private removeDisplayChangeListener(): void {
    try {
      display.off('change', this.displayChangeCallback);
    } catch (err) {
      LogUtil.error(`${TAG} failed off display change event, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  async aboutToAppear() {
    this.addDisplayChangeListener();
    AppStorage.setOrCreate('jumpFromSceneBoard', false);
    this.recordTransState = (this.focusRecord.tranState === 1 || this.focusRecord.tranState === 2) ? true : false;
    this.recordPlayMarkListHeightOpen = false;
    this.transImageOpacity = this.recordTransState ? 0 : 1;
    this.transOpacity = this.recordTransState ? 1 : 0;
    this.want = {
      bundleName: 'com.hmos.vassistant',
      abilityName: 'RecordTransAbility',
      parameters: {
        'ability.want.params.uiExtensionType': 'sys/commonUI',
        'recordId': 'recordId',
        'recordDuration': this.focusRecordDuration,
        'type': 'recordTranscriptionSceneSelect'
      }
    }
    const player = PlayManager.getInstance();
    LogUtil.info(TAG + ' aboutToAppear player state : ' + player.getAVPlayerState());

    let params: Record<string, number | RecordData | string> =
      this.pathStack.getParamByName('recordPlay')[0] as Record<string, number | RecordData | string>;
    if (player.getAVPlayerState() === 'idle' && this.navMode === NavigationMode.Split) {
      LogUtil.info(TAG + ' aboutToAppear params.focusRecord : ' + AnonymousUtil.anonymous(this.focusRecord.name));
      if (this.focusRecord?._data === '' && !this.loading) {
        this.focusRecord = await PreferencesUtil.get('focusRecord', new RecordData()) as RecordData;
      }
      this.focusRecord.isNeedPlay = false;
      this.currentTimePlay = params?.currentTimePlay as number;
      this.tranState = params?.tranState as number;
      player.setDataSource('recordPlayPageAboutToAppear', this.focusRecord);
    }
    // 开启播放长时任务
    this.queryMarkList();
    getContext()?.eventHub?.on('changeFocus', this.changeFocusCallback);
    getContext().eventHub.on('syncDbEnd', this.syncDbEndCallback);
    getContext(this)?.eventHub?.on('setDurationCallback', this.setDurationCallback);
    this.updatePlaySpeedAndOutputDevice();
    getContext().eventHub.on('backPressed', () => {
      LogUtil.info(`${TAG} Navigation onBackPressed.`);
      if (this.navMode === NavigationMode.Stack) {
        this.isExistRecordPlayPage = true;
        player.reset();
      } else {
        player.pause()
      }
      // if true, go back to index, otherwise go back to desktop
      return this.navMode === NavigationMode.Stack;
    });
  }

  aboutToDisappear() {
    LogUtil.info(TAG + ' aboutToDisappear. ');
    this.isShowDigest = false;
    getContext()?.eventHub?.off('syncDbEnd', this.syncDbEndCallback);
    getContext()?.eventHub?.off('backPressed');
    getContext(this)?.eventHub?.off('setDurationCallback', this.setDurationCallback);
    getContext(this)?.eventHub?.off('changeFocus', this.changeFocusCallback);
    this.clearWaveTimer();
    this.removeDisplayChangeListener();

    this.unsetDurationCallback();
  }

  /* instrument ignore next */
  private unsetDurationCallback() {
    PlayManager.getInstance().unsetDurationCallback(TAG);
    // 折叠机从展开到收起，新页面的onAppear执行在旧页面的aboutToDisappear之后，导致新页面设置的durationCallback被清空
    // 此处就页面销毁时发送setDurationCallback事件，保证新页面执行durationCallback不为空
    getContext(this)?.eventHub?.emit('setDurationCallback', this.setDurationCallback);
  }

  private onPlaybackStateChange() {
    this.speed = AppStorage.get(CommonConstants.CURRENT_SPEED) as number;
    LogUtil.info(TAG + ' onPlaybackStateChange in recordPlayPage, state : ' + this.state + ', speed : ' + this.speed);
    this.playPauseButton.baseIcon = (this.state === 'playing') ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill')
    if (this.state === 'idle') {
      this.handleStateIsIdle();
    }

    if (this.state === 'playing') {
      this.handleStateIsPlaying();
    }

    if (this.state === 'completed') {
      this.handleStateIsCompleted();
    }

    if (this.state === 'prepared') {
      this.handleStateIsPrepared();
    }
    if (this.state === 'paused') {
      this.waveCommand = WaveCommand.PAUSE;
    } else if (this.state === 'playing') {
      this.waveCommand = WaveCommand.START;
    } else if (this.state === 'prepared') {
      this.waveCommand = WaveCommand.MARK;
    } else {
      this.waveCommand = WaveCommand.STOP;
    }
    this.playPauseButton.accessibilityText = this.getPlayStatusText();
    this.playPauseButton.hoverTips = this.getPlayStatusText();
  }

  private changeFocusCallback = (item: RecordData) => {
    this.focusRecord = item || new RecordData();
  }

  private async checkSharedFilePath(): Promise<void> {
    if (!this.transferData) {
      LogUtil.error(TAG + ` checkSharedFilePath error: transferData is undefined`);
      return;
    }
    let sharedFilePath = this.transferData.fileUri;
    let sharedFileName = sharedFilePath.substring(sharedFilePath.lastIndexOf('/') + 1);
    let transId: string = await DatabaseManager.getTransId(this.focusRecord._data);
    let fileName: string = transId + ConfigData.FileType;
    if (sharedFileName !== fileName) {
      LogUtil.info(TAG + ` checkSharedFilePath failed, shared file path not equal focus record path. `);
      let transferDataId = util.generateRandomUUID(true);
      let sharedFilePath = this.getSharedUuidPath(transferDataId);
      try {
        fs.copyFileSync(this.focusRecord._data, sharedFilePath);
        let sharedFileUri = fileUri.getUriFromPath(sharedFilePath);
        if (sharedFileUri.indexOf('*') > -1) {
          // 不支持授权到带*的路径，其一是文件名不支持带*，其二是授权到*可能会导致权限放大
          LogUtil.info(`${TAG} grantUriPermission fail, can not grant file has *`);
          return;
        }
        await uriPermissionManager.grantUriPermission(sharedFileUri,
          wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION |
            wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION,
          XIAOYI_BUNDLE);
        this.transferData.fileUri = sharedFileUri;
        await DatabaseManager.updateTransferData(this.transferData);
      } catch (e) {
        LogUtil.info(TAG + ` checkSharedFilePath error ` + e);
      }
    }
  }

  async queryMarkList() {
    if (this.isSearchMode) {
      HiSysEventUtil.eventDotting(HiSysEventName.SEARCH_TAP_RESULT);
    } else {
      // 从列表进入播放录音页面的时延
      let startTime: number = this.focusRecord.jumpRecordPlayPageTime === 0
        ? new Date().getTime() : this.focusRecord.jumpRecordPlayPageTime;
      const time: number = new Date().getTime() - startTime;
      HiSysEventUtil.eventDotting(HiSysEventName.DIRECTION_VIEW,
        { VALUE: DFXEnumConstants.EnterRecordPlayWays.IN_APP, DURATION: time }
      );
      HiSysEventUtil.eventDotting(HiSysEventName.RECORD_LIST_ITEM_CLICKED, { DURATION: time });
    }
    this.updateMarkList();
  }

  async updateMarkList() {
    const _data = this.focusRecord._data;
    this.inMarkQuery = true;
    let arr = await DatabaseManager.queryTagByRecord(_data);
    this.markList.content.updateAllData(arr)
    if (arr.length > 0) {
      this.recordPlayMarkListHeightOpen = true;
    }
    LogUtil.info(TAG + ` this.markList.content length：` + this.markList.content.getAll().length);
    this.inMarkQuery = false;
    this.updateMarkOpacity();
    this.recordTags = [];
    this.markList.content.getAll().forEach(ele => {
      let recordTag = {
        milliseconds: ele.markDuration.toString(),
        taggedText: ele.count.toString()
      } as RecordTag;
      this.recordTags.push(recordTag);
    });
    this.want.parameters!.recordTags = this.recordTags;
    this.recordTagsDone = true;
    if (this.recordTransState && this.wantParametersDone) {
      animateTo({
        duration: 150,
        curve: Curve.Sharp,
      }, () => {
        this.transImageOpacity = 0;
      })
      animateTo({
        delay: 100,
        duration: 300,
        curve: Curve.Sharp,
      }, () => {
        this.transOpacity = 1;
      })
    }
    LogUtil.info(TAG + ` this.recordTagsDone:${this.recordTagsDone}`)
  }

  // 拖动波形图后触发父组件方法执行
  onWaveMove() {
    PlayManager.getInstance().seek(this.waveMoveTime)
  }

  // 分享弹框
  showShareModal() {
    const anchor = this.getUIContext().getComponentUtils().getRectangleById('evenMore');
    const shareModalParams: ShareModalParams = {
      context: getContext(this) as common.UIAbilityContext,
      srcData: [this.focusRecord],
      eventName: HiSysEventName.SHARE_MENU
    };
    ShareUtil.showModal(shareModalParams);
  }

  renameDialogController: CustomDialogController = new CustomDialogController({
    builder: RenameDialog({
      confirmCallback: async (inputValue: string) => {
        if (!this.focusRecord) {
          LogUtil.error(TAG + ' rename failed, focusRecord is null.');
          return;
        }
        const player = PlayManager.getInstance();
        player.pause();
        this.needInitElapsedTime = (this.state === 'completed' ? false : true);
        this.playTimeBeforeRename = player.getAVPlayerCurrentPlayTime();
        this.recordDataBeforeRename = this.focusRecord;
        const indexForPoint = this.recordDataBeforeRename.title.lastIndexOf('.');
        const fileType = this.recordDataBeforeRename.title.substring(indexForPoint);
        let newRecord: RecordData[];
        newRecord = this.focusRecord.phoneNumber ?
          await DatabaseManager.getCallRecordDataFromDb('title', inputValue) :
          await DatabaseManager.getNormalRecordDataFromDb('title', inputValue + fileType);
        if (newRecord.length === 0) {
          LogUtil.info(TAG + ' rename ' + AnonymousUtil.anonymous(this.focusRecord.name) + ' failed.');
          AuditLogManager.getInstance().renameAuditLog('FAIL');
          this.renameDialogController.close();
          return;
        }
        AuditLogManager.getInstance().renameAuditLog('SUCCESS');
        LogUtil.info(TAG + ': confirmCallback - saveMarkData');
        await this.saveMarkData(newRecord[0], false);
        this.isRenameFlag = true;
        this.focusRecord = newRecord[0];
        this.focusRecord.isNeedPlay = false;
        Util.showToast($r('app.string.renamed'), DeviceUtil.isPC());
        // 原本 updateIndexList 事件的发送，放在收到avPlayer的prepared状态后，
        // 但多次重命名时会偶现应用未收到 avPlayer prepared 状态的情况，
        // 导致重命名后的录音无法在列表中播放，所以将这部分逻辑放回 confirmCallback，确保每次重命名成功都会更新Index的录音列表
        getContext().eventHub.emit('updateIndexList', this.recordDataBeforeRename, this.focusRecord);
        getContext()
          .eventHub
          .emit('updateSearchResult', CommonConstants.UPDATE, newRecord, this.recordDataBeforeRename._data);
        player.updateCurrentPlayedRecordName(inputValue);
        let idInfo = ContactsManagerUtil.getInstance().addCallRecordPrefix(this.recordDataBeforeRename);
        HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TRACK_CONFIRM_ON_PLAYING, { FILEID: idInfo });
        this.renameDialogController.close();
      },
      recordBeforeRename: this.focusRecord
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    cornerRadius: DeviceUtil.isPC() ? $r('app.float.distance_16') : $r('app.float.distance_32'),
    customStyle: false,
  })

  @Builder
  NavDestinationTitleBar() {
    Column() {
      Text(this.focusRecord?.name || '')
        .fontColor($r('sys.color.ohos_id_color_titlebar_text'))
        .maxFontSize($r('sys.float.ohos_id_text_size_headline8'))
        .minFontSize('14fp')
        .fontWeight(FontWeight.Bold)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
        .flexGrow(1)
        .flexShrink(100)
        .margin({
          left: Configuration.getLocale().dir === 'ltr'
            ? ((this.navMode === NavigationMode.Stack && !DeviceUtil.isTabletOrTripleGStatus()) ||
              DeviceUtil.isExpanded() ?
              4 : $r('sys.float.ohos_id_max_padding_start')) : 0,
          right: Configuration.getLocale().dir === 'rtl'
            ? (this.navMode === NavigationMode.Stack && !DeviceUtil.isTabletOrTripleGStatus() ? 4 :
              $r('sys.float.ohos_id_max_padding_start')) : 0
        })
        .padding({
          left: Configuration.getLocale().dir === 'rtl' ? 16 : 0,
          right: Configuration.getLocale().dir === 'rtl' ? 0 : 16
        })
        .direction(Configuration.getLocale().dir == 'rtl' ? Direction.Rtl : Direction.Ltr)
        .id('plagPageRecordNameText')
        .maxFontScale(CommonConstants.TEXT_SIZE_LARGE)
    }
    .opacity(this.isWindowFocused || !DeviceUtil.isPC() ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
    .height(DeviceUtil.isExpanded() || DeviceUtil.isTabletOrTripleGStatus() ?
      (this.isSmallFoldVer ? $r('app.float.wh_value_64') : $r('app.float.wh_value_56')) :
      DeviceUtil.isPC() ? $r('app.float.wh_value_64') : $r('app.float.wh_value_40'))
    .margin({
      top: DeviceUtil.isExpanded() || DeviceUtil.isTabletOrTripleGStatus() || DeviceUtil.isPC() ?
        (this.isSmallFoldVer ? 8 : 0) :
        (this.displaySizeScale === CommonConstants.PAD_DISPLAY_SIZE_SCALE_LARGER ? this.getPx(16) : 16)
    })
    .justifyContent(FlexAlign.Center)
    .padding({
      left: Configuration.getLocale().dir === 'ltr' ? (DeviceUtil.isTablet() || DeviceUtil.isPC() ?
        CommonConstants.ZERO : $r('sys.float.ohos_id_default_padding_start')) :
        $r('sys.float.ohos_id_default_padding_end'),
      right: Configuration.getLocale().dir === 'rtl' ? (DeviceUtil.isTablet() || DeviceUtil.isPC() ?
        CommonConstants.ZERO : $r('sys.float.ohos_id_default_padding_start')) :
        $r('sys.float.ohos_id_default_padding_end'),
      top: DeviceUtil.isExpanded() && this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF ? 8 : 0
    })
    .visibility(this.isEditMode ? Visibility.None : Visibility.Visible)
  }

  private createLongPressDialog(iconRes: ResourceStr, label?: ResourceStr, isOnlyShowText: boolean = false): void {
    this.customDialogViewController = new CustomDialogController({
      builder: LongPressDialogView({
        cancel: () => {
        },
        confirm: () => {
        },
        iconItem: {
          iconRes: iconRes,
          isEnabled: true,
          label: label
        },
        textRes: label,
        isOnlyShowText: isOnlyShowText
      }),
      maskColor: Color.Transparent,
      isModal: true,
      customStyle: true
    })
  }

  @Styles
  gestureAttrsMore() {
    .gesture(
      LongPressGesture({ repeat: false, duration: CommonConstants.DEFAULT_LONG_PRESS_TIME })
        .onAction((event) => {
          if (event && (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2)) {
            this.createLongPressDialog($r('app.media.public_more'));
            this.customDialogViewController?.open();
          }
        })
    )
    .onTouch((event) => {
      if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.customDialogViewController?.close();
      }
    })
  }

  evenMoreMarginTop(): Length {
    if (DeviceUtil.isExpanded() && this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF) {
      return 8;
    }
    if (DeviceUtil.isExpanded() || DeviceUtil.isTabletOrTripleGStatus()) {
      return 0;
    }
    if (DeviceUtil.isPC()) {
      return $r('app.float.margin_size_12');
    }
    return $r('app.float.margin_size_16');
  }

  evenMoreMarginRight(): Length {
    if (DeviceUtil.isTablet()) {
      return $r('app.float.margin_size_24');
    }
    const offsetX = 5;
    if (DeviceUtil.isPC()) {
      if (this.isShowSideBar && this.curBp === 'lg') {
        // PC当navigation组件占用整个窗口的时候，navigation自动避让三键区域，否则需要应用自行避让三键区域
        const decorWidth = AppStorage.get<number>('decorWidth') || 0;
        // PC侧工具栏和三键区域左边距要满足16vp，在原有左边距12vp基础上加上5
        return decorWidth + offsetX;
      }
      return offsetX;
    }
    return $r('app.float.margin_size_16');
  }

  @Styles
  moreCommonAttr() {
    .width($r('app.float.distance_40'))
    .height($r('app.float.distance_40'))
    .accessibilityText(this.rsc.getStringSync($r('app.string.more_options')))
    .backgroundColor(DeviceUtil.isPC() ? Color.Transparent : $r('sys.color.comp_background_tertiary'))
    .borderRadius($r('sys.float.corner_radius_level4'))
    .onHover((isHover) => {
      HoverTextTipsUtil.showTipsTimer(isHover, (isHover) => {
        this.isMoreShowTips = isHover
      });
    })
    // 使更多按钮可以获取焦点
    .onClick(() => {
    })
    .bindPopup(this.isMoreShowTips && !this.isShowMenu, {
      builder: this.tipsViewBuilder($r('app.string.toolbar_more')),
      placementOnTop: false,
      enableArrow: false,
      popupColor: $r('sys.color.ohos_id_color_list_card_bg'),
      targetSpace: HoverTextTipsStyle.BIND_POPUP_TARGET_SPACE,
      mask: false,
      radius: $r('sys.float.corner_radius_level4'),
      shadow: HoverTextTipsUtil.getPopupShadow(),
      onStateChange: (event) => {
        if (!event.isVisible) {
          this.isMoreShowTips = false;
        }
      }
    })
  }

  @Builder
  navMenu() {
    Row() {
      Row() {
        if (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2) {
          Button({ type: DeviceUtil.isPC() ? ButtonType.Normal : ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontSize($r('app.float.wh_value_24'))
              .draggable(false)
              .width($r('app.float.wh_value_24'))
              .height($r('app.float.wh_value_24'))
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .gestureAttrsMore()
          .id('evenMore')
          .moreCommonAttr()
          .bindMenu(this.ShareMenu(), this.menuOptions())
          .visibility(this.isSmallFoldVer && this.foldDisplayMode === FoldStatus.FOLD_STATUS_FOLDED ?
            Visibility.None : Visibility.Visible)
        } else {
          Button({ type: DeviceUtil.isPC() ? ButtonType.Normal : ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontSize($r('app.float.wh_value_24'))
              .draggable(false)
              .width($r('app.float.wh_value_24'))
              .height($r('app.float.wh_value_24'))
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .id('evenMore')
          .moreCommonAttr()
          .bindMenu(this.ShareMenu(), this.menuOptions())
          .visibility(this.isSmallFoldVer && this.foldDisplayMode === FoldStatus.FOLD_STATUS_FOLDED ?
            Visibility.None : Visibility.Visible)
        }
        Button({ type: ButtonType.Circle, stateEffect: true }) {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize($r('app.float.wh_value_24'))
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            .draggable(false)
        }
        .id('backIconInNavDestinationTitleBar')
        .accessibilityText(getContext().resourceManager.getStringSync($r('app.string.detailDialog_close')))
        .width($r('app.float.distance_40'))
        .height($r('app.float.distance_40'))
        .margin({
          left: Configuration.getLocale().dir === 'ltr' ? $r('app.float.margin_size_8') : 0,
          right: Configuration.getLocale().dir === 'rtl' ? $r('app.float.margin_size_8') : 0
        })
        .visibility((this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF ||
          DeviceUtil.isPhoneNotFold() || this.isSmallFoldVer) ?
          ((this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF && DeviceUtil.isTabletOrTripleGStatus() &&
            DeviceUtil.isLandscape() && !this.isShowRecordPlay) || this.curBp === 'lg') ? Visibility.None :
            Visibility.Visible : Visibility.None)
        .backgroundColor($r('sys.color.comp_background_tertiary'))
        .onClick(() => {
          this.isShowRecordPlay = false;
          this.pathStack.pop(false);
          this.isExistRecordPlayPage = true;
          PlayManager.getInstance().reset();
        })
      }
      .accessibilityLevel('no')
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Center)
      .width((this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF ||
        DeviceUtil.isPhoneNotFold() || this.isSmallFoldVer) ?
        (this.isSmallFoldVer && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) ?
          $r('app.float.wh_value_48') :
          (this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF && DeviceUtil.isTabletOrTripleGStatus() &&
            DeviceUtil.isLandscape() && !this.isShowRecordPlay) ? $r('app.float.wh_value_40') :
            $r('app.float.wh_value_88') : $r('app.float.wh_value_40'))
      .height(DeviceUtil.isExpanded() || DeviceUtil.isTabletOrTripleGStatus() ?
        $r('app.float.wh_value_56') : $r('app.float.wh_value_40'))
      .bindMenu(this.ShareMenu(), this.menuOptions())
      .margin({
        top: this.isSmallFoldVer && DeviceUtil.isExpanded() ? 8 : this.evenMoreMarginTop(),
        left: Configuration.getLocale().dir === 'rtl' ? this.evenMoreMarginRight() : 0,
        right: this.evenMoreMarginRight()
      })
      .enabled(this.shouldEnableMenu())
      .opacity(!this.isWindowFocused && DeviceUtil.isPC() ? $r('sys.float.ohos_id_alpha_disabled') :
        this.shouldEnableMenu() ? 1 : 0.4)
      .visibility(this.isEditMode ? Visibility.None : Visibility.Visible)
    }
  }

  menuOptions(): MenuOptions {
    return {
      showInSubWindow: false,
      onAppear: () => {
        this.isShowMenu = true;
      },
      onDisappear: () => {
        this.isShowMenu = false;
      }
    }
  }

  @Builder
  tipsViewBuilder(name: ResourceStr) {
    TextTipsPopup({ promptText: name })
  }

  @Builder
  SelectedAudioRecordCountDisplayComponent() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center
    }) {
      Text($r('app.plural.selected_recording_plural', this.selectedRecordList.length, this.selectedRecordList.length))
        .fontSize('16vp')
        .fontColor($r('sys.color.ohos_id_color_text_hint'))
        .fontWeight(FontWeight.Medium)
        .lineHeight('21vp')
    }
  }

  // 菜单栏是否显示
  private shouldEnableMenu(): boolean {
    const focusRecordAvailable = this.focusRecord?._data !== '';
    const isInRecentDeleteTab = this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS;
    const isSplit = this.navMode === NavigationMode.Split;
    return isSplit ? focusRecordAvailable && !isInRecentDeleteTab : focusRecordAvailable;
  }

  private getPlayStatusText(): string {
    return this.state === 'playing' ? this.rsc.getStringSync($r('app.string.pause'))
      : this.rsc.getStringSync($r('app.string.play'));
  }

  private getSpeedBroadCastText(): string {
    let currentSpeed: number = this.playSpeedMap[this.speed ?? 1]; // 分栏状态冷启动，this.speed的值可能为undefined
    return currentSpeed.toString().concat(getContext().resourceManager.getStringSync($r('app.string.speed_play')));
  }

  private getCurrentTimeText(): string {
    return this.rsc.getStringSync($r('app.string.content_already_played'),
      AccessibilityUtil.getDurationText(this.currentTimePlay));
  }

  private async checkLogin(): Promise<boolean> {

    LogUtil.info(TAG + 'checkLogin skipped in open source build');
    return false;
  }

  private getTransResultJsonFilePath(): string {
    let recordFileName = this.focusRecord._data.substring(this.focusRecord._data.lastIndexOf('/') + 1);
    let jsonFileName = recordFileName.substring(0, recordFileName.lastIndexOf('.')) + '.json';
    let sanboxPath = this.getTransResultSanboxPath();
    let jsonfilePath = sanboxPath + '/' + jsonFileName;
    return jsonfilePath;
  }

  private getTransResultSanboxPath(): string {
    if (this.focusRecord.phoneNumber) {
      return getContext(this).filesDir + PathUtil.CALLRECORD_SANBOX_FILEPATH;
    } else {
      return getContext(this).filesDir;
    }
  }

  private getSharedUuidPath(transferDataId: string): string {
    let jsonfilePath = getContext(this).distributedFilesDir + '/' + transferDataId + '.m4a';
    return jsonfilePath;
  }

  @Builder
  UnTransferExtensionComponent() {
    UIExtensionComponent(
      this.want
    )
      .size({ width: '100%', height: '100%' })
      .onReceive(async (data: Record<string, Object>) => {
        LogUtil.info(TAG + ` onReceive start`);
        if (data.event as string === 'transcription.start') {
          HiSysEventUtil.eventDotting(HiSysEventName.TEXT_START_TRANSCRIPTION);
          this.transcriptionTime = new Date().getTime();
          let transferDataId = util.generateRandomUUID(true);
          let sharedAudioFilePath = this.getSharedUuidPath(transferDataId);
          fs.copyFileSync(this.focusRecord._data, sharedAudioFilePath);
          let uri = fileUri.getUriFromPath(sharedAudioFilePath);
          let jsonFilePath = this.getTransResultJsonFilePath();
          let file: fs.File | null = null;
          try {
            FileUtil.mkdirIfNotExists(this.getTransResultSanboxPath());
            if (!fs.accessSync(jsonFilePath)) {
              file = fs.openSync(jsonFilePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
              fs.copyFileSync(file.fd, jsonFilePath);
            } else {
              file = fs.openSync(jsonFilePath, fs.OpenMode.READ_WRITE);
              DatabaseManager.removeTransferData([this.focusRecord._data]);
            }
            let jsonFileUri = await Util.getSharePathUri(jsonFilePath);
            const scene = data.scene as Record<string, string>;
            this.want.parameters!.type = 'recordTranscriptionsStart';
            this.want.parameters!.scene = scene.name;
            this.want.parameters!.recordFile = uri;
            this.want.parameters!.transcribeUri = jsonFileUri;
            this.want.parameters![wantConstant.Params.PARAMS_STREAM] = [uri, jsonFileUri];
            this.want.flags = wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION |
              wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION |
              wantConstant.Flags.FLAG_AUTH_PERSISTABLE_URI_PERMISSION;
            LogUtil.info(TAG + `recordTranscriptionsStart want.`)
            this.transferData = {
              id: transferDataId,
              recordPath: this.focusRecord._data,
              sessionId: '',
              fileUri: uri,
              domain: scene.name,
              state: 0,
              createTime: new Date().getTime(),
              jsonPath: '',
              sourceType: 0,
              incomplete: 0
            } as TransferData;
            await DatabaseManager.saveTransferData(this.transferData);
          } catch (err) {
            LogUtil.error(TAG + `fail to grant uri permission: code: ${err.code}, message: ${err.message}`);
            if (file !== null) {
              fs.closeSync(file);
            }
          } finally {
            if (file !== null) {
              fs.closeSync(file);
            }
          }
        }
        if (data.event as string === 'transcription.cancel' ||
          data.event as string === 'transcription.privacy.disagree') {
          if (this.focusRecord.tranState === CommonConstants.TRANS_DONE) {
            this.wantParametersDone = false;
            this.wantParametersDone = true;
            return;
          }
          this.recordTransState = false;
          this.transImageOpacity = 1;
          this.transOpacity = 0;
          this.want = {
            bundleName: 'com.hmos.vassistant',
            abilityName: 'RecordTransAbility',
            parameters: {
              'ability.want.params.uiExtensionType': 'sys/commonUI',
              'recordId': 'recordId',
              'recordDuration': this.focusRecordDuration,
              'type': 'recordTranscriptionSceneSelect',
              'recordTags': this.recordTags
            }
          }
          this.transferData = undefined;
        }
      })
      .onError((err) => {
        LogUtil.error(`${TAG} recordTranscriptionSceneSelect onError, code: ${err.code}, message: ${err.message}`);
        this.isShowLoadingProgress = false;
      })
      .onRemoteReady(() => {
        LogUtil.warn(`${TAG} UnTransferExtensionComponent onRemoteReady success`);
        this.isShowLoadingProgress = false;
      })
      .onAppear(() => {
        LogUtil.warn(`${TAG} UnTransferExtensionComponent onAppear`);
      })
      .onDisAppear(() => {
        LogUtil.warn(`${TAG} UnTransferExtensionComponent onDisAppear recordTransState: ${this.recordTransState}
        ,wantParametersDone: ${this.wantParametersDone}, recordTagsDone: ${this.recordTagsDone}`);
      })
  }

  private processSpeedClick() {
    // 默认1倍速，点击变为1.5倍速图，点击变为2倍速图，点击变为0.5倍速图
    const speedList = this.playSpeedNumberList;
    const currentPlaySpeedIndex = speedList.indexOf(this.speed);
    const newPlaySpeedIndex = currentPlaySpeedIndex == speedList.length - 1 ? 0 : currentPlaySpeedIndex + 1;
    const newPlaySpeed = speedList[newPlaySpeedIndex];
    this.speed = newPlaySpeed;

    const speedIconList = this.playSpeedIconList;
    const newSpeedIcon = speedIconList[newPlaySpeedIndex];
    this.speedIcon = newSpeedIcon;
    let currentSpeed: number = this.playSpeedMap[this.speed ?? 1];
    let eventName: string = (this.recordTransState && this.transferData) ?
      HiSysEventName.TEXT_MULTIPLE_SPEED : HiSysEventName.MULTIPLE_SPEED
    PlayManager.getInstance().setSpeed(this.speed).then((value) => {
      LogUtil.info(TAG + ' The speed is set successfully.');
      let result = (value === CommonConstants.SUCCESS) ? CommonConstants.SUCCESS : CommonConstants.FAILURE;
      HiSysEventUtil.eventDotting(eventName,
        { VALUE: currentSpeed, SUCCESS: result }
      );
    }).catch((err: BusinessError) => {
      LogUtil.info(TAG + ` Failed to set the speed. The failure message is: ${err?.code}, msg: ${err?.message}`);
      HiSysEventUtil.eventDotting(eventName,
        { VALUE: currentSpeed, SUCCESS: CommonConstants.FAILURE }
      );
    });
    AccessibilityUtil.sendAnnounceAccessibilityEvent(this.getSpeedBroadCastText());
  }

  //是否直板机或者小折叠XX 分屏
  isWidthHalfVerOrbar(): boolean {
    return this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF &&
      (DeviceUtil.isBarPhone() || this.isSmallFoldVer);
  }

  @Builder
  BackGroundComponent() {
    Flex({
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.Center,
      alignItems: ItemAlign.Center
    }) {
      Column() {
        Image($r('app.media.no_more'))
          .matchTextDirection(Configuration.getLocale().dir == 'rtl' ? true : false)
          .draggable(false)
          .objectFit(ImageFit.Contain)
      }.width(120)
      .height(120)

      Text($r('app.string.no_records')).fontSize(14).margin({ top: 16 }).fontColor($r('app.color.text_colors'))
    }
  }

  @Builder
  MainContent() {
    Flex({
      wrap: FlexWrap.NoWrap,
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.SpaceBetween
    }) {
      // h2
      Flex({ wrap: FlexWrap.NoWrap, direction: FlexDirection.Column, justifyContent: FlexAlign.Center }) {
        this.ASection()

        this.WaveSection()
      }
      .borderRadius(16)
      .backgroundColor($r('sys.color.comp_background_list_card'))
      .clip(true)
      .width('100%')
      .height(this.h2Box.height)
      .margin(this.h2Box.margin)
      .flexShrink(this.h2Box.flexShrink)
      .visibility(this.h2Box.visible ? Visibility.Visible : Visibility.None)

      // mark list
      this.MarkList()

      // process bar
      this.ProcessBar()

      // action bar
      this.ActionBar()
    }
    .width('100%')
    .clip(true)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  ASection() {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.Center,
    }) {
      Flex({
        wrap: FlexWrap.NoWrap,
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Center,
        alignItems: ItemAlign.Center
      }) {
        // progress time
        Text(Util.timeFormatMs(this.currentTimePlay || 0))
          .baselineOffset(0)
          .maxLines(1)
          .maxFontSize(this.progressTimeMaxFontSize)
          .minFontSize(mainTitleFontSize.min)
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Bold)
          .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
          .accessibilityText(this.getCurrentTimeText())
          .fontFeature('\"ss01\" on')
          .id('progressTime')

        // duration time
        Text(Util.timeFormatMs(this.focusRecordDuration || 0))
          .baselineOffset(0)
          .maxLines(1)
          .maxFontSize(this.durationTimeMaxFontSize)
          .minFontSize(subTitleFontSize.min)
          .constraintSize({ minHeight: 0 })
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontFamily('HarmonyHeiTi')
          .fontWeight(FontWeight.Medium)
          .fontFeature('\"ss01\" on')
          .maxFontScale(CommonConstants.TEXT_SIZE_NORMAL)
          .accessibilityText(AccessibilityUtil.getTotalDurationText(this.focusRecordDuration))
          .id('durationTime')
      }
      .alignRules({
        center: { anchor: '__container__', align: VerticalAlign.Center },
        middle: { anchor: '__container__', align: HorizontalAlign.Center }
      })
    }
    .width('100%')
    .clip(true)
    .height(this.aBox.height)
    .margin(this.aBox.margin)
    .visibility(this.aBox.visible ? Visibility.Visible : Visibility.None)
  }

  @Builder
  WaveSection() {
    WaveView({
      recorderState: RecorderState.PLAY,
      markTimeArray: this.markList,
      waveDragTime: this.waveMoveTime,
      audioTotalTime: this.focusRecordDuration,
      audioCountdownTime: this.currentTimePlay,
      mediaSpeed: this.speed,
      isShowMark: this.markList.content.getAll().length > 0,
      isRecordTrans: this.recordTransState
    })
      .width('100%')
      .height(this.waveBox.height)
      .visibility(this.waveBox.visible ? Visibility.Visible : Visibility.None)
  }

  @Builder
  MarkList() {
    MarkListComponent({
      markList: this.markList,
      markOpacity: this.markOpacity,
      state: this.state,
      focusRecord: this.focusRecord,
      currentTimePlay: this.currentTimePlay,
      page: this.page
    })
      .width('100%')
      .flexShrink(this.markListBox.flexShrink)
      .height(this.markListBox.height)
      .margin(this.markListBox.margin)
      .visibility(this.markListBox.visible ? Visibility.Visible : Visibility.None)
  }

  @Builder
  ProcessBar() {
    ProgressBarComponent({
      currentTimePlay: this.currentTimePlay,
      duration: this.focusRecordDuration,
      transferData: this.transferData
    })
      .width('100%')
      .flexShrink(this.progressBarBox.flexShrink)
      .height(this.progressBarBox.height)
      .margin(this.progressBarBox.margin)
      .visibility(this.progressBarBox.visible ? Visibility.Visible : Visibility.None)
  }

  private getActionBarStyleOptions(): ActionBarStyleOptions {
    const options: ActionBarStyleOptions = {
      isPrimaryIconChanged: this.isPrimaryIconChanged,
      backgroundColor: ColorMetrics.resourceColor($r('sys.color.comp_background_primary'))
    };
    return options;
  }

  @Builder
  ActionBar() {
    Column() {

      Row() {
        WithTheme({
          colorMode: ThemeColorMode.SYSTEM
        }) {
          RecorderActionBar({
            startButtons: this.markButtons,
            endButtons: this.speedButtons,
            primaryButton: this.playPauseButton,
            actionBarStyle: new ActionBarStyle(this.getActionBarStyleOptions()),
            isExpand: true
          })
        }
      }
    }
    .width('100%')
    .flexShrink(this.actionBarBox.flexShrink)
    .justifyContent(FlexAlign.Center)
    .height(this.actionBarBox.height)
    .margin(this.actionBarBox.margin)
    .visibility(this.actionBarBox.visible ? Visibility.Visible : Visibility.None)
  }

  build() {
    NavDestination() {
      if (this.focusRecord && this.focusRecord.name !== '') {
        if (this.isEditMode && this.navMode === NavigationMode.Split) {
          this.SelectedAudioRecordCountDisplayComponent()
        } else {
          this.MainContent()
        }
      } else {
        if (this.navMode === NavigationMode.Split && !this.isSearchMode) {
          this.BackGroundComponent();
        }
      }
      Row() {
      }
      // .bindSheet($$this.isShowDigest, this.DigestPageShowBuilder(), {
      //   height: DeviceUtil.isPC() ? ConfigData.WH_560_VP :
      //     (DeviceUtil.isTabletOrTripleGStatus() || DeviceUtil.isExpanded()) ?
      //     ConfigData.WH_560_VP : ConfigData.WH_100_100,
      //   width: DeviceUtil.isPC() ? ConfigData.WH_720_VP : undefined,
      //   backgroundColor: $r('app.color.bind_sheet_background'),
      //   preferType: SheetType.CENTER,
      //   showClose: false
      // })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
    .padding({ top: this.navMode === NavigationMode.Split ? this.statusBarHeight : 0, bottom: this.offsetBottom })
    .backgroundColor(DeviceUtil.isPhoneNotFold() ||
      (this.isSmallFoldVer && this.foldDisplayMode !== display.FoldStatus.FOLD_STATUS_FOLDED) ?
      $r('app.color.bind_sheet_background') : $r('sys.color.ohos_id_color_sub_background'))
    .borderColor(Color.Transparent)
    .hideTitleBar(false)
    .title({ builder: this.NavDestinationTitleBar(), height: this.titleHeight })
    .menus(this.navMenu())
    .onShown(() => {
      let isConvertText: boolean = AppStorage.get('isShowConvertText') as boolean;
      LogUtil.info(`${TAG} onShown isConvertText: ` + isConvertText);
      if (isConvertText) {
        AppStorage.setOrCreate('isShowConvertText', false);
      }
      if (this.navMode === NavigationMode.Stack && this.state === 'idle' && !this.jumpFromDoubleXEnd) {
        this.pathStack.pop(false);
      }
      if (this.navMode === NavigationMode.Stack && this.shortCutRecordList) {
        const player = PlayManager.getInstance();
        this.isExistRecordPlayPage = true;
        player.reset();
      }
    })
    .onHidden(() => {
      if (this.navMode !== 1) {
        AppStorage.setOrCreate('selectIndex', -1);
      }
    })
    .onBackPressed(() => {
      LogUtil.info(`${TAG} Navigation onBackPressed.`);
      // 退出详情界面时，重设倍速为1
      const player = PlayManager.getInstance();
      if (this.navMode == NavigationMode.Stack) {
        this.isExistRecordPlayPage = true;
        player.reset();
      } else {
        player.pause()
      }
      // onBackPressed比aboutToDisappear更灵敏，重命名标记，返回退出详情，快速进入，
      // 该场景下在aboutToDisappear中做保存操作，会出现重命名标记未保存的情况。
      // 较大字体条件下
      if (DeviceUtil.isTabletOrTripleGStatus() && this.navMode === NavigationMode.Stack) {
        this.isExitTopAction = true;
      }
      // if true, go back to index, otherwise go back to desktop
      return this.navMode === NavigationMode.Stack;
    })
    .onAreaChange((_, newValue) => {
      this.h1 = Number(newValue.height);
      this.displayChangeCallback();
    })
    .onAppear(() => {
      LogUtil.info(TAG + ' onAppear.');
      this.setDurationCallback();
    })
    .onDisAppear(() => {
      LogUtil.info(TAG + ' onDisAppear.');
    })
  }

  /* instrument ignore next */
  private setDurationCallback = () => {
    PlayManager.getInstance().setDurationCallback(TAG, (duration: number | undefined) => {
      LogUtil.info(TAG + ' update focusRecordDuration: ' + duration);
      if (duration === undefined) {
        LogUtil.log(TAG + ' duration undefined');
        return;
      }
      this.focusRecordDuration = duration;
      this.want.parameters!.recordDuration = duration;
      this.wantParametersDone = true;
      if (this.recordTransState && this.recordTagsDone) {
        animateTo({
          duration: 150,
          curve: Curve.Sharp,
        }, () => {
          this.transImageOpacity = 0;
        })
        animateTo({
          delay: 100,
          duration: 300,
          curve: Curve.Sharp,
        }, () => {
          this.transOpacity = 1;
        })
      }
      LogUtil.info(TAG + `queryRecordTransferData success.`);
    })
  }
}

// @ObservedV2
// class ActionBarButtonExt extends ActionBarButton {
//   @Trace public buttonModifier?: ButtonModifier;
//
//   constructor(actionBarButtonOptions: ActionBarButtonOptions, buttonModifier?: ButtonModifier) {
//     super(actionBarButtonOptions);
//     this.buttonModifier = buttonModifier;
//   }
// }
