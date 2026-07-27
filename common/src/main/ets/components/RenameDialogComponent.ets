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
import common from '@ohos.app.ability.common';
import resourceManager from '@ohos.resourceManager';
import { BusinessError } from '@kit.BasicServicesKit';
import { LogUtil } from '../utils/LogUtil';
import { CustomColors, CustomTheme, Theme } from '@ohos.arkui.theme';
import { ButtonOptions } from '@ohos.arkui.advanced.Dialog';

class CustomThemeImpl implements CustomTheme {
  public colors?: CustomColors;

  constructor(colors: CustomColors) {
    this.colors = colors;
  }
}

const TAG: string = 'RenameDialogComponent';
const TITLE_MAX_LINES: number = 2;
const BUTTON_LAYOUT_WEIGHT: number = 1;
const MIN_CONTENT_HEIGHT: number = 100;
const MAX_CONTENT_HEIGHT: number = 30000;
const BUTTON_MIN_FONT_SIZE = 9;
const MAX_FONT_SCALE: number = 2;
// 'sys.float.Body_L'
const BODY_L = getNumberByResourceId(125830970) ?? 16;
// 'sys.float.Title_S'
const TITLE_S = getNumberByResourceId(125830966) ?? 20;
// 'sys.float.alert_button_style'
const ALERT_BUTTON_STYLE = getNumberByResourceId(125831085) ?? 0;

@CustomDialog
export struct RenameDialogComponent {
  controller: CustomDialogController;
  primaryTitle?: ResourceStr;
  @BuilderParam contentBuilder: () => void;
  cancelButton?: ButtonOptions;
  confirmButton?: ButtonOptions;
  @State fontSizeScale: number = 1;
  @State minContentHeight: number = MIN_CONTENT_HEIGHT;

  build() {
    CustomDialogContentComponent({
      controller: this.controller,
      primaryTitle: this.primaryTitle,
      contentBuilder: () => {
        this.contentBuilder();
      },
      cancelButton: this.cancelButton,
      confirmButton: this.confirmButton,
      fontSizeScale: this.fontSizeScale,
      minContentHeight: this.minContentHeight,
    }).constraintSize({ maxHeight: '100%' });
  }
}

@Component
struct CustomDialogLayout {
  @Builder
  doNothingBuilder(): void {
  };

  @Link titleHeight: number;
  @Link buttonHeight: number;
  @Link titleMinHeight: Length;
  @BuilderParam dialogBuilder: () => void = this.doNothingBuilder;
  titleIndex: number = 0;
  contentIndex: number = 1;
  buttonIndex: number = 2;

  onPlaceChildren(selfLayoutInfo: GeometryInfo, children: Array<Layoutable>, constraint: ConstraintSizeOptions) {
    let currentX: number = 0;
    let currentY: number = 0;
    for (let index = 0; index < children.length; index++) {
      let child = children[index];
      child.layout({ x: currentX, y: currentY });
      currentY += child.measureResult.height;
    }
  }

  onMeasureSize(selfLayoutInfo: GeometryInfo, children: Array<Measurable>,
    constraint: ConstraintSizeOptions): SizeResult {
    let sizeResult: SizeResult = { width: Number(constraint.maxWidth), height: 0 };
    let childrenSize: number = 3;
    if (children.length < childrenSize) {
      return sizeResult;
    }
    let height: number = 0;
    let titleChild: Measurable = children[this.titleIndex];
    let titleConstraint: ConstraintSizeOptions = {
      maxWidth: constraint.maxWidth,
      minHeight: this.titleMinHeight,
      maxHeight: constraint.maxHeight
    };
    let titleMeasureResult: MeasureResult = titleChild.measure(titleConstraint);
    this.titleHeight = titleMeasureResult.height;
    height += this.titleHeight;

    let buttonChild: Measurable = children[this.buttonIndex];
    let buttonMeasureResult: MeasureResult = buttonChild.measure(constraint);
    this.buttonHeight = buttonMeasureResult.height;
    height += this.buttonHeight;

    let contentChild: Measurable = children[this.contentIndex];
    let contentConstraint: ConstraintSizeOptions = {
      maxWidth: constraint.maxWidth,
      maxHeight: Number(constraint.maxHeight) - height
    };

    let contentMeasureResult: MeasureResult = contentChild.measure(contentConstraint);
    height += contentMeasureResult.height;
    sizeResult.height = height;
    return sizeResult;
  }

