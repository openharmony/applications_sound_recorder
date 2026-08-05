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

import { LogUtil, Util } from '@ohos/common';
import i18n from '@ohos.i18n';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';

const TAG: string = 'SoundRecorder_Record2x2Form'
@Entry
@Component
struct Record2x2Form {
  /*
   * The action type.
   */
  readonly ACTION_TYPE: string = 'router';
  /*
   * The ability name.
   */
  readonly ABILITY_NAME: string = 'MainAbility';

  @LocalStorageProp('formId') formId: string = '';

  // 录音机应用是否正在录音
  @LocalStorageProp('isRecording') isRecording: boolean = false;

  @LocalStorageProp('currentTimePlay') currentTimePlay: number = 0;

  @LocalStorageProp('fileName') fileName: string = '';

  @LocalStorageProp('markOpacity') markOpacity: number = 1;

  @LocalStorageProp('playOrPauseOpacity') playOrPauseOpacity: number = 1;

  @LocalStorageProp('recordState') recordState: string = 'idle';

  isMirrorLanguage(): boolean {
    let systemLanguage = i18n.System.getSystemLanguage();
    return systemLanguage === 'ug';
  }

  aboutToDisappear(): void {
    LogUtil.info(TAG + ` aboutToDisappear`);
    this.fileName = '';
  }

