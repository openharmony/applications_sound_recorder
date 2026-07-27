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

import CommonEventManager from '@ohos.commonEventManager';
import Base, { AsyncCallback } from '@ohos.base';
import { LogUtil } from '@ohos/common';

const TAG = 'SoundRecorder_ScreenStateListener';
//用于保存创建成功的订阅者对象，后续使用其完成订阅及退订的动作
let subscriber: CommonEventManager.CommonEventSubscriber;

// 订阅者信息
let subscribeInfo: CommonEventManager.CommonEventSubscribeInfo = {
  events: [
    CommonEventManager.Support.COMMON_EVENT_SCREEN_ON,
    CommonEventManager.Support.COMMON_EVENT_SCREEN_OFF,
    CommonEventManager.Support.COMMON_EVENT_SCREEN_LOCKED,
    CommonEventManager.Support.COMMON_EVENT_SCREEN_UNLOCKED
  ]
};

export class ScreenStateListener {

  private static createSubscriber(subscribeCallBack: AsyncCallback<CommonEventManager.CommonEventData>) {
    LogUtil.info(TAG + 'create subscriber');
    //创建订阅者回调
    let createCB = (err: Base.BusinessError, commonEventSubscriber: CommonEventManager.CommonEventSubscriber) => {
      if (!err) {
        LogUtil.info(TAG + 'createSubscriber success');
        subscriber = commonEventSubscriber;
        //订阅公共事件
        try {
          // 订阅事件
          CommonEventManager.subscribe(subscriber, subscribeCallBack);
        } catch (error) {
          let err:Base.BusinessError = error as Base.BusinessError;
          LogUtil.error(TAG + `subscribe failed, code is ${err.code}, message is ${err.message}`);
        }
      } else {
        LogUtil.error(TAG + `createSubscriber failed, code is ${err.code}, message is ${err.message}`);
      }
    }
    //创建订阅者
    try {
      CommonEventManager.createSubscriber(subscribeInfo, createCB);
    } catch (error) {
      let err: Base.BusinessError = error as Base.BusinessError;
      LogUtil.error(TAG + `createSubscriber failed, code is ${err.code}, message is ${err.message}`);
    }
  }

  public static registerListener(subscribeCallBack: AsyncCallback<CommonEventManager.CommonEventData>) {
    LogUtil.info(TAG + 'registerScreenStateListener');
    if (!subscriber) {
      LogUtil.error(TAG + 'subscriber is empty, need to create');
      ScreenStateListener.createSubscriber(subscribeCallBack);
    } else {
      LogUtil.error(TAG + 'registerScreenListener');
      //订阅公共事件
      try {
        // 不管之前没有人注册，先取消订阅公共事件回调
        LogUtil.info(TAG + 'unsubscribe');
        CommonEventManager.unsubscribe(subscriber, ScreenStateListener.getCallBack(subscribeCallBack));
      } catch (error) {
        let err: Base.BusinessError = error as Base.BusinessError;
        LogUtil.error(TAG + ` subscribe failed, code is ${err.code}, message is ${err.message}`);
      }
    }
  }

  private static getCallBack(subscribeCallBack: AsyncCallback<CommonEventManager.CommonEventData>) {
    return (err: Base.BusinessError) => {
      if (err) {
        LogUtil.error(TAG + `unsubscribe failed, code is ${err.code}, message is ${err.message}`);
      } else {
        LogUtil.error(TAG + 'unsubscribe success');
        CommonEventManager.subscribe(subscriber, subscribeCallBack);
      }
    }
  }

  public static unRegisterListener() {
    LogUtil.info(TAG + 'unRegisterScreenListener');
    if (subscriber) {
      CommonEventManager.unsubscribe(subscriber);
    }
  }
}

export default new ScreenStateListener();