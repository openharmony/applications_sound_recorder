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
import notificationManager from '@ohos.notificationManager';
import image from '@ohos.multimedia.image';
import { LogUtil } from '../utils/LogUtil';
import { Context, Want } from '@kit.AbilityKit';
import WantAgent from '@ohos.app.ability.wantAgent';
import { Util } from './Util';
import { CommonConstants } from '../constants/CommonConstants';
import ResourceManagerUtil from '../utils/ResourceManagerUtil';
import { NotificationConstants } from '../constants/NotificationConstants';
import { systemParameter } from '@kit.BasicServicesKit';

const TAG = 'SoundRecorder_NotificationManagerUtil ';

/**
 * 通知工具
 */
export class NotificationManagerUtil {
  private static instance?: NotificationManagerUtil;
  private static lock = false;
  public requestData?: notificationManager.NotificationRequest;
  public darkMode: number = CommonConstants.darkModeLight;
  private systemLiveViewSubscriber?: notificationManager.SystemLiveViewSubscriber;

  /* instrument ignore next */
  public static getInstance(): NotificationManagerUtil {
    if (!NotificationManagerUtil.instance) {
      while (NotificationManagerUtil.lock) {
      }
      NotificationManagerUtil.lock = true;
      if (!NotificationManagerUtil.instance) {
        NotificationManagerUtil.instance = new NotificationManagerUtil();
      }
      NotificationManagerUtil.lock = false;
    }
    return NotificationManagerUtil.instance;
  }

  public updateNotification = async (context: Context, mode: number, state: string, duration: number,
    onResponseCallback: (id: number, option: notificationManager.ButtonOptions) => void) => {
    // instrument ignore if
    if ([CommonConstants.PREPARED, CommonConstants.STARTED, CommonConstants.PAUSED].indexOf(state) === -1) {
      return;
    }
    state = state === CommonConstants.PREPARED ? CommonConstants.STARTED : state;
    // instrument ignore else
    if (!NotificationManagerUtil.getInstance().requestData) {
      LogUtil.info(TAG + 'updateNotification -1 ' + JSON.stringify(NotificationManagerUtil.getInstance().requestData));
      await NotificationManagerUtil.getInstance().initRequestData(context, state);
    }
    await context.resourceManager.release();
    // instrument ignore if
    if (mode === NotificationConstants.UpdateNotificationMode.UPDATE_BY_DARK_MODE) {
      await NotificationManagerUtil.getInstance().updateNotificationByMode(state, context);
      LogUtil.info(TAG + 'updateNotification 0 ' + JSON.stringify(NotificationManagerUtil.getInstance().requestData));
    } else if (mode === NotificationConstants.UpdateNotificationMode.UPDATE_BY_STATE) {
      LogUtil.info(TAG + 'updateNotification 1 ' + JSON.stringify(NotificationManagerUtil.getInstance().requestData));
      await NotificationManagerUtil.getInstance().updateNotificationByState(state, context);
    }
    NotificationManagerUtil.getInstance().updateBaseInfo(duration);
    NotificationManagerUtil.getInstance()
      .sendRequestData(NotificationManagerUtil.getInstance().requestData as notificationManager.NotificationRequest,
        onResponseCallback);
  }

  // instrument ignore next
  public async updateNotificationByMode(state: string, context: Context) {
    let operateIcon = await NotificationManagerUtil.getInstance().getImageInfoByState(state, context);
    let operateIconResource = NotificationManagerUtil.getInstance().getImageResourceByState(state);
    let resetIcon = await NotificationManagerUtil.getInstance().getResetIcon(context);
    let request: notificationManager.NotificationRequest =
      NotificationManagerUtil.getInstance().requestData as notificationManager.NotificationRequest;
    if (request?.content.systemLiveView) {
      if (request.content.systemLiveView.button?.icons) {
        request.content.systemLiveView.button.icons[0] = operateIcon;
        request.content.systemLiveView.button.icons[1] = resetIcon;
      }
      if (request.content.systemLiveView.button?.iconsResource) {
        request.content.systemLiveView.button.iconsResource[0] = operateIconResource;
        request.content.systemLiveView.button.iconsResource[1] = $r('app.media.ic_reset');
      }
    }
    NotificationManagerUtil.getInstance().requestData = request;
  }

