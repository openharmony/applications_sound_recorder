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
import { flexBox } from '@ohos/common';
import { describe, expect, it } from '@ohos/hypium';
export default function FlexBoxTestTest() {

  describe('flexBox.getLayoutHeight_testSuite', () => {

    it('should_return_0_when_box_is_not_visible', 0, () => {
      let box: flexBox.FlexBox = {
        height: 100,
        margin: { top: 10, bottom: 5 },
        visible: false
      };
      const result = flexBox.getLayoutHeight(box);
      expect(result).assertEqual(0);
    });

    it('should_return_sum_of_height_and_margins_when_box_is_visible', 0, () => {
      let box:flexBox.FlexBox = {
        height: 100,
        margin: { top: 10, bottom: 5 },
        visible: true
      };
      const result = flexBox.getLayoutHeight(box);
      expect(result).assertEqual(115);
    });

    it('should_return_sum_of_height_and_margins_when_box_is_visible_and_margin_is_undefined', 0, () => {
      let box:flexBox.FlexBox = {
        height: 100,
        margin: undefined,
        visible: true
      };
      const result = flexBox.getLayoutHeight(box);
      expect(result).assertEqual(100);
    });

    it('should_return_SM_when_height_is_less_than_SM_Breakpoint', 0, () => {
      let height: number = 100;
      let result: flexBox.HeightBreakpoint = flexBox.getNarrowScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.SM);
    });

    it('should_return_MD_when_height_is_less_than_MD_Breakpoint', 0, () => {
      let height: number = 300;
      let result: flexBox.HeightBreakpoint = flexBox.getNarrowScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.MD);
    });

    it('should_return_LG_when_height_is_greater_than_or_equal_to_MD_Breakpoint', 0, () => {
      let height: number = 500;
      let result: flexBox.HeightBreakpoint = flexBox.getNarrowScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.LG);
    });

    it('should_return_SM_when_height_is_less_than_SM_breakPoint', 0, () => {
      let height: number = flexBox.wideScreenBreakpoints.SM - 1;
      const result = flexBox.getWideScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.SM);
    });

    it('should_return_MD_when_height_is_less_than_MD_breakPoint', 0, () => {
      let height: number = flexBox.wideScreenBreakpoints.MD - 1;
      const result = flexBox.getWideScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.MD);
    });

    it('should_return_LG_when_height_is_greater_than_or_equal_to_MD_breakPoint', 0, () => {
      let height: number = flexBox.wideScreenBreakpoints.MD;
      const result = flexBox.getWideScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.LG);
    });

    it('should_return_LG_when_height_is_greater_than_MD_breakPoint', 0, () => {
      let height: number = flexBox.wideScreenBreakpoints.MD + 1;
      const result = flexBox.getWideScreenHeightBreakpoint(height);
      expect(result).assertEqual(flexBox.HeightBreakpoint.LG);
    });
  });
}
