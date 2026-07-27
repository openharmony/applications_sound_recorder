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

// 波形组件
import {
  CommonConstants,
  DeviceUtil,
  LogUtil,
  Preferences,
  PreferencesUtil,
  Props,
  Util,
  HiSysEventName,
  HiSysEventUtil,
  RecordData
} from '@ohos/common';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import statfs from '@ohos.file.statvfs';
import common from '@ohos.app.ability.common';
import { CommonConstants as Const } from '@ohos/common/src/main/ets/constants/CommonConstants';
import { RecorderState } from '../enums/RecorderState';
import { WaveCommand, WaveView } from './WaveView';
import { media } from '@kit.MediaKit';
import { RecordManager } from '../controller/RecordManager';
import { MarkDataGroup } from '@ohos/common/src/main/ets/model/RecordData';

export interface LongPressMsg {
  isLongPress: boolean;
  mCurTime: number;
}

const TAG: string = 'SoundRecorder_Wave';
const INVALID_TIMER = -1;

@Component
export struct Wave {
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @Prop duration: number = 0 // 播放视频时总时长
  @Prop @Watch('curTimeChange') currentTimePlay: number // 播放视频时，视频当前进度时长
  @Prop @Watch('stateChange') recordState: string = 'stopped'
  @StorageProp('screenShowState') screenShowState: string = Const.SCREEN_FULL;
  @StorageLink('screenWidthSplitState') screenWidthSplitState: string = Const.SCREEN_WIDTH_FULL;
  @Prop avType: string = 'record' // 区分波形图组件类型，是录制时还是播放时，【'record', 'play'】分别表示录音，播放
  @State timerId: number = 0 // 时间定时器ID，为整数
  @Link @Watch('updateMark') markList: MarkDataGroup;
  @State estimatedDuration: ResourceStr = '' // 预估录音还能录制的时间长度， 根据剩余空间计算。音频文件大小 = 音频采样率 * 声道数 * 位数
  @Link recordWaveList: number[];
  @State waveTimerHeight: number = this.markList.content.getAll().length ? 76 : 100 // 波形图计时组件区总高
  @State scheduleHeight: number = this.markList.content.getAll().length ? 35 : 44 // 时间刻度区高度
  @State timerFontSize: number = this.markList.content.getAll().length ? 32 : 56 //
  @State timerBigFontHeight: number = this.markList.content.getAll().length ? 43 : 63
  @State topPadding: number = 8
  @State canvasH: number = this.markList.content.getAll().length ? 186 : 304 // 画布组件高度
  @State startOffsetX: number = 0 // 手势事件中初始位置，然后用手势滑动最新位置宽度减去该值得到移动总宽，计算出波形图移动范围
  @State gestureStartTime: number = 0 // 记录手势触发时的时间
  @State isLongPress: boolean = false // 是否长按波形图标记
  @State hasMark: boolean = false // 是否有标记
  @State calcTimerId: number = 0
  @State diskSpace: number = 0
  @State leftMinute: number = 0 // 预估剩余时间
  @State currentMinute: number = 0 // 录制时间
  @State filesDir: string = '/' // 文件空间目录
  @State tempEstimateHour: number = 0
  @State waveHeight: number = this.markList.content.getAll().length ? 262 : 408;
  @StorageLink('WindowStatusType') windowStatusType: number = 1;
  @StorageLink('windowHeight') @Watch('onWindowHeightChange') windowHeight: number = 0;
  @StorageLink('screenHeight') screenHeight: number = 0;
  @State timerFontSize1: number = 30;
  @State timerBigFontHeight1: number = 40;
  @State waveTimerHeight1: number = 64;
  @State timerBigFontHeight2: number = 28;
  @State waveMoveTime: number = 0;
  @Consume waveCommand: WaveCommand;
  @Prop contentHeight: number;
  @State speed: media.PlaybackSpeed = media.PlaybackSpeed.SPEED_FORWARD_1_00_X;
  @StorageProp(Props.IS_IN_BACKGROUND) isInBackground: boolean = false;
  @StorageLink('addFirstTag') addFirstTag: boolean = false;
  @State waveCardHeightRecord: number = 0;
  @State @Watch('waveCardHeightChange') waveCardHeight: number | string = 'auto';
  @State waveLayoutWeight: number | null = 1;
  @State voiceEnhanced: boolean = false;
  @StorageProp('screenLandscapeExpandedHalf') screenLandscapeExpandedHalf: boolean = false;
  @StorageLink('fontSizeScale') fontSizeScale: number = CommonConstants.TEXT_SIZE_NORMAL;
  @StorageProp('isSmallFoldVer') isSmallFoldVer: boolean = false;
  @State isRecordToTextShowTips: boolean = false;
  @Consume @Watch('onIsShowQuickTransChange') isShowQuickTrans: boolean;
  @StorageLink('isAgreeQuickTrans') isAgreeQuickTrans: boolean = false;
  @Consume focusRecord: RecordData;
  @State progressTimeMaxFontSize: number = 24;
  @State durationTimeMaxFontSize: number = 12;
  @StorageLink('isSmallFoldSplit') isSmallFoldSplit: boolean = false;
  @State isFirstRecord: boolean = false;
  @State isFirstTimer: number = INVALID_TIMER;
  private convertIconEffect: TransitionEffect =
    TransitionEffect.asymmetric(
      TransitionEffect.opacity(1).animation({ duration: 150, curve: Curve.Sharp }),
      TransitionEffect.IDENTITY
    )

