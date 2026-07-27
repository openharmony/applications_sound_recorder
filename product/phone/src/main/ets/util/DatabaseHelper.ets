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
import relationalStore from '@ohos.data.relationalStore';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { dataShare, dataSharePredicates, DataShareResultSet, ValuesBucket } from '@kit.ArkData';
import { DatabaseManager, FileUtil, PathUtil, RecordType } from '@ohos/common';

const TAG = 'RecorderSoundDatabaseHelper';
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'recorderSound.db',
  securityLevel: relationalStore.SecurityLevel.S2
};
const DB_CORRUPTED = 14800011;
const CALL_RECORD_DATABASE_URI = 'datashare:///com.ohos.callrecorder.datashareAbility/call_record/record_log';
const CHECK_OK = 'ok';
let rdbStore: relationalStore.RdbStore;
const MAX_RETRY_TIMES = 3;
const NORMAL_RECORD_DATABASE_NAME = 'normal_record_table';
const RECENT_DELETE_RECORD_DATABASE_NAME = 'recent_delete_record_table';

export class RecorderSoundDatabaseHelper {
  private static instance: RecorderSoundDatabaseHelper;
  private dataShareHelper?: dataShare.DataShareHelper;


  private constructor() {
  }

  /**
   * get RecorderSoundDatabaseHelper instance
   *
   * @returns instance
   */
  public static getInstance(): RecorderSoundDatabaseHelper {
    if (!RecorderSoundDatabaseHelper.instance) {
      RecorderSoundDatabaseHelper.instance = new RecorderSoundDatabaseHelper();
    }
    return RecorderSoundDatabaseHelper.instance;
  }

  /**
   * get rdbStore instance
   *
   * @param context
   * @returns rdb instance
   */
  async getDualWriteRdbStore(context: Context): Promise<relationalStore.RdbStore> {
    LogUtil.info(TAG + 'getDualWriteRdbStore');
    try {
      await this.getRdb(context);
      let isCheckPassed = await this.isPragmaIntegrityCheckOk();
      if (!isCheckPassed) {
        await this.restore(DB_CORRUPTED);
      }
    } catch (err) {
      LogUtil.error(TAG + `getDualWriteRdbStore failed, err: ${err.code}`);
      await this.restore(err?.code);
    }
    return rdbStore;
  }

  /**
   * check integrity
   *
   * @returns
   */
  async isPragmaIntegrityCheckOk(): Promise<boolean> {
    let checkResult = await rdbStore.execute('pragma integrity_check;');
    LogUtil.info(TAG + `getDualWriteRdbStore pragma integrity_check result:${checkResult}`);
    return checkResult === CHECK_OK;
  }

  /**
   * restore rdb when meet error
   *
   * @param errorCode
   */
  async restore(errorCode: number) {
    LogUtil.info(TAG + `restore errorCode:${errorCode}`);
    try {
      if (errorCode === DB_CORRUPTED) {
        await rdbStore.restore();
      }
      LogUtil.info(TAG +'restore ok');
    } catch (err) {
      LogUtil.error(TAG + `restore failed, err: ${err.code}`);
    }
  }

  /**
   * get rdb by config
   *
   * @param context
   * @returns
   */
  async getRdb(context: Context): Promise<void> {
    try {
      rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      this.dataShareHelper = DatabaseManager.getDataShareHelper();
    } catch (error) {
      LogUtil.error(TAG + `getRdb failed: ${error?.code}`);
    }
    LogUtil.info(TAG + 'getRdb getRdbStore build type:' + rdbStore.rebuilt);
  }

  /* instrument ignore next */
  public async insertCallRecordLog(value: ValuesBucket, inode: number): Promise<number> {
    LogUtil.info(TAG + 'insertCallRecordLog start');
    let number = 0;
    try {
      if (this.dataShareHelper === undefined) {
        return number;
      }
      const valueBucket: ValuesBucket = {
        id: inode,
        file_path: value['file_path'] as string || '',
        duration: value['duration'] as string || '',
        display_name: value['display_name'] as string || '',
        date_added: value['date_added'] as number || 0,
        recorder_added: value['recorder_added'] as number || 0,
        title: value['title'] as string || '',
        phone_number: value['phone_number'] as string || '',
        contacts: value['contacts'] as string || '',
        is_deleted: value['is_deleted'] as number || 0,
        soundrecord_display_name: value['soundrecord_display_name'] as string || ''
      };
      number = await this.dataShareHelper.insert(CALL_RECORD_DATABASE_URI, valueBucket);
    } catch (err) {
      LogUtil.error(TAG + ` insertCallRecordLog failed, code: ${err?.code}, message: ${err?.message}`);
    }
    return number;
  }

