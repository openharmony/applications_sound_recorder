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
import { LinkedList } from '@kit.ArkTS';

/**
 * [数组工具类]
 */
export class ArrayUtils {
  /**
   * 数组是否为空
   *
   * @param arr 输入集合对象
   * @return boolean
   */
  static isEmpty<T>(arr: Array<T>): boolean {
    return arr === null || arr === undefined || arr.length === 0;
  }
}