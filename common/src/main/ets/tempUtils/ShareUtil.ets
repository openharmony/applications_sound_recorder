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
import systemShare from '../systemShare';
import { ObjectUtil } from '../utils/ObjectUtil';
import { RecordData } from '../model/RecordData';
import { HiSysEventUtil } from './HiSysEventUtil';
import { CommonConstants } from '../constants/CommonConstants';
import { LogUtil } from '../utils/LogUtil';
import { Util } from './Util';

const TAG = `SoundRecorder_ShareUtil`;

export interface ShareModalParams {
  context: common.UIAbilityContext;
  srcData: RecordData[],
  eventName: string // HiSysEventName
  options?: systemShare.ShareControllerOptions
  onDismiss?: Callback<void>
  offDismiss?: Callback<void>
}

export class ShareUtil {
  /* instrument ignore next */
  private static getModalDefaultOptions(srcDataLength: number): systemShare.ShareControllerOptions {
    return {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: srcDataLength > 1 ? systemShare.SelectionMode.BATCH : systemShare.SelectionMode.SINGLE
    };
  }

  /**
   * 返回文件扩展名，如.m4a
   * @param filename
   * @returns
   */
  /* instrument ignore next */
  private static getFileExtension(filePath: string) {
    return filePath.substring(filePath.lastIndexOf('.'));
  }

  private static recordDataToShareRecord(ctx: common.UIAbilityContext,
    recordData: RecordData): systemShare.SharedRecord {
    let title = recordData.title;
    let path = recordData._data;

    // instrument ignore if
    if (recordData.phoneNumber) {
      // 通话录音
      title = `${recordData.name}${ShareUtil.getFileExtension(path)}`;
      path = Util.getSharePathToCopy(recordData._data, title, ctx, true);
    }

    return {
      utd: utd.UniformDataType.AUDIO,
      uri: fileUri.getUriFromPath(path),
      title
    }
  }

  private static recordDataListToShareData(ctx: common.UIAbilityContext,
    recordDataList: RecordData[]): systemShare.SharedData {
    const shareData = new systemShare.SharedData(ShareUtil.recordDataToShareRecord(ctx, recordDataList[0]));
    recordDataList.slice(1).forEach(item => shareData.addRecord(ShareUtil.recordDataToShareRecord(ctx, item)));
    return shareData;
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
    const options = ObjectUtil.assign(ShareUtil.getModalDefaultOptions(srcDataLength), params.options);
    const shareData = ShareUtil.recordDataListToShareData(ctx, srcData);

    try {
      const controller = new systemShare.ShareController(shareData);
      controller.show(ctx, options);
      params.onDismiss && controller.on('dismiss', params.onDismiss);
      params.offDismiss && controller.off('dismiss', params.offDismiss);
    } catch (e) {
      HiSysEventUtil.eventDotting(eventName, { VALUE: CommonConstants.FAILURE, NUM: srcDataLength });
      LogUtil.error(`${TAG} failed to show share modal, records: ${srcDataLength}, code: ${e.code}, message: ${e.message}`);
    }

    HiSysEventUtil.eventDotting(eventName, { VALUE: CommonConstants.SUCCESS, NUM: srcDataLength });
    LogUtil.info(`${TAG} show share modal success, records: ${srcDataLength}`);
  }
}