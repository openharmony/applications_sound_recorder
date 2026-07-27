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

import { CommonConstants, HiSysEventName, HiSysEventUtil, LogUtil, Util } from '@ohos/common';
import { Configuration, curves, display, LengthMetrics } from '@kit.ArkUI';
import { ConfigData } from '@ohos/common/src/main/ets/utils/ConfigData';
import { LazyDataSource, RecordData, RecordDataGroupArray } from '@ohos/common/src/main/ets/model/RecordData';
import { AudioRecordItemComponent } from './AudioRecordItemComponent';
import { i18n, intl } from '@kit.LocalizationKit';
import SortType from '@ohos/common/src/main/ets/constants/DataSortType';
import { SearchResult } from '@ohos/common/src/main/ets/model/SearchResult';
import { SideBarMode } from './SideBarComponent';
import { PlayManager } from '../controller/PlayManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';


const TAG: string = 'SoundRecorder_SearchComponent ';
const DEFAULT_FONT_SIZE = 16;
const LIST_ITEM_SPACE: number = 12;

//搜索组件
@Component
export struct SearchComponent {
  private scroller: ListScroller = new ListScroller();
  @State searchText: string = CommonConstants.EMPTY_STR;
  @Consume @Watch('onSearchModeChanged') isSearchMode: boolean;
  @State isFocusable: boolean = false;
  @Link searchStatus: number;
  @Link currentTimePlay: number;
  @Consume state: string;
  @StorageLink('isEditMode') isEditMode: boolean = false;
  @State callResult: number = 0;
  @State normalResult: number = 0;
  @State totalResult: number = 0;
  @Consume focusRecord: RecordData;
  @State searchRecordList: LazyDataSource<SearchResult> = new LazyDataSource();
  //排序方式
  @Prop sortType: string;
  @Consume recordDataGroupList: RecordDataGroupArray;
  @StorageProp('navigationMode') @Watch('onNavModeChanged') navMode: number = 0;
  @StorageProp('navigatorBarHeight') navigatorBarHeight: number = 0;
  //全部录音查询结果列表
  private allResultList: RecordData[] = [];
  //通话录音查询结果列表
  private callResultList: RecordData[] = [];
  //普通录音查询结果列表
  private normalResultList: RecordData[] = [];
  //完整搜索结果列表
  private totalResultList: SearchResult[] = [];

  @Consume finalResultList: SearchResult[];
  //是否已经搜索过一次
  private searchOnce: boolean = false;
  private searchLess: boolean = false;
  private oldSearchText: string = CommonConstants.EMPTY_STR;
  private callHeader: string = getContext(this).resourceManager.getStringSync($r('app.string.call_recording'));
  private normalHeader: string = getContext(this).resourceManager.getStringSync($r('app.string.audio_recordings'));
  private isUpdate: boolean = false;
  @Consume sideFolderNameFlag: number;
  @Link @Watch('closeSwipeAction') isSearchCloseSwipe: boolean;
  @StorageProp('fontSizeScale') @Watch('onFontScaleChange') fontScale: number = AppStorage.get('fontSizeScale') || 1;
  @State fontSize: string = `${DEFAULT_FONT_SIZE}vp`;
  @Consume isSwipeOpen: boolean;
  @Consume isCloseAllSwipe: boolean;

  private onNavModeChanged() {
    if (this.isSearchMode) {
      Util.delayExecute(() => {
        LogUtil.info(`${TAG} request record_search focus.`);
        focusControl.requestFocus('record_search');
      }, 100);
    }
  }

  private onFontScaleChange() {
    let scale = Math.min(1.2, this.fontScale);
    if (isNaN(scale) || !scale) {
      scale = 1;
    }
    this.fontSize = `${scale * DEFAULT_FONT_SIZE}vp`;
  }

  //字符比较器
  private recordCompare: intl.Collator = new intl.Collator(i18n.System.getSystemLocale(), {
    sensitivity: 'case',
    numeric: false,
    caseFirst: 'lower',
    usage: 'sort',
    collation: 'dict',
    ignorePunctuation: false
  });

