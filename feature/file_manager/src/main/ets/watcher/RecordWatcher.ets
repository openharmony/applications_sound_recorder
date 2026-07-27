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
import FileManager from '../manager/FileManager';
import { FileWatcher } from './FileWatcher';

const TAG = 'SoundRecorder_RecordWatcher';

enum SubDir {
  CALL_RECORD = 'CallRecord',
  HEADSET_RECORD = 'AudioAccessoryManager'
}

const subDir = [SubDir.CALL_RECORD, SubDir.HEADSET_RECORD];

class RecordWatcher extends FileWatcher {
  private static instance?: RecordWatcher;

  private constructor() {
    super(PathUtil.USER_FILEPATH, subDir);
  }

  public static getInstance(): RecordWatcher {
    if (!RecordWatcher.instance) {
      RecordWatcher.instance = new RecordWatcher();
    }
    return RecordWatcher.instance;
  }

  protected async onDelete(path: string): Promise<void> {
    LogUtil.info(`${TAG} onDelete.`);
    await FileManager.removeRecord(path);
  }

  protected async onInsert(path: string): Promise<void> {
    LogUtil.info(`${TAG} onInsert.`);
    await FileManager.insertRecord(path);
  }

  protected async onSelfDelete(): Promise<void> {
    LogUtil.info(`${TAG} onSelfDelete.`);
  }

  protected async onSubDirDelete(dir: string): Promise<void> {
    LogUtil.info(`${TAG} onSubDirDelete.`);
    if (dir === SubDir.CALL_RECORD) {
      FileManager.onCallRecordDirRemoved();
    }
  }
  protected async onRename(oldPath:string, newPath:string): Promise<void> {
    LogUtil.info(`${TAG} onRename.`);
    await FileManager.updateRecord(oldPath, newPath);
  }

  protected async onSubDirCreate(dir: string): Promise<void> {
    LogUtil.info(`${TAG} onSubDirCreate.`);
  }
}

export default RecordWatcher.getInstance();