  async aboutToAppear() {
    this.voiceEnhanced = await PreferencesUtil.get(Preferences.VOICE_ENHANCEMENT, false) as boolean;
    this.hasMark = this.markList.content.getAll().length ? true : false
    this.timerFn()
    const context = getContext(this) as common.UIAbilityContext
    this.filesDir = context.filesDir + '/';
    this.availableRecord()
    this.calcTimer();
    this.refreshMaxFontSize();
    this.isFirstTimer = setTimeout(() => {
      this.setFirstPop();
      this.isFirstTimer = INVALID_TIMER;
    }, 350);
  }

  /* instrument ignore next */
  onIsShowQuickTransChange() {
    LogUtil.info(TAG + ' isShowQuickTrans:' + this.isShowQuickTrans);
    this.refreshMaxFontSize();
  }

  /* instrument ignore next */
  refreshMaxFontSize() {
    if (this.isShowQuickTrans || this.isSmallFoldSplit) {
      this.progressTimeMaxFontSize = 18;
      this.durationTimeMaxFontSize = 10;
    } else {
      this.progressTimeMaxFontSize = 24;
      this.durationTimeMaxFontSize = 12;
    }
  }

  waveCardHeightChange() {
    LogUtil.info(`waveCardHeightChange:${this.waveCardHeight}`);
  }

  async availableRecord() {
    try {
      this.diskSpace = await statfs.getFreeSize(this.filesDir);
      const leftSpace: number = this.diskSpace / 1024 / 1024 - this.currentMinute * Const.SIZE_PER_MINUTE;
      this.leftMinute = leftSpace / 2 / Const.SIZE_PER_MINUTE;
      LogUtil.info(`${TAG} availableRecord leftMinute is : ${this.leftMinute}`);
      this.tempEstimateHour = this.leftMinute / Const.SIXTY_MINUTE;
      if (this.leftMinute < Const.SIXTY_MINUTE && this.leftMinute > Const.THIRTY_MINUTE) {
        this.estimatedDuration = $r('app.string.less_than_60');
      } else if (this.leftMinute < Const.THIRTY_MINUTE) {
        // 如果剩余时间小于30分钟，需要停止录音并保存，给出提示信息
        Util.showToast($r('app.string.stop_save'), DeviceUtil.isPC(), this.isInBackground);
        setTimeout(() => RecordManager.getInstance().release(), 1500);
      } else {
        let tempShowHour: string = '';
        if (this.tempEstimateHour > 0 && this.tempEstimateHour.toString().includes('.')) {
          tempShowHour = this.tempEstimateHour.toString().split('.')[0];
        } else {
          tempShowHour = this.tempEstimateHour.toString();
        }
        if (this.tempEstimateHour > 10) {
          this.estimatedDuration = $r('app.string.predict_hint', 10);
        } else if (this.tempEstimateHour >= 1 && this.tempEstimateHour <= 10) {
          this.estimatedDuration = $r('app.plural.predict_hint_plural', Number(tempShowHour), tempShowHour);
        }
      }
    } catch (err) {
      LogUtil.error(`${TAG} failed in availableRecord is : ${err.message}`);
    }
  }

  calcTimer() {
    if (this.calcTimerId) {
      clearInterval(this.calcTimerId)
    }
    this.calcTimerId = setInterval(() => {
      this.currentMinute += 2
      this.availableRecord()
    }, 120000)
  }

  clearCalcTimer() {
    clearInterval(this.calcTimerId)
  }

  onWindowHeightChange() {
    if (this.windowHeight / this.screenHeight == 5 / 6) {
      this.timerFontSize1 = 38
      this.timerBigFontHeight1 = 51
      this.waveTimerHeight1 = 104
      this.timerBigFontHeight2 = 43
    } else if (this.windowHeight / this.screenHeight > 2 / 3 && this.windowHeight / this.screenHeight < 5 / 6) {
      this.timerFontSize1 = 38 - ((this.screenHeight / 6) * 5 - this.windowHeight) / 60
      this.timerBigFontHeight1 = 51 - ((this.screenHeight / 6) * 5 - this.windowHeight) / 40
      this.waveTimerHeight1 = 104 - ((this.screenHeight / 6) * 5 - this.windowHeight) / 11
      this.timerBigFontHeight2 = 43 - ((this.screenHeight / 6) * 5 - this.windowHeight) / 45
    } else if (this.windowHeight / this.screenHeight > 0.46 && this.windowHeight / this.screenHeight < 2 / 3) {
      this.timerFontSize1 = 30
      this.timerBigFontHeight1 = 40
      this.waveTimerHeight1 = 64
      this.timerBigFontHeight2 = 33 - ((this.screenHeight / 3) * 2 - this.windowHeight) / 130
    } else {
      this.timerFontSize1 = 0
      this.timerBigFontHeight1 = 0
      this.waveTimerHeight1 = 19
      this.timerBigFontHeight2 = 25
    }
    this.refreshMaxFontSize();
  }

