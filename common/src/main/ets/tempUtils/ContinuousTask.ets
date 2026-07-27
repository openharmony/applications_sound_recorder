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

import { BusinessError } from '@ohos.base';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import wantAgent from '@ohos.app.ability.wantAgent';

import { LogUtil } from './LogUtil';
import DatabaseManager from './DatabaseManager';

const TAG = 'SoundRecorder_ContinuousTask';
/**
 * 申请长时任务
 */
export class ContinuousTask {

  static startPlayTask(context: Context) {
    LogUtil.info(TAG + ' start playback task.');
    ContinuousTask.startContinuousTask(context, backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK);
  }

  static startRecordTask(context: Context) {
    ContinuousTask.startContinuousTask(context, backgroundTaskManager.BackgroundMode.AUDIO_RECORDING);
  }

  /* instrument ignore next */
  static async startContinuousTask(context: Context, mode: backgroundTaskManager.BackgroundMode) {
    LogUtil.info(TAG + ` startContinuousTask. mode = ${mode}`);
    let wantAgentInfo: wantAgent.WantAgentInfo = {
      // 点击通知后，将要执行的动作列表
      // 添加需要被拉起应用的bundleName和abilityName
      wants: [
        {
          bundleName: 'com.ohos.soundrecorder',
          abilityName: 'MainAbility'
        }
      ],
      // 指定点击通知栏消息后的动作是拉起ability
      actionType: wantAgent.OperationType.START_ABILITY,
      // 使用者自定义的一个私有值
      requestCode: 0,
      // 点击通知后，动作执行属性
      wantAgentFlags: [wantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG],
    };

    // 通过wantAgent模块下getWantAgent方法获取WantAgent对象
    let agent = await wantAgent.getWantAgent(wantAgentInfo);
    if (agent) {
      // 后台长时任务只允许同时存在一个, 先结束掉之前正在执行的长时任务，然后重新启动
      try {
        await backgroundTaskManager.stopBackgroundRunning(context);
      } catch (err) {
        LogUtil.error(TAG + ` no background task, no need to stop, code: ${err?.code}, message: ${err?.message}`);
      }
      backgroundTaskManager.startBackgroundRunning(context, mode, agent).then(() => {
        LogUtil.info(TAG + ' Succeeded in operation startBackgroundRunning.');
      }).catch((err: BusinessError) => {
        LogUtil.error(TAG + ` Failed to operation startBackgroundRunning. Code is ${err.code}, ${err.message}`);
      });
    }
  }

  /* instrument ignore next */
  static stopContinuousTask(context: Context) {
    LogUtil.info(TAG + ' stopBackgroundRunning');
    DatabaseManager.queryHasFormData().then((hasForm: boolean) => {
      LogUtil.info(TAG + ` stopContinuousTask hasForm: ${JSON.stringify(hasForm)}`);
      if (hasForm) {
        context.eventHub.on('stopContinuousTask', () => {
          ContinuousTask.stopTask(context);
        });
      } else {
        ContinuousTask.stopTask(context);
      }
    });
  }

  static stopTask(context: Context) {
    backgroundTaskManager.stopBackgroundRunning(context).then(() => {
      LogUtil.info(TAG + ' Succeeded in operation stopBackgroundRunning.');
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` Failed to operation stopBackgroundRunning. Code is ${err.code}, message is ${err.message}`);
    });
  }
}