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

import { DeviceUtil, LogUtil } from '@ohos/common';
import bundleManager from '@ohos.bundle.bundleManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { Configuration } from '@kit.ArkUI';

const TAG: string = 'SoundRecorder_AboutPage ';
const ABOUT_START_TIME: number = 2023;
const ABOUT_END_TIME: number = new Date().getFullYear();

@Component
export struct AboutPage {
  @StorageProp('navigatorBarHeight') navigatorBarHeight: number = 0;
  @State version: string = '';
  @State isShowContent: boolean = false;
  @Link showAboutPage: boolean;

  async aboutToAppear() {
    bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).then(data => {
      this.version = data.versionName;
      this.isShowContent = true;
    });
  }

  openBrowser(url: string) {
    let want: Want = {
      action: 'ohos.want.action.viewData',
      uri: url
    };
    const context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
    context.startAbility(want).then(() => {
      LogUtil.info(TAG + 'startAbility success');
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + `startAbility fail, code: ${err.code}, message: ${err.message}`);
    });
  }

  @Builder
  AboutTitleBar() {
    Row() {
      Text($r('app.string.about'))
        .fontColor($r('sys.color.ohos_id_color_titlebar_text'))
        .fontSize($r('sys.float.ohos_id_text_size_headline8'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)

      Button({ type: ButtonType.Circle, stateEffect: true }) {
        SymbolGlyph($r('sys.symbol.xmark'))
          .id('backIconInNavDestinationTitleBar')
          .fontSize(24)
          .fontColor([$r('sys.color.icon_primary')])
          .draggable(false)
      }
      .accessibilityText(getContext().resourceManager.getStringSync($r('app.string.detailDialog_close')))
      .width($r('app.float.distance_40'))
      .height($r('app.float.distance_40'))
      .backgroundColor($r('sys.color.comp_background_tertiary'))
      .onClick(() => {
        LogUtil.info(TAG + ' close AboutPage')
        this.showAboutPage = false;
      })
    }
    .width('100%')
    .height(DeviceUtil.isPC() ? 64 : 56)
    .padding({
      left: Configuration.getLocale().dir === 'ltr' ? 16 : 8,
      right: Configuration.getLocale().dir === 'rtl' ? 16 : 8
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  aboutContent() {
    Scroll() {
      Column({ space: 16 }) {
        Image($r('app.media.app_icon'))
          .width(72)
          .height(72)
          .borderRadius(16)
          .margin({ top: 24 })

        Text($r('app.string.title'))
          .fontSize($r('sys.float.ohos_id_text_size_headline7'))
          .fontWeight(FontWeight.Medium)
          .fontColor($r('sys.color.font_primary'))

        Text($r('app.string.version_info'))
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))

        Text(this.version)
          .fontSize($r('sys.float.Body_M'))
          .fontColor($r('sys.color.font_secondary'))

        Text() {
          Span($r('app.string.filing_number'))
            .fontColor($r('sys.color.font_emphasize'))
            .decoration({ type: TextDecorationType.Underline })
            .onClick(() => {
              LogUtil.info(TAG + 'click filing number');
              this.openBrowser(getContext(this).resourceManager.getStringSync($r('app.string.filing_number_url').id));
            })
          Span('\n')
          Span($r('app.string.copy_right', ABOUT_START_TIME, ABOUT_END_TIME))
            .fontColor($r('sys.color.font_secondary'))
        }
        .fontSize($r('sys.float.Body_S'))
        .textAlign(TextAlign.Center)
        .width('100%')
        .padding({ left: 24, right: 24, bottom: this.navigatorBarHeight + 24 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
  }

  build() {
    NavDestination() {
      if (this.isShowContent) {
        this.aboutContent();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_sub_background'))
    .hideBackButton(true)
    .hideTitleBar(false)
    .title({ builder: this.AboutTitleBar(), height: DeviceUtil.isPC() ? 64 : 56 })
  }
}