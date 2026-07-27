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

import { BusinessError } from '@ohos.base';
import { JSON } from '@kit.ArkTS';
import commonEventManager from '@ohos.commonEventManager';
import { statfs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import GlobalContext from './GlobalContext';
import { LogUtil } from './LogUtil';

interface ICommonEventData {
  faultDescription: string;
  faultSuggestion: string;
  publisherBundleName: string;
}

const TAG = 'SoundRecorder_MemoryManager';

export class MemoryManager {

  /* instrument ignore next */
  public static async getFreeSize(): Promise<number> {
    let context = GlobalContext.getUIAbilityContext();
    let path = context.filesDir;
    return await statfs.getFreeSize(path);
  }

  public static insufficientStorageDialog() {
    let data: ICommonEventData = {
      faultDescription: '845010023',
      faultSuggestion: '545010023',
      publisherBundleName: 'com.ohos.soundrecorder' // 发送者自己的包名
    };
    let options: commonEventManager.CommonEventPublishData = {
      bundleName: 'com.hmos.hiviewcare',
      data: JSON.stringify(data)
    };

    /* instrument ignore next */
    commonEventManager.publish('hicare.event.SMART_NOTIFICATION', options, (err: BusinessError) => {
      if (err) {
        LogUtil.error(`${TAG} pullUpIntelligentDetectionDialog publish failed, err.code: ${err.code},
        err.message: ${err.message}`);
      } else {
        LogUtil.error(`${TAG} pullUpIntelligentDetectionDialog pushlish success`);
      }
    });
  }


}