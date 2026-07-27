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

export class TransferDataUtil {
  static getSummaryTextOrigin(data: Object): string {
    let valueArr = Object.entries(data).flatMap(([key, value]) => {
      console.log(`getSummaryTextOrigin:${key}`);
      let summaryTextOrigin = '';
      if (`${key}` === 'transcriptionResult') {
        value.forEach(ele => {
          summaryTextOrigin += ele.speakingContent;
        });
      }
      return summaryTextOrigin;
    });
    if (valueArr.length > 0) {
      let index = valueArr.findIndex((ele) => {
        return ele.length > 0;
      });
      console.log(`getSummaryTextOrigin:${JSON.stringify(valueArr)}`);
      return valueArr[index];
    }
    return '';
  }
}