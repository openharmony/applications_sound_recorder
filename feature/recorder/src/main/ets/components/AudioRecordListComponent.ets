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
  AuditLogManager,
  CommonConstants,
  DeviceUtil,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  NotificationUtil,
  PathUtil,
  Util,
  RecordType,
  GlobalContext
} from '@ohos/common';
import { LazyDataSource, RecordData } from '@ohos/common/src/main/ets/model/RecordData';
import { ConfigData } from '@ohos/common/src/main/ets/utils/ConfigData';
import { AudioRecordItemComponent } from './AudioRecordItemComponent';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import { BusinessError } from '@ohos.base';
import { PlayManager } from '../controller/PlayManager';
import { Configuration, CustomContentDialog, display } from '@kit.ArkUI';
import ContactsManagerUtil from '@ohos/common/src/main/ets/utils/ContactsManagerUtil';
import { SideBarMode } from './SideBarComponent';
import { SearchComponent } from './SearchComponent';
import { PreferencesUtil } from '@ohos/common/src/main/ets/utils/PreferencesUtil';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { KeyCode } from '@kit.InputKit';
import Curves from '@ohos.curves';
import i18n from '@ohos.i18n';

const TAG = 'SoundRecorder_AudioRecordListComponent';

const LIST_ITEM_SPACE: number = 12;
const NAV_BAR_WIDTH_PROPORTION: number = 0.4;
const permissionList: Permissions[] = [
  'ohos.permission.APPROXIMATELY_LOCATION',
  'ohos.permission.LOCATION'
];

// 列表形式下滚动区域的宽度
const CHECK_BOX_WIDTH: number = 40;
// 列表滚动区域Margin值
const CHECK_BOX_MARGIN: number = 20;
// 滚动速度: 贝塞尔曲线
const SLIDE_SELECT_SPEED_CURVE = Curves.cubicBezierCurve(0.33, 0, 0.67, 1);

// 滑动的操作类型
export enum SlideActionType {
  START,
  UPDATE,
  END
}

// 滑动多选时，滚动条滚动的方向
enum ScrollDir {
  NONE = 'NONE',
  TOP = 'TOP',
  BOTTOM = 'BOTTOM'
}

@Component
export struct AudioRecordListComponent {
  private audioRecordListController: AudioRecordListController = new AudioRecordListController();
  private scroller: ListScroller = new ListScroller();
  private isAudioRecordListShowUp = false;
  private deleteSourcePage: string = '';
  @StorageLink('isEditMode') isEditMode: boolean = false;
  @StorageLink('isNormalMode') isNormalMode: boolean = true;
  @StorageLink('enterEdit') enterEdit: boolean = false;
  @StorageLink('screenHeight') screenHeight: number = 0;
  @StorageProp('jumpFromContacts') jumpFromContacts: boolean = false;
  @State isCallRecordVisible: Visibility = Visibility.None;
  @ObjectLink recordDataList: LazyDataSource<RecordData>;
  @Consume @Watch('onFocusRecordChange') focusRecord: RecordData;
  @Consume selectedRecordList: RecordData[];
  @Link currentTimePlay: number;
  @Consume state: string;
  @Provide @Watch('onCloseAllSwipe') isCloseAllSwipe: boolean = false;
  @Provide @Watch('clickDeleteInSwipeMenu') isClickDeleteInSwipeMenu: boolean = false;
  @StorageProp('isScreenOn') @Watch('onScreenChange') isScreenOn: boolean = true;
  @StorageProp('isScreenLock') @Watch('onScreenLockChange') isScreenLock: boolean = false;
  @StorageProp('foldDisplayMode') @Watch('onFoldModeChange') foldDisplayMode: number = 0;
  @StorageProp('isLtr') @Watch('onLangDirectionChange') isLtr: boolean = Configuration.getLocale().dir === 'ltr';
  @StorageLink('RecordPlayBindSheet') isShowRecordPlay: boolean = false;
  @StorageProp('navigationMode') navMode: number = 0;
  @StorageProp('navigatorBarHeight') navigatorBarHeight: number = 0;
  @StorageProp('isMaskShow') isMaskShow: boolean = false;
  @State navBarWidth: number = 0;
  @Consume isSearchMode: boolean;
  //排序方式
  @Prop sortType: string;
  @Link isAudioRecordExist: boolean;
  @State searchStatus: number = CommonConstants.NOT_SEARCH;
  @Consume recordingCount: number;
  @Consume recentDeleteRecordingCount: number;
  @Consume sideFolderNameFlag: number;
  @Consume callRecordingCount: number;
  @Consume headsetRecordingCount: number;
  @Consume isExitTopAction: boolean;
  @State isSearchCloseSwipe: boolean = false;
  @Provide deletingOrRecoveringDialog: string = CommonConstants.DIALOG_DELETING;
  @Provide accessibilityTip: string = '';
  // VerXXX小折叠产品首次使用或者最近删除页面tips相关变量
  @State closeButtonBackgroundColor: ResourceColor = $r('sys.color.ohos_id_color_background_transparent');
  @Link isUserAllow: boolean;
  @Link isTipsClose: boolean;
  @Link isOverOneWeek: boolean;
  @State buttonBackgroundColor: ResourceColor = $r('sys.color.ohos_id_color_background_transparent');
  @State accessBtnHeight: number = 19;
  @State msgTextHeight: number = 38;
  @State tipsHeight: number = 89;
  @Consume defaultDP: number;
  @Consume densityPixels: number;
  @Link isSkipMute: boolean;
  private listWidth: number = 0;
  @Provide isSwipeOpen: boolean = false;
  private scrollStartIndex: number = 0;
  private scrollEndIndex: number = 0;
  // 滚动部位显示区域的高度
  @State contentHeight: number = 0;
  @State areaY: number = 0;
  // 滑动的初始点位
  @State startIndex: number = -1;
  @State updateIndex: number = -1;
  @State lastUpdateIndex: number = -1;
  // 每次滑动时，当前列表选中状态，滑动结束后清空
  @State oldCheckList: boolean[] = [];
  // 滑动过程中是否将经过的点设为选中状态
  @State setChecked: boolean = false;
  // 停止手势
  @State stopGesture: boolean = false;
  @State scrollDir: ScrollDir = ScrollDir.NONE;
  // 热区
  private hotAreaLength = Math.round(Util.getDensityDPI() * 10 / 25.4 / Util.getDensityPixels());
  // 滚动速度: 最大速度
  private autoSpeedMax: number = Math.round(2400 / display.getDefaultDisplaySync().densityPixels);

