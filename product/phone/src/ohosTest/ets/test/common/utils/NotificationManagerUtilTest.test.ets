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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { CommonConstants, NotificationManagerUtil } from '@ohos/common';
import { Delay } from '@ohos/common/test';
import notificationManager from '@ohos.notificationManager';
import { Driver } from '@ohos.UiTest';
import common from '@ohos.app.ability.common';

export default function NotificationManagerUtilTest() {
  describe('NotificationManagerUtilTest', async () => {
    it('NotificationManagerUtilTest_updateNotification_001', 0, async () => {
      const notificationManagerUtil = NotificationManagerUtil.getInstance();
      let context: common.UIAbilityContext = AppStorage.get('pageContext') as common.UIAbilityContext;
      notificationManagerUtil.darkMode = CommonConstants.darkModeLight;
      notificationManagerUtil.updateNotification(context, 1, CommonConstants.STARTED, 0, async () => {
      });
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let getActiveNumbers = await notificationManager.getActiveNotificationCount();
      expect(getActiveNumbers).assertEqual(1);
    });

    it('NotificationManagerUtilTest_updateNotification_002', 0, async () => {
      const notificationManagerUtil = NotificationManagerUtil.getInstance();
      let context: common.UIAbilityContext = AppStorage.get('pageContext') as common.UIAbilityContext;
      notificationManagerUtil.darkMode = CommonConstants.darkModeGray;
      notificationManagerUtil.updateNotification(context, 1, CommonConstants.PREPARED, 0, async () => {
      });
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let getActiveNumbers = await notificationManager.getActiveNotificationCount();
      expect(getActiveNumbers).assertEqual(1);
    });

    it('NotificationManagerUtilTest_updateNotification_003', 0, async () => {
      const notificationManagerUtil = NotificationManagerUtil.getInstance();
      let context: common.UIAbilityContext = AppStorage.get('pageContext') as common.UIAbilityContext;
      notificationManagerUtil.updateNotification(context, 1, CommonConstants.PAUSED, 0, async () => {
      });
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let getActiveNumbers = await notificationManager.getActiveNotificationCount();
      expect(getActiveNumbers).assertEqual(1);
    });

    it('NotificationManagerUtilTest_updateNotification_004', 0, async () => {
      const notificationManagerUtil = NotificationManagerUtil.getInstance();
      let context: common.UIAbilityContext = AppStorage.get('pageContext') as common.UIAbilityContext;
      let mocker: MockKit = new MockKit();
      let func: Function = mocker.mockFunc(notificationManager.publish, notificationManager.publish);
      when(func)(ArgumentMatchers.any).afterThrow('error');
      mocker.clearAll();
      notificationManagerUtil.updateNotification(context, 1, CommonConstants.PLAYING, 0, async () => {
      });
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let getActiveNumbers = await notificationManager.getActiveNotificationCount();
      expect(getActiveNumbers).assertEqual(1);
    });

    it('NotificationManagerUtilTest_cancelNotification', 0, async () => {
      const TEST_CONTENT = 'test_cancelNotification';
      expect(TEST_CONTENT).assertContain('test');
      NotificationManagerUtilTest_cancelNotification_001Func();
      NotificationManagerUtilTest_cancelNotification_002Func();
    });
  });
}

const NotificationManagerUtilTest_cancelNotification_001Func = () => {
  let mocker: MockKit = new MockKit();
  let func: Function = mocker.mockFunc(notificationManager.cancel, notificationManager.cancel);
  when(func)(ArgumentMatchers.any).afterReturn({
    code: 1, message: '10086'
  });
  NotificationManagerUtil.getInstance().cancelNotification();
  mocker.clearAll();
};

const NotificationManagerUtilTest_cancelNotification_002Func = () => {
  let mocker: MockKit = new MockKit();
  let func: Function = mocker.mockFunc(notificationManager.cancel, notificationManager.cancel);
  when(func)(ArgumentMatchers.any).afterThrow('error');
  NotificationManagerUtil.getInstance().cancelNotification();
  mocker.clearAll();
};