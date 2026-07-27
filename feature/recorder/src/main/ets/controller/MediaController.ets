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

import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import abilityAccessCtrl, { Permissions } from '@ohos.abilityAccessCtrl';
import bundleManager from '@ohos.bundle.bundleManager';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import fs from '@ohos.file.fs';
import { RecordData } from '@ohos/common/src/main/ets/model/RecordData';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import { DeviceUtil } from '@ohos/common';

const TAG = 'SoundRecorder_MediaController';

@CustomDialog
export struct FileDeletedComponent {
  controller?: CustomDialogController;

  constructor() {
    super();
  }

  private async refreshRecordList(): Promise<void> {
    let removedCallList: RecordData[] = [];
    let callRecordList = await DatabaseManager.getInitialCallRecordList();
    LogUtil.info(TAG + ' refreshRecordList callRecordList length: ' + callRecordList.length);
    for (let index = 0; index < callRecordList.length; index++) {
      if (!fs.accessSync(callRecordList[index]._data)) {
        removedCallList.push(callRecordList[index]);
      }
    }
    LogUtil.info(TAG + ' removed call record file count: ' + removedCallList.length);
    await DatabaseManager.removeCallRecordData(removedCallList.map(item => item._data));

    let removedRecentDeleteList: RecordData[] = [];
    let recentDeleteList = await DatabaseManager.getAllDbQuery('recent_delete_record_table')
    LogUtil.info(TAG + ' refreshRecordList recentDeleteList length: ' + recentDeleteList.length);
    for (let index = 0; index < recentDeleteList.length; index++) {
      if (!fs.accessSync(recentDeleteList[index]._data)) {
        removedRecentDeleteList.push(recentDeleteList[index])
      }
    }
    LogUtil.info(TAG + ' removed recent delete record file count: ' + removedRecentDeleteList.length);
    await DatabaseManager.removeRecentDeleteRecordData(removedRecentDeleteList.map(item => item._data));

    let removedNormalList: RecordData[] = [];
    let normalRecordList = await DatabaseManager.getAllDbQuery('normal_record_table');
    LogUtil.info(TAG + ' refreshRecordList normalRecordList length: ' + normalRecordList.length);
    for (let index = 0; index < normalRecordList.length; index++) {
      if (!fs.accessSync(normalRecordList[index]._data)) {
        removedNormalList.push(normalRecordList[index]);
      }
    }
    LogUtil.info(TAG + ' removed normal record file count: ' + removedNormalList.length);
    await DatabaseManager.removeNormalRecordData(removedNormalList.map(item => item._data));

    getContext().eventHub.emit('removeIndexList', removedCallList.concat(removedRecentDeleteList, removedNormalList), true);
    MediaController.controller?.close();
  }

  @Builder
  buildContent(context: ResourceStr): void {
    Column() {
      Text(context)
    }
    .width('100%')
    .align(Alignment.Center)
  }

  build() {
    CustomContentDialog({
      primaryTitle: $r('app.string.file_has_been_deleted'),
      contentBuilder: () => {
        this.buildContent($r('app.string.file_has_been_deleted_description'))
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          fontColor: '#FB654E',
          background: Color.Transparent,
          buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
          action: () => {
            LogUtil.info(TAG + ` user canceled the delete note dialog.`);
            MediaController.controller?.close();
          }
        },
        {
          value: $r('app.string.file_list_refresh'),
          fontColor: '#FB654E',
          background: Color.Transparent,
          buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
          action: () => {
            this.refreshRecordList();
          }
        }
      ]
    })
  }
}

export default class MediaController {
  public static controller?: CustomDialogController;

  public static async checkAccessToken(permission: Permissions): Promise<abilityAccessCtrl.GrantStatus> {
    let atManager = abilityAccessCtrl.createAtManager();
    let grantStatus: abilityAccessCtrl.GrantStatus = {} as abilityAccessCtrl.GrantStatus;

    // 获取应用程序的accessTokenID
    let tokenId: number = 0;
    try {
      let bundleInfo: bundleManager.BundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager
        .BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      let appInfo: bundleManager.ApplicationInfo = bundleInfo.appInfo;
      tokenId = appInfo.accessTokenId;
    } catch (err) {
      LogUtil.error(TAG + ` getBundleInfoForSelf failed, code is ${err.code}, message is ${err.message}`);
    }

    // 校验应用是否被授予权限
    try {
      grantStatus = await atManager.checkAccessToken(tokenId, permission);
    } catch (err) {
      LogUtil.error(TAG + ` checkAccessToken failed, code is ${err.code}, message is ${err.message}`);
    }

    return grantStatus;
  }

  // 文管删除沙盒中的录音文件时弹窗
  public static async openFileDeletedDialog(controller?: CustomDialogController) {
    MediaController.controller = controller;
    controller?.open();
  }
}
