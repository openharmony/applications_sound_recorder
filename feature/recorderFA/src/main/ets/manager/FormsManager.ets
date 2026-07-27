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
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { rpc } from '@kit.IPCKit';
import { BaseViewModel, MediaController, PlayManager, RecordManager } from '@ohos/recorder';
import { FormUpdateUtil } from '../utils/FormUpdateUtil';
import { formBindingData } from '@kit.FormKit';
import { BusinessError } from '@kit.BasicServicesKit';
import notificationManager from '@ohos.notificationManager';
import {
  CommonConstants,
  DeviceUtil,
  DFXEnumConstants,
  GlobalContext,
  HiSysEventName,
  HiSysEventUtil,
  MarkData,
  NotificationConstants,
  NotificationManagerUtil,
  Util
} from '@ohos/common';
import { abilityAccessCtrl, Context } from '@kit.AbilityKit';
import { call } from '@kit.TelephonyKit';
import { statfs } from '@kit.CoreFileKit';
import { MarkDataGroup } from '@ohos/common/src/main/ets/model/RecordData';
import { FormDbManager } from '../storage/FormDbManager';
import AudioSDKManager from '@ohos/recorder/src/main/ets/audiokit/manager/AudioSDKManager';

/**
 * [录音机所有卡片管理类]
 *
 * @Description 管理卡片和卡片数据
 */
const TAG: string = 'SoundRecorder_FaManager'
/**
 * 默认卡片toast距离底部显示高度
 */
export const DEFAULT_TOAST_BOTTOM_HIGH = 80;

// 卡片管理类实例
export class FormsManager {
  private static instance: FormsManager | null = null;
  private recordState: string = 'idle';
  private context: Context;
  private updateCurrentTimer: number = 0;
  private lastMarkTime: number = 0;
  private currentTime: number = 0;
  private markList: MarkDataGroup = new MarkDataGroup();
  private subscription: (tag: string, markList: MarkDataGroup) => void;
  private markOpacity: number = 1;
  private playOrPauseOpacity: number = 1;
  private updateFileNameTimer: number = 0;

  /**
   * 获取唯一实例
   * @returns FAsManager
   */
  public static getInstance(): FormsManager {
    if (!FormsManager.instance) {
      FormsManager.instance = new FormsManager();
    }
    return FormsManager.instance;
  }

  private constructor() {
    LogUtil.info(TAG + ` constructor`);
    this.context = GlobalContext.getUIAbilityContext() ?? GlobalContext.getServiceAbilityContext();
    this.subscription = (tag, newMarkList) => {
      // instrument ignore if
      if (tag === TAG) {
        return;
      }
      this.markList.content.updateAllData(newMarkList.content.getAll());
    };
    this.addListeners();
  }

  public addListeners(): void {
    RecordManager.getInstance().addRecorderStateListeners(TAG, this.recorderStateCallback);
    this.context?.eventHub.on('updateFaFileName', this.updateFaFileName);
    this.context?.eventHub.on('updateFaFileNameWhenKill', this.updateFaFileNameWhenKill);
    this.context?.eventHub.on('refreshRecordLiveView', this.refreshRecordLiveViewNotification);
    BaseViewModel.getInstance().subscribeMarkList(this.subscription);
  }

  /**
   * 响应2x2卡片标记按钮
   *
   * @param data
   */
  public faCardMark(data: rpc.MessageSequence): null {
    this.tryRegisterFormIdFromCall(data, 'Record2x2Form');
    // instrument ignore if
    if (this.lastMarkTime !== 0 && this.currentTime - this.lastMarkTime < CommonConstants.TIME_1000) {
      LogUtil.warn(TAG + '：The interval for clicking the mark button is too short.');
      return null;
    }
    this.insertMark();
    this.lastMarkTime = this.currentTime;
    BaseViewModel.getInstance().broadcastWhenUpdateMarkList();
    return null;
  }

  /**
   * 响应2x2卡片暂停、播放按钮
   *
   * @param data
   */
  /* instrument ignore next */
  public faCardResume(data: rpc.MessageSequence): null {
    let message: Record<string, string> = {}
    try {
      message = JSON.parse(data.readString());
    } catch (e) {
      LogUtil.error(TAG + ` faCardResumeCall parse error, code: ${e.code}, message: ${e.message}`);
    }
    this.registerFormIdFromMessage(message, 'Record2x2Form');
    if (message && message.nextState) {
      if (message.nextState === 'toPause') {
        RecordManager.getInstance().pause();
      } else if (message.nextState === 'toResume') {
        RecordManager.getInstance().resume();
      }
    }
    return null;
  }

