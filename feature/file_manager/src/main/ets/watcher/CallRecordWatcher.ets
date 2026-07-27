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

import { LogUtil, PathUtil } from '@ohos/common';
import { FileWatcher } from './FileWatcher';
import FileManager from '../manager/FileManager';

const TAG = 'SoundRecorder_CallRecordWatcher';

class CallRecordWatcher extends FileWatcher {
  private static instance?: CallRecordWatcher;

  private constructor() {
    super(PathUtil.CALLRECORD_FILEPATH);
  }

  public static getInstance(): CallRecordWatcher {
    if (!CallRecordWatcher.instance) {
      CallRecordWatcher.instance = new CallRecordWatcher();
    }
    return CallRecordWatcher.instance;
  }

  protected async onDelete(path: string): Promise<void> {
    LogUtil.info(`${TAG} onDelete.`);
    await FileManager.removeCallRecord(path);
  }

  protected async onInsert(path: string): Promise<void> {
    LogUtil.info(`${TAG} onInsert.`);
    await FileManager.insertCallRecord(path);
  }

  protected async onSelfDelete(): Promise<void> {
    LogUtil.info(`${TAG} onSelfDelete.`);
    FileManager.onCallRecordDirRemoved();
  }
  protected async onSubDirDelete(dir: string): Promise<void> {
    LogUtil.info(`${TAG} onSubDirDelete.`);
  }

  protected async onRename(oldPath:string, newPath:string): Promise<void> {
    LogUtil.info(`${TAG} onRename.`);
    FileManager.onCallRecordRename(oldPath, newPath);
  }

  protected async onSubDirCreate(dir: string): Promise<void> {
    LogUtil.info(`${TAG} onSubDirCreate.`);
  }
}

export default CallRecordWatcher.getInstance();