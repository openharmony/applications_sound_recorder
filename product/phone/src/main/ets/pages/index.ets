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
import Base, { BusinessError } from '@ohos.base';
import CommonEventManager from '@ohos.commonEventManager';
import display from '@ohos.display';
import {
  AudioRecordListComponent,
  BaseViewModel,
  PlayManager,
  RecordManager,
  RecordPlayPage,
  ScreenStateListener,
  SideBarComponent
} from '@ohos/recorder';
import call from '@ohos.telephony.call';
import util from '@ohos.util';
import fs from '@ohos.file.fs';
import {
  AnonymousUtil,
  AuditLogManager,
  CommonConstants,
  ConfigData,
  ContinuousTask,
  DataToast,
  DeviceUtil,
  DFXEnumConstants,
  Events,
  FileUtil,
  flexBox,
  GlobalContext,
  Helps,
  HiSysEventName,
  HiSysEventUtil,
  ListAnimationUtil,
  LongPressDialogView,
  PathUtil,
  Preferences,
  Props,
  RecordData,
  RecordType,
  RenameDialog,
  ShareModalParams,
  ShareUtil,
  Util
} from '@ohos/common';
import abilityAccessCtrl, { PermissionRequestResult, Permissions } from '@ohos.abilityAccessCtrl';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { SearchResult } from '@ohos/common/src/main/ets/model/SearchResult';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import Intl from '@ohos.intl';
import { PreferencesUtil } from '@ohos/common/src/main/ets/utils/PreferencesUtil';
import statfs from '@ohos.file.statvfs';
import { LazyDataSource, RecordDataGroupArray } from '@ohos/common/src/main/ets/model/RecordData';
import * as RecordingPage from '@ohos/recorder/src/main/ets/pages/RecordingPage';
import RecordingPageShow from '@ohos/recorder/src/main/ets/pages/RecordingPage';
import { ComponentContent, Configuration, curves, LengthMetrics, SymbolGlyphModifier } from '@kit.ArkUI';
import Curves from '@ohos.curves';
import I18n from '@ohos.i18n';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import window from '@ohos.window';
import MediaController, { FileDeletedComponent } from '@ohos/recorder/src/main/ets/controller/MediaController';
import ContactsManagerUtil from '@ohos/common/src/main/ets/utils/ContactsManagerUtil';
import { SideBarMode, sideBarModeToNameMap } from '@ohos/recorder/src/main/ets/components/SideBarComponent';
import { HashSet, JSON } from '@kit.ArkTS';
import hiTraceMeter from '@ohos.hiTraceMeter';
import SortType, { SortConstants } from '@ohos/common/src/main/ets/constants/DataSortType';
import { i18n, intl } from '@kit.LocalizationKit';
import { AboutPage } from '@ohos/recorder/src/main/ets/pages/AboutPage';
import { AudioRecordListController } from '@ohos/recorder/src/main/ets/components/AudioRecordListComponent';
import systemparameter from '@ohos.systemParameterEnhance';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { RecordDbManager } from '@ohos/databaseManager';
import { FileManager } from '@ohos/fileManager';
import { geoLocationManager } from '@kit.LocationKit';

const MAX_SHARE_LENGTH = 100;
const STANDARD_DPI: number = 160;
/** 侧边栏展开/收起与内容区平移共用动画参数，修改此处即可统一调速 */
const SIDE_BAR_ANIM_CURVE = curves.cubicBezierCurve(0.2, 0.2, 0.1, 1);
const SIDE_BAR_ANIM_DURATION: number = 500;
const permissionList: Permissions[] = [
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.LOCATION'
];

const TAG = 'SoundRecorder_IndexPage';

export const INDEX_PAGE: string = 'IndexPage';

const MENU_DEFAULT_WIDTH: number = 224;
const TIME_FOR_ONE_DAY: number = 24 * 60 * 60 * 1000;
const DAYS_FOR_ONE_WEEK: number = 7;
const KEYCODE_ESCAPE = 2070; //	ESC键

interface ParamsInterface {
  multiSelect: Function,
  sortBuilder: CustomBuilder;
  openAbout: Function,
  openPersonal: Function,
  openHelps: Function,
  isAudioRecordExist: boolean,
  sideFolderNameFlag: number,
  allRecordsRecover: Function,
  allRecordsDelete: Function,
}

interface Rect {
  x: number
  y: number
  width: number
  height: number
}

@Builder
function menuComponent(params: ParamsInterface) {
  if (params.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) {
    Menu() {
      MenuItem({
        content: $r('app.string.menu_multiselect')
      })
        .padding({ left: 16 })
        .onClick(() => {
          params.multiSelect();
        })
        .enabled(params.isAudioRecordExist)
      MenuItem({
        content: $r('app.string.data_sort'),
        builder: params.sortBuilder,
      })
        .id('sortBtn')
        .padding({ left: 16 })
      // if (params.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
        // MenuItem({
        //   content: $r('app.string.about'),
        // })
        //   .padding({ left: 16 })
        //   .onClick(() => {
        //     params.openAbout();
        //   })
        // MenuItem({
        //   content: $r('app.string.help_and_feedback'),
        // })
        //   .padding({ left: 16 })
        //   .onClick(() => {
        //     params.openHelps();
        //   })
      // }
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      color: $r('sys.color.comp_divider'),
      startMargin: LengthMetrics.vp(1),
      endMargin: LengthMetrics.vp(16)
    })
    .width(224)
    .subMenuExpandingMode(SubMenuExpandingMode.EMBEDDED_EXPAND)
  } else {
    Menu() {
      MenuItem({
        content: $r('app.string.menu_multiselect')
      })
        .padding({ left: 16 })
        .onClick(() => {
          LogUtil.info(TAG + ' click the multi select button');
          params.multiSelect();
        })
      MenuItem({
        content: $r('app.string.all_recording_recover'),
      })
        .padding({ left: 16 })
        .onClick(() => {
          // 全部恢复，将数据重新放到normal表
          params.allRecordsRecover();
        })
      MenuItem({
        content: $r('app.string.all_recording_delete'),
      })
        .padding({ left: 16 })
        .onClick(() => {
          // 全部删除，将数据移出回收站表，同时删除文件，需要弹窗
          params.allRecordsDelete();
        })
    }.menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      color: $r('sys.color.comp_divider'),
      startMargin: LengthMetrics.vp(16),
      endMargin: LengthMetrics.vp(16),
    })
    .width(MENU_DEFAULT_WIDTH)
    .subMenuExpandingMode(SubMenuExpandingMode.EMBEDDED_EXPAND)
  }
}

@Entry({ routeName: INDEX_PAGE })
@Component
struct Index {
  private isRenameFocusRecord: boolean = false;
  private hasCloneEvent: boolean = false; // 是否有clone事件
  private tabsController: TabsController = new TabsController();
  private audioRecordListContrRef: AudioRecordListController = new AudioRecordListController();
  private listScroller: ListScroller = new ListScroller();
  @StorageProp('currentBreakpoint') @Watch('onBreakPointChange') curBp: string = 'sm';
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('navigatorBarHeight') @Watch('calcOffsetBottom') navigatorBarHeight: number = 0;
  @StorageProp('appContentHeight') @Watch('calcOffsetBottom') appContentHeight: number = 0;
  @StorageProp('jumpFromContacts') jumpFromContacts: boolean = false;
  @StorageProp('jumpFromSceneBoard') jumpFromSceneBoard: boolean = false;
  @StorageProp('jumpFromDoubleX') jumpFromDoubleX: boolean = false;
  @StorageProp('jumpFromDoubleXEnd') @Watch('doubleXStart') jumpFromDoubleXEnd: boolean = false;
  @StorageProp('screenShowState') screenShowState: string = CommonConstants.SCREEN_FULL;
  @StorageProp('xTapCount') xTapCount: number = 1;
  @StorageProp('navigationMode') @Watch('calcOffsetBottom') navMode: number = 0;
  @StorageLink('isEditMode') @Watch('onEditModeChange') isEditMode: boolean = false;
  @StorageLink('isNormalMode') isNormalMode: boolean = true;
  @StorageLink('hideToolBar') hideToolBar: boolean = true;
  @StorageLink('enterEdit') enterEdit: boolean = false;
  @StorageProp(Props.IS_IN_BACKGROUND) @Watch('onBackgroundChange') isInBackground: boolean = false;
  @StorageLink('isPortrait') isPortrait: boolean = true;
  @StorageProp('cloneDone') cloneDone: boolean = false;
  @Provide isSort: boolean = false;
  @StorageLink('RecordTime') time: number = 0;
  @StorageLink('RecordObj') obj: Record<string, Array<number>> = {};
  @StorageLink('clickDelay') clickDelay: boolean = false;
  @StorageLink('recordingMarkListHeightOpen')
  @Watch('getQuickTransHeight') recordingMarkListHeightOpen: boolean = false;
  @StorageProp('bottomAvoidAreaHeight') bottomAvoidAreaHeight: number = 0;
  @Provide pathStack: NavPathStack = new NavPathStack();
  @Provide @Watch('onFocusRecordChange') focusRecord: RecordData = new RecordData();
  private isFocusRecordChanged: boolean = false;
  private currentTimePlayTemp: number = -1;
  @Provide @Watch('isSelectedAllRecord') selectedRecordList: Array<RecordData> = [];
  @Provide state: string = 'idle';
  @Provide currentTimePlay: number = 0;
  @Provide recordDataGroupList: RecordDataGroupArray = new RecordDataGroupArray();
  @Provide @Watch('isSearchModeChange') isSearchMode: boolean = false;
  @Provide isExitPageToQuickRecord: boolean = false;
  @Provide offsetBottom: number = 52;
  @State lastIsExpanded: boolean = false;
  @Provide loading: boolean = true;
  @State hasPermission: boolean = false;
  @State scrollBarState: boolean = false;
  @State isPermitAccessMediaLibrary: boolean = false;
  @State isSelectedAllAudio: boolean = false;
  @StorageLink('isScreenOn') isScreenOn: boolean = true;
  @StorageLink('isScreenLock') isScreenLock: boolean = false;
  @StorageLink('foldDisplayMode') foldDisplayMode: number = 0;
  @State isAudioRecordExist: boolean = false;
  @State @Watch('onPageStateChange') isPageHide: boolean = false;
  @State isVerdeFolded: boolean = false;
  @StorageLink('WindowStatusType') windowStatusType: number = 1;
  @StorageLink('screenWidthSplitState') screenWidthSplitState: string = CommonConstants.SCREEN_WIDTH_FULL;
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Provide canFocus: boolean = true;
  private scroller: Scroller = new Scroller();
  @StorageLink('fontSizeScale') fontSizeScale: number = CommonConstants.TEXT_SIZE_NORMAL;
  private customDialogViewController?: CustomDialogController;
  @StorageLink('windowClass') windowClass: window.Window | undefined = undefined;
  @StorageLink('windowWidth') windowWidth: number = 0;
  @StorageLink('windowHeight') @Watch('onWindowHeightChange') windowHeight: number = 0;
  @StorageLink('screenHeight') @Watch('onWindowHeightChange') screenHeight: number = 0;
  @StorageLink('windowSizeChangeFlag') @Watch('windowSizeChangeCallback') windowSizeChangeFlag: boolean = false;
  @State recorderWindowHeight: string = ConfigData.WH_60_100;
  @State isFullScreen: boolean = true;
  private recordListInitTime: number = 0;
  @StorageLink('RecordBindSheet') @Watch('showRecordChange') isShowRecord: boolean = false;
  @StorageLink('RecordPlayBindSheet') isShowRecordPlay: boolean = false;
  @StorageLink('backFromRecordingPage') backFromRecordingPage: boolean = false;
  @StorageLink('RecordTranslateState') @Watch('onRecordTransState') recordTransState: boolean = false;
  @Provide isShowOverlay: boolean = false; // 蒙层是否显示
  @Provide isShowSideBar: boolean = false; // 侧边栏是否显示
  @Provide isExitTopAction: boolean = true; // 进入其他页面时是否去除顶部工具栏
  @Provide @Watch('onSideFolderNameFlagChange') sideFolderNameFlag: number = SideBarMode.ALL_RECORDINGS;
  @Provide allRecordingCount: number = 0;
  @Provide callRecordingCount: number = 0;
  @Provide headsetRecordingCount: number = 0;
  @Provide recordingCount: number = 0;
  @Provide recentDeleteRecordingCount: number = 0;
  @Provide sideFolderName: String =
    getContext().resourceManager.getStringByNameSync('all_recordings'); // 传递侧边栏用户选择的文件夹名称
  @State titleHeight: number = 56;
  @State subTitleHeight: number = 56;
  @State jumpFromShortCut: boolean = false;
  private callRecordCountInCallAppDatabase: number = 0; // 记录通话录音app数据库中的通话录音总条数，为了识别录音机应用后台打开，在通话录音app中新增通话录音的这种场景
  @Provide defaultDP: number = Util.getDefaultDensityPixels(getContext());
  @Provide densityPixels: number = Util.getDensityPixels();
  private clickShowSideBarTime: number = 0;
  private clickCloseShowSideBarTime: number = 0;
  @State isAbleToShare: boolean = false;
  @State sortType: string = SortType.SORT_TIME_DESC;
  @State selectEndModifier: SymbolGlyphModifier = new SymbolGlyphModifier($r('sys.symbol.checkmark')).fontSize(24);
  @State nonSelectEndModifier: SymbolGlyphModifier = new SymbolGlyphModifier().fontSize(24);
  @Provide isRenameFlag: boolean = false;
  @Provide isFromLockScreenRecord: boolean = false;
  private recordCompare: intl.Collator = new intl.Collator(i18n.System.getSystemLocale(), {
    sensitivity: 'case',
    numeric: false,
    caseFirst: 'lower',
    usage: 'sort',
    collation: 'dict',
    ignorePunctuation: false
  });
  //是否折叠屏折叠状态
  @State isFoldFold: boolean = false;
  @Provide isRecordItemFloatMenuShown: boolean = false;
  @State showAboutPage: boolean = false;
  @State showPersonalDataPage: boolean = false;
  @Provide isLogin: number = CommonConstants.LOGIN_DEFAULT_VALUE;
  @Provide playTimeBeforeRenameIndex: number = 0;
  @StorageLink('jumpFromNotification') @Watch('onJumpFromNotificationChange') jumpFromNotification: boolean = false;
  @StorageLink('displaySizeScale') displaySizeScale: number = CommonConstants.PAD_DISPLAY_SIZE_SCALE_NORMAL;
  @State isUserAllow: boolean = false;
  @State isTipsClose: boolean = false;
  @State isOverOneWeek: boolean = false;
  private tipsCloseTime: number = 0;
  @State closeButtonBackgroundColor: ResourceColor = $r('sys.color.ohos_id_color_background_transparent');
  @State buttonBackgroundColor: ResourceColor = $r('sys.color.ohos_id_color_background_transparent');
  @StorageProp(Props.LANGUAGE) @Watch('onLanguageChange') language: string = Configuration.getLocale().language;
  @StorageProp('isCeliaEnabled') @Watch('isCeliaEnabledChange') isCeliaEnabled: boolean = false;
  @StorageProp('isRecordingSaveDone') isRecordingSaveDone: boolean = true;
  @StorageProp('enterTimer') enterTimer: number = 0;
  @StorageProp('isFirstEnter') isFirstEnter: boolean = true;
  @StorageProp('isSmallFoldVer') isSmallFoldVer: boolean = false;
  private fileDeletedController: CustomDialogController = new CustomDialogController({ builder: FileDeletedComponent });
  // 是否演示版本
  @State isDemo: boolean = false;
  @Provide finalResultList: SearchResult[] = [];
  @Provide detailRecord: RecordData = this.selectedRecordList[0];
  @Provide isSkipMute: boolean = false;
  private isTripleFold: boolean = false;
  @BuilderParam contentBuilder: () => void = this.ContentPanelBuilder;
  @BuilderParam sideBarBuilder: () => void = this.SideBarPanelBuilder;
  @State playPageWindowHeight: SheetSize | Length = px2vp(this.screenHeight) * 0.6;
  @State isShortCutList: boolean = false;
  @State @Watch('bindSheetStateWatch') bindSheetState: boolean = false;
  @Provide @Watch('onIsShowQuickTransChange') isShowQuickTrans: boolean = false;
  @StorageLink('isAgreeQuickTrans') isAgreeQuickTrans: boolean = false;
  @Provide quickTransHeight: string = ConfigData.QH_432_VP;
  @State isLoginPageShow: boolean = false;
  @StorageLink('isSmallFoldSplit') isSmallFoldSplit: boolean = false;
  //标识从锁屏态拉起录音，且上一个录音未销毁的场景
  private isLastPageExist: boolean = false;

  /**
   * 计算底部偏移高度
   * 录制按钮 & 播放页 action bar 处于同一高度
   */
  private calcOffsetBottom(): void {
    this.offsetBottom = this.navMode === NavigationMode.Split ?
      this.getWideScreenOffsetBottom() :
      this.getNarrowScreenOffsetBottom();
  }

  bindSheetStateWatch() {
    if (!this.bindSheetState && this.isLastPageExist) {
      LogUtil.info(TAG + ` bindSheetState : ${this.bindSheetState}, isLastPageExist:${this.isLastPageExist}`);
      this.isShowRecord = true;
      this.isLastPageExist = false;
    }
  }

  showRecordChange() {
    LogUtil.info(TAG + ` isShowRecord change to: ${this.isShowRecord}}`);
  }

  private getNarrowScreenOffsetBottom(): number {
    return this.navigatorBarHeight || 8;
  }

  /* instrument ignore next */
  private getWideScreenOffsetBottom(): number {
    const navigatorBarHeight = this.navigatorBarHeight;
    const bp = flexBox.getWideScreenHeightBreakpoint(this.appContentHeight);
    const offsetHeight = bp === flexBox.HeightBreakpoint.SM ? 12 : 24;
    return navigatorBarHeight + offsetHeight;
  }

  /* instrument ignore next */
  onBreakPointChange() {
    LogUtil.info(TAG + ' onBreakPointChange.');
    if (this.isTripleFold) {
      this.isShowSideBar = false;
    } else {
      this.isShowSideBar = this.curBp === 'lg';
    }
    this.isShowOverlay = false;
  }

  /* instrument ignore next */
  async onBackgroundChange() {
    if (!this.isInBackground && this.hasCloneEvent) {
      this.loading = true;
      LogUtil.info(TAG + ' Switch to the foreground to refresh callRecord after cloning.');
      await this.handleCallRecordingsAdded();
      await this.onRecordDataGroupListChange();
      this.loading = false;
      this.hasCloneEvent = false;
    }
  }

  /* instrument ignore next */
  async onSideFolderNameFlagChange() {
    LogUtil.info(TAG + ' onSideFolderNameFlagChange.');
    if (this.isSearchMode) {
      this.isSearchMode = false;
    }
    this.currentTimePlay = 0;
    this.state = 'idle';
    await PlayManager.getInstance().reset();
    this.onRecordDataGroupListChange();
    this.getNewFocusRecordWhenSideFolderChange();
    this.focusRecord.isNeedPlay = false;
    PlayManager.getInstance().setDataSource('onSideFolderNameFlagChange', this.focusRecord);
  }

  /* instrument ignore next */
  private onJumpFromNotificationChange(): void {
    if (this.jumpFromNotification) {
      this.sideFolderNameFlag = SideBarMode.CALL_RECORDINGS;
      this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
      this.jumpFromNotification = false;
    }
  }

  /* instrument ignore next */
  private onLanguageChange(): void {
    let recentDeleteLanguage = this.recordDataGroupList.recentDeleteList.getAll();
    recentDeleteLanguage.forEach((item) => {
      let restDays = DatabaseManager.getRestDays(item.deleteTime);
      item.remainDaysTip =
        getContext(this).resourceManager.getPluralStringValueSync($r('app.plural.remaining_days_plural').id, restDays);
    })
  }

  /* instrument ignore next */
  private getSideFolderName(sideMode: SideBarMode): string {
    if (sideMode === SideBarMode.ALL_RECORDINGS) {
      return getContext().resourceManager.getStringByNameSync('all_recordings');
    } else if (sideMode === SideBarMode.CALL_RECORDINGS) {
      return getContext().resourceManager.getStringByNameSync('call_recording');
    } else if (sideMode === SideBarMode.AUDIO_RECORDINGS) {
      return getContext().resourceManager.getStringByNameSync('audio_recordings');
    } else {
      return getContext(this).resourceManager.getStringSync($r('app.string.recent_delete'));
    }
  }