  // 获取拼接后可用的title
  /* instrument ignore next */
  public async findAvailableName(recordType: string, baseName: string, extName: string):
    Promise<string | undefined> {
    LogUtil.info(TAG + 'findAvailableName start');
    try {
      let round = 0;
      let newBaseName: string | undefined = undefined;
      while (round++ < MAX_RETRY_TIMES) {
        if (recordType === RecordType.CALL_RECORD) {
          // 查询现有可用后缀值
          const minAvailableSuffix = await this.getCallRecordAvailableSuffix(baseName);
          // 生成新标题
          newBaseName =  await this.getAvailableBaseName(recordType, baseName, minAvailableSuffix, extName);
        } else if (recordType === RecordType.AUDIO_RECORD) {
          // 查询现有可用后缀值
          const minAvailableSuffix = await this.getSoundRecordAvailableSuffix(baseName);
          // 生成新标题
          newBaseName = await this.getAvailableBaseName(recordType, baseName, minAvailableSuffix, extName);
        }
        if (newBaseName === undefined) {
          continue;
        } else {
          break;
        }
      }
      return newBaseName;
    } catch (err) {
      LogUtil.error(TAG + `findAvailableName failed, message: ${err?.message}, code is ${err?.code}`);
    }
    return undefined;
  }

  // 查询title是否重复
  private async isDupTitle(recordType: string, baseName: string, extName: string) {
    let isDuplicate = true;
    try {
      if (recordType === RecordType.CALL_RECORD) {
        // 通话录音title不带.m4a的后缀
        isDuplicate = await this.checkCallRecordTitleExists(baseName);
      } else if (recordType === RecordType.AUDIO_RECORD) {
        // 普通录音title带.m4a的后缀
        isDuplicate = await this.checkNormalRecordTitleExists(`${baseName}${extName}`);
      }
    } catch (err) {
      LogUtil.error(TAG + `isDupTitle failed, message: ${err?.message}, code is ${err?.code}`);
    }
    return isDuplicate;
  }

  // 检查标题是否在普通录音和最近删除中存在，存在时不使用该标题
  private async checkNormalRecordTitleExists(title: string): Promise<boolean> {
    let countNormalRecord: relationalStore.ResultSet | undefined;
    let countRecentDeleteRecord: relationalStore.ResultSet | undefined;
    if (rdbStore === undefined) {
      LogUtil.error(TAG + ` checkNormalRecordTitleExists rdbStore is undefined`);
      // 异常情况下，认为不可采用该后缀
      return true;
    }
    let isExist = false;
    try {
      // 事务内检查
      rdbStore.beginTransaction();
      const predicatesNormalRecord = new relationalStore.RdbPredicates(NORMAL_RECORD_DATABASE_NAME);
      predicatesNormalRecord.equalTo('title', title);
      countNormalRecord = await rdbStore.query(predicatesNormalRecord);
      const predicatesRecentDeleteRecord = new relationalStore.RdbPredicates(RECENT_DELETE_RECORD_DATABASE_NAME);
      predicatesRecentDeleteRecord.equalTo('title', title);
      countRecentDeleteRecord = await rdbStore.query(predicatesRecentDeleteRecord);
      isExist = (countNormalRecord?.rowCount > 0) || (countRecentDeleteRecord?.rowCount > 0);
      rdbStore.commit();
    } catch (err) {
      rdbStore.rollBack();
      LogUtil.error(TAG + `checkTitleExists failed, message: ${err?.message}, code is ${err?.code}`);
      // 查询异常时，认为该title已存在，避免占用重名
      isExist = true;
    } finally {
      countNormalRecord?.close();
      countRecentDeleteRecord?.close();
    }
    return isExist;
  }

