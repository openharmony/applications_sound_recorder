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
import { LogUtil } from '@ohos/common';
import { ConsentManager, StandardContentTag } from '@ohos/recorder/src/main/ets/controller/ConsentManager';

const TAG: string = 'SoundRecorder_ConsentManagerTest';

export default function ConsentManagerTest() {

  describe('ConsentManagerTest', () => {

    it('ConsentManagerTest_001', 0, async () => {
      LogUtil.info(TAG + ' ConsentManagerTest_001 start');
      const consentManager = ConsentManager.getInstance();
      let urls = await consentManager.getUrl(false, StandardContentTag.PERSONAL_DATA);
      expect(urls.length).assertEqual(0);
      LogUtil.info(TAG + ' ConsentManagerTest_001 end');
    });

    it('ConsentManagerTest_002', 0, async () => {
      LogUtil.info(TAG + ' ConsentManagerTest_002 start');
      const consentManager = ConsentManager.getInstance();
      let uuid = consentManager.getUUID();
      expect(uuid).not().assertEqual('');
      LogUtil.info(TAG + ' ConsentManagerTest_002 end');
    });

  });
}