  private closeSwipeAction() {
    if (this.isSearchCloseSwipe) {
      LogUtil.info(TAG + 'closeSwipeAction');
      try {
        this.scroller.closeAllSwipeActions();
      } catch (err) {
        let message = (err as BusinessError).message;
        LogUtil.error(TAG + ' closeSwipeAction closeAllSwipeActions error ' + message);
      }
      this.isSearchCloseSwipe = false;
    }
  }

  private updateSearchResult = async (type: string, data: RecordData[], beforeName?: string) => {
    if (!this.isSearchMode) {
      return;
    }
    if (!data || data.length === 0) {
      LogUtil.log(TAG + ' empty data');
      return;
    }
    switch (type) {
      case CommonConstants.DELETE:
        this.removeData(data[0]);
        break;
      case CommonConstants.UPDATE:
        this.reSearch();
        break;
      default: {
        LogUtil.warn(TAG + ' unkown type: ' + type);
      }
    }
  }

  private changeFocusState = async (item: RecordData) => {
    if (!this.isSearchMode) {
      return;
    }
    for (let i = 0; i < this.totalResultList.length; i++) {
      let result = this.totalResultList[i];
      if (result.isTitle || !result.record) {
        continue;
      }
      if (result.record._data === item._data && result.isFocus) {
        return;
      }
      if (result.record._data !== item._data && result.isFocus) {
        result.isFocus = false;
      }
      if (result.record._data === item._data && !result.isFocus) {
        result.isFocus = true;
      }
    }
  }

  private updateData(updateData: RecordData, beforeName?: string) {
    LogUtil.log(TAG + ' update record data');
    this.isUpdate = true;
    //判断新名称是否匹配查询的规则，如果匹配则直接更新，否则重新搜索
    let match = this.matchRecord(updateData, this.searchText);
    if (!match || this.sortType === SortType.SORT_NAME_ASC) {
      LogUtil.log(TAG + ' update record data, need to reSearch');
      this.reSearch();
      return;
    }
    LogUtil.log(TAG + ' update record data, update searchRecordList');
    let oldRecord: SearchResult = new SearchResult();
    let index = this.searchRecordList.getAll().findIndex((item: SearchResult) => {
      if (item.isTitle) {
        return false;
      } else {
        if (item.record?._data === beforeName) {
          item.record = updateData;
          oldRecord = item;
          return true;
        }
        return false;
      }
    })
    LogUtil.log(TAG + ' update record data, search index:' + index);
    if (index >= 0) {
      oldRecord.record = updateData;
      if (!this.isFoldFold() && !this.isTabletStack()) {
        getContext().eventHub.emit('changeFocus', updateData);
        getContext().eventHub.emit('playRecord', updateData);
      }
      this.searchRecordList.updateData(index, oldRecord);
      LogUtil.log(TAG + ' update record data, update finish');
    }
    this.isUpdate = false;
  }

  private removeData(removeData: RecordData) {
    LogUtil.log(TAG + ' remove record data');
    let beforeSearchRecord: RecordData[] = [];
    this.searchRecordList.getAll().forEach((item: SearchResult) => {
      if (!item.isTitle) {
        beforeSearchRecord.push(item.record);
      }
    })
    this.searchRecordList.deleteItemByPredicate((item: SearchResult) => {
      if (!item.isTitle) {
        if (item.record?._data === removeData._data) {
          this.totalResult--;
          if (this.totalResult === 0) {
            LogUtil.log(TAG + ' remove to zero');
            this.searchStatus = CommonConstants.SEARCH_RESULTS_EMPTY;
            this.focusRecord = new RecordData();
          }
          return true;
        }
      }
      return false;
    });
    this.searchRecordList.reload();
    let afterSearchRecord: RecordData[] = [];
    this.searchRecordList.getAll().forEach((item: SearchResult) => {
      if (!item.isTitle) {
        afterSearchRecord.push(item.record);
      }
    })
    this.updateRecordPlayPageAfterDelete(beforeSearchRecord, afterSearchRecord, removeData);
  }

