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

import log from '@ohos.hilog';
import { LogCommon, LogLevel } from './common/LogCommon';
import { Logger } from './Logger';
import { LogConfig } from './entity/LogConfig';
import { BusinessError } from '@kit.BasicServicesKit';
import { AsyncLock } from './AsyncLock';
import dateUtil from './DateUtil';

const TAG = 'pafLog';
const DOMAIN: number = LogCommon.DOMAIN;
const GLOBAL_TAG: string = LogCommon.GLOBAL_TAG;
const LOG_PREFIX: string = '[HmosDataRecorder]';

export class PafLogUtil {
  private static config: LogConfig = {
    minLevel: LogLevel.DEBUG,
    formatter: 'text',
  } as LogConfig;
  private static logQueue: (() => Promise<void>)[] = [];
  private static isProcessing = false;
  private static writeLock = new AsyncLock();

  private static getLogger(): Logger {
    return Logger.getInstance(PafLogUtil.config);
  }

  private static async processQueue(): Promise<void> {
    while (PafLogUtil.logQueue.length > 0) {
      const task = PafLogUtil.logQueue.shift();
      if (task) {
        try {
          await task();
        } catch (err) {
          log.error(DOMAIN, GLOBAL_TAG, `Task failed: ${err}`);
          PafLogUtil.isProcessing = false;
          return;
        }
      }
    }
    PafLogUtil.isProcessing = false;
  }

  private static enqueueLogTask(task: () => Promise<void>): void {
    PafLogUtil.logQueue.push(task);
    if (!PafLogUtil.isProcessing) {
      PafLogUtil.isProcessing = true;
      PafLogUtil.processQueue();
    }
  }

  private static async printWriteLog(level: LogLevel, tag: string, message: string, ...param: Object[]): Promise<void> {
    const datetime = dateUtil.dateFormat('YYYY-MM-dd HH:mm:ss.SSS', Date.now());
    message = datetime + ' ' + message;
    PafLogUtil.enqueueLogTask(async () => {
      try {
        await PafLogUtil.writeLock.acquire();
        await PafLogUtil.getLogger().write(level, tag, {
          message, ...param
        });
      } catch (err) {
        const error = err as BusinessError;
        log.debug(DOMAIN, GLOBAL_TAG, `[%{public}s]Log write failed:${error?.code};${error?.message}`, TAG);
      } finally {
        PafLogUtil.writeLock.release();
      }
    });
  }

  /**
   * 打印debug日志
   *
   * @param message 格式化字符串
   * @param param 字符串参数
   */
  static debug(message: string, ...param: Object[]): void {
    PafLogUtil.printWriteLog(LogLevel.DEBUG, LOG_PREFIX, message, ...param);
  }

  /**
   * 打印info日志
   *
   * @param message 格式化字符串
   * @param param 字符串参数
   */
  static info(message: string, ...param: Object[]): void {
    PafLogUtil.printWriteLog(LogLevel.INFO, LOG_PREFIX, message, ...param);
  }

  /**
   * 打印warn日志
   *
   * @param message 格式化字符串
   * @param param 字符串参数
   */
  static warn(message: string, ...param: Object[]): void {
    PafLogUtil.printWriteLog(LogLevel.WARN, LOG_PREFIX, message, ...param);
  }

  /**
   * 打印error日志
   *
   * @param message 格式化字符串
   * @param param 字符串参数
   */
  static error(message: string, ...param: Object[]): void {
    PafLogUtil.printWriteLog(LogLevel.ERROR, LOG_PREFIX, message, ...param);
  }
}