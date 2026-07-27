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

import ArrayList from '@ohos.util.ArrayList';

/**
 * 校验工具
 *
 * @since 2025-09-30
 */
export default class Checker {
  private constructor() {}

  /**
   * 判断是否为空，null/undefined；string、array、map长度为0；返回true
   *
   * @param value 输入
   * @return true or false
   */
  public static isEmpty(value: Object | null | undefined): boolean {
    if (value === null || value === undefined) {
      return true;
    }

    if (Array.isArray(value)) {
      return value.length === 0;
    }

    if (value instanceof ArrayList) {
      return value.length === 0;
    }

    if ((typeof value === 'string') || (value instanceof String)) {
      return value.length === 0;
    }

    if (value instanceof Map) {
      return value.size === 0;
    }

    if (value instanceof Set) {
      return value.size === 0;
    }
    return false;
  }
}