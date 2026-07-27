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

import DateUtil from './DateUtil';
import { LogCommon, LogLevel, LogLevelString } from './common/LogCommon';
import { LogEntry } from './entity/LogEntry';
import { process } from '@kit.ArkTS';
import fs from '@ohos.file.fs';
import log from '@ohos.hilog';
import Checker from './Checker';
import { ILogFormatter } from './ILog';
import zLib from '@ohos.zlib';
import Buffer from '@ohos.buffer';
import { BusinessError } from '@ohos.base';

const TAG = 'LogConduct';
const DOMAIN: number = LogCommon.DOMAIN;

/**
 * text数据格式转换
 */
export class TextFormatter implements ILogFormatter {
  /**
   * text数据格式转换
   */
  format(entry: LogEntry): string {
    const datetime = DateUtil.dateFormat('YYYY-MM-dd HH:mm:ss.SSS', entry.timestamp);
    const pid = process.pid;
    const tid = process.tid;
    const level = LogLevelString[LogLevel[entry.level]];
    const message = entry.message;
    const contextMessage = entry.context?.message as string;
    return `${datetime} ${level} ${pid} ${tid} ${message} ${contextMessage} `;
  }
}

/**
 * 轮转,文件超过阈值,新建文件写入
 */
export class RollingFileWriter {
  private readonly formatter: ILogFormatter;
  private fd: number | null = null;
  private logDir: string = LogCommon.LOG_DIR;
  private currentLogPath: string = LogCommon.LOG_DIR + '/' + LogCommon.PAFLOG_NAME;
  private static isFileCreate = false;
  private static isFileErrorCreate = false;

  constructor(formatter: ILogFormatter) {
    log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]RollingFileWriter constructor`, TAG);
    this.formatter = formatter;
    if (!RollingFileWriter.isFileCreate) {
      this.makeFile();
      RollingFileWriter.isFileCreate = true;
    }
    // 保持文件句柄打开
    this.openFile();
  }

  private async openFile(): Promise<void> {
    try {
      const file = await fs.open(this.currentLogPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND);
      this.fd = file.fd;
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]Fail to open file: ${error?.code};${error?.message}`, TAG);
    }
  }

  /**
   * 写入文件
   *
   * @param entry LogEntry
   */

  public async write(entry: LogEntry): Promise<void> {
    try {
      if (Checker.isEmpty(this.fd)) {
        await this.openFile();
      }
      const content = this.formatter.format(entry) + '\n';
      const bufferContent = Buffer.from(content);
      const arrayBufferContent = bufferContent.buffer;
      await fs.write(this.fd, arrayBufferContent);
      if (await this.overThreshold(this.currentLogPath)) {
        log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]overThreshold need flush`, TAG);
        await this.rotateFile();
      }
    } catch (err) {
      const content = this.formatter.format(entry) + '\n';
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]Log write failed:${error?.code};${error?.message}`, TAG);
      await this.handleWriteError(content + JSON.stringify(error));
    }
  }

  private async overThreshold(filePath: string): Promise<boolean> {
    try {
      let stat = await fs.stat(filePath);
      return stat.size > LogCommon.MAX_FILE_SIZE_MB * LogCommon.KB_IN_BYTES * LogCommon.KB_IN_BYTES;
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]stat failed: ${error?.code};${error?.message}`, TAG);
      return false;
    }
  }

  private async rotateFile(): Promise<void> {
    try {
      if (!Checker.isEmpty(this.fd)) {
        await fs.close(this.fd);
        this.fd = null;
        log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]clear fd`, TAG);
      }

      const newPath = `${this.logDir}/recorder_pafLog_${this.getTime()}.txt`;
      await fs.copyFile(this.currentLogPath, newPath);
      await fs.truncate(this.currentLogPath);
      await this.zipFile(newPath);
      await this.cleanOldLogs();
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]rotateFile error: ${error?.code};${error?.message}`, TAG);
    }
  }

  private async cleanOldLogs(): Promise<void> {
    if (Checker.isEmpty(this.logDir)) {
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]logDir is empty`, TAG);
      return;
    }

    try {
      // 过滤zip文件
      const zipFiles = await fs.listFile(this.logDir);
      await this.filterZipFile(zipFiles);

    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]cleanOldLogs err: ${error?.code};${error?.message}`, TAG);
    }
  }

  private async filterZipFile(files: string[]): Promise<void> {
    let zipFiles: string[] = files.filter(fileName => fileName.endsWith('.zip'));
    try {
      if (zipFiles.length > LogCommon.MAX_FILE_ZIP_SIZE) {
        let oldFileNames: string[] = this.getOldFileNames(zipFiles);
        log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]cleanOldLogs zip unlink file:${oldFileNames}`, TAG);
        await this.unlinkOldFile(oldFileNames);
      }
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]filterZipFile err: ${error?.code};${error?.message}`, TAG);
    }
  }

  private async unlinkOldFile(oldFileNames: string[]): Promise<void> {
    try {
      oldFileNames.forEach(async (oldFileName) => {
        await fs.unlink(`${this.logDir}/${oldFileName}`);
      });
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]unlinkOldFile err: ${error?.code};${error?.message}`, TAG);
    }
  }

  private async zipFile(filePath: string): Promise<void> {
    try {
      await zLib.compressFile(filePath, filePath.replace(/\.txt$/, '.zip'), {});
      await fs.unlink(filePath);
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]zipFile err: ${error?.code};${error?.message}`, TAG);
    }
  }

  private getOldFileNames(files: string[]): string[] {
    // 保留最近最大文件个数，返回其余需要删除的数据
    let sortFileName: string[] = files.sort((a, b) => b.localeCompare(a));
    let oldFileNames: string[] = sortFileName.slice(LogCommon.MAX_FILE_ZIP_SIZE);
    return oldFileNames;
  }

  private async handleWriteError(logs: string): Promise<void> {
    try {
      const fallbackPath = `${this.logDir}/${LogCommon.WRITE_ERROR_LOG_NAME}`;
      if (!RollingFileWriter.isFileErrorCreate) {
        await this.createFile(fallbackPath);
        RollingFileWriter.isFileErrorCreate = true;
      }
      const file = await fs.open(fallbackPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND);
      const bufferContent = Buffer.from(logs);
      const arrayBufferContent = bufferContent.buffer;
      await fs.write(file.fd, arrayBufferContent);
      if (await this.overThreshold(fallbackPath)) {
        await fs.truncate(fallbackPath, LogCommon.MAX_FILE_SIZE_MB * LogCommon.KB_IN_BYTES * LogCommon.KB_IN_BYTES / 2);
      }
      await fs.close(file.fd);
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG, '[%{public}s]Logged to write error file', TAG);
    } catch (err) {
      const error = err as BusinessError;
      log.debug(DOMAIN, LogCommon.GLOBAL_TAG,
        `[%{public}s]write error logging failed: ${error?.code};${error?.message}`, TAG);
    }
  }

  private async createFile(filePath: string): Promise<void> {
    await fs.open(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.APPEND);
  }

  private async makeFile(): Promise<void> {
    try {
      await fs.mkdir(this.logDir, true);
      await this.createFile(this.currentLogPath);
    } catch (err) {
      if (err.code !== LogCommon.FILE_EXISTS_ERROR) {
        log.debug(DOMAIN, LogCommon.GLOBAL_TAG, `[%{public}s]failed to create logs directory:${err}`, TAG);
      }
    }
  }

  private getTime(): string {
    // 格式化输出（补零处理）
    return DateUtil.dateFormat('YYYYMMddHHmmss', Date.now());
  }
}