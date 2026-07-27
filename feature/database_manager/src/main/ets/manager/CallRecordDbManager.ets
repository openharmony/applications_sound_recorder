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

import { DatabaseManager, LogUtil, PathUtil, RecordData } from '@ohos/common';
import { dataSharePredicates, DataShareResultSet, ValuesBucket } from '@kit.ArkData';

const TAG = 'SoundRecorder_CallRecordDbManager';

const CALL_RECORD_URI = 'datashare:///com.ohos.callrecorder.datashareAbility/call_record/record_log';

class CallRecordDbManager {
  private static instance: CallRecordDbManager;

  private constructor() {
    LogUtil.info(`${TAG} new instance.`);
  }

  public static getInstance(): CallRecordDbManager {
    if (!CallRecordDbManager.instance) {
      CallRecordDbManager.instance = new CallRecordDbManager();
    }

    return CallRecordDbManager.instance;
  }

  public async deleteRecords(paths: string[]): Promise<number> {
    if (!paths.length) {
      return 0;
    }

    const dataShareHelper = DatabaseManager.getDataShareHelper();
    if (!dataShareHelper) {
      return 0;
    }

    let count = 0;
    try {
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.in('file_path', paths);
      count = await dataShareHelper.delete(CALL_RECORD_URI, predicates);
    } catch (e) {
      LogUtil.error(`${TAG} failed to batch insert call records, code ${e.code}, message: ${e.message}`);
    }

    return count;
  }

  public async hasRecord(path: string): Promise<boolean> {
    const dataShareHelper = DatabaseManager.getDataShareHelper();
    if (!dataShareHelper) {
      return false;
    }

    let result: boolean = false;
    let resultSet: DataShareResultSet | undefined;

    try {
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('file_path', path);
      resultSet = await dataShareHelper.query(CALL_RECORD_URI, predicates, ['file_path']);
      result = resultSet.goToNextRow();
    } catch (e) {
      LogUtil.error(`${TAG} failed to has call record, code ${e.code}, message: ${e.message}`);
    } finally {
      resultSet?.close();
    }

    return result;
  }

  public async insertRecords(records: RecordData[]): Promise<number> {
    let count = 0;
    const dataShareHelper = DatabaseManager.getDataShareHelper();
    if (!dataShareHelper) {
      return count;
    }

    try {
      const rows: ValuesBucket[] = [];

      for (const record of records) {
        const row: ValuesBucket = {
          'display_name': PathUtil.filename(record._data),
          'title': record.name,
          'file_path': record._data,
          'duration': record.duration,
          'date_added': record.date,
          'recorder_added': record.date
        };
        rows.push(row);
      }

      count = await dataShareHelper.batchInsert(CALL_RECORD_URI, rows);
    } catch (e) {
      LogUtil.error(`${TAG} failed to batch insert call records, code ${e.code}, message: ${e.message}`);
    }

    return count;
  }

  public async updateRecord(oldPath: string, newPath: string): Promise<number> {
    let count = 0;
    const dataShareHelper = DatabaseManager.getDataShareHelper();
    if (!dataShareHelper) {
      return count;
    }

    try {
      const row: ValuesBucket = {
        'file_path': newPath,
        'display_name': PathUtil.filename(newPath),
        'title': PathUtil.basename(newPath)
      };
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('file_path', oldPath);
      count = await dataShareHelper.update(CALL_RECORD_URI, predicates, row);
    } catch (e) {
      LogUtil.error(`${TAG} failed to update call record, code ${e.code}, message: ${e.message}`);
    }

    return count;
  }

  public async clearRecord(): Promise<number> {
    const dataShareHelper = DatabaseManager.getDataShareHelper();
    if (!dataShareHelper) {
      return 0;
    }
    let result = 0;
    try {
      const predicates = new dataSharePredicates.DataSharePredicates();
      predicates.beginsWith('file_path', PathUtil.CALLRECORD_FILEPATH);
      result = await dataShareHelper.delete(CALL_RECORD_URI, predicates);
    } catch (e) {
      LogUtil.error(`${TAG} failed to clear call record, code ${e.code}, message: ${e.message}`);
    }
    return result;
  }
}

export default CallRecordDbManager.getInstance();