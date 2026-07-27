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

import { DeviceUtil } from './DeviceUtil';

export enum HoverTextTipsStyle {
  HOVER_MENU_MAX_WIDTH = 604,
  HOVER_DEFAULT_TAG_MAX_WIDTH = 400,
  BIND_POPUP_TARGET_SPACE = 8,
  HOVER_MENU_FONT_SIZE = 14,
  HOVER_MENU_HORIZON_PADDING = 16,
  HOVER_MENU_VERTICAL_PADDING = 8,
  HOVER_MENU_TEXT_OPACITY = 0.6,
  HOVER_MENU_LINE_HEIGHT = 19,
  HOVER_MENU_BORDER_RADIUS = 16,
  ADDRESS_BAR_HOVER_HEIGHT_LIMIT = 20
}

const HOVER_TIPS_TIME: number = 850;


export class HoverTextTipsUtil {

  // 全局只有一个唯一hover，只需持有一个全局唯一的timer
  private static showTipsTimerId: number = -1;

  public static getPopupShadow(): ShadowOptions | ShadowStyle {
    if (DeviceUtil.isPC()) {
      return {
        offsetX: 0,
        offsetY: 0,
        radius: 16,
        color: '#33000000'
      }
    }
    return ShadowStyle.OUTER_DEFAULT_MD;
  }

  /**
   * 根据hover的状态和时间，控制提示语(tips)弹出
   * @param isHover：表示当前Hover状态
   * @param callback：控制提示语的弹出的回调
   */
  public static showTipsTimer(isHover: boolean, callback: (isHover: boolean) => void): void {
    if (isHover) {
      HoverTextTipsUtil.clearTipsTimer(HoverTextTipsUtil.showTipsTimerId);
      HoverTextTipsUtil.showTipsTimerId = HoverTextTipsUtil.delayExecute(() => {
        callback(true);
      }, HOVER_TIPS_TIME);
    } else {
      callback(false);
      HoverTextTipsUtil.clearTipsTimer(HoverTextTipsUtil.showTipsTimerId);
    }
  }

  private static clearTipsTimer(showTipsTimerId: number): void {
    if (showTipsTimerId >= 0) {
      clearTimeout(HoverTextTipsUtil.showTipsTimerId);
      HoverTextTipsUtil.showTipsTimerId = -1;
    }
  }

  /**
   * 设置定时器
   *
   * @param callback 回调处理
   * @param delay 延时时间
   * @param 定时器Id
   */
  public static delayExecute(callback: () => void, delay: number): number {
    let timeoutId: number = setTimeout(() => {
      callback();
      clearTimeout(timeoutId);
    }, delay);
    return timeoutId;
  }
}