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

import { Callback } from '@ohos.base';
import display from '@ohos.display';

import { LogUtil } from '@ohos/common';


const FOLD_CHANGE_EVENT = 'foldDisplayModeChange';
/**
 * 监听折叠状态变化
 */
export class FoldStateListener {

  private static registedCB: Callback<display.FoldDisplayMode>;
  private static isRegisted = false;

  static registerFoldStatusListener(callback: Callback<display.FoldDisplayMode>) {
    LogUtil.info('registerFoldStatusListener');
    try {
      FoldStateListener.unRegisterFoldStatusListener();
      display.on(FOLD_CHANGE_EVENT, callback);
      FoldStateListener.isRegisted = true;
      FoldStateListener.registedCB = callback;
    } catch (err) {
      LogUtil.error(` Failed to register callback. code: ${err?.code}, message: ${err?.message}`);
    }
  }

  /* instrument ignore next */
  static unRegisterFoldStatusListener() {
    LogUtil.info('unRegisterFoldStatusListener');
    try {
      if (FoldStateListener.isRegisted) {
        display.off(FOLD_CHANGE_EVENT, FoldStateListener.registedCB);
        FoldStateListener.isRegisted = false;
        LogUtil.info('off success');
      }
    } catch (err) {
      LogUtil.error(`Failed to register callback. code: ${err?.code}, message: ${err?.message}`);
    }
  }
}

export default new FoldStateListener();