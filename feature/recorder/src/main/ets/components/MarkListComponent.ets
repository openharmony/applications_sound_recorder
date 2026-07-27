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

import { DeviceUtil, DFXEnumConstants, HiSysEventName, HiSysEventUtil, LogUtil, MarkData } from '@ohos/common';
import curves from '@ohos.curves';
import { MarkComponent } from './MarkComponent';
import { CommonConstants, CommonConstants as Const } from '@ohos/common/src/main/ets/constants/CommonConstants';
import { Configuration } from '@kit.ArkUI';
import { relationalStore } from '@kit.ArkData';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import router from '@ohos.router';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { BusinessError } from '@kit.BasicServicesKit';
import { SideBarMode } from './SideBarComponent';
import { DatabaseConstants } from '@ohos/common/src/main/ets/constants/DatabaseConstants';
import util from '@ohos.util';
import { MarkDataGroup, RecordData } from '@ohos/common/src/main/ets/model/RecordData';
import { ConfigData } from '@ohos/common/src/main/ets/utils/ConfigData';
import { BaseViewModel } from '../viewModel/BaseViewModel';

const TAG = 'SoundRecorder_MarkListComponent';

@Component
export struct MarkListComponent {
  private listScroller: ListScroller = new ListScroller();
  private selectedMarkIndex: number = Const.DEFAULT_HIGHLIGHT_INDEX;
  private deleteCount: number = -1;
  private markEnterEffect: TransitionEffect = TransitionEffect.OPACITY
    .combine(TransitionEffect.asymmetric(
      TransitionEffect.opacity(0).animation({ duration: 250, curve: Curve.Sharp }),
      TransitionEffect.opacity(0).animation({ duration: 250, curve: Curve.Sharp })
    ).animation({ curve: curves.interpolatingSpring(0, 1, 328, 36) }))
    .combine(TransitionEffect.asymmetric(
      TransitionEffect.translate({ x: 19 }),
      TransitionEffect.scale({
        x: CommonConstants.SCALING_RATIO_PERCENT_85,
        y: CommonConstants.SCALING_RATIO_PERCENT_85
      }).animation({ curve: Curve.Friction, duration: CommonConstants.DURATION_300 })
    ).animation({ curve: curves.interpolatingSpring(0, 1, 328, 36) }))
  private markEnterEffectFirst: TransitionEffect = TransitionEffect.OPACITY
    .combine(TransitionEffect.asymmetric(
      TransitionEffect.opacity(0).animation({ delay: 250, duration: 250, curve: Curve.Sharp }),
      TransitionEffect.opacity(0).animation({ duration: 200, curve: Curve.Sharp })
    ).animation({ curve: curves.interpolatingSpring(0, 1, 328, 36) }))
    .combine(TransitionEffect.asymmetric(
      TransitionEffect.translate({ x: 19 }),
      TransitionEffect.IDENTITY
    ).animation({ delay: 250, curve: curves.interpolatingSpring(0, 1, 328, 36) }))
  @State isStickyHeaderVisible: boolean = true;
  @State deleteIconAngle: number = 0;

  @StorageProp('navigationMode') navMode: number = 0;
  @Consume sideFolderNameFlag: number;
  /**
   * 标记列表
   */
  @ObjectLink markList: MarkDataGroup;
  /*
   * 标记按钮透明度，0.4表示标记按钮不可用，1表示标记按钮可用
   * */
  @Link markOpacity: number;
  /*
   * avplayer或者avrecorder状态，只有录制中或者播放中可以添加标记
   * */
  @Prop state: string;
  /*
   * page页面名称
   * */
  @Prop page: string;
  /*
  * 当前焦点录音
  * */
  @Prop focusRecord: RecordData;
  /*
   * 当前播放到的位置，当播放到的位置大于标记时间时，高亮标记
   * */
  @Link @Watch('onCurrentPlayTimeChange') currentTimePlay: number;
  @StorageProp('isLtr') @Watch('onLangDirectionChange') isLtr: boolean = Configuration.getLocale().dir === 'ltr';
  @State isInsertMarkFlag: boolean = false;
  @StorageLink('RecordTranslateState') recordTransState: boolean = false;
  @StorageLink('RecordBindSheet') isShowRecord: boolean = false;
  @StorageLink('addFirstTag') addFirstTag: boolean = false;
  @StorageLink('recordPlayMarkListHeightOpen') recordPlayMarkListHeightOpen: boolean = false;
  @StorageLink('recordingMarkListHeightOpen') recordingMarkListHeightOpen: boolean = false;

