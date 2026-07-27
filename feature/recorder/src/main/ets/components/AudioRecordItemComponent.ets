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
  CommonConstants,
  DeviceUtil,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  PathUtil,
  ShareModalParams,
  ShareUtil,
  SwipeIconConfigurations,
  Util
} from '@ohos/common';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { RecordData } from '@ohos/common/src/main/ets/model/RecordData';
import { ConfigData } from '@ohos/common/src/main/ets/utils/ConfigData';
import fileUri from '@ohos.file.fileuri';
import common from '@ohos.app.ability.common';
import { ProgressBarComponent } from './ProgressBarComponent';
import { PlayManager } from '../controller/PlayManager';
import Curves from '@ohos.curves';
import { AttributeUpdater, Configuration, display, ImageModifier, LengthMetrics, router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import UDC from '@ohos.data.unifiedDataChannel';
import ContactsManagerUtil from '@ohos/common/src/main/ets/utils/ContactsManagerUtil';
import { SideBarMode } from './SideBarComponent';
import { accessibility } from '@kit.AccessibilityKit';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import Settings from '@ohos.settings';
import { SymbolGlyphModifier } from '@kit.ArkUI';

const TAG = 'SoundRecorder_AudioRecordItemComponent';
const MAX_HEAD_ANGLE: number = 17;
const BODY_HEAD_CRITICAL_ANGLE: number = 12;
const MAX_BODY_ANGLE: number = 10;
const DELETE_SWIPE_HEAD_WIDTH_WITH_SHARE_BUTTON: number = 16 + 40 + 8 + 40;
const DELETE_SWIPE_BODY_WIDTH: number = 123;
const ANGLE_RADIO: number = 10;
const DEFAULT_ITEM_OPACITY: number = 1;
const DRAGGING_ITEM_OPACITY: number = 0.4;
const DRAGGING_ITEM_LIMIT: number = 16;

function getContentMaxScale() {
  return DeviceUtil.isTabletOrTripleGStatus() ? CommonConstants.TEXT_SIZE_EXTRA_LARGE :
    CommonConstants.TEXT_SIZE_HUGE_LEVEL3;
}

@Extend(Text)
function recordNameStyle() {
  .fontColor($r('sys.color.ohos_id_color_text_primary'))
  .maxFontSize($r('sys.float.ohos_id_text_size_body1'))
  .minFontSize('14fp')
  .constraintSize({
    minHeight: $r('app.float.wh_value_21'), // 适老化，将原来的固定高度改为最小高度
  })
  .maxLines(1)
  .fontSize(16)
  .lineHeight(21)
  .fontWeight(FontWeight.Medium)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
  .wordBreak(WordBreak.BREAK_ALL)
  .fontFeature('\"ss01\" on')
  .id('indexPageRecordNameText')
  .maxFontScale(getContentMaxScale())
}

@Extend(Text)
function recordTimeNormalFoldStyle() {
  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
  .maxLines(1)
  .fontSize('12fp')
  .fontWeight(FontWeight.Regular)
  .margin({
    top: $r('app.float.distance_2')
  })
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .fontFeature('\"ss01\" on')
  .id('indexPageRecordDataText')
}

@Extend(Text)
function recordTimeStyle() {
  .fontColor($r('sys.color.ohos_id_color_text_secondary'))
  .maxFontSize($r('sys.float.ohos_id_text_size_body2'))
  .minFontSize('12fp')
  .maxLines(1)
  .fontSize(14)
  .lineHeight(19)
  .fontWeight(FontWeight.Regular)
  .constraintSize({
    minHeight: '19vp',
  })
  .textOverflow({ overflow: TextOverflow.Ellipsis })
  .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
  .fontFeature('\"ss01\" on')
  .id('indexPageRecordDataText')
  .maxFontScale(getContentMaxScale())
}

@Extend(Text)
function recordDurationStyle() {
  .fontColor($r('sys.color.ohos_id_color_text_primary'))
  .maxLines(1)
  .fontSize(16)
  .constraintSize({
    minHeight: '21vp',
  })
  .lineHeight(21)
  .fontWeight(FontWeight.Medium)
  .fontFeature('\"ss01\" on')
  .id('indexPageRecordDurationText')
  .maxFontScale(getContentMaxScale())
}

// 状态变量方式更新当前listItem的opacity
class RecordListItemModifier extends AttributeUpdater<ColumnAttribute> {
  public isDragging: boolean = false;
  public isSelected: boolean = false;

  /* instrument ignore next */
  applyNormalAttribute(instance: ColumnAttribute): void {
    let isEditMode: boolean | undefined = AppStorage.get('isEditMode');
    let isSearchMode: boolean | undefined = AppStorage.get('isSearchMode');
    let isRecordListDragging: boolean | undefined = AppStorage.get('isRecordListDragging');
    let opacity = DEFAULT_ITEM_OPACITY;

    if (isEditMode && isRecordListDragging) {
      if (this.isDragging) {
        opacity = DRAGGING_ITEM_OPACITY;
      } else {
        opacity = this.handleNoDrag();
      }
    } else if (isSearchMode && this.isDragging) {
      opacity = DRAGGING_ITEM_OPACITY;
    } else if (this.isDragging) {
      opacity = DRAGGING_ITEM_OPACITY;
    }

    instance.opacity(opacity);
  }

  /* instrument ignore next */
  private handleNoDrag(): number {
    let draggingItemSelectStatus: boolean | undefined = AppStorage.get('draggingItemSelectStatus');
    let opacity = DEFAULT_ITEM_OPACITY;
    if (draggingItemSelectStatus) {
      if (this.isSelected) {
        opacity = DRAGGING_ITEM_OPACITY;
      } else {
        opacity = DEFAULT_ITEM_OPACITY;
      }
    } else {
      opacity = DEFAULT_ITEM_OPACITY;
    }
    return opacity;
  }
}

interface ReusableParams {
  showProgressBarComponent?: boolean;
  showPauseSymbol?: boolean;
}

@Component
@Reusable
export struct AudioRecordItemComponent {
  @State recordListItemModifier: RecordListItemModifier = new RecordListItemModifier();
  @State dragImageModifier: ImageAttribute = new ImageModifier()
    .borderRadius($r('app.float.wh_value_14'))
    .shadow(ShadowStyle.OUTER_DEFAULT_LG);
  @State listItemWidth: Length = 0;
  @State listItemHeight: Length = 0;
  // use to solve problem av player state error when frequency jump record play page.
  private isRouteRecordPlayPage: boolean = false;
  private isRoutePlayPageFromProgressBar: boolean = false;
  private lastItem: boolean = false;
  private isSearchItem: boolean = false;
  private needFocus: boolean = false;
  private isTouchProgressBar: boolean = false;
  //高亮匹配字符
  private needHighlight: boolean = false;
  @State highlightColor: string = '#FB654E';
  // take effect inside AudioRecordItemComponent
  @State @Watch('onShowProgressChange') isShowProgressBar: boolean = false;
  @State showProgressBarComponent: boolean = false;
  // swipe animate attribute
  @State headAngle: number = 0;
  @State bodyAngle: number = 0;
  @State swipeScale: number = 1;
  @State shareButtonVisibility: Visibility = Visibility.Visible;
  @State renameButtonVisibility: Visibility = Visibility.Visible;
  // take effect inside AudioRecordItemComponent, assigned from parent
  @Prop index: number;
  @Link @Watch('onPlaybackStateChange') state: string;
  @State isPermitAccessMediaLibrary: boolean = false;
  @Link currentTimePlay: number;
  @Prop isCallRecord: boolean;
  @State showPauseSymbol: boolean = false;
  private btnStateTimerId: number = 0;
  @StorageLink('recordPlayMarkListHeightOpen') recordPlayMarkListHeightOpen: boolean = false;
  // changes in parent effect child, and vice versa
  @Consume @Watch('onSelectedRecordList') selectedRecordList: RecordData[];
  // same with @Link, but the property of item changes will also take effect in UI
  @ObjectLink item: RecordData;
  // same with @Link, but take effect between grand parent and children.
  @Consume @Watch('onShowProgressChange') focusRecord: RecordData;
  @Consume pathStack: NavPathStack;
  @Consume isClickDeleteInSwipeMenu: boolean;
  @Consume isCloseAllSwipe: boolean;
  @Consume sideFolderNameFlag: number;
  @Consume @Watch('onSearchModeChange') isSearchMode: boolean;
  @Consume isSort: boolean;
  @Consume isRecordItemFloatMenuShown: boolean;
  @Consume isExitPageToQuickRecord: boolean;
  @Consume isFromLockScreenRecord: boolean;
  // same with @Link, but @StorageLink is global, all Linked variables shared the same value.
  @StorageLink('isEditMode') @Watch('isEditModeChange') isEditMode: boolean = false;
  @StorageLink('isNormalMode') isNormalMode: boolean = true;
  @StorageLink('enterEdit') enterEdit: boolean = false;
  @StorageProp('navigationMode') @Watch('onNavModeChange') navMode: number = 0;
  @StorageLink('backFromRecordingPage') backFromRecordingPage: boolean = false;
  @StorageLink('RecordBindSheet') isShowRecord: boolean = false;
  @StorageLink('RecordPlayBindSheet') isShowRecordPlay: boolean = false;
  @StorageLink('screenWidthSplitState') screenWidthSplitState: string = CommonConstants.SCREEN_WIDTH_FULL;
  @StorageLink('RecordTranslateState') recordTransState: boolean = false;
  // Dark mode
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @State needInitElapsedTime: boolean = false;
  @StorageLink('isExistRecordPlayPage') isExistRecordPlayPage: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = CommonConstants.TEXT_SIZE_NORMAL;
  @StorageProp(CommonConstants.CURRENT_SPEED) currentSpeed: number = CommonConstants.SPEED_FORWARD_1_00_X;
  @State shareOpacity: number = 1;
  @State renameOpacity: number = 1;
  // Menu
  private contextThis: Context = getContext(this);
  @State @Watch('onFloatMenuShownChange') isFloatMenuShown: boolean = false;
  @State menuAtTheBottom: boolean = true;
  @StorageLink('appContentHeight') appContentHeight: number = 0;
  private recordItemWidth: number | string = '100%';
  private recordItemHeight: number = 60;
  private recordItemGlobalY: number = 0;
  private menuItemHeight: number = 50;
  private menuHeight: number = 295; // 悬浮菜单总高度，不包含预览卡片
  // Preview Transition Effect
  private previewEffect: TransitionEffect = TransitionEffect.asymmetric(
    TransitionEffect.opacity(1).animation({ duration: 250, curve: Curve.Smooth }),
    TransitionEffect.opacity(0).animation({ duration: 250, curve: Curves.springMotion(0.314, 0.95) })
  )
  @StorageLink('isRecordListDragging') @Watch('onListDraggingStatusChanged') isRecordListDragging: boolean = false;
  private triggerLongClickTime: number = 0;
  @StorageProp('callAPPId') @Watch('onCallAPPIdChanged') callAppId: number = -1;
  @State dragEnable: boolean = true;
  @Consume defaultDP: number;
  @Consume densityPixels: number;
  @Link isSearchCloseSwipe: boolean;
  @Consume isShowSideBar: boolean;
  @State isHover: boolean = false;
  @Consume playTimeBeforeRenameIndex: number;
  @StorageProp('navWidth') navWidth: number = 0;
  @State accessibilityTip: string = '';
  @Consume isExitTopAction: boolean;
  @StorageProp('isCeliaEnabled') isCeliaEnabled: boolean = false;
  @State isMultiSelect: boolean = false;
  @StorageProp('foldDisplayMode') foldDisplayMode: number = 0;
  @StorageProp('isSmallFoldVer') isSmallFoldVer: boolean = false;
  @Consume detailRecord: RecordData;
  @State checkBoxSelectColor: string = '#FB654E';
  @Consume isSwipeOpen: boolean;
  @StorageLink('shortCutRecordList') @Watch('onShortCutRecordList') isShortCutRecordList: boolean = false;

  private onFloatMenuShownChange() {
    this.isRecordItemFloatMenuShown = this.isFloatMenuShown;
    AppStorage.setOrCreate('isMaskShow', this.isFloatMenuShown);
  }

  private onSearchModeChange() {
    AppStorage.setOrCreate('isSearchMode', this.isSearchMode);
    this.updateAccessibilityTip();
  }

  /* instrument ignore next */
  private callRecordPlay(): void {
    setTimeout(async () => {
      LogUtil.info(`${TAG} callAPPId: ${this.callAppId}, item.id: ${this.item.id}`);
      if (this.item.id !== this.callAppId) {
        return;
      }
      LogUtil.error(`${TAG} click play in CallRecord App, clicked item: ${AnonymousUtil.anonymous(this.item.title)},
                   callAppId: ${this.callAppId}, item.id: ${this.item.id}`);
      let dbRecord = await DatabaseManager.getCallRecordDataFromDb('id', String(this.callAppId));
      if (dbRecord.length > 0 && this.item._data !== dbRecord[0]._data) {
        this.item = dbRecord[0];
      }
      this.playOrPause(this.item);
      AppStorage.setOrCreate('callAPPId', -1);
    }, 500);
  }

  // 监听整个List是否有拖拽事件发生，用于主动更新当前ListItem的opacity
  /* instrument ignore next */
  private onListDraggingStatusChanged(): void {
    if (this.isEditMode) {
      let draggingItemSelectStatus: boolean | undefined = AppStorage.get('draggingItemSelectStatus');
      if (this.isRecordListDragging) {
        if (this.item.flagSelect && draggingItemSelectStatus) {
          this.recordListItemModifier.attribute?.opacity(DRAGGING_ITEM_OPACITY);
        } else {
          this.recordListItemModifier.attribute?.opacity(DEFAULT_ITEM_OPACITY);
        }
      } else {
        this.recordListItemModifier.attribute?.opacity(DEFAULT_ITEM_OPACITY);
      }
    }
  }

  // 监听通话录音跳转过来的item是否发生改变，发生改变的话，点击该item的播放按钮
  /* instrument ignore next */
  private onCallAPPIdChanged(): void {
    if (this.callAppId > 0) {
      this.callRecordPlay();
    }
  }

  private isEditModeChange() {
    if (this.isEditMode) {
      this.onSelectFlagChange();
      this.isShowProgressBar = false;
    }
    this.isMultiSelect = this.isEditMode;
    this.updateAccessibilityTip()
  }

  private onSelectedRecordList() {
    if (this.isEditMode && this.selectedRecordList.length >= DRAGGING_ITEM_LIMIT) {
      this.isMultiSelect = false;
    } else {
      this.isMultiSelect = true;
    }
  }

  private computeShowProgressBar(): boolean {
    return this.isFocusRecord(this.item) && this.isShowProgressBar && this.navMode !== NavigationMode.Split;
  }

  private onShowProgressChange(): void {
    animateTo({
      duration: 250,
      curve: Curves.cubicBezierCurve(0.2, 0, 0.2, 1)
    }, () => {
      if (this.isFocusRecord(this.item) && this.navMode === NavigationMode.Stack &&
        (this.state === 'playing' || this.state === 'paused') && !this.isRoutePlayPageFromProgressBar) {
        this.isShowProgressBar = true;
      }
      LogUtil.info(`${TAG} onShowProgressChange isFocusRecord: ${this.isFocusRecord(this.item)},
        isShowProgressBar: ${this.isShowProgressBar}, Current Playback State: ${this.state}`);
      this.showProgressBarComponent = this.computeShowProgressBar();
      this.updateBtnSymbol();
    });
  }

  private isFocusRecord(item: RecordData): boolean {
    return this.focusRecord?._data === item?._data;
  }

  /* instrument ignore next */
  private onNavModeChange(): void {
    LogUtil.info(TAG + ' onNavModeChange Mode : ' + this.navMode)
    this.isFloatMenuShown = false;
    if (this.navMode === NavigationMode.Split) {
      LogUtil.info(TAG + ' Split mode do not show progress bar.');
      this.isShowProgressBar = false;
    }
    if (this.navMode === NavigationMode.Stack) {
      if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
        this.onShowProgressChange();
      }
    }
    this.updateAccessibilityTip();
  }

  /**
   * 更新播放、暂停按钮的显示
   */
  updateBtnSymbol() {
    let newSymbolState = this.isFocusRecord(this.item) && this.state === 'playing';
    if (this.btnStateTimerId !== 0) {
      clearTimeout(this.btnStateTimerId);
      this.btnStateTimerId = 0;
    }
    // 添加一定的延迟，防止频繁更新导致抖动
    this.btnStateTimerId = setTimeout(() => this.showPauseSymbol = newSymbolState, CommonConstants.TIME_60);
  }

  /* instrument ignore next */
  private onPlaybackStateChange(): void {
    if (!this.isFocusRecord(this.item)) {
      this.isShowProgressBar = false;
      return;
    }
    LogUtil.info(`${TAG} onPlaybackStateChange state: ${this.state}, currentSpeed: ${this.currentSpeed}`);

    if (this.isEditMode) {
      this.isShowProgressBar = false;
    }

    if (this.state === 'completed') {
      LogUtil.info(TAG + ' not play or play completed, hide progress bar.');
      this.isShowProgressBar = false;
      // 解决录音文件真实时长this.item.duration和录制时统计的时长this.currentTimePlay之间有误差的问题，这里在做一下进度条动画，让进度条走到最后
      if (this.currentTimePlay < this.item.duration) {
        animateTo({ curve: Curve.Linear, duration: 100 }, () => {
          this.currentTimePlay = this.item.duration;
        })
      }
    }

    // 播控中心使用
    if (this.state === 'playing') {
      this.onPlaybackStatePlaying();
    }

    if (this.state === 'prepared') {
      LogUtil.info(TAG + ' av player is ready to play, let begin.');
      if (this.isRouteRecordPlayPage) {
        if (!DeviceUtil.isPhoneNotFold() && this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_FULL &&
          !this.isSmallFoldVer) {
          this.pathStack.pushPathByName('recordPlay', new RecordData());
        }
        this.recordTransState = this.item.tranState === 1 || this.item.tranState === 2;
        this.isShowRecordPlay = true;
        this.isRouteRecordPlayPage = false;
        this.isRoutePlayPageFromProgressBar = false;
      }
      if (this.focusRecord.isNeedPlay) {
        PlayManager.getInstance().play().then((value) => {
          if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_PLAY);
          } else {
            HiSysEventUtil.eventDotting(HiSysEventName.PLAY_SINGLE_AUDIO, { VALUE: value });
          }
        })
      } else {
        LogUtil.info(TAG + ' av player prepared.');
      }
    }
    this.updateBtnSymbol();
  }

  /* instrument ignore next */
  private onPlaybackStatePlaying() {
    if (this.isExistRecordPlayPage) {
      // 从播放详情页退出并且是playing状态的前提下，退到主界面上由于avplayer的状态切换需要时间，此时可能会导致回到主界面先显示一下进度条之后又立即消失
      LogUtil.info(TAG + ' isExistRecordPlayPage value is true');
      if (this.navMode === NavigationMode.Stack) {
        this.isShowProgressBar = false;
      }
      this.isExistRecordPlayPage = false;
    }
    if (this.navMode === NavigationMode.Stack && this.pathStack.size() === 0 && !DeviceUtil.isPhoneNotFold() &&
      !this.isSmallFoldVer) {
      LogUtil.info(TAG + ' playing, show progress bar.');
      if (!this.isShowProgressBar) {
        this.isShowProgressBar = true;
      }
    }
  }

  // 左滑删除恢复且不能跳转
  /* instrument ignore next */
  private checkSwipeState(item: RecordData): boolean {
    if (item.isSwipeExpanded) {
      LogUtil.info(TAG + ' current item is swipe expanded, ignore click and close all Swipe.');
      item.isSwipeExpanded = false;
      this.isCloseAllSwipe = true;
      this.isSearchCloseSwipe = true;
      return false;
    }
    return true;
  }

  /* instrument ignore next */
  private playOrPause(item: RecordData): void {
    AppStorage.setOrCreate(CommonConstants.CURRENT_FOCUS_RECORD, this.item);
    const player = PlayManager.getInstance();
    const playbackState = player.getAVPlayerState();
    LogUtil.info(TAG + ' click play or pause button, focusRecord ' + AnonymousUtil.anonymous(item.title) +
      ' player state: ' + playbackState + this.state);
    if (this.isFocusRecord(item) && this.state !== 'idle') {
      this.state === 'completed' ? this.currentTimePlay = 0 : '';
      if (this.state === 'playing') {
        player.pause().then((value) => {
          if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_PAUSE);
          } else {
            HiSysEventUtil.eventDotting(HiSysEventName.PAUSE_SINGLE_AUDIO, { VALUE: value });
          }
        })
        AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.play'), ''));
      } else if (this.state === 'prepared' || this.state === 'paused' || this.state === 'completed') {
        player.play().then((value) => {
          if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_PLAY);
          } else {
            HiSysEventUtil.eventDotting(HiSysEventName.PLAY_SINGLE_AUDIO, { VALUE: value });
          }
        })
        AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.pause'), ''));
      } else {
        LogUtil.error(`${TAG} current player state is invalid, state: ${this.state}`);
      }
      LogUtil.info(`${TAG} click play or pause button, focusRecord ${AnonymousUtil.anonymous(item.title)} player state: ${playbackState}`);
    } else {
      this.state = 'idle';
      this.item.isNeedPlay = true;
      player.setDataSource('playOrPause', item);
      this.currentTimePlay = 0;
      AccessibilityUtil.sendAnnounceAccessibilityEvent(Util.getFormatStringSync($r('app.string.pause'), ''));
    }
    this.focusRecord = item;
    if (this.navMode === NavigationMode.Stack && this.pathStack.size() === 0) {
      LogUtil.info(TAG + ' click playOrPause button, show progress bar.');
      this.state = 'idle';
      if (!this.isShowProgressBar) {
        this.isShowProgressBar = true
      }
    }
  }

  /* instrument ignore next */
  private async routeRecordPlayPage(item: RecordData, needPlay: boolean) {
    if (this.isFloatMenuShown) {
      LogUtil.warn(TAG + ' When the floating menu is displayed, the details page should not be displayed.');
      return;
    }
    const player = PlayManager.getInstance();
    LogUtil.info(TAG + ' click list item to route RecordPlayPage, state: ' + player.getAVPlayerState());
    item.jumpRecordPlayPageTime = new Date().getTime();
    if (this.navMode === NavigationMode.Split) {
      this.isShowProgressBar = false;
      if (this.isFocusRecord(item)) {
        LogUtil.info(TAG + ' click the same record, do nothing.');
        // 在双屏模式下重新点击了正播放中的录音文件，就没必要重复更新了。
        return;
      } else {
        LogUtil.info(TAG + ' nav mode is split, click nav bar to switch record.');
        await player.pause();
        this.currentTimePlay = 0;
        item.isNeedPlay = needPlay;
        player.setDataSourceDebounce({ tag: 'routeRecordPlayPage_Split', recordData: item });
      }
    } else {
      if (this.isFocusRecord(item) && (player.getAVPlayerState() === 'playing' ||
        player.getAVPlayerState() === 'paused')) {
        if (this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) {
          LogUtil.info(TAG + ' current record is already playing or paused, route record play page directly.');
          this.recordPlayMarkListHeightOpen = false;
          this.isRoutePlayPageFromProgressBar = true;
          this.isShowProgressBar = false;
          this.isShowRecordPlay = true;
          if (!DeviceUtil.isPhoneNotFold() && this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_FULL &&
            !this.isSmallFoldVer) {
            this.pathStack.pushPathByName('recordPlay', item);
          }
        }
      } else {
        LogUtil.info(TAG + ' set data source for clicked record, and prepare to route.');
        this.isShowProgressBar = false;
        item.isNeedPlay = needPlay;
        this.isRouteRecordPlayPage = true;
        this.isRoutePlayPageFromProgressBar = true;
        // 避免长时录音点击播放按钮后快速进入播放详情页导致重复setDataSource引起avplayer状态混乱
        if (player.getAVPlayerState() !== 'initialized') {
          player.setDataSource('routeRecordPlayPage_Stack', item);
        }
        // 最近删除界面不跳转播放详情页
        this.isRouteRecordPlayPage = this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS;
      }
      this.isExistRecordPlayPage = false;
    }
    this.focusRecord = item;
  }

  /* instrument ignore next */
  private onSwipeAction(): void {
    LogUtil.info(TAG + ' long swipe to delete.');
    let idInfo = ContactsManagerUtil.getInstance().addCallRecordPrefix(this.item);
    HiSysEventUtil.eventDotting(HiSysEventName.LONG_SWIPE_DELETE, { FILEID: idInfo });
    this.selectedRecordList = [];
    let item = this.item;
    this.selectedRecordList.push(item);
    getContext(this).eventHub.emit('openDeleteDialog', 'longSwipeDelete');
  }

  /* instrument ignore next */
  async aboutToAppear() {
    LogUtil.info(TAG + ' aboutToAppear this.index: ' + this.index);
    getContext().eventHub.on('playRecord', (item: RecordData) => {
      if (this.item._data === item._data) {
        LogUtil.info(TAG + 'update playRecord');
        this.routeRecordPlayPage(this.item, false);
      }
    })
    if (this.needFocus && this.isSearchItem) {
      this.routeRecordPlayPage(this.item, false);
    }
    this.updateAccessibilityTip();
    if (this.item.index < 0) {
      this.item.index = this.index;
    }
    this.showProgressBarComponent = false;
    let playingItem = AppStorage.get(CommonConstants.CURRENT_FOCUS_RECORD) as RecordData;
    if (playingItem !== undefined && playingItem._data === this.item._data && this.state === 'playing') {
      LogUtil.info(TAG + ' aboutToAppear:Resume Playing');
      setTimeout(() => {
        this.focusRecord = this.item;
        if (DeviceUtil.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED ||
          this.navMode === NavigationMode.Stack) {
          this.isShowProgressBar = true;
        } else {
          this.isShowProgressBar = !this.isSort;
        }
        AppStorage.setOrCreate(CommonConstants.CURRENT_FOCUS_RECORD, undefined);
        this.isSort = false;
      }, 80)
    }
    this.callRecordPlay();
    if (this.isFocusRecord(this.item) && this.navMode === NavigationMode.Stack &&
      (this.state === 'playing' || this.state === 'paused')) {
      LogUtil.info(TAG + ' init ShowProgressBar.');
      this.isShowProgressBar = true;
    }
  }

  aboutToDisappear(): void {
    LogUtil.info(TAG + ' aboutToDisappear.');
    getContext().eventHub.off('playRecord');
  }

  aboutToReuse(params: ReusableParams): void {
    this.showProgressBarComponent = params.showProgressBarComponent as boolean;
    this.showPauseSymbol = params.showPauseSymbol as boolean;
  }

  /* instrument ignore next */
  private shareRecord(source: string): void {
    const anchor = this.getUIContext().getComponentUtils().getRectangleById(`list${this.item.index}`);
    const shareModalParams: ShareModalParams = {
      context: getContext(this) as common.UIAbilityContext,
      srcData: [this.item],
      eventName: source === 'swipeShare' ? HiSysEventName.SWIPE_SHARE : HiSysEventName.SHARE_FLOAT_RECORD_LIST
    };
    ShareUtil.showModal(shareModalParams);
    this.isCloseAllSwipe = true;
    this.isSearchCloseSwipe = true;
  }

  /**
   * 获取录音选中后的颜色
   * @returns
   */
  /* instrument ignore next */
  private getSelectedColor(): string | Resource {
    return $r('sys.color.ohos_id_color_hover');
  }

  /**
   * 长按录音时显示悬浮菜单
   */
  /* instrument ignore next */
  private onLongClick(): void {
    // 尝试暂停播放 (双屏态 且 选中的录音是当前录音，不暂停播放)
    if (this.navMode !== NavigationMode.Split) {
      PlayManager.getInstance().pause();
    }
    if (this.showProgressBarComponent) {
      this.isShowProgressBar = false;
      // 隐藏进度条
      animateTo({ duration: CommonConstants.TIME_300, curve: Curves.cubicBezierCurve(0.2, 0, 0.2, 1) }, () => {
        this.showProgressBarComponent = false;
      });
    }
    setTimeout(() => {
      this.calculateMenuPos();
      this.isFloatMenuShown = true;
    }, 0);
  }

  /**
   * 计算悬浮菜单的位置（顶部 or 底部）
   */
  /* instrument ignore next */
  private calculateMenuPos(): void {
    let menuHeight: number = this.isCallRecord ? (this.menuHeight - this.menuItemHeight) : this.menuHeight;
    let expectMinHeight: number = this.recordItemGlobalY + this.recordItemHeight + menuHeight;
    if (this.appContentHeight >= expectMinHeight) {
      this.menuAtTheBottom = true;
    } else {
      let recordItemCenterY: number = this.recordItemGlobalY + this.recordItemHeight / 2;
      if (recordItemCenterY < this.appContentHeight / 2) {
        this.menuAtTheBottom = true;
      } else {
        this.menuAtTheBottom = false;
      }
    }
    LogUtil.info(TAG + `: calculateMenuPos appHeight=${this.appContentHeight}` +
      ` globalY=${this.recordItemGlobalY} height=${this.recordItemHeight}`);
  }

  /**
   * 进入编辑（全选）模式
   */
  private editMode(): void {
    this.backFromRecordingPage = false;
    if (!this.isEditMode && !this.item?.isSwipeExpanded) {
      this.item.flagSelect = true;
      this.selectedRecordList = [];
      let item = this.item;
      this.selectedRecordList.push(item);
      this.isNormalMode = false;
      animateTo({ curve: Curve.Friction, duration: 350 }, () => {
        this.isEditMode = true;
        this.isExitPageToQuickRecord = false;
        AppStorage.setAndLink('isEditMode', this.isEditMode);
        const player = PlayManager.getInstance();
        // instrument ignore if
        if (this.navMode === NavigationMode.Split) {
          LogUtil.info(TAG + ' navigation split mode long click, pause play.');
          player.pause();
        } else {
          LogUtil.info(TAG + ' navigation stack mode long click, reset.');
          AppStorage.setOrCreate(CommonConstants.CURRENT_FOCUS_RECORD, this.focusRecord);
          player.reset();
        }
      });
      animateTo({ delay: 150, curve: Curve.Friction, duration: 200 }, () => {
        this.enterEdit = true;
      })
      AppStorage.setOrCreate('hideToolBar', !this.isEditMode);
      LogUtil.info(TAG + ' long click to edit.');
    }
  }

  private getButtonGap(): Margin {
    return {
      left: Configuration.getLocale().dir === 'ltr' ? undefined : 8,
      right: Configuration.getLocale().dir === 'ltr' ? 8 : undefined,
    }
  }

  @Builder
  SymbolPlayAndPauseButton() {
    SymbolGlyph(this.showPauseSymbol ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
      .accessibilityText(this.showPauseSymbol ? $r('app.string.pause') : $r('app.string.play'))
      .rotate({
        x: 0,
        y: 1,
        z: 0,
        angle: Configuration.getLocale().dir === 'rtl' ? 180 : 0
      })
      .direction(Configuration.getLocale().dir === 'rtl' ? Direction.Rtl : Direction.Ltr)
      .draggable(false)
      .width('20vp')
      .height('20vp')
      .fontSize('20vp')
      .fontColor(this.isDarkMode ? new Array($r('sys.color.ohos_id_color_primary')) : new Array('#040000'))
      .symbolEffect(new AppearSymbolEffect(EffectScope.WHOLE), this.isFocusRecord(this.item) ? true : false)
  }

  /* instrument ignore next */
  private recordItemClick() {
    this.isFloatMenuShown = false;
    let delayTime = 0;
    setTimeout(async () => {
      if (this.checkSwipeState(this.item)) {
        this.playOrPause(this.item);
      }
    }, delayTime);
  }

  @Builder
  RecordItemButton(isFloatCard: boolean) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      if (!this.isDarkMode) {
        Row()
          .id('floatPlayBtn')
          .width('40vp')
          .height('40vp')
          .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
          .borderRadius(20)
      }
      this.SymbolPlayAndPauseButton();
    }
    .accessibilityGroup(this.isEditMode ? true : false)
    .accessibilityLevel(this.isEditMode ? 'no-hide-descendants' : 'yes')
    .opacity(isFloatCard ? 1 : this.isEditMode ? 0 : 1)
    .hitTestBehavior(HitTestMode.Block)
    .backgroundColor(!this.isDarkMode ? Color.Transparent : $r('sys.color.ohos_id_color_button_normal'))
    .id('playBtn')
    .width('40vp')
    .height('40vp')
    .margin({
      left: Configuration.getLocale().dir == 'ltr' ? $r('app.float.distance_12') : 0,
      right: Configuration.getLocale().dir == 'rtl' ? $r('app.float.distance_12') : 0
    })
    .onClick(() => {
      this.recordItemClick();
    })
    .width('52vp')
  }

  @Builder
  /* instrument ignore next */
  checkBoxBuilder(isFloatCard: boolean) {
    Checkbox({})
      .select(this.item.flagSelect)
      .width('20vp')
      .height('20vp')
      .selectedColor(this.checkBoxSelectColor)
      .onChange((value: boolean) => {
      })
      .enabled(this.isEditMode)
      .accessibilityGroup(!this.isEditMode ? true : false)
      .accessibilityLevel(!this.isEditMode ? 'no-hide-descendants' : 'yes')
      .visibility((isFloatCard || this.isExitPageToQuickRecord) ? Visibility.None : Visibility.Visible)
      .opacity(this.enterEdit ? 1 : 0)
      .margin({
        left: Configuration.getLocale().dir == 'ltr' ? 16 : 0,
        right: Configuration.getLocale().dir == 'rtl' ? 16 : 0
      })
      .onClick(() => {
        this.item.flagSelect = !this.item.flagSelect;
        this.handleSelectRecord();
      })
      .id(`item${this.index}`)
  }

  showRecordSelectedColor(): boolean {
    return this.isFocusRecord(this.item) && (this.navMode === NavigationMode.Split) && !this.isEditMode;
  }

  private getItemBorderRadius() {
    if (DeviceUtil.isPC()) {
      return this.isFocusRecord(this.item)
        ? $r('app.float.wh_value_12') : $r('app.float.wh_value_16');
    }
    return $r('app.float.wh_value_16');
  }

  @Builder
  DragRecordItem(): void {
    Flex({ direction: FlexDirection.Row, justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
      if (this.fontSizeScale < CommonConstants.TEXT_SIZE_HUGE_LEVEL2 && this.densityPixels <= this.defaultDP) {
        this.RecordListStandardLayout(false);
      } else {
        this.RecordListHugeLayout(true);
      }
    }
    .width(this.recordItemWidth)
    .borderRadius(DeviceUtil.isPC() ? $r('app.float.wh_value_12') : 0)
    .backgroundColor(DeviceUtil.isPC() ? this.getSelectedColor() : Color.Transparent)
    .padding(this.getContentPadding(false))
  }

  @Builder
  /* instrument ignore next */
  SeparateLine() {
    Column() {
    }
    .height('1px')
    .backgroundColor($r('sys.color.ohos_id_color_list_separator'))
    .margin({
      left: 14,
      right: 14
    })
    .width('80%')
  }

  private getFloatItemFontStyle(): Font {
    return {
      size: DeviceUtil.isTabletOrTripleGStatus() && this.fontSizeScale >
        CommonConstants.TEXT_SIZE_EXTRA_LARGE ? 12 : 16,
      weight: FontWeight.Medium
    };
  }

  @Builder
  /* instrument ignore next */
  FloatMenu(): void {
    if (this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) {
      Column() {
        if (!this.isSearchMode) {
          // 多选
          MenuItem({ content: $r('app.string.menu_multiselect') })
            .width('224vp')
            .contentFont(this.getFloatItemFontStyle())
            .id('multi_select')
            .onClick(() => {
              this.isFloatMenuShown = false;
              this.editMode();
            })
            .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
          if (!DeviceUtil.isPC()) {
            Divider().height('1vp').color($r('sys.color.ohos_id_color_list_separator'))
              .margin({ left: 14, right: 14 })
          }
        }
        // 分享
        MenuItem({ content: $r('app.string.voice_share') })
          .width('224vp')
          .contentFont(this.getFloatItemFontStyle())
          .onClick(() => {
            this.isFloatMenuShown = false;
            this.shareRecord('floatShare');
          })
          .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
          .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
        if (!DeviceUtil.isPC()) {
          Divider().height('1vp').color($r('sys.color.ohos_id_color_list_separator'))
            .margin({ left: 14, right: 14 })
        }
        // 重命名
        if (!(this.isSmallFoldVer && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED)) {
          MenuItem({ content: $r('app.string.file_rename') })
            .width('224vp')
            .contentFont(this.getFloatItemFontStyle())
            .id('long_rename')
            .onClick(() => {
              this.isFloatMenuShown = false;
              this.selectedRecordList = [];
              let item = this.item;
              this.selectedRecordList.push(item);
              HiSysEventUtil.eventDotting(HiSysEventName.RENAME_RECORD_LIST);
              this.contextThis.eventHub.emit('renameSelectedRecord');
            })
            .enabled(this.item.tranState !== 1)
            .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
            .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
          if (!DeviceUtil.isPC()) {
            Divider().height('1vp').color($r('sys.color.ohos_id_color_list_separator'))
              .margin({ left: 14, right: 14 })
          }
        }
        // 删除
        MenuItem({ content: $r('app.string.delete') })
          .width('224vp')
          .contentFont(this.getFloatItemFontStyle())
          .id('float_delete')
          .onClick(() => {
            this.isFloatMenuShown = false;
            this.selectedRecordList = [];
            let item = this.item;
            this.selectedRecordList.push(item);
            let idInfo = ContactsManagerUtil.getInstance().addCallRecordPrefix(this.item);
            HiSysEventUtil.eventDotting(HiSysEventName.DELETE_FLOAT_RECORD_LIST, { FILEID: idInfo });
            this.contextThis.eventHub.emit('openDeleteDialog', 'floatDelete');
          })
          .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
          .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
        if (!DeviceUtil.isPC()) {
          Divider().height('1vp').color($r('sys.color.ohos_id_color_list_separator'))
            .margin({ left: 14, right: 14 })
        }
        // 详情
        MenuItem({ content: $r('app.string.voice_retail') })
          .width('224vp')
          .contentFont(this.getFloatItemFontStyle())
          .id('record_detail')
          .onClick(() => {
            this.isFloatMenuShown = false;
            this.selectedRecordList = [];
            let item = this.item;
            this.selectedRecordList.push(item);
            this.detailRecord = this.item;
            this.contextThis.eventHub.emit('showRecordDetail');
          })
          .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
          .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
      }.width(224)
    } else {
      Menu() {
        MenuItem({
          content: $r('app.string.menu_multiselect')
        })
          .padding({ left: 16 })
          .onClick(() => {
            LogUtil.info(TAG + ' click the multi select button');
            this.isFloatMenuShown = false;
            this.editMode();
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_PRESS_SEL);
          })
          .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
        MenuItem({
          content: $r('app.string.recording_recover'),
        })
          .padding({ left: 16 })
          .onClick(() => {
            LogUtil.info(TAG + ' click recording recover button');
            this.isFloatMenuShown = false;
            this.selectedRecordList = [];
            let item = this.item;
            this.selectedRecordList.push(item);
            this.contextThis.eventHub.emit('recoverFromRecentDelete', 'floatMenuRecover');
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_PRESS_RECOVER);
          })
          .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
          .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
        MenuItem({
          content: $r('app.string.recording_delete'),
        })
          .padding({ left: 16 })
          .onClick(() => {
            LogUtil.info(TAG + ' click recording delete button');
            this.isFloatMenuShown = false;
            this.selectedRecordList = [];
            let item = this.item;
            this.selectedRecordList.push(item);
            this.contextThis.eventHub.emit('openDeleteDialog', 'floatRecentDelete');
            HiSysEventUtil.eventDotting(HiSysEventName.DEL_PRESS_DELETE);
          })
          .height(!DeviceUtil.isPC() ? undefined : $r('app.float.wh_value_40'))
          .margin(!DeviceUtil.isPC() ? undefined : { top: $r('app.float.margin_size_2') })
      }
      .menuItemDivider(DeviceUtil.isPC() ? undefined : {
        strokeWidth: LengthMetrics.px(1),
        color: $r('sys.color.comp_divider'),
        startMargin: LengthMetrics.vp(16),
        endMargin: LengthMetrics.vp(16),
      })
      .width(224)
    }
  }

  private getContentPadding(isFloatCard: boolean): Padding {
    if (this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL3) {
      return {
        top: isFloatCard ? $r('app.float.distance_16') : $r('app.float.distance_8'),
        bottom: isFloatCard ? $r('app.float.distance_16') : $r('app.float.distance_8'),
        left: $r('app.float.distance_8'),
        right: $r('app.float.distance_8'),
      };
    } else if (this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL2) {
      return {
        top: isFloatCard ? $r('app.float.distance_16') : $r('app.float.distance_4'),
        bottom: isFloatCard ? $r('app.float.distance_16') : $r('app.float.distance_4'),
        left: $r('app.float.distance_8'),
        right: $r('app.float.distance_8'),
      };
    } else {
      return {
        top: isFloatCard ? $r('app.float.distance_16') :
          (DeviceUtil.isPC() ? $r('app.float.distance_8') : $r('app.float.distance_12')),
        bottom: isFloatCard ? $r('app.float.distance_16') :
          (DeviceUtil.isPC() ? $r('app.float.distance_8') : $r('app.float.distance_12')),
        left: $r('app.float.distance_8'),
        right: $r('app.float.distance_8'),
      };
    }
  }

  private getDurationText(): string {
    let durationBroadcastText: string = Util.getFormatStringSync($r('app.string.total_duration'),
      Util.timeFormat(this.item?.duration || 0));
    return durationBroadcastText.replace(/\s+/g, '');
  }

  /**
   * 剩余天数
   */
  /* instrument ignore next */
  getRestDays(): number {
    const deleteDuration = (Date.now() - this.item.deleteTime) / (24 * 60 * 60 * 1000);
    let restDays = CommonConstants.RECYCLE_DAYS_LIMIT - Math.floor(deleteDuration);
    restDays = restDays <= 0 ? 1 : (restDays > 30 ? 30 : restDays);
    return restDays;
  }

  /* instrument ignore next */
  getDateTimeTitle(): string {
    // 回收站显示剩余天数
    if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS &&
      this.item?.deleteTime > 0) {
      return Util.getDateFormat(this.item.date || 0) + ' ' + this.item.remainDaysTip;
    }
    return Util.getDateAndTimeFormat(this.item?.date || 0)
  }

  /* instrument ignore next */
  getDateTimeHugeTitle(isSubTitle: boolean): string {
    if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS && this.item?.deleteTime > 0) {
      return isSubTitle ? this.item.remainDaysTip : Util.getDateFormat(this.item.date || 0);
    }
    return Util.getDateAndTimeFormat(this.item?.date || 0)
  }

  @Builder
  highlightName() {
    Flex({ justifyContent: FlexAlign.Start }) {
      if (this.item.matchType === CommonConstants.PHONETIC_MATCH) {
        if (this.item.matchStart === 0) {
          Text(this.item.name.substring(0, this.item.matchEnd + 1))
            .recordNameStyle()
            .fontColor(this.highlightColor)
        } else {
          Text(this.item.name.substring(0, this.item.matchStart))
            .recordNameStyle()
          Text(this.item.name.substring(this.item.matchStart, this.item.matchEnd + 1))
            .recordNameStyle()
            .fontColor(this.highlightColor)
        }
        if (this.item.matchEnd + 1 !== this.item.name.length) {
          Text(this.item.name.substring(this.item.matchEnd + 1))
            .recordNameStyle()
        }
      } else {
        if (this.item.matchStart === 0) {
          Text(this.item.name.substring(0, this.item.matchEnd))
            .recordNameStyle()
            .fontColor(this.highlightColor)
        } else {
          Text(this.item.name.substring(0, this.item.matchStart))
            .recordNameStyle()
          Text(this.item.name.substring(this.item.matchStart, this.item.matchEnd))
            .recordNameStyle()
            .fontColor(this.highlightColor)
        }
        if (this.item.matchEnd !== this.item.name.length) {
          Text(this.item.name.substring(this.item.matchEnd))
            .recordNameStyle()
        }
      }
    }
  }

  // 标准大小录音机列表布局
  @Builder
  RecordListStandardLayout(isFloatCard: boolean) {
    Column() {
      if (!this.needHighlight) {
        Text(this.item?.name || '')
          .recordNameStyle()
          .accessibilityText(this.item?.name + ' ' + (this.item.tranState === 2 ?
            getContext().resourceManager.getStringSync($r('app.string.transcribed_talkback')) : ''))
      } else {
        this.highlightName()
      }
      Flex({ wrap: FlexWrap.NoWrap, direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        if (DeviceUtil.isFolded() || DeviceUtil.isExpanded() && this.densityPixels <= this.defaultDP) {
          Text(this.getDateTimeTitle())
            .recordTimeNormalFoldStyle()
        } else {
          Text(this.getDateTimeTitle())
            .recordTimeStyle()
        }

        Column() {
          Image(this.isDarkMode ? $rawfile('ic_trans_done_dark.svg') : $rawfile('ic_trans_done.svg'))
            .width(12)
            .height(12)
            .margin({ left: 10.5, right: Configuration.getLocale().dir === 'rtl' ? 10.5 : 0, top: 4.5 })
            .visibility(this.item.tranState === 2 ? Visibility.Visible : Visibility.None)
        }.constraintSize({
          minHeight: '19vp',
        })
      }
    }
    .width('100%')
    .flexShrink(1)
    .accessibilityGroup(isFloatCard)
    .padding({
      end: LengthMetrics.vp(8),
      start: LengthMetrics.vp(0),
    })
    .alignItems(HorizontalAlign.Start)

    Column() {
      Text(Util.timeFormat(this.item?.duration || 0))
        .recordDurationStyle()
        // 显示进度条时，不播报总时长，避免合进度条的总时长播报重复导致冗余
        .accessibilityLevel(this.showProgressBarComponent ? 'no' : 'yes')
        .accessibilityText(accessibility.isOpenTouchGuideSync()
          ? AccessibilityUtil.getTotalDurationText(this.item?.duration) : '')
    }
    .flexShrink(0)

    this.actionArea(isFloatCard);
  }

  // 特大模式下，录音机列表布局
  @Builder
  /* instrument ignore next */
  RecordListHugeLayout(isFloatCard: boolean) {
    Column() {
      if (!this.needHighlight) {
        Text(this.item?.name || '')
          .recordNameStyle()
          .accessibilityText(this.item?.name + ' ' + (this.item.tranState === 2 ?
            getContext().resourceManager.getStringSync($r('app.string.transcribed_talkback')) : ''))
      } else {
        this.highlightName()
      }
      Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
        Text(this.getDateTimeHugeTitle(false))
          .recordTimeStyle()
        if (this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) {
          Image(this.isDarkMode ? $rawfile('ic_trans_done_dark.svg') : $rawfile('ic_trans_done.svg'))
            .width(11.5)
            .height(11.5)
            .visibility(this.item.tranState === 2 ? Visibility.Visible :
              Visibility.Hidden)
            .margin({
              left: $r('app.float.distance_8')
            })
        }
      }

      if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
        Flex({ direction: FlexDirection.Row, alignItems: ItemAlign.Center }) {
          Text(this.getDateTimeHugeTitle(true))
            .recordTimeStyle()
          Image(this.isDarkMode ? $rawfile('ic_trans_done_dark.svg') : $rawfile('ic_trans_done.svg'))
            .width(11.5)
            .height(11.5)
            .visibility(this.item.tranState === 2 ? Visibility.Visible :
              Visibility.Hidden)
            .margin({
              left: $r('app.float.distance_8')
            })
        }
      }
      Text(Util.timeFormat(this.item?.duration || 0))
        .recordDurationStyle()
        .accessibilityText(AccessibilityUtil.getTotalDurationText(this.item?.duration))
        .margin({
          top: isFloatCard && DeviceUtil.isTabletOrTripleGStatus() ? 6 : 16,
        })

    }
    .accessibilityGroup(isFloatCard)
    .padding({
      start: LengthMetrics.vp(0),
      end: (this.fontSizeScale >= CommonConstants.TEXT_SIZE_HUGE_LEVEL2 && this.navMode === NavigationMode.Split)
        ? LengthMetrics.vp(0)
        : LengthMetrics.vp(24),
    })
    .alignItems(HorizontalAlign.Start)
    .flexShrink(1)

    this.actionArea(false);
  }

  @Builder
  /* instrument ignore next */
  actionArea(isFloatCard: boolean) {
    if (this.navMode === NavigationMode.Stack) {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          this.RecordItemButton(isFloatCard);
          if (!isFloatCard) {
            this.checkBoxBuilder(isFloatCard);
          }
        }
      }
      .accessibilityLevel('no')
      .flexShrink(0)
      .translate(this.navMode === NavigationMode.Stack ? {} : { x: this.isEditMode ? -40 : 0 })
    } else if (this.isEditMode) {
      Column() {
        Stack({ alignContent: Alignment.Center }) {
          this.checkBoxBuilder(isFloatCard);
        }
      }
      .flexShrink(0)
    }
  }

  @Builder
  myDragBuild() {
    Column() {
      this.DragRecordItem();
    }
    .backgroundColor($r('sys.color.comp_background_primary'))
    .padding($r('app.float.padding_4'))
    .borderRadius($r('app.float.wh_value_16'))
    .width(this.navWidth - (this.isEditMode ? 48 : 32))
  }

  @Styles
  dragAttrs() {
    .draggable(
      (this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) ?
        (DeviceUtil.isSmallFoldVer() && DeviceUtil.isFolded() ? false : this.dragEnable) : false
    )
    .dragPreview(this.myDragBuild())
    .dragPreviewOptions({
      mode: DragPreviewMode.DISABLE_SCALE,
      numberBadge: this.item.flagSelect ? this.selectedRecordList.length : 1,
      modifier: this.dragImageModifier
        .borderRadius($r('app.float.wh_value_14'))
        .shadow(ShadowStyle.OUTER_DEFAULT_LG) as ImageModifier,
    }, {
      isMultiSelectionEnabled: this.isMultiSelect,
      defaultAnimationBeforeLifting: false,
    })
    .onPreDrag((preDragStatus: PreDragStatus) => {
      LogUtil.info(`${TAG} onPreDrag, isEditMode: ${this.isEditMode}`);
      this.onPreDragFun(preDragStatus);
    })
    .onDragStart((event: DragEvent) => {
      LogUtil.info(`${TAG} onDragStart, isEditMode: ${this.isEditMode}, event result : ${event.getResult()}`);
      if (this.isEditMode) {
        this.onDragStartFunMultiSelect(event);
      } else {
        this.onDragStartFunSingle(event);
      }
      AccessibilityUtil.sendAnnounceAccessibilityEvent(
        Util.getFormatStringSync($r('app.string.accessibility_drag_down_to_vassistant'), ''));
    })
    .onDragEnd((event: DragEvent) => {
      LogUtil.info(`${TAG} onDragEnd, isEditMode: ${this.isEditMode}, event result : ${event.getResult()}`);
      this.onDragEndFun(event);
    })
  }

  /* instrument ignore next */
  private onPreDragFun(preDragStatus: PreDragStatus): void {
    if (this.isEditMode && preDragStatus === PreDragStatus.READY_TO_TRIGGER_DRAG_ACTION) {
      Util.startVibration();
    }
  }

  // 首页列表视图拖拽
  /* instrument ignore next */
  private onDragStartFunSingle(event: DragEvent): void {
    this.recordListItemModifier.isDragging = true;
    this.showProgressBarComponent = false;
    this.isShowProgressBar = false;
    this.isFloatMenuShown = false;
    Util.startVibration();
    event.setData(this.packDragInfo());
  }

  // 多选视图拖拽
  /* instrument ignore next */
  private onDragStartFunMultiSelect(event: DragEvent): void {
    this.recordListItemModifier.isDragging = true;
    AppStorage.setOrCreate('draggingItemSelectStatus', this.item.flagSelect);
    AppStorage.setOrCreate('isRecordListDragging', true);
    Util.startVibration();
    event.setData(this.packDragInfoFromSelect());
  }

  /* instrument ignore next */
  private onDragEndFun(event: DragEvent): void {
    this.recordListItemModifier.isDragging = false;
    AppStorage.setOrCreate('draggingItemSelectStatus', undefined);
    AppStorage.setOrCreate('isRecordListDragging', false);
    this.recordListItemModifier.attribute?.opacity(DEFAULT_ITEM_OPACITY);
  }

  /* instrument ignore next */
  private packDragInfo(): UDC.UnifiedData {
    LogUtil.info(`${TAG}, start to pack drag info.`);
    let record: UDC.Audio = new UDC.Audio();
    let path = this.item._data;
    if (this.item?.phoneNumber) {
      try {
        let title: string = this.item.title;
        let titleTempList = title.split('.');
        let titleSuffix = titleTempList[titleTempList.length - 1];
        title = this.item.name + '.' + titleSuffix;
        let callRecordPath = Util.getSharePathToCopy(this.item._data, title, getContext(this));
        record.audioUri = fileUri.getUriFromPath(callRecordPath);
      } catch (error) {
        let code: number = (error as BusinessError).code;
        let message: string = (error as BusinessError).message;
        LogUtil.error(`${TAG}, packDragInfoFromSelect error, code: ${code}, message: ${message}`);
      }
      return new UDC.UnifiedData(record);
    } else {
      try {
        record.audioUri = fileUri.getUriFromPath(path);
      } catch (error) {
        let code: number = (error as BusinessError).code;
        let message: string = (error as BusinessError).message;
        LogUtil.error(`${TAG}, packDragInfoFromSelect error, code: ${code}, message: ${message}`);
      }
      return new UDC.UnifiedData(record);
    }
  }

  /* instrument ignore next */
  private packDragInfoFromSelect(): UDC.UnifiedData {
    if (!this.item.flagSelect) {
      let unifiedDataSingle: UDC.UnifiedData = new UDC.UnifiedData();
      let activeRecord: UDC.Audio = new UDC.Audio();
      try {
        activeRecord.audioUri = fileUri.getUriFromPath(this.item._data);
        unifiedDataSingle.addRecord(activeRecord);
      } catch (error) {
        let code: number = (error as BusinessError).code;
        let message: string = (error as BusinessError).message;
        LogUtil.error(`${TAG}, packDragInfoFromSelect error, code: ${code}, message: ${message}`);
      }
      return unifiedDataSingle;
    } else {
      let unifiedDataMulti: UDC.UnifiedData = new UDC.UnifiedData();
      this.handleSelectList(unifiedDataMulti);
      return unifiedDataMulti;
    }
  }

  /* instrument ignore next */
  private handleSelectList(unifiedDataMulti: UDC.UnifiedData): void {
    let limit = this.selectedRecordList.length > DRAGGING_ITEM_LIMIT
      ? DRAGGING_ITEM_LIMIT : this.selectedRecordList.length;
    for (let i = 0; i < limit; i++) {
      let item = this.selectedRecordList[i];
      if (item.phoneNumber === undefined) {
        let commonRecord: UDC.Audio = new UDC.Audio();
        try {
          commonRecord.audioUri = fileUri.getUriFromPath(item._data);
          unifiedDataMulti.addRecord(commonRecord);
        } catch (error) {
          let code: number = (error as BusinessError).code;
          let message: string = (error as BusinessError).message;
          LogUtil.error(`${TAG}, packDragInfoFromSelect error, code: ${code}, message: ${message}`);
        }
      } else {
        let singleRecord: UDC.Audio = new UDC.Audio();
        try {
          let title: string = item.title;
          let titleTempList = title.split('.');
          let titleSuffix = titleTempList[titleTempList.length - 1];
          title = item.name + '.' + titleSuffix;
          let path = Util.getSharePathToCopyNoDelete(item._data, title, getContext(this));
          singleRecord.audioUri = fileUri.getUriFromPath(path);
          unifiedDataMulti.addRecord(singleRecord);
        } catch (error) {
          let code: number = (error as BusinessError).code;
          let message: string = (error as BusinessError).message;
          LogUtil.error(`${TAG}, packDragInfoFromSelect error, code: ${code}, message: ${message}`);
        }
      }
    }
  }

  private updateAccessibilityTip() {
    const clickStr = Util.getFormatStringSync($r('app.string.accessibility_double_click'), '');
    const leftSwipeStr = Util.getFormatStringSync($r('app.string.accessibility_left_swipe'), '');
    const longPressStr = Util.getFormatStringSync($r('app.string.accessibility_long_press'), '');
    if (this.item.isSwipeExpanded) {
      this.accessibilityTip = Util.getFormatStringSync($r('app.string.accessibility_right_swipe'), '');
    } else if (this.isSearchMode) {
      this.accessibilityTip = `${clickStr} ${leftSwipeStr}`;
    } else if (this.isEditMode) {
      this.accessibilityTip = `${clickStr}`;
    } else if (this.navMode === NavigationMode.Stack &&
      this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
      this.accessibilityTip = `${longPressStr} ${leftSwipeStr}`;
    } else {
      this.accessibilityTip = `${clickStr} ${longPressStr} ${leftSwipeStr}`;
    }
  }

  @Styles
  /* instrument ignore next */
  gestureAttrs() {
    .onGestureJudgeBegin((gestureInfo: GestureInfo) => {
      let isScreenReaderEnabled =
        Settings.getValueSync(getContext(this), 'accessibility_screenreader_enabled', '') === '1';
      // 屏幕朗读模式下触摸进度条，拒绝ListItem的长按和拖拽事件
      if (isScreenReaderEnabled && this.isTouchProgressBar) {
        if (gestureInfo.type == GestureControl.GestureType.LONG_PRESS_GESTURE) {
          return GestureJudgeResult.REJECT;
        }
        if (gestureInfo.type == GestureControl.GestureType.DRAG) {
          return GestureJudgeResult.REJECT;
        }
      }
      return GestureJudgeResult.CONTINUE;
    })
    .parallelGesture(LongPressGesture({ repeat: false, duration: 500 })
      .onAction(async (event: GestureEvent) => {
        this.dragEnable = true;
        if (this.isEditMode && this.selectedRecordList.length >= DRAGGING_ITEM_LIMIT &&
          this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) {
          Util.showToast($r('app.string.drag_quantity_limit', DRAGGING_ITEM_LIMIT - 1), DeviceUtil.isPC());
          this.dragEnable = false;
          return;
        }
        // 设置点击的y坐标
        const touchPoint = event.fingerList[0];
        this.recordItemGlobalY = touchPoint?.globalY || 0;
        // 防止在左滑状态，或已经跳转到其他页面的情况下，才触发了长按事件
        // instrument ignore if
        this.triggerLongClickTime = new Date().getTime();
        LogUtil.warn(TAG + '：this.navMode:' + this.navMode)
        LogUtil.warn(TAG + '：length' + this.pathStack.getAllPathName().length)
        if (this.isEditMode || this.item.isSwipeExpanded || (this.navMode === NavigationMode.Stack &&
          (this.pathStack.getAllPathName().length > 0 || router.getState().name !== 'Index'))) {
          LogUtil.warn(TAG + ': The page has been redirected. The float menu doesn\'t need to be displayed.')
          return;
        }
        HiSysEventUtil.eventDotting(HiSysEventName.LOGNPRESS_ON_RECORD_LIST);
        LogUtil.info(TAG + ' long press gesture.');
        // 处理长按事件
        this.onLongClick();
        Util.startVibration();
      }))
    .bindContextMenu(this.isFloatMenuShown, this.FloatMenu(), {
      placement: this.menuAtTheBottom ?
        (Configuration.getLocale().dir === 'ltr' ? Placement.BottomLeft : Placement.BottomRight) :
        (Configuration.getLocale().dir === 'ltr' ? Placement.TopLeft : Placement.TopRight),
      preview: this.myDragBuild(),
      previewAnimationOptions: {
        scale: [1, 1],
        transition: this.previewEffect
      },
      borderRadius: DeviceUtil.isPC() ? $r('sys.float.corner_radius_level4') : $r('app.float.wh_value_20'),
      onDisappear: () => {
        this.isFloatMenuShown = false;
      },
      layoutRegionMargin: { left: 0, right: 0 }
    })
  }

  @Styles
  selectedStyles(): void {
    .backgroundColor(Color.Transparent)
  }

  @Styles
  pressedStyles(): void {
    .backgroundColor(this.isDarkMode ? $r('sys.color.ohos_id_color_click_effect_dark') :
      $r('sys.color.ohos_id_color_click_effect'));
  }

  @Styles
  selectedRadius(): void {
    .borderRadius($r('app.float.wh_value_12'));
  }

  @Styles
  normalStyles(): void {
    .backgroundColor(this.isHover ?
      (this.isDarkMode ? $r('sys.color.ohos_id_color_hover_dark') : $r('sys.color.ohos_id_color_hover')) :
      Color.Transparent);
  }

  private getIconList(): Array<SwipeIconConfigurations> {
    let iconList: SwipeIconConfigurations[] = [];
    let renameIcon: SwipeIconConfigurations = {
      icon: new SymbolGlyphModifier($r('sys.symbol.square_and_pencil'))
        .id('indexRename')
        .draggable(false)
        .opacity(this.renameOpacity),
      backgroundColor: ($r('sys.color.multi_color_11')),
      iconOptions: {
        accessibilityText: ($r('app.string.file_rename')),
        enable: this.item.tranState !== 1
      },
      onAction: () => {
        this.selectedRecordList = [];
        let item = this.item;
        this.selectedRecordList.push(item);
        HiSysEventUtil.eventDotting(HiSysEventName.SWIPE_RENAME);
        this.contextThis.eventHub.emit('renameSelectedRecord');
        this.isCloseAllSwipe = true;
        this.isSearchCloseSwipe = true;
      }
    };
    let shareIcon: SwipeIconConfigurations = {
      icon: new SymbolGlyphModifier($r('sys.symbol.share'))
        .draggable(false)
        .id('indexShare')
        .opacity(this.shareOpacity)
        .visibility(this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS ?
          Visibility.None : this.shareButtonVisibility)
        .accessibilityText($r('app.string.voice_share')),
      backgroundColor: ('#3c8153'),
      onAction: () => {
        this.shareRecord('swipeShare');
      }
    };
    let restoreIcon: SwipeIconConfigurations = {
      icon: new SymbolGlyphModifier($r('sys.symbol.arrow_counterclockwise'))
        .draggable(false)
        .id('recentDeleteRecover')
        .backgroundColor($r('sys.color.comp_background_emphasize'))
        .fontColor(this.isDarkMode ? [$r('sys.color.ohos_id_color_primary')] : [$r('sys.color.background_primary')])
        .visibility(this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS ?
          this.shareButtonVisibility : Visibility.None)
        .accessibilityText($r('app.string.recording_recover')),
      backgroundColor: ($r('sys.color.comp_background_emphasize')),
      onAction: () => {
        this.selectedRecordList = [];
        let item = this.item;
        this.selectedRecordList.push(item);
        this.contextThis.eventHub.emit('recoverFromRecentDelete', 'swipeRecover');
        this.isSearchCloseSwipe = true;
      }
    }

    if (this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS &&
      !(this.isSmallFoldVer && this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED)) {
      iconList.push(renameIcon);
    }
    if (this.sideFolderNameFlag !== SideBarMode.RECENT_DELETE_RECORDINGS) {
      iconList.push(shareIcon);
    }
    if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS) {
      iconList.push(restoreIcon);
    }
    return iconList;
  }

  private resolveAccessibilityText(text?: ResourceStr): string {
    if (!text) {
      return '';
    }
    if (typeof text === 'string') {
      return text;
    }
    return getContext(this).resourceManager.getStringSync(text);
  }

  @Builder
  SwipeEndActions() {
    Row({space:'5vp'}) {
      ForEach(this.getIconList(), (iconConfig: SwipeIconConfigurations) => {
        Button({ type: ButtonType.Normal }) {
          SymbolGlyph()
            .fontSize('24vp')
            .attributeModifier(iconConfig.icon)
        }
        .borderRadius('50%')
        .padding('10vp')
        .backgroundColor(iconConfig.backgroundColor)
        .enabled(iconConfig.iconOptions?.enable !== false)
        .accessibilityText(this.resolveAccessibilityText(iconConfig.iconOptions?.accessibilityText))
        .onClick(() => {
          iconConfig.onAction();
        })
      }, (iconConfig: SwipeIconConfigurations, index: number) => `${index}`)

      Button({ type: ButtonType.Normal }) {
        SymbolGlyph($r('sys.symbol.trash'))
          .fontSize($r('app.float.wh_value_24'))
          .fontColor([$r('sys.color.icon_on_primary')])
      }
      .borderRadius('50%')
      .padding('10vp')
      .backgroundColor($r('sys.color.warning'))
      .accessibilityText($r('app.string.delete'))
      .onClick(() => {
        LogUtil.info(TAG + ' click swipe delete button.');
        HiSysEventUtil.eventDotting(HiSysEventName.SWIPE_DELETE);
        this.selectedRecordList = [];
        let item = this.item;
        this.selectedRecordList.push(item);
        this.isClickDeleteInSwipeMenu = true;
        this.isSearchCloseSwipe = true;
      })
    }
    .margin('10vp')
  }

  build() {
    ListItem() {
      this.ContentArea()
    }
    .swipeAction(!this.isNormalMode ? undefined : {
      end: {
        builder: () => {
          this.SwipeEndActions()
        },
        onAction: () => {
          this.onSwipeAction();
        }
      }
    })
  }

  @Builder
  ContentArea() {
    Column() {
      Button({ type: ButtonType.Normal, stateEffect: false }) {
        Column() {
          Flex({
            direction: FlexDirection.Row,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
          }) {
            if (this.fontSizeScale < CommonConstants.TEXT_SIZE_LARGE && this.densityPixels <= this.defaultDP) {
              this.RecordListStandardLayout(false);
            } else {
              this.RecordListHugeLayout(false);
            }
          }
          .backgroundColor(this.showRecordSelectedColor() ? this.getSelectedColor() : Color.Transparent)
          .borderRadius(this.getItemBorderRadius())
          .width(ConfigData.WH_100_100)
          .padding(this.getContentPadding(false))
          .id(`id_recordItem_${this.index}`)

          if (this.showProgressBarComponent) {
            ProgressBarComponent({
              currentTimePlay: this.currentTimePlay,
              duration: this.item?.duration,
            })
              .accessibilityGroup(false)
              .accessibilityLevel('yes')
              .margin({ bottom: 13 })
              .padding({ left: 8, right: 8 })
              .onTouch((event) => {
                if (event.type === TouchType.Down) {
                  this.isTouchProgressBar = true;
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.isTouchProgressBar = false;
                }
              })
          }
        }
        .onAreaChange((_, newValue: Area) => {
          if (this.item.itemHeight !== Number(newValue.height)) {
            this.item.itemHeight = Number(newValue.height)
          }
        })
      }
      .backgroundColor(Color.Transparent)
      .borderRadius(this.getItemBorderRadius())
      .padding(0)
      .stateStyles({
        normal: this.normalStyles,
        pressed: this.pressedStyles,
        selected: this.selectedRadius
      })
      .onHover((isHover) => {
        this.isHover = isHover;
      })
    }
    .id(`list${this.item.index}`)
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .padding($r('app.float.padding_4'))
    .borderRadius(this.getItemBorderRadius())
    .attributeModifier(this.recordListItemModifier)
    .stateStyles({
      selected: this.selectedStyles
    })
    .dragAttrs()
    .gestureAttrs()
    .onMouse((event: MouseEvent) => {
      if (event.button === MouseButton.Right && event.action === MouseAction.Press) {
        LogUtil.info(TAG + ' Right-click to display the floating menu.');
        let mousePositionY = event.target.area.globalPosition.y;
        this.recordItemGlobalY = Number(mousePositionY) || 0;
        if (this.isEditMode || this.item.isSwipeExpanded || (this.navMode === NavigationMode.Stack &&
          (this.pathStack.getAllPathName().length > 0 || router.getState().name !== 'Index'))) {
          LogUtil.warn(TAG + ': The page has been redirected. The float menu doesn\'t need to be displayed.')
        } else {
          this.onLongClick();
        }
      }
    })
    .onClick(async () => {
      let triggerClickTime = new Date().getTime();
      if (this.isFromLockScreenRecord) {
        LogUtil.warn(TAG + ' recording is from lockScreen, do not process click events.');
        return;
      }
      if (Math.abs(triggerClickTime - this.triggerLongClickTime) < 100 || this.isFloatMenuShown) {
        LogUtil.info(TAG + ' long click triggered, no need to handle onclick event');
        return;
      }
      if (this.isEditMode) {
        this.item.flagSelect = !this.item.flagSelect;
        this.handleSelectRecord();
        return;
      }
      if (this.checkSwipeState(this.item)) {
        if (this.sideFolderNameFlag === SideBarMode.RECENT_DELETE_RECORDINGS && this.navMode === NavigationMode.Stack) {
          LogUtil.info(TAG + ' click the recent delete Recordings, no operation');
        } else {
          this.routeRecordPlayPage(this.item, false);
        }
      }
    })
    .translate({ y: this.item.offsetY })
    .transition(this.getDeleteAnimation())
    .zIndex(this.index)
    .width('100%')
    .clip(true)
    .focusBox({
      margin: LengthMetrics.vp(-2),
    })
    .accessibilityDescription(this.accessibilityTip)
    .onAppear(async () => {
      let tranState: number = await DatabaseManager.getTransStatus(this.item._data);
      this.item.tranState = !this.isCeliaEnabled ? -1 : tranState;
      this.item.preTranState = tranState;
    })
  }

  getDeleteAnimation(): TransitionEffect {
    return TransitionEffect.asymmetric(
      TransitionEffect.IDENTITY,
      this.item.isSwipeExpanded ? TransitionEffect.scale({
        centerX: CommonConstants.COORDINATE_OF_TRANSFORMATION_CENTER_0,
        centerY: CommonConstants.COORDINATE_OF_TRANSFORMATION_CENTER_0,
        x: CommonConstants.SCALING_RATIO_PERCENT_75,
        y: CommonConstants.SCALING_RATIO_PERCENT_75
      })
        .animation({ curve: Curve.Friction, duration: CommonConstants.DURATION_300 })
        .combine(
          TransitionEffect.OPACITY.animation(
            { curve: Curve.Sharp, duration: CommonConstants.DURATION_300 }
          )
        )
        .combine(
          TransitionEffect.translate({
            y: CommonConstants.OFFSET_AMOUNT_30,
          }),
        ) :
        this.item.indexDelete ?
          TransitionEffect.OPACITY.animation(
            { curve: Curve.Sharp, duration: CommonConstants.DURATION_300 }
          )
          : TransitionEffect.IDENTITY,
    );
  }

  /* instrument ignore next */
  private handleSelectRecord() {
    let item = this.item;
    let indexInSelectedRecordList = this.selectedRecordList.findIndex(record => record._data === item._data);
    if (item.flagSelect) {
      LogUtil.info(TAG + ' select: ' + AnonymousUtil.anonymous(item.title) + ' to edit.');
      indexInSelectedRecordList === -1 ? this.selectedRecordList.push(item) : '';
      HiSysEventUtil.eventDotting(HiSysEventName.SELECT_ITEM_ON_RECORD_LIST);
    } else {
      LogUtil.info(TAG + ' unselect: ' + AnonymousUtil.anonymous(item.title) + ' to exit edit.');
      indexInSelectedRecordList === -1 ? '' : this.selectedRecordList.splice(indexInSelectedRecordList, 1);
      HiSysEventUtil.eventDotting(HiSysEventName.CNCL_SEL_ON_REC_LIST);
    }
  }

  private onSelectFlagChange() {
    LogUtil.info(TAG + ' onSelectFlagChange selectedRecordList size: ' + this.selectedRecordList.length);
    let filterResult = this.selectedRecordList.filter(item => item._data === this.item._data);
    // instrument ignore else
    if (filterResult.length > 0) {
      this.item.flagSelect = filterResult[0].flagSelect;
    } else {
      this.item.flagSelect = false;
    }
    this.recordListItemModifier.isSelected = this.item.flagSelect;
  }

  onShortCutRecordList() {
    if (this.isShortCutRecordList && this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS &&
      (this.state === CommonConstants.PLAYING || this.state === CommonConstants.PAUSED)) {
      this.isShowProgressBar = true;
      this.showProgressBarComponent = this.computeShowProgressBar();
      this.updateBtnSymbol();
    }
  }
}
