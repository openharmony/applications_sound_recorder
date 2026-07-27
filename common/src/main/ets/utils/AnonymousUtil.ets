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
export class AnonymousUtil {
  static anonymous(value: string, reserveLength: number = 4, reg: string = '*'): string {
    // instrument ignore if
    if (reserveLength < 0) {
      return value;
    }

    let length = value.length;

    if (reserveLength > length) {
      return AnonymousUtil.fillStringByNum(reg, length);
    }

    let start = length / 2 - reserveLength / 2;
    let end = start + Math.min(length - start, reserveLength);
    let numberOfReg = end - start;

    return value.substring(0, start) + AnonymousUtil.fillStringByNum(reg, numberOfReg) + value.substring(end);
  }

  static fillStringByNum(reg: string, num: number) {
    let regString = '';
    for (let i = 0; i < num; i++) {
      regString += reg;
    }
    return regString;
  }
}