  private onCurrentPlayTimeChange() {
    // Seek到标记点后再次收到回调的时间与seek（标记）的时间点有误差，减去300ms去除误差
    let highLightItem =
      this.markList.content.getAll().findIndex(item => this.currentTimePlay < item.markDuration - 300) - 1;
    if (highLightItem === -2) {
      highLightItem = this.markList.content.getAll().length - 1;
    }
    if (highLightItem === this.selectedMarkIndex || highLightItem === Const.DEFAULT_HIGHLIGHT_INDEX) {
      if (highLightItem === Const.DEFAULT_HIGHLIGHT_INDEX && this.markList.content.getAll().length > 0) {
        this.scrollToIndex(0, false);
      }
      // 双屏，先录音后跳转回播放详情页时，selectedMarkIndex会“记住”最后一个Index，导致标记高亮异常
      if (this.selectedMarkIndex !== highLightItem) {
        LogUtil.warn(TAG + ': reset last selected mark index. ' + this.selectedMarkIndex + ', ' + highLightItem)
        if (this.markList.content.getData(this.selectedMarkIndex)?.isSelect) {
          animateTo({ duration: 150, curve: Curve.Sharp }, () => {
            this.markList.content.getData(this.selectedMarkIndex).isSelect = false;
          })
        }
        this.selectedMarkIndex = highLightItem;
      }
      return;
    }
    LogUtil.info(TAG + ' unset high light item: ' + this.selectedMarkIndex);
    if (this.selectedMarkIndex !== Const.DEFAULT_HIGHLIGHT_INDEX &&
      this.selectedMarkIndex < this.markList.content.getAll().length) {
      animateTo({ duration: 150, curve: Curve.Sharp }, () => {
        this.markList.content.getData(this.selectedMarkIndex).isSelect = false;
      })
    }
    LogUtil.info(TAG + ' set high light item: ' + highLightItem);
    if (this.markList.content.getAll().length > 0) {
      this.scrollToIndex(highLightItem, true);
    }
    animateTo({ duration: 150, curve: Curve.Sharp }, () => {
      this.markList.content.getData(highLightItem).isSelect = true
    })
    this.selectedMarkIndex = highLightItem;
  }

  private getInsertMarkCount() {
    let maxCount = 0;
    this.markList.content.getAll().forEach(item => maxCount = item.count > maxCount ? item.count : maxCount);
    return maxCount + 1;
  }

  private async insertMarkToDb(mark: MarkData): Promise<number> {
    let markValueBucket: relationalStore.ValuesBucket = {
      'id': util.generateRandomUUID(true),
      'type': mark.type,
      'time_in_session': mark.markDuration,
      'content': mark.title,
      '_data': mark._data,
      'countNum': mark.count,
    };
    LogUtil.info(TAG + ' insertMarkToDb start.');
    return await DatabaseManager.insertTag(markValueBucket);
  }

  private async deleteMarkFromDb(mark: MarkData): Promise<number> {
    return await DatabaseManager.deleteTag(mark._data, mark.markDuration);
  }