  updateMark() {
    this.hasMark = this.markList.content.getAll().length ? true : false;
    this.waveCommand = WaveCommand.MARK;
  }

  aboutToDisappear() {
    this.waveCommand = WaveCommand.RESET;
    if (this.calcTimerId) {
      clearInterval(this.calcTimerId);
    }
    PreferencesUtil.put(Preferences.IS_FIRST_RECORD, false);
    if (this.isFirstTimer !== INVALID_TIMER) {
      clearTimeout(this.isFirstTimer);
    }
  }

  stateChange() {
    if (this.recordState === 'paused' || this.recordState === 'stopped' || this.recordState === 'released') {
      this.clearCalcTimer()
      this.waveCommand = WaveCommand.STOP;
    }
    if (this.recordState === 'started') {
      if (!this.calcTimerId) {
        this.calcTimer()
      }
      this.waveCommand = WaveCommand.START;
    }
  }

  // 当前播放进度时间监听
  curTimeChange() {
    this.performance()
  }

  performance() {
    if (0 < this.currentTimePlay % 300000 && this.currentTimePlay % 300000 < 120) {
      this.clearCalcTimer()
      this.calcTimer()
      this.clearWaveTimer()
      this.timerFn()
    }
  }

  private async transButtonClickEvent() {
    this.isShowQuickTrans = !this.isShowQuickTrans;
    LogUtil.info(TAG + ' click Transcription button:' + this.isShowQuickTrans);
    // 记录转写开关状态
    await PreferencesUtil.put(Preferences.IS_QUICK_TRANS, this.isShowQuickTrans);
    HiSysEventUtil.eventDotting(HiSysEventName.ENTER_RECORD_TEXT_PAGE, { VALUE: Number(this.isShowQuickTrans) });
    if (this.isFirstRecord) {
      this.isFirstRecord = false;
      PreferencesUtil.put(Preferences.IS_FIRST_RECORD, false);
    }
    HiSysEventUtil.eventDotting(HiSysEventName.ENTER_TEXT_PAGE, { FILEID: this.focusRecord.date });
  }

  async timerFn() {
  }

  clearWaveTimer() {
    clearInterval(this.timerId)
  }

  build() {
    Flex({
      wrap: FlexWrap.NoWrap,
      direction: FlexDirection.Column,
      justifyContent: FlexAlign.SpaceBetween
    }) {
      RelativeContainer() {
        // times
        Flex({
          wrap: FlexWrap.NoWrap,
          direction: FlexDirection.Column,
          justifyContent: FlexAlign.Center,
          alignItems: ItemAlign.Center
        }) {
          this.ProgressRecordTime()
          this.EstimatedRecordTime()
        }
        .alignRules({
          top: { anchor: '__container__', align: VerticalAlign.Top },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
      }
      .flexGrow(10)
      .height('34%')

      WaveView({
        recorderState: this.avType == 'record' ? RecorderState.RECORD : RecorderState.PLAY,
        markTimeArray: this.markList,
        waveDragTime: this.waveMoveTime,
        audioCountdownTime: this.currentTimePlay,
        mediaSpeed: this.speed
      })
    }
    .clip(true)
    .borderRadius(20)
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.comp_background_list_card'))
  }

  @Builder
  ProgressRecordTime() {
    Text(Util.timeFormatMs(this.currentTimePlay || 0))
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .minFontSize(18)
      .maxFontSize(this.progressTimeMaxFontSize)
      .maxFontScale(1.15)
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Bold)
      .opacity(0.9)
      .fontFeature('\"ss01\" on')
      .accessibilityText(AccessibilityUtil.getDurationText(this.currentTimePlay))
      .id('progressRecordTime')
  }

  @Builder
  EstimatedRecordTime() {
    Text(this.estimatedDuration)
      .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      .minFontSize(10)
      .maxFontSize(this.durationTimeMaxFontSize)
      .fontFamily('HarmonyHeiTi')
      .fontWeight(FontWeight.Medium)
      .id('estimatedRecordTime')
      .maxFontScale(DeviceUtil.isPC() ? CommonConstants.TEXT_SIZE_HUGE_LEVEL3 : 0)
  }

  async setFirstPop() {
    this.isFirstRecord = await PreferencesUtil.get(Preferences.IS_FIRST_RECORD, true) as boolean;
  }
}
