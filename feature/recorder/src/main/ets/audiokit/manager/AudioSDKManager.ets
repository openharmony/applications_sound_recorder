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

import { LogUtil } from '@ohos/common';
import { AudioRecordInfo } from '../bean/AudioRecordInfo';

const TAG = '[AudioSDKManagerTag]';

/**
 * 音频管家SDK接口使用管理类
 * 音频管家SDK所有接口均封装在此类中，其他类不直接调用音频管家SDK接口
 */
class AudioSDKManager {
  private static instance: AudioSDKManager;
  private readonly recordStateCallbackMap: Map<string, Callback<AudioRecordInfo>>;
  private readonly recordDataCallbackMap: Map<string, Callback<ArrayBuffer>>;

  private constructor() {
    this.recordStateCallbackMap = new Map();
    this.recordDataCallbackMap = new Map();
  }

  public static getInstance(): AudioSDKManager {
    if (!AudioSDKManager.instance) {
      AudioSDKManager.instance = new AudioSDKManager();
    }
    return AudioSDKManager.instance;
  }

  /**
   * SDK初始化
   */
  public init(context: ESObject): void {
    LogUtil.info(`${TAG} audio sdk init `);
  }

  /**
   * SDK销毁
   */
  public destroy(): void {
    LogUtil.info(`${TAG} audio sdk destroy`);
  }

  /**
   * 暂停耳机录音
   */
  public pauseRecord(): void {
    LogUtil.info(`${TAG} pauseRecord`);
  }

  /**
   * 恢复耳机录音
   */
  public resumeRecord(): void {
    LogUtil.info(`${TAG} resumeRecord`);
  }

  /**
   * 结束耳机录音
   */
  public stopRecord(): void {
    LogUtil.info(`${TAG} stopRecord`);
  }

  public addRecordStateChangeCallback(tag: string, callback: Callback<AudioRecordInfo>): void {
    this.recordStateCallbackMap.set(tag, callback);
  }

  public removeRecordStateChangeCallback(tag: string): void {
    this.recordStateCallbackMap.delete(tag);
  }

  public addRecordDataCallback(tag: string, callback: Callback<ArrayBuffer>): void {
    this.recordDataCallbackMap.set(tag, callback);
  }

  public removeRecordDataCallback(tag: string): void {
    this.recordDataCallbackMap.delete(tag);
  }

  public onRecordStateChange(info: AudioRecordInfo): void {
    this.recordStateCallbackMap.forEach(callback => callback(info));
  }
}

export default AudioSDKManager.getInstance();