  private getAccessibilityTip(): string {
    if (this.isSearchMode) {
      return getContext(this).resourceManager.getStringSync($r('app.string.accessibility_double_click'));
    }
    const clickStr = getContext(this).resourceManager.getStringSync($r('app.string.accessibility_double_click'));
    const longPressStr = getContext(this).resourceManager.getStringSync($r('app.string.accessibility_long_press'))
    return `${clickStr} ${longPressStr}`;
  }

  private onCloseAllSwipe() {
    if (this.isCloseAllSwipe && this.isAudioRecordListShowUp) {
      LogUtil.info(TAG + ' closeAllSwipeActions.');
      try {
        this.scroller.closeAllSwipeActions();
        this.isSwipeOpen = false;
      } catch (err) {
        let message = (err as BusinessError).message;
        LogUtil.error(TAG + ' onCloseAllSwipe closeAllSwipeActions error ' + message)
      }
      this.isCloseAllSwipe = false;
    }
  }

  private clickDeleteInSwipeMenu() {
    if (this.isClickDeleteInSwipeMenu) {
      LogUtil.info(TAG + ' click delete in swipe menu, begin to delete.');
      this.deleteSourcePage = 'swipeDelete';
      this.deleteDialogController.open();
      this.isClickDeleteInSwipeMenu = false;
    }
  }

  private onFocusRecordChange(): void {
    LogUtil.info(`${TAG} onFocusRecordChange.`);
    const player = PlayManager.getInstance();
    if (!this.isAudioRecordListShowUp ||
      (this.navMode === NavigationMode.Stack && this.sideFolderNameFlag !== SideBarMode.CALL_RECORDINGS)) {
      LogUtil.error(TAG + ' audio record list has not show up, can not operate scroller.');
      return;
    }
  }

  //删除框确认按钮调用接口
  private async confirmDelete(items: RecordData[], isShowConfirmDialog: boolean = true): Promise<void> {
    LogUtil.info(TAG + ' confirm to delete, num is: ' + items.length);
    if (items.length === 0) {
      LogUtil.error(TAG + ' items length to delete is 0. ');
      return;
    }
    if (items.length > 100) {
      isShowConfirmDialog ? this.detailProgressController.open() : '';
    }
    const auditLogManager = AuditLogManager.getInstance();
    this.removeRecordData(items, this.sideFolderNameFlag).then(() => {
      if (this.deleteSourcePage === 'swipeDelete' || this.deleteSourcePage === 'longSwipeDelete') {
        this.isCloseAllSwipe = true;
      }
      if (items.findIndex(item => item._data === this.focusRecord._data) !== -1) {
        LogUtil.info(TAG + ' delete the focusRecord, stop it first.');
        PlayManager.getInstance().reset();
        this.state = 'idle';
      }
      auditLogManager.deleteAuditLog('SUCCESS', this.deleteSourcePage, items.length);
      getContext().eventHub.emit('removeIndexList', items,
        this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS);
    }).catch((err: BusinessError) => {
      auditLogManager.deleteAuditLog('FAIL', this.deleteSourcePage, items.length)
      this.deleteHiSysEvent(items, CommonConstants.FAILURE);
      LogUtil.error(TAG + ` removeRecordData error, code: ${err?.code}, message: ${err?.message}`);
    });
  }

