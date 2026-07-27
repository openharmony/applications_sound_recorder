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

import { ButtonModifier, ColorMetrics } from '@kit.ArkUI';

export interface ActionBarButtonOptions {
  id: string;
  baseIcon: Resource;
  altIcon?: Resource;
  iconFillColor?: ColorMetrics;
  backgroundColor?: ColorMetrics;
  shadowStyle?: ShadowStyle;
  onClick?: () => void;
  enabled?: boolean;
  accessibilityText?: ResourceStr;
  hoverTips?: ResourceStr;
  accessibilityDescription?: ResourceStr;
}

export interface ActionBarStyleOptions {
  isPrimaryIconChanged?: boolean;
  backgroundColor?: ColorMetrics;
}

@ObservedV2
export class ActionBarStyle {
  @Trace isPrimaryIconChanged?: boolean;
  @Trace backgroundColor?: ColorMetrics;

  constructor(options?: ActionBarStyleOptions) {
    this.isPrimaryIconChanged = options?.isPrimaryIconChanged;
    this.backgroundColor = options?.backgroundColor;
  }
}

@ObservedV2
export class ActionBarButton {
  @Trace id: string = '';
  @Trace baseIcon: Resource = $r('sys.symbol.bookmark');
  @Trace altIcon?: Resource;
  @Trace iconFillColor?: ColorMetrics;
  @Trace backgroundColor?: ColorMetrics;
  @Trace shadowStyle?: ShadowStyle;
  @Trace onClick?: () => void;
  @Trace enabled: boolean = true;
  @Trace accessibilityText?: ResourceStr;
  @Trace hoverTips?: ResourceStr;
  @Trace accessibilityDescription?: ResourceStr;
  @Trace buttonModifier?: ButtonModifier;

  constructor(options: ActionBarButtonOptions, buttonModifier?: ButtonModifier) {
    this.id = options.id;
    this.baseIcon = options.baseIcon;
    this.altIcon = options.altIcon;
    this.iconFillColor = options.iconFillColor;
    this.backgroundColor = options.backgroundColor;
    this.shadowStyle = options.shadowStyle;
    this.onClick = options.onClick;
    this.enabled = options.enabled ?? true;
    this.accessibilityText = options.accessibilityText;
    this.hoverTips = options.hoverTips;
    this.accessibilityDescription = options.accessibilityDescription;
    this.buttonModifier = buttonModifier;
  }
}

const ACTION_BAR_BUTTON_SIZE: number = 48;
const ACTION_BAR_PRIMARY_SIZE: number = 56;
const ACTION_BAR_ICON_SIZE: number = 24;

@ComponentV2
export struct RecorderActionBar {
  @Param startButtons: ActionBarButton[] = [];
  @Param endButtons: ActionBarButton[] = [];
  @Param primaryButton?: ActionBarButton = undefined;
  @Param isExpand: boolean = false;
  @Param actionBarStyle?: ActionBarStyle = undefined;

  private resolveAccessibilityText(text?: ResourceStr): string {
    if (!text) {
      return '';
    }
    if (typeof text === 'string') {
      return text;
    }
    return getContext(this).resourceManager.getStringSync(text);
  }

  @Builder
  ActionBarButtonItem(button: ActionBarButton, isPrimary: boolean = false) {
    Button({ type: ButtonType.Circle, stateEffect: true }) {
      SymbolGlyph(this.getButtonIcon(button, isPrimary))
        .fontSize(ACTION_BAR_ICON_SIZE)
        .fontColor([$r('sys.color.icon_primary')])
        .draggable(false)
    }
    .id(button.id)
    .width(isPrimary ? ACTION_BAR_PRIMARY_SIZE : ACTION_BAR_BUTTON_SIZE)
    .height(isPrimary ? ACTION_BAR_PRIMARY_SIZE : ACTION_BAR_BUTTON_SIZE)
    .backgroundColor(button.backgroundColor ?? ColorMetrics.resourceColor($r('sys.color.comp_background_tertiary')))
    .shadow(isPrimary && button.shadowStyle ? button.shadowStyle : undefined)
    .enabled(button.enabled)
    .opacity(button.enabled ? 1 : $r('sys.float.ohos_id_alpha_disabled'))
    .accessibilityText(this.resolveAccessibilityText(button.accessibilityText))
    .accessibilityDescription(this.resolveAccessibilityText(button.accessibilityDescription))
    .attributeModifier(button.buttonModifier)
    .onClick(() => {
      if (button.enabled && button.onClick) {
        button.onClick();
      }
    })
  }

  private getButtonIcon(button: ActionBarButton, isPrimary: boolean): Resource {
    if (isPrimary && this.actionBarStyle?.isPrimaryIconChanged && button.altIcon) {
      return button.altIcon;
    }
    return button.baseIcon;
  }

  build() {
    Row() {
      Row({ space: 8 }) {
        ForEach(this.startButtons, (button: ActionBarButton) => {
          this.ActionBarButtonItem(button, false)
        }, (button: ActionBarButton) => button.id)
      }

      if (this.isExpand) {
        Blank().layoutWeight(1)
      }

      if (this.primaryButton) {
        this.ActionBarButtonItem(this.primaryButton, true)
      }

      if (this.isExpand) {
        Blank().layoutWeight(1)
      }

      Row({ space: 8 }) {
        ForEach(this.endButtons, (button: ActionBarButton) => {
          this.ActionBarButtonItem(button, false)
        }, (button: ActionBarButton) => button.id)
      }
    }
    .width('100%')
    .height(ACTION_BAR_PRIMARY_SIZE)
    .justifyContent(this.isExpand ? FlexAlign.SpaceBetween : FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(this.actionBarStyle?.backgroundColor ??
      ColorMetrics.resourceColor($r('sys.color.comp_background_primary')))
    .padding({ left: 16, right: 16 })
  }
}
