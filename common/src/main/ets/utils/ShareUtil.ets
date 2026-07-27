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

import utd from '@ohos.data.uniformTypeDescriptor';
import { fileUri } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';
import { Callback } from '@ohos.base';
import { ObjectUtil } from './ObjectUtil';
import { RecordData } from '../model/RecordData';
import { HiSysEventUtil } from './HiSysEventUtil';
import { CommonConstants } from '../constants/CommonConstants';
import { LogUtil } from './LogUtil';
import { Util } from './Util';

const TAG = `SoundRecorder_ShareUtil`;

export interface ShareModalParams {
  context: common.UIAbilityContext;
  srcData: RecordData[],
  eventName: string // HiSysEventName
  onDismiss?: Callback<void>
  offDismiss?: Callback<void>
}

export class ShareUtil {

  /**
   * 返回文件扩展名，如.m4a
   * @param filename
   * @returns
   */
  /* instrument ignore next */
  private static getFileExtension(filePath: string) {
    return filePath.substring(filePath.lastIndexOf('.'));
  }

  /* instrument ignore next */
  public static showModal(params: ShareModalParams) {
    const srcData = params.srcData;
    const srcDataLength = srcData.length;
    if (!srcDataLength) {
      LogUtil.error(`${TAG} failed to show share modal, records: ${srcDataLength}`);
      return;
    }

    const ctx = params.context;
    const eventName = params.eventName;

    HiSysEventUtil.eventDotting(eventName, { VALUE: CommonConstants.SUCCESS, NUM: srcDataLength });
    LogUtil.info(`${TAG} show share modal success, records: ${srcDataLength}`);
  }
}