  /* instrument ignore next */
  private async removeRecentDeleteOver30Days(): Promise<void> {
    LogUtil.info(TAG + ' removeRecentDeleteOver30Days.');
    let recentDeleteOver30Days: string[] = [];
    let recentDeleteRecordNotOver30Days: RecordData[] = [];
    let recentDeleteList = this.recordDataGroupList.recentDeleteList;
    recentDeleteList.forEach(item => {
      if (Date.now() - item.deleteTime > 30 * 24 * 3600 * 1000) {
        recentDeleteOver30Days.push(item._data);
      } else {
        recentDeleteRecordNotOver30Days.push(item);
      }
    })

    if (recentDeleteOver30Days.length === 0) {
      return;
    }

    await DatabaseManager.removeRecentDeleteRecordData(recentDeleteOver30Days);
    recentDeleteList.updateAllData(recentDeleteRecordNotOver30Days);
    LogUtil.error(TAG + ' recent delete records over 30 days count: ' + recentDeleteOver30Days.length);

    //删除超30天的全部数据及文件
    try {
      await DatabaseManager.batchRemoveTag(recentDeleteOver30Days);
      const rows = await DatabaseManager.queryTransferDataWithRecords(recentDeleteOver30Days);
      let transferFilePath: string[] = rows.map(item => item.jsonPath);
      await DatabaseManager.removeTransferData(recentDeleteOver30Days);
      DatabaseManager.deleteAudioFile(recentDeleteOver30Days.concat(transferFilePath), () => {
        LogUtil.info(TAG + ' delete recent delete records files over 30 days success.');
        this.onRecordDataGroupListChange();
      });
    } catch (e) {
      LogUtil.error(TAG + ` delete recent delete records files over 30 days failed: ${e.code}, ${e.message} `);
    }

  }

  @State toolbarItemShare: ToolbarItem = {
    value: $r('app.string.voice_share'),
    icon: $r('app.media.ic_public_share'),
    action: () => {
      this.showShareModal();
    },
  };
  @State toolbarItemDelete: ToolbarItem = {
    value: $r('app.string.delete'),
    icon: $r('app.media.ic_public_deletely'),
    action: () => {
      // instrument ignore if
      if (this.selectedRecordList.length > 0) {
        let idList = ContactsManagerUtil.getInstance().batchAddCallRecordPrefix(this.selectedRecordList);
        HiSysEventUtil.eventDotting(HiSysEventName.DELETE_RECORD_LIST,
          { VALUE: this.selectedRecordList.length, FILEID: idList.toString() }
        );
        getContext(this).eventHub.emit('openDeleteDialog', 'indexDelete');
      }
    },
  }
  // 使用Navigation的ToolbarItem组件，实现适老化UX，使用symbol支持自定义颜色
  // instrument ignore next
  @State toolbarItemSelectAll: ToolbarItem = {
    value: $r('app.string.toolbar_select_all'),
    symbolIcon: new SymbolGlyphModifier($r('sys.symbol.checkmark_square_on_square')),
    action: () => {
      this.handleSelect();
    },
  }

  private async onRecordDataGroupListChange(): Promise<void> {
    LogUtil.info(TAG + ' onRecordDataGroupListChange.');
    this.recordingCount = this.recordDataGroupList.normalRecordList.totalCount();
    this.recentDeleteRecordingCount = this.recordDataGroupList.recentDeleteList.totalCount();
    this.callRecordingCount = await DatabaseManager.getNormalCallRecordCount();
    this.headsetRecordingCount = this.recordDataGroupList.headsetRecordList.totalCount();
    this.allRecordingCount = this.callRecordingCount + this.recordingCount + this.headsetRecordingCount;

    let dataSource = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
    this.isAudioRecordExist = dataSource.totalCount() > 0;
    this.callRecordCountInCallAppDatabase = await DatabaseManager.getCallRecordCount();
  }

  /* instrument ignore next */
  private getNewFocusRecordWhenSideFolderChange(): void {
    let dataSource = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
    this.focusRecord = dataSource.totalCount() > 0 ? dataSource.getData(0) : new RecordData();
  }

