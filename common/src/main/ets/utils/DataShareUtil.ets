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

import dataShare from '@ohos.data.dataShare';
import { LogUtil } from './LogUtil';

const TAG = 'SoundRecorder_DataShareUtil';

export class DataShareUtil {
  private static dataShareHelper?: dataShare.DataShareHelper;

  static async getDataShareHelper(context: Context, uri: string): Promise<dataShare.DataShareHelper | undefined> {
    if (DataShareUtil.dataShareHelper) {
      return DataShareUtil.dataShareHelper;
    }
    try {
      DataShareUtil.dataShareHelper = await dataShare.createDataShareHelper(context, uri);
    } catch (err) {
      LogUtil.error(TAG + ` createDataShareHelper failed, code: ${err.code}, message: ${err.message}`);
    }
    return DataShareUtil.dataShareHelper;
  }

  static async closeDataShareHelper(): Promise<void> {
    try {
      await DataShareUtil.dataShareHelper?.close();
    } catch (err) {
      LogUtil.error(TAG + ` closeDataShareHelper failed, code: ${err.code}, message: ${err.message}`);
    }
  }
}