  build() {
    this.dialogBuilder();
  }
}

@Component
struct CustomDialogContentComponent {
  controller?: CustomDialogController;
  primaryTitle?: ResourceStr;
  @BuilderParam contentBuilder: () => void = this.defaultContentBuilder;
  cancelButton?: ButtonOptions;
  confirmButton?: ButtonOptions;
  keyIndex: number = 0;
  private theme: Theme | CustomTheme = new CustomThemeImpl({});
  private themeColorMode: ThemeColorMode = ThemeColorMode.SYSTEM;
  @Link minContentHeight: number;

  @Builder
  defaultContentBuilder(): void {
  }

  @State titleHeight: number = 0;
  @State buttonHeight: number = 0;
  @State contentMaxHeight: Length = '100%';
  @Link fontSizeScale: number;
  @State buttonMaxFontSize: Length = $r('sys.float.Body_L');
  @State buttonMinFontSize: Length = 9;
  @State primaryTitleMaxFontSize: Length = $r('sys.float.Title_S');
  @State primaryTitleMinFontSize: Length = $r('sys.float.Body_L');
  @State primaryTitleFontColorWithTheme: ResourceColor = $r('sys.color.font_primary');
  @State titleTextAlign: TextAlign = TextAlign.Center;
  @State titleMinHeight: Length = 0;

  build() {
    WithTheme({ theme: this.theme, colorMode: this.themeColorMode }) {
      Column() {
        CustomDialogLayout({
          buttonHeight: this.buttonHeight,
          titleHeight: this.titleHeight,
          titleMinHeight: this.titleMinHeight
        }) {
          WithTheme({ theme: this.theme, colorMode: this.themeColorMode }) {
            this.titleBuilder();
          }
          Column() {
            WithTheme({ theme: this.theme, colorMode: this.themeColorMode }) {
              this.contentBuilder();
            }
          }
          .padding({
            top: 0,
            right: $r('sys.float.alert_content_default_padding'),
            bottom: 0,
            left: $r('sys.float.alert_content_default_padding'),
          })
          WithTheme({ theme: this.theme, colorMode: this.themeColorMode }) {
            this.ButtonBuilder();
          }
        }
      }
      .constraintSize({ maxHeight: this.contentMaxHeight })
      .backgroundColor(this.themeColorMode === ThemeColorMode.SYSTEM || undefined
        ? Color.Transparent : $r('sys.color.comp_background_primary'))
    }
  }

  onMeasureSize(selfLayoutInfo: GeometryInfo, children: Array<Measurable>,
    constraint: ConstraintSizeOptions): SizeResult {
    let sizeResult: SizeResult = { width: selfLayoutInfo.width, height: selfLayoutInfo.height };
    let maxWidth: number = Number(constraint.maxWidth);
    let maxHeight: number = Number(constraint.maxHeight);
    this.updateFontScale();
    this.updateFontSize();
    this.titleMinHeight = $r('sys.float.alert_title_primary_height');
    let height: number = 0;
    children.forEach((child) => {
      this.contentMaxHeight = '100%';
      let measureResult: MeasureResult = child.measure(constraint);
      if (maxHeight - this.buttonHeight - this.titleHeight < this.minContentHeight) {
        this.contentMaxHeight = MAX_CONTENT_HEIGHT;
        measureResult = child.measure(constraint);
      }
      height += measureResult.height;
    });
    sizeResult.height = height;
    sizeResult.width = maxWidth;
    return sizeResult;
  }

  aboutToAppear(): void {
    this.updateFontScale();
    this.primaryTitleFontColorWithTheme = this.theme?.colors?.fontPrimary ?
    this.theme.colors.fontPrimary : $r('sys.color.font_primary');
    this.titleTextAlign = TextAlign.Center;
  }

