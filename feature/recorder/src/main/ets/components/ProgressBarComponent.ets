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
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { PlayManager } from '../controller/PlayManager';
import { Configuration } from '@kit.ArkUI';
import { TransferData } from '@ohos/common/src/main/ets/model/TransferData';

const TAG = 'SoundRecorder_ProgressBarComponent';

@Component
export struct ProgressBarComponent {
  private isSeeking: boolean = false;
  private lastSeekPosition: number = -1;
  @State timeToShow: number = 0;
  @Prop @Watch('onCurrentTimePlayChange') currentTimePlay: number = 0;
  @Prop duration: number = 0;
  @StorageLink('WindowStatusType') windowStatusType: number = 1;
  @StorageLink('RecordTranslateState') recordTransState: boolean = false;
  @StorageLink('isPortrait') isPortrait: boolean = true;
  @Prop transferData: TransferData | undefined = undefined;

  private onCurrentTimePlayChange(): void {
    const player = PlayManager.getInstance();
    LogUtil.info(`${TAG} onCurrentTimePlayChange: ${this.currentTimePlay}, timeToShow: ${this.timeToShow}, player.getSpeedValue: ${player.getSpeedValue()}`);
    if (this.isSeeking) {
      LogUtil.info(TAG + ' do not update currentTimePlay because is seeking');
      return;
    }
    // 当前播放时间和进度条显示时间同时大于0说明非初始也非播放完成重新播放
    // 进度条显示时间大于当前播放时间，说明返回的数据异常。 大于1是因为seek的时候，进度条的数据为计算值，会有小数，大于当前播放时间且小于1
    if (this.currentTimePlay > 0 && this.timeToShow > 0 &&  (this.timeToShow - this.currentTimePlay) > 1 ) {
      LogUtil.info(TAG + ' The time returned by AVPlayer is less than the previous time.');
      return;
    }
    if (this.currentTimePlay === 0) {
      LogUtil.info(TAG + ' New playback progress.');
      this.timeToShow = 0;
      return;
    }
    if (this.duration < 2 * 60 * 1000) {
      animateTo({ curve: Curve.Linear, duration: 100 }, () => this.timeToShow = this.currentTimePlay);
      return;
    }
    if (this.currentTimePlay - this.timeToShow >= 1000 || this.currentTimePlay === this.duration) {
      LogUtil.error(TAG + ' update progress per 1000ms to reduce power dissipation.');
      this.timeToShow = this.currentTimePlay;
    }
  }

  private seekDoneCallback = (seekDoneTime: number) => {
    LogUtil.info(`${TAG} seekDoneTime: ${seekDoneTime}, lastSeekPosition: ${this.lastSeekPosition}`);
    if (!this.isSeeking && this.lastSeekPosition === -1) {
      LogUtil.info(`${TAG} isSeeking=false but seekDone triggered means do seek operate from other component but not progress bar.`);
      this.timeToShow = seekDoneTime;
      return;
    }
    this.lastSeekPosition = Math.min(this.lastSeekPosition, this.duration);
    if (Math.abs(this.lastSeekPosition - seekDoneTime) < 100) {
      LogUtil.info(`${TAG} seekDone isSeeking false.`);
      this.isSeeking = false;
      this.lastSeekPosition = -1;
    }
  }

  aboutToAppear(): void {
    LogUtil.info(`${TAG} aboutToAppear.`);
    this.timeToShow = this.currentTimePlay;
    getContext().eventHub.on('seekDone', this.seekDoneCallback);
  }

  aboutToDisappear(): void {
    LogUtil.info(`${TAG} aboutToDisappear.`);
    getContext().eventHub.off('seekDone', this.seekDoneCallback);
  }

  private computeValue(): number {
    if (this.timeToShow > 0 && this.duration > 0) {
      return this.timeToShow / this.duration * 100;
    }
    return 0;
  }

  build() {
    Column() {
      Row() {
        Slider({
          value: this.computeValue(),
          min: 0,
          max: 100,
          style: SliderStyle.OutSet,
          step: 1
        })
          .direction(Configuration.getLocale().dir === 'rtl' ? Direction.Rtl : Direction.Ltr)
          .blockColor($r('app.color.red'))
          .blockSize({ width: 12, height: 12 })
          .selectedColor($r('app.color.red'))
          .trackColor($r('sys.color.ohos_id_color_component_normal'))
          .showSteps(false)
          .showTips(false)
          .trackThickness(4)
          .id('progressSlider')
          .responseRegion({
            x: 0,
            y: '-100%',
            width: '100%',
            height: '300%'
          })
          .onChange((value: number, mode: SliderChangeMode) => {
            LogUtil.info(TAG + ' onChange of slider trigger value: ' + value + ' mode: ' + mode);
            if (mode === SliderChangeMode.Begin) {
              this.isSeeking = true;
              AppStorage.setOrCreate('isTouchProgressBar', true);
            }
            this.timeToShow = value * this.duration / 100;
            if (mode === SliderChangeMode.End && this.isSeeking) {
              LogUtil.info(TAG + ' click slider end seek to: ' + this.timeToShow);
              this.lastSeekPosition = this.timeToShow;
              PlayManager.getInstance().seek(this.timeToShow);
              if (this.recordTransState && this.transferData) {
                HiSysEventUtil.eventDotting(HiSysEventName.TEXT_DRAG_SEEKBAR);
              } else {
                HiSysEventUtil.eventDotting(HiSysEventName.DRAG_SEEKBAR_PLAY_RECORD);
              }
              AppStorage.setOrCreate('isTouchProgressBar', false);
            }
            AppStorage.setOrCreate('isSeeked', true);
          })
          .margin({ left: -8, right: -8 })
      }
      .width('100%')
      .zIndex(5)
      .height(12)

      Row() {
        Text(Util.timeFormat(this.timeToShow))
          .accessibilityText(Util.getFormatStringSync($r('app.string.content_already_played'),
            AccessibilityUtil.getDurationText(this.timeToShow)).replace(/\s+/g, ''))
          .fontColor($r('sys.color.ohos_id_color_bottom_tab_text_off'))
          .fontSize($r('app.float.font_9'))
          .fontFeature('\"ss01\" on')
          .id('playTimeOfProgressText')
          .height($r('app.float.wh_value_12'))
        Text(Util.timeFormat(this.duration | 0))
          .accessibilityText(AccessibilityUtil.getTotalDurationText(this.duration))
          .fontColor($r('sys.color.ohos_id_color_bottom_tab_text_off'))
          .fontSize($r('app.float.font_9'))
          .fontFeature('\"ss01\" on')
          .id('durationOfProgressText')
          .height($r('app.float.wh_value_12'))
      }
      .width('100%')
      .margin({ top: 5 })
      .zIndex(1)
      .onAppear(() => {
        LogUtil.info(TAG + `this.timeToShow: ${this.timeToShow}, this.duration: ${this.duration}`)
      })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
    .height(28)
    .draggable(false)
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        AppStorage.setOrCreate('isTouchProgressBar', true);
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        AppStorage.setOrCreate('isTouchProgressBar', false);
      }
    })
  }
}