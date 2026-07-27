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

// instrument ignore file

import { LogUtil } from './LogUtil';

const TAG = 'SoundRecorder_ArrayUtil';

export class ArrayUtil {
  /**
   * 数组分片
   * @param array 原始数组
   * @param size 分片大小 (默认100)
   * @returns 分片后的二维数组
   *
   * @example1
   * 数字数组分片
   * chunk([1, 2, 3, 4, 5], 2) → [[1,2], [3,4], [5]]
   *
   * @example2
   * 对象数组分片
   * chunk([{id:1}, {id:2}], 1) → [[{id:1}], [{id:2}]]
   */
  public static chunk<T>(array: T[], size: number = 100): T[][] {
    if (!Number.isInteger(size) || size < 1) {
      LogUtil.error(`${TAG} Chunk size must be a positive integer`);
      return [];
    }

    const chunkCount = Math.ceil(array.length / size);
    const result: T[][] = new Array(chunkCount);

    for (let i = 0, j = 0; i < array.length; i += size, j++) {
      result[j] = array.slice(i, i + size);
    }

    return result;
  }
}
