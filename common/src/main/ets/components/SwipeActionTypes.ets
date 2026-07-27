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

import { SymbolGlyphModifier } from '@kit.ArkUI';

export interface SwipeIconOptions {
  accessibilityText?: ResourceStr;
  enable?: boolean;
}

export interface SwipeIconConfigurations {
  icon: SymbolGlyphModifier;
  backgroundColor: ResourceColor;
  iconOptions?: SwipeIconOptions;
  onAction: () => void;
}

export interface SwipeDeleteIconOptions {
  iconOptions?: SwipeIconOptions;
  onAction: () => void;
}

export interface SwipeFullDeleteOptions {
  isFullDelete?: boolean;
  onFullDeleteAction: () => void;
}

export interface SwipeActionDynamicOptions {
  icons: SwipeIconConfigurations[];
  deleteIconOptions?: SwipeDeleteIconOptions;
  fullDeleteOptions?: SwipeFullDeleteOptions;
}