  // 检查标题是否在通话录音中存在，存在时不使用该标题
  private async checkCallRecordTitleExists(title: string): Promise<boolean> {
    let result: DataShareResultSet | undefined;
    let isExist = false;
    try {
      if (this.dataShareHelper === undefined) {
        LogUtil.error(TAG + ' updateCallRecordDatabase error, dataShareHelper is null');
        // 异常情况时，认为不可采用该后缀
        return true;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('title', title);
      result = await this.dataShareHelper.query(CALL_RECORD_DATABASE_URI, predicates, ['title']);
      isExist = result?.rowCount > 0;
    } catch (err) {
      isExist = true;
      LogUtil.error(TAG + `getAvailableSuffix failed, message: ${err?.message}, code is ${err?.code}`);
    } finally {
      result?.close();
    }
    return isExist;
  }

  // 获取通话录音当前可用的后缀值
  private async getCallRecordAvailableSuffix(title: string): Promise<number> {
    let result: DataShareResultSet | undefined;
    let minAvailable = 1;
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' getCallRecordAvailableSuffix error, dataShareHelper is null');
        return -1;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      const escaped = FileUtil.getEscapeString(title);
      predicates.like('title', `${escaped}%`);
      result = await this.dataShareHelper.query(CALL_RECORD_DATABASE_URI, predicates, ['title']);
      minAvailable = this.findMinSuffix(result, title);
      LogUtil.info(TAG + `getCallRecordAvailableSuffix suffix:${minAvailable}`);
    } catch (err) {
      LogUtil.error(TAG + `getCallRecordAvailableSuffix failed, message: ${err?.message}, code is ${err?.code}`);
    } finally {
      result?.close();
    }
    return minAvailable;
  }

  // 获取普通录音当前可用的后缀值
  private async getSoundRecordAvailableSuffix(baseName: string): Promise<number> {
    LogUtil.info(TAG + 'getAvailableSuffix start');
    const sql = ` SELECT title FROM normal_record_table
                  WHERE title LIKE ? UNION ALL SELECT title FROM
                  recent_delete_record_table WHERE title LIKE ? `;
    // 查找最小可用后缀
    let minAvailable = 1;
    let result: relationalStore.ResultSet | undefined;
    try {
      // 执行联合查询（使用OR连接两个表的条件）
      const escaped: string = FileUtil.getEscapeString(baseName);
      const result = await rdbStore?.querySql(sql, [ `${escaped}%`, `${escaped}%` ]);
      minAvailable = this.findMinSuffix(result, baseName);
      LogUtil.info(TAG + `getSoundRecordAvailableSuffix suffix:${minAvailable}`);
    } catch (err) {
      LogUtil.error(TAG + `getSoundRecordAvailableSuffix failed, message: ${err?.message}, code is ${err?.code}`);
    } finally {
      result?.close();
    }
    return minAvailable;
  }

  // 获取可用的最小后缀值
  /* instrument ignore next */
  public findMinSuffix(result: DataShareResultSet | relationalStore.ResultSet | undefined, name: string): number {
    let minAvailable = 1;
    // 处理查询结果
    let usedSuffixes = new Set<number>();
    try {
      // 然后查找最小可用后缀
      while (result?.goToNextRow()) {
        const data = result.getString(result.getColumnIndex('title'));
        const originBaseName = PathUtil.basename(data);
        // 精确匹配基础标题
        // instrument ignore if
        if (originBaseName === name) {
          usedSuffixes.add(1);
        } else if (originBaseName.startsWith(`${name} (`) && originBaseName.endsWith(')')) { // 匹配带括号后缀的标题
          const suffixStr = originBaseName.substring(name.length + 2, originBaseName.length - 1);
          const suffixNum = Number(suffixStr);
          // instrument ignore if
          if (!Number.isNaN(suffixNum)) {
            usedSuffixes.add(suffixNum);
          }
        }
      }
      while (usedSuffixes.has(minAvailable)) {
        minAvailable++;
      }
    } catch (err) {
      LogUtil.error(TAG + `findMinSuffix failed, message: ${err?.message}, code is ${err?.code}`);
    }
    LogUtil.info(TAG + `findMinSuffix value: ${minAvailable}`);
    return minAvailable;
  }

  // 获取拼接后可用的title
  private async getAvailableBaseName(recordType: string, title: string, startSuffix: number, extName: string):
    Promise<string | undefined> {
    LogUtil.info(TAG + 'getAvailableBaseName start');
    try {
      const candidate = startSuffix === 1 ? title : `${title} (${startSuffix})`;
      if (!await this.isDupTitle(recordType, candidate, extName)) {
        return candidate;
      }
    } catch (err) {
      LogUtil.error(TAG + `getAvailableBaseName failed, message: ${err?.message}, code is ${err?.code}`);
    }
    return undefined;
  }
}
