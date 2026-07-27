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
import { LogCommon, LogLevel } from './common/LogCommon';
import { RollingFileWriter, TextFormatter } from './LogConduct';
import { LogConfig } from './entity/LogConfig';
import { LogEntry } from './entity/LogEntry';
import log from '@ohos.hilog';

const TAG: string = 'Logger';
const DOMAIN: number = LogCommon.DOMAIN;
const GLOBAL_TAG: string = LogCommon.GLOBAL_TAG;

export class Logger {
  private static instance: Logger;
  private static minLevel: LogLevel;
  private static rollingFileWriter: RollingFileWriter;

  private constructor(config: LogConfig) {
    log.debug(DOMAIN, GLOBAL_TAG, `[%{public}s]Logger constructor`, TAG);
    Logger.minLevel = config.minLevel ?? LogLevel.INFO;
    const formatter = new TextFormatter();
    Logger.rollingFileWriter = new RollingFileWriter(formatter);
  }

  public static getInstance(config: LogConfig): Logger {
    if (!Logger.instance) {
      Logger.instance = new Logger(config);
    }
    return Logger.instance;
  }

  public async write(level: LogLevel, message: string, context: Record<string, Object>): Promise<void> {
    if (level < Logger.minLevel) {
      return;
    }
    const entry = new LogEntry(level, message, Date.now(), context);
    await Logger.rollingFileWriter.write(entry);
  }
}