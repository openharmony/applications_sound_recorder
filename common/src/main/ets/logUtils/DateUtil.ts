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

namespace dateUtil {
  /**
   * 日期格式化
   *
   * @param fmt 格式化字符串，比如 YYYYMMddHHmmssSSS
   * @param date 日期
   * @return string 格式化之后的日期
   */
  export function dateFormat(fmt: string, date: Date | number): string {
    let realDate: Date = typeof date === 'number' ? new Date(date) : date;
    const opt: Map<string, string> = new Map();
    opt.set('Y+', realDate.getFullYear().toString());
    opt.set('M+', (realDate.getMonth() + 1).toString());
    opt.set('d+', realDate.getDate().toString());
    opt.set('H+', realDate.getHours().toString());
    opt.set('m+', realDate.getMinutes().toString());
    opt.set('s+', realDate.getSeconds().toString());
    opt.set('S+', realDate.getMilliseconds().toString());
    let dateStr: string = fmt;
    for (let key of opt.keys()) {
      const ret: RegExpExecArray = new RegExp(`(${key})`).exec(fmt);
      if (ret) {
        dateStr = dateStr.replace(ret[1], (ret[1].length === 1) ? opt.get(key) : opt.get(key).padStart(ret[1].length, '0'));
      }
    }
    return dateStr;
  }
}

export default dateUtil;