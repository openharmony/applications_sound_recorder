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

import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { ArrayUtil, DatabaseManager, FileUtil, LogUtil, PathUtil, RecordData } from '@ohos/common';
import { TableNames } from '../constants/TableNames';

const TAG = 'SoundRecorder_RecordDbManager';

class RecordDbManager {
  private static instance: RecordDbManager;
  private rdbStore?: relationalStore.RdbStore;

  private constructor() {
    LogUtil.info(`${TAG} new instance.`);
  }

  public static getInstance(): RecordDbManager {
    if (!RecordDbManager.instance) {
      RecordDbManager.instance = new RecordDbManager();
    }

    return RecordDbManager.instance;
  }

  public init(): void {
    LogUtil.info(`${TAG} init.`);
    const rdbStore = DatabaseManager.getRdbStore();
    if (!rdbStore) {
      LogUtil.error(`${TAG} failed to set rdb store, it is empty.`);
    }
    this.rdbStore = rdbStore;
  }

  public batchInsert(tableName: string, list: ValuesBucket[]): Promise<number> {
    return DatabaseManager.dbBatchInsert(tableName, list);
  }

  public getNormalRecords(): Promise<RecordData[]> {
    return this.getAllDbQuery(TableNames.NORMAL_RECORD);
  }

  public getRecentDeletedRecords(): Promise<RecordData[]> {
    return this.getAllDbQuery(TableNames.RECENT_DELETED_RECORD);
  }

  public async insertNormalRecords(records: RecordData[]): Promise<number> {
    LogUtil.info(`${TAG} insert normal records.`);
    const rows: ValuesBucket[] = [];

    for (const record of records) {
      const row: ValuesBucket = {
        'id': record.id,
        'title': record.title,
        '_data': record._data,
        'file_size': record.size,
        'duration': record.duration,
        'date_added': record.date
      };
      rows.push(row);
    }

    return this.insertRecords(rows, TableNames.NORMAL_RECORD);
  }

  public async updateRecordToTables(originPath: string, newPath: string): Promise<void> {
    await this.updateRecordsAllTables(originPath, newPath);
  }

  public async updateCallRecordRecordToTables(originPath: string, newPath: string): Promise<void> {
    await this.updateRecordToRecentDelete(originPath, newPath);
    await this.updateRecordToTag(originPath, newPath);
    await this.updateRecordToRecognizeAi(originPath, newPath);
  }

  public async deleteRecordFromTables(path: string): Promise<void> {
    await this.deleteNormalOrRecentDeletedRecords([path]);
    await this.deleteRecordFromTag(path);
    await this.deleteRecordsFromRecognizeAi([path]);
  }

  public async queryRecognizeAiRecords(recordPath?: string): Promise<ValuesBucket[]> {
    const result: ValuesBucket[] = [];
    if (!this.rdbStore) {
      return result;
    }

    let resultSet: relationalStore.ResultSet | undefined;
    try {
      const predicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
      if (recordPath) {
        predicates.equalTo('record_path', recordPath);
      }
      resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        result.push(resultSet.getRow() as ValuesBucket);
      }
    } catch (err) {
      LogUtil.info(`${TAG} failed to query recognize-ai records, code: ${err.code}, message: ${err.message}`);
    } finally {
      resultSet?.close();
    }

