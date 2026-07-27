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

/**
 * 日志常量类
 *
 * @since 2025-09-30
 */
export class LogCommon {
  /**
   * 日志文件最大大小为 2MB
   */
  public static readonly MAX_FILE_SIZE_MB: number = 2;

  /**
   * 日志zip文件最大文件个数
   */
  public static readonly MAX_FILE_ZIP_SIZE: number = 10;

  /**
   * kb in bytes
   */
  public static readonly KB_IN_BYTES: number = 1024;

  /**
   * 文件已存在错误
   */
  public static readonly FILE_EXISTS_ERROR: number = 13900015;

  /**
   * 字节最小长度
   */
  public static readonly BUFFER_MIN_LENGTH: number = 50;

  /**
   * 领域
   */
  public static readonly DOMAIN: number = 0x0500;

  /**
   * 诊断
   */
  public static readonly GLOBAL_TAG: string = '[SoundRecorder]';

  /**
   * 本地日志落盘路径
   */
  public static readonly LOG_DIR: string = '/data/storage/el2/log/pafLog';

  /**
   * pafLog日志落盘错误文件名
   */
  public static readonly WRITE_ERROR_LOG_NAME: string = 'recorder_pafLog_write_error.txt';

  /**
   * pafLog日志落盘文件名
   */
  public static readonly PAFLOG_NAME: string = 'recorder_pafLog.txt';
}

/**
 * 日志等级
 */
export enum LogLevel {
  DEBUG = 0,
  INFO = 1,
  WARN = 2,
  ERROR = 3,
}

/**
 * 日志等级转换字符
 */
export enum LogLevelString {
  DEBUG = 'D',
  INFO = 'I',
  WARN = 'W',
  ERROR = 'E',
}