  @Builder
  searchBackButton() {
    if (this.isSearchMode) {
      Button({ type: ButtonType.Circle, stateEffect: true }) {
        Image($r('sys.media.ohos_ic_compnent_titlebar_back'))
          .id('back_image')
          .fillColor($r('sys.color.ohos_id_color_primary'))
          .draggable(false)
          .objectFit(ImageFit.Contain)
          .width($r('app.float.wh_value_24'))
          .height($r('app.float.wh_value_24'))
      }
      .id('back_btn')
      .margin({
        left: Configuration.getLocale().dir === 'ltr'
          ? undefined : $r('sys.float.ohos_id_elements_margin_horizontal_m'),
        right: Configuration.getLocale().dir === 'ltr'
          ? $r('sys.float.ohos_id_elements_margin_horizontal_m') : undefined,
      })
      .width($r('app.float.wh_value_40'))
      .height($r('app.float.wh_value_40'))
      .backgroundColor($r('sys.color.ohos_id_color_button_normal'))
      .draggable(false)
      .borderRadius(20)
      .accessibilityText($r('app.string.back'))
      .rotate({ y: 360, angle: Configuration.getLocale().dir === 'ltr' ? 0 : 180 })
      .onClick(() => {
        if (this.isSwipeOpen) {
          this.cleanSwipeAction();
          return;
        }
        this.reset();
        if (!this.isFoldFold() && !this.isTabletStack()) {
          let playRecord: RecordData = this.getDefaultFocus();
          if (this.focusRecord._data !== '') {
            playRecord = this.focusRecord;
          }
          getContext().eventHub.emit('playRecord', playRecord);
          getContext().eventHub.emit('changeFocus', playRecord);
        }
        this.isFocusable = false;
        animateTo({
          curve: curves.interpolatingSpring(0, 1, 342, 38)
        }, () => {
          this.isSearchMode = false;
        });
      })
    }
  }

  private showSearchMode() {
    if (this.isEditMode) {
      return;
    }
    if (this.isSwipeOpen) {
      this.cleanSwipeAction();
      return;
    }
    const player = PlayManager.getInstance();
    if (this.state === 'playing') {
      player.pause();
    }
    this.isFocusable = true;
    focusControl.requestFocus('record_search');
    animateTo({
      curve: curves.interpolatingSpring(0, 1, 342, 38)
    }, () => {
      this.isSearchMode = true;
      AccessibilityUtil.sendFocusAccessibilityEvent('record_search');
    });
  }

  @Builder
  recordSearch() {
    Row() {
      Row() {
        // 搜索框无障碍播报时会播报“双击并按住会弹出更多选项”，不是搜索态时没有更多选项，特拆分为两个组件。
        Search({
          placeholder: $r('app.string.search_recording_files'),
          value: $$this.searchText,
        })
          .placeholderColor($r('sys.color.font_secondary'))
          .accessibilityGroup(true)
          .focusable(false)
          .caretStyle({ color: '#FB654E' })
          .selectedBackgroundColor('#FB654E')
          .enabled(!this.isEditMode)
          .visibility(this.isFocusable ? Visibility.None : Visibility.Visible)
          .onClick(() => this.showSearchMode())
          .placeholderFont({size: this.fontSize})
          .searchIcon({size: this.fontSize})
      }
      .id('record_search_readonly')
      .enabled(!this.isEditMode)
      .accessibilityRole(AccessibilityRoleType.SEARCH)
      .accessibilityText($r('app.string.search_recording_files'))
      .onClick(() => this.showSearchMode())
      .focusBox({
        margin: LengthMetrics.vp(-2)
      })

      Search({
        placeholder: $r('app.string.searching'),
        value: $$this.searchText,
      })
        .defaultFocus(true)
        .placeholderColor($r('sys.color.font_secondary'))
        .focusable(true)
        .caretStyle({ color: '#FB654E' })
        .selectedBackgroundColor('#FB654E')
        .id('record_search')
        .onChange((value: string) => {
          if (this.isSearchMode) {
            this.handlerSearch(value);
          }
        })
        .visibility(!this.isFocusable ? Visibility.Hidden : Visibility.Visible)
        .placeholderFont({size: this.fontSize})
        .searchIcon({size: this.fontSize})
        .textFont({size: this.fontSize})
        .cancelButton({icon: {size: this.fontSize}})
    }
    .onAreaChange((oldVal, newVal) => {
      const x = Number(newVal.globalPosition.x)
      const y = Number(newVal.globalPosition.y)
      const width = Number(newVal.width)
      const height = Number(newVal.height)
      AppStorage.setOrCreate('searchRect', { x, y, width, height })
    })
    .layoutWeight(1)
  }

