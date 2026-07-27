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
import { backgroundTaskManager } from '@kit.BackgroundTasksKit';
import { CommonConstants } from '../constants/CommonConstants';
import { LogUtil } from './LogUtil';


const TAG = 'SoundRecorder_BackgroundTaskManagerUtil ';

/**
 * BackgroundTaskManagerUtil 方法
 *
 * @since 2025-11-11
 */

class BackgroundTaskManagerUtil {
  /* instrument ignore next */
  private applyEfficiencyResourcesInternal(timeOut: number, isPersist: boolean, reason: string): boolean {
    const request: backgroundTaskManager.EfficiencyResourcesRequest = {
      resourceTypes: backgroundTaskManager.ResourceType.CPU,
      isApply: true,
      timeOut,
      reason,
      isPersist,
      isProcess: false
    };

    const operationName = isPersist
      ? `setPersistEfficiencyResources`
      : `setTimeOutEfficiencyResources(time=${timeOut})`;

    try {
      backgroundTaskManager.applyEfficiencyResources(request);
      LogUtil.info(TAG + `${operationName} success.`);
      return true;
    } catch (err) {
      LogUtil.error(TAG + `${operationName} failed. code=${err.code}, message=${err.message}`);
      return false;
    }
  }

  /* instrument ignore next */
  public setPersistEfficiencyResources(reason: string): boolean {
    return this.applyEfficiencyResourcesInternal(CommonConstants.PERMANENT_TIMEOUT_VALUE, true, reason);
  }

  /* instrument ignore next */
  public setTimeOutEfficiencyResources(time: number, reason: string): boolean {
    if (!Number.isFinite(time) || time < 0) {
      LogUtil.error(TAG + `setTimeOutEfficiencyResources set invalid time:${time}`);
      return false;
    }
    return this.applyEfficiencyResourcesInternal(time, false, reason);
  }


  /* instrument ignore next */
  public resetEfficiencyResources(): boolean {
    try {
      backgroundTaskManager.resetAllEfficiencyResources();
      LogUtil.info(TAG + `resetEfficiencyResources success. `);
      return true;
    } catch (err) {
      LogUtil.error(TAG + `resetEfficiencyResources failed. code=${err.code}, message=${err.message}`);
    }
    return false;
  }
}

export default new BackgroundTaskManagerUtil();