  @Builder
  StartRecordButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Row() {
      }
      .width('9vp')
      .height('9vp')
      .backgroundColor('#ffffff')
      .borderRadius(50)
    }
    .id('recorder2x2FaBtn')
    .width($r('app.float.distance_32'))
    .height($r('app.float.distance_32'))
    .backgroundColor('#FB654E')
    .accessibilityText($r('app.string.start'))
    .alignRules({
      right: { anchor: '__container__', align: HorizontalAlign.End },
      bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
    })
    .onClick(() => {
      LogUtil.info(TAG + ` StartRecordButton`);
      postCardAction(this, {
        action: 'call',
        abilityName: this.ABILITY_NAME,
        params: {
          method: 'FaCardCallback',
          formId: this.formId,
          formName: 'Record2x2Form'
        }
      });
    })
    .margin(this.isMirrorLanguage()
      ? { left: $r('sys.float.ohos_id_card_margin_end'), bottom: '12vp' } :
      { right: $r('sys.float.ohos_id_card_margin_end'), bottom: '12vp' })
  }

  @Builder
  /* instrument ignore next */
  MarkButton() {
    //标记按钮
    Button({type: ButtonType.Normal, stateEffect: true}) {
      SymbolGlyph($r('sys.symbol.bookmark'))
        .width('15vp')
        .height('15vp')
        .opacity(this.markOpacity)
        .fontSize('15vp')
        .fontColor(new Array($r('sys.color.ohos_id_color_primary')))
    }
    .id('fa_markBtn')
    .width($r('app.float.distance_30'))
    .height($r('app.float.distance_30'))
    .borderRadius($r('app.float.distance_30'))
    .accessibilityText($r('app.string.mark'))
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .onClick(() => {
      LogUtil.info(TAG + ' fa click to add insert mark.');
      postCardAction(this, {
        action: 'call',
        abilityName: this.ABILITY_NAME,
        params: {
          method: 'FaCardMarkCallback',
          formId: this.formId,
          formName: 'Record2x2Form'
        }
      });
    })
  }

  @Builder
  /* instrument ignore next */
  EndRecordButton() {
    //开始结束录音按钮
    Button({type: ButtonType.Normal, stateEffect: true}) {
      Row()
        .width('11vp')
        .height('11vp')
        .backgroundColor($r('app.color.white'))
        .borderRadius(3)
    }
    .id('fa_recordBtn')
    .width($r('app.float.distance_32'))
    .height($r('app.float.distance_32'))
    .borderRadius($r('app.float.distance_32'))
    .accessibilityText($r('app.string.end'))
    .backgroundColor('#FB654E')
    .onClick(() => {
      LogUtil.info(TAG + ` EndRecordButton`);
      postCardAction(this, {
        action: 'call',
        abilityName: this.ABILITY_NAME,
        params: {
          method: 'FaCardCallback',
          formId: this.formId,
          formName: 'Record2x2Form'
        }
      });
    })
  }

  @Builder
  /* instrument ignore next */
  ResumeButton() {
    //暂停继续按钮
    Button({type: ButtonType.Normal, stateEffect: true}) {
      Stack() {
        this.SymbolPlayAndPauseButton();
      }
      .opacity(this.playOrPauseOpacity)
    }
    .id('fa_resumeBtn')
    .width($r('app.float.distance_30'))
    .height($r('app.float.distance_30'))
    .borderRadius($r('app.float.distance_30'))
    .accessibilityText(this.recordState === 'started' ? $r('app.string.pause') : $r('app.string.resume'))
    .backgroundColor($r('sys.color.comp_background_tertiary'))
    .onClick(() => {
      LogUtil.info(TAG + ' click play or pause button, state: ' + this.recordState);
      let nextState = ''
      if (this.recordState === 'started') {
        nextState = 'toPause';
      }
      if (this.recordState === 'paused') {
        nextState = 'toResume';
      }
      postCardAction(this, {
        action: 'call',
        abilityName: this.ABILITY_NAME,
        params: {
          method: 'FaCardResumeCallback',
          nextState: nextState,
          formId: this.formId,
          formName: 'Record2x2Form'
        }
      });
    })
  }

  @Builder
  /* instrument ignore next */
  SymbolPlayAndPauseButton() {
    SymbolGlyph(this.recordState === 'started' ? $r('sys.symbol.pause') : $r('sys.symbol.play_fill'))
      .rotate({x: 0, y: 1, z: 0, angle: this.isMirrorLanguage() ? 180 : 0})
      .direction(this.isMirrorLanguage() ? Direction.Rtl : Direction.Ltr)
      .width('15vp')
      .height('15vp')
      .fontSize('15vp')
      .fontColor(new Array($r('sys.color.ohos_id_color_primary')))
      .symbolEffect(new AppearSymbolEffect(EffectScope.WHOLE), true)
  }

  @Builder
  /* instrument ignore next */
  BottomToolBarComponent() {
    Flex({
      direction: FlexDirection.Row,
      justifyContent: FlexAlign.SpaceBetween,
      alignItems: ItemAlign.Center
    }) {
      this.MarkButton();
      this.EndRecordButton();
      this.ResumeButton();
    }
  }

  @Builder
  FileSavedPage() {
    Column() {
      /* button */
      SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
        .fontColor(['#FB654E'])
        .fontSize('32vp')

      /* fileName */
      Column(){
        Text(this.fileName)
          .textAlign(TextAlign.Center)
          .fontWeight(FontWeight.Bold)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('app.float.font_12'))
          .lineHeight('14vp')
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .maxLines(2)
          .textOverflow({overflow: TextOverflow.Ellipsis})
          .id('record_fa_2x2_fileName')
          .accessibilityText(this.fileName)
      }
      .margin({
        top: '8vp',
        left: '12vp',
        right: '12vp'
      })

      /* saved */
      Column() {
        Text($r('app.string.saved'))
          .fontWeight(FontWeight.Regular)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('app.float.font_10'))
          .fontColor($r('sys.color.font_secondary'))
          .lineHeight('12vp')
          .id('record_fa_2x2_saved')
          .accessibilityText($r('app.string.saved'))
      }
      .height('14vp')
      .margin({
        top: '4vp',
      })
    }
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .height('100%')
    .width('100%')
  }

  @Builder
  FaInitialPage() {
    Column() {
      /* 录音机 */
      Text($r('app.string.title'))
        .alignSelf(ItemAlign.Start)
        .fontSize($r('app.float.font_18'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .fontWeight(FontWeight.Bold)
        .margin({
          top: '12vp',
          left: '12vp',
          right: '12vp'
        })
        .width('100%')
        .lineHeight('21vp')
        .height('24vp')
        .id('record_fa_2x2_title')

      Text($r('app.string.start_record'))
        .width('100%')
        .lineHeight('14vp')
        .height('16vp')
        .alignSelf(ItemAlign.Start)
        .fontSize($r('app.float.font_12'))
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .fontWeight(FontWeight.Regular)
        .margin({
          left: '12vp',
          right: '12vp',
          top: '2vp'
        })
        .id('record_fa_2x2_title_second')

      RelativeContainer() {
        Image($r('app.media.fa_2x2_background'))
          .width('calc(100% - 44vp)')
          .height('100%')
          .id('fa_2x2_card_back_cover')
          .alignRules({
            left: { anchor: '__container__', align: HorizontalAlign.Start },
            bottom: { anchor: '__container__', align: VerticalAlign.Bottom }
          })
          .interpolation(ImageInterpolation.Medium)
          .matchTextDirection(true)
        this.StartRecordButton();
      }
      .width('100%')
      .height('calc(100% - 54vp)')
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  FaRecordingPage() {
    Column() {
      Row() {
        Image($r('app.media.fa_2x2_recording'))
          .width('16vp')
          .height('16vp')
          .matchTextDirection(true)

        /* 正在录音 */
        Text($r('app.string.notice_recording'))
          .fontSize($r('sys.float.ohos_id_text_size_caption1'))
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(FontWeight.Regular)
          .id('record_fa_2x2_recording')
          .lineHeight('12vp')
      }
      .height('16vp')
      .justifyContent(FlexAlign.Center)
      /* 时间 */
      Column(){
        Text(Util.timeFormat(this.currentTimePlay))
          .fontWeight(FontWeight.Bold)
          .fontColor(this.markOpacity === 0.4 ? '#FB654E' : $r('sys.color.ohos_id_color_text_primary'))
          .textAlign(TextAlign.Center)
          .fontFamily('HarmonyHeiTi')
          .width('calc(100% - 56vp)')
          .height('27vp')
          .fontSize($r('app.float.font_20_vp'))
          .accessibilityText(AccessibilityUtil.getDurationText(this.currentTimePlay))
          .id('record_fa_2x2_currentTime')
      }
      .height('27vp')
      .alignItems(HorizontalAlign.Center)

      Column() {
        /* 按钮 */
        this.BottomToolBarComponent()
      }
      .margin({
        left: '12vp',
        right: '12vp',
      })
    }
    .padding({
      top: '12vp',
      bottom: '12vp'
    })
    .justifyContent(FlexAlign.SpaceBetween)
    .width('100%')
    .height('100%')
  }

  build() {
    Column() {
      if (this.fileName !== '' && !this.isRecording) {
        this.FileSavedPage();
      } else {
        if (!this.isRecording) {
          this.FaInitialPage();
        } else {
          this.FaRecordingPage();
        }
      }
    }
    .backgroundColor($r('app.color.fa_background_color'))
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: this.ABILITY_NAME,
      });
    })
  }
}