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

import notificationManager from '@ohos.notificationManager';
import Base, { BusinessError } from '@ohos.base';
import display from '@ohos.display';

import { LogUtil, Util, NotificationUtil, CommonConstants } from '@ohos/common';


const TAG = 'SoundRecorder_RecordNotification';
const timeSize = 36;
const recordNoteId = 1;
const timeIntervalMinus = 1000;
let mPreScreenDisplayMode = NotificationUtil.getDisplayMode();
let intervalId = -1;

export let hasNotice: boolean = false;

export class RecordNotification {

  /**
   * @param state: 录音机当前状态
   * @param duration: 录音时间
   */
  public updateNotification = (context: Context, state: string, duration: number) => {
    notificationManager.isNotificationEnabled().then((data: boolean) => {
      LogUtil.info(TAG + ' request isNotificationEnabled success, data: ' + JSON.stringify(data));
      if (data) {
        this.sendNotification(context, state, duration);
      } else {
        LogUtil.info(TAG + 'have no permission to send notification');
      }
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` isNotificationEnabled fail, code: ${err?.code}, message: ${err?.message}`);
    });
  }

  private sendNotification = (context: Context, state: string, duration: number) => {
    LogUtil.info(TAG + 'intervalId = ' + intervalId);
    this.cancelNotification();
    if (!NotificationUtil.isRecordWorking(state)) {
      LogUtil.info(TAG + 'ignore sendNotification due to state is not RECORDING or PAUSED.');
      return;
    }
    let isScreenOn: boolean = NotificationUtil.getScreenState();
    let displayMode = NotificationUtil.getDisplayMode();
    LogUtil.info(TAG + ' sendNotification.isScreenOn=' + isScreenOn + ',displayMode=' + displayMode +
      ',mPreScreenDisplayMode = ' + mPreScreenDisplayMode);
    if (!isScreenOn || displayMode !== display.FoldDisplayMode.FOLD_DISPLAY_MODE_SUB ||
      mPreScreenDisplayMode === display.FoldDisplayMode.FOLD_DISPLAY_MODE_UNKNOWN) {
      this.cancelNotification();
      mPreScreenDisplayMode = displayMode;
      return;
    }
    let bottomContent = state === CommonConstants.PAUSED
      ? NotificationUtil.getStringResource(context, $r('app.string.notice_record_pause'))
      : NotificationUtil.getStringResource(context, $r('app.string.notice_recording'));
    let title = NotificationUtil.getStringResource(context, $r('app.string.title'));
    this.doSendNotification(title, duration, bottomContent);
    mPreScreenDisplayMode = displayMode;
    if (state === CommonConstants.STARTED) {
      duration += timeIntervalMinus;
      intervalId = setInterval(() => {
        this.doSendNotification(title, duration, bottomContent);
        duration += timeIntervalMinus;
      }, timeIntervalMinus);
      LogUtil.info(TAG + ' intervalId=' + intervalId);
    }
  }

  private async doSendNotification(title: string, duration: number, bottomContent: string) {
    let floorTime = Math.floor(duration / timeIntervalMinus) * timeIntervalMinus;
    let time = Util.timeFormat(floorTime);
    let publishData = NotificationUtil.buildOngoingNotification(title, recordNoteId, time, bottomContent, timeSize);
    publishData.wantAgent = await NotificationUtil.getWantAgent();
    LogUtil.info(TAG + `send notification content is: ${JSON.stringify(publishData)}`);
    notificationManager.publish(publishData).then(
      () => {
        LogUtil.info(TAG + 'send success');
        hasNotice = true;
      },
      (err: BusinessError) => {
        LogUtil.error(TAG + ` send fail, code: ${err?.code}, message: ${err?.message}`);
        return new Error(JSON.stringify(err));
      }
    )
  }

  /**
   * 取消通知
   */
  public cancelNotification = () => {
    LogUtil.info(TAG + 'cancel notification');
    if (intervalId != -1) {
      clearInterval(intervalId);
      intervalId = -1;
    }
    this.cancel();
  }

  /**
   * 取消通知，无需系统权限
   */
  private cancel = () => {
    if (hasNotice) {
      // cancel回调
      let cancelCallback = (err: Base.BusinessError): void => {
        if (err) {
          LogUtil.error(`cancel failed, code is ${err.code}, message is ${err.message}`);
        } else {
          LogUtil.info(TAG + 'cancel success');
          hasNotice = false;
        }
      }
      notificationManager.cancel(recordNoteId, cancelCallback);
    }
  }
}

export default new RecordNotification();