  public async updateNotificationByState(state: string, context: Context): Promise<void> {
    let systemLiveViewText: string = '';
    if (state === CommonConstants.STARTED) {
      systemLiveViewText = ResourceManagerUtil.resourceToString($r('app.string.notice_recording'), context);
    } else {
      systemLiveViewText = ResourceManagerUtil.resourceToString($r('app.string.notice_record_pause'), context);
    }
    let operateIcon = await NotificationManagerUtil.getInstance().getImageInfoByState(state, context);
    let operateIconResource = NotificationManagerUtil.getInstance().getImageResourceByState(state);
    let request: notificationManager.NotificationRequest =
      NotificationManagerUtil.getInstance().requestData as notificationManager.NotificationRequest;
    // instrument ignore else
    if (request?.content.systemLiveView) {
      request.content.systemLiveView.text = systemLiveViewText;
      // instrument ignore else
      if (request.content.systemLiveView.button?.names) {
        request.content.systemLiveView.button.names[0] = state;
      }
      // instrument ignore else
      if (request.content.systemLiveView.button?.icons) {
        request.content.systemLiveView.button.icons[0] = operateIcon;
      }
      // instrument ignore else
      if (request.content.systemLiveView.button?.iconsResource) {
        request.content.systemLiveView.button.iconsResource[0] = operateIconResource;
      }
      // instrument ignore else
      if (request.content.systemLiveView.time) {
        request.content.systemLiveView.time.isPaused = state !== CommonConstants.STARTED;
      }
    }
    request.extraInfo = {
      hw_button_accessibility_text: [this.getOperationNameByState(context, state),
        context.resourceManager.getStringSync($r('app.string.end'))]
    };
    NotificationManagerUtil.getInstance().requestData = request;
  }

  private getOperationNameByState(context:Context, state: string): string {
    let operationName: Resource = $r('app.string.pause');
    // instrument ignore else
    if (state === 'paused') {
      operationName = $r('app.string.resume');
    }
    return context.resourceManager.getStringSync(operationName);
  }

  public getImageResourceByState(state: string): Resource {
    let operateSvgName: Resource = $r('app.media.ic_pause');
    // instrument ignore else
    if (state === 'paused') {
      operateSvgName = $r('app.media.ic_play');
    }
    return operateSvgName;
  }

  public updateBaseInfo(duration: number) {
    let request: notificationManager.NotificationRequest =
      NotificationManagerUtil.getInstance().requestData as notificationManager.NotificationRequest;
    request.deliveryTime = new Date().getTime();
    // instrument ignore else
    if (request?.content.systemLiveView) {
      let timeUse: string = NotificationManagerUtil.getInstance().getRequestTime(duration);
      request.content.systemLiveView.title = timeUse;
      // instrument ignore else
      if (request.content.systemLiveView.capsule?.title) {
        request.content.systemLiveView.capsule.title = timeUse;
      }
      // instrument ignore else
      if (request.content.systemLiveView.time?.initialTime || request.content.systemLiveView.time?.initialTime === 0) {
        request.content.systemLiveView.time.initialTime = duration;
      }
    }
    NotificationManagerUtil.getInstance().requestData = request;
  }

  public getRequestTime(duration: number): string {
    let timerUse: string = Util.timeFormat(duration, false);
    return timerUse;
  }

  public async initRequestData(context: Context, state: string): Promise<void> {
    let wantAgentObj = await NotificationManagerUtil.getInstance().getWantAgent();
    let capsuleIcon: PixelMap = await NotificationManagerUtil.getInstance().getCapsuleIcon(context);
    let resetIcon: PixelMap = await NotificationManagerUtil.getInstance().getResetIcon(context);
    let requestData: notificationManager.NotificationRequest = {
      notificationSlotType: notificationManager.SlotType.LIVE_VIEW, // 实况窗类型
      id: NotificationConstants.NOTIFICATION_ID,
      isRemoveAllowed: false,
      isOngoing: true,
      wantAgent: wantAgentObj,
      deliveryTime: new Date().getTime(),
      content: {
        notificationContentType: notificationManager.ContentType.NOTIFICATION_CONTENT_SYSTEM_LIVE_VIEW,
        systemLiveView: {
          title: '--',
          text: '--',
          typeCode: 14, // 调用方的业务类型/实况窗类型，区分系统应用定制化
          // 按钮：支持最多3个右侧按钮
          button: {
            names: [state, CommonConstants.STOPPED],
            icons: [resetIcon, resetIcon],
            iconsResource: [$r('app.media.ic_reset'), $r('app.media.ic_reset')]
          },
          capsule: {
            title: '--',
            icon: capsuleIcon,
            backgroundColor: '#E84026'
          },
          // 时间
          time: {
            initialTime: 0,
            isCountDown: false,
            isPaused: false,
            isInTitle: true
          }
        }
      },
      extraInfo: {
        hw_button_accessibility_text: [context.resourceManager.getStringSync($r('app.string.pause')),
          context.resourceManager.getStringSync($r('app.string.end'))]
      }
    };
    NotificationManagerUtil.getInstance().requestData = requestData;
  }

  public async getImageInfoByState(state: string, context: Context): Promise<PixelMap> {
    let imageSuffix: string = '';
    // instrument ignore if
    if (NotificationManagerUtil.getInstance().darkMode === CommonConstants.darkModeGray) {
      imageSuffix = '_dark';
    }
    let operateSvgName: string = 'ic_live_' + state + imageSuffix + '.svg';
    let operateIcon: PixelMap =
      await NotificationManagerUtil.getInstance()
        .getPixMap(context, operateSvgName, NotificationConstants.PixMapSizeNumber.MEDIUM_ICON_SIZE);
    return operateIcon;
  }

