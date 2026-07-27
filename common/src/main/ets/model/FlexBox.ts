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

export namespace flexBox {
  const narrowScreenBreakpoints = {
    SM: 280,
    MD: 360
  } as const;

  export const wideScreenBreakpoints = {
    SM: 380,
    MD: 780
  } as const;

  export interface Margin {
    top?: number;
    bottom?: number;
  }

  export interface RangeLimit {
    max: number;
    min: number;
  }

  export interface SizeBreakpointMap {
    sm: number;
    md: number;
    lg: number;
  }

  export const enum HeightBreakpoint {
    SM = 'sm',
    MD = 'md',
    LG = 'lg'
  }

  export interface FlexBox {
    height?: number;
    width?: number;
    margin?: Margin;
    visible?: boolean;
    flexShrink?: number;
  }

  /**
   * 获取元素布局高度（包含边距）
   */
  export function getLayoutHeight(box: FlexBox): number {
    if (!box.visible) {
      return 0;
    }

    const marginTop = box.margin?.top ?? 0;
    const marginBottom = box.margin?.bottom ?? 0;
    const height = box.height ?? 0;
    return height + marginTop + marginBottom;
  }

  /**
   * 获取窄屏高度断点类型
   * @param height 当前高度值
   */
  /* instrument ignore next */
  export function getNarrowScreenHeightBreakpoint(height: number): HeightBreakpoint {
    if (height < narrowScreenBreakpoints.SM) {
      return HeightBreakpoint.SM;
    }
    if (height < narrowScreenBreakpoints.MD) {
      return HeightBreakpoint.MD;
    }
    return HeightBreakpoint.LG;
  }

  /**
   * 获取宽屏高度断点类型
   * @param height 当前高度值
   */
  /* instrument ignore next */
  export function getWideScreenHeightBreakpoint(height: number): HeightBreakpoint {
    if (height < wideScreenBreakpoints.SM) {
      return HeightBreakpoint.SM;
    }
    if (height < wideScreenBreakpoints.MD) {
      return HeightBreakpoint.MD;
    }
    return HeightBreakpoint.LG;
  }
}