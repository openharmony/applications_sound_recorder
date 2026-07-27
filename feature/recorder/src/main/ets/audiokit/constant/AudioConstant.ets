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

export enum ServiceRequestCode {
  /**
   * 请求录音
   */
  REQUEST_RECORDING = 100,
}

export enum ServiceResultCode {
  /**
   * 请求成功
   */
  SUCCESS = 100,
  /**
   * 请求失败-rpc异常
   */
  FAIL_RPC_ERROR = -101,
  /**
   * 请求失败-无效token
   */
  FAIL_INVALID_TOKEN = -102,
  /**
   * 请求失败-无效请求码
   */
  FAIL_INVALID_REQUEST_CODE = -103,
}

/**
 * 录音类型
 */
export enum RecordType {
  /**
   * 未知
   */
  UNKNOWN = -1,
  /**
   * 通话录音
   */
  CALL = 0,
  /**
   * 媒体录音
   */
  MEDIA = 1,
  /**
   * 环境录音
   */
  AMBIENT = 2,
}

/**
 * 耳机录音状态
 */
export enum SmartRecordState {
  START = 0,
  PAUSE = 1,
  STOP = 2,
}

/**
 * 全局录音状态
 */
export enum GlobalRecordState {
  /**
   * 空闲
   */
  IDLE = 0,

  /**
   * 手机录音中，包括暂停状态
   */
  COMMON_RECORDING = 1,

  /**
   * 耳机录音中，包括暂停状态
   */
  EARPHONE_RECORDING = 2,
}