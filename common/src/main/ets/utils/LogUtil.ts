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
import HiLog from '@ohos.hilog';
import { PafLogUtil } from '../logUtils/PafLogUtil';

const DOMAIN = 0x0500;
const TAG = '[Recorder]';

/**
 *  log package tool class
 */
export class LogUtil {
  static debug(msg: string): void {
    HiLog.debug(DOMAIN, TAG, msg);
    PafLogUtil.debug(msg);
  }

  static log(msg: string): void {
    HiLog.info(DOMAIN, TAG, msg);
    PafLogUtil.info(msg);
  }

  static info(msg: string): void {
    HiLog.info(DOMAIN, TAG, msg);
    PafLogUtil.info(msg);
  }

  static warn(msg: string): void {
    HiLog.warn(DOMAIN, TAG, msg);
    PafLogUtil.warn(msg);
  }

  static error(msg: string): void {
    HiLog.error(DOMAIN, TAG, msg);
    PafLogUtil.error(msg);
  }
}