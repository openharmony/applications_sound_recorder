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

import { describe, expect, it } from '@ohos/hypium';
import { LogUtil, NotificationUtil } from '@ohos/common';
import display from '@ohos.display';

const TAG: string = 'SoundRecorder_NotificationUtilTest';

export default function NotificationUtilTest() {
  describe('NotificationUtilTest', () => {
    /**
     * @tc.number:NotificationUtilTest_001
     * @tc.name: NotificationUtil工具类测试
     */
    it('NotificationUtilTest_001', 0, async () => {
      LogUtil.info(TAG + ' NotificationUtilTest_001 start');
      let isScreenOn = NotificationUtil.getScreenState();
      let tmpState = !isScreenOn;
      NotificationUtil.setScreenState(tmpState);
      if (tmpState) {
        expect(NotificationUtil.getScreenState()).assertTrue();
      } else {
        expect(NotificationUtil.getScreenState()).assertFalse();
      }
      NotificationUtil.setScreenState(isScreenOn);
      LogUtil.info(TAG + ' NotificationUtilTest_001 end');
    });

    /**
     * @tc.number:NotificationUtilTest_002
     * @tc.name: NotificationUtil工具类测试
     */
    it('NotificationUtilTest_002', 0, async () => {
      LogUtil.info(TAG + ' NotificationUtilTest_002 start');
      let displayMode = NotificationUtil.getDisplayMode();
      let tmpDisplayMode = display.FoldDisplayMode.FOLD_DISPLAY_MODE_UNKNOWN;
      NotificationUtil.setDisplayMode(tmpDisplayMode);
      expect(NotificationUtil.getDisplayMode()).assertEqual(tmpDisplayMode);
      NotificationUtil.setDisplayMode(displayMode);
      LogUtil.info(TAG + ' NotificationUtilTest_002 end');
    });

    /**
     * @tc.number:NotificationUtilTest_003
     * @tc.name: NotificationUtil工具类测试
     */
    it('NotificationUtilTest_003', 0, async () => {
      LogUtil.info(TAG + ' NotificationUtilTest_003 start');
      let title = '录音机';
      let id = 1;
      let midContent = 'midContent';
      let bottomContent = 'bottomContent';
      let fontSize = 10;
      let requestData = NotificationUtil.buildOngoingNotification(title, id, midContent, bottomContent, fontSize);
      expect(requestData.content.normal?.title).assertEqual(title);
      LogUtil.info(TAG + ' NotificationUtilTest_003 end');
    });
  });
}