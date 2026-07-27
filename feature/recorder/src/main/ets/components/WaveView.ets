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

// 波形图组件
import { ArrayList } from '@kit.ArkTS';
import { displaySync } from '@kit.ArkGraphics2D';
import media from '@ohos.multimedia.media';
import { RecorderState } from '../enums/RecorderState';
import { PlayManager } from '../controller/PlayManager';
import {
  CommonConstants,
  DeviceUtil,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  MarkData,
  Props,
  Util
} from '@ohos/common';
import { Configuration, display } from '@kit.ArkUI';
import SampleUtil, { SampleDataConstant } from '@ohos/common/src/main/ets/utils/SampleUtil';
import { MarkDataGroup } from '@ohos/common/src/main/ets/model/RecordData';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { RecordManager } from '../controller/RecordManager';
import RecordStateManager from '../audiokit/manager/RecordStateManager';


export const DATA_TIME_INTERVAL: number = 160;

const EXPECTED_FPS: number = 20;
const HIGH_EXPECTED_FPS: number = 120;
const OFFSET_PER_SECOND: number = 30;
const SCALES_PRE_SECOND: number = 2;
const DIFF_TIME_ALLOW: number = 433; // 允许的录音时间与波形图时间的最大误差值
const DEFAULT_MANUAL_SETUP_SPEED: number = -1;
const MANUAL_SETUP_SPEED_THRESHOLD: number = 0.25;

// 每秒多少根波形线条
export const LINES_PRE_SECOND: number = SampleDataConstant.SAMPLES_PRE_SECOND;

const SCALE_SPACE: number = OFFSET_PER_SECOND / SCALES_PRE_SECOND;
const LINE_SPACE: number = OFFSET_PER_SECOND / LINES_PRE_SECOND;

/**
 * 波形图控制指令
 */
export enum WaveCommand {
  START = 'start', PAUSE = 'pause', STOP = 'stop', RESET = 'reset', SYNC = 'sync',
  MARK = 'mark', FORM_PAUSE = 'formPause', NONE = 'none'
}

/**
 * 设备形态
 */
export enum DeviceState {
  PHONE = 'phone',
  FOLDED = 'folded',
  EXPANDED = 'expanded',
  PAD = 'pad',
  PC = 'pc',
}

/**
 * 波形图状态
 *
 * WaveCommand.START  ->  WaveState.PLAYING
 * WaveCommand.STOP   ->  WaveState.STOPED
 * WaveCommand.RESET  ->  WaveState.STOPED
 * WaveCommand.MARK   ->  NA
 * WaveCommand.NONE   ->  NA
 */
enum WaveState { PLAYING, STOPED }

/**
 * 在屏幕外多绘制的线条，防止波形 滚动/滑动 过程中线条渲染不及时
 */
const EXTRA_LINE_COUNT: number = 2;

/**
 * 波形图可以跳过绘制的状态
 */
enum SkipFrameState {
  CANVAS_NOT_READY = 'CANVAS_NOT_READY',
  DRAWING_TOO_FREQUENT = 'DRAWING_TOO_FREQUENT',
  WAVE_STOPED = 'WAVE_STOPED',
  DRAWING_COMPLETED = 'DRAWING_COMPLETED',
  NONE = 'NONE'
}

/**
 * 日志连续且重复打印的允许次数，日志重复打印5次后自动停止Log，节省性能
 */
const SKIP_FRAME_LOG_COUNT: number = 5;

/**
 * 进度条滑动后的全局 Storage
 */
AppStorage.setOrCreate('sliderSeekTo', 0);

const TAG: string = 'SoundRecorder_WaveView';