  aboutToAppear(): void {
    LogUtil.log(TAG + ' search component appear');
    getContext().eventHub.on('updateSearchResult', this.updateSearchResult);
    getContext().eventHub.on('changeFocusState', this.changeFocusState);
    this.onFontScaleChange();
  }

  aboutToDisappear(): void {
    LogUtil.log(TAG + ' search component disappear');
    getContext().eventHub.off('updateSearchResult', this.updateSearchResult);
    getContext().eventHub.off('changeFocusState', this.changeFocusState);
  }

  @Builder
  emptyComponent() {
    Column() {
      Image($r('app.media.no_more'))
        .matchTextDirection(Configuration.getLocale().dir === 'rtl' ? true : false)
        .draggable(false)
        .objectFit(ImageFit.Contain)
        .width($r('app.float.wh_value_120'))
        .height($r('app.float.wh_value_120'))
      Text($r('app.string.no_records'))
        .fontSize($r('app.float.font_14_fp'))
        .fontColor($r('sys.color.font_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .width(ConfigData.WH_100_100)
    .height(`calc(100% - 56vp - ${this.navigatorBarHeight}vp)`)
  }

  @Builder
  searchResultList() {
    Column() {
      Column() {
        this.recordList();
      }
    }
    .justifyContent(FlexAlign.Start)
    .width(ConfigData.WH_100_100)
  }

  @Builder
  recordList() {
    List({ scroller: this.scroller, space: LIST_ITEM_SPACE }) {
      ListItem() {
        Column() {
          Text($r('app.plural.search_result_plural', this.totalResult, this.totalResult))
            .fontSize($r('sys.float.Body_M'))
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.font_secondary'))
        }
        .width(ConfigData.WH_100_100)
        .padding({
          left: $r('app.float.wh_value_12'),
          right: $r('app.float.wh_value_12'),
          top: 27,
          bottom: 0
        })
        .alignItems(HorizontalAlign.Start)
        .justifyContent(FlexAlign.End)
      }

      LazyForEach(this.searchRecordList, (recordResult: SearchResult, index: number) => {
        AudioRecordItemComponent({
          state: this.state,
          index: index,
          item: recordResult.record,
          currentTimePlay: this.currentTimePlay,
          isCallRecord: recordResult.isCallRecord,
          needHighlight: true,
          lastItem: recordResult.lastOne,
          isSearchItem: true,
          needFocus: ((this.isFoldFold() || this.isTabletStack()) ? false : recordResult.isFocus),
          isSearchCloseSwipe: this.isSearchCloseSwipe
        })
      }, (item: SearchResult) => item.record._data)

      ListItem() {
        Column() {
        }.height($r('app.float.wh_value_12'))
      }
    }
    .layoutWeight(1)
    .height(ConfigData.WH_100_100)
    .cachedCount(5)
    .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true }) // 边缘效果设置为Spring
    .padding({
      left: this.searchStatus === CommonConstants.NOT_SEARCH ? 0 : 16,
      right: this.searchStatus === CommonConstants.NOT_SEARCH ? 0 : 16
    })
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      Row() {
        this.searchBackButton();
        this.recordSearch();
      }
      .padding({
        left: this.searchStatus === CommonConstants.NOT_SEARCH ? 0 : 16,
        right: this.searchStatus === CommonConstants.NOT_SEARCH ? 0 : 16
      })
      .margin({
        bottom: this.searchStatus === CommonConstants.SEARCH_RESULTS_EMPTY || !this.isSearchMode ? 0 : 8
      })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .width(ConfigData.WH_100_100)
      .height($r('app.float.wh_value_56'))

      Row() {
        if (this.searchStatus === CommonConstants.SEARCH_RESULTS_EMPTY) {
          this.emptyComponent();
        } else if (this.searchStatus === CommonConstants.HAS_SEARCH_RESULTS) {
          this.searchResultList();
        }
      }
      .margin({ top: $r('app.float.wh_value_56') })
    }
  }

