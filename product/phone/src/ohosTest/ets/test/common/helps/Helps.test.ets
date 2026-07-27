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
import { Helps } from '@ohos/common';

export default function HelpsTest() {
  describe('Helps.debounce_test', () => {
    it('Helps.debounce_test_001', 0, () => {
      const debouncedFunc: Function = Helps.debounce((...args: object[]) => {
        expect(args).assertDeepEquals([]);
      }, 50);

      debouncedFunc();
      debouncedFunc();
      debouncedFunc();
    });

    it('Helps.debounce_test_002', 0, () => {
      const debouncedFunc: Function = Helps.debounce((...args: object[]) => {
        expect(args).assertDeepEquals([]);
      }, 100);

      debouncedFunc();
      debouncedFunc();
      debouncedFunc();
    });

    it('Helps.debounce_test_003', 0, () => {
      const debouncedFunc: Function = Helps.debounce((...args: object[]) => {
        expect(args).assertDeepEquals([1, 2, 3]);
      }, 100);

      debouncedFunc(1, 2, 3);
      debouncedFunc(1, 2, 3);
      debouncedFunc(1, 2, 3);
    });

    it('Helps.debounce_test_004', 0, () => {
      const debouncedFunc: Function = Helps.debounce((...args: object[]) => {
        expect(args).assertDeepEquals([1, 2, 3]);
      }, 100);

      debouncedFunc(1, 2, 3);
      debouncedFunc(4, 5, 6);
      debouncedFunc(1, 2, 3);
    });
  });
}