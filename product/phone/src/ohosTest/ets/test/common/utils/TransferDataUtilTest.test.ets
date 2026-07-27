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
import { afterEach, ArgumentMatchers, beforeEach, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { DeviceType, DeviceUtil } from '@ohos/common';

export default function DeviceUtilTest() {
  describe('isPC_testSuite', () => {

    it('should_is_pc_return_true_when_deviceType_is_PC', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.PC)
      expect(DeviceUtil.isPC()).assertEqual(true);
    });

    it('should_is_pc_return_false_when_deviceType_is_phone', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.PHONE)
      expect(DeviceUtil.isPC()).assertEqual(false);
    });

    it('should_is_pc_return_false_when_deviceType_is_tablet', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.TABLET)
      expect(DeviceUtil.isPC()).assertEqual(false);
    });

  });

  describe('isPhone_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });


    it('should_is_phone_return_true_when_deviceType_is_phone', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.PHONE)
      expect(DeviceUtil.isPhone()).assertEqual(true);
    });

    it('should_is_phone_return_false_when_deviceType_is_pc', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.PC)
      expect(DeviceUtil.isPhone()).assertEqual(false);
    });

    it('should_is_phone_return_false_when_deviceType_is_tablet', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.TABLET)
      expect(DeviceUtil.isPhone()).assertEqual(false);
    });

  });

  describe('isTablet_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('should_is_tablet_return_true_when_deviceType_is_tablet', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.TABLET)
      expect(DeviceUtil.isTablet()).assertEqual(true);
    });

    it('should_is_tablet_return_false_when_deviceType_is_pc', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.PC)
      expect(DeviceUtil.isTablet()).assertEqual(false);
    });

    it('should_is_tablet_return_false_when_deviceType_is_phone', 0, () => {
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(DeviceUtil, DeviceUtil.getDeviceType);
      when(func)(ArgumentMatchers.any).afterReturn(DeviceType.PHONE)
      expect(DeviceUtil.isTablet()).assertEqual(false);
    });

  });
}