  @Builder
  recordHeader(header: string) {
    Row() {
      Text(header)
        .fontSize($r('sys.float.Body_M'))
        .fontColor($r('sys.color.font_secondary'))
        .width(ConfigData.WH_100_100)
        .fontWeight(FontWeight.Medium)
    }
    .constraintSize({
      minHeight: $r('app.float.wh_value_36'),
    })
    .height($r('app.float.wh_value_48'))
    .padding({
      left: $r('app.float.wh_value_12'),
      bottom: $r('app.float.wh_value_10')
    })
    .width(ConfigData.WH_100_100)
    .alignItems(VerticalAlign.Bottom)
    .justifyContent(FlexAlign.Start)
  }

  private onSearchModeChanged() {
    if (!this.isSearchMode) {
      LogUtil.info(TAG + 'searchMode change to : ' + this.isSearchMode);
      AccessibilityUtil.sendFocusAccessibilityEvent('record_search_readonly');
      this.searchStatus = CommonConstants.NOT_SEARCH;
      this.searchText = CommonConstants.EMPTY_STR;
      this.isFocusable = false;
      this.reset();
      this.cleanSwipeAction();
    }
  }

  private matchRecords(records: RecordData[], search: string) {
    LogUtil.info(TAG + 'matchRecords');
    let result: RecordData[] = [];
    if (!records || records.length === 0) {
      LogUtil.log(TAG + ' records is empty, not need to match');
      return result;
    }
    LogUtil.log(TAG + ' match record circulation')
    for (let i = 0; i < records.length; i++) {
      this.matchRecord(records[i], search, result);
    }
    LogUtil.log(TAG + ' match result:' + result.length + ' search:' + search.length);
    return result;
  }

  private matchRecord(record: RecordData, search: string, result?: RecordData[]): boolean {
    if (record.name.includes(search)) {
      record.matchType = CommonConstants.LIKE_MATCH;
      let start = record.name.indexOf(search);
      record.matchStart = start;
      record.matchEnd = start + search.length;
      result?.push(record);
      return true;
    }
    search = search.toLowerCase();
    if (record.initials.toLowerCase().includes(search)) {
      record.matchType = CommonConstants.INITIALS_MATCH;
      let start = record.initials.toLowerCase().indexOf(search);
      record.matchStart = start;
      record.matchEnd = start + search.length;
      result?.push(record);
      return true;
    }
    if (this.matchPhonetic(record, search)) {
      record.matchType = CommonConstants.PHONETIC_MATCH;
      result?.push(record);
      return true;
    }
    return false;
  }

  private matchPhonetic(record: RecordData, search: string): boolean {
    let phonetic = record.phonetic;
    let initials = record.initials;
    let firstLetter = search.substring(0, 1);
    let start = initials.indexOf(firstLetter);
    let phoneticArr = phonetic.split(CommonConstants.SPELL_SEPARATE);
    while (start >= 0) {
      let matchStr = CommonConstants.EMPTY_STR;
      for (let i = start; i < phoneticArr.length; i++) {
        matchStr += phoneticArr[i];
        if (matchStr.length < search.length) {
          continue;
        }
        if (matchStr.toLowerCase().startsWith(search)) {
          record.matchStart = start;
          record.matchEnd = i;
          return true;
        }
      }
      start = initials.indexOf(firstLetter, start + 1);
    }
    return false;
  }

  //搜索录音文件
  private async handlerSearch(value: string) {
    this.cleanSwipeAction();
    LogUtil.log(TAG + ' handle search:' + value.length);
    let playRecord: RecordData = new RecordData();
    if (!value) {
      this.searchStatus = CommonConstants.NOT_SEARCH;
      playRecord = this.getDefaultFocus();
      LogUtil.log(TAG + ' get default focus');
    } else {
      playRecord = this.search(value);
      LogUtil.log(TAG + ' search and get focus');
    }
    this.searchOnce = false;
    if (this.isFoldFold() || this.isTabletStack()) {
      return;
    }
    LogUtil.log(TAG + ' send event to change focus');
    getContext().eventHub.emit('playRecord', playRecord);
    getContext().eventHub.emit('changeFocus', playRecord);
  }