  /**
   * 响应2x2、1x2卡片播放、结束按钮
   *
   * @param data
   */
  public faCardCall(data: rpc.MessageSequence): null {
    LogUtil.info(TAG + ' fACardCall ');
    this.tryRegisterFormIdFromCall(data);
    let context = GlobalContext.getUIAbilityContext() ?? GlobalContext.getServiceAbilityContext();
    if (!context) {
      LogUtil.error(TAG + ' faCardCall context is null');
      return null;
    }
    // instrument ignore else
    if (this.recordState === 'started' || this.recordState === 'paused') {
      RecordManager.getInstance().release();
    } else {
      this.handleRecording(context);
      HiSysEventUtil.eventDotting(HiSysEventName.START_RECORD,
        { VALUE: DFXEnumConstants.StartRecordResource.DESKTOP_CARD });
    }
    return null;
  }

  private tryRegisterFormIdFromCall(data: rpc.MessageSequence, defaultFormName: string = 'Record2x1Form'): void {
    try {
      const message = JSON.parse(data.readString()) as Record<string, string>;
      this.registerFormIdFromMessage(message, defaultFormName);
    } catch (e) {
      LogUtil.warn(TAG + ` tryRegisterFormIdFromCall skip, message: ${e?.message}`);
    }
  }

  private registerFormIdFromMessage(message: Record<string, string>, defaultFormName: string): void {
    const formId = Number(message?.formId);
    if (!formId) {
      return;
    }
    const formName = message?.formName ?? defaultFormName;
    const cardType = formName === 'Record2x2Form' ? 2 : 1;
    FormDbManager.getInstance().addCardInfoInner(formId, cardType, formName);
  }

  private async handleRecording(context: Context): Promise<void> {
    if (!context) {
      LogUtil.error(TAG + ' handleRecording context is null');
      return;
    }
    context.eventHub.emit('exitPageToRecording');
    PlayManager.getInstance().reset();
    // instrument ignore if
    if (!await this.calculateAvailableSpace()) {
      return;
    }
    // instrument ignore if
    if (!await this.checkPermission() || !await this.checkCallConflict()) {
      return;
    }
    this.markList = new MarkDataGroup();
    await RecordManager.getInstance().initAvRecorder();
    await BaseViewModel.getInstance().startRecording(TAG, context, this.recorderStateCallback, this.onErrorCallback);
    await BaseViewModel.getInstance().syncNormalRecordListFromDb('faInitRecordList');
  }

  private recorderStateCallback = async (state: string) => {
    LogUtil.info(TAG + ` avRecorder state is: ${state}`);
    this.recordState = state;
    let param: Record<string, string | boolean | number>;

    // 统一设置 param
    param = {
      'isRecording': state === 'started' || state === 'paused' || state === 'stopped',
      'recordState': state,
    };

    if (state === 'started') {
      clearInterval(this.updateCurrentTimer);
      this.updateCurrentTimer = this.updateFaTime();
    }
    if (state === 'paused') {
      clearInterval(this.updateCurrentTimer);
    }
    if (state === 'released') {
      clearInterval(this.updateCurrentTimer);
      this.lastMarkTime = 0;
      this.markList = new MarkDataGroup();
    }
    let data: formBindingData.FormBindingData = formBindingData.createFormBindingData(param);
    FormUpdateUtil.getInstance().updateAllForm(data);
    await this.updateRecordLiveViewNotification(state);

    LogUtil.info(TAG + ' play state changed, state = ' + state);
  }

  private refreshRecordLiveViewNotification = async (): Promise<void> => {
    if (this.recordState !== CommonConstants.STARTED && this.recordState !== CommonConstants.PAUSED) {
      return;
    }
    await this.updateRecordLiveViewNotification(this.recordState);
  }

  private async updateRecordLiveViewNotification(state: string): Promise<void> {
    if ([CommonConstants.PREPARED, CommonConstants.STARTED, CommonConstants.PAUSED].indexOf(state) === -1) {
      return;
    }
    const context = this.context ?? GlobalContext.getUIAbilityContext() ?? GlobalContext.getServiceAbilityContext();
    if (!context) {
      LogUtil.error(TAG + ' updateRecordLiveViewNotification context is null');
      return;
    }
    const duration = RecordManager.getInstance().getRecordTime();
    LogUtil.info(TAG + ` updateRecordLiveViewNotification state=${state}, duration=${duration}`);
    await NotificationManagerUtil.getInstance().updateNotification(
      context,
      NotificationConstants.UpdateNotificationMode.UPDATE_BY_STATE,
      state,
      duration,
      this.onLiveViewButtonResponse
    );
  }

