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

import { LogUtil } from '@ohos/common';
import { GlobalRecordState } from '../constant/AudioConstant';

const TAG = '[RecordStateManagerTag]';

/**
 * 录音状态管理，主要区分当前是手机录音还是耳机录音
 */
class RecordStateManager {
  private static instance: RecordStateManager;
  private curRecordState: GlobalRecordState = GlobalRecordState.IDLE;

  private constructor() {
  }

  public static getInstance(): RecordStateManager {
    if (!RecordStateManager.instance) {
      RecordStateManager.instance = new RecordStateManager();
    }
    return RecordStateManager.instance;
  }

  public changeRecordState(state: GlobalRecordState): void {
    if (this.curRecordState === state) {
      return;
    }
    LogUtil.info(`${TAG} GlobalRecordState change: [${this.curRecordState}] => [${state}]`);
    this.curRecordState = state;
  }

  public getCurrentRecordState(): GlobalRecordState {
    return this.curRecordState;
  }
}

export default RecordStateManager.getInstance();