  private search(value: string): RecordData {
    let playRecord = new RecordData();
    //转为小写字母进行搜索
    this.searchLess = this.oldSearchText.length < value.length;
    LogUtil.log(TAG + ' search less:' + this.searchLess);
    this.oldSearchText = value;

    this.searchFromLastResult(value);

    if (this.totalResultList.length !== 0) {
      if (this.isUpdate && this.matchRecord(this.focusRecord, this.searchText)) {
        LogUtil.log(TAG + ' is update, no need to change focus');
        playRecord = this.focusRecord;
      } else {
        LogUtil.log(TAG + ' change focus');
        playRecord = this.totalResultList[0].record;
      }
      this.searchStatus = CommonConstants.HAS_SEARCH_RESULTS;
      this.totalResultList.some((item: SearchResult) => {
        if (!item.isTitle && item.record && item.record._data === playRecord._data) {
          item.isFocus = true;
          return true;
        }
        return false;
      })
    } else {
      LogUtil.log(TAG + ' search result is empty, focus is empty');
      this.searchStatus = CommonConstants.SEARCH_RESULTS_EMPTY;
    }
    LogUtil.log(TAG + ' has gaps, update all data');
    this.searchRecordList.deleteAll();
    this.searchRecordList.batchPushItem(this.totalResultList);
    this.isUpdate = false;
    return playRecord;
  }

