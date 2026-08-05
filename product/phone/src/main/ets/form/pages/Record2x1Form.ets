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

const TAG: string = 'SoundRecorder_Record2x1Form'
@Entry
@Component
struct Record2x1Form {
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
    .id('startRecord2x1FaBtn')
    .width($r('app.float.distance_32'))
    .height($r('app.float.distance_32'))
    .backgroundColor('#FB654E')
    .accessibilityText($r('app.string.start'))
    .onClick(() => {
      LogUtil.info(TAG + ` StartRecordButton`);
      postCardAction(this, {
        action: 'call',
        abilityName: this.ABILITY_NAME,
        params: {
          method: 'FaCardCallback',
          formId: this.formId,
          formName: 'Record2x1Form'
        }
      });
    })
    .alignRules({
      right: { anchor: '__container__', align: HorizontalAlign.End },
      top: { anchor: '__container__', align: VerticalAlign.Center }
    })
    .margin(this.isMirrorLanguage() ? {
        left: '12vp',
        top: '-16vp'} : {
        right: '12vp',
        top: '-16vp'
    })
  }

  @Builder
  EndRecordButton() {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      Row() {
      }
      .width('11vp')
      .height('11vp')
      .backgroundColor('#ffffff')
      .borderRadius(3)
    }
    .id('endRecord2x1FaBtn')
    .width($r('app.float.distance_32'))
    .height($r('app.float.distance_32'))
    .backgroundColor('#FB654E')
    .accessibilityText($r('app.string.end'))
    .onClick(() => {
      LogUtil.info(TAG + ` EndRecordButton`);
      postCardAction(this, {
        action: 'call',
        abilityName: this.ABILITY_NAME,
        params: {
          method: 'FaCardCallback',
          formId: this.formId,
          formName: 'Record2x1Form'
        }
      });
    })
    .margin(this.isMirrorLanguage() ? { left: $r('sys.float.ohos_id_card_margin_end') } :
      { right: $r('sys.float.ohos_id_card_margin_end')})
  }

  isMirrorLanguage(): boolean {
    let systemLanguage = i18n.System.getSystemLanguage();
    return systemLanguage === 'ug';
  }

  @Builder
  FileSavedPage() {
    Column() {
      Text(this.fileName)
        .fontWeight(FontWeight.Bold)
        .textAlign(TextAlign.Start)
        .fontFamily('HarmonyHeiTi')
        .fontSize($r('app.float.font_14'))
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .id('record_fa_2x1_fileName')
        .maxLines(1)
        .textOverflow({overflow: TextOverflow.Ellipsis})
        .accessibilityText(this.fileName)
    }
    .alignItems(HorizontalAlign.Start)
    .width('72vp')

    SymbolGlyph($r('sys.symbol.checkmark_circle_fill'))
      .fontColor(['#FB654E'])
      .fontSize('32vp')
      .margin(this.isMirrorLanguage() ? { left: $r('sys.float.ohos_id_card_margin_end') } :
        { right: $r('sys.float.ohos_id_card_margin_end')})
  }

  @Builder
  FaInitialPage() {
    RelativeContainer() {
      Column() {
        Text($r('app.string.title'))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('app.float.font_14'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .id('record_fa_2x1_title')
      }
      .alignRules({
        left: { anchor: '__container__', align: HorizontalAlign.Start },
        top: { anchor: '__container__', align: VerticalAlign.Center }
      })
      .offset({
        y: -7
      })
      Image($r('app.media.fa_1x2_background'))
        .id('fa_1x2_card_back_cover')
        .interpolation(ImageInterpolation.Medium)
        .height('calc(100% - 27vp)')
        .width('73vp')
        .matchTextDirection(true)
        .alignRules({
          right: { anchor: '__container__', align: HorizontalAlign.End },
          top: { anchor: '__container__', align: VerticalAlign.Top }
        })
      this.StartRecordButton();
    }
  }

  @Builder
  FaRecordingPage() {
    Row() {
      Column() {
        Button({ type: ButtonType.Circle, stateEffect: true })
          .width('6vp')
          .height('6vp')
          .backgroundColor('#FB654E')
      }
      .alignItems(HorizontalAlign.Start)
      Column() {
        Text(Util.timeFormat(this.currentTimePlay))
          .fontWeight(FontWeight.Bold)
          .textAlign(TextAlign.Start)
          .fontFamily('HarmonyHeiTi')
          .fontSize($r('app.float.font_14'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .accessibilityText(AccessibilityUtil.getDurationText(this.currentTimePlay))
          .id('record_fa_2x1_currentTime')
      }
      .margin(this.isMirrorLanguage() ? { right: '6vp' } : { left: '6vp'})
      .alignItems(HorizontalAlign.Start)
    }
    this.EndRecordButton();
  }

  build() {
    Row() {
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
    .justifyContent(FlexAlign.SpaceBetween)
    .padding(this.isMirrorLanguage() ? { right: $r('sys.float.ohos_id_card_margin_end') } :
      { left: $r('sys.float.ohos_id_card_margin_end') })
    .height('100%')
    .width('100%')
    .onClick(() => {
      postCardAction(this, {
        action: 'router',
        abilityName: this.ABILITY_NAME,
      });
    })
  }
}