  private updateFontSize(): void {
    if (this.fontSizeScale > MAX_FONT_SCALE) {
      this.buttonMaxFontSize = BODY_L * MAX_FONT_SCALE + 'vp';
      this.buttonMinFontSize = BUTTON_MIN_FONT_SIZE * MAX_FONT_SCALE + 'vp';
      this.primaryTitleMaxFontSize = TITLE_S * MAX_FONT_SCALE + 'vp';
      this.primaryTitleMinFontSize = BODY_L * MAX_FONT_SCALE + 'vp';
    } else {
      this.primaryTitleMaxFontSize = TITLE_S + 'fp';
      this.primaryTitleMinFontSize = BODY_L + 'fp';
      this.buttonMaxFontSize = BODY_L + 'fp';
      this.buttonMinFontSize = BUTTON_MIN_FONT_SIZE + 'fp';
    }
  }

  updateFontScale(): void {
    try {
      let context: common.ExtensionContext = this.getUIContext().getHostContext() as common.ExtensionContext;
      this.fontSizeScale = context.config?.fontSizeScale ?? this.fontSizeScale;
    } catch (exception) {
      let code: number = (exception as BusinessError).code;
      let message: string = (exception as BusinessError).message;
      LogUtil.error(`${TAG}, Faild to init fontsizescale info,cause, code: ${code}, message: ${message}`);
    }
  }

  @Builder
  titleBuilder() {
    Column() {
      Row() {
        Text(this.primaryTitle)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.primaryTitleFontColorWithTheme)
          .textAlign(this.titleTextAlign)
          .maxFontSize(this.primaryTitleMaxFontSize)
          .minFontSize(this.primaryTitleMinFontSize)
          .maxLines(TITLE_MAX_LINES)
          .heightAdaptivePolicy(TextHeightAdaptivePolicy.MIN_FONT_SIZE_FIRST)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
      }
      .width('100%')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .padding({
      top: $r('sys.float.alert_title_padding_top'),
      right: $r('sys.float.alert_title_padding_right'),
      left: $r('sys.float.alert_title_padding_left'),
      bottom: $r('sys.float.alert_title_padding_bottom'),
    })
  }

  @Builder
  ButtonBuilder(): void {
    Column() {
      Row() {
        if (this.cancelButton) {
          this.buildSingleButton(this.cancelButton);
        }
        if (this.confirmButton) {
          Divider()
            .width($r('sys.float.alert_divider_width'))
            .height($r('sys.float.alert_divider_height'))
            .color($r('sys.color.alert_divider_color'))
            .vertical(true)
            .margin({
              left: $r('sys.float.alert_button_horizontal_space'),
              right: $r('sys.float.alert_button_horizontal_space'),
            });
          this.buildSingleButton(this.confirmButton);
        }
      }
    }
    .width('100%')
    .padding({
      top: $r('sys.float.alert_button_top_padding'),
      right: $r('sys.float.alert_right_padding_horizontal'),
      left: $r('sys.float.alert_left_padding_horizontal'),
      bottom: $r('sys.float.alert_button_bottom_padding_horizontal'),
    })
  }

  @Builder
  buildSingleButton(buttonOptions: ButtonOptions): void {
    Button(buttonOptions.value)
      .setButtonProperties(buttonOptions, this.controller)
      .backgroundColor(buttonOptions.background)
      .fontColor(buttonOptions.fontColor)
      .key(`advanced_dialog_button_${this.keyIndex++}`)
      .labelStyle({ maxLines: 1, maxFontSize: this.buttonMaxFontSize, minFontSize: this.buttonMinFontSize })
  }
}

@Extend(Button)
function setButtonProperties(buttonOptions: ButtonOptions, controller?: CustomDialogController) {
  .onClick(() => {
    if (buttonOptions.action) {
      buttonOptions.action();
    }
  })
  .defaultFocus(true)
  .buttonStyle(buttonOptions.buttonStyle ?? ALERT_BUTTON_STYLE)
  .layoutWeight(BUTTON_LAYOUT_WEIGHT)
}

/**
 * get resource size
 *
 * @param resourceId resource id
 * @returns resource size
 */
function getNumberByResourceId(resourceId: number): number | undefined {
  try {
    return resourceManager.getSystemResourceManager().getNumber(resourceId);
  } catch (error) {
    let code: number = (error as BusinessError).code;
    let message: string = (error as BusinessError).message;
    LogUtil.error(`${TAG}, CustomContentDialog getNumberByResourceId error, code: ${code}, message: ${message}`);
    return undefined;
  }
}