@Component
export struct WaveView {
  // State
  @StorageProp('isDarkMode') @Watch('updateDarkModeColor') isDarkMode: boolean = false;
  @StorageProp('foldDisplayMode') foldDisplayMode: number = 0;
  @StorageProp(Props.IS_IN_BACKGROUND) @Watch('onBackgroundStatusChange') isInBackground: boolean = false;
  @Prop recorderState: RecorderState = RecorderState.PLAY;
  @State deviceType: string = DeviceState.PHONE;
  @Prop isShowMark: boolean = true;
  @Prop isRecordTrans: boolean = true;
  @State backgroundImageTop: number = 0;
  @Consume @Watch('onWaveCommand') waveCommand: WaveCommand;
  @StorageLink('isPortrait') isPortrait: boolean = true;
  @Link waveDragTime: number;
  private waveState: WaveState = WaveState.STOPED;
  // Time
  private waveStartTime: number = Date.now();
  private waveEndTime: number = this.waveStartTime;
  private waveRunningTime: number = this.waveEndTime - this.waveStartTime;
  private drawingDiffTime: number = 0;
  private keepOnDrawTime: number = 0;
  @Prop audioTotalTime: number = 0;
  @Prop @Watch('onAudioTimeChange') audioCountdownTime: number = 0;
  @StorageLink('sliderSeekTo') @Watch('onSliderSeek') sliderSeekTime: number = 0;
  @StorageLink('RecordTranslateState') recordTransState: boolean = false;
  @StorageProp('screenShowState') @Watch('initBaseSize') screenShowState: string = CommonConstants.SCREEN_FULL;
  // Speed
  @Link mediaSpeed: media.PlaybackSpeed;
  // Canvas
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private canvas: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);
  // Size
  private uiCanvasDefaultHeight: number = 284; // 绘制区域高度下限（低于需要绘制背景遮盖层）
  private canvasWidth: number = 0; // canvas总宽度
  private canvasHeight: number = 0; // canvas总高度
  private waveAreaHeight: number = 0; // 波形图绘制区域高度（= 总高度 - 顶部圆形标记高度 - 底部刻度区域高度）
  private uiSmallScaleHeight: number = 5; // 小刻度线条高度
  private uiBigScaleHeight: number = 8; // 大刻度线条高度
  private uiScaleWidth: number = 1; // 刻度线条粗度
  @State uiScaleAreaHeight: number = 25; // 底部刻度区域高度
  private uiIndicatorWidth: number = 2.19; // 指针粗度
  private uiIndicatorCircleDiameter: number = 7; // 指针底部球形直径
  private uiLineWidth: number = 2.5; // 波形图线条粗度
  private uiMarkWidth: number = 2; // 标记线条粗度
  private uiMarkCircleDiameter: number = 12; // 标记顶部球形直径
  private uiMaxLineHeightFactor: number = 0.8; // 波形图最大幅度比例
  private uiMaxLineHeight: number = 0; // 波形图最大幅度高度
  private uiMarkTopLength: number = 1; // 标记顶部圆形超出波形图区域长度
  private uiScaleAreaTextBottom: number = 14; // 刻度文字和canvas底部距离
  // Data
  private waveLineList: ArrayList<number> = new ArrayList();
  @ObjectLink markTimeArray: MarkDataGroup;
  // Offset
  private strictOffset: number = 0;
  private drawingOffset: number = 0;
  private panStartOffset: number = 0;
  private maxDrawLineCount: number = 10;
  // Color
  private colorGray: string = '#aaaaaa';
  private colorBlack: Color = Color.Black;
  private colorWhite: Color = Color.White;
  private uiBigScaleColor: string = '#4d000000';
  private uiBigScaleDarkColor: string = '#4dffffff';
  private uiSmallScaleColor: string = '#1a000000';
  private uiSmallScaleDarkColor: string = '#1affffff';
  private uiIndicatorColor: string = '#FB654E';
  private uiLineEdgeColor: string = '#1a000000';
  private uiLineCenterColor: string = '#40000000';
  private uiLineEdgeDarkColor: string = '#1affffff';
  private uiLineCenterDarkColor: string = '#33ffffff';
  private uiBottomCoverColor: number | string | Color = Color.Transparent;
  private uiWaveGradient?: CanvasGradient;
  // Flag
  private isCanvasReady: boolean = false;
  private isPanGesture: boolean = false;
  private skipFrameCount: number = SKIP_FRAME_LOG_COUNT;
  private skipFrameMark: SkipFrameState = SkipFrameState.NONE;
  private isAudioFileChanged: boolean = false;
  private newRecordFlag: boolean = false;
  private waveToStartWhenNewRecord: boolean = true;
  private simpleLoadingState: boolean = false;
  // Animate
  private waveScale: number = 1;
  private targetCanvasHeight: number = 0;
  // Sync
  private waveDisplaySync?: displaySync.DisplaySync;
  private lowSyncRange: ExpectedFrameRateRange = {
    expected: EXPECTED_FPS,
    min: EXPECTED_FPS,
    max: EXPECTED_FPS
  };
  private highSyncRange: ExpectedFrameRateRange = {
    expected: HIGH_EXPECTED_FPS,
    min: EXPECTED_FPS,
    max: HIGH_EXPECTED_FPS
  }
  private currentSyncRange: ExpectedFrameRateRange = this.lowSyncRange;
  // 镜像矩阵
  private mirrorMatrix: number[] = [-1, 0, 0, 1, 0, 0];
  // Locale
  @StorageProp('isLtr') @Watch('onLangDirectionChange') isLtr: boolean = Configuration.getLocale().dir === 'ltr';
  @StorageProp('isSeeked') @Watch('onSeekedChange') isSeeked: boolean = false;
  @StorageLink('displaySizeScale') displaySizeScale: number = CommonConstants.PAD_DISPLAY_SIZE_SCALE_NORMAL;
  @State isMini: boolean = false;
  @StorageLink('screenWidthSplitState') screenWidthSplitState: string = CommonConstants.SCREEN_WIDTH_FULL;
  @StorageProp('screenLandscapeExpandedHalf') screenLandscapeExpandedHalf: boolean = false;
  private tabletDrawWaveTimer: number = 0;
  private maxMarkNumber = 0;
  @State manualSetupSpeed: number = DEFAULT_MANUAL_SETUP_SPEED;
  @Prop isShowQuickTrans: boolean = true;
  @State isShowWaveView: boolean = true;

  getDeviceType(): string {
    if (DeviceUtil.isPhone()) {
      if (DeviceUtil.isPhoneNotFold()) {
        return DeviceState.PHONE;
      } else {
        if (DeviceUtil.isFolded()) {
          return DeviceState.FOLDED;
        } else {
          return DeviceState.EXPANDED;
        }
      }
    } else if (DeviceUtil.isTabletOrTripleGStatus()) {
      return DeviceState.PAD;
    } else if (DeviceUtil.isPC()) {
      return DeviceState.PC;
    } else {
      return DeviceState.PHONE;
    }
  }

  initBaseSize() {
    LogUtil.info(TAG + ' initBaseSize deviceType: ' + this.deviceType + ' screenShowState: ' + this.screenShowState +
      ' screenWidthSplitState: ' + this.screenWidthSplitState);
    let markCountArray: number[]  = this.markTimeArray.content.getAll().map(item => item.count);
    this.maxMarkNumber = Math.max(...markCountArray);
    this.deviceType = this.getDeviceType();
    this.isShowMark = this.markTimeArray.content.getAll().length > 0 ? true : false;
    this.isMini = false;
    if (this.deviceType === DeviceState.PHONE || this.deviceType === DeviceState.FOLDED) {
      this.uiSmallScaleHeight = 3; // 小刻度线条高度
      this.uiBigScaleHeight = 6; // 大刻度线条高度
      this.uiScaleAreaHeight = this.recorderState === RecorderState.RECORD ? 42 : 32; // 底部刻度区域高度
      this.uiIndicatorCircleDiameter = 8; // 指针底部球形直径
      this.uiScaleAreaTextBottom =
        this.isShowMark ? 14 : this.recorderState === RecorderState.RECORD ? 22 : 16; // 刻度文字和canvas底部距离
      this.uiMarkCircleDiameter = this.isShowMark ? 12 : 9; // 标记顶部球形直径
      if (this.screenShowState === CommonConstants.SCREEN_ONE_THREE) {
        this.uiScaleAreaHeight = 21;
        this.uiScaleAreaTextBottom = 4;
        this.uiMarkCircleDiameter = 9;
        this.isMini = true;
      } else if (this.screenShowState === CommonConstants.SCREEN_HALF) {
        this.uiScaleAreaHeight = 29;
        this.uiScaleAreaTextBottom = 10;
        this.uiMarkCircleDiameter = 12;
        if (DeviceUtil.isLandscape()) {
          this.isMini = true;
        }
      }
    } else if (this.deviceType === DeviceState.EXPANDED) {
      this.uiSmallScaleHeight = 5; // 小刻度线条高度
      this.uiBigScaleHeight = 8; // 大刻度线条高度
      this.uiIndicatorCircleDiameter = 7; // 指针底部球形直径
      this.uiMarkCircleDiameter = this.screenLandscapeExpandedHalf ? 15 : 11; // 标记顶部球形直径
      if (this.screenShowState === CommonConstants.SCREEN_HALF ||
        this.screenWidthSplitState === CommonConstants.SCREEN_WIDTH_HALF) {
        this.uiScaleAreaHeight = this.screenLandscapeExpandedHalf ? 30 : 36;
        this.uiScaleAreaTextBottom = this.screenLandscapeExpandedHalf ? 10 : 16;
      } else {
        this.uiScaleAreaHeight = this.recorderState == RecorderState.RECORD && this.isShowQuickTrans ? 26 :
          this.isRecordTrans ? this.recorderState === RecorderState.PLAY ? 36 : 54 : 55; // 底部刻度区域高度
        this.uiScaleAreaTextBottom = this.recorderState == RecorderState.RECORD && this.isShowQuickTrans ? 8 :
          this.isRecordTrans ? this.recorderState === RecorderState.PLAY ? 16 : 31 : 32; // 刻度文字和canvas底部距离
      }
      if (this.screenShowState === CommonConstants.SCREEN_HALF && this.screenLandscapeExpandedHalf) {
        this.isMini = true;
      }
    } else if (this.deviceType === DeviceState.PAD) {
      this.uiSmallScaleHeight = 5; // 小刻度线条高度
      this.uiBigScaleHeight = 8; // 大刻度线条高度
      this.uiIndicatorCircleDiameter = 7; // 指针底部球形直径
      if (this.screenShowState === CommonConstants.SCREEN_ONE_THREE) {
        this.uiScaleAreaHeight = 36; // 底部刻度区域高度
        this.uiScaleAreaTextBottom = 16; // 刻度文字和canvas底部距离
        this.uiMarkCircleDiameter = 11; // 标记顶部球形直径
      } else if (this.displaySizeScale === CommonConstants.PAD_DISPLAY_SIZE_SCALE_LARGER) {
        this.uiScaleAreaHeight = !this.isRecordTrans ? 45 : 39;
        this.uiScaleAreaTextBottom = !this.isRecordTrans ? 22 : 16;
        this.uiMarkCircleDiameter = 12;
      } else {
        this.uiScaleAreaHeight = this.recorderState == RecorderState.RECORD && this.isShowQuickTrans ? 26 :
          !this.isRecordTrans ? 55 : 39; // 底部刻度区域高度
        this.uiScaleAreaTextBottom = this.recorderState == RecorderState.RECORD && this.isShowQuickTrans ? 8 :
          !this.isRecordTrans ? 32 : 16; // 刻度文字和canvas底部距离
        this.uiMarkCircleDiameter = 12; // 标记顶部球形直径
      }
    } else if (this.deviceType === DeviceState.PC) {
      this.uiSmallScaleHeight = 5; // 小刻度线条高度
      this.uiBigScaleHeight = 8; // 大刻度线条高度
      this.uiScaleAreaHeight = !this.isRecordTrans ? 55 : 36; // 底部刻度区域高度
      this.uiIndicatorCircleDiameter = 7; // 指针底部球形直径
      this.uiScaleAreaTextBottom = !this.isRecordTrans ? 32 : 16; // 刻度文字和canvas底部距离
      this.uiMarkCircleDiameter = 12; // 标记顶部球形直径
    }
    this.backgroundImageTop = this.uiMarkCircleDiameter + this.uiMarkTopLength;
    if (this.screenShowState === CommonConstants.SCREEN_ONE_THREE && this.recordTransState &&
      this.waveState === WaveState.STOPED) {
      // 转写态，从2分之一到3分之一，切换成波形图，在录音暂停的情况下波形图不展示
      setTimeout(() => {
        this.onDraw();
      }, 200);
    }
    this.showWaveView();
  }

  build() {
    Stack() {
      Canvas(this.canvas)
        .id('id_canvas')
        .width('100%')
        .height('100%')
        .onReady(() => {
          let node: FrameNode = this.canvas.canvas;
          node?.commonEvent.setOnVisibleAreaApproximateChange(
            { ratios: [0, 1], expectedUpdateInterval: 10},
            (isVisible: boolean, currentRatio: number) => {
              if (!isVisible && currentRatio <= 0.0) {
                this.isCanvasReady = false;
              } else {
                this.isCanvasReady = true;
                LogUtil.info(TAG + ` isCanvasReady: ${this.isCanvasReady}`);
                this.onDraw();
              }
            }
          )
        })
        .accessibilityText(this.getWaveBroadCastText())
        .gesture(PanGesture()
          .onActionStart(() => {
            if (this.recorderState === RecorderState.RECORD) {
              return;
            }
            this.isPanGesture = true;
            this.panStartOffset = this.drawingOffset
          })
          .onActionEnd(() => this.onPanGestureDone())
          .onActionCancel(() => this.onPanGestureDone())
          .onActionUpdate((event: GestureEvent) => {
            if (this.recorderState === RecorderState.RECORD && !this.isPanGesture) {
              return;
            }
            let offset: number = this.panStartOffset - event.offsetX * (this.isLtr ? 1 : -1);
            this.drawingOffset = Math.min(this.getOffsetEnd(), Math.max(offset, 0));
          })
        )
    }
    .flexShrink(10)
    .onAreaChange((_, newVal) => {
      this.canvasWidth = Number(newVal.width);
      let height: number = Number(newVal.height);
      LogUtil.info(TAG + ': onAreaChange width=' + newVal.width + ', height=' + height);
      this.maxDrawLineCount = Math.ceil(this.canvasWidth / LINE_SPACE + EXTRA_LINE_COUNT);
      this.updateDarkModeColor();
      this.initBaseSize();
      this.computeCanvasHeight(height);
      this.onDraw();
    })
    .onAppear(() => this.onAppearFunc())
    .onDisAppear(() => this.onDisAppearFunc())
    .alignContent(Alignment.TopStart)
    .rotate({
      x: 0,
      y: 1,
      z: 0,
      angle: Configuration.getLocale().dir === 'rtl' ? 180 : 0
    })
    .visibility(this.isShowWaveView ? Visibility.Visible : Visibility.None)
  }

  private getWaveBroadCastText(): string {
    const duration = AccessibilityUtil.getDurationText(this.audioCountdownTime);
    if (this.recorderState === RecorderState.RECORD) {
      return Util.getFormatStringSync($r('app.string.notice_recording'), '', duration).replace(/\s+/g, '');
    } else if (this.recorderState === RecorderState.PLAY) {
      return Util.getFormatStringSync($r('app.string.current_location_time'), duration).replace(/\s+/g, '');
    } else {
      return '';
    }
  }

  /**
   * 语言方向改变后，持续绘制1s，刷新文字显示方向
   */
  onLangDirectionChange(): void {
    LogUtil.info(TAG + ': onLangDirectionChange. isLtr = ' + this.isLtr);
    this.keepOnDraw(1000);
  }

  /**
   * seek期间，波形图暂停播放，收到AVPlayer的时间回调后波形图继续绘制
   */
  onSeekedChange(): void {
    if (this.isSeeked) {
      this.waveCommand = WaveCommand.STOP;
      return;
    }
    if (PlayManager.getInstance().getAVPlayerState() === 'playing') {
      this.waveCommand = WaveCommand.START;
    }
  }

  /**
   * onAppear
   */
  private onAppearFunc(): void {
    LogUtil.info(TAG + ' WaveView onAppearFunc')
    this.registerSamplesListener();
    this.tryStartWaveView();
    this.updateDarkModeColor();
    this.initBaseSize();
  }

  /**
   * onDisAppear
   */
  private onDisAppearFunc(): void {
    LogUtil.info(TAG + ' WaveView onDisAppearFunc')
    this.stopLooper();
  }

  /**
   * 持续绘制
   *
   * @param duration 持续绘制时长，单位毫秒
   */
  private keepOnDraw(duration: number): void {
    LogUtil.info(TAG + ': keepOnDraw ' + duration);
    this.keepOnDrawTime = duration / (1000 / EXPECTED_FPS);
  }

  private computeCanvasHeight(height: number): boolean {
    this.targetCanvasHeight = height;
    this.canvasHeight = this.targetCanvasHeight;
    this.waveAreaHeight = this.canvasHeight - this.uiMarkCircleDiameter -
    this.uiMarkTopLength - this.uiScaleAreaHeight;
    this.uiMaxLineHeight = this.waveAreaHeight * this.uiMaxLineHeightFactor;
    this.waveScale = this.canvasHeight / this.uiCanvasDefaultHeight;
    return true;
  }

  /**
   * 拖动波形图的手势结束时
   */
  private onPanGestureDone(): void {
    LogUtil.info(TAG + ': onPanGestureDone start.');
    if (this.recorderState === RecorderState.RECORD) {
      LogUtil.info(TAG + ': onPanGestureDone cancel.');
      return;
    }
    this.panStartOffset = 0;
    let time: number = this.drawingOffset / OFFSET_PER_SECOND * 1000;
    if (time === this.waveDragTime) {
      // 防止用户两次拖动结束都处于同一个位置，导致State未更新
      time++;
    }
    this.waveDragTime = Math.max(Math.min(this.audioTotalTime + DIFF_TIME_ALLOW, time), 0);
    this.waveEndTime = Date.now();
    this.waveStartTime = this.waveEndTime - this.waveDragTime;
    this.waveRunningTime = this.waveDragTime;
    this.strictOffset = this.waveRunningTime / 1000 * OFFSET_PER_SECOND;
    this.drawingOffset = this.strictOffset;
    // AvPlayer的Seek需要时间，等待300毫秒再启动波形图，防止抖动
    AppStorage.setOrCreate('isSeeked', true);
    setTimeout(() => {
      this.isPanGesture = false;
      let diffTime: number = this.waveDragTime - this.audioCountdownTime;
      HiSysEventUtil.eventDotting(HiSysEventName.MOVE_WAVE_AND_SEEK, { SUCCESS: CommonConstants.SUCCESS });
      if (Math.abs(diffTime) > (CommonConstants.TIME_300 + DIFF_TIME_ALLOW) * this.getSpeed()) {
        LogUtil.info(TAG + ': onPanGestureDone player reSeek. ' + diffTime);
        // 说明State又丢状态了（双屏频繁切换录音+Seek），在这里直接调用player#seek更新播放进度
        PlayManager.getInstance().seek(Math.min(this.audioTotalTime, this.waveDragTime));
      }
    }, CommonConstants.TIME_300);
    LogUtil.info(TAG + ': onPanGestureDone end.');
  }

  /**
   * 深色模式变化时，即使更新颜色属性
   */
  updateDarkModeColor(): void {
    LogUtil.info(TAG + ': updateDarkModeColor start. isDarkMode: ' + this.isDarkMode);
    const uiWaveGradient = this.canvas?.createLinearGradient(0, 0, this.canvasWidth, 0);
    if (this.isDarkMode) {
      uiWaveGradient.addColorStop(0, this.uiLineEdgeDarkColor);
      uiWaveGradient.addColorStop(1, this.uiLineEdgeDarkColor);
      uiWaveGradient.addColorStop(0.5, this.uiLineCenterDarkColor);
    } else {
      uiWaveGradient.addColorStop(0, this.uiLineEdgeColor);
      uiWaveGradient.addColorStop(1, this.uiLineEdgeColor);
      uiWaveGradient.addColorStop(0.5, this.uiLineCenterColor);
    }
    this.uiWaveGradient = uiWaveGradient;
    getContext(this).resourceManager.getColor($r('sys.color.comp_background_list_card').id).then((color) => {
      let bgColor: number = this.isDarkMode ? (DeviceUtil.isPhoneNotFold() ||
        (this.recorderState === RecorderState.RECORD) ||
        (DeviceUtil.isSmallFoldVer() && this.foldDisplayMode !== display.FoldStatus.FOLD_STATUS_FOLDED) ?
        0xff202224 : 0xff000000) : 0xffffffff;
      let mixedColor: string = this.mixColor(bgColor, color);
      this.uiBottomCoverColor = mixedColor;
      this.onDraw();
    });
    LogUtil.info(TAG + ': updateDarkModeColor end.');
  }

  /**
   * 获取两个（带透明度）颜色混合后的颜色
   *
   * @param color1
   * @param color2
   * @returns
   */
  private mixColor(color1: number, color2: number): string {
    LogUtil.info(TAG + ': mixColor start. color1:' + color1.toString(16) + ', color2:' + color2.toString(16));
    let a1: number = (color1 >> 24 & 0xFF) / 255;
    let r1: number = (color1 >> 16 & 0xFF) / 255;
    let g1: number = (color1 >> 8 & 0xFF) / 255;
    let b1: number = (color1 & 0xff) / 255;
    let a2: number = (color2 >> 24 & 0xFF) / 255;
    let r2: number = (color2 >> 16 & 0xFF) / 255;
    let g2: number = (color2 >> 8 & 0xFF) / 255;
    let b2: number = (color2 & 0xff) / 255;
    let a: number = 1 - (1 - a1) * (1 - a2);
    let r: number = (r1 * a1 * (1 - a2) + r2 * a2) / a;
    let g: number = (g1 * a1 * (1 - a2) + g2 * a2) / a;
    let b: number = (b1 * a1 * (1 - a2) + b2 * a2) / a;
    let mixedColor: string = '#' +
    Math.floor(a * 255).toString(16) +
    Math.floor(r * 255).toString(16) +
    Math.floor(g * 255).toString(16) +
    Math.floor(b * 255).toString(16);
    LogUtil.info(TAG + ': mixColor end. mixedColor:' + mixedColor);
    return mixedColor;
  }

  /**
   * 监听录音时间变化，如果与波形图时间相差到一定的值，则需要对齐。（拖动了进度条时）
   */
  onAudioTimeChange(): void {
    if (this.recorderState === RecorderState.PLAY) {
      // 播放结束后重新播放，直接跳转到波形图起始位置
      if (!this.newRecordFlag && this.audioCountdownTime === 0 && this.waveToStartWhenNewRecord) {
        LogUtil.info(TAG + ': onAudioTimeChange set offset 0.');
        this.waveViewSlideToStart();
        this.waveToStartWhenNewRecord = false;
        return;
      }

      const player = PlayManager.getInstance();
      let audioStart = this.audioCountdownTime < CommonConstants.DEVIATION_FOR_AV_PLAYER_START * player.getSpeedValue();
      // 过了播放录音开始阶段
      if (!audioStart) {
        // 标记这不是新的录音了
        this.newRecordFlag = false;
        // 标记如果有新录音，则波形图需要从头开始
        this.waveToStartWhenNewRecord = true;
      }
    }
    this.drawingDiffTime = this.waveRunningTime - this.audioCountdownTime;
    if (this.isDiffTimeAllowed()) {
      // 此时已经不在差值阈值范围内，如果手动设置的速度不是默认值，则恢复默认值
      if (this.manualSetupSpeed !== DEFAULT_MANUAL_SETUP_SPEED) {
        this.manualSetupSpeed = DEFAULT_MANUAL_SETUP_SPEED;
      }
      return;
    }
    if (this.recorderState === RecorderState.RECORD) {
      LogUtil.info(`${TAG} Anomalies in the waveform during recording require correction.`);
      this.proofreadTime();
      return;
    }
    if (this.manualSetupSpeed !== DEFAULT_MANUAL_SETUP_SPEED) {
      LogUtil.info(`${TAG} The speed has already been manually set; no further adjustment is needed.`)
      return;
    }
    if (this.drawingDiffTime > 0) {
      this.manualSetupSpeed = this.getSpeed() - MANUAL_SETUP_SPEED_THRESHOLD;
    } else {
      this.manualSetupSpeed = this.getSpeed() + MANUAL_SETUP_SPEED_THRESHOLD;
    }
  }

  /**
   * 波形图回到开始位置
   */
  private waveViewSlideToStart(): void {
    LogUtil.info(TAG + ': waveViewSlideToStart start.');
    this.waveStartTime = this.waveEndTime = Date.now();
    this.waveRunningTime = 0;
    this.strictOffset = 0;
    this.drawingOffset = 0;
    // 必须重置diffTime，这个数据也参与了绘制的进度计算，不重置将导致概率性回弹
    this.drawingDiffTime = 0;
    this.onDraw();
    LogUtil.info(TAG + ': waveViewSlideToStart end.');
  }

  /**
   * 拖动进度条时，需要对齐波形图时间
   */
  onSliderSeek(): void {
    if (this.sliderSeekTime < 0) {
      return;
    }
    LogUtil.info(TAG + ': onSliderSeek ' + this.sliderSeekTime);
    this.audioCountdownTime = this.sliderSeekTime;
    this.proofreadTime();
    this.sliderSeekTime = -1;
  }

  /**
   * 校正时间 —— 录音时间 & 波形图时间
   */
  private proofreadTime(): void {
    LogUtil.info(TAG + ': proofread time start.')
    this.waveEndTime = Date.now();
    this.waveStartTime = this.waveEndTime - this.audioCountdownTime;
    this.waveRunningTime = this.audioCountdownTime;
    this.drawingDiffTime = 0;
    this.strictOffset = this.waveRunningTime / 1000 * OFFSET_PER_SECOND;
    if (this.recorderState === RecorderState.PLAY) {
      this.strictOffset = Math.min(this.strictOffset, this.waveLineList.length * LINE_SPACE);
    }
    LogUtil.info(TAG + ': proofread time end.')
  }

  /**
   * 获取音频播放的速度
   *
   * @returns
   */
  private getSpeed(): number {
    if (this.manualSetupSpeed !== DEFAULT_MANUAL_SETUP_SPEED) {
      return this.manualSetupSpeed;
    }
    switch (this.mediaSpeed) {
      case media.PlaybackSpeed.SPEED_FORWARD_0_75_X:
        return 0.75;
      case media.PlaybackSpeed.SPEED_FORWARD_1_00_X:
        return 1;
      case media.PlaybackSpeed.SPEED_FORWARD_1_25_X:
        return 1.25;
      case media.PlaybackSpeed.SPEED_FORWARD_1_75_X:
        return 1.75;
      case media.PlaybackSpeed.SPEED_FORWARD_2_00_X:
        return 2;
      case CommonConstants.SPEED_FORWARD_0_50_X:
        return 0.5;
      case CommonConstants.SPEED_FORWARD_1_50_X:
        return 1.5;
      default:
        return 1;
    }
  }

  /**
   * 接收到波形控制命令时的处理逻辑
   */
  onWaveCommand(): void {
    LogUtil.debug(TAG + ': Receive wave command: ' + this.waveCommand + '. And current waveState: ' + this.waveState);
    switch (this.waveCommand) {
      case WaveCommand.START:
        this.onCommandStart();
        break;
      case WaveCommand.PAUSE:
        this.waveState = WaveState.STOPED;
        break;
      case WaveCommand.RESET:
        this.waveState = WaveState.STOPED;
        this.stopLooper();
        this.waveStartTime = Date.now();
        this.waveEndTime = this.waveStartTime;
        this.waveRunningTime = 0;
        break;
      case WaveCommand.MARK:
        this.keepOnDraw(1000);
        break;
      case WaveCommand.SYNC:
        // 同步波形数据
        this.syncWaveData();
        // 对齐录音时间
        this.proofreadTime();
        // 持续更新波形图
        this.keepOnDraw(1000);
        break;
      case WaveCommand.FORM_PAUSE:
        this.startLooper();
        break;
    }
    LogUtil.debug(TAG + ': Processing command end. And current waveState: ' + this.waveState);
    this.waveCommand = WaveCommand.NONE;
  }

  /**
   * 当收到波形图启动的命令时
   */
  private onCommandStart(): void {
    LogUtil.info(TAG + ': onCommandStart start.');
    if (this.waveState === WaveState.PLAYING) {
      LogUtil.info(TAG + ': onCommandStart skip.');
      return;
    }
    if (this.waveStartTime === this.waveEndTime) {
      // 说明是第一次启动波形图
      this.waveEndTime = Date.now();
      this.waveStartTime = this.waveEndTime;
      this.waveState = WaveState.PLAYING;
    } else {
      // 说明是暂停后再次启动波形图
      let diffTime: number = Math.ceil(this.waveRunningTime - this.audioCountdownTime);
      LogUtil.debug(TAG + ': Restart samples wave. The diffTime between waveRunningTime & countdown: ' + diffTime);
      if (diffTime > Math.min(this.audioTotalTime / 10, DIFF_TIME_ALLOW)) {
        // 误差超出范围了，说明是重新播放录音，直接对齐时间，diffTime作废
        this.waveRunningTime = this.audioCountdownTime;
        diffTime = 0;
        LogUtil.info(TAG + ': The difftime out of range!');
      }
      // 不是重新播放，且波形图时间比音频播放时间更快时，需要设置一定的延迟来校正波形图进度。
      if (diffTime > 0) {
        // 多次 Start/Stop 会导致 drawingDiffTime 增大
        // 原因1：波形图时间比录音时间更精细，所以波形图时间不能完全等于录音时间
        // 原因2：波形图的启动比音频的启动快
        // 所以这里使用Timeout对波形图时间和录音时间进行纠正
        setTimeout(() => {
          this.proofreadTime();
          this.waveState = WaveState.PLAYING;
          LogUtil.debug(TAG + ': Processing command completed. And current waveState: ' + this.waveState);
        }, diffTime);
      } else {
        this.proofreadTime();
        this.waveState = WaveState.PLAYING;
      }
    }
    if (!DeviceUtil.isTablet() || !this.isInBackground) {
      this.startLooper();
    }
    LogUtil.info(TAG + ': onCommandStart end.');
  }

  /**
   * 绘制波形图（会在绘制中频繁调用，需减少日志打印）
   */
  private onDraw(): void {
    if (!this.isCanvasReady) {
      LogUtil.info(TAG + ": Canvas isn't ready.");
      return;
    }
    this.canvas?.reset();
    if (!this.canvas) {
      return;
    }
    this.drawBottomCover(this.canvas);
    this.drawScale(this.canvas);
    this.drawWave(this.canvas);
    if (this.isShowMark && !this.isMini) {
      this.drawMark(this.canvas);
    }
    this.drawIndicator(this.canvas);
  }

  /**
   * 使用卡片背景色覆盖掉底部的空白部分，防止Canvas缩小时将带点的背景图显示出来（会在绘制中频繁调用，需减少日志打印）
   *
   * @param canvas
   */
  private drawBottomCover(canvas: CanvasRenderingContext2D): void {
    if (this.canvasHeight >= this.uiCanvasDefaultHeight) {
      return;
    }
    canvas.fillStyle = this.uiBottomCoverColor;
    let y: number = this.canvasHeight - this.uiScaleAreaHeight;
    canvas.fillRect(0, y, this.canvasWidth, this.canvas.height - y);
  }

  /**
   * 绘制指示器——红色竖线（会在绘制中频繁调用，需减少日志打印）
   *
   * @param canvas
   */
  private drawIndicator(canvas: CanvasRenderingContext2D): void {
    let x: number = this.canvasWidth >> 1;
    let y: number = this.canvasHeight - this.uiScaleAreaHeight + this.uiIndicatorCircleDiameter / 2;
    // Draw paint
    canvas.fillStyle = this.uiIndicatorColor;
    canvas.strokeStyle = this.uiIndicatorColor;
    canvas.lineCap = 'square';
    canvas.lineWidth = this.uiIndicatorWidth;
    canvas.beginPath();
    let indicatorStartY: number = this.uiMarkCircleDiameter + this.uiMarkTopLength + this.uiIndicatorWidth / 2;
    indicatorStartY = DeviceUtil.isSmallFoldVer() && this.screenShowState === CommonConstants.SCREEN_HALF ?
      indicatorStartY + 8 : indicatorStartY;
    canvas.moveTo(x, indicatorStartY);
    canvas.lineTo(x, y);
    canvas.stroke();
    // Draw paint
    canvas.lineCap = 'round';
    canvas.lineWidth = this.uiIndicatorCircleDiameter;
    canvas.beginPath();
    canvas.moveTo(x, y);
    canvas.lineTo(x, y);
    canvas.stroke();
  }

  /**
   * 绘制标记（会在绘制中频繁调用，需减少日志打印）
   *
   * @param canvas
   */
  private drawMark(canvas: CanvasRenderingContext2D): void {
    let halfWidth: number = this.canvasWidth >> 1;
    // Draw paint
    canvas.fillStyle = this.isDarkMode ? this.colorWhite : this.colorBlack;
    canvas.strokeStyle = this.isDarkMode ? this.colorWhite : this.colorBlack;
    for (let i = 0; i < this.markTimeArray.content.getAll().length; i++) {
      let markData: MarkData = this.markTimeArray.content.getData(i);
      let mark: number = markData.markDuration / 1000 * OFFSET_PER_SECOND;
      let x: number = halfWidth + mark - this.drawingOffset;
      if (x < 0 || x > this.canvasWidth) {
        continue;
      }
      if (this.recorderState === RecorderState.RECORD && (!this.isPanGesture && x > halfWidth)) {
        continue;
      }
      let y: number = this.canvasHeight - this.uiScaleAreaHeight - (this.uiMarkWidth / 2);
      let drawMarkToptart: number = this.uiMarkCircleDiameter / 2;
      drawMarkToptart =
        (DeviceUtil.isSmallFoldVer() && this.screenShowState === CommonConstants.SCREEN_HALF) ? drawMarkToptart + 8 :
          drawMarkToptart
      canvas.lineCap = 'square';
      canvas.lineWidth = this.uiMarkWidth;
      canvas.beginPath();
      canvas.moveTo(x, drawMarkToptart);
      canvas.lineTo(x, y);
      canvas.stroke();
      canvas.lineCap = 'round';
      canvas.lineWidth = this.uiMarkCircleDiameter;
      canvas.beginPath();
      canvas.moveTo(x, drawMarkToptart);
      canvas.lineTo(x, drawMarkToptart);
      canvas.stroke();
      canvas.fillStyle = this.isDarkMode ? this.colorBlack : this.colorWhite;
      canvas.direction = Configuration.getLocale().dir;
      if (this.maxMarkNumber < CommonConstants.ONE_THOUSAND) {
        canvas.font = '8vp HarmonyHeiTi';
      } else if (this.maxMarkNumber < CommonConstants.TEN_THOUSAND) {
        canvas.font = '6vp HarmonyHeiTi';
      } else {
        canvas.font = '3vp HarmonyHeiTi';
      }
      canvas.textAlign = 'center';
      canvas.textBaseline = 'middle';
      this.drawText(`${markData.count}`, x, drawMarkToptart);
    }
  }

  /**
   * 绘制时间刻度（会在绘制中频繁调用，需减少日志打印）
   *
   * @param canvas
   */
  private drawScale(canvas: CanvasRenderingContext2D): void {
    let halfWidth: number = this.canvasWidth >> 1;
    let startI: number = this.drawingOffset - halfWidth;
    startI = startI < 0 ? 0 : startI;
    startI = startI - startI % SCALE_SPACE;
    let endI: number = this.drawingOffset + halfWidth;
    if (this.recorderState === RecorderState.PLAY) {
      endI = Math.min(this.drawingOffset + halfWidth, this.waveLineList.length * LINE_SPACE);
    }
    // Draw paint
    canvas.lineWidth = this.uiScaleWidth;
    canvas.lineCap = 'square';
    canvas.font = '8vp Helvetica';
    canvas.textAlign = 'center';
    canvas.textBaseline = 'bottom';
    canvas.strokeStyle = this.isDarkMode ? this.uiSmallScaleDarkColor : this.uiSmallScaleColor;
    canvas.beginPath();
    for (let i = startI; i < endI; i += SCALE_SPACE) {
      let count: number = Math.floor(i / SCALE_SPACE);
      let x: number = halfWidth + i - this.drawingOffset;
      let y: number = this.canvasHeight - this.uiScaleAreaHeight;
      if (count % 4 !== 0) {
        canvas.moveTo(x, y);
        canvas.lineTo(x, y + this.uiSmallScaleHeight);
      }
    }
    canvas.stroke();
    canvas.fillStyle = this.isDarkMode ? this.uiBigScaleDarkColor : this.uiBigScaleColor;
    canvas.strokeStyle = this.isDarkMode ? this.uiBigScaleDarkColor : this.uiBigScaleColor;
    canvas.beginPath();
    for (let i = startI; i < endI; i += SCALE_SPACE) {
      let count: number = Math.floor(i / SCALE_SPACE);
      let x: number = halfWidth + i - this.drawingOffset;
      let y: number = this.canvasHeight - this.uiScaleAreaHeight;
      if (count % 4 === 0) {
        canvas.moveTo(x, y);
        canvas.lineTo(x, y + this.uiBigScaleHeight);
        this.drawText(`${this.formatTime(count / 2)}`, x, this.canvasHeight - this.uiScaleAreaTextBottom);
      }
    }
    canvas.stroke();
  }

  /**
   * 绘制文字
   *
   * @param text
   * @param x
   * @param y
   */
  private drawText(text: string, x: number, y: number): void {
    if (!this.canvas) {
      return;
    }
    if (this.isLtr) {
      // 普通绘制
      this.canvas.fillText(text, x, y);
    } else {
      // 镜像绘制
      this.canvas.save();
      this.canvas.translate(x, y);
      this.canvas.transform(this.mirrorMatrix[0], this.mirrorMatrix[1], this.mirrorMatrix[2],
        this.mirrorMatrix[3], this.mirrorMatrix[4], this.mirrorMatrix[5]);
      this.canvas.fillText(text, 0, 0);
      this.canvas.restore();
    }
  }

  /**
   * 格式化时间（会在绘制中频繁调用，需减少日志打印）
   *
   * @param time
   * @returns
   */
  private formatTime(time: number): string {
    let hour: number = Math.floor(time / 60 / 60);
    let minute: number = Math.floor(time / 60) % 60;
    let second: number = time % 60;
    let hourStr: string = hour > 0 ? `${hour >= 10 ? hour : '0' + hour}:` : '';
    return `${hourStr}${minute >= 10 ? minute : '0' + minute}:${second >= 10 ? second : '0' + second}`;
  }

  /**
   * 绘制波形（会在绘制中频繁调用，需减少日志打印）
   *
   * @param canvas
   */
  private drawWave(canvas: CanvasRenderingContext2D): void {
    let halfWidth: number = this.canvasWidth / 2;
    let centerWaveY: number = (this.waveAreaHeight / 2) + this.uiMarkCircleDiameter + this.uiMarkTopLength;
    centerWaveY = DeviceUtil.isSmallFoldVer() && this.screenShowState === CommonConstants.SCREEN_HALF ?
      centerWaveY + 4 : centerWaveY;
    let startI: number = (this.drawingOffset - halfWidth) / LINE_SPACE - (EXTRA_LINE_COUNT / 2);
    startI = Math.floor(startI < 0 ? 0 : startI);
    let endI: number = startI + this.maxDrawLineCount;
    endI = Math.ceil(endI > this.waveLineList.length ? this.waveLineList.length : endI);
    // Draw paint
    canvas.lineWidth = this.uiLineWidth;
    canvas.lineCap = 'round';
    if (this.uiWaveGradient) {
      canvas.strokeStyle = this.uiWaveGradient;
    } else {
      canvas.strokeStyle = this.colorGray;
    }
    canvas.beginPath();
    for (let i = startI; i < endI; i++) {
      let line: number = Math.min(this.waveLineList[i] * this.waveScale, this.uiMaxLineHeight);
      let x: number = halfWidth + (i * LINE_SPACE) - this.drawingOffset;
      if (this.recorderState === RecorderState.RECORD && x > halfWidth) {
        // 录音时线条不能超过半屏
        continue;
      }
      let y: number = centerWaveY - line / 2;
      canvas.moveTo(x, y);
      canvas.lineTo(x, y + line);
    }
    canvas.stroke();
  }

  /**
   * 取消波形数据监听
   */
  private unRegisterSamplesListener(): void {
    LogUtil.info(TAG + ': unRegisterSamplesListener start.');
    if (this.recorderState === RecorderState.RECORD) {
      LogUtil.info(TAG + ': unRegisterSamplesListener cancel.');
      return;
    }
    PlayManager.getInstance().unRegisterSamplesListener();
    LogUtil.info(TAG + ': unRegisterSamplesListener end.');
  }

  /**
   * 注册波形数据监听
   */
  private registerSamplesListener(): void {
    LogUtil.info(TAG + ': registerSamplesListener start.');
    if (this.recorderState === RecorderState.RECORD) {
      LogUtil.info(TAG + ': registerSamplesListener cancel.');
      return;
    }
    PlayManager.getInstance().registerSamplesListener((result: number[] | 'new_record_flag') => {
      LogUtil.info(TAG + ' SamplesListener callback result : ' + result);
      if (result === 'new_record_flag') {
        // 原本期望是在新设置录音时，重置波形图状态，但是时序有些慢了，容易出现显示上的异常
        this.newRecordFlag = true;
        this.simpleLoadingState = true;
        this.waveState = WaveState.STOPED;
        this.waveLineList.clear();
        this.waveViewSlideToStart();
        return;
      }
      let samples: number[] = result;
      LogUtil.info(TAG + ': samples update: ' + samples.length);
      this.fillUpWaveData(result);
      this.drawingOffset = this.strictOffset;
      this.onDraw();
      this.simpleLoadingState = false;
      LogUtil.info(TAG + ': samples update success.');
    });
    LogUtil.info(TAG + ': registerSamplesListener end. waveSize=' + this.waveLineList.length);
  }

  fillUpWaveData(samples: number[]): void {
    for (const sample of samples) {
      this.waveLineList.add(SampleUtil.sampleToWaveLine(sample));
    }
    LogUtil.info(`${TAG} fill up wave data, samples length: ${samples.length}`);
  }

  /**
   * 尝试开启绘制Looper，用于进入波形图页面时
   * 刚进入波形图界面时，如果用户已经开始播放了音频，这需要自动开启波形图的绘制
   */
  private tryStartWaveView(): void {
    LogUtil.info(TAG + ': tryStartWaveView start.');
    if (this.recorderState !== RecorderState.PLAY) {
      return;
    }
    this.proofreadTime();
    // 在播放录音组件控制播放速度，此处重置播放速度会导致展开折叠屏时播放速度可能会发生变化（比如用户在折叠屏时设置了速度为2）。
    this.startLooper();
    if (PlayManager.getInstance().getAVPlayerState() === 'playing') {
      this.waveCommand = WaveCommand.START;
      LogUtil.info(TAG + ': Try start WaveView success.')
    }
    LogUtil.info(TAG + ': tryStartWaveView end.')
  }

  /**
   * 开启绘制循环，开启读取振幅循环
   */
  private startLooper(): void {
    LogUtil.info(TAG + ': startLooper start.');
    if (DeviceUtil.isTablet()) {
      this.listenDisplaySync();
    } else {
      if (!this.waveDisplaySync) {
        this.listenDisplaySync();
      }
    }
    LogUtil.info(TAG + ': startLooper end.');
  }

  /**
   * 停止绘制循环，停止读取振幅循环
   */
  private stopLooper(): void {
    LogUtil.info(TAG + ': stopLooper start.');
    if (DeviceUtil.isTablet()) {
      // 平板的屏幕类型不支持应用设置刷新率，因此使用定时器的方式
      LogUtil.info(TAG + ' tablet stop draw wave.');
      clearInterval(this.tabletDrawWaveTimer);
    } else {
      if (this.waveDisplaySync) {
        this.waveDisplaySync.off('frame');
        this.waveDisplaySync.stop();
        this.waveDisplaySync = undefined;
      }
    }
    LogUtil.info(TAG + ': stopLooper end.');
  }

  /**
   * 判断录音时间与波形图时间的误差值是否是允许的，如果超出范围，则需要立刻校正时间
   *
   * @returns
   */
  private isDiffTimeAllowed(): boolean {
    return Math.abs(this.drawingDiffTime) < DIFF_TIME_ALLOW;
  }

  /**
   * 判断绘制中的offset和通过时间计算出来的offset是否”相等“的（误差在允许范围内）
   *
   * @returns
   */
  private isDiffOffsetAllowed(): boolean {
    let diffOffset: number = this.strictOffset - this.drawingOffset;
    let allowed: boolean = Math.abs(diffOffset) < 0.2;
    return allowed;
  }

  /**
   * 日志节流，防止日志频繁打印
   *
   * @param state
   */
  private throttleSkipFrameLog(state: SkipFrameState): void {
    if (this.skipFrameMark === state) {
      this.skipFrameCount--;
    } else {
      this.skipFrameMark = state;
      this.skipFrameCount = SKIP_FRAME_LOG_COUNT;
    }
    if (this.skipFrameCount > 0) {
      LogUtil.info(TAG + ': Skip frame by ' + state);
    }
  }

  /**
   * 计算出波形的当前帧，然后绘制（会在绘制过程中频繁调用，需减少日志打印）
   */
  private prepareFrame(): void {
    let nowTime: number = Date.now();
    if (!this.isShowMark) {
      this.isShowMark = this.markTimeArray.content.getAll().length > 0 ? true : false;
    }
    let isPassed: boolean = this.checkBeforeOnDraw(nowTime);
    if (isPassed) {
      this.calculateBeforeOnDraw(nowTime);
      this.onDraw();
    }
  }

  /**
   * 最终边界偏移量
   */
  private getOffsetEnd(): number {
    return this.waveLineList.length * LINE_SPACE;
  }

  /**
   * 在绘制之前的各种状态检查（会在绘制过程中频繁调用，需减少日志打印）
   *
   * @param nowTime 当前时间
   * @returns 是否通过
   */
  private checkBeforeOnDraw(nowTime: number): boolean {
    if (!this.isCanvasReady) {
      // Canvas 尚未 Ready
      this.throttleSkipFrameLog(SkipFrameState.CANVAS_NOT_READY);
      return false;
    }
    if (this.keepOnDrawTime > 0) {
      this.keepOnDrawTime--;
    }
    if (nowTime - this.waveEndTime < (1000 / EXPECTED_FPS / 2)) {
      // 计算屏幕刷新间隔，得知当前屏幕刷新率远大于期望刷新率，于是跳过部分绘制，减轻绘制负担
      this.throttleSkipFrameLog(SkipFrameState.DRAWING_TOO_FREQUENT);
      return false;
    }
    if (this.keepOnDrawTime <= 0 && this.isDiffOffsetAllowed() &&
      !this.isPanGesture && this.waveState === WaveState.STOPED) {
      // 没有新的CanvasHeight 且 没有需要处理的Offset 且 录音已暂停
      this.throttleSkipFrameLog(SkipFrameState.WAVE_STOPED);
      return false;
    }
    if (this.recorderState === RecorderState.PLAY && this.waveState === WaveState.PLAYING &&
      (this.audioTotalTime + DIFF_TIME_ALLOW) < this.waveRunningTime && this.keepOnDrawTime <= 0 &&
      this.drawingOffset >= this.getOffsetEnd()) {
      // 正常播放过程中，波形图数据已经全部完成绘制，进度100%
      this.waveState = WaveState.STOPED;
      this.throttleSkipFrameLog(SkipFrameState.DRAWING_COMPLETED);
      return false;
    }
    this.skipFrameMark = SkipFrameState.NONE;
    return true;
  }

  /**
   * 从RecordManager中同步波形数据
   */
  private syncWaveData(): void {
    if (this.recorderState === RecorderState.RECORD) {
      let realTimeWaves = RecordManager.getInstance().getRealtimeWaves();
      for (let i = this.waveLineList.length; i < realTimeWaves.length; i++) {
        this.waveLineList.add(realTimeWaves[i]);
      }
    }
  }

  /**
   * 绘制波形图前进行的一些计算工作（会在绘制过程中频繁调用，需减少日志打印）
   *
   * @param nowTime 当前时间
   */
  private calculateBeforeOnDraw(nowTime: number): void {
    if (this.waveState === WaveState.PLAYING ||
      this.waveCommand === WaveCommand.FORM_PAUSE) {
      // 倍速补偿，补偿开了倍速播放情况下的startTime
      this.waveStartTime -= ((this.getSpeed() ?? 1) - 1) * (nowTime - this.waveEndTime);
      // 录音时间与波形图时间补偿
      this.waveStartTime += this.drawingDiffTime / 100;
      this.waveEndTime = nowTime;
    }
    if (!this.isPanGesture && this.waveLineList.length < (this.strictOffset / LINE_SPACE) ||
        this.waveCommand === WaveCommand.FORM_PAUSE) {
      // 同步波形数据
      this.syncWaveData();
    }
    // 计算波形图进行的时间；如果处于波形图数据加载阶段，则波形图时间固定为0，防止加载阶段抖动
    this.waveRunningTime = this.simpleLoadingState ? 0 : (this.waveEndTime - this.waveStartTime);
    // 计算出"严格的"的Offset（“严格”指的是完全按照播放时间计算出来的Offset，没有为了显示流畅而妥协、微调）
    this.strictOffset = this.waveRunningTime / 1000 * OFFSET_PER_SECOND;
    if (this.recorderState === RecorderState.PLAY) {
      this.strictOffset = Math.min(this.strictOffset, this.waveLineList.length * LINE_SPACE);
    }
    if (!this.isPanGesture) {
      // 计算用于平滑绘制的Offset
      let diffOffset: number = Math.abs(this.strictOffset - this.drawingOffset);
      if (diffOffset > 1) {
        if (this.strictOffset > this.drawingOffset) {
          this.drawingOffset += Math.max(diffOffset / 3, 1);
        } else {
          this.drawingOffset -= Math.max(diffOffset / 3, 1);
        }
      } else {
        this.drawingOffset = this.strictOffset;
      }
    }
  }

  /**
   * 高低帧率切换
   * @param enable
   */
  private enableHighFps(enable: boolean) {
    let target: ExpectedFrameRateRange;
    if (enable) {
      target = this.highSyncRange;
    } else {
      target = this.lowSyncRange;
    }
    if (this.currentSyncRange !== target) {
      try {
        this.waveDisplaySync?.setExpectedFrameRateRange(target);
      } catch (e) {
        LogUtil.info(TAG + ': enableHighFps error: ' + JSON.stringify(e));
      }
      this.currentSyncRange = target;
      LogUtil.info(TAG + ': enableHighFps ' + enable);
    }
  }

  /**
   * 监听屏幕绘制事件
   */
  private listenDisplaySync(): void {
    LogUtil.info(TAG + ': listenDisplaySync start.');
    if (DeviceUtil.isTablet()) {
      // 平板的屏幕类型不支持应用设置刷新率，因此使用定时器的方式
      LogUtil.info(TAG + ' tablet start draw wave.');
      clearInterval(this.tabletDrawWaveTimer);
      this.prepareFrame();
      this.tabletDrawWaveTimer = setInterval(() => {
        this.prepareFrame()
      }, 50);
    } else {
      const waveDisplaySync = displaySync.create();
      waveDisplaySync.setExpectedFrameRateRange(this.currentSyncRange);
      waveDisplaySync.on('frame', () => this.prepareFrame());
      waveDisplaySync.start();
      this.waveDisplaySync = waveDisplaySync;
    }
    LogUtil.info(TAG + ': listenDisplaySync end.')
  }

  /**
   * 前后台状态变更时调用
   */
  private onBackgroundStatusChange() : void {
    if (!DeviceUtil.isTablet()) {
      return;
    }
    if (this.isInBackground) {
      this.stopLooper();
    } else {
      this.startLooper();
    }
  }

  private showWaveView() {
    // 录音 | 播放
    if (this.recorderState === RecorderState.RECORD) {
      // 分屏1/3|1/2 时不显示波形图
      if (this.screenShowState === CommonConstants.SCREEN_ONE_THREE ||
        this.screenShowState === CommonConstants.SCREEN_HALF) {
        this.isShowWaveView = false;
        return;
      }
    }
    this.isShowWaveView = true;
  }
}