  private insertMarkCallback = (filePath: string, obj: number, isTransferData?: boolean) => {
    LogUtil.info(TAG + `insertMarkCallback:${this.page}---${this.isShowRecord}`)
    if (this.page === 'RecordPlayPage' && this.isShowRecord) {
      LogUtil.error(TAG + ' callback is RecordPlayPage, but now displayed page is RecordingPage.');
      return;
    }
    if (this.markList === undefined) {
      LogUtil.error(TAG + ' insertMark error mark list is undefined.');
      return;
    }
    this.markList.content.getAll().forEach(item =>
    animateTo({ duration: 150, curve: Curve.Sharp }, () => {
      item.isSelect = false
    })
    );
    let data = new MarkData(getContext(this)
      .resourceManager
      .getStringSync($r('app.string.mark')), this.currentTimePlay, this.getInsertMarkCount(), true, '0', 1, this.focusRecord?._data);
    data._data = filePath;
    this.deleteCount = -1;
    data.isSelect = true;
    let validMarkIndex: number;
    if (obj === undefined) {
      // insert mark for recording, just need to meet mark time interval large than 1 second;
      LogUtil.info(TAG + ' insert mark at top when recording.');
      validMarkIndex = 0;
      setTimeout(() => {
        this.markOpacity = this.state === 'started' ? 1 : 0.4
      }, 1000);
    } else {
      validMarkIndex = obj;
      this.selectedMarkIndex = validMarkIndex;
      LogUtil.info(TAG + ' when record playing insert mark at validMarkIndex: ' + validMarkIndex);
    }

    setTimeout(() => {
      // 滚动到新增标记的位置
      if (this.page === 'RecordPlayPage') {
        this.scrollToIndex(validMarkIndex, true);
      }
    }, this.markList.content.getAll().length === 0 ? 0 : CommonConstants.TIME_180);
    if (this.markList.content.getAll().length === 0) {
      this.addFirstTag = true;
    }
    animateTo({
      duration: 800,
      curve: curves.springCurve(0, 1, 328, 36),
    }, () => {
      let insertMarkIndex: number = validMarkIndex;
      if (this.page === 'RecordingPage') {
        insertMarkIndex = this.markList.content.getAll().length;
      }
      this.markList.content.insertItem(data, insertMarkIndex);
      BaseViewModel.getInstance().setMarkList('SoundRecorder_RecordingPage', this.markList);
      LogUtil.info(TAG + ` this.page:${this.page}`);
      this.page === 'RecordingPage' ? this.recordingMarkListHeightOpen = true :
        this.recordPlayMarkListHeightOpen = true;
    })
    let quickTagName = HiSysEventName.ADD_QUICK_TAG;
    if (this.page === 'RecordPlayPage') {
      quickTagName = isTransferData ? HiSysEventName.TEXT_ADD_TAG : HiSysEventName.ADD_QUICK_TAG_PLAYBACK;
    }
    this.insertMarkToDb(data).then((value) =>{
      LogUtil.info(TAG + ' Inserting the tag succeeded. The ID is: ' + value);
      HiSysEventUtil.eventDotting(
        quickTagName,
        isTransferData ? { SUCCESS: CommonConstants.SUCCESS } :
          { VALUE: CommonConstants.SUCCESS, FROM: DFXEnumConstants.AddTagSource.IN_APP}
      );
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` Failed to insert the tag. code: ${err?.code}, message: ${err?.message}`);
      HiSysEventUtil.eventDotting(
        quickTagName,
        isTransferData ? { SUCCESS: CommonConstants.FAILURE } :
          { VALUE: CommonConstants.FAILURE, FROM: DFXEnumConstants.AddTagSource.IN_APP}
      );
    });
    getContext(this).eventHub.emit('insertMarkDone', data);
  }

  private deleteMarkCallback = (markDuration: number) => {
    let index = this.markList.content.getAll().findIndex(item => item.markDuration === markDuration);
    LogUtil.info(`${TAG} list length: ${this.markList.content.getAll()
      .length},delete index: ${index}, mark time: ${markDuration}`);
    if (index !== -1) {
      this.deleteMarkFromDb(this.markList.content.getData(index))
      getContext(this)?.eventHub?.emit('deleteMarkDone', this.markList.content.getData(index));
      // 删除的标记小于高亮的标记，则高亮的标记下表 -1
      if (index < this.selectedMarkIndex) {
        this.selectedMarkIndex--;
      } else if (index === this.selectedMarkIndex) {
        LogUtil.info(TAG + ' deleteMarkCallback selectedMarkIndex is deleted : ' + this.selectedMarkIndex)
        this.selectedMarkIndex = Const.DEFAULT_HIGHLIGHT_INDEX;
      }
    } else {
      LogUtil.info(TAG + ' no mark to delete.');
    }
    if (index !== Const.DEFAULT_HIGHLIGHT_INDEX) {
      animateTo({
        delay: this.markList.content.getAll().length === 1 ? 0 : 100, // 删除最后一个元素时，无需delay，防止进度条往下移动
        curve: curves.interpolatingSpring(0, 1, 131, 23)
      }, () => {
        if (this.deleteCount < this.markList.content.getData(index).count) {
          this.deleteCount = this.markList.content.getData(index).count;
        }
        LogUtil.info(TAG + `deleteItemByIndex start.`);
        this.markList.content.deleteItemByIndex(index);
        BaseViewModel.getInstance().setMarkList('SoundRecorder_RecordingPage', this.markList);
        if (this.markList.content.getAll().length === 0) {
          this.deleteCount = -1;
          this.page === 'RecordingPage' ? this.recordingMarkListHeightOpen = false :
            this.recordPlayMarkListHeightOpen = false;
        }
        // 删除标记后，可重新在同位置上添加标记，所以将标记按钮透明度置为1
        if (markDuration === this.currentTimePlay) {
          this.markOpacity = 1;
        }
      })
    }
  }

  /**
   * 列表滚动到指定位置
   *
   * @param index
   * @param smooth
   */
  private scrollToIndex(index: number, smooth: boolean): void {
    this.listScroller.scrollToIndex(index, smooth, ScrollAlign.AUTO);
  }

  private scrollTo(index: number, smooth: boolean): void {
    let offset: number = (76 + 12) * index;
    this.listScroller.scrollTo({ xOffset: offset, yOffset: 0, animation: smooth });
  }

  aboutToAppear() {
    LogUtil.info(TAG + ' aboutToAppear.');
    getContext(this)?.eventHub?.on('insertMark', this.insertMarkCallback);
    getContext(this)?.eventHub?.on('deleteMark', this.deleteMarkCallback);
  }

  aboutToDisappear() {
    LogUtil.info(TAG + ' aboutToDisappear.');
    AppStorage.setOrCreate('isTouchMarkList', false);
    getContext(this)?.eventHub?.off('insertMark', this.insertMarkCallback);
    getContext(this)?.eventHub?.off('deleteMark', this.deleteMarkCallback);
  }

  build() {
    Stack() {
      List({
        initialIndex: 0, space: 12, scroller: this.listScroller
      }) {
        LazyForEach(this.markList.content, (item: MarkData, index: number) => {
          this.markItem(item, index)
        }, (item: MarkData) => `${item.count}-${item.markDuration}-${item.createTime}`)
      }
      .width('100%')
      .height($r('app.float.wh_value_40'))
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true }) // 边缘效果设置为Spring
      .align(Alignment.Top)
      .listDirection(Axis.Horizontal)
      .onTouch((event: TouchEvent) => {
        if (event.type === TouchType.Down) {
          AppStorage.setOrCreate('isTouchMarkList', true);
        } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
          AppStorage.setOrCreate('isTouchMarkList', false);
        }
      })
      .onScrollStart(() => {
        AppStorage.setOrCreate('isTouchMarkList', true);
      })
      .onScrollStop(() => {
        AppStorage.setOrCreate('isTouchMarkList', false);
      })
    }
    .alignContent(Alignment.Start)
  }

  @Builder
  private markItem(item: MarkData, index: number) {
    ListItem() {
      MarkComponent({
        item: item,
        page: this.page,
        currentTimePlay: this.currentTimePlay,
        index: index
      })
    }
    .transition(index === 0 && this.markList.content.getAll().length === 1 ? this.markEnterEffectFirst :
    this.markEnterEffect)
    .id(`markListOf${item.id}`)
    .borderRadius($r('app.float.wh_value_20'))
    .clip(true)
    .onDisAppear(() => {
      LogUtil.info(TAG + `onDisAppear:${item.title}`)
    })
    .id(`markListOf${item.id}`)
  }

  onLangDirectionChange(): void {
    LogUtil.info(TAG + ' closeAllSwipeActions.');
    try {
      this.listScroller.closeAllSwipeActions();
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG + ' button cancel onClick closeAllSwipeActions error ' + message);
    }
  }
}