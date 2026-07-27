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

import { common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CommonConstants } from '../constants/CommonConstants';

const IMAGE_SIZE = '64vp';
const TEXT_EDITABLE_DIALOG = '18.3fp';
const MAX_DIALOG = '256vp';
const MIN_DIALOG = '216vp';

export declare interface IconItem {
  iconRes: ResourceStr;
  isEnabled: boolean;
  label?: ResourceStr;
  isCanvasIcon?: boolean;
  canvasPath?: string;
  action?: () => void;
}

/**
 * 该组件适用于标题栏、底部页签、工具栏等场景控件的长按提示：
 * 当系统字体放大倍数为1.75倍及以上时，长按控件有放大提示效果
 * */
@CustomDialog
export struct LongPressDialogView {
  controller?: CustomDialogController
  iconItem: IconItem = {
    iconRes: '',
    isEnabled: true,
    isCanvasIcon: false
  }
  textRes?: ResourceStr = '';
  @StorageLink('fontSizeScale') fontSizeScale: number = 1;
  @State windowWidth: number = 0;
  @State maxLines: number = 1;
  verticalScreenLines: number = 6;
  horizontalsScreenLines: number = 1;
  isOnlyShowText: boolean = false;
  @State rotateAngle: number = 0;
  @State isShowSemiFolded: boolean = false;

  mainWindowStage?: window.Window;
  cancel: () => void = () => {
  }
  confirm: () => void = () => {
  }
  private antiAliasingSetting: RenderingContextSettings = new RenderingContextSettings(true);
  private canvasContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.antiAliasingSetting);

  @Styles
  CommonAttr() {
    .width(this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ? MAX_DIALOG : MIN_DIALOG)
    .constraintSize({
      minHeight: this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ?
        MAX_DIALOG : MIN_DIALOG
    })
    .backgroundBlurStyle(BlurStyle.NONE)
    .shadow(ShadowStyle.OUTER_DEFAULT_LG)
    .borderRadius(($r('sys.float.ohos_id_corner_radius_default_xl')))
    .rotate({
      angle: this.isShowSemiFolded ? 90 : this.rotateAngle,
    })
  }

  @Builder
  SingleTextBuilder() {
    Column() {
      Text(this.textRes)
        .fontSize(TEXT_EDITABLE_DIALOG)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
        .width('100%')
        .textAlign(TextAlign.Center)
        .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
    }
    .CommonAttr()
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private CanvasItemBuilder() {
    Canvas(this.canvasContext)
      .width(IMAGE_SIZE)
      .height(IMAGE_SIZE)
      .margin({
        top: $r('sys.float.padding_level24'),
        bottom: $r('sys.float.padding_level8'),
      })
  }

  @Builder
  ImageAndTextBuilder() {
    Column() {
      if (this.iconItem.isCanvasIcon) {
        this.CanvasItemBuilder();
      } else {
        Image(this.iconItem.iconRes)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .objectFit(ImageFit.Contain)
          .margin({
            top: $r('sys.float.padding_level24'),
            bottom: $r('sys.float.padding_level8'),
          })
      }

      Column() {
        Text(this.textRes)
          .fontSize(TEXT_EDITABLE_DIALOG)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .maxLines(this.maxLines)
          .width('100%')
          .textAlign(TextAlign.Center)
          .fontColor($r('sys.color.ohos_id_color_text_primary_contrary'))
      }
      .width('100%')
      .padding({
        left: $r('sys.float.padding_level4'),
        right: $r('sys.float.padding_level4'),
        bottom: $r('sys.float.padding_level12'),
      })
    }
    .CommonAttr()
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  SingleImageBuilder() {
    Column() {
      if (this.iconItem.isCanvasIcon) {
        Canvas(this.canvasContext)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
      } else {
        Image(this.iconItem.iconRes)
          .width(IMAGE_SIZE)
          .height(IMAGE_SIZE)
          .fillColor($r('sys.color.icon_primary'))
      }
    }
    .width(this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ? MAX_DIALOG : MIN_DIALOG)
    .constraintSize({
      minHeight: this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4 ?
        MAX_DIALOG : MIN_DIALOG
    })
    .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
    .shadow(ShadowStyle.OUTER_DEFAULT_LG)
    .borderRadius(($r('sys.float.corner_radius_level10')))
    .justifyContent(FlexAlign.Center)
    .rotate({
      angle: this.isShowSemiFolded ? 90 : this.rotateAngle,
    })
  }

  build() {
    if (this.isOnlyShowText) {
      this.SingleTextBuilder();

    } else if (this.textRes) {
      this.ImageAndTextBuilder();

    } else {
      this.SingleImageBuilder();
    }
  }

  async aboutToAppear(): Promise<void> {
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.mainWindowStage = context.windowStage.getMainWindowSync();
    let properties: window.WindowProperties = this.mainWindowStage.getWindowProperties();
    let rect = properties.windowRect;
    if (px2vp(rect.height) > this.windowWidth) {
      this.maxLines = this.verticalScreenLines;
    } else {
      this.maxLines = this.horizontalsScreenLines;
    }
  }
}