  private deleteHiSysEvent = (items: RecordData[], status: number) => {
    let idList = ContactsManagerUtil.getInstance().batchAddCallRecordPrefix(items);
    if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
      let callNum = 'CallRecord: ' + this.callRecordingCount;
      let normalNum = ', NormalRecord: ' + this.recordingCount;
      let headsetNum = ', headsetRecord: ' + this.headsetRecordingCount;
      let recentDeleteNum = ', recentDeleteNum: ' + this.recentDeleteRecordingCount;
      HiSysEventUtil.eventDotting(HiSysEventName.DEL_CONFIRM_DEL,
        {
          NUM: items.length,
          SUCCESS: status,
          FILEID: idList.toString(),
          REMAINING_FILE_COUNT: callNum + normalNum + headsetNum + recentDeleteNum
        }
      );
      return;
    }
    if (this.deleteSourcePage === 'indexDelete') {
      HiSysEventUtil.eventDotting(HiSysEventName.DELETE_CONFIRM,
        { VALUE: items.length, SUCCESS: status, FILEID: idList.toString() }
      );
    } else if (this.deleteSourcePage === 'playPageDelete') {
      HiSysEventUtil.eventDotting(HiSysEventName.DELETE_TRACK_CONFIRM_ON_PLAYING,
        { SUCCESS: status, FILEID: idList.toString() }
      );
    } else if (this.deleteSourcePage === 'floatDelete') {
      HiSysEventUtil.eventDotting(HiSysEventName.DELETE_FLOAT_RECORD_LIST_CONFIRM,
        { SUCCESS: status, FILEID: idList.toString() }
      );
    } else if (this.deleteSourcePage === 'longSwipeDelete') {
      HiSysEventUtil.eventDotting(HiSysEventName.LONG_SWIPE_DELETE_CONFIRM,
        { SUCCESS: status, FILEID: idList.toString() }
      );
    } else {
      HiSysEventUtil.eventDotting(HiSysEventName.SWIPE_DELETE_CONFIRM, { SUCCESS: status, FILEID: idList.toString() });
    }
    this.deleteSourcePage = '';
  }
  //删除弹框
  private deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({
      primaryTitle: $r('app.string.recent_delete_dialog_title'),
      contentBuilder: () => {
        this.buildContent(this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS ?
          this.selectedRecordList.length > 1 ? $r('app.string.recent_delete_dialog_summary_multi') :
            $r('app.string.recent_delete_dialog_summary') :
          this.selectedRecordList.length > 1 ?
            $r('app.string.first_delete_dialog_summary', CommonConstants.RECYCLE_DAYS_LIMIT) :
            $r('app.string.first_delete_dialog_summary_one', CommonConstants.RECYCLE_DAYS_LIMIT));
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          fontColor: '#FB654E',
          background: Color.Transparent,
          buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
          action: () => {
            try {
              this.scroller.closeAllSwipeActions();
              this.isSearchCloseSwipe = true;
            } catch (err) {
              let message = (err as BusinessError).message;
              LogUtil.error(TAG + ' button cancel onClick closeAllSwipeActions error ' + message);
            }
            this.deleteDialogController.close();
          },
        },
        {
          value: $r('app.string.delete'),
          fontColor: '#FB654E',
          background: Color.Transparent,
          buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
          action: () => {
            this.deleteItem();
          },
        }
      ]
    }),
    autoCancel: true,
    cancel: () => {
      try {
        this.scroller.closeAllSwipeActions();
        this.isSearchCloseSwipe = true;
      } catch (err) {
        let message = (err as BusinessError).message;
        LogUtil.error(TAG + ' deleteDialogController closeAllSwipeActions error ' + message);
      }
    },
    alignment: DialogAlignment.Center,
    offset: { dx: 0, dy: 0 },
    cornerRadius: DeviceUtil.isPC() ? $r('app.float.distance_16') : $r('app.float.distance_32'),
    customStyle: false,
    onDidDisappear: () => {
      if (this.isShowRecordPlay) {
        AccessibilityUtil.sendFocusAccessibilityEvent('evenMore');
      } else {
        AccessibilityUtil.sendFocusAccessibilityEvent('side_bar_button');
      }
    },
  })

  private getDeleteDialogContent(): Resource {
    if (this.selectedRecordList.length === 1) {
      return $r('app.string.delete_hint');
    } else {
      if (this.selectedRecordList.length === this.recordDataList.totalCount()) {
        return $r('app.string.delete_all_record');
      } else {
        return $r('app.plural.partial_delete_record_plural',
          this.selectedRecordList.length, this.selectedRecordList.length);
      }
    }
  }

  @Builder
  /* instrument ignore next */
  buildContent(context: ResourceStr): void {
    Text(context)
  }

  private deleteItem(): void {
    this.deleteDialogController.close();
    setTimeout(() => {
      this.isEditMode = false;
      this.enterEdit = false;
      this.isNormalMode = true;
      AppStorage.setAndLink('isEditMode', this.isEditMode);
      AppStorage.setOrCreate('hideToolBar', true);
      this.confirmDelete(this.selectedRecordList);
      if (this.isShowRecordPlay) {
        this.isShowRecordPlay = false;
        AccessibilityUtil.sendFocusAccessibilityEvent('side_bar_button');
      }
    }, 10);
  }

  // VerXXX小折叠产品，外屏首次使用时出现沉浸态的tips提示
  @Builder
  verderPermissionTips() {
    ListItem() {
      Flex({
        direction: FlexDirection.Column,
        justifyContent: FlexAlign.Center
      }) {
        Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween }) {
          Scroll() {
            Text($r('app.string.access_location'))
              .fontSize($r('sys.float.Body_M'))
              .fontColor($r('sys.color.font_secondary'))
              .constraintSize({ minHeight: 38 })
              .maxFontScale(1.75)
              .onAreaChange((oldValue: Area, newValue: Area) => {
                let dp = this.densityPixels / this.defaultDP;
                dp = dp < 1 ? 1 : dp;
                const rowHeight = Math.round(Number(newValue.height) * dp);
                if (this.msgTextHeight !== rowHeight) {
                  this.msgTextHeight = rowHeight;
                }
              })
          }.scrollBar(BarState.Off)

          Button() {
            Image($r('sys.media.ohos_ic_public_cancel'))
              .matchTextDirection(Configuration.getLocale().dir === 'rtl' ? true : false)
              .width($r('app.float.wh_value_18'))
              .height($r('app.float.wh_value_18'))
              .fillColor($r('sys.color.icon_secondary'))
              .draggable(false)
          }
          .width($r('app.float.wh_value_22'))
          .height($r('app.float.wh_value_22'))
          .padding($r('app.float.padding_2'))
          .direction(Direction.Auto)
          .margin({
            left: Configuration.getLocale().dir === 'rtl' ? 0 : $r('app.float.distance_12'),
            right: Configuration.getLocale().dir === 'rtl' ? $r('app.float.distance_12') : 0
          })
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
          })
        }.height('100%')

        Button({ type: ButtonType.Capsule, stateEffect: false }) {
          Text($r('app.string.allow_access'))
            .fontSize($r('sys.float.Subtitle_S'))
            .fontColor($r('sys.color.font_emphasize'))
            .fontWeight(FontWeight.Medium)
            .maxFontSize(1.75)
        }
        .margin({ top: 8 })
        .padding($r('app.float.padding_4'))
        .onClick(async () => {
          LogUtil.info(TAG + ' confirm button click.');
          await this.requestLocationPermission();
        })
        .direction(Direction.Auto)
        .backgroundColor(this.buttonBackgroundColor)
        .onHover((isHover: boolean) => {
          if (isHover) {
            this.buttonBackgroundColor = $r('sys.color.ohos_id_color_hover')
          } else {
            this.buttonBackgroundColor = $r('sys.color.ohos_id_color_background_transparent')
          }
        })
        .align(Alignment.Start)
        .onAreaChange((oldValue: Area, newValue: Area) => {
          let dp = this.densityPixels / this.defaultDP;
          dp = dp < 1 ? 1 : dp;
          const rowHeight = Math.round(Number(newValue.height) * dp);
          if (this.accessBtnHeight !== rowHeight) {
            this.accessBtnHeight = rowHeight;
          }
        })
      }
      .direction(Direction.Auto)
      .padding($r('app.float.distance_12'))
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .borderRadius($r('sys.float.corner_radius_level9'))
      .visibility(this.isEditMode ? Visibility.None : Visibility.Visible)
      .height(this.getTipsHeight())
      .constraintSize({ minHeight: 89, maxHeight: 160 })
    }
  }

  async requestLocationPermission() {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    await atManager.requestPermissionsFromUser(getContext(this), permissionList);
    await PreferencesUtil.put('isUserGrantedLocation', true);
    this.isUserAllow = true;
  }

  private getTipsHeight(): number {
    return this.tipsHeight = this.msgTextHeight + 32 + this.accessBtnHeight;
  }

  //删除/恢复之后动效弹框
  private detailProgressController: CustomDialogController = new CustomDialogController({
    builder: detailProgressDialog({}),
    offset: { dy: 16, dx: 0 },
    gridCount: 4,
    cornerRadius: DeviceUtil.isPC() ? $r('app.float.distance_16') : $r('app.float.distance_32')
  })
  // 监听通话录音跳转
  private onCallRecordJump: Function = () => {
    LogUtil.info(TAG + ' onCallRecordJump');
    this.callRecordJump();
  };

  private callRecordJump(): void {
    let callAPPId = AppStorage.get('callAPPId') || -1;
    setTimeout(() => {
      let itemIndex = this.recordDataList.getAll().findIndex(item => item.id === callAPPId);
      this.scroller.scrollToIndex(itemIndex + 1, false, ScrollAlign.AUTO);
    }, 200);
  }

  private setCallback() {
    const player = PlayManager.getInstance();
    getContext().eventHub.on('callRecordJump', this.onCallRecordJump);
    getContext(this).eventHub.on('openDeleteDialog', (deleteModule: string) => {
      this.deleteSourcePage = deleteModule;
      this.deletingOrRecoveringDialog = CommonConstants.DIALOG_DELETING;
      if (deleteModule === 'longSwipeDelete') {
        LogUtil.info(TAG + ' swipe to delete and open delete dialog.');
        this.deleteDialogController.open();
      } else if (deleteModule === 'indexDelete' || deleteModule === 'floatDelete') {
        LogUtil.info(TAG + ' click delete in index page and open delete dialog.');
        this.selectedRecordList.forEach(ele => {
          ele.indexDelete = true;
        })
        this.deleteDialogController.open();
      } else if (deleteModule === 'floatMenuDeleteAll' || deleteModule === 'floatRecentDelete') {
        // 最近删除的悬浮卡片、多选删除
        this.deleteDialogController.open();
      } else {
        LogUtil.info(TAG + ' click delete in record play page and open delete dialog.');
        this.selectedRecordList = [this.focusRecord];
        this.deleteDialogController.open();
      }
    });

    getContext(this).eventHub.on('recoverFromRecentDelete', this.recoverFromRecentDeleteCallBack);

    getContext(this).eventHub.on('closeProcessDetailDialog', (task: string) => {
      LogUtil.info(TAG + ' handle done task ' + task);
      this.detailProgressController.close();
    });
  }

  private recoverFromRecentDeleteCallBack = async (recoverFrom: string) => {
    LogUtil.info(TAG + ' recoverFromRecentDeleteCallback: ' + recoverFrom);
    // 恢复或删除操作的时候，需要停止当前正在播放的录音文件
    if (this.selectedRecordList.find(item => item._data === this.focusRecord._data)) {
      PlayManager.getInstance().reset();
    }
    this.deletingOrRecoveringDialog = CommonConstants.DIALOG_RECOVERING;

    if (this.selectedRecordList.length > 100) {
      this.detailProgressController.open();
    }

    // 将最近删除中选中的记录移除
    await DatabaseManager.removeRecentDeleteRecordData(this.selectedRecordList.map(item => item._data));

    // 将选中的记录中的通话录音恢复
    let callRecord = this.selectedRecordList.filter(item => item.phoneNumber).map(item => item._data);
    if (callRecord.length > 0) {
      if (callRecord.length > CommonConstants.CALL_RECORD_UPDATA_MAX) {
        let callRecordSliceArray: string[][] = [];
        for (let i = 0; i < callRecord.length; i += CommonConstants.CALL_RECORD_UPDATA_MAX) {
          if (i + CommonConstants.CALL_RECORD_UPDATA_MAX > callRecord.length) {
            callRecordSliceArray.push(callRecord.slice(i, callRecord.length));
          } else {
            callRecordSliceArray.push(callRecord.slice(i, i + CommonConstants.CALL_RECORD_UPDATA_MAX));
          }
        }
        for (let callRecord of callRecordSliceArray) {
          await DatabaseManager.markCallRecordRecoverFromRecycleBin(callRecord);
        }
      } else {
        await DatabaseManager.markCallRecordRecoverFromRecycleBin(callRecord);
      }
    }

    // 将选中的记录中的普通录音恢复
    let normalRecord =
      this.selectedRecordList.filter(item => !item.phoneNumber);
    if (normalRecord.length > 0) {
      await DatabaseManager.insertToNormalRecordTable(normalRecord);
    }

    // 通知UI刷新
    getContext().eventHub.emit('recentDeleteRecover', this.selectedRecordList);
  }

  private unsetCallback() {
    const player = PlayManager.getInstance();
    getContext(this).eventHub.off('openDeleteDialog');
    getContext(this).eventHub.off('recoverFromRecentDelete');
    getContext(this).eventHub.off('closeProcessDetailDialog');
    getContext().eventHub.off('callRecordJump');
  }

  private updateNavBarWidth(): void {
    let currentDp: number = Util.getDensityPixels();
    let currentWindowWidth: number | undefined = AppStorage.get<number>('windowWidth');
    if (currentWindowWidth) {
      this.navBarWidth = currentWindowWidth * NAV_BAR_WIDTH_PROPORTION / currentDp;
    }
    LogUtil.info(`${TAG} dpValue: ${currentDp},  windowWidth: ${currentWindowWidth}, navBarWidth: ${this.navBarWidth}`);
  }

  async aboutToAppear() {
    LogUtil.info(TAG + ' aboutToAppear.');
    GlobalContext.getUIAbilityContext().eventHub?.on('removeRecordHiSysEvent', this.deleteHiSysEvent);
    this.isAudioRecordListShowUp = true;
    this.accessibilityTip = this.getAccessibilityTip();
    this.callRecordJump();
    this.updateNavBarWidth();
    if (this.audioRecordListController) {
      this.audioRecordListController.deleteDialogController = this.deleteDialogController;
    }
  }

  aboutToDisappear() {
    LogUtil.info(TAG + ' aboutToDisappear.');
    GlobalContext.getUIAbilityContext().eventHub?.off('removeRecordHiSysEvent', this.deleteHiSysEvent);
  }

  @Builder
  searchHeader() {
    SearchComponent({
      searchStatus: this.searchStatus,
      sortType: this.sortType,
      currentTimePlay: this.currentTimePlay,
      isSearchCloseSwipe: this.isSearchCloseSwipe
    })
  }

  getPhoneBottomDistance(): number {
    if (DeviceUtil.isPC() || this.isEditMode) {
      return 0;
    }
    return this.navigatorBarHeight - LIST_ITEM_SPACE;
  }

  build() {
    Column() {
      // 搜索组件
      List() {
        ListItem() {
          Column() {
            this.searchHeader()
          }
          .margin({top:15})
          .padding({ bottom: 8 })
        }
        .zIndex(2)
        .visibility(
          this.isEditMode ? Visibility.None :
            (this.isSearchMode ? Visibility.Visible :
              ((this.isAudioRecordExist && this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) ?
                (DeviceUtil.isSmallFoldVer() && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED ?
                  Visibility.None : Visibility.Visible) : Visibility.None))
        )
        .opacity(this.isEditMode ? 0.4 : 1)
      }
      .enabled(!this.isMaskShow)
      .padding(this.getListHorizontalMargin())

      List({ scroller: this.scroller, space: LIST_ITEM_SPACE }) {
        if (!this.isUserAllow && this.isOverOneWeek && !this.isTipsClose &&
          this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS &&
          (DeviceUtil.isSmallFoldVer() && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED)) {
          this.verderPermissionTips();
        }

        if (this.searchStatus === CommonConstants.NOT_SEARCH) {
          LazyForEach(this.recordDataList, (item: RecordData, index: number) => {
            AudioRecordItemComponent({
              index: index,
              item: item,
              state: this.state,
              currentTimePlay: this.currentTimePlay,
              isCallRecord: item.phoneNumber !== undefined,
              isSearchCloseSwipe: this.isSearchCloseSwipe
            })
          }, (item: RecordData) => item._data)
        }
        if (!this.isEditMode) {
          ListItem().height(this.navigatorBarHeight + 92)
        }
      }
      .layoutWeight(1)
      .enableScrollInteraction(this.searchStatus !== CommonConstants.HAS_SEARCH_RESULTS)
      .scrollBar(this.searchStatus !== CommonConstants.NOT_SEARCH ? BarState.Off :
        (DeviceUtil.isSmallFoldVer() && DeviceUtil.isFolded()) ? BarState.Off :
          BarState.Auto)
      .contentStartOffset(DeviceUtil.isSmallFoldVer() &&
        this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED ? 56 : 0)
      .expandSafeArea(null, this.isEditMode ? [] : [SafeAreaEdge.BOTTOM])
      .width(ConfigData.WH_100_100)
      .height(ConfigData.WH_100_100)
      .listDirection(Axis.Vertical)
      .flexGrow(1)
      .padding(this.getListHorizontalMargin())
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true }) // 边缘效果设置为Spring
      .onAppear(() => {
        LogUtil.info(TAG + ' audio record list appear.');
      })
      .onAreaChange((_, newVal) => {
        let navWidth: number = newVal.width as number;
        AppStorage.setOrCreate('navWidth', navWidth);
        this.areaY = newVal.globalPosition.y as number;
        this.contentHeight = newVal.height as number;
      })
      .onSizeChange((oldValue: SizeOptions, newValue: SizeOptions) => {
        this.listWidth = newValue.width as number
      })
      .cachedCount(5)
      .gesture(
        PanGesture({ direction: PanDirection.Vertical })
          .onActionStart((event: GestureEvent | undefined) => {
            this.panGestureAction(SlideActionType.START, event);
          })
          .onActionUpdate((event: GestureEvent | undefined) => {
            this.panGestureAction(SlideActionType.UPDATE, event);
          })
          .onActionEnd((event?: GestureEvent) => {
            this.panGestureAction(SlideActionType.END, event);
          }),
        GestureMask.Normal
      )
      .onGestureRecognizerJudgeBegin((event: BaseGestureEvent, current: GestureRecognizer,
        recognizers: Array<GestureRecognizer>) => {
        if (this.isEditMode && current.isBuiltIn() &&
          current.getType() == GestureControl.GestureType.PAN_GESTURE && event.fingerList[0] != undefined &&
          event.fingerList[0].localX != undefined && this.isCheckBoxSection(event)) {
          return GestureJudgeResult.REJECT;
        }
        return GestureJudgeResult.CONTINUE;
      })
      .onScrollIndex((start, end) => {
        this.scrollStartIndex = start;
        this.scrollEndIndex = end;
      })
    }.onAppear(() => {
      // 此类AudioRecordListComponent的组件属于多个窗口复用一个组件，
      // 放在页面加载的aboutToAppear和aboutToDisappear生命周期中会造成紊乱。故此放在列表加载的onAppear和onDisAppear中
      this.setCallback();
    }).onDisAppear(() => {
      this.unsetCallback();
    })
  }

  //手指滑动区域是否在CheckBox的热区范围内
  isCheckBoxSection(event: BaseGestureEvent): boolean {
    return i18n.isRTL(i18n.System.getSystemLanguage()) ?
      (event.fingerList[0]?.localX < CHECK_BOX_WIDTH + CHECK_BOX_MARGIN &&
        event.fingerList[0]?.localX > CHECK_BOX_MARGIN) :
      (event.fingerList[0]?.localX > this.listWidth - CHECK_BOX_WIDTH - CHECK_BOX_MARGIN &&
        event.fingerList[0]?.localX < this.listWidth - CHECK_BOX_MARGIN)
  }

  // 滑动多选操作
  panGestureAction(type: SlideActionType, event: GestureEvent | undefined): void {
    if (this.stopGesture) {
      return;
    }
    // 非多选、非单指滑动等情况下不操作
    if (!this.isEditMode || DeviceUtil.isPC() || !event || !event.fingerList || event.fingerList.length !== 1) {
      return;
    }
    const finger = event.fingerList[0];
    const index = this.getIndex(finger);
    switch (type) {
      case SlideActionType.START: {
        this.slideActionStart(index);
        break;
      }
      case SlideActionType.UPDATE: {
        this.slideActionUpdate(index);
        this.autoScroll(finger);
        break;
      }
      case SlideActionType.END: {
        this.slideActionEnd();
        break;
      }
      default: {
      }
    }
  }

  //获取当前下标
  getIndex(finger: FingerInfo): number {
    let index = -1;
    try {
      if (this.scroller.getItemIndex) {
        index = this.scroller.getItemIndex(finger.localX, finger.localY);
      }
      if (index === -1) {
        for (let i = this.scrollStartIndex; i <= this.scrollEndIndex; i++) {
          const item = this.scroller.getItemRect(i);
          if (finger.localY < item.y ||
            finger.localY >= item.y && finger.localY <= item.y + item.height && finger.localX < item.x) {
            break;
          }
          index = i;
        }
      }
    } catch {
      // scroller未绑定完成时，直接调用getItemRect和getItemIndex会报错，闪退
      this.stopGesture = true;
      LogUtil.info(TAG + 'controller not bound to component');
      return index;
    }
    if (index === -1 && this.scrollDir === ScrollDir.TOP) {
      index = this.scrollStartIndex;
    }
    return index;
  }

  // 开始滑动多选，配置滑动过程中的初始数据
  slideActionStart(index: number): void {
    if (index < 0) {
      LogUtil.info(TAG + 'slideActionStart' + 'index is -1');
      return;
    }
    this.oldCheckList = this.recordDataList.getAll().map(it => it.flagSelect);
    let item = this.recordDataList.getData(index);
    this.setChecked = !item.flagSelect;
    LogUtil.info(TAG + 'this.setChecked' + this.setChecked);
    item.flagSelect = !item.flagSelect;
    this.updateSelectedRecordList(index);
    this.startIndex = index;
    this.updateIndex = index;
    LogUtil.info(TAG + `PanGesture start: ${this.startIndex},${index}`);
  }

  // 滑动多选更新
  slideActionUpdate(index: number): void {
    if (this.startIndex === -1) {
      this.slideActionStart(index);
      return;
    }
    if (index === -1) {
      LogUtil.info(TAG + 'slideActionUpdate' + 'index is -1');
      return;
    }
    LogUtil.info(TAG + `PanGesture update: ${this.updateIndex},${index}` + '' + this.scrollDir);
    // 1.滑动选择的项没有发生变化。2、滚动条向下滚动时，滑动选择的项应该依次递增。3、滚动条向上滚动时，滑动选择的项应该依次递减
    if (this.updateIndex === index || (this.scrollDir === ScrollDir.BOTTOM && index < this.updateIndex) ||
      (this.scrollDir === ScrollDir.TOP && index > this.updateIndex)) {
      return;
    }

    this.lastUpdateIndex = this.updateIndex;
    this.setListSourceChecked(index);
    this.updateIndex = index;
  }

  // 滑动结束
  slideActionEnd(): void {
    this.startIndex = -1;
    this.updateIndex = -1;
    this.oldCheckList = [];
    this.scroller.scrollBy(0, 0);
    this.scrollDir = ScrollDir.NONE;
    LogUtil.info(TAG + 'PanGesture End.');
  }

  // 重置列表数据中的选中项
  setListSourceChecked(index: number): void {
    const beginIndex = this.lastUpdateIndex === -1 ? this.startIndex : this.lastUpdateIndex;
    const start = Math.min(beginIndex, index);
    const end = Math.max(beginIndex, index);
    // 滑动多选经过的item选中状态重置为滑动多选之前的状态
    for (let i = start; i < end + 1; i++) {
      let item = this.recordDataList.getData(i);
      const isChecked = this.getCheckedByIndex(index, i);
      item.flagSelect = isChecked;
      this.updateSelectedRecordList(i)
    }
  }

  // 获取targetIndex处的item的选中状态
  getCheckedByIndex(currentIndex: number, targetIndex: number): boolean {
    const lastIndex = this.lastUpdateIndex === -1 ? this.startIndex : this.lastUpdateIndex;
    if (currentIndex >= lastIndex && lastIndex >= this.startIndex ||
      currentIndex <= lastIndex && lastIndex <= this.startIndex) {
      // 上次点在中间（上次点位和此次点位之间的数据都为初始点位的选中状态）
      return this.setChecked;
    } else {
      // 起始点在中间（起始点位到当前点位之间的数据的选中状态和起始点位保持一致，起始点位和上次选中点位的状态复原）
      if (targetIndex >= this.startIndex && targetIndex <= currentIndex ||
        targetIndex <= this.startIndex && targetIndex >= currentIndex) {
        return this.setChecked
      } else {
        //当前点在中间
        return this.oldCheckList[targetIndex];
      }
    }
  }

  // 自动滚动
  autoScroll(finger: FingerInfo): void {
    let pointY = finger.globalY - this.areaY;
    if (pointY <= this.hotAreaLength) {
      if (pointY <= 0) {
        return;
      }
      const speedFlag = pointY > 0 ? SLIDE_SELECT_SPEED_CURVE
        .interpolate(1 - pointY / this.hotAreaLength) : 1;
      this.scroller.scrollEdge(Edge.Top, {
        velocity: speedFlag * this.autoSpeedMax
      })
      this.scrollDir = ScrollDir.TOP;
    } else if (pointY > this.contentHeight - this.hotAreaLength) {
      if (pointY >= this.contentHeight) {
        return;
      }
      const speedFlag = pointY < this.contentHeight ? SLIDE_SELECT_SPEED_CURVE
        .interpolate(1 - (this.contentHeight - pointY) / this.hotAreaLength) : 1;
      this.scroller.scrollEdge(Edge.Bottom, {
        velocity: speedFlag * this.autoSpeedMax
      })
      this.scrollDir = ScrollDir.BOTTOM;
    } else {
      this.scrollDir = ScrollDir.NONE;
    }
  }

  private updateSelectedRecordList(index: number): void {
    let item = this.recordDataList.getData(index)
    let indexInSelectedRecordList = this.selectedRecordList.findIndex(record => record._data === item._data);
    if (item.flagSelect && indexInSelectedRecordList === -1) {
      this.selectedRecordList.push(item);
      HiSysEventUtil.eventDotting(HiSysEventName.SELECT_ITEM_ON_RECORD_LIST);
    }
    if (!item.flagSelect && indexInSelectedRecordList !== -1) {
      this.selectedRecordList.splice(indexInSelectedRecordList, 1);
      HiSysEventUtil.eventDotting(HiSysEventName.CNCL_SEL_ON_REC_LIST);
    }
  }

  // 列表父容器的窗口宽度，决定了列表左右两侧的margin
  private getListHorizontalMargin(): Margin {
    if (this.searchStatus !== CommonConstants.NOT_SEARCH) {
      return {
        left: 0,
        right: 0
      }
    }
    if (DeviceUtil.isPC()) {
      if (this.navBarWidth >= CommonConstants.NAV_WIDTH_MEDIUM) {
        return {
          left: $r('app.float.wh_value_32'),
          right: $r('app.float.wh_value_32'),
        };
      } else {
        if (this.navBarWidth >= CommonConstants.NAV_WIDTH_SMALL) {
          return {
            left: $r('app.float.wh_value_24'),
            right: $r('app.float.wh_value_24'),
          };
        } else {
          return {
            left: $r('app.float.wh_value_16'),
            right: $r('app.float.wh_value_16'),
          };
        }
      }
    } else {
      return {
        left: $r('app.float.wh_value_16'),
        right: $r('app.float.wh_value_16'),
      };
    }
  }

  onScreenChange() {
    LogUtil.info(TAG + ' screenStateChange, isScreenOn=' + this.isScreenOn);
    NotificationUtil.setScreenState(this.isScreenOn);
  }

  onScreenLockChange() {
    LogUtil.info(TAG + ' screenStateChange, isScreenLock=' + this.isScreenLock);
    if (!this.isScreenLock && DeviceUtil.isSmallFoldVer() &&
      this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) {
      this.deleteDialogController.close();
    }
  }

  onFoldModeChange() {
    LogUtil.info(TAG + ' foldModeChange, foldDisplayMode=' + this.foldDisplayMode);
    NotificationUtil.setDisplayMode(this.foldDisplayMode);
    if (DeviceUtil.isSmallFoldVer() && !this.isCloseAllSwipe) {
      this.isCloseAllSwipe = true;
    }
  }

  private onLangDirectionChange(): void {
    LogUtil.info(TAG + ' closeAllSwipeActions.');
    if (this.isAudioRecordListShowUp) {
      try {
        this.scroller.closeAllSwipeActions();
      } catch (err) {
        let message = (err as BusinessError).message;
        LogUtil.error(TAG + ' onLangDirectionChange closeAllSwipeActions error ' + message);
      }
      this.isCloseAllSwipe = false;
    }
  }

  // 当在全部页签删除录音时，需要对录音进行分类，分类型进行删除
  private async removeRecordDataInAllRecords(recordDataArray: RecordData[]): Promise<void> {
    const callRecordArray = recordDataArray.filter(item => item.type === RecordType.CALL_RECORD);
    const callRecordList = callRecordArray.map(item => item._data);
    if (callRecordList.length > 0) {
      await this.batchUpdateCallRecord(callRecordList, callRecordArray);
    }

    const normalRecordArray = recordDataArray.filter(item => item.type === RecordType.AUDIO_RECORD);
    const normalRecordList = normalRecordArray.map(item => item._data);
    if (normalRecordList.length > 0) {
      let moveRecycleBinCount = await DatabaseManager.removeNormalRecordData(normalRecordList);
      let insertRecentDeleteCount =
        await DatabaseManager.insertToRecentDeleteTable(normalRecordArray, RecordType.AUDIO_RECORD);
      if (moveRecycleBinCount !== insertRecentDeleteCount) {
        // 删除的录音记录和插入回收站的记录条数不一致，记录到preference中
        LogUtil.info(TAG + ' check normal record consistency error when move normal record to recycle bin');
        getContext().eventHub.emit('checkConsistency', 'recordings');
      }
    }
  }

  private async removeRecordData(recordDataArray: RecordData[], sideBarType: number): Promise<void> {
    LogUtil.info(TAG + ' removeRecordData length: ' + recordDataArray.length + ' sideBarType: ' + sideBarType);
    switch (sideBarType) {
      case SideBarMode.ALL_RECORDINGS:
        await this.removeRecordDataInAllRecords(recordDataArray);
        break;
      case SideBarMode.CALL_RECORDINGS:
        let callRecordList = recordDataArray.filter(
          item => (item._data.startsWith(CommonConstants.CALL_RECORD_URI_PREFIX)) ||
            item._data.startsWith(CommonConstants.CALL_RECORD_URI_PREFIX_GROUP) ||
            item._data.startsWith(PathUtil.CALLRECORD_FILEPATH))
          .map(item => item._data);
        await this.batchUpdateCallRecord(callRecordList, recordDataArray);
        break;
      case SideBarMode.AUDIO_RECORDINGS:
        let normalRecordList = recordDataArray.filter(
          item => !(item._data.startsWith(CommonConstants.CALL_RECORD_URI_PREFIX) ||
            item._data.startsWith(CommonConstants.CALL_RECORD_URI_PREFIX_GROUP)))
          .map(item => item._data);
        let moveRecycleBinCount = await DatabaseManager.removeNormalRecordData(normalRecordList);
        let insertRecentDeleteCount =
          await DatabaseManager.insertToRecentDeleteTable(recordDataArray, RecordType.AUDIO_RECORD);
        if (moveRecycleBinCount !== insertRecentDeleteCount) {
          // 删除的录音记录和插入回收站的记录条数不一致，记录到preference中
          LogUtil.info(TAG + ' check normal record consistency error when move normal record to recycle bin');
          getContext().eventHub.emit('checkConsistency', 'recordings');
        }
        break;
      case SideBarMode.RECENT_DELETE_RECORDINGS:
        await this.removeRecentDelete(recordDataArray);
        break;
      default:
    }
  }

  /**
   *   刪除最近刪除列表里面的录音记录
   *   刪除的思路为：
   *   1、删除回收站数据库中的记录
   *   2、删除通话录音数据库中的记录 在要删除的通话录音数量多（> CALL_RECORD_UPDATA_MAX即1000）时 分批删除避免卡死
   *   3、删除标记表里的记录
   *   4、删除转文本表里的记录
   *   5、删除音频文件和转文本的json文件
   */
  private async removeRecentDelete(recordDataArray: RecordData[]): Promise<void> {
    let recentDeleteCallRecord = recordDataArray.filter(item => item.phoneNumber).map(item => item._data);
    let normalRecordData = recordDataArray.filter(item => !item.phoneNumber);
    let allRecordPath = recordDataArray.map(item => item._data);
    let recentDeleteNormalRecord = normalRecordData.map(item => item._data);
    let recentDeleteRecordList = recentDeleteCallRecord.concat(recentDeleteNormalRecord);
    // 删除回收站中的记录
    await DatabaseManager.removeRecentDeleteRecordData(allRecordPath);
    if (recentDeleteCallRecord.length > CommonConstants.CALL_RECORD_UPDATA_MAX) {
      let recentDeleteCallRecordListSliceArray: string[][] = [];
      for (let i = 0; i < recentDeleteCallRecord.length; i += CommonConstants.CALL_RECORD_UPDATA_MAX) {
        if (i + CommonConstants.CALL_RECORD_UPDATA_MAX > recentDeleteCallRecord.length) {
          recentDeleteCallRecordListSliceArray.push(recentDeleteCallRecord.slice(i, recentDeleteCallRecord.length));
        } else {
          recentDeleteCallRecordListSliceArray.push(recentDeleteCallRecord.slice(i,
            i + CommonConstants.CALL_RECORD_UPDATA_MAX));
        }
      }
      for (let recentDeleteCallRecordList of recentDeleteCallRecordListSliceArray) {
        await DatabaseManager.removeCallRecordData(recentDeleteCallRecordList);
      }
    } else {
      await DatabaseManager.removeCallRecordData(recentDeleteCallRecord);
    }

    // 删除标记
    await DatabaseManager.batchRemoveTag(recentDeleteRecordList);

    // 删除转文本表中的记录,删除之前查询对应的文件路径
    const rows = await DatabaseManager.queryTransferDataWithRecords(allRecordPath);
    let transferFilePath: string[] = rows.map(item => item.jsonPath);
    await DatabaseManager.removeTransferData(allRecordPath);

    // 删除音频文件和转文本生成的json文件
    DatabaseManager.deleteAudioFile(allRecordPath.concat(transferFilePath), () => {
      LogUtil.info(TAG + ' deleteAudioFile task done.');
      getContext().eventHub.emit('closeProcessDetailDialog', 'deleteAudioFile');
    });
  }

  private async batchUpdateCallRecord(callRecordList: string[], recordDataArray: RecordData[]): Promise<void> {
    // 大批量数据分块更新
    let moveRecycleBinCount = 0;
    if (callRecordList.length > CommonConstants.CALL_RECORD_UPDATA_MAX) {
      let callRecordListSliceArray: string[][] = [];
      for (let i = 0; i < callRecordList.length; i += CommonConstants.CALL_RECORD_UPDATA_MAX) {
        if (i + CommonConstants.CALL_RECORD_UPDATA_MAX > callRecordList.length) {
          callRecordListSliceArray.push(callRecordList.slice(i, callRecordList.length));
        } else {
          callRecordListSliceArray.push(callRecordList.slice(i, i + CommonConstants.CALL_RECORD_UPDATA_MAX));
        }
      }
      for (let callRecord of callRecordListSliceArray) {
        moveRecycleBinCount += await DatabaseManager.markCallRecordMovedRecycleBin(callRecord);
      }
      let insertRecentDeleteCount =
        await DatabaseManager.insertToRecentDeleteTable(recordDataArray, RecordType.CALL_RECORD);
      if (moveRecycleBinCount !== insertRecentDeleteCount) {
        // 删除的通话录音记录和插入回收站的记录条数不一致，记录到preference中
        LogUtil.info(TAG + ' check call record consistency error when move call record to recycle bin');
        getContext().eventHub.emit('checkConsistency', 'call_recordings');
      }
    } else {
      moveRecycleBinCount = await DatabaseManager.markCallRecordMovedRecycleBin(callRecordList);
      let insertRecentDeleteCount =
        await DatabaseManager.insertToRecentDeleteTable(recordDataArray, RecordType.CALL_RECORD);
      if (moveRecycleBinCount !== insertRecentDeleteCount) {
        // 删除的通话录音记录和插入回收站的记录条数不一致，记录到preference中
        LogUtil.info(TAG + ' check call record consistency error when move call record to recycle bin');
        getContext().eventHub.emit('checkConsistency', 'call_recordings');
      }
    }
  }
}

@CustomDialog
export struct detailProgressDialog {
  detailProgressController: CustomDialogController;
  @Consume deletingOrRecoveringDialog: string;

  build() {
    Column() {
      Column() {
        Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
          Text(this.deletingOrRecoveringDialog === CommonConstants.DIALOG_DELETING ? $r('app.string.deleting') :
            $r('app.string.recovering'))
          Column() {
            LoadingProgress()
              .color(Color.Grey)
          }.margin({ top: 10, bottom: 10 })
        }
      }
    }.height(100).padding(15)
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
  }
}


//定义controller对象
export class AudioRecordListController {
  public deleteDialogController: CustomDialogController = new CustomDialogController({
    builder: CustomContentDialog({})
  })
}
