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
import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';

export default function DatabaseManagerTest() {
  describe('getRestDays_testSuite', () => {

    it('should_return_30_days_when_delete_time_in_future', 0, () => {
      const delete_time = Date.now() + 24 * 60 * 60 * 1000; // 1 day ago
      const result = DatabaseManager.getRestDays(delete_time);
      expect(result).assertEqual(30);
    });

    it('should_return_30_days_when_delete_time_is_in_1_day', 0, () => {
      const delete_time = Date.now() - 4 * 60 * 60 * 1000; // 1 day ago
      const result = DatabaseManager.getRestDays(delete_time);
      expect(result).assertEqual(30);
    });

    it('should_return_29_days_when_delete_time_is_1_day_ago', 0, () => {
      const delete_time = Date.now() - 24 * 60 * 60 * 1000; // 1 day ago
      const result = DatabaseManager.getRestDays(delete_time);
      expect(result).assertEqual(29);
    });

    it('should_return_1_when_delete_time_is_more_than_30_days_ago', 0, () => {
      const delete_time = Date.now() - 31 * 24 * 60 * 60 * 1000; // 31 days ago
      const result = DatabaseManager.getRestDays(delete_time);
      expect(result).assertEqual(1);
    });

    it('should_return_30_when_rest_days_is_more_than_30', 0, () => {
      const delete_time = Date.now() - 61 * 24 * 60 * 60 * 1000; // 61 days ago
      const result = DatabaseManager.getRestDays(delete_time);
      expect(result).assertEqual(1);
    });
  });
}
