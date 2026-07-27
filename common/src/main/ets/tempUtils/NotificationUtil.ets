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
import display from '@ohos.display';
import notificationManager from '@ohos.notificationManager';
import power from '@ohos.power';
import { Context, Want } from '@kit.AbilityKit';
import type { WantAgent } from '@ohos.wantAgent';
import wantAgent from '@ohos.app.ability.wantAgent';
import { CommonConstants } from '../constants/CommonConstants';
import { LogUtil } from '../utils/LogUtil';

const TAG = 'SoundRecorder_NotificationUtil';

/**
 * 通知工具
 */
export class NotificationUtil {

  private static isScreenOn = power.isActive();
  private static foldDisplayMode = display.getFoldDisplayMode();

  public static setScreenState = (isScreenOn: boolean) => {
    NotificationUtil.isScreenOn = isScreenOn;
  }

  public static setDisplayMode = (foldStatus: display.FoldDisplayMode) => {
    NotificationUtil.foldDisplayMode = foldStatus;
  }

  public static getScreenState = () => {
    return NotificationUtil.isScreenOn;
  }

  public static getDisplayMode = () => {
    return NotificationUtil.foldDisplayMode;
  }

  /**
   * @param context :context of Ability
   * @param id :notification id
   * @param midContent : content of middle
   * @param bottomContent :content of bottom
   * @param fontSize  size of midContent
   * @returns notification request data
   */
  public static buildOngoingNotification(title: string, id: number, midContent: string, bottomContent: string,
    fontSize: number): notificationManager.NotificationRequest {
    let requestData: notificationManager.NotificationRequest = {
      id: id,
      isOngoing: true,
      isUnremovable: true,
      extraInfo: {
        midContent: midContent,
        bottomContent: bottomContent,
        fontSize: fontSize
      },
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT, // 普通文本类型通知
        normal: {
          title: title,
          text: bottomContent,
          additionalText: '',
        }
      }
    };
    return requestData;
  }

  public static async getWantAgent(): Promise<WantAgent> {
    let want: Want = {
      bundleName: 'com.ohos.soundrecorder',
      abilityName: 'MainAbility',
      'entities': [
        'entity.system.home'
      ]
    };
    return await wantAgent.getWantAgent({
      wants: [want],
      requestCode: 0,
      actionType: wantAgent.OperationType.START_ABILITY,
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    });
  }

  public static isRecordWorking(state: string): boolean {
    return state === CommonConstants.STARTED || state === CommonConstants.PAUSED;
  }

  public static isPlayWorking(state: string): boolean {
    return state === CommonConstants.PLAYING || state === CommonConstants.PAUSED;
  }

  public static getStringResource(context: Context, key: Resource): string {
    try {
      return context.resourceManager.getStringSync(key);
    } catch (error) {
      let code = (error as BusinessError).code;
      let message = (error as BusinessError).message;
      LogUtil.error(TAG + `getStringSync failed, error code: ${code}, message: ${message}.`);
      return '';
    }
  }
}