    return result;
  }

  public async queryRecognizeAiRecordsByDirPath(dirPath: string): Promise<ValuesBucket[]> {
    const result: ValuesBucket[] = [];
    if (!this.rdbStore) {
      return result;
    }

    let resultSet: relationalStore.ResultSet | undefined;
    try {
      const predicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
      predicates.beginsWith('record_path', dirPath);
      resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        result.push(resultSet.getRow() as ValuesBucket);
      }
    } catch (err) {
      LogUtil.info(`${TAG} failed to query recognize-ai records by dirPath, code: ${err.code}, message: ${err.message}`);
    } finally {
      resultSet?.close();
    }

    return result;
  }

  public async clearRecognizeAiRecordsByDirPath(dirPath: string): Promise<number> {
    let result = 0;
    if (!this.rdbStore) {
      return result;
    }

    try {
      const predicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
      predicates.beginsWith('record_path', dirPath);
      result = await this.rdbStore.delete(predicates);
    } catch (err) {
      LogUtil.info(`${TAG} failed to clear recognize-ai records by dirPath, code: ${err.code}, message: ${err.message}`);
    }

    return result;
  }

  public async updateRecognizeAiJsonPath(originJsonPath: string, newJsonPath: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
    predicates.equalTo('json_path', originJsonPath);
    const values: ValuesBucket = { 'json_path': newJsonPath };
    return this.updateRecords(values, predicates);
  }

  public async deleteRecordsFromRecognizeAi(paths: string[]): Promise<number> {
    if (!paths.length) {
      return 0;
    }
    const predicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
    predicates.in('record_path', paths);
    return this.deleteRecords(predicates);
  }

  public createRdbPredicates(tableName: string): relationalStore.RdbPredicates {
    return new relationalStore.RdbPredicates(tableName);
  }

  public async hasRecord(path: string): Promise<boolean> {
    let result = await this.hasNormalRecord(path);
    if (result) {
      return true
    }
    return await this.hasRecentDeletedRecord(path);
  }

  public async updateRecords(
    values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    let rows = 0;

    if (!this.rdbStore) {
      return rows;
    }

    try {
      this.rdbStore.beginTransaction();
      rows = await this.rdbStore.update(values, predicates);
      this.rdbStore.commit();
    } catch (err) {
      this.rdbStore.rollBack();
      LogUtil.error(`${TAG} failed to update records, code: ${err.code}, message: ${err.message}`);
    }

    return rows;
  }

  public async updateRecordsAllTables(originPath: string, newPath: string): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    const stat = await FileUtil.stat(newPath);

    const normalPredicates = this.createRdbPredicates(TableNames.NORMAL_RECORD);
    normalPredicates.equalTo('_data', originPath);
    const normalValues: ValuesBucket = {
      'id': stat.inode,
      '_data': newPath,
      'title': PathUtil.filename(newPath)
    };

    const deletePredicates = this.createRdbPredicates(TableNames.RECENT_DELETED_RECORD);
    deletePredicates.equalTo('_data', originPath);
    const deleteValues: ValuesBucket = {
      'id': stat.inode,
      '_data': newPath,
      'title': PathUtil.filename(newPath)
    };

    const tagPredicates = this.createRdbPredicates(TableNames.TAG);
    tagPredicates.equalTo('_data', originPath);
    const tagValues: ValuesBucket = { '_data': newPath };

    const recognizeAiPredicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
    recognizeAiPredicates.equalTo('record_path', originPath);
    const recognizeAiValues: ValuesBucket = { 'record_path': newPath };

    try {
      this.rdbStore.beginTransaction();
      await this.rdbStore.update(normalValues, normalPredicates);
      await this.rdbStore.update(deleteValues, deletePredicates);
      await this.rdbStore.update(tagValues, tagPredicates);
      await this.rdbStore.update(recognizeAiValues, recognizeAiPredicates);
      this.rdbStore.commit();
    } catch (err) {
      this.rdbStore.rollBack();
      LogUtil.error(`${TAG} failed to update records, code: ${err.code}, message: ${err.message}`);
    }
  }

  public async insertRecords(records: ValuesBucket[], tableName: string, interrupted?: () => boolean): Promise<number> {
    let count = 0;
    hiTraceMeter.startTrace('insert-records', 0);
    const chunks = ArrayUtil.chunk(records);
    for (const chunk of chunks) {
      if (typeof interrupted === 'function' && interrupted()) {
        hiTraceMeter.finishTrace('insert-records', 0);
        LogUtil.info(`${TAG} insert records is interrupted, records: ${count}, origin records: ${records.length}`);
        return count;
      }
      count += await this.batchInsert(tableName, chunk);
    }
    hiTraceMeter.finishTrace('insert-records', 0);
    LogUtil.info(`${TAG} batch insert successfully, records: ${count}, origin records: ${records.length}`);
    return count;
  }

  public async updateRecordToRecognizeAi(originPath: string, newPath: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.RECOGNIZE_AI);
    predicates.equalTo('record_path', originPath);
    const values: ValuesBucket = { 'record_path': newPath };
    return this.updateRecords(values, predicates);
  }

  public async deleteNormalOrRecentDeletedRecords(paths: string[]): Promise<void> {
    if (!paths.length) {
      return;
    }
    await this.deleteRecordsFromNormal(paths);
    await this.deleteRecordsFromRecentDeleted(paths);
  }

  private async hasNormalRecord(path: string): Promise<boolean> {
    if (!this.rdbStore || !path) {
      return false;
    }

    let result: boolean = false;
    let resultSet: relationalStore.ResultSet | undefined;

    try {
      let predicates = this.createRdbPredicates(TableNames.NORMAL_RECORD);
      predicates.equalTo('_data', path);
      resultSet = await this.rdbStore.query(predicates);
      result = resultSet.goToNextRow();
    } catch (err) {
      LogUtil.info(`${TAG} failed to has normal record, code: ${err.code}, message: ${err.message}`);
    } finally {
      resultSet?.close();
    }

    return result;
  }

  private async hasRecentDeletedRecord(path: string): Promise<boolean> {
    if (!this.rdbStore || !path) {
      return false;
    }

    let result: boolean = false;
    let resultSet: relationalStore.ResultSet | undefined;

    try {
      let predicates = this.createRdbPredicates(TableNames.RECENT_DELETED_RECORD);
      predicates.equalTo('_data', path);
      resultSet = await this.rdbStore.query(predicates);
      result = resultSet.goToNextRow();
    } catch (err) {
      LogUtil.info(`${TAG} failed to has recent-deleted record, code: ${err.code}, message: ${err.message}`);
    } finally {
      resultSet?.close();
    }

    return result;
  }

  private getAllDbQuery(tableName: string): Promise<RecordData[]> {
    return DatabaseManager.getAllDbQuery(tableName);
  }

  private async updateRecordToRecentDelete(originPath: string, newPath: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.RECENT_DELETED_RECORD);
    predicates.equalTo('_data', originPath);
    const stat = await FileUtil.stat(newPath);
    const values: ValuesBucket = {
      'id': stat.inode,
      '_data': newPath,
      'title': PathUtil.filename(newPath)
    };
    return this.updateRecords(values, predicates);
  }

  private async updateRecordToNormal(originPath: string, newPath: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.NORMAL_RECORD);
    predicates.equalTo('_data', originPath);
    const stat = await FileUtil.stat(newPath);
    const values: ValuesBucket = {
      'id': stat.inode,
      '_data': newPath,
      'title': PathUtil.filename(newPath)
    };
    return this.updateRecords(values, predicates);
  }

  private updateRecordToTag(originPath: string, newPath: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.TAG);
    predicates.equalTo('_data', originPath);
    const values: ValuesBucket = { '_data': newPath };
    return this.updateRecords(values, predicates);
  }

  private deleteRecordsFromNormal(paths: string[]): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.NORMAL_RECORD);
    predicates.in('_data', paths);
    return this.deleteRecords(predicates);
  }

  private deleteRecordFromTag(path: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.TAG);
    predicates.equalTo('_data', path);
    return this.deleteRecords(predicates);
  }

  private deleteRecordsFromRecentDeleted(paths: string[]): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.RECENT_DELETED_RECORD);
    predicates.in('_data', paths);
    return this.deleteRecords(predicates);
  }

  private async deleteRecords(predicates: relationalStore.RdbPredicates): Promise<number> {
    let rows = 0;

    if (!this.rdbStore) {
      return rows;
    }

    try {
      this.rdbStore.beginTransaction();
      rows = await this.rdbStore.delete(predicates);
      this.rdbStore.commit();
    } catch (e) {
      this.rdbStore.rollBack();
      LogUtil.error(`${TAG} failed to delete records, code: ${e.code}, message: ${e.message}`);
    }

    return rows;
  }

  //更新录音周边数据
  public updateRecordSomeTables(originPath: string, newPath: string): void {
    this.updateRecordToRecentDelete(originPath, newPath);
    this.updateRecordToTag(originPath, newPath);
    this.updateRecordToRecognizeAi(originPath, newPath);
  }

  //删除录音周边数据
  public deleteRecordSomeTables(path: string): void {
    this.deleteRecordsFromRecentDeleted([path]);
    this.deleteRecordFromTag(path);
    this.deleteRecordsFromRecognizeAi([path]);
  }

  public async deleteRecentDeletedBy(key: string, value: string): Promise<number> {
    const predicates = this.createRdbPredicates(TableNames.RECENT_DELETED_RECORD);
    predicates.equalTo(key, value);
    return this.deleteRecords(predicates);
  }

  public async clearTagsByDirPath(dirPath: string): Promise<number> {
    let result = 0;
    if (!this.rdbStore) {
      return result;
    }

    try {
      const predicates = this.createRdbPredicates(TableNames.TAG);
      predicates.beginsWith('_data', dirPath);
      result = await this.rdbStore.delete(predicates);
    } catch (err) {
      LogUtil.info(`${TAG} failed to clear Tag by dirPath, code: ${err.code}, message: ${err.message}`);
    }

    return result;
  }
}

export default RecordDbManager.getInstance();