  /**
   * 从上一次搜索结果继续搜索，避免每次都从完整的列表中搜索
   * @param value 搜索的值
   * @returns 返回搜索结果
   */
  private searchFromLastResult(value: string) {
    LogUtil.info(TAG + 'search from last result');
    this.totalResultList = [];
    let useLastList = this.searchOnce && this.searchLess;
    LogUtil.log(TAG + ' use last list:' + useLastList);
    let recordList: RecordData[] = [];
    if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
      recordList = useLastList ? this.allResultList :
      this.recordDataGroupList.allRecordList.getAll();
    } else if (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
      recordList = useLastList ? this.normalResultList :
      this.recordDataGroupList.normalRecordList.getAll();
    } else if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS) {
      recordList = useLastList ? this.callResultList :
      this.recordDataGroupList.callRecordList.getAll();
    }
    let matchRecordList = this.matchRecords(recordList, value);
    // 进行埋点，触发点位的打印
    this.sendHiSysEvent(matchRecordList);
    if (this.sortType === SortType.SORT_NAME_ASC) {
      LogUtil.log(TAG + ' sort by name again');
      matchRecordList.sort((a: RecordData, b: RecordData) => {
        return this.recordCompare.compare(a.name, b.name);
      });
    }
    let header = (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) ? this.normalHeader : this.callHeader;
    let isCallRecord: boolean = (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) ? false : true;
    this.totalResultList = this.foldRecordResult(matchRecordList, header, isCallRecord);
    this.totalResult = this.totalResultList.length;
    this.finalResultList = this.totalResultList;
    LogUtil.log(TAG + ' push all data to totalResultList length: ' + this.totalResult);
  }

  sendHiSysEvent(matchRecordList: RecordData[]) {
    if (this.searchText === CommonConstants.EMPTY_STR) {
      LogUtil.info(TAG + ' First entry, invalid search.');
      return;
    }
    if (matchRecordList.length > 0) {
      HiSysEventUtil.eventDotting(HiSysEventName.SEARCH_START);
    } else {
      HiSysEventUtil.eventDotting(HiSysEventName.SEARCH_NO_RESULT);
    }
  }

  //封装搜索到的记录
  private foldRecordResult(recordList: RecordData[], recordHeader: string, callRecord: boolean): SearchResult[] {
    LogUtil.log(TAG + ' begin to fold record result');
    let result: SearchResult[] = [];
    if (recordList.length !== 0) {
      for (let i = 0; i < recordList.length; i++) {
        let item = recordList[i];
        let record: SearchResult =
          new SearchResult(false, recordHeader, callRecord, item, i === recordList.length - 1, false)
        result.push(record);
      }
    }
    return result;
  }

  private reSearch() {
    LogUtil.log(TAG + ' search again');
    this.searchOnce = false;
    this.allResultList = [];
    this.callResultList = [];
    this.normalResultList = [];
    this.oldSearchText = CommonConstants.EMPTY_STR;
    this.handlerSearch(this.searchText);
  }

  private getDefaultFocus(): RecordData {
    let allList = this.recordDataGroupList.allRecordList.getAll();
    let normalList = this.recordDataGroupList.normalRecordList.getAll();
    let callList = this.recordDataGroupList.callRecordList.getAll();
    let headsetList = this.recordDataGroupList.headsetRecordList.getAll();
    return this.getDefault(allList, callList, normalList, headsetList);
  }

  private getDefault(allList: RecordData[], callList: RecordData[], normalList: RecordData[],
    headsetList: RecordData[]): RecordData {
    if (allList && allList.length > 0) {
      return allList[0];
    }
    if (normalList && normalList.length > 0) {
      return normalList[0];
    }
    if (callList && callList.length > 0) {
      return callList[0];
    }
    if (headsetList && headsetList.length > 0) {
      return headsetList[0];
    }
    return new RecordData();
  }

  private isFold() {
    let isFold: boolean = false;
    try {
      isFold = display.isFoldable();
    } catch (error) {
      LogUtil.error(TAG + ' get isFold failed ' + error);
    }
    return isFold;
  }

  //是否折叠屏折叠状态
  private isFoldFold() {
    if (!this.isFold()) {
      return false;
    }
    try {
      return display.getFoldStatus() === display.FoldStatus.FOLD_STATUS_FOLDED;
    } catch (error) {
      LogUtil.error('isFoldFold getFoldStatus error');
      return false;
    }
  }

  //判断是否平板机应用悬浮
  private isTabletStack(): boolean {
    return this.navMode === NavigationMode.Stack;
  }

  private reset() {
    LogUtil.log(TAG + ' reset fields');
    this.callResultList = []
    this.normalResultList = [];
    this.totalResultList = [];
    this.searchOnce = false;
    this.searchLess = false;
    this.oldSearchText = CommonConstants.EMPTY_STR;
  }

  private updateRecordPlayPageAfterDelete(beforeDeleteRecordData: RecordData[], afterDeleteRecordData: RecordData[],
    removeData: RecordData) {
    if (this.focusRecord === undefined) {
      LogUtil.info(TAG + ' updateRecordPlayPageAfterDelete error, removeData is null.');
      return;
    }
    if (afterDeleteRecordData.findIndex(item => item._data === this.focusRecord._data) !== -1) {
      LogUtil.info(TAG + ' removeData does not delete, no need to update record play page.');
      return;
    }
    // removeData is deleted, find a new one
    let recordIndexBeforeDelete = beforeDeleteRecordData.findIndex(item => item._data === removeData._data);
    LogUtil.info(TAG + ' removeData index before delete is: ' + recordIndexBeforeDelete);
    if (afterDeleteRecordData.length !== 0) {
      if (this.findNewFocusRecord(recordIndexBeforeDelete + 1, beforeDeleteRecordData.length,
        beforeDeleteRecordData, afterDeleteRecordData)) {
        LogUtil.info(TAG + ' new focusRecord found behind of origin removeData.');
        return;
      }
      if (this.findNewFocusRecord(recordIndexBeforeDelete - 1, -1, beforeDeleteRecordData,
        afterDeleteRecordData)) {
        LogUtil.info(TAG + ' new focusRecord found front of origin removeData.');
        return;
      }
    } else {
      LogUtil.info(TAG + ' all record deleted, update to null.');
      this.focusRecord = new RecordData();
    }
  }

  private findNewFocusRecord(startFindPosition: number, finishFindPosition: number,
    beforeDeleteRecordData: RecordData[], afterDeleteRecordData: RecordData[]): boolean {
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

  private isMatchNewFocus(afterDeleteRecordData: RecordData[], newFocus: RecordData): boolean {
    let index = afterDeleteRecordData.findIndex(item => item.title === newFocus.title);
    LogUtil.info(TAG + ' isMatchNewFocus  index : ' + index);
    if (index !== -1) {
      this.focusRecord = afterDeleteRecordData[index];
      LogUtil.info(TAG + ' update RecordPlayPage to: ' + this.focusRecord.title);
      return true;
    }
    return false;
  }

  private cleanSwipeAction(): void {
    this.isCloseAllSwipe = true;
    this.isSearchCloseSwipe = true;
    this.isSwipeOpen = false;
  }
}