  // 麦克风设置权限弹框
  private requestMicroPhonePermissionController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.label_permission_microphone_title'),
      contentBuilder: () => {
        this.buildContent($r('app.string.label_permission_microphone'));
      },
      buttons: [{
        value: $r('app.string.cancel'),
        fontColor: '#FB654E',
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          LogUtil.info(TAG + `The user cancels the operation permission setting.`);
        }
      },
        {
          value: $r('app.string.go_to_setting'),
          fontColor: '#FB654E',
          buttonStyle: ButtonStyleMode.TEXTUAL,
          action: () => {
            this.redirectSettings();
          }
        }],
    }),
    autoCancel: false,
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    cornerRadius: $r('app.float.distance_32'),
    customStyle: false,
  })

  /* instrument ignore next */
  private onWindowHeightChange() {
    if ((this.windowHeight / this.screenHeight) > 5 / 6) {
      this.isFullScreen = true;
    } else {
      this.isFullScreen = false;
    }
    this.isVerdeFolded = DeviceUtil.isSmallFoldVer() && DeviceUtil.isFolded();
    this.isSmallFoldSplit = this.getSmallFoldSplit();
    LogUtil.info(TAG + ' onWindowHeightChange isFullScreen: ' + this.isFullScreen +
      ' windowHeight: ' + this.windowHeight + ' screenHeight: ' + this.screenHeight);
  }

  private windowSizeChangeCallback() {
    this.calcSplitScreenConfig(this.windowHeight, AppStorage.get('windowWidthOri') as number);
    this.resetBindSheetShow();
    this.getRecorderWindowHeight();
    this.getRecordPlayBindSheetHeight();
  }

  @Builder
  buildContent(context: ResourceStr) {
    Column() {
      Text(context)
    }
    .width('100%')
    .align(Alignment.Center)
  }

  /* instrument ignore next */
  private async redirectSettings() {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    try {
      await atManager.requestPermissionOnSetting(getContext(), ['ohos.permission.MICROPHONE']);
    } catch (err) {
      LogUtil.error(`${TAG} requestPermissionOnSetting failed, code: ${err.code}, message: ${err.message}}`);
    }
  }

  private onEditModeChange(): void {
    LogUtil.info(TAG + ': onEditModeChange.');
    if (!this.isEditMode) {
      LogUtil.info(TAG + ' exist edit mode, select no audio.');
      this.isSelectedAllAudio = false;
      this.isExitTopAction = true;
      this.isNormalMode = true;
    } else {
      this.isExitTopAction = false;
      this.isNormalMode = false;
      if (this.isSearchMode) {
        this.isSearchMode = false;
      }
    }
  }

  /* instrument ignore next */
  private async startRecord() {
    if (this.isShowRecord) {
      RecordManager.getInstance().resume().then((value) => {
        HiSysEventUtil.eventDotting(HiSysEventName.RESUME_RECORD, { VALUE: value, FROM: 'AudioCapturer' });
      }).catch((err: BusinessError) => {
        HiSysEventUtil.eventDotting(HiSysEventName.RESUME_RECORD, { VALUE: err.code, FROM: 'AudioCapturer' });
      });
      return;
    }
    PlayManager.getInstance().reset();
    this.availableRecord();
  }

  /* instrument ignore next */
  // 有侧边指纹解锁机型（X键），双触X键，进行录音
  private doubleXStart(): void {
    if (this.jumpFromDoubleXEnd && !this.jumpFromDoubleX && this.isRecordingSaveDone) {
      this.xTapCount += 1;
      AppStorage.setOrCreate('xTapCount', this.xTapCount);
      if (this.xTapCount % 2 === 0) {
        this.exitPageToRecording();
        if (this.sideFolderNameFlag !== SideBarMode.ALL_RECORDINGS) {
          this.sideFolderNameFlag = SideBarMode.ALL_RECORDINGS;
          this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
        }
        this.startRecord();
        HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
          { VALUE: DFXEnumConstants.StartRecordResource.SHORTCUT });
      }
    }
  }

  /* instrument ignore next */
  private isSelectedAudioRecordsToShare() {
    if (!this.selectedRecordList.length) {
      this.isAbleToShare = false;
    } else if (this.selectedRecordList.length > MAX_SHARE_LENGTH) {
      this.isAbleToShare = false;
    } else {
      this.isAbleToShare = true;
    }
  }

  private isSelectedAllRecord(): void {
    if (this.selectedRecordList.length === this.getRecordListBySideFolderId(this.sideFolderNameFlag).totalCount()) {
      this.isSelectedAllAudio = true;
      this.toolbarItemSelectAll.value = $r('app.string.toolbar_cancel_select_all');
      this.toolbarItemSelectAll.symbolIcon = new SymbolGlyphModifier($r('sys.symbol.checkmark_square_on_square_fill'))
        .fontColor(['#FB654E']);
    } else {
      this.isSelectedAllAudio = false;
      this.toolbarItemSelectAll.value = $r('app.string.toolbar_select_all');
      this.toolbarItemSelectAll.symbolIcon = new SymbolGlyphModifier($r('sys.symbol.checkmark_square_on_square'));
    }
    // 更新分享按钮状态
    this.isSelectedAudioRecordsToShare();
    if (this.isAbleToShare) {
      this.toolbarItemShare.status = ToolbarItemStatus.NORMAL;
    } else {
      this.toolbarItemShare.status = ToolbarItemStatus.DISABLED;
    }
    if (this.selectedRecordList.length === 0) {
      this.toolbarItemDelete.status = ToolbarItemStatus.DISABLED;
    } else {
      this.toolbarItemDelete.status = ToolbarItemStatus.NORMAL;
    }
  }

  /* instrument ignore next */
  private availableRecord() {
    const context = GlobalContext.getUIAbilityContext();
    const filesDir: string = context.filesDir + '/';
    statfs.getFreeSize(filesDir).then(async (size: number) => {
      // 录音预估能够录制时长计算规则： 根据剩余空间计算。录音文件大小 = 录音时长 * 每分钟录音占用空间 2.6
      const leftSpace: number = size / 1024 / 1024;
      const leftMinute: number = leftSpace / 2 / CommonConstants.SIZE_PER_MINUTE;
      if (leftMinute <= 30) {
        let message = context?.resourceManager.getStringSync($r('app.string.cannot_recording'));
        Util.showToast(message);
        return;
      } else {
        await this.ScreenRecording();
      }
    })
  }

  /* instrument ignore next */
  async sortNormalRecordList(normalRecordList: RecordData[]) {
    this.sortType = await PreferencesUtil.get(SortConstants.PRE_KEY, SortType.SORT_TIME_DESC) as string;
    LogUtil.info(TAG + ' sortNormalRecordList sortType: ' + this.sortType);
    if (typeof this.sortType === 'number') {
      LogUtil.error(TAG + ' sortType is invalid: number');
      this.sortType = String(this.sortType);
      await PreferencesUtil.put(SortConstants.PRE_KEY, this.sortType);
    }
    DatabaseManager.sortRecords(normalRecordList, this.sortType);
  }

  /* instrument ignore next */
  private async syncCallRecordsFromDb(): Promise<RecordData[]> {
    hiTraceMeter.startTrace('queryCallRecordTable', 1);
    let callRecordList = await DatabaseManager.getInitialCallRecordList();
    const extraRecords = await FileManager.scanCallRecordFileDir(callRecordList);
    callRecordList.push(...extraRecords);
    this.callRecordCountInCallAppDatabase = callRecordList.length;
    ContactsManagerUtil.getInstance().updateCallRecordIndex(getContext(), callRecordList);
    let recentDeleteCallRecordList = callRecordList.filter(item => item.delete === 1);
    callRecordList = callRecordList.filter(item => item.delete === 0);
    this.recordDataGroupList.callRecordList.deleteAll();
    this.recordDataGroupList.callRecordList.batchPushItem(callRecordList);
    this.recordDataGroupList.allRecordList.batchPushItem(callRecordList);
    hiTraceMeter.finishTrace('queryCallRecordTable', 1);
    LogUtil.error(TAG + ' recentDeleteCallRecordList length: ' + recentDeleteCallRecordList.length);
    let moveToRecentDeleteCallRecord: RecordData[] = [];
    if (this.recordDataGroupList.recentDeleteList.getAll()
      .filter(item => item.phoneNumber)
      .length !== recentDeleteCallRecordList.length) {
      let dataTempSet: HashSet<string> = new HashSet<string>();
      this.recordDataGroupList.recentDeleteList.getAll()
        .filter(item => item.phoneNumber)
        .forEach((value: RecordData) => {
          dataTempSet.add(value._data);
        });
      LogUtil.info(TAG + ' temp length: ' + dataTempSet.length);
      for (let callRecord of recentDeleteCallRecordList) {
        if (dataTempSet.has(callRecord._data)) {
          continue;
        } else {
          moveToRecentDeleteCallRecord.push(callRecord)
        }
      }
      await DatabaseManager.insertToRecentDeleteTable(moveToRecentDeleteCallRecord, RecordType.CALL_RECORD);
      this.recordDataGroupList.recentDeleteList.batchPushItem(moveToRecentDeleteCallRecord);
    }
    LogUtil.info(TAG + ' callRecordList length: ' + callRecordList.length);
    return callRecordList;
  }

  /* instrument ignore next */
  private async syncRecordListFromDb(reason: string): Promise<void> {
    LogUtil.info(TAG + ' begin to syncRecordListFromDb: ' + reason);
    hiTraceMeter.startTrace('syncRecordListFromDb', 1);
    this.recordDataGroupList.allRecordList.deleteAll();

    // 获取回收站中录音记录
    hiTraceMeter.startTrace('queryRecentDeleteTable', 1);
    let recentDeleteList = await DatabaseManager.getAllDbQuery('recent_delete_record_table');
    this.recordDataGroupList.recentDeleteList.deleteAll();
    this.recordDataGroupList.recentDeleteList.batchPushItem(recentDeleteList);
    hiTraceMeter.finishTrace('queryRecentDeleteTable', 1);
    LogUtil.info(TAG + ' recentDeleteList length: ' + recentDeleteList.length);
    // 获取普通录音数据
    hiTraceMeter.startTrace('queryNormalRecordTable', 1);
    let normalRecordList = await DatabaseManager.getAllDbQuery('normal_record_table', false);
    let fileName = BaseViewModel.getInstance().getRecordingData().getFileName();
    const context = GlobalContext.getUIAbilityContext();
    const sandboxAudios = await FileUtil.listAudioFile(context.filesDir);
    await FileManager.cleanSandboxFileDir(fileName, sandboxAudios, normalRecordList, recentDeleteList);
    normalRecordList = await DatabaseManager.scanFiles(normalRecordList, recentDeleteList, fileName, sandboxAudios);
    const extraRecords = await FileManager.scanUserFileDir(normalRecordList, recentDeleteList);
    normalRecordList.push(...extraRecords);
    await this.sortNormalRecordList(normalRecordList);
    this.recordDataGroupList.normalRecordList.deleteAll();
    this.recordDataGroupList.normalRecordList.batchPushItem(normalRecordList);
    this.recordDataGroupList.allRecordList.batchPushItem(normalRecordList);
    hiTraceMeter.finishTrace('queryNormalRecordTable', 1);
    LogUtil.info(TAG + ' normalRecordList length: ' + normalRecordList.length);

    // 获取通话录音数据
    let callRecordList = await this.syncCallRecordsFromDb();

    this.callRecordingCount = callRecordList.length;
    this.recordingCount = normalRecordList.length;
    this.recentDeleteRecordingCount = recentDeleteList.length;
    this.allRecordingCount = this.callRecordingCount + this.recordingCount + this.headsetRecordingCount;
    this.onRecordDataGroupListChange();
    this.refreshAllRecord();

    this.removeRecentDeleteOver30Days();
    hiTraceMeter.finishTrace('syncRecordListFromDb', 1);
  };

  private changeShadowColor(resource: string): string {
    return Util.changeShadowColor(resource, getContext(this));
  }

  // 显示文件已删除弹窗
  private showFileDeletedDialog: Function = async () => {
    LogUtil.info(TAG + ' file has been deleted , show FileDeletedDialog');
    this.fileDeletedController = new CustomDialogController({ builder: FileDeletedComponent() });
    await MediaController.openFileDeletedDialog(this.fileDeletedController);
  };

  // 详情的弹框内容
  @Builder
  buildDetailContent(): void {
    Scroll(this.scroller) {
      Column() {
        // instrument ignore else
        if (this.fontSizeScale < CommonConstants.TEXT_SIZE_HUGE_LEVEL2) {
          this.detailContentStandardLayout();
        } else {
          this.detailContentHugeLayout();
        }
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  detailContentStandardLayout(): void {
    Text($r('app.string.detailDialog_name', this.getName()))
      .margin({
        bottom: $r('app.float.wh_value_10')
      })
    Text($r('app.string.detailDialog_time', this.getDates()))
      .margin({
        bottom: $r('app.float.wh_value_10')
      })
    Row() {
      Text($r('app.string.detailDialog_size', this.getSize() + ' '))
    }
    .alignItems(VerticalAlign.Bottom)
  }

  @Builder
  detailContentHugeLayout() {
    Text($r('app.string.detailDialog_name_huge_layout'))
      .margin({
        bottom: $r('app.float.wh_value_10')
      })
    Column() {
      Text(this.getName())
    }
    .margin({
      bottom: $r('app.float.wh_value_10'),
      end: LengthMetrics.vp(8)
    })

    Text($r('app.string.detailDialog_time_huge_layout'))
      .margin({
        bottom: $r('app.float.wh_value_10')
      })
    Text(this.getDates())
      .margin({
        bottom: $r('app.float.wh_value_10')
      })
    Text($r('app.string.detailDialog_size_huge_layout'))
      .margin({
        bottom: $r('app.float.wh_value_10')
      })
    Text(this.getSize())
  }

  detailDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.voice_retail'),
      contentBuilder: () => {
        this.buildDetailContent();
      },
      buttons: [{
        value: $r('app.string.detailDialog_close'),
        buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
        action: () => {
          this.detailDialogController.close();
        },
        fontColor: '#FB654E',
        background: Color.Transparent,
      }]
    })
  })

  /* instrument ignore next */
  private detailDialogClose() {
    this.detailDialogController?.close();
  }

  private detailDialogOpen() {
    this.detailDialogController?.open();
  }

  // 显示录音详情
  private showRecordDetail: Function = () => {
    this.detailDialogController.open();
    LogUtil.info(TAG + 'moreShowMenu Click');
    HiSysEventUtil.eventDotting(HiSysEventName.OPEN_FILE_DETAIL, { VALUE: CommonConstants.SUCCESS });
  };
  // 重命名录音
  private renameSelectedRecord: Function = () => {
    this.isRenameFocusRecord = this.selectedRecordList[0]?.title === this.focusRecord?.title;
    this.renameDialogController.open();
  }

  private exitEditMode(): void {
    LogUtil.info(TAG + ': exitEditMode start.');
    this.enterEdit = false;
    this.isNormalMode = true;
    animateTo({ curve: Curve.Friction, duration: 350 }, () => {
      this.isEditMode = false;
      AppStorage.setAndLink('isEditMode', this.isEditMode);
      LogUtil.info(TAG + ': exitEditMode update state.');
    });
    this.hideToolBar = true;
    this.selectedRecordList.forEach(item => item.flagSelect = false);
    this.selectedRecordList = [];
    LogUtil.info(TAG + ': exitEditMode end.');
  }

  /* instrument ignore next */
  private async initRecordList(): Promise<void> {
    if (Math.abs(new Date().getTime() - this.recordListInitTime) < 500) {
      // 连续初始化两次recordDataGroup会导致ObjectLink失效，为了解决从通话录音跳转到录音机之后，主界面上多选功能失效的问题，做此规避方案
      LogUtil.info(TAG + ' recordList has already initialized, return.');
      return;
    }
    this.recordListInitTime = new Date().getTime();
    await this.syncRecordListFromDb('initRecordList').then(() => {
      LogUtil.info(TAG + ' syncRecordListFromDb end, set loading flag false.');
      this.loading = false;
      let dataSource = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
      if (dataSource.totalCount() > 0) {
        getContext().eventHub.emit('syncDbEnd', dataSource.getData(0));
      }
      this.jumpFromContacts = false;
      let time: number = new Date().getTime() - this.enterTimer;
      let enterFrom = this.getEnterAppSource();
      let callNum = 'CallRecord: ' + this.callRecordingCount;
      let normalNum = ', NormalRecord: ' + this.recordingCount;
      let headsetNum = ', headsetRecord: ' + this.headsetRecordingCount;
      let recentDeleteNum = ', recentDeleteNum: ' + this.recentDeleteRecordingCount;
      HiSysEventUtil.eventDotting(HiSysEventName.ENTER_APP,
        {
          ENTER_FROM: enterFrom,
          DURATION: time,
          NUM: callNum + normalNum + headsetNum + recentDeleteNum
        }
      )
    });
  }

  /* instrument ignore next */
  private calculateNameSortIndex(dataArr: RecordData[], newName: string): number {
    LogUtil.info(TAG + 'calculateNameSortIndex');
    let insertIndex: number = 0;
    for (let i = 0; i < dataArr.length; i++) {
      let element = dataArr[i];
      let result = this.recordCompare.compare(newName, element.name);
      if (result < 0) {
        insertIndex = i;
        break;
      }
      if (i === dataArr.length - 1) {
        // 名称排序查到最后一个数据时，将插入到最后
        LogUtil.info(TAG + 'Name sorting does not find the insertion position, put it at the end');
        insertIndex = dataArr.length;
      } else {
        insertIndex = i + 1;
      }
    }
    return insertIndex;
  }

  /* instrument ignore next */
  private insertNewRecord(recordList: LazyDataSource<RecordData>, newRecordData: RecordData) {
    LogUtil.info(TAG + 'insertNewRecord');
    let maxIndex: number = -1;
    recordList.forEach(record => {
      if (record.index > maxIndex) {
        maxIndex = record.index;
      }
    });
    newRecordData.index = maxIndex + 1;
    let dataSource = recordList;
    if (dataSource.totalCount() === 0) {
      dataSource.insertItem(newRecordData, 0);
      LogUtil.info(TAG + ' add record success, totalCount is: ' + dataSource.totalCount());
    } else {
      let insertIndex: number = 0;
      let dataArr = dataSource.getAll();
      if (this.sortType === SortType.SORT_TIME_ASC) {
        LogUtil.info(TAG + 'sort time asc insert last');
        // 由远到近，插入到最后一个位置
        insertIndex = dataArr.length;
      } else if (this.sortType === SortType.SORT_NAME_ASC) {
        // 名称排序，计算应插入位置
        insertIndex = this.calculateNameSortIndex(dataArr, newRecordData.name);
      }
      LogUtil.info(TAG + 'insert record index: ' + insertIndex);
      dataSource.insertItem(newRecordData, insertIndex);
    }
  }

  private onAddNewRecord = async (startTime: number, filePath: string) => {
    // instrument ignore if
    if (startTime === 0) {
      startTime = new Date().getTime();
    }
    hiTraceMeter.startTrace('onAddNewRecord', 1);
    let newRecordData = await DatabaseManager.getNormalRecordDataFromDb('_data', filePath);
    // instrument ignore if
    if (!newRecordData) {
      return;
    }
    LogUtil.info(TAG + ' onAddNewRecord pathStack.size : ' + this.pathStack.size() + ', newRecordData[0] : ' +
      AnonymousUtil.anonymous(newRecordData[0].title));
    this.focusRecord = newRecordData[0];
    // instrument ignore if
    if (this.pathStack.size() === 0 && this.navMode === NavigationMode.Split && !DeviceUtil.isFolded()) {
      LogUtil.info(TAG + ' onAddNewRecord split mode, open recordPlayPage');
      this.focusRecord.isNeedPlay = false;
      this.isShowRecordPlay = true;
      let params: Record<string, number | RecordData | string> = {
        'focusRecord': this.focusRecord,
        'currentTimePlay': this.currentTimePlay,
        'tranState': this.focusRecord.tranState
      }
      this.pathStack.pushPathByName('recordPlay', params);
    }
    LogUtil.info(TAG + ' new record ' + AnonymousUtil.anonymous(this.focusRecord.title));
    // instrument ignore if
    if (newRecordData.length === 0) {
      LogUtil.info(TAG + ' add new record error, newRecordData length is 0');
      return;
    }
    this.insertNewRecord(this.recordDataGroupList.allRecordList, newRecordData[0]);
    this.insertNewRecord(this.recordDataGroupList.normalRecordList, newRecordData[0]);

    let dataSource = this.recordDataGroupList.normalRecordList;
    // 解决折叠屏场景下同步新增录音数据到播放详情界面，数据变化时执行
    // instrument ignore if
    LogUtil.info(TAG + ' totalCount: ' + dataSource.totalCount() + ', sideFolderNameFlag: ' + this.sideFolderNameFlag);
    if (dataSource.totalCount() > 0 && this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
      LogUtil.info(TAG + ' add new record, set data source.');
      this.focusRecord.isNeedPlay = false;
      PlayManager.getInstance().setDataSource('onAddNewRecord', this.focusRecord);
    }
    // 从录音页面返回列表页面的时延及打点
    const time: number = new Date().getTime() - startTime;
    let callNum = 'CallRecord: ' + this.recordDataGroupList.callRecordList.totalCount();
    let normalNum = ', NormalRecord: ' + this.recordDataGroupList.normalRecordList.totalCount();
    let headsetNum = ', headsetRecord: ' + this.recordDataGroupList.headsetRecordList.totalCount();
    let recentDeleteNum = ', recentDeleteNum: ' + this.recordDataGroupList.recentDeleteList.totalCount();
    HiSysEventUtil.eventDotting(HiSysEventName.SAVE_RECORD,
      {
        VALUE: 1,
        DURATION: time,
        RECORD_TIME: newRecordData[0].duration,
        NUM: callNum + normalNum + headsetNum + recentDeleteNum
      }
    );
    this.onRecordDataGroupListChange();
    hiTraceMeter.finishTrace('onAddNewRecord', 1);
  }

  /* instrument ignore next */
  private getRecordListBySideFolderId(from: SideBarMode): LazyDataSource<RecordData> {
    LogUtil.info(TAG + ' getRecordListBySideFolderId: ' + from);
    switch (from) {
      case SideBarMode.ALL_RECORDINGS:
        return this.recordDataGroupList.allRecordList;
      case SideBarMode.AUDIO_RECORDINGS:
        return this.recordDataGroupList.normalRecordList;
      case SideBarMode.CALL_RECORDINGS:
        return this.recordDataGroupList.callRecordList;
      case SideBarMode.RECENT_DELETE_RECORDINGS:
        return this.recordDataGroupList.recentDeleteList;
      default:
        return this.recordDataGroupList.normalRecordList;
    }
  }

  /* instrument ignore next */
  private getRecordType(from: SideBarMode): RecordType {
    switch (from) {
      case SideBarMode.AUDIO_RECORDINGS:
        return RecordType.AUDIO_RECORD;
      case SideBarMode.CALL_RECORDINGS:
        return RecordType.CALL_RECORD;
      default:
        return RecordType.AUDIO_RECORD;
    }
  }

  /* instrument ignore next */
  private async calculateNewFocusRecord(lastFocusRecord: RecordData, removedData: RecordData[],
    dataSource: LazyDataSource<RecordData>): Promise<RecordData> {
    let removedRecord = removedData.map(item => item._data);
    let lastFocusRecordIndex = dataSource.findIndexOf(lastFocusRecord);
    let recordCount = dataSource.totalCount();
    let recordList = dataSource.getAll();

    const removedRecordSet = new Set(removedRecord);
    for (let i = lastFocusRecordIndex + 1; i < recordCount; i++) {
      let record = recordList[i];
      if (!removedRecordSet.has(record._data)) {
        return record;
      }
    }

    for (let i = lastFocusRecordIndex - 1; i >= 0; i--) {
      let record = recordList[i];
      if (!removedRecordSet.has(record._data)) {
        return record;
      }
    }
    LogUtil.info(TAG + ' calculateNewFocusRecord, reset preference')
    const emptyRecord = new RecordData();
    await PreferencesUtil.put('focusRecord', emptyRecord);
    return emptyRecord;
  }

  // instrument ignore if
  private batchUpdateDataSourceInRemoveScene(removedData: RecordData[], removeFromRecycleBin: boolean,
    dataSource: LazyDataSource<RecordData>) {
    const filePaths = new Set(removedData.map(item => item._data))
    const normalDataSource: RecordData[] = [];
    const recentDataSource: RecordData[] = [];
    for (let index = 0; index < dataSource.totalCount(); index++) {
      const item = dataSource.getData(index);
      const path = item._data;
      item.flagSelect = false;
      if (filePaths.has(path) && !removeFromRecycleBin) {
        let restDays = DatabaseManager.getRestDays(item.deleteTime);
        item.remainDaysTip =
          getContext(this).resourceManager
            .getPluralStringValueSync($r('app.plural.remaining_days_plural').id, restDays);
        recentDataSource.push(item);
        filePaths.delete(path);
      } else {
        normalDataSource.push(item)
      }
    }

    if (!removeFromRecycleBin) {
      this.recordDataGroupList.recentDeleteList.batchPushItem(recentDataSource);
    }
    dataSource.updateAllData(normalDataSource);
  }

  // instrument ignore if
  private singleUpdateDataSourceInRemoveScene(removedData: RecordData[], removeFromRecycleBin: boolean,
    dataSource: LazyDataSource<RecordData>) {
    let removeDataIndexArr: number[] = [];
    for (let i = 0; i < removedData.length; i++) {
      // 通过多选选中并且移动到回收站的场景，需要将选中的记录的selectFlag置为false，避免在回收站内多选的时候，这些删除的记录处于选中状态
      removedData[i].flagSelect = false;
      let index = dataSource.findIndexOf(removedData[i]);
      LogUtil.info(TAG + ' findIndex : ' + index);

      if (index === -1) {
        continue;
      }
      removeDataIndexArr.push(index);
      // 如果不是从回收站删除的记录，还需要将删除的录音记录插入到回收站中
      if (!removeFromRecycleBin) {
        let deleteItem = dataSource.getData(index);
        let restDays = DatabaseManager.getRestDays(deleteItem.deleteTime);
        deleteItem.remainDaysTip =
          getContext(this)
            .resourceManager
            .getPluralStringValueSync($r('app.plural.remaining_days_plural').id, restDays);
        this.recordDataGroupList.recentDeleteList.insertItemWithOutNotify(deleteItem, 0);
      }
      dataSource.deleteItemByIndexWithOutNotify(index);
    }
    dataSource.reload();
    if (!removeFromRecycleBin) {
      this.recordDataGroupList.recentDeleteList.reload();
    }
    // 从性能考虑，当用户删除的录音记录条数小于100条的时候才考虑删除动效，否则的话使用loading
    LogUtil.info(TAG + ' onRemoveRecord dataSource length : ' + dataSource.totalCount() + ', removedData length : ' +
      removedData.length + ', removeDataIndexArr length : ' + removeDataIndexArr.length);
    // 全选删除dataSource.totalCount() == 0，record不存在，去除删除动效
    if (dataSource.totalCount() > 0) {
      ListAnimationUtil.deleteAnimation(dataSource, removedData, removeDataIndexArr, this.screenHeight);
    }
  }

  // 当在全部录音页签删除录音时，需要同时更新其他页签的数据源
  private updateOtherDataSourceRemoveInAllRecordsSideFolder(removedData: RecordData[]) {
    let callRecordPaths = new Set<string>();
    let normalRecordPaths = new Set<string>();
    let headsetRecordPaths = new Set<string>();
    for (let i = 0; i < removedData.length; i++) {
      const item = removedData[i];
      if (item.type === RecordType.CALL_RECORD) {
        callRecordPaths.add(item._data);
      } else if (item.type === RecordType.AUDIO_RECORD) {
        normalRecordPaths.add(item._data);
      }
    }

    if (callRecordPaths.size > 0) {
      const callRecords: RecordData[] = [];
      for (let i = 0; i < this.recordDataGroupList.callRecordList.totalCount(); i++) {
        const item = this.recordDataGroupList.callRecordList.getData(i);
        const path = item._data;
        if (!callRecordPaths.has(path)) {
          callRecords.push(item);
        }
      }
      this.recordDataGroupList.callRecordList.updateAllData(callRecords);
    }

    if (normalRecordPaths.size > 0) {
      const normalRecords: RecordData[] = [];
      for (let i = 0; i < this.recordDataGroupList.normalRecordList.totalCount(); i++) {
        const item = this.recordDataGroupList.normalRecordList.getData(i);
        const path = item._data;
        if (!normalRecordPaths.has(path)) {
          normalRecords.push(item);
        }
      }
      this.recordDataGroupList.normalRecordList.updateAllData(normalRecords);
    }

    if (headsetRecordPaths.size > 0) {
      const headsetRecords: RecordData[] = [];
      for (let i = 0; i < this.recordDataGroupList.headsetRecordList.totalCount(); i++) {
        const item = this.recordDataGroupList.headsetRecordList.getData(i);
        const path = item._data;
        if (!headsetRecordPaths.has(path)) {
          headsetRecords.push(item);
        }
      }
      this.recordDataGroupList.headsetRecordList.updateAllData(headsetRecords);
    }
  }

  // 当在其他录音页签删除录音时，需要同时更新全部页签的数据源
  private updateAllRecordsDataSourceRemoveInOthersSideFolder(removedData: RecordData[]) {
    const filePaths = new Set(removedData.map(item => item._data))
    const allRecords: RecordData[] = [];
    for (let i = 0; i < this.recordDataGroupList.allRecordList.totalCount(); i++) {
      const item = this.recordDataGroupList.allRecordList.getData(i);
      const path = item._data;
      if (!filePaths.has(path)) {
        allRecords.push(item);
      }
    }
    this.recordDataGroupList.allRecordList.updateAllData(allRecords);
  }

  private onRemoveRecord = async (removedData: RecordData[], removeFromRecycleBin: boolean = false) => {
    hiTraceMeter.startTrace('onRemoveRecord', 1);
    LogUtil.info(TAG + ' removeFromRecycleBin: ' + removeFromRecycleBin);
    LogUtil.info(TAG + ' remove record and refresh index of: ' + this.sideFolderName);
    LogUtil.info(TAG + ' removed record count: ' + removedData.length);
    // instrument ignore if
    if (this.focusRecord?._data === '') {
      this.focusRecord = await PreferencesUtil.get('focusRecord', new RecordData()) as RecordData;
    }
    let lastFocusRecord = this.focusRecord;

    // 从数据源中将删除的数据移除
    let dataSource = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
    if (removedData.findIndex(item => item._data === lastFocusRecord._data) !== -1) {
      LogUtil.info(TAG + ' focusRecord deleted, calculate new one.');
      this.focusRecord = await this.calculateNewFocusRecord(lastFocusRecord, removedData, dataSource);
    }

    // instrument ignore if
    if (removedData.length > 100) {
      this.batchUpdateDataSourceInRemoveScene(removedData, removeFromRecycleBin, dataSource);
    } else {
      this.singleUpdateDataSourceInRemoveScene(removedData, removeFromRecycleBin, dataSource);
    }

    // instrument ignore if
    if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
      this.updateOtherDataSourceRemoveInAllRecordsSideFolder(removedData);
    } else if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS ||
      this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
      this.updateAllRecordsDataSourceRemoveInOthersSideFolder(removedData);
    }

    // instrument ignore if
    if (this.isSearchMode) {
      getContext().eventHub.emit('updateSearchResult', CommonConstants.DELETE, removedData);
    }
    // 直板机模式下，如果在播放详情页上执行的删除，要回到主界面
    // instrument ignore if
    if (this.navMode === NavigationMode.Stack && this.pathStack.size() > 0) {
      LogUtil.info(TAG + ' click delete in record play page, delete done and back to index.');
      this.isShowRecordPlay = false;
      this.pathStack.pop(false);
    }

    LogUtil.info(TAG + ' set new focus record to av player: ' + AnonymousUtil.anonymous(this.focusRecord.title));
    // instrument ignore if
    if (this.focusRecord._data !== lastFocusRecord._data && this.focusRecord._data) {
      LogUtil.info(TAG + ' focusRecord changed, set data source.');
      this.focusRecord.isNeedPlay = false;
      PlayManager.getInstance().setDataSource('onRemoveRecord', this.focusRecord);
    }
    this.onRecordDataGroupListChange();
    getContext().eventHub.emit('closeProcessDetailDialog', 'onRemoveRecord');
    GlobalContext.getUIAbilityContext().eventHub?.emit('removeRecordHiSysEvent', removedData, CommonConstants.SUCCESS);
    hiTraceMeter.finishTrace('onRemoveRecord', 1);
  }

  // instrument ignore if
  private batchUpdateDataSourceInRecoverScene(recoverData: RecordData[], dataSource: LazyDataSource<RecordData>) {
    const filePaths = new Set(recoverData.map(item => item._data))
    const recentDataSource: RecordData[] = [];
    const allRecordDataSource: RecordData[] = [];
    const normalRecordDataSource: RecordData[] = [];
    const callRecordDataSource: RecordData[] = [];
    const headsetRecordDataSource: RecordData[] = [];
    for (let index = 0; index < dataSource.totalCount(); index++) {
      const item = dataSource.getData(index);
      const path = item._data;
      item.flagSelect = false;
      item.isSwipeExpanded = false;
      if (!filePaths.has(path)) {
        recentDataSource.push(item);
      } else if (item.phoneNumber) {
        item.deleteTime = 0;
        callRecordDataSource.push(item);
        allRecordDataSource.push(item);
      } else {
        item.deleteTime = 0;
        normalRecordDataSource.push(item);
        allRecordDataSource.push(item);
      }
    }
    this.recordDataGroupList.allRecordList.batchPushItem(allRecordDataSource);
    this.recordDataGroupList.headsetRecordList.batchPushItem(headsetRecordDataSource);
    this.recordDataGroupList.callRecordList.batchPushItem(callRecordDataSource);
    this.recordDataGroupList.normalRecordList.batchPushItem(normalRecordDataSource);
    dataSource.updateAllData(recentDataSource);
  }

  // instrument ignore if
  private singleUpdateDataSourceInRecoverScene(recoverData: RecordData[], dataSource: LazyDataSource<RecordData>) {
    let recoverDataIndexArr: number[] = [];
    for (let i = 0; i < recoverData.length; i++) {
      recoverData[i].flagSelect = false;
      recoverData[i].deleteTime = 0;
      recoverData[i].isSwipeExpanded = false;
      let index = dataSource.findIndexOf(recoverData[i]);
      if (index === -1) {
        continue;
      }
      recoverDataIndexArr.push(index);
      dataSource.deleteItemByIndexWithOutNotify(index);
    }
    this.recordDataGroupList.recentDeleteList.reload();
    // 从最近删除列表恢复时动效
    // 从性能考虑，当用户删除的录音记录条数小于100条的时候才考虑删除动效，否则的话使用loading;
    ListAnimationUtil.deleteAnimation(dataSource, this.selectedRecordList, recoverDataIndexArr, this.screenHeight);
    hiTraceMeter.finishTrace('onRecentDeleteRecover-recentDelete', 1);

    // reload通话录音数据源
    hiTraceMeter.startTrace('onRecentDeleteRecover-callRecord', 1);
    let callRecord = recoverData.filter(item => item.phoneNumber);
    if (callRecord.length > 0) {
      LogUtil.info(TAG + ' begin to reload call record.');
      this.recordDataGroupList.callRecordList.batchPushItem(callRecord);
      this.refreshCallRecord();
      this.recordDataGroupList.allRecordList.batchPushItem(callRecord);
      this.refreshAllRecord();
    }
    hiTraceMeter.finishTrace('onRecentDeleteRecover-callRecord', 1);

    // reload普通录音数据源
    hiTraceMeter.startTrace('onRecentDeleteRecover-normalRecord', 1);
    let normalRecord = recoverData.filter(item => !item.phoneNumber);
    if (normalRecord.length > 0) {
      LogUtil.info(TAG + ' begin to reload normal record.');
      this.recordDataGroupList.normalRecordList.batchPushItem(normalRecord);
      this.refreshNormalRecord();
      this.recordDataGroupList.allRecordList.batchPushItem(normalRecord);
      this.refreshAllRecord();
    }
    hiTraceMeter.finishTrace('onRecentDeleteRecover-headsetRecord', 1);
  }

  private onRecentDeleteRecover = async (recoverData: RecordData[]) => {
    hiTraceMeter.startTrace('onRecentDeleteRecover', 1);
    LogUtil.info(TAG + ' onRecentDeleteRecover and refresh index of: ' + this.sideFolderName);
    LogUtil.info(TAG + ' recover record count: ' + recoverData.length);
    let lastFocusRecord = this.focusRecord;

    hiTraceMeter.startTrace('onRecentDeleteRecover-recentDelete', 1);
    let dataSource = this.recordDataGroupList.recentDeleteList;
    if (recoverData.findIndex(item => item._data === lastFocusRecord._data) !== -1) {
      LogUtil.info(TAG + ' focusRecord recovered, calculate new one.');
      this.focusRecord = await this.calculateNewFocusRecord(lastFocusRecord, recoverData, dataSource);
    }
    // instrument ignore if
    if (recoverData.length >= 100) {
      this.batchUpdateDataSourceInRecoverScene(recoverData, dataSource);
    } else {
      this.singleUpdateDataSourceInRecoverScene(recoverData, dataSource);
    }

    if (this.focusRecord._data !== lastFocusRecord._data && this.focusRecord._data) {
      LogUtil.info(TAG + ' focusRecord changed, set data source.');
      this.focusRecord.isNeedPlay = false;
      PlayManager.getInstance().setDataSource('onRecentDeleteRecover', this.focusRecord);
    }
    this.onRecordDataGroupListChange();
    getContext().eventHub.emit('closeProcessDetailDialog', 'onRecentDeleteRecover');
    hiTraceMeter.finishTrace('onRecentDeleteRecover-normalRecord', 1);
    hiTraceMeter.finishTrace('onRecentDeleteRecover', 1);
  }
  private onUpdateRecord = async (oldRecord: RecordData, newRecord: RecordData) => {
    LogUtil.info(TAG + ' trigger updateIndexList: ' + AnonymousUtil.anonymous(oldRecord.name) + ' to: ' +
      AnonymousUtil.anonymous(newRecord.name));
    let dataSource = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
    let index = dataSource.getAll().findIndex(item => item._data === oldRecord._data);
    dataSource.updateData(index, newRecord);

    // instrument ignore if
    if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS ||
      this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
      let index = this.recordDataGroupList.allRecordList.getAll().findIndex(item => item._data === oldRecord._data);
      this.recordDataGroupList.allRecordList.updateData(index, newRecord);
    }

    // instrument ignore if
    if (this.isSearchMode) {
      getContext().eventHub.emit('updateSearchResult', CommonConstants.UPDATE, [newRecord]);
    }
    // instrument ignore if
    if (this.sortType === SortType.SORT_NAME_ASC) {
      this.sortRecordList();
    }
  }

  /* instrument ignore next */
  private showSaveFileToastCallback(data: DataToast): void {
    const context = GlobalContext.getUIAbilityContext();
    if (data.isShow) {
      let timerOut = setTimeout(() => {
        let message = context?.resourceManager.getStringSync($r('app.string.store_as_filename').id, data.fileName);
        Util.showToast(message, false, data.isInBackground);
        clearTimeout(timerOut);
      }, 1000);
    }
  }

  /* instrument ignore next */
  private async handleStartFromShortCut(): Promise<void> {
    let isStartFromShortCut = AppStorage.get<boolean>('shortCutStartRecord');
    LogUtil.info(TAG + ' handleStartFromShortCut: ' + isStartFromShortCut);
    if (isStartFromShortCut) {
      this.startRecord();
      HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
        { VALUE: DFXEnumConstants.StartRecordResource.SHORTCUT });
      AppStorage.setOrCreate('shortCutStartRecord', false);
      AppStorage.setOrCreate('isFirstEnter', false);
    }
  }

  private handleStartFromLockScreen(): void {
    let isStartFromLockScreen = AppStorage.get<boolean>('recordingFromLock');
    LogUtil.info(TAG + ' handleStartFromLockScreen isStartFromLockScreen ' + isStartFromLockScreen);
    // instrument ignore if
    if (isStartFromLockScreen) {
      this.isFromLockScreenRecord = true;
      this.startRecord();
      HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
        { VALUE: DFXEnumConstants.StartRecordResource.LOCKSCREEN_CARD });
      AppStorage.setOrCreate('recordingFromLock', false);
      AppStorage.setOrCreate('isFirstEnter', false);
    }
  }

  /**
   * 引入回收站之后需要检查一下数据的一致性，防止出现文件存在，但是没有录音记录，或者出现录音记录存在，但是没有文件的情况
   * @param recordType
   * @returns
   */
  /* instrument ignore next */
  private async checkDataConsistency(recordType: string): Promise<void> {
    LogUtil.info(TAG + ' checkDataConsistency begin.');

    if (recordType === 'call_recordings') {
      let callRecordList = await DatabaseManager.getInitialCallRecordList();
      let invalidRecord: string[] = [];
      for (let i = 0; i < callRecordList.length; i++) {
        if (!fs.accessSync(callRecordList[i]._data)) {
          invalidRecord.push(callRecordList[i]._data);
        }
      }
      await DatabaseManager.removeCallRecordData(invalidRecord);
    }

    if (recordType === 'recordings') {
      let normalRecordList = await DatabaseManager.getAllDbQuery('normal_record_table');
      let invalidRecord: string[] = [];
      for (let i = 0; i < normalRecordList.length; i++) {
        if (!fs.accessSync(normalRecordList[i]._data)) {
          invalidRecord.push(normalRecordList[i]._data);
        }
      }
      await DatabaseManager.removeNormalRecordData(invalidRecord);

      let recentDeleteRecordList = await DatabaseManager.getAllDbQuery('recent_delete_record_table');
      invalidRecord = [];
      for (let i = 0; i < recentDeleteRecordList.length; i++) {
        if (!fs.accessSync(recentDeleteRecordList[i]._data)) {
          invalidRecord.push(recentDeleteRecordList[i]._data);
        }
      }
      await DatabaseManager.removeRecentDeleteRecordData(invalidRecord);
    }
  }

  /* instrument ignore next */
  private async initTipsCondition(): Promise<void> {
    const locationGrantStatus = await MediaController.checkAccessToken('ohos.permission.LOCATION');
    const nonPreciseLocationGrant = await MediaController.checkAccessToken('ohos.permission.APPROXIMATELY_LOCATION');
    LogUtil.info(`${TAG} locationGrant : ${locationGrantStatus}, nonPreciseGrant : ${nonPreciseLocationGrant}`);
    const hasRequested = locationGrantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_DENIED ||
      nonPreciseLocationGrant !== abilityAccessCtrl.GrantStatus.PERMISSION_DENIED;
    this.isUserAllow = hasRequested || await PreferencesUtil.get('isUserGrantedLocation', false) as boolean;
    this.tipsCloseTime = await PreferencesUtil.get('tipsCloseTime', 0) as number;
    let currentTime: number = Date.now();
    this.isOverOneWeek = (currentTime - this.tipsCloseTime) / (TIME_FOR_ONE_DAY) >= DAYS_FOR_ONE_WEEK;
    this.isTipsClose = !this.isOverOneWeek && this.tipsCloseTime !== 0;
    LogUtil.info(TAG + ' initTipsCondition isUserAllow : ' + this.isUserAllow + ', isTipsClose : ' + this.isTipsClose +
      ', isOverOneWeek : ' + this.isOverOneWeek);
  }

  private dataShareChanged = (err: Base.BusinessError) => {
    if (err) {
      LogUtil.error(`${TAG} data share failed.`);
      return;
    }
    LogUtil.info(`${TAG} call record changes in CallRecord app.`);
    this.handleCallRecordingAdded();
  }
  private flushRecordsToNormalRecords = async (records: RecordData[]) => {
    const list = this.recordDataGroupList.normalRecordList;
    const data = list.getAll().slice();
    data.push(...records);
    await this.sortNormalRecordList(data);
    list.deleteAll();
    list.batchPushItem(data);
    this.recordingCount = this.recordDataGroupList.normalRecordList.totalCount();
    LogUtil.log(`${TAG} flush records: ${records.length}`);
  }

  // 定义持续定位参数
  request: geoLocationManager.ContinuousLocationRequest= {
    'interval': 1,
    'locationScenario': geoLocationManager.UserActivityScenario.NAVIGATION
  }
  // 持续定位回调函数
  locationCallback = (location:geoLocationManager.Location):void => {
    // 弹窗只是为了方便看到数据，验证没问题可注释，下面同理
    // this.getUIContext().getPromptAction().showToast({message:'开启成功'+JSON.stringify(location)})
    LogUtil.log(`${TAG} locationCallback: data: ${JSON.stringify(location)}`);
  };
  //卫星监听回调函数
  gnssStatusCb = (satelliteStatusInfo:geoLocationManager.SatelliteStatusInfo):void => {
    LogUtil.log(`${TAG} satelliteStatusChange: ${JSON.stringify(satelliteStatusInfo)}`);
    // this.getUIContext().getPromptAction().showToast({message:'卫星数量：'+satelliteStatusInfo.satellitesNumber})
  }

  /* instrument ignore next */
  async aboutToAppear() {
    const ctx = getContext();
    const eventHub = ctx.eventHub;
    eventHub.on(Events.FLUSH_RECORDS_TO_UI_LIST, this.flushRecordsToNormalRecords);
    eventHub.on(Events.UPDATE_GROUP_LIST_COUNT, () => this.onRecordDataGroupListChange());
    eventHub.on('updateIndexList', this.onUpdateRecord);
    eventHub.on('addIndexList', this.onAddNewRecord);
    eventHub.on('removeIndexList', this.onRemoveRecord);
    eventHub.on('recentDeleteRecover', this.onRecentDeleteRecover);
    eventHub.on('fileDeleted', this.showFileDeletedDialog);
    eventHub.on('renameSelectedRecord', this.renameSelectedRecord);
    eventHub.on('showRecordDetail', this.showRecordDetail);
    eventHub.on('isShowToast', this.showSaveFileToastCallback);
    eventHub.on('checkConsistency', this.checkDataConsistency);
    eventHub.on('newWantJumpFromLock', this.handleJumpFromLockScreenWhenBackground.bind(this));
    eventHub.on('detailDialogClose', this.detailDialogClose.bind(this));
    eventHub.on('detailDialogOpen', this.detailDialogOpen.bind(this));
    eventHub.on('exitPageToRecording', this.exitPageToRecording);
    const player = PlayManager.getInstance();
    player.setPlayStateCallback(TAG, this.playerStateChangeCallback);
    player.setTimeUpdateCallback(TAG, this.playerTimeUpdateCallback);
    this.initTipsCondition();
    hiTraceMeter.startTrace('aboutToAppear', 1);
    this.isTripleFold = AppStorage.get(CommonConstants.IS_TRIPLE_FOLD_DEVICE) as boolean;
    LogUtil.info(TAG + ' aboutToAppear: ' + this.sideFolderNameFlag);
    // 开启位置监听（持续定位）和卫星监听
    try {
      geoLocationManager.on('locationChange', this.request, this.locationCallback);
      geoLocationManager.on('satelliteStatusChange', this.gnssStatusCb);
    } catch (err) {
      LogUtil.log(`${TAG} errCode: ${JSON.stringify(err)}`);
    }
    this.lastIsExpanded = DeviceUtil.isExpanded();
    await DatabaseManager.init(getContext());
    RecordDbManager.init();
    await this.initRecordList();
    FileManager.init(this.recordDataGroupList);
    DatabaseManager.registerDataChangeToDataShare(this.dataShareChanged);

    this.getUIContext().bindTabsToScrollable(this.tabsController, this.listScroller);
    this.registerScreenListener();
    this.registerCloneDoneListener();
    this.handleStartFromShortCut();
    this.handleStartFromLockScreen();
    this.isExitTopAction = true;
    this.windowSizeChangeCallback();
    this.initIsDemo();
    // 语音转文本首选项查询
    AppStorage.setOrCreate('isAgreeQuickTrans', this.isDemo ? true :
      await PreferencesUtil.get(Preferences.IS_AGREE_QUICK_TRANS, false) as boolean);
    this.isShowQuickTrans = await PreferencesUtil.get(Preferences.IS_QUICK_TRANS, false) as boolean;
    hiTraceMeter.finishTrace('aboutToAppear', 1);
  }

  initIsDemo() {
    try {
      let value: string = systemparameter.getSync('const.dfx.enable_retail');
      this.isDemo = Boolean(value).valueOf();
    } catch (e) {
      LogUtil.error(TAG + ' initIsDemo: ' + e);
    }
  }

  private async isRecodingAndShowRecordPage(): Promise<void> {
    if (!this.isRecordingSaveDone) {
      return;
    }
    let isShortCutRecordList = AppStorage.get<boolean>('shortCutRecordList');
    if (isShortCutRecordList) {
      LogUtil.info(TAG + 'access from the shortCut recordList and do not start a new recording.');
      return;
    }
    RecordManager.getInstance().getAvRecorderState().then((state) => {
      LogUtil.info(TAG + ` index getAvRecorderState is ` + state);
      // instrument ignore if
      if (state === 'started' || state === 'paused') {
        this.sideFolderNameFlag = SideBarMode.ALL_RECORDINGS;
        this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
        if (!this.isShowRecord) {
          this.routeToRecordingPage();
        }
      }
    });
  }

  private onFocusRecordChange(): void {
    this.isFocusRecordChanged = true;
  }

  private onPageStateChange() {
    LogUtil.info(TAG + ' onPageStateChange: ' + this.isPageHide);
    if (!this.isPageHide && this.currentTimePlayTemp >= 0) {
      this.currentTimePlay = this.currentTimePlayTemp;
    } else {
      this.currentTimePlayTemp = -1;
    }
  }

  private playerStateChangeCallback = (state: string) => {
    LogUtil.info(TAG + ' playerStateChangeCallback state is ' + state);
    this.state = state;
  }
  private playerTimeUpdateCallback = (time: number) => {
    // 主页面切换录音后，由于收到时间回调的延迟，当前time可能为上一条录音的切换时间，不应改变currentTimePlay
    if (this.isFocusRecordChanged && this.currentTimePlay <= time && this.currentTimePlay === 0) {
      this.isFocusRecordChanged = false;
    } else if (AppStorage.get('isSeeked') && this.currentTimePlay - time < 300) {
      // seek后，由于收到时间回调的延迟，time可能早于currentTimePlay，在时间回调大于currentTimePlay时实时修改进度
      if (time > this.currentTimePlay) {
        this.currentTimePlay = time;
        AppStorage.setOrCreate('isSeeked', false);
      }
    } else if (this.isPageHide) {
      this.currentTimePlayTemp = time;
    } else {
      this.currentTimePlay = time;
    }
  }

  /* instrument ignore next */
  async onPageShow() {
    // refresh the sound record list after private space migration
    const isMigration = AppStorage.get('isMigration') || false;
    if (isMigration) {
      LogUtil.info(TAG + ` isMigration, refresh data`);
      AppStorage.setOrCreate('isMigration', false);
      this.initRecordList();
    }
    hiTraceMeter.startTrace('onPageShow', 1);
    LogUtil.info(TAG + ` onPageShow`);
    this.isVerdeFolded = DeviceUtil.isSmallFoldVer() && DeviceUtil.isFolded();
    this.isSmallFoldSplit = this.getSmallFoldSplit();
    this.isPageHide = false;
    await this.isRecodingAndShowRecordPage();
    AppStorage.setOrCreate('jumpFromSceneBoard', false);

    // 录音机在后台运行时，从桌面快捷方式跳转到录音机录制界面
    this.handleJumpFormShortCutWhenBackground();

    // 录音机在后台运行时，从录音机应用的通话录音菜单选项跳转到录音机
    this.handleJumpFormContactsWhenBackground();

    // 1.申请权限
    this.requestStatePermission();
    if (this.jumpFromDoubleX) {
      // 双击X键跳转到录音机
      setTimeout(() => {
        AppStorage.setOrCreate('jumpFromDoubleX', false);
        this.startRecord();
      }, 500)
      HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
        { VALUE: DFXEnumConstants.StartRecordResource.SHORTCUT });
    }

    hiTraceMeter.finishTrace('onPageShow', 1);
  }

  /* instrument ignore next */
  aboutToDisappear() {
    LogUtil.info(TAG + ' aboutToDisappear.');
    this.saveFocusRecord();
    const ctx = getContext();
    const eventHub = ctx.eventHub;
    eventHub.off(Events.FLUSH_RECORDS_TO_UI_LIST, this.flushRecordsToNormalRecords);
    eventHub.off(Events.UPDATE_GROUP_LIST_COUNT);
    eventHub.off('updateIndexList', this.onUpdateRecord);
    eventHub.off('addIndexList', this.onAddNewRecord);
    eventHub.off('removeIndexList', this.onRemoveRecord);
    eventHub.off('fileDeleted', this.showFileDeletedDialog);
    eventHub.off('renameSelectedRecord', this.renameSelectedRecord);
    eventHub.off('showRecordDetail', this.showRecordDetail);
    eventHub.off('isShowToast', this.showSaveFileToastCallback);
    eventHub.off('recentDeleteRecover', this.onRecentDeleteRecover);
    eventHub.off('checkConsistency', this.checkDataConsistency);
    eventHub.off('newWantJumpFromLock', this.handleJumpFromLockScreenWhenBackground.bind(this));
    eventHub.off('detailDialogClose', this.detailDialogClose.bind(this));
    eventHub.off('detailDialogOpen', this.detailDialogOpen.bind(this));
    eventHub.off('exitPageToRecording', this.exitPageToRecording);

    eventHub.off('changeFocus');
    eventHub.off('changeFocusState');
    // 关闭位置监听和卫星监听
    geoLocationManager.off('locationChange', this.locationCallback);
    geoLocationManager.off('satelliteStatusChange', this.gnssStatusCb);
    const player = PlayManager.getInstance();
    player.unsetPlayStateCallback(TAG);
    player.unsetTimeUpdateCallback(TAG);
    this.getUIContext().unbindTabsFromScrollable(this.tabsController, this.listScroller);
    PlayManager.getInstance().release();
    this.unRegisterScreenListener();
    // 暂停长时任务
    ContinuousTask.stopContinuousTask(getContext(), TAG);
  }

  /* instrument ignore next */
  onPageHide() {
    LogUtil.info(TAG + ' onPageHide.');
    AppStorage.setOrCreate('jumpFromContacts', false);
    this.isPageHide = true;
  }

  /* instrument ignore next */
  private async saveFocusRecord() {
    let firstRecord = this.recordDataGroupList.normalRecordList.totalCount() > 0 ?
      this.recordDataGroupList.normalRecordList.getData(0) : new RecordData();
    LogUtil.info(TAG + ' saveFocusRecordForDestroy, normal record is null : ' + (!firstRecord));
    await PreferencesUtil.putFlushSync('focusRecord', firstRecord);
  }

  // 单个通话录音增加
  /* instrument ignore next */
  private handleCallRecordingAdded = Helps.debounce(async (): Promise<void> => {
    let callRecordCount = await DatabaseManager.getCallRecordCount();
    LogUtil.info(`${TAG} handleCallRecordingsAdded, callRecordCount: ${callRecordCount}
      callRecordCountInCallAppDatabase: ${this.callRecordCountInCallAppDatabase}`);
    if (callRecordCount <= this.callRecordCountInCallAppDatabase) {
      LogUtil.error(TAG + ' no new call record added, return.');
      this.callRecordCountInCallAppDatabase = callRecordCount;
      return;
    }
    LogUtil.info(`${TAG} new call record added.`);
    let filePathLst = this.recordDataGroupList.callRecordList.getAll().map(item => item._data);
    // 从数据库中取出来最新添加的通话录音记录
    let allCallRecordList = await DatabaseManager.getInitialCallRecordList();
    let newDataList = allCallRecordList.filter((item) => !filePathLst.includes(item._data));
    if (newDataList.length === 0) {
      LogUtil.info(`${TAG} Filter out calls without new recordings`);
      return;
    }

    for (const record of newDataList) {
      if (record.contacts) {
        continue;
      }
      ContactsManagerUtil.getInstance().updateNewCallRecordName(record);
      // 新通话录音默认放在第一个
      this.recordDataGroupList.callRecordList.insertItem(record, 0);
      this.recordDataGroupList.allRecordList.insertItem(record, 0);
    }

    this.refreshCallRecord();
    this.refreshAllRecord();
    this.onRecordDataGroupListChange();
    this.callRecordCountInCallAppDatabase = callRecordCount;
  }, 1000)

  // 多个通话录音增加
  /* instrument ignore next */
  private async handleCallRecordingsAdded(): Promise<void> {
    let allRecords = await DatabaseManager.getInitialCallRecordList();
    this.callRecordCountInCallAppDatabase = allRecords.length;
    // 处理通话录音
    let callRecordList = allRecords.filter(item => item.delete === 0);
    let curCallRecordList = this.recordDataGroupList.callRecordList;
    const curCallRecordPathsSet = new Set(curCallRecordList.getAll().map(item => item._data));
    let newCallRecords = callRecordList.filter(item => !curCallRecordPathsSet.has(item._data));
    newCallRecords.forEach((item): void => curCallRecordList.addItem(item));
    DatabaseManager.sortRecords(curCallRecordList.getAll(), this.sortType);
    curCallRecordList.reload();

    // 同时更新全部录音
    let curAllRecordList = this.recordDataGroupList.allRecordList;
    newCallRecords.forEach((item): void => curAllRecordList.addItem(item));
    DatabaseManager.sortRecords(curAllRecordList.getAll(), this.sortType);
    curAllRecordList.reload();

    // 处理回收站中的通话录音
    let recentDeleteCallRecordList = allRecords.filter(item => item.delete === 1);
    let recentDeleteList = this.recordDataGroupList.recentDeleteList;
    const recentDeletePathsSet = new Set(recentDeleteList.getAll().map(item => item._data));
    let newRecentDeleteCallRecords = recentDeleteCallRecordList.filter(item => !recentDeletePathsSet.has(item._data));
    newRecentDeleteCallRecords.forEach((item): void => recentDeleteList.addItem(item));
    recentDeleteList.getAll().sort((a, b) => b.deleteTime - a.deleteTime);
    recentDeleteList.reload();

    // 更新命名索引
    ContactsManagerUtil.getInstance().updateCallRecordIndex(getContext(), allRecords);
  }

  // 普通录音增加
  /* instrument ignore next */
  private async handleAudioRecordingsAdded(): Promise<void> {
    const newNormalRecords = await DatabaseManager.getAllDbQuery('normal_record_table');
    const normalRecordList = this.recordDataGroupList.normalRecordList;
    const filterRecords = newNormalRecords.filter(i => normalRecordList.findIndexOf(i) === -1);
    filterRecords.forEach((i): void => normalRecordList.addItem(i));
    DatabaseManager.sortRecords(normalRecordList.getAll(), this.sortType);
    normalRecordList.reload();

    let curAllRecordList = this.recordDataGroupList.allRecordList;
    filterRecords.forEach((item): void => curAllRecordList.addItem(item));
    DatabaseManager.sortRecords(curAllRecordList.getAll(), this.sortType);
    curAllRecordList.reload();
  }

  // 回收站中录音增加
  /* instrument ignore next */
  private async handleRecentDeleteRecordingsAdded(): Promise<void> {
    const allRecords = await DatabaseManager.getAllDbQuery('recent_delete_record_table');
    const recentDeleteList = this.recordDataGroupList.recentDeleteList;
    const filterRecords = allRecords.filter(i => recentDeleteList.findIndexOf(i) === -1);
    filterRecords.forEach((i): void => recentDeleteList.addItem(i));
    recentDeleteList.getAll().sort((a, b) => b.deleteTime - a.deleteTime);
    recentDeleteList.reload();
  }

  /* instrument ignore next */
  private handleJumpFormShortCutWhenBackground(): void {
    let isShortCutStartRecord = AppStorage.get<boolean>('shortCutStartRecord');
    let isShortCutRecordList = AppStorage.get<boolean>('shortCutRecordList');
    LogUtil.info(`${TAG} handleJumpFormShortCutWhenBackground: isShortCutStartRecord ${isShortCutStartRecord}`);
    LogUtil.info(`${TAG} handleJumpFormShortCutWhenBackground: isShortCutRecordList ${isShortCutRecordList}`);
    this.isShortCutList = false;
    if (isShortCutRecordList) {
      this.exitPageToRecording();
      this.sideFolderNameFlag = SideBarMode.ALL_RECORDINGS;
      this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
      AppStorage.setOrCreate('shortCutRecordList', false);
      this.jumpFromShortCut = true;
      this.isShortCutList = true;
      this.selectedRecordList = [];
    }
    if (isShortCutStartRecord && !AppStorage.get('isFirstEnter')) {
      this.exitPageToRecording();
      this.sideFolderNameFlag = SideBarMode.ALL_RECORDINGS;
      this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
      this.startRecord();
      HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
        { VALUE: DFXEnumConstants.StartRecordResource.SHORTCUT });
      AppStorage.setOrCreate('shortCutStartRecord', false);
      this.jumpFromShortCut = true;
      this.selectedRecordList = [];
    }
  }

  /* instrument ignore next */
  private handleJumpFromLockScreenWhenBackground(): void {
    let isLockScreenStartRecord = AppStorage.get<boolean>('recordingFromLock');
    LogUtil.info(`${TAG} handleJumpFromLockScreenWhenBackground: isLockScreenStartRecord ${isLockScreenStartRecord}`);
    if (isLockScreenStartRecord && !AppStorage.get('isFirstEnter')) {
      LogUtil.info(`${TAG} handleJumpFromLockScreenWhenBackground isShowRecord: ${this.isShowRecord}}`);
      this.exitPageToRecording();
      this.isFromLockScreenRecord = true;
      this.sideFolderNameFlag = SideBarMode.ALL_RECORDINGS;
      this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
      this.startRecord();
      HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
        { VALUE: DFXEnumConstants.StartRecordResource.LOCKSCREEN_CARD });
      AppStorage.setOrCreate('recordingFromLock', false);
    }
  }

  /* instrument ignore next */
  private async handleJumpFormContactsWhenBackground(): Promise<void> {
    if (this.jumpFromShortCut) {
      this.jumpFromShortCut = false;
      AppStorage.setOrCreate('jumpFromSceneBoard', false);
      return;
    }
    // 这里是录音机应用已经打开并且在后台运行时，用户点击从通话录音菜单入口进入录音机
    this.jumpFromContacts = AppStorage.get('jumpFromContacts') as boolean;
    LogUtil.info(TAG + ' is jump from contacts: ' + this.jumpFromContacts);
    if ((!this.jumpFromContacts && !this.jumpFromSceneBoard && !AppStorage.get('jumpFromNotification')) ||
      this.isShowRecord) {
      LogUtil.info(TAG + ' not from jump or current is recording, skip!');
      let callAppId = AppStorage.get('callAPPId') || -1;
      if (callAppId > 0) {
        AppStorage.setOrCreate('callAPPId', -1);
      }
      return;
    }
    this.sideFolderNameFlag = SideBarMode.CALL_RECORDINGS;
    this.sideFolderName = this.getSideFolderName(this.sideFolderNameFlag);
    AppStorage.setOrCreate('jumpFromContacts', false);
    AppStorage.setOrCreate('jumpFromSceneBoard', false);
    AppStorage.setOrCreate('jumpFromNotification', false);
    LogUtil.info(TAG + ' sideFolderNameFlag: ' + this.sideFolderNameFlag + ' sideFolderName: ' + this.sideFolderName);
    this.jumpFromSceneBoard = false;
    getContext().eventHub.emit('callRecordJump');
  }

  /* instrument ignore next */
  private exitPageToRecording = () => {
    LogUtil.info(TAG + ` exitPageToRecording`);
    this.isShowRecordPlay = false;
    this.isEditMode = false;
    this.isSearchMode = false;
    this.isExitPageToQuickRecord = true;
    this.showAboutPage = false;
    this.showPersonalDataPage = false;
    this.renameDialogController?.close();
    this.audioRecordListContrRef?.deleteDialogController?.close();
    this.detailDialogController?.close();
    this.fileDeletedController?.close();
    this.isShowSideBar = false;
    getContext().eventHub.emit('renameDialogClose');
  }

  /* instrument ignore next */
  private handlePressEsc(): boolean {
    if (this.isEditMode) {
      this.exitEditMode();
      return true;
    }
    if (this.isShowSideBar) {
      this.runSideBarAnimation(() => {
        this.isShowSideBar = false;
        this.isShowOverlay = false;
      })
      return true;
    }
    return false;
  }

  /* instrument ignore next */
  onBackPress() {
    if (this.handlePressEsc()) {
      return true;
    }
    if (this.isSearchMode) {
      animateTo({
        curve: curves.interpolatingSpring(0, 1, 342, 38)
      }, () => {
        this.isSearchMode = false;
      });
      return true;
    }
    if (this.navMode == NavigationMode.Stack) {
      // 直板机或折叠机折叠态,手势返回就重置player
      PlayManager.getInstance().reset();
    }
    return false;
  }

  //详情名称
  private getName(): string {
    const selectedItem = this.detailRecord;
    const indexForPoint = selectedItem.title.lastIndexOf('.');
    const fileType = selectedItem.title.substring(indexForPoint)
    return `${selectedItem.name}${fileType}`
  }

  //详情日期
  private getDates(): string {
    let locale = new Intl.Locale();
    let dateTimeFormat = new Intl.DateTimeFormat(locale.toString(), { dateStyle: 'medium', timeStyle: 'medium' });
    return dateTimeFormat.format(new Date(this.detailRecord.date));
  }

  // 获取文件size
  /* instrument ignore next */
  private getSize(): string {
    let numToString: number = 0;
    try {
      LogUtil.info('get size of pathDir');
      let curpathDir = this.detailRecord._data;
      let stat = fs.statSync(curpathDir);
      numToString = stat.size;
    } catch (err) {
      LogUtil.error(TAG + ` get size of pathDir error, code: ${err?.code}, message: ${err?.message}`);
    }
    let n: string = util.format('%s', Util.formatFileSizeFlexible(numToString));
    LogUtil.info('file size: ' + n);
    return n;
  }

  // 申请获取电话状态权限
  private async requestStatePermission() {
    let permissionList: Permissions[] = ['ohos.permission.GET_TELEPHONY_STATE'];
    await abilityAccessCtrl.createAtManager().requestPermissionsFromUser(getContext(), permissionList);
  }

  // 全选判断
  /* instrument ignore next */
  selectAllHandle(isAllSelected: boolean) {
    // 全选 全不选 部分选中
    let dataSource = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
    if (isAllSelected) {
      LogUtil.info(TAG + ' unselect all. ');
      dataSource.forEach(item => item.flagSelect = false);
      this.selectedRecordList = [];
      this.isSelectedAllAudio = false;
      AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.toolbar_select_all'),
        ''));
    } else {
      LogUtil.info(TAG + ' select all. ');
      dataSource.forEach(item => item.flagSelect = true);
      this.selectedRecordList = dataSource.getAll().filter(item => item);
      LogUtil.info(TAG + ' select all: ' + this.selectedRecordList.length);
      this.isSelectedAllAudio = true;
      AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.toolbar_cancel_select_all'),
        ''));
    }
  }

  /* instrument ignore next */
  private isMatchNewFocus(afterDeleteRecordData: RecordData[], newFocus: RecordData): boolean {
    let index = afterDeleteRecordData.findIndex(item => item.title === newFocus.title);
    LogUtil.info(TAG + ' isMatchNewFocus  index : ' + index);
    if (index !== -1) {
      // if selected record form beforeDeleteRecordData is in afterDeleteRecordData, use it as new focusRecord.
      this.focusRecord = afterDeleteRecordData[index];
      LogUtil.info(TAG + ' update RecordPlayPage to: ' + AnonymousUtil.anonymous(this.focusRecord.title));
      return true;
    }
    return false;
  }

  /* instrument ignore next */
  private findNewFocusRecord(startFindPosition: number, finishFindPosition: number,
    beforeDeleteRecordData: RecordData[], afterDeleteRecordData: RecordData[]): boolean {
    // find a record in beforeDeleteRecordData from startFindPosition to finishFindPosition
    LogUtil.info(TAG + ' startFindPosition : ' + startFindPosition + ', finishFindPosition : ' + finishFindPosition);
    if (startFindPosition <= finishFindPosition) {
      for (let i = startFindPosition; i < finishFindPosition; i++) {
        if (this.isMatchNewFocus(afterDeleteRecordData, beforeDeleteRecordData[i])) {
          return true;
        }
      }
    } else {
      for (let i = startFindPosition; i >= finishFindPosition; i--) {
        if (this.isMatchNewFocus(afterDeleteRecordData, beforeDeleteRecordData[i])) {
          return true;
        }
      }
    }
    return false;
  }

  /* instrument ignore next */
  private updateRecordPlayPageAfterDelete(beforeDeleteRecordData: RecordData[], afterDeleteRecordData: RecordData[]) {
    if (!this.focusRecord) {
      LogUtil.info(TAG + ' updateRecordPlayPageAfterDelete error, focusRecord is null.');
      return;
    }
    if (afterDeleteRecordData.findIndex(item => item.title === this.focusRecord?.title) !== -1) {
      LogUtil.info(TAG + ' focusRecord does not delete, no need to update record play page.');
      return;
    }
    // focusRecord is deleted, find a new one
    let focusRecordIndexBeforeDelete = beforeDeleteRecordData.findIndex(item => item.title === this.focusRecord?.title);
    LogUtil.info(TAG + ' focusRecord index before delete is: ' + focusRecordIndexBeforeDelete);
    if (afterDeleteRecordData.length !== 0) {
      if (this.findNewFocusRecord(focusRecordIndexBeforeDelete + 1, beforeDeleteRecordData.length,
        beforeDeleteRecordData, afterDeleteRecordData)) {
        LogUtil.info(TAG + ' new focusRecord found behind of origin focusRecord.');
        return;
      }
      if (this.findNewFocusRecord(focusRecordIndexBeforeDelete - 1, -1, beforeDeleteRecordData,
        afterDeleteRecordData)) {
        LogUtil.info(TAG + ' new focusRecord found front of origin focusRecord.');
        return;
      }
    } else {
      LogUtil.info(TAG + ' all record deleted, update to null.');
      this.focusRecord = new RecordData();
    }
  }

  //重命名弹框
  renameDialogController: CustomDialogController = new CustomDialogController({
    builder: RenameDialog({
      confirmCallback: async (newName: string) => {
        this.renameConfirmCallback(newName);
      },
      recordBeforeRename: this.selectedRecordList[0],
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    onDidDisappear: () => {
      AccessibilityUtil.sendFocusAccessibilityEvent('side_bar_button');
    },
  })

  // instrument ignore if
  private updateDatasourceInRenameScene(oldRecord: RecordData, newRecord: RecordData[], newName: string) {
    LogUtil.info(`${TAG} update: ${AnonymousUtil.anonymous(oldRecord.name)} to: ${AnonymousUtil.anonymous(newName)}`);
    let recordList = this.getRecordListBySideFolderId(this.sideFolderNameFlag);
    let index = recordList.getAll().findIndex(item => item._data === oldRecord._data);
    newRecord[0].index = index;
    newRecord[0].type = oldRecord.type;
    recordList.updateData(index, newRecord[0]);
    if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS ||
      this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
      let index = this.recordDataGroupList.allRecordList.getAll().findIndex(item => item._data === oldRecord._data);
      newRecord[0].index = index;
      this.recordDataGroupList.allRecordList.updateData(index, newRecord[0]);
    }

    this.isRenameFlag = true;
    recordList.forEach((item) => {
      if (item.name === newName && this.isRenameFocusRecord) {
        LogUtil.info(`${TAG} rename file success, set focusRecord to: ${AnonymousUtil.anonymous(item.title)}`);
        PlayManager.getInstance().pause();
        PlayManager.getInstance().updateCurrentPlayedRecordName(newName);
        this.focusRecord = item;
      }
    });
    LogUtil.info(`${TAG} update name done.`);
  }

  /* instrument ignore next */
  private async renameConfirmCallback(newName: string): Promise<void> {
    // update list to display
    let oldRecord = this.selectedRecordList[0];
    const indexForPoint = oldRecord.title.lastIndexOf('.');
    const fileType = oldRecord.title.substring(indexForPoint);
    let newRecord: RecordData[];

    newRecord = oldRecord.phoneNumber ?
      await DatabaseManager.getCallRecordDataFromDb('title', newName) :
      await DatabaseManager.getNormalRecordDataFromDb('title', newName + fileType);

    // instrument ignore if
    if (newRecord.length === 0) {
      LogUtil.info(`${TAG} rename: ${oldRecord.name} failed.`);
      AuditLogManager.getInstance().renameAuditLog('FAIL');
      this.renameDialogController.close();
      return;
    }
    if (newName === oldRecord.name) {
      this.renameDialogController.close();
      return;
    }

    this.updateDatasourceInRenameScene(oldRecord, newRecord, newName);

    // instrument ignore if
    if (this.sortType === SortType.SORT_NAME_ASC) {
      this.sortRecordList();
    }
    // instrument ignore if
    if (this.navMode === NavigationMode.Split) {
      if (this.focusRecord !== undefined) {
        this.focusRecord.isNeedPlay = false;
      }
    }
    AuditLogManager.getInstance().renameAuditLog('SUCCESS');
    LogUtil.info(`${TAG} DatabaseManager.updateDatabase succeed.`);
    this.enterEdit = false;
    this.isEditMode = false;
    AppStorage.setAndLink('isEditMode', this.isEditMode);
    this.selectedRecordList = [];
    const context = GlobalContext.getUIAbilityContext();
    let message = context?.resourceManager.getStringSync($r('app.string.renamed'));
    Util.showToast(message);
    let idInfo = ContactsManagerUtil.getInstance().addCallRecordPrefix(oldRecord);
    HiSysEventUtil.eventDotting(HiSysEventName.RENAME_CONFIRM, { FILEID: idInfo });
    this.renameDialogController.close();
    // instrument ignore if
    if (this.isSearchMode) {
      getContext().eventHub.emit('updateSearchResult', CommonConstants.UPDATE, [newRecord]);
    }
  }

  // 分享弹框
  /* instrument ignore next */
  showShareModal() {
    const shareModalParams: ShareModalParams = {
      context: GlobalContext.getUIAbilityContext(),
      srcData: this.selectedRecordList,
      eventName: HiSysEventName.SHARE_RECORD_LIST
    };
    ShareUtil.showModal(shareModalParams);
  }

  //路由到录音页面
  /* instrument ignore next */
  private routeToRecordingPage() {
    if (this.isShowRecordPlay) {
      this.isShowRecordPlay = false;
    }
    if (!this.bindSheetState) {
      this.isShowRecord = true;
      this.recordingMarkListHeightOpen = false;
      this.time = new Date().getTime();
    } else {
      this.isLastPageExist = true;
      LogUtil.error(TAG + ' routeToRecordingPage bindSheetState: ' + this.bindSheetState);
    }
  }

  async ScreenRecording(): Promise<void> {
    let callState = await call.getCallState();
    // instrument ignore if
    if (callState === call.CallState.CALL_STATE_RINGING || callState === call.CallState.CALL_STATE_OFFHOOK) {
      const context = GlobalContext.getUIAbilityContext();
      let message = context?.resourceManager.getStringSync($r('app.string.has_call_hint'));
      Util.showToast(message);
      AppStorage.setOrCreate('jumpFromDoubleXEnd', false);
      AppStorage.setOrCreate('xTapCount', 1);
      return;
    }
    let permissionList: Permissions[] = [
      'ohos.permission.MICROPHONE',
      'ohos.permission.APPROXIMATELY_LOCATION',
      'ohos.permission.LOCATION'
    ];
    let isUserGranted = await PreferencesUtil.get('isUserGrantedMicrophone', false) as boolean;
    let isUserGrantedLocation = await PreferencesUtil.get('isUserGrantedLocation', false) as boolean;
    LogUtil.info(TAG + ' isUserGrantedMicrophone:' + isUserGranted + ' isUserGrantedLocation:' + isUserGrantedLocation);
    this.hasPermissionOfMicrophoneAndLocation(isUserGranted, permissionList);
  }

  /* instrument ignore next */
  checkMoreButtonEnabled() {
    let enabled: boolean = false;
    if ((this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS && this.recentDeleteRecordingCount > 0) ||
      (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) ||
      (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) ||
      (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS)) {
      enabled = true;
    }
    return enabled;
  }

  /* instrument ignore next */
  private checkMultiSelectEnabled(): boolean {
    let enabled: boolean = false;
    if ((this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS && this.allRecordingCount > 0) ||
      (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS && this.recordingCount > 0) ||
      (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS && this.callRecordingCount > 0)) {
      enabled = true;
    }
    return enabled;
  }

  /* instrument ignore next */
  @Builder
  SettingPageBuilder() {
    Column() {
      if (this.showAboutPage) {
        AboutPage({ showAboutPage: this.showAboutPage })
      }
    }
    .width('100%')
    .height('100%')
  }

  /* instrument ignore next */
  private async hasPermissionOfMicrophoneAndLocation(isUserGranted: boolean, permissionList: Permissions[]) {
    const ctx: Context = getContext(this);
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const result: PermissionRequestResult = await atManager.requestPermissionsFromUser(ctx, [permissionList[0]]);
    const microphoneAuthStatus = result.authResults[0];
    const nonPreciseLocationGrant = await MediaController.checkAccessToken('ohos.permission.APPROXIMATELY_LOCATION');
    if (!isUserGranted) {
      if (microphoneAuthStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        LogUtil.info(TAG + ' permission granted, start to record.');
        if (this.isUserAllow && nonPreciseLocationGrant === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
          await atManager.requestPermissionsFromUser(ctx, [permissionList[1], permissionList[2]]);
        }
        this.routeToRecordingPage();
        await PreferencesUtil.put('isUserGrantedMicrophone', true);
        return;
      }
      if (this.jumpFromDoubleXEnd) {
        this.routeToRecordingPage();
      }
      await PreferencesUtil.put('isUserGrantedMicrophone', true);
    } else {
      if (microphoneAuthStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
        LogUtil.info(TAG + ' you has not permit to use MICROPHONE.');
        this.requestMicroPhonePermissionController.open();
      } else if (microphoneAuthStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
        LogUtil.info(TAG + ' permission granted by checkAccessToken, start to record.');
        if (this.isUserAllow && nonPreciseLocationGrant === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
          LogUtil.info(TAG + 'you has not permit to use location.');
          await atManager.requestPermissionsFromUser(ctx, [permissionList[1], permissionList[2]]);
        }
        this.routeToRecordingPage();
      }
    }
  }

  @Builder
  RecordingPageShowBuilder() {
    Column() {
      RecordingPageShow({ currentTimePlay: this.currentTimePlay });
    }
    .width('100%')
    .height('100%')
  }

  /* instrument ignore next */
  blankHeight(windowStatusType: number): number {
    if (windowStatusType === window.WindowStatusType.FLOATING) {
      return 130 + this.navigatorBarHeight;
    }
    if (windowStatusType === window.WindowStatusType.SPLIT_SCREEN) {
      return 108 + this.navigatorBarHeight;
    }
    return 156;
  }

  /* instrument ignore next */
  private async setSortType(type: string) {
    LogUtil.info(TAG + 'set sort type: ' + type);
    if (this.sortType === type) {
      return;
    }
    this.isSort = true;
    this.sortType = type;
    await PreferencesUtil.put(SortConstants.PRE_KEY, type);
    this.sortRecordList(true);
  }

  /* instrument ignore next */
  private refreshAllRecord() {
    LogUtil.info(TAG + ' refresh all record');
    let list = this.recordDataGroupList.allRecordList.getAll();
    DatabaseManager.sortRecords(list, this.sortType);
    this.recordDataGroupList.allRecordList.updateAllData(list);
  }

  /* instrument ignore next */
  private refreshNormalRecord() {
    LogUtil.info(TAG + ' refresh normal record');
    let list = this.recordDataGroupList.normalRecordList.getAll();
    DatabaseManager.sortRecords(list, this.sortType);
    this.recordDataGroupList.normalRecordList.updateAllData(list);
  }

  /* instrument ignore next */
  private refreshCallRecord() {
    LogUtil.info(TAG + 'refresh call record');
    let callRecordList = this.recordDataGroupList.callRecordList.getAll();
    DatabaseManager.sortRecords(callRecordList, this.sortType);
    this.recordDataGroupList.callRecordList.updateAllData(callRecordList);
  }

  /* instrument ignore next */
  private async sortRecordList(isSortAll: boolean = false) {
    LogUtil.info(TAG + 'sort record list side flag : ' + this.sideFolderNameFlag + ' isSortAll: ' + isSortAll);
    if (isSortAll) {
      this.refreshAllRecord();
      this.refreshNormalRecord();
      this.refreshCallRecord();
    } else {
      if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
        this.refreshAllRecord();
      } else if (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
        this.refreshNormalRecord();
      } else if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS) {
        this.refreshCallRecord();
      }
    }
  }

  /* instrument ignore next */
  @Builder
  SubMenu() {
    Menu() {
      MenuItem({
        content: $r('app.string.sort_mode_0'),
        symbolEndIcon: this.sortType === SortType.SORT_TIME_DESC ? this.selectEndModifier : this.nonSelectEndModifier
      })
        .id('sort_time_desc')
        .padding({ left: 16 })
        .onClick(() => {
          this.setSortType(SortType.SORT_TIME_DESC);
          HiSysEventUtil.eventDotting(HiSysEventName.SORT_CHANGE, { MODE: DFXEnumConstants.SortBy.SORT_TIME_DESC });
        })
        .accessibilitySelected(this.sortType === SortType.SORT_TIME_DESC)
      MenuItem({
        content: $r('app.string.sort_mode_1'),
        symbolEndIcon: this.sortType === SortType.SORT_TIME_ASC ? this.selectEndModifier : this.nonSelectEndModifier
      })
        .id('sort_time_asc')
        .padding({ left: 16 })
        .onClick(() => {
          this.setSortType(SortType.SORT_TIME_ASC);
          HiSysEventUtil.eventDotting(HiSysEventName.SORT_CHANGE, { MODE: DFXEnumConstants.SortBy.SORT_TIME_ASC });
        })
        .accessibilitySelected(this.sortType === SortType.SORT_TIME_ASC)
      MenuItem({
        content: $r('app.string.sort_mode_2'),
        symbolEndIcon: this.sortType === SortType.SORT_NAME_ASC ? this.selectEndModifier : this.nonSelectEndModifier
      })
        .id('sort_name')
        .padding({ left: 16 })
        .onClick(() => {
          this.setSortType(SortType.SORT_NAME_ASC);
          HiSysEventUtil.eventDotting(HiSysEventName.SORT_CHANGE, { MODE: DFXEnumConstants.SortBy.SORT_NAME_ASC });
        })
        .accessibilitySelected(this.sortType === SortType.SORT_NAME_ASC)
    }
    .fontColor($r('sys.color.font_secondary'))
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      color: $r('sys.color.comp_divider'),
      startMargin: LengthMetrics.vp(8)
    })
    .onAppear(() => {
      HiSysEventUtil.eventDotting(HiSysEventName.SORT);
      AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.expanded'), ''));
    })
    .onDisAppear(() => {
      AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.collapsed'), ''));
    })
  }

  /* instrument ignore next */
  getRecorderWindowHeight() {
    let result = ConfigData.WH_60_100;
    let transHeight = ConfigData.QH_0_VP;
    if (this.isSmallFoldSplit) {
      result = ConfigData.WH_100_100;
    } else if (this.windowStatusType === window.WindowStatusType.FLOATING ||
      (this.isSmallFoldVer && !DeviceUtil.isFolded())) {
      result = ConfigData.WH_100_100;
      if (!this.isShowQuickTrans) {
        result = ConfigData.WH_60_100;
      }
      transHeight = ConfigData.WH_50_100;
    } else if ((DeviceUtil.isBarPhone() || this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED ||
      this.screenShowState === CommonConstants.SCREEN_ONE_THREE) &&
      this.windowStatusType === window.WindowStatusType.SPLIT_SCREEN) {
      // 分屏状态下：直板 | 折叠 | 1/3屏
      result = ConfigData.WH_100_100;
    } else if (this.screenShowState === CommonConstants.SCREEN_FULL &&
      (DeviceUtil.isBarPhone() || DeviceUtil.isFolded()) ||
      (!DeviceUtil.isBarPhone() && this.windowStatusType === window.WindowStatusType.SPLIT_SCREEN)) {
      if (this.isShowQuickTrans) {
        result = ConfigData.WH_100_100;
        transHeight = ConfigData.QH_432_VP;
        if (this.recordingMarkListHeightOpen) {
          transHeight = ConfigData.QH_372_VP;
        }
      }
      transHeight = this.getTransHeightLandscape(transHeight);
    } else if (DeviceUtil.isTabletOrTripleGStatus() || DeviceUtil.isExpanded()) {
      result = ConfigData.WH_560_VP;
      transHeight = this.getQuickTransHeight();
    }
    this.recorderWindowHeight = result;
    this.quickTransHeight = transHeight;
    LogUtil.info(TAG + 'this.recorderWindowHeight:' + this.recorderWindowHeight)
  }

  /* instrument ignore next */
  getQuickTransHeight(): ConfigData {
    if (this.recordingMarkListHeightOpen) {
      return ConfigData.QH_204_VP;
    }
    return ConfigData.QH_256_VP;
  }

  /* instrument ignore next */
  getTransHeightLandscape(transHeight: ConfigData): ConfigData {
    // 折叠屏横屏下分屏显示
    if (!DeviceUtil.isBarPhone() && this.windowStatusType === window.WindowStatusType.SPLIT_SCREEN &&
      DeviceUtil.isLandscape()) {
      if (this.isShowQuickTrans) {
        transHeight = ConfigData.QH_350_VP;
        if (this.recordingMarkListHeightOpen) {
          transHeight = ConfigData.QH_290_VP;
        }
      }
    }
    return transHeight;
  }

  //  长按选中多项时更多按钮
  /* instrument ignore next */
  @Builder
  MultiSelectedMoreMenu() {
    Menu() {
      MenuItem({ content: $r('app.string.voice_retail') })
        .width('100%')
        .contentFont({
          size: $r('app.float.wh_value_16'), family: 'HarmonyHeiTi'
        })
        .enabled(false)
        .padding({ left: 16 })
      MenuItem({ content: $r('app.string.file_rename') })
        .width('100%')
        .contentFont({
          size: $r('app.float.wh_value_16'),
          family: 'HarmonyHeiTi'
        })
        .enabled(false)
        .padding({ left: 16 })
    }
    .menuItemDivider({
      strokeWidth: LengthMetrics.px(1),
      color: $r('sys.color.comp_divider'),
      startMargin: LengthMetrics.vp(16),
      endMargin: LengthMetrics.vp(16),
    })
    .width(MENU_DEFAULT_WIDTH)
  }

  //  长按选中一项时更多按钮
  /* instrument ignore next */
  @Builder
  SingleSelectedMoreMenu() {
    Scroll(new Scroller()) {
      Menu() {
        MenuItem({ content: $r('app.string.voice_retail') })
          .width('100%')
          .contentFont({
            size: $r('app.float.wh_value_16'),
            family: 'HarmonyHeiTi'
          })
          .height('48vp')
          .enabled(true)
          .padding({ left: 16 })
          .onClick(() => {
            getContext().eventHub.emit('showRecordDetail');
          })
        MenuItem({ content: $r('app.string.file_rename') })
          .width('100%')
          .contentFont({
            size: $r('app.float.wh_value_16'),
            family: 'HarmonyHeiTi'
          })
          .height('48vp')
          .enabled(true)
          .padding({ left: 16 })
          .onClick(() => {
            LogUtil.info(TAG + ' Click file rename button.');
            getContext().eventHub.emit('showRecordDetail');
          })
      }
      .menuItemDivider({
        strokeWidth: LengthMetrics.px(1),
        color: $r('sys.color.comp_divider'),
        startMargin: LengthMetrics.vp(16),
        endMargin: LengthMetrics.vp(16),
      })
      .width(MENU_DEFAULT_WIDTH)
    }
    .edgeEffect(EdgeEffect.Spring)
    .scrollBar(this.scrollBarState ? BarState.Auto : BarState.Off)
    .scrollable(ScrollDirection.Vertical)
    .onScrollStart(() => {
      this.scrollBarState = true;
    })
    .onScrollStop(() => {
      this.scrollBarState = false;
    })
  }

  @Builder
  LoadingProgressComponent() {
    Column() {
      LoadingProgress()
        .color(Color.Grey)
        .width('20%')
    }
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
    .padding({ bottom: this.navigatorBarHeight + 56 })
  }

  @Builder
  /* instrument ignore next */
  BackGroundComponent() {
    Column() {
      Image($r('app.media.no_more'))
        .matchTextDirection(Configuration.getLocale().dir === 'rtl' ? true : false)
        .draggable(false)
        .objectFit(ImageFit.Contain)
        .margin({
          top: this.isSmallFoldVerFoldMode() ? this.getNomoreImageTopMargin() : 0
        })
        .width(120)
        .height(120)

      Text($r('app.string.no_records'))
        .fontSize(14)
        .margin({
          bottom: this.isSmallFoldVerFoldMode() && this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS ? 46 : 0
        })
        .fontColor($r('app.color.text_colors'))
    }
    .justifyContent(
      ((this.windowHeight / this.screenHeight) <= 0.5) ? FlexAlign.Start : FlexAlign.Center
    )
    .width('100%')
    .height(this.isSmallFoldVerFoldMode() ? '100%' : `calc(100% - 56vp - ${this.navigatorBarHeight}vp)`)
  }

  @Builder
  RecordPlayPageShowBuilder() {
    Column() {
      RecordPlayPage({
        recordDataGroupList: this.recordDataGroupList,
        currentTimePlay: this.currentTimePlay,
        tranState: this.focusRecord.tranState,
        isSkipMute: this.isSkipMute
      })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  StartRecordButtonComponent() {
    Column() {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Row() {
        }
        .width(16)
        .height(16)
        .backgroundColor('#ffffff')
        .borderRadius(50)
      }
      .id('recorderBtn')
      .width($r('app.float.distance_56'))
      .height($r('app.float.distance_56'))
      .backgroundColor('#FB654E')
      .accessibilityText($r('app.string.start'))
      .shadow({
        radius: $r('app.float.distance_8'),
        color: this.changeShadowColor('#FB654E'),
        offsetX: 0,
        offsetY: $r('app.float.distance_6'),
      })
      .onClick(async () => {
        // instrument ignore if
        if (this.clickDelay) {
          return;
        }
        await PlayManager.getInstance().reset();
        this.availableRecord()
        HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
          { VALUE: DFXEnumConstants.StartRecordResource.IN_APP }
        );
      })
      .bindSheet($$this.isShowRecord, this.RecordingPageShowBuilder(), {
        preferType: SheetType.CENTER,
        onWillSpringBackWhenDismiss: () => {
        },
        onWillDismiss: ((dismissSheetAction: DismissSheetAction) => {
          // instrument ignore if
          if (dismissSheetAction.reason == DismissReason.PRESS_BACK) {
            getContext().eventHub.emit('backPress')
          }
        }),
        onDisappear: () => {
          this.clickDelay = false;
          this.bindSheetState = false;
        },
        onAppear: () => {
          this.clickDelay = true;
          this.bindSheetState = true;
        },
        height: this.recorderWindowHeight,
        showClose: false
      })
    }
    .width('auto')
    .margin({ bottom: this.navigatorBarHeight + 24 })
    .transition(TransitionEffect.asymmetric(
      TransitionEffect.OPACITY.animation({ curve: Curve.Friction, duration: 250, delay: 100 }),
      TransitionEffect.OPACITY.animation({ curve: Curves.cubicBezierCurve(0.8, 0, 0.8, 1), duration: 250 }),
    ))
  }

  @Builder
  /* instrument ignore next */
  SelectedMenuComponent() {
    Row() {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column({ space: I18n.System.getSystemLanguage() === 'bo' ? 0 : 3 }) {
          SymbolGlyph($r('sys.symbol.share'))
            .id('shareBtn')
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .margin({ top: 7 })
            .fontSize('24vp')
            .fontColor(this.isAbleToShare
              ? new Array($r('sys.color.ohos_id_color_titlebar_icon')) : new Array('#9C9D9F'))
          Text($r('app.string.voice_share'))
            .fontSize('10vp')
            .fontColor(this.isAbleToShare
              ? $r('sys.color.ohos_id_color_toolbar_text') : '#9C9D9F')
        }
        .height('100%')
        .layoutWeight(1)
      }
      .visibility(this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS ? Visibility.None :
        Visibility.Visible)
      .backgroundColor(Color.Transparent)
      .borderRadius($r('app.float.wh_value_2_5'))
      .layoutWeight(1)
      .draggable(false)
      .enabled(this.isAbleToShare)
      .accessibilityGroup(true)
      .accessibilityText($r('app.string.voice_share'))
      .onClick(() => {
        //分享弹框
        this.showShareModal();
      })

      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column({ space: I18n.System.getSystemLanguage() === 'bo' ? 0 : 3 }) {
          SymbolGlyph($r('sys.symbol.arrow_counterclockwise'))
            .id('shareBtn')
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .margin({ top: 7 })
            .fontSize('24vp')
            .fontColor(this.isSelectedAudioRecord()
              ? new Array($r('sys.color.ohos_id_color_titlebar_icon')) : new Array('#9C9D9F'))
          Text($r('app.string.recording_recover'))
            .fontSize('10vp')
            .fontColor(this.isSelectedAudioRecord()
              ? $r('sys.color.ohos_id_color_toolbar_text') : '#9C9D9F')
        }
        .height('100%')
        .layoutWeight(1)
      }
      .visibility(this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS ? Visibility.Visible :
        Visibility.None)
      .backgroundColor(Color.Transparent)
      .borderRadius($r('app.float.wh_value_2_5'))
      .layoutWeight(1)
      .draggable(false)
      .enabled(this.isSelectedAudioRecord())
      .accessibilityGroup(true)
      .accessibilityText($r('app.string.recording_recover'))
      .onClick(() => {
        LogUtil.info(TAG + ' click recover button in swipe menu: ' + this.selectedRecordList.length);
        if (this.selectedRecordList.length > 0) {
          getContext(this).eventHub.emit('recoverFromRecentDelete', 'multiSelectRecover');
          this.isEditMode = false;
          this.enterEdit = false;
          this.isNormalMode = true;
          HiSysEventUtil.eventDotting(HiSysEventName.DEL_RECOVER_MUL, { NUM: this.selectedRecordList.length });
        }
      })

      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column({ space: I18n.System.getSystemLanguage() === 'bo' ? 0 : 3 }) {
          SymbolGlyph($r('sys.symbol.trash'))
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .margin({ top: 7 })
            .fontSize('24vp')
            .fontColor(this.isSelectedAudioRecord()
              ? new Array($r('sys.color.ohos_id_color_titlebar_icon')) : new Array('#9C9D9F'))
          Text($r('app.string.delete'))
            .fontSize('10vp')
            .fontColor(this.isSelectedAudioRecord() ? $r('sys.color.ohos_id_color_toolbar_text') : '#9C9D9F')
        }
        .height('100%')
        .layoutWeight(1)
      }
      .backgroundColor(Color.Transparent)
      .borderRadius($r('app.float.wh_value_2_5'))
      .layoutWeight(1)
      .draggable(false)
      .enabled(this.isSelectedAudioRecord())
      .accessibilityGroup(true)
      .accessibilityText($r('app.string.delete'))
      .onClick(() => {
        if (this.selectedRecordList.length > 0) {
          let idList = ContactsManagerUtil.getInstance().batchAddCallRecordPrefix(this.selectedRecordList);
          if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_DELETE_MUL, { NUM: this.selectedRecordList.length });
          } else {
            HiSysEventUtil.eventDotting(HiSysEventName.DELETE_RECORD_LIST,
              { VALUE: this.selectedRecordList.length, FILEID: idList.toString() }
            );
          }
          getContext(this).eventHub.emit('openDeleteDialog', 'indexDelete');
        }
      })

      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column({ space: I18n.System.getSystemLanguage() === 'bo' ? 0 : 3 }) {
          SymbolGlyph(this.isSelectedAllAudio ? $r('sys.symbol.checkmark_square_on_square_fill') :
            $r('sys.symbol.checkmark_square_on_square'))
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .margin({ top: 7 })
            .fontSize('24vp')
            .fontColor(this.isSelectedAllAudio
              ? new Array('#FB654E') : new Array($r('sys.color.ohos_id_color_titlebar_icon')))
          Text(this.isSelectedAllAudio
            ? $r('app.string.toolbar_cancel_select_all') : $r('app.string.toolbar_select_all'))
            .fontSize('10vp')
            .fontColor(this.isSelectedAllAudio ? '#FB654E' : $r('sys.color.ohos_id_color_toolbar_text'))
        }
        .height('100%')
        .layoutWeight(1)
      }
      .id('select_all_button')
      .backgroundColor(Color.Transparent)
      .borderRadius($r('app.float.wh_value_2_5'))
      .layoutWeight(1)
      .draggable(false)
      .accessibilityGroup(true)
      .accessibilityText(this.isSelectedAllAudio ? $r('app.string.toolbar_cancel_select_all')
        : $r('app.string.toolbar_select_all'))
      .onClick(() => {
        this.handleSelect();
      })

      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column({ space: I18n.System.getSystemLanguage() === 'bo' ? 0 : 3 }) {
          Image($r('sys.media.ohos_ic_public_more'))
            .width($r('app.float.wh_value_24'))
            .height($r('app.float.wh_value_24'))
            .margin({ top: 7 })
            .fillColor($r('sys.color.ohos_id_color_titlebar_icon'))
            .draggable(false)
          Text($r('app.string.toolbar_more'))
            .fontSize(10)
            .fontWeight(FontWeight.Medium)
        }
        .height('100%')
        .layoutWeight(1)
      }
      .backgroundColor(Color.Transparent)
      .borderRadius($r('app.float.wh_value_2_5'))
      .layoutWeight(1)
      .draggable(false)
      .accessibilityGroup(true)
      .visibility(Visibility.None)
      .accessibilityText($r('app.string.more_options'))
      .bindMenu(this.isSelectedOneAudioRecord() ? this.SingleSelectedMoreMenu : this.MultiSelectedMoreMenu, {
        placement: Placement.TopRight,
        offset: { x: 18, y: 8 }
      })
      .enabled(this.isSelectedOneAudioRecord())
    }
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .width(ConfigData.WH_100_100)
    .height(52 + this.navigatorBarHeight)
    .justifyContent(FlexAlign.SpaceAround)
    .alignItems(I18n.System.getSystemLanguage() === 'ug' || I18n.System.getSystemLanguage() === 'bo' ? VerticalAlign.Top
      : VerticalAlign.Center)
    .transition(TransitionEffect.asymmetric(
      TransitionEffect.OPACITY.animation({ curve: Curve.Friction, duration: 250, delay: 100 }),
      TransitionEffect.OPACITY.animation({ curve: Curves.cubicBezierCurve(0.8, 0, 0.8, 1), duration: 250 }),
    ))

  }

  /* instrument ignore next */
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

  /* instrument ignore next */
  private isSelectedAudioRecord() {
    return this.selectedRecordList.length !== 0;
  }

  /* instrument ignore next */
  private isSelectedOneAudioRecord() {
    return this.selectedRecordList.length === 1;
  }

  /* instrument ignore next */
  private calcSplitScreenConfig(height: number, width: number) {
    try {
      let displayObj = display.getDefaultDisplaySync();
      let maxHeight = displayObj.height;
      let maxWidth = displayObj.width;
      let oneThirdHeight = maxHeight * 1 / 3;
      let oneHalfHeight = maxHeight * 1 / 2;
      let twoThirdsHeight = maxHeight * 2 / 3;
      if ((DeviceUtil.isPhoneNotFold() && DeviceUtil.isLandscape() && !this.isSmallFoldVer)) {
        LogUtil.info(TAG + ': phone land space, applyNewHeight to SIZE_ONE_HALF');
        AppStorage.setOrCreate('screenShowState', CommonConstants.SCREEN_HALF);
      } else if (height < oneThirdHeight) {
        LogUtil.info(TAG + ': applyNewHeight to SIZE_ONE_THIRD');
        AppStorage.setOrCreate('screenShowState', CommonConstants.SCREEN_ONE_THREE);
      } else if (height < oneHalfHeight) {
        LogUtil.info(TAG + ': applyNewHeight to SIZE_ONE_HALF');
        AppStorage.setOrCreate('screenShowState', CommonConstants.SCREEN_HALF);
      } else if (height < twoThirdsHeight) {
        LogUtil.info(TAG + ': applyNewHeight to SIZE_TWO_THIRDS');
        AppStorage.setOrCreate('screenShowState', CommonConstants.SCREEN_TWO_THREE);
      } else {
        LogUtil.info(TAG + ': applyNewHeight to SIZE_FULL_SCREEN');
        AppStorage.setOrCreate('screenShowState', CommonConstants.SCREEN_FULL);
      }
      if (width < (maxWidth * 5 / 6)) {
        AppStorage.setOrCreate('screenWidthSplitState', CommonConstants.SCREEN_WIDTH_HALF);
      } else {
        AppStorage.setOrCreate('screenWidthSplitState', CommonConstants.SCREEN_WIDTH_FULL);
      }
      if (this.screenShowState === CommonConstants.SCREEN_HALF && DeviceUtil.isExpanded() &&
        DeviceUtil.isLandscape()) {
        LogUtil.info(TAG + 'applyNewHeight to screenLandscapeExpandedHalf true');
        AppStorage.setOrCreate('screenLandscapeExpandedHalf', true);
      } else {
        LogUtil.info(TAG + 'applyNewHeight to screenLandscapeExpandedHalf false');
        AppStorage.setOrCreate('screenLandscapeExpandedHalf', false);
      }
    } catch (error) {
      LogUtil.error(TAG + ' calcSplitScreenConfig error: ' + error);
    }
  }

  /* instrument ignore next */
  private resetBindSheetShow() {
    let screenWidthSplitState: string = AppStorage.get('screenWidthSplitState') || '';
    let needResizeShow = false
    if (DeviceUtil.isTabletOrTripleGStatus() || DeviceUtil.isExpanded()) {
      if (screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF) {
        needResizeShow = true;
      }
      if (this.isSmallFoldVer) {
        needResizeShow = true;
      }
      this.lastIsExpanded = true;
    } else if (DeviceUtil.isFolded()) {
      if (this.lastIsExpanded) {
        needResizeShow = true;
      }
      this.lastIsExpanded = false;
    }
    if (needResizeShow) {
      this.isFoldFold = true;
      let pathArr = this.pathStack.getAllPathName();
      if (pathArr.includes('recordPlay') && this.navMode === NavigationMode.Stack) {
        this.pathStack.removeByName('recordPlay');
      }
      if (this.isShowRecord) {
        this.isShowRecordPlay = false;
      } else if (this.isShowRecordPlay && !this.currentTimePlay) {
        this.isShowRecordPlay = false;
      }
    } else if (DeviceUtil.isPhoneNotFold()) {
      this.isFoldFold = true;
    } else {
      this.isFoldFold = false;
      this.isShowRecordPlay = false;
    }
  }

  /* instrument ignore next */
  private getRecordPlayBindSheetHeight(): void {
    if (this.recordTransState) {
      this.playPageWindowHeight = SheetSize.LARGE;
      return;
    }
    if (this.getUIContext().getWindowHeightBreakpoint() === HeightBreakpoint.HEIGHT_LG) {
      this.playPageWindowHeight = px2vp(this.screenHeight) * 0.6;
      return;
    }
    this.playPageWindowHeight = SheetSize.LARGE;
  }

  private isShowBackGroundComponent() {
    return !this.isAudioRecordExist && !this.loading && this.navMode === NavigationMode.Stack &&
      !this.isSearchMode && !(!this.isUserAllow && this.isOverOneWeek && !this.isTipsClose &&
      this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS &&
      (this.isSmallFoldVerFoldMode()))
  }

  /**
   * 计算顶部间距
   * @returns
   */
  /* instrument ignore next */
  private getListTopMargin(): number {
    let calMargin: number = this.titleHeight + 16 + 56; // 56顶部按钮行高度
    if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
      calMargin += this.subTitleHeight + 20;
    }
    if (this.isFullScreen) {
      calMargin = calMargin / 2;
    }
    return calMargin;
  }

  /**
   * 是否为折叠屏展开或平板
   * @returns
   */
  private isFullMode(): boolean {
    return DeviceUtil.isPC() || DeviceUtil.isTabletOrTripleGStatus() || DeviceUtil.isLandscape() ||
      this.foldDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_FULL;

  }

  /* instrument ignore next */
  private getSideBarWidth(): number | string {
    let result: number | string = '67%';
    if (this.isFullMode()) {
      result = 304;
    }
    if (this.curBp === 'lg') {
      result = 241;
    }
    return result;
  }

  /** 侧边栏展开时内容区右移距离，内容保持全宽溢出裁切而非压缩 */
  private getSideBarTranslateOffset(): number {
    if (!this.isShowSideBar) {
      return 0;
    }
    let width = this.getSideBarWidth();
    if (typeof width === 'number') {
      return width;
    }
    const percent = parseFloat((width as string).replace('%', '')) / 100;
    return this.windowWidth * percent;
  }

  getNomoreImageTopMargin(): number {
    // instrument ignore if
    if (this.isSmallFoldVerFoldMode()) {
      if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
        return this.getListTopMargin() - this.subTitleHeight / 2 - 10;
      } else if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
        return this.getListTopMargin() - 8;
      }
    }
    return this.getListTopMargin();
  }

  isSmallFoldVerFoldMode(): boolean {
    return this.isSmallFoldVer && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED;
  }

  private getEffectiveStatusBarHeight(): number {
    return this.statusBarHeight > 0 ? this.statusBarHeight : 36;
  }

  private getNavTitleBarHeight(): number {
    return this.titleHeight + this.getEffectiveStatusBarHeight();
  }

  @Styles
  dividerStyle() {
    .backgroundColor('#F0000000')
  }

  /** 侧边栏展开/收起动画，与内容区 translate 同步 */
  private runSideBarAnimation(stateChange: () => void): void {
    animateTo({
      curve: SIDE_BAR_ANIM_CURVE,
      duration: SIDE_BAR_ANIM_DURATION
    }, stateChange);
  }

  handleClickSideBarBtn = () => {
    LogUtil.info(TAG + ' click the sideBar button, isShowSideBar: ' + this.isShowSideBar);
    this.runSideBarAnimation(() => {
      this.isShowSideBar = !this.isShowSideBar;
      this.isShowOverlay =  this.isShowSideBar;
      this.isShowSideBar ? this.clickShowSideBarTime = new Date().getTime() :
        this.clickCloseShowSideBarTime = new Date().getTime();
      AccessibilityUtil.sendFocusAccessibilityEvent('side_bar_button');
      if (this.isShowSideBar) {
        AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.expanded'), ''));
      } else {
        AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.collapsed'), ''));
      }
    })
  }

  closeSideBarByMask = () => {
    LogUtil.info(TAG + ' click content mask to close sideBar.');
    this.runSideBarAnimation(() => {
      this.isShowSideBar = false;
      this.isShowOverlay = false;
    })
  }

  handleSideBarSwipeEnd = (event?: GestureEvent) => {
    if (this.shouldBlockSideBarSwipe()) {
      return;
    }
    if (event && event.offsetX > 0) {
      this.handleClickSideBarBtn();
    }
  }

  private shouldBlockSideBarSwipe(): boolean {
    return (AppStorage.get('isTouchProgressBar') as boolean) ||
      (AppStorage.get('isTouchMarkList') as boolean) ||
      this.isShowRecordPlay ||
      this.pathStack.getAllPathName().includes('recordPlay') ||
      !this.isExitTopAction;
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
    } else if (AppStorage.get('recordingFromLock') as boolean) {
      source = DFXEnumConstants.EnterAppWays.LOCK_SCREEN;
    } else if (AppStorage.get('jumpFromHeadset') as boolean) {
      source = DFXEnumConstants.EnterAppWays.AUDIO_MANAGER;
    }
    return source;
  }

  private openMoreMenu() {
    console.info(TAG + ' open more menu');
    let uiContext = this.getUIContext();
    let promptAction = uiContext.getPromptAction();
    let contentNode =
      new ComponentContent<ParamsInterface>(uiContext, wrapBuilder<[ParamsInterface]>(menuComponent), {
        multiSelect: () => {
          LogUtil.info(TAG + ' click the multi select button');
          this.selectedRecordList = [];
          this.isNormalMode = false;
          this.isEditMode = true;
          AppStorage.setAndLink('isEditMode', this.isEditMode);
          this.enterEdit = true;
          this.isExitPageToQuickRecord = false;
          if (this.navMode === NavigationMode.Split) {
            LogUtil.info(TAG + ' recentDeletem page split mode click, pause play.');
            PlayManager.getInstance().pause();
          } else {
            LogUtil.info(TAG + ' recentDelete page stack mode click, reset.');
            AppStorage.setOrCreate(CommonConstants.CURRENT_FOCUS_RECORD, this.focusRecord);
            PlayManager.getInstance().reset();
          }
          HiSysEventUtil.eventDotting(HiSysEventName.DEL_MULTI_SEL);
        },
        sortBuilder: (): void => this.SubMenu(),
        openAbout: () => {
          LogUtil.info(TAG + ' openAbout');
          this.showAboutPage = true;
        },
        openPersonal: () => {
          LogUtil.info(TAG + ' openPersonal');
          this.showPersonalDataPage = true
        },
        openHelps: () => {
          LogUtil.info(TAG + ' openHelps');
          const want: Want = {
            bundleName: 'com.hmos.hiviewcare',
            abilityName: 'FeedBackAbility',
            parameters: {
              pafAppid: '6055',
              bName: 'com.ohos.soundrecorder'
            }
          }
          GlobalContext.getUIAbilityContext().startAbility(want);
        },
        isAudioRecordExist: this.isAudioRecordExist,
        sideFolderNameFlag: this.sideFolderNameFlag,
        allRecordsRecover: () => {
          LogUtil.info(TAG + ' click all recording recover button');
          this.selectedRecordList = this.recordDataGroupList.recentDeleteList.getAll().filter(item => item);
          getContext(this).eventHub.emit('recoverFromRecentDelete', 'floatMenuRecoverAll');
          PlayManager.getInstance().reset();
          HiSysEventUtil.eventDotting(HiSysEventName.DEL_RECOVER_ALL);
        },
        allRecordsDelete: () => {
          this.selectedRecordList = this.recordDataGroupList.recentDeleteList.getAll().filter(item => item);
          getContext(this).eventHub.emit('openDeleteDialog', 'floatMenuDeleteAll');
          LogUtil.info(TAG + ' click all recording delete button');
          HiSysEventUtil.eventDotting(HiSysEventName.DEL_DELETE_ALL);
        },
      });
    try {
      promptAction.openMenu(contentNode, { id: 'indexMore' }, { placement: Placement.BottomRight })
    } catch (error) {
      let message = (error as BusinessError).message;
      let code = (error as BusinessError).code;
      console.error(`zhy openMenu args error code is ${code}, message is ${message}`);
    }
  }

  @Builder
  private navTitleBuilder() {
    Column() {
      Text(this.isEditMode ? $r('app.plural.partial_select_plural', this.selectedRecordList.length,
        this.selectedRecordList.length) : sideBarModeToNameMap[this.sideFolderNameFlag])
        .fontColor($r('sys.color.ohos_id_color_titlebar_text'))
        .maxFontSize($r('sys.float.ohos_id_text_size_headline8'))
        .minFontSize('14fp')
        .fontWeight(FontWeight.Bold)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(1)
        .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
    }
    .width('100%')
    .height(this.titleHeight)
    .justifyContent(FlexAlign.Center)
    .padding({ top: this.getEffectiveStatusBarHeight() })
  }

  @Builder
  private navMenu() {
    Column() {
      Row() {
        if (this.isEditMode) {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.xmark'))
              .fontSize($r('app.float.wh_value_24'))
              .width($r('app.float.wh_value_24'))
              .height($r('app.float.wh_value_24'))
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .id('cancelBtn')
          .backgroundColor(Color.Transparent)
          .width($r('app.float.distance_40'))
          .height($r('app.float.distance_40'))
          .onClick(() => {
            LogUtil.info(TAG + ' cancel edit mode. ');
            this.exitEditMode();
          })
        } else {
          Button({ type: ButtonType.Circle, stateEffect: true }) {
            SymbolGlyph($r('sys.symbol.dot_grid_2x2'))
              .fontSize($r('app.float.wh_value_24'))
              .width($r('app.float.wh_value_24'))
              .height($r('app.float.wh_value_24'))
              .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
          }
          .id('indexMore')
          .enabled(this.checkMoreButtonEnabled())
          .backgroundColor(Color.Transparent)
          .width($r('app.float.distance_40'))
          .height($r('app.float.distance_40'))
          .onClick(() => {
            this.openMoreMenu();
          })
        }
      }
      .height(this.titleHeight)
      .alignItems(VerticalAlign.Center)
    }
    .padding({ top: this.getEffectiveStatusBarHeight() })
  }

  //左侧侧边栏区
  @Builder
  SideBarPanelBuilder() {
    Column() {
      SideBarComponent().layoutWeight(1);
    }
  }

  //右侧内容区
  @Builder
  ContentPanelBuilder() {
    // 内容区
    Navigation(this.pathStack) {
      Stack({ alignContent: Alignment.Bottom }) {
        // 文件夹目录名称
        Flex({ direction: FlexDirection.Column }) {

          if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS &&
            !(this.isSmallFoldVerFoldMode())) {
            Row() {
              Text($r('app.string.recent_delete_description', CommonConstants.RECYCLE_DAYS_LIMIT))
                .fontWeight(FontWeight.Regular)
                .lineHeight(21)
                .fontSize($r('sys.float.Subtitle_S'))
                .fontColor($r('sys.color.font_secondary'))
                .maxFontScale(1.75)
                .padding({
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: 6
                })
            }
            .constraintSize({ minHeight: 56 })
            .padding({ left: 16, right: 16, bottom: 18 })
            .onAreaChange((oldValue: Area, newValue: Area) => {
              let dp = this.densityPixels / this.defaultDP;
              dp = dp < 1 ? 1 : dp;
              const rowHeight = Math.round(Number(newValue.height) * dp);
              if (this.subTitleHeight !== rowHeight) {
                this.subTitleHeight = rowHeight;
              }
            })
          }

          if (!this.isUserAllow && this.isOverOneWeek && !this.isTipsClose &&
            this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS &&
            !(this.isSmallFoldVerFoldMode()) && !this.isDemo) {
            Flex({
              direction: FlexDirection.Row,
              space: { main: LengthMetrics.vp(12) },
              alignItems: ItemAlign.Start,
              justifyContent: FlexAlign.Center
            }) {
              Column({ space: 8 }) {
                Text($r('app.string.access_location'))
                  .fontSize($r('sys.float.Body_M'))
                  .fontColor($r('sys.color.font_secondary'))
                  .maxFontScale(i18n.System.getSystemLanguage() === 'zh-Hans' ? 1.75 : 1.3)
                  .width('100%')

                Row() {
                  Text($r('app.string.allow_access'))
                    .maxFontScale(i18n.System.getSystemLanguage() === 'zh-Hans' ? 1.75 : 1.3)
                    .fontSize($r('sys.float.Subtitle_S'))
                    .fontColor($r('sys.color.font_emphasize'))
                    .fontWeight(FontWeight.Medium)
                }
                .onClick(async () => {
                  LogUtil.info(TAG + ' confirm button click.');
                  await this.requestLocationPermission();
                })
                .backgroundColor(this.buttonBackgroundColor)
                .onHover((isHover: boolean) => {
                  if (isHover) {
                    this.buttonBackgroundColor = $r('sys.color.ohos_id_color_hover')
                  } else {
                    this.buttonBackgroundColor = $r('sys.color.ohos_id_color_background_transparent')
                  }
                })
              }
              .flexShrink(3)
              .alignItems(HorizontalAlign.Start)
              .alignSelf(ItemAlign.Center)

              Button() {
                SymbolGlyph($r('sys.symbol.xmark'))
                  .fontSize($r('app.float.wh_value_18'))
                  .fontColor([$r('sys.color.icon_secondary')])
                  .draggable(false)
              }
              .width($r('app.float.wh_value_18'))
              .height($r('app.float.wh_value_18'))
              .accessibilityText(getContext().resourceManager.getStringSync($r('app.string.detailDialog_close')))
              .backgroundColor(this.closeButtonBackgroundColor)
              .onHover((isHover: boolean) => {
                if (isHover) {
                  this.closeButtonBackgroundColor = $r('sys.color.ohos_id_color_hover');
                } else {
                  this.closeButtonBackgroundColor = $r('sys.color.ohos_id_color_background_transparent');
                }
              })
              .onClick(async () => {
                LogUtil.info(TAG + ' close Button click');
                await PreferencesUtil.put('tipsCloseTime', Date.now());
                this.isTipsClose = true;
                AccessibilityUtil.sendFocusAccessibilityEvent('side_bar_button');
              })
            }
            .direction(Direction.Auto)
            .padding($r('app.float.distance_12'))
            .margin({ left: 16, right: 16, bottom: 8 })
            .backgroundColor($r('sys.color.comp_background_tertiary'))
            .borderRadius($r('sys.float.corner_radius_level9'))
            .visibility(this.isEditMode || this.isSearchMode ? Visibility.None : Visibility.Visible)
            .flexGrow(20)
          }

          Column() {
            Tabs({ barPosition: BarPosition.Start, controller: this.tabsController }) {
              TabContent() {
                if (this.isShowBackGroundComponent()) {
                  this.BackGroundComponent();
                } else if (this.loading) {
                  this.LoadingProgressComponent();
                } else if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
                  AudioRecordListComponent({
                    recordDataList: this.recordDataGroupList.allRecordList,
                    sortType: this.sortType,
                    isAudioRecordExist: this.isAudioRecordExist,
                    currentTimePlay: this.currentTimePlay,
                    scroller: this.listScroller,
                    isTipsClose: this.isTipsClose,
                    isUserAllow: this.isUserAllow,
                    isOverOneWeek: this.isOverOneWeek,
                    audioRecordListController: this.audioRecordListContrRef,
                    isSkipMute: this.isSkipMute
                  });
                } else if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS) {
                  AudioRecordListComponent({
                    recordDataList: this.recordDataGroupList.callRecordList,
                    sortType: this.sortType,
                    isAudioRecordExist: this.isAudioRecordExist,
                    currentTimePlay: this.currentTimePlay,
                    scroller: this.listScroller,
                    isTipsClose: this.isTipsClose,
                    isUserAllow: this.isUserAllow,
                    isOverOneWeek: this.isOverOneWeek,
                    audioRecordListController: this.audioRecordListContrRef,
                    isSkipMute: this.isSkipMute
                  })
                } else if (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
                  AudioRecordListComponent({
                    recordDataList: this.recordDataGroupList.normalRecordList,
                    sortType: this.sortType,
                    isAudioRecordExist: this.isAudioRecordExist,
                    currentTimePlay: this.currentTimePlay,
                    scroller: this.listScroller,
                    isTipsClose: this.isTipsClose,
                    isUserAllow: this.isUserAllow,
                    isOverOneWeek: this.isOverOneWeek,
                    audioRecordListController: this.audioRecordListContrRef,
                    isSkipMute: this.isSkipMute
                  });
                } else {
                  AudioRecordListComponent({
                    recordDataList: this.recordDataGroupList.recentDeleteList,
                    sortType: this.sortType,
                    isAudioRecordExist: this.isAudioRecordExist,
                    currentTimePlay: this.currentTimePlay,
                    scroller: this.listScroller,
                    isTipsClose: this.isTipsClose,
                    isUserAllow: this.isUserAllow,
                    isOverOneWeek: this.isOverOneWeek,
                    audioRecordListController: this.audioRecordListContrRef,
                    isSkipMute: this.isSkipMute
                  });
                }
              }
              .tabBar(this.subTitleBuilder)
              .align(Alignment.TopStart)
              .width('100%')
              .height('100%')
            }
            .width('100%')
            .height('100%')
            .align(Alignment.TopStart)
            .barOverlap(true) // 使TabBar叠加在TabContent上，当TabBar向上或向下隐藏后，原位置处不为空白
            .clip(true)
            .barHeight(this.isSmallFoldVerFoldMode() ? this.getNavTitleBarHeight() : 0)
            .scrollable(this.isNormalMode && this.isAudioRecordExist)
          }.flexShrink(50)
          .height('100%')
          .width('100%')
          .margin({ bottom: this.isEditMode ? this.navigatorBarHeight + 52 : 0 })
        }
        .height(ConfigData.WH_100_100)
        .width(ConfigData.WH_100_100)

        // --------- 录音按钮
        if (!this.isEditMode && !this.isSearchMode) {
          if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS ||
            this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
            this.StartRecordButtonComponent();
          }
        } else if (this.isEditMode) {
          this.SelectedMenuComponent(); //toolBar暂时使用自定义组件，后续建议使用Api13的toolBar高级组件
        }
        if (!this.isEditMode && (this.isFoldFold || this.windowStatusType === window.WindowStatusType.FLOATING)) {
          Row() {
          }
          .bindSheet($$this.isShowRecordPlay, this.RecordPlayPageShowBuilder(), {
            onWillSpringBackWhenDismiss: () => {
            },
            shouldDismiss: () => {
              if (this.navMode === NavigationMode.Stack) {
                this.isShowRecordPlay = false;
                PlayManager.getInstance().reset();
              } else {
                PlayManager.getInstance().pause();
              }
              // if true, go back to index, otherwise go back to desktop
              return this.navMode === NavigationMode.Stack;
            },
            height: this.playPageWindowHeight,
            showClose: false
          })
        }

        Row() {
        }
        .bindSheet(this.showAboutPage || this.showPersonalDataPage, this.SettingPageBuilder(), {
          height: '100%',
          preferType: SheetType.CENTER,
          showClose: false,
          onWillDismiss: ((dismissSheetAction: DismissSheetAction) => {
            // instrument ignore if
            if (dismissSheetAction.reason == DismissReason.PRESS_BACK ||
              dismissSheetAction.reason === DismissReason.CLOSE_BUTTON) {
              this.showAboutPage = false;
              this.showPersonalDataPage = false;
            }
          }),
          onDisappear: () => {
            this.showAboutPage = false;
            this.showPersonalDataPage = false;
          }
        })
      }
      .height(ConfigData.WH_100_100)
      .width(ConfigData.WH_100_100)
      .padding({ top: this.isSearchMode ? this.getEffectiveStatusBarHeight() : 0 })
    }
    .height(ConfigData.WH_100_100)
    .width(ConfigData.WH_100_100)
    .hideTitleBar(this.isSearchMode || this.isVerdeFolded)
    .title({ builder: this.navTitleBuilder(), height: this.getNavTitleBarHeight() })
    .menus(this.navMenu())
    .accessibilityLevel(this.curBp !== 'lg' && this.isShowSideBar ? 'no-hide-descendants' : 'yes')
    .mode(NavigationMode.Auto)
    .backgroundColor(Color.Transparent)
    .borderColor(Color.Transparent)
    .navBarWidth('40%')
    .zIndex(1)
    .focusable(this.canFocus)
    .onNavigationModeChange(async (mode) => {
      LogUtil.info(TAG + ' onNavigationModeChange nav mode：' + mode);
      let realMode = mode;
      // 展开态后台录音，切成折叠态点击实况胶囊停止录音，此时进入这里 mode为1（实际应为0）
      if (DeviceUtil.isFolded() && NavigationMode.Split) {
        realMode = NavigationMode.Stack;
      }
      this.navMode = realMode;
      AppStorage.setOrCreate('navigationMode', realMode);
      // instrument ignore if
      if (realMode === NavigationMode.Stack) {
        LogUtil.info(TAG + ' nav mode change to stack, route to index page.');
        // 去掉全模态播放详情窗口
        this.pathStack.pop(false);
        // 设置是否显示半模态详情页
        if (this.isShortCutList || this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
          // 异常场景，折叠手机，展开态播放并退出后台，shortCutList进入，不进入半模态播放页并再次触发shortCut进入模式改变进度条的显示
          if (this.isShortCutList) {
            this.isShortCutList = false;
            AppStorage.setOrCreate('shortCutRecordList', true);
          }
          this.isShowRecordPlay = false;
        } else {
          this.isShowRecordPlay = this.state === 'playing' || this.state === 'paused' || this.state === 'completed'
        }
      }
      // instrument ignore if
      if (realMode === NavigationMode.Split && this.pathStack.size() === 0 &&
        router.getState().name !== RecordingPage.RECORDING_PAGE) {
        if (this.isShortCutList) {
          this.isShortCutList = false;
        }
        LogUtil.info(TAG + ' nav mode is split, show recordPlayPage');
        let savedFocusRecord = await PreferencesUtil.get('focusRecord', new RecordData()) as RecordData;
        LogUtil.info(TAG + ' onNavigationModeChange get savedFocusRecord');
        let params: Record<string, number | RecordData | string> = {
          'focusRecord': this.focusRecord?._data !== '' ? this.focusRecord : savedFocusRecord,
          'currentTimePlay': this.currentTimePlay
        }
        this.isShowRecordPlay = false;
        this.pathStack.pushPathByName('recordPlay', params);
      }
    })
    .navDestination(this.myRouter)
    .onAreaChange((_, newValue) => AppStorage.setOrCreate('appContentHeight', Number(newValue.height)))
  }

  /* instrument ignore next */
  build() {
    Stack() {
      if (this.isExitTopAction) {
        // 侧边栏展开收起按钮，通过position定位在左上角
        Button() {
          SymbolGlyph(this.isShowSideBar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'))
            .fontWeight(FontWeight.Normal)
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            .hitTestBehavior(HitTestMode.None)
        }
        .id('side_bar_button')
        .accessibilityText(this.isShowSideBar
          ? getContext().resourceManager.getStringSync($r('app.string.collapse_side_navigation_bar'))
          : getContext().resourceManager.getStringSync($r('app.string.show_side_navigation_bar')))
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .height(40)
        .width(40)
        .onClick(() => {
          this.handleClickSideBarBtn();
        })
        .position({
          top: LengthMetrics.vp(this.getEffectiveStatusBarHeight() + 8),
          start: LengthMetrics.vp(16)
        })
        .zIndex(1)
        .visibility(this.isVerdeFolded && !this.isShowSideBar ? Visibility.None : Visibility.Visible)
      }

      Stack({ alignContent: Alignment.TopStart }) {
        Stack() {
          Column() {
            this.contentBuilder()
          }
          .width('100%')
          .height('100%')

          if (this.isShowOverlay) {
            Column()
              .width('100%')
              .height('100%')
              .backgroundColor('#33000000')
              .onClick(() => {
                this.closeSideBarByMask();
              })
          }
        }
        .width('100%')
        .height('100%')
        .translate({ x: this.getSideBarTranslateOffset() })
        .onGestureJudgeBegin((gestureInfo: GestureInfo) => {
          if (gestureInfo.type === GestureControl.GestureType.PAN_GESTURE &&
            this.shouldBlockSideBarSwipe()) {
            return GestureJudgeResult.REJECT;
          }
          return GestureJudgeResult.CONTINUE;
        })
        .parallelGesture(
          PanGesture({ direction: PanDirection.Horizontal, distance: 10 })
            .onActionEnd(this.handleSideBarSwipeEnd),
          GestureMask.Normal
        )

        Column() {
          this.sideBarBuilder()
        }
        .width(this.isShowSideBar ? this.getSideBarWidth() : 0)
        .height('100%')
        .clip(true)
        .zIndex(1)
      }
      .width('100%')
      .height('100%')
      .clip(true)

      //透明遮罩：点击Search组件外收起键盘
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor(Color.Transparent)
        .hitTestBehavior(HitTestMode.Transparent)
        .onTouch((event: TouchEvent) => {
          if (!this.isSearchMode) {
            return;
          }
          if (event.type !== TouchType.Down) {
            return;
          }
          try {
            const x = event.touches[0].x;
            const y = event.touches[0].y;
            let rect = AppStorage.get('searchRect') as Rect;
            // 判断点击是否在Search区域之外
            if (x < rect.x || x > rect.x + rect.width || y < rect.y || y > rect.y + rect.height) {
              this.getUIContext().getFocusController().clearFocus();
              LogUtil.info(TAG + ' click other than search to clearFocus success.');
            }
          } catch (e) {
            LogUtil.error(TAG + ` click other than search failed, code: ${e?.code} message: ${e?.message}`);
          }
        })
    }
    .height(ConfigData.WH_100_100)
    .width(ConfigData.WH_100_100)
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .accessibilityLevel(this.isRecordItemFloatMenuShown ? 'no-hide-descendants' : 'yes')
    .onKeyPreIme((event?: KeyEvent) => {
      if (event && event.type === KeyType.Down && event.keyCode === KEYCODE_ESCAPE) {
        return this.handlePressEsc();
      }
      return false;
    })
    .onAppear(() => {
      LogUtil.info(TAG + ' The main page has been loaded.');
    })
  }

  @Builder
  subTitleBuilder() {
    Column() {
      Row() {
        Button() {
          SymbolGlyph(this.isShowSideBar ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'))
            .fontWeight(FontWeight.Normal)
            .fontSize($r('sys.float.ohos_id_text_size_headline7'))
            .fontColor([$r('sys.color.ohos_id_color_titlebar_icon')])
            .hitTestBehavior(HitTestMode.None)
        }
        .id('side_bar_button')
        .accessibilityText(this.isShowSideBar
          ? getContext().resourceManager.getStringSync($r('app.string.collapse_side_navigation_bar'))
          : getContext().resourceManager.getStringSync($r('app.string.show_side_navigation_bar')))
        .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
        .height(40)
        .width(40)
        .opacity(this.isSearchMode ? 0 : 1)
        .animation({ curve: Curve.Sharp, duration: 100 })
        .visibility(this.isSearchMode || this.isEditMode ? Visibility.None : Visibility.Visible)
        .onClick(() => {
          this.handleClickSideBarBtn();
        })

        Text(this.isEditMode ? $r('app.plural.partial_select_plural', this.selectedRecordList.length,
          this.selectedRecordList.length) : sideBarModeToNameMap[this.sideFolderNameFlag])
          .fontWeight(FontWeight.Bold)
          .lineHeight('23vp')
          .fontSize('20vp')
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(1)
          .layoutWeight(1)
          .margin({
            left: Configuration.getLocale().dir === 'rtl' ? 0 : 8,
            right: Configuration.getLocale().dir === 'rtl' ? 8 : 0
          })
      }
      .width('100%')
      .height(this.titleHeight)
      .alignItems(VerticalAlign.Center)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .padding({ top: this.getEffectiveStatusBarHeight() })
  }

  @Builder
  myRouter() {
    RecordPlayPage({
      recordDataGroupList: this.recordDataGroupList,
      currentTimePlay: this.currentTimePlay,
      tranState: this.focusRecord.tranState,
      isSkipMute: this.isSkipMute
    })
  }

  /* instrument ignore next */
  registerScreenListener() {
    let subscribeCB = (err: Base.BusinessError, data: CommonEventManager.CommonEventData) => {
      if (err) {
        LogUtil.error(TAG + `subscribe failed, code is ${err.code}, message is ${err.message}`);
      } else {
        LogUtil.info(TAG + ` onScreenStateChange ${JSON.stringify(data)}`);
        if (CommonEventManager.Support.COMMON_EVENT_SCREEN_OFF === data.event) {
          this.isScreenOn = false;
        }
        if (CommonEventManager.Support.COMMON_EVENT_SCREEN_ON === data.event) {
          this.isScreenOn = true;
        }
        if (CommonEventManager.Support.COMMON_EVENT_SCREEN_LOCKED === data.event) {
          this.isScreenLock = true;
        }
        if (CommonEventManager.Support.COMMON_EVENT_SCREEN_UNLOCKED === data.event) {
          this.isScreenLock = false;
          if (this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED && this.isSmallFoldVer) {
            this.renameDialogController.close();
            this.detailDialogController.close();
            if (this.showAboutPage) {
              this.showAboutPage = false;
            }
            if (this.isEditMode) {
              this.exitEditMode();
            }
            if (this.showPersonalDataPage) {
              this.showPersonalDataPage = false;
            }
            if (this.isSearchMode) {
              this.isSearchMode = false;
            }
          }
        }
      }
    }
    ScreenStateListener.registerListener(subscribeCB);
    try {
      display.on('change', this.displayChangeCallback);
    } catch (error) {
      LogUtil.error(TAG + ' registerScreenListener display on error');
    }
  }

  /* instrument ignore next */
  async requestLocationPermission() {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    await atManager.requestPermissionsFromUser(getContext(this), permissionList);
    await PreferencesUtil.put('isUserGrantedLocation', true);
    this.isUserAllow = true;
  }

  displayChangeCallback = () => {
    let newDensityPixels: number = Util.getDensityPixels();
    // instrument ignore if
    if (this.densityPixels !== newDensityPixels) {
      this.densityPixels = newDensityPixels;
    }
    try {
      let currentDensityDPI = display.getDefaultDisplaySync().densityDPI;
      let currentDensityPixels = currentDensityDPI / STANDARD_DPI;
      this.setPadDisplayScale(currentDensityPixels);
    } catch (error) {
      LogUtil.error(TAG + ' displayChangeCallback meet error');
    }
  }

  /* instrument ignore next */
  async setPadDisplayScale(currentDensityPixels: number) {
    if (DeviceUtil.isTabletOrTripleGStatus() && DeviceUtil.isLandscape()) {
      // 显示大小缩放，xyao设备，currentDensityPixels对应的值为1.91->2.25->2.625->3->3.375
      LogUtil.info(TAG + ' setPadDisplayScale-currentDensityPixels: ' + currentDensityPixels);
      if (currentDensityPixels >= 3) {
        this.displaySizeScale = CommonConstants.PAD_DISPLAY_SIZE_SCALE_LARGER;
      } else {
        this.displaySizeScale = CommonConstants.PAD_DISPLAY_SIZE_SCALE_NORMAL;
      }
    } else {
      this.displaySizeScale = CommonConstants.PAD_DISPLAY_SIZE_SCALE_NORMAL;
    }
    AppStorage.setOrCreate('displaySizeScale', this.displaySizeScale);
  }

  /* instrument ignore next */
  unRegisterScreenListener() {
    ScreenStateListener.unRegisterListener();
    try {
      display.off('change', this.displayChangeCallback);
    } catch (error) {
      LogUtil.error(TAG + ' unRegisterScreenListener display off failed: ' + error);
    }
  }

  /* instrument ignore next */
  private registerCloneDoneListener(): void {
    let subscribeCB = async (err: Base.BusinessError) => {
      if (err) {
        LogUtil.error(TAG + ` subscribe clone done failed, code is ${err.code}, message is ${err.message}`);
        return;
      }
      this.hasCloneEvent = true;
      // 获取回收站中录音记录
      await this.handleRecentDeleteRecordingsAdded();
      // 获取普通录音数据
      await this.handleAudioRecordingsAdded();

      // 刷新侧边栏及主界面数据
      this.onRecordDataGroupListChange();
    }
  }

  /* instrument ignore next */
  async isCeliaEnabledChange() {
    if (!this.isCeliaEnabled) {
      this.recordDataGroupList.callRecordList.forEach((value) => {
        value.preTranState = value.tranState;
        value.tranState = -1;
      })
      this.recordDataGroupList.normalRecordList.forEach((value) => {
        value.preTranState = value.tranState;
        value.tranState = -1;
      })
    } else {
      this.recordDataGroupList.callRecordList.forEach((value) => {
        value.tranState = value.preTranState;
      })
      this.recordDataGroupList.normalRecordList.forEach((value) => {
        value.tranState = value.preTranState;
      })
    }
    this.recordDataGroupList.normalRecordList.reload();
    this.recordDataGroupList.callRecordList.reload();
  }

  /* instrument ignore next */
  isSearchModeChange(changedPropertyName: string) {
    this.isExitTopAction = !this.isSearchMode;
  }

  onRecordTransState() {
    this.getRecordPlayBindSheetHeight();
  }

  // 防抖外壳
  /* instrument ignore next */
  private handleSelect = Helps.debounce(() => {
    HiSysEventUtil.eventDotting(HiSysEventName.SELECT_ALL_RECORD_LIST,
      { VALUE: this.isSelectedAllAudio ? 'NOT_ALL' : 'ALL' }
    );
    this.selectAllHandle(this.isSelectedAllAudio);
  }, 100)

  /* instrument ignore next */
  onIsShowQuickTransChange() {
    LogUtil.info(TAG + ' isShowQuickTrans:' + this.isShowQuickTrans);
    this.getRecorderWindowHeight();
  }

  /* instrument ignore next */
  private getSmallFoldSplit(): boolean {
    return this.isVerdeFolded ||
      (this.isSmallFoldVer && this.windowStatusType === window.WindowStatusType.SPLIT_SCREEN);
  }
}

