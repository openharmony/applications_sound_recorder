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
import { DeviceUtil, HoverTextTipsUtil } from '@ohos/common';
import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect, MockKit, when, ArgumentMatchers } from '@ohos/hypium';
export default function HoverTextTipsUtilTest() {
  describe('getPopupShadow_testSuite', () => {

    it('should_return_shadow_options_when_device_is_PC', 0, () => {
      let mocker: MockKit = new MockKit();
      when(mocker.mockFunc(DeviceUtil, DeviceUtil.isPC))(ArgumentMatchers.any).afterReturn(true);
      const result = HoverTextTipsUtil.getPopupShadow();
      expect((result as ShadowOptions).offsetX).assertEqual(0);
      expect((result as ShadowOptions).offsetY).assertEqual(0);
      expect((result as ShadowOptions).radius).assertEqual(16);
      expect((result as ShadowOptions).color).assertEqual('#33000000');
    });

    it('should_return_shadow_style_when_device_is_not_PC', 0, () => {
      let mocker: MockKit = new MockKit();
      when(mocker.mockFunc(DeviceUtil, DeviceUtil.isPC))(ArgumentMatchers.any).afterReturn(false);
      const result = HoverTextTipsUtil.getPopupShadow();
      expect(result).assertInstanceOf('Number');
      expect(result).assertEqual(ShadowStyle.OUTER_DEFAULT_MD);
    });
  });


}