  /* instrument ignore next */
  public async getCapsuleIcon(context: Context): Promise<PixelMap> {
    let capsuleIcon = await NotificationManagerUtil.getInstance()
      .getPixMap(context, 'ic_live_voice.svg', NotificationConstants.PixMapSizeType.ICON_SIZE_CAPSULE);
    try {
      const property = systemParameter.getSync('persist.systemui.live2', 'false');
      LogUtil.info(`${TAG} getCapsuleIcon is capsule 2.0 : ` + property + ', ' + typeof property)
      if (property === 'true') {
        capsuleIcon = await NotificationManagerUtil.getInstance()
          .getPixMap(context, 'ic_microphone.png', NotificationConstants.PixMapSizeType.ICON_SIZE_CAPSULE);
      }
    } catch (error) {
      LogUtil.error(TAG + `getCapsuleIcon error: ${error}`);
    }
    return capsuleIcon;
  }

  public async getResetIcon(context: Context): Promise<PixelMap> {
    let imageSuffix: string =
      NotificationManagerUtil.getInstance().darkMode === CommonConstants.darkModeGray ? '_dark' : '';
    let imageName: string = 'ic_live_reset' + imageSuffix + '.svg';
    let capsuleIcon: PixelMap = await NotificationManagerUtil.getInstance()
      .getPixMap(context, imageName, NotificationConstants.PixMapSizeType.ICON_SIZE);
    return capsuleIcon;
  }

  /* instrument ignore next */
  private async sendRequestData(requestData: notificationManager.NotificationRequest,
    callback: (id: number, option: notificationManager.ButtonOptions) => void): Promise<void> {
    // 按钮回调：进程注册一次即可，进程发送的系统实况窗通知复用，ButtonOptions入参区分具体点击哪个按钮
    // instrument ignore else
    if (!NotificationManagerUtil.getInstance().systemLiveViewSubscriber) {
      NotificationManagerUtil.getInstance().systemLiveViewSubscriber = {
        onResponse: callback
      };
      // 订阅系统实况窗(按钮回调)
     await notificationManager.subscribeSystemLiveView(NotificationManagerUtil.getInstance().systemLiveViewSubscriber);
    }
    notificationManager.publish(requestData).then(() => {
      LogUtil.info(TAG + 'publish success');
    }, (err: BusinessError) => {
      LogUtil.error(TAG + ` publish fail, code: ${err?.code}, message: ${err?.message}`);
      return new Error(JSON.stringify(err));
    }
    );
  }

  public async getPixMap(context: Context, imageName: string, size?: number): Promise<PixelMap> {
    let resourceMgr = context?.resourceManager;
    let decodeOption: image.DecodingOptions;
    // use number size instead of vp2px
    let desiredWidth: number = 0;
    if (size === NotificationConstants.PixMapSizeType.ICON_SIZE_CAPSULE) {
      desiredWidth = NotificationConstants.PixMapSizeNumber.CAPSULE_ICON_SIZE;
    } else {
      desiredWidth = NotificationConstants.PixMapSizeNumber.MEDIUM_ICON_SIZE;
    }
    decodeOption = {
      desiredSize: {
        height: desiredWidth,
        width: desiredWidth
      }
    };
    let data = await resourceMgr.getRawFileContent(imageName);
    let buffer = data.buffer;
    let imageSource = image.createImageSource(buffer);
    let pixelMap: image.PixelMap = await imageSource.createPixelMap(decodeOption);
    imageSource.release();
    return pixelMap;
  }

  private async getWantAgent() {
    let want: Want = {
      bundleName: 'com.ohos.soundrecorder',
      abilityName: 'MainAbility',
      'entities': [
        'entity.system.home'
      ]
    };
    return await WantAgent.getWantAgent({
      wants: [want],
      requestCode: 0,
      actionType: WantAgent.OperationType.START_ABILITY,
      wantAgentFlags: [WantAgent.WantAgentFlags.UPDATE_PRESENT_FLAG]
    });
  }

  public cancelNotification(): void {
    let cancelCallback = (err: BusinessError): void => {
      NotificationManagerUtil.getInstance().requestData = undefined;
      // instrument ignore if
      if (err) {
        LogUtil.error(TAG + ` cancel failed, code is ${err.code}, message is ${err.message}`);
      } else {
        LogUtil.info(TAG + ' cancel success');
      }
    }
    // instrument ignore else
    if (NotificationManagerUtil.getInstance().requestData) {
      notificationManager.cancel(NotificationConstants.NOTIFICATION_ID, cancelCallback);
    }
  }
}