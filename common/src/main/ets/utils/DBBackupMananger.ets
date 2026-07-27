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

import { relationalStore } from '@kit.ArkData';
import { LogUtil } from './LogUtil';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';

const TAG = 'SoundRecorder_DBBackupManager';

/**
 * 数据库备份恢复管理基类
 * 通过继承实现具体能力
 *
 * @since 2023-08-10
 */
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'recorderSound.db',
  securityLevel: relationalStore.SecurityLevel.S2
};

export default class DBBackupManager {
  private backupCount = 0;
  /**
   * 普通录音数据库
   */
  private rdbStore?: relationalStore.RdbStore;
  private static instance?: DBBackupManager;
  private static lock = false;

  /**
   * 获取DBBackupManager实例
   * @returns
   */
  public static getInstance(): DBBackupManager {
    if (!DBBackupManager.instance) {
      while (DBBackupManager.lock) {
      }
      DBBackupManager.lock = true;
      if (!DBBackupManager.instance) {
        DBBackupManager.instance = new DBBackupManager();
      }
      DBBackupManager.lock = false;
    }
    return DBBackupManager.instance;
  }

  private constructor() {
    LogUtil.info(TAG + ' construct DBBackupManager.');
  }

  public async CycleBackup() {
    try {
      hiTraceMeter.startTrace('CycleBackup', 1);
      let backupFileName = getContext().databaseDir + '/rdb/recorderSoundBackup.db';
      LogUtil.info(TAG + ' CycleBackup to recorderSoundBackup db file' );
      this.rdbStore = await relationalStore.getRdbStore(getContext(), STORE_CONFIG);
      if (this.backupCount === 0) {
        this.backupCount = 1;
        this.rdbStore?.backup(backupFileName).then(() => {
          this.backupCount = 0;
        })
      }
      hiTraceMeter.finishTrace('CycleBackup', 1);
    } catch (err) {
      LogUtil.info(TAG + ` CycleBackup failed error, code: ${err?.code}, message: ${err?.message}`);
    }
  }
}