  private onLiveViewButtonResponse = (id: number, option: notificationManager.ButtonOptions) => {
    LogUtil.info(TAG + ` onLiveViewButtonResponse id=${id}, buttonName=${option.buttonName}`);
    const recordManager = RecordManager.getInstance();
    const buttonName: string = option.buttonName;
    if (buttonName === CommonConstants.STOPPED) {
      recordManager.release();
      return;
    }
    if (buttonName === CommonConstants.STARTED) {
      recordManager.pause();
      return;
    }
    if (buttonName === CommonConstants.PAUSED) {
      if (recordManager.isInCall() && !DeviceUtil.isPC()) {
        Util.showToast($r('app.string.has_call_hint'), false, true);
        return;
      }
      recordManager.resume();
    }
  }

  private updateFaFileName = (fileName: string) => {
    let param: Record<string, string>;
    param = {
      'fileName' :fileName
    };
    const data = formBindingData.createFormBindingData(param);
    FormUpdateUtil.getInstance().updateAllForm(data);

    if (this.updateFileNameTimer) {
      clearInterval(this.updateFileNameTimer);
    }

    this.updateFileNameTimer = setInterval(async () => {
      LogUtil.info(TAG + ` updateFileNameTimer setInterval 3s after`);
      param['fileName'] = '';
      const data = formBindingData.createFormBindingData(param);
      await FormUpdateUtil.getInstance().updateFileNameAllForm(data);
      clearInterval(this.updateFileNameTimer);
      if (this.recordState === 'idle' || this.recordState === 'released' ||
        this.recordState === 'stopped' || this.recordState === 'error') {
        this.context.eventHub.emit('stopContinuousTask');
      }
    }, 3000);
  };

  private updateFaFileNameWhenKill = (fileName: string) => {
    let param: Record<string, string | boolean>;
    param = {
      'fileName' :fileName,
      'isRecording': false,
    };
    const data = formBindingData.createFormBindingData(param);
    FormUpdateUtil.getInstance().updateAllForm(data);
  }

  // instrument ignore next
  private onErrorCallback = async (error: BusinessError) => {
    LogUtil.info(TAG + ' avRecorder onErrorCallback, error msg: ' + error);
    let state = await RecordManager.getInstance().getAvRecorderState();
    let data: formBindingData.FormBindingData;
    let param: Record<string, string | number>;
    let context = GlobalContext.getUIAbilityContext();
    switch (error.code) {
      case 5400107:
        if (state !== 'started') {
          let message = context?.resourceManager.getStringSync($r('app.string.has_screen_hint'));
          Util.showToast(message, false, true);
        }
        try {
          LogUtil.info(TAG + ' audio interrupted.');
          this.markOpacity = 0.4;
          this.playOrPauseOpacity = 0.4;
          param = {
            'markOpacity': this.markOpacity,
            'playOrPauseOpacity': this.playOrPauseOpacity
          };
          data = formBindingData.createFormBindingData(param);
          FormUpdateUtil.getInstance().updateAllForm(data);
        } catch (e) {
          LogUtil.error(TAG + ' remove record file error, reason: ' + e);
        }
        this.clearAllStatusByError();
        break;
      default:
        break;
    }
    RecordManager.getInstance().reset();
  };

  private clearAllStatusByError = () => {
    NotificationManagerUtil.getInstance().cancelNotification();
  }

  private async checkPermission(): Promise<boolean> {
    const microPhoneGrantStatus = await MediaController.checkAccessToken('ohos.permission.MICROPHONE');
    // instrument ignore if
    if (microPhoneGrantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) {
      this.showMicroPermissionToast();
      return false;
    }
    return true;
  }

  /**
   * 显示麦克风禁用Toast
   */
  /* instrument ignore next */
  private showMicroPermissionToast() {
    let context = GlobalContext.getUIAbilityContext();
    if (!context) {
      LogUtil.info(TAG + ' context is null, cannot toast');
      return;
    }
    try {
      LogUtil.info(TAG + ` showMicroPermissionToast`);
      let message = context?.resourceManager.getStringSync($r('app.string.label_permission_microphone_text'));
      Util.showToast(message, false, true);
    } catch (err) {
      LogUtil.error(TAG + ` cardShowNetworkAlertToast has exception, errCode: ${err?.code}, errMessage: ${err?.message}`);
    }
  }

  private async checkCallConflict(): Promise<boolean> {
    let context = GlobalContext.getUIAbilityContext();
    let callState: call.CallState = await call.getCallState();
    // instrument ignore if
    if ((callState === call.CallState.CALL_STATE_RINGING || callState === call.CallState.CALL_STATE_OFFHOOK)) {
      LogUtil.info(TAG + ` checkCallConflict`);
      let message = context?.resourceManager.getStringSync($r('app.string.has_call_hint'));
      Util.showToast(message, false, true);
      return false;
    }
    return true;
  }

  private async calculateAvailableSpace(): Promise<boolean> {
    LogUtil.info(TAG + ` into calculateAvailableSpace`);
    let context = GlobalContext.getUIAbilityContext();
    const filesDir: string = context.filesDir + '/'
    const freeSize = await statfs.getFreeSize(filesDir);
    const leftSpace: number = freeSize / 1024 / 1024;
    const leftMinute: number = leftSpace / CommonConstants.SIZE_PER_MINUTE;
    // instrument ignore if
    if (leftMinute <= 30) {
      LogUtil.info(TAG + ` calculateAvailableSpace`);
      let message = context?.resourceManager.getStringSync($r('app.string.cannot_recording'));
      Util.showToast(message, false, true);
      return false;
    }
    return true;
  }

  private updateFaTime(): number {
    let param: Record<string, number> = {};
    let data: formBindingData.FormBindingData;
    return setInterval(() => {
      let recordedTime = RecordManager.getInstance().getRecordTime();
      this.currentTime = recordedTime;
      this.markOpacity = this.checkCanInsertMark() ? 1 : 0.4;
      if (recordedTime !== 0) {
        param = {
          'currentTimePlay': recordedTime,
          'markOpacity':this.markOpacity
        }
        data = formBindingData.createFormBindingData(param);
        FormUpdateUtil.getInstance().updateAllForm(data);
      }
    }, 160);
  }

  /* instrument ignore next */
  private insertMark() {
    let context = GlobalContext.getUIAbilityContext();
    let filePath = BaseViewModel.getInstance().getRecordingData().getFilePath();
    let markData = new MarkData(context.resourceManager
      .getStringSync($r('app.string.mark')), this.currentTime, this.getInsertMarkCount(), true, '0', 1);
    markData._data = filePath;
    markData.isSelect = true;
    LogUtil.info(TAG + ' fa insert mark when recording.');
    let insertMarkIndex: number = 0;
    insertMarkIndex = this.markList.content.getAll().length;
    this.markList.content.insertItem(markData, insertMarkIndex);
    FormDbManager.getInstance().insertMarkToDb(markData).then((value) =>{
      LogUtil.info(TAG + ' fa inserting the tag succeeded. The ID is: ' + value);
      HiSysEventUtil.eventDotting(
        HiSysEventName.ADD_QUICK_TAG,
        { VALUE: CommonConstants.SUCCESS, FROM: DFXEnumConstants.AddTagSource.DESKTOP_CARD });
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` fa failed to insert the tag. code: ${err?.code}, message: ${err?.message}`);
      HiSysEventUtil.eventDotting(
        HiSysEventName.ADD_QUICK_TAG,
        { VALUE: CommonConstants.FAILURE, FROM: DFXEnumConstants.AddTagSource.DESKTOP_CARD });
    });
    BaseViewModel.getInstance().setMarkList(TAG, this.markList);
  }

  // instrument ignore next
  private getInsertMarkCount() {
    let maxCount = 0;
    this.markList.content.getAll().forEach(item => maxCount = item.count > maxCount ? item.count : maxCount);
    return maxCount + 1;
  }

  private checkCanInsertMark(): boolean {
    if (this.markList.content.getAll().length === 0) {
      return true;
    }
    // instrument ignore if
    if (this.currentTime < this.markList.content.getData(0).markDuration - 1000) {
      return true;
    }
    if (this.markList.content.getData(this.markList.content.getAll().length - 1).markDuration + 1000 <
    this.currentTime) {
      return true;
    }

    for (let i = 0, j = i + 1; j < this.markList.content.getAll().length; i++, j++) {
      // instrument ignore if
      if (this.markList.content.getData(i).markDuration + 1000 < this.currentTime &&
        this.currentTime < this.markList.content.getData(j).markDuration - 1000) {
        return true;
      }
    }
    return false;
  }
}