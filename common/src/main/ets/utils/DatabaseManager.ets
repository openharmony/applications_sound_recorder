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
import { LogUtil } from './LogUtil';
import common from '@ohos.app.ability.common';
import { AsyncCallback, BusinessError } from '@ohos.base';
import { RecordData } from '../model/RecordData';
import { MarkData } from '../model/MarkData';
import dataShare from '@ohos.data.dataShare';
import dataSharePredicates from '@ohos.data.dataSharePredicates';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { ValuesBucket } from '@ohos.data.ValuesBucket';
import ContactsManagerUtil from './ContactsManagerUtil';
import fs from '@ohos.file.fs';
import SampleUtil from './SampleUtil';
import { AnonymousUtil } from './AnonymousUtil';
import { AuditLogManager } from './AuditLogManager';
import { taskpool } from '@kit.ArkTS';
import SortType, { SortConstants } from '../constants/DataSortType';
import { i18n, intl } from '@kit.LocalizationKit';
import { PreferencesUtil } from './PreferencesUtil';
import { CommonConstants } from '../constants/CommonConstants';
import { DatabaseConstants, FADbProperties } from '../constants/DatabaseConstants';
import { TransferData } from '../model/TransferData';
import { sendableRelationalStore } from '@kit.ArkData';
import { SendableRecordData } from '../model/SendableRecordData';
import { DataShareUtil } from './DataShareUtil';
import GlobalContext from './GlobalContext';
import { FileUtil } from './FileUtil';
import { PathUtil } from './PathUtil';
import { Util } from './Util';
import { RecordType } from '../enums/RecordType';


const TAG = 'SoundRecorder_DatabaseManager';

const DATABASE_CORRUPTED_ERR: number = 14800011;
const CALL_RECORD_UPDATE_LIMIT: number = 1000;

/**
 * 数据库管理基类
 * 通过继承实现具体能力
 *
 * @since 2023-08-10
 */
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'recorderSound.db',
  securityLevel: relationalStore.SecurityLevel.S2
};

const CALL_RECORD_DATABASE_URI = 'datashare:///com.ohos.callrecorder.datashareAbility/call_record/record_log';
const NORMAL_RECORD_DATABASE_NAME = 'normal_record_table';
const TAG_DATABASE_NAME = 'tag';
const RECENT_DELETE_RECORD_DATABASE_NAME = 'recent_delete_record_table';
const CALL_RECORD_DATABASE = 'record_log';
const FA_FORM_TABLE: string = 'fa_form_info';
const TYPE_FIELD: string = 'type';

const singleCreateSql: string = `
    CREATE TABLE IF NOT EXISTS normal_record_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT,
        _data TEXT,
        date_added LONG,
        file_size LONG,
        duration LONG,
        record_mode LONG,
        speech_text LONG,
        angle_path TEXT,
        is_file_uploaded LONG,
        transfer_voice TEXT,
        voiceList TEXT,
        is_support_session_calibration LONG)`;

const tagCreateSql: string = `
    CREATE TABLE IF NOT EXISTS tag (
      id TEXT,
      countNum LONG,
      type LONG,
      time_in_session LONG,
      content TEXT,
      picpath TEXT,
      copypicpach TEXT,
      session_id LONG,
      back_up_num LONG,
      back_up_text TEXT,
      _data TEXT,
      quick_tag_text_index LONG,
      PRIMARY KEY(time_in_session,_data))`;

const TAG_CREATE_SQL_TMP: string = `
    CREATE TABLE IF NOT EXISTS tag_tmp (
      id TEXT,
      countNum LONG,
      type LONG,
      time_in_session LONG,
      content TEXT,
      picpath TEXT,
      copypicpach TEXT,
      session_id LONG,
      back_up_num LONG,
      back_up_text TEXT,
      _data TEXT,
      quick_tag_text_index LONG,
      PRIMARY KEY(time_in_session,_data))`;

const INSERT_TO_TEMP_TAG_RDB: string = `
    INSERT INTO tag_tmp (
        id, countNum, type, time_in_session, content,
        picpath, copypicpach, session_id,
        back_up_num, back_up_text, _data
    ) select
        id, countNum, type, time_in_session, content,
        picpath, copypicpach, session_id,
        back_up_num, back_up_text, _data
    from tag group by time_in_session, _data`;

const sharedPrefsCreateSql: string = `
    CREATE TABLE IF NOT EXISTS shared_prefs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      is_earpiece TEXT,
      is_high_definition TEXT,
      sort_mode TEXT)`;

//最新版本recognize_ai表sql
export const RECOGNIZE_AI_TABLE_CREATE_SQL_FINISH: string = `CREATE TABLE IF NOT EXISTS recognize_ai (
        id TEXT PRIMARY KEY,
        record_path TEXT,
        task_id TEXT,
        session_id TEXT,
        file_uri TEXT,
        domain INTEGER,
        state INTEGER,
        supplier INTEGER,
        consumed_order_id TEXT,
        recognize_token TEXT,
        engine_type INTEGER,
        create_time LONG,
        source_type INTEGER,
        json_path TEXT,
        attachment ASSET,
        summary_text TEXT,
        file_size LONG)`;

const CREATE_TEMP_RDB: string = `
    CREATE TABLE IF NOT EXISTS normal_record_table_tmp (
        id INTEGER,
        title TEXT,
        _data TEXT PRIMARY KEY,
        date_added LONG,
        file_size LONG,
        duration LONG,
        record_mode LONG,
        speech_text LONG,
        angle_path TEXT,
        is_file_uploaded LONG,
        transfer_voice TEXT,
        voiceList TEXT,
        is_support_session_calibration LONG,
        location TEXT)`;

const CREATE_FA_RDB: string = `
    CREATE TABLE IF NOT EXISTS fa_form_info (
      ${FADbProperties.FORM_ID} INTEGER,
      ${FADbProperties.FORM_NAME} TEXT,
      ${FADbProperties.SPECIFICATION_ID} INTEGER,
      ${FADbProperties.CREATE_TIME} INTEGER,
      ${FADbProperties.UPDATE_TIME} INTEGER)`;

const INSERT_TO_TEMP_RDB: string = `
    insert into normal_record_table_tmp (
        id, title, _data, date_added, file_size,
        duration, record_mode, speech_text,
        angle_path, is_file_uploaded, transfer_voice,
        voiceList, is_support_session_calibration
    ) select
        id, title, _data, date_added, file_size,
        duration, record_mode, speech_text,
        angle_path, is_file_uploaded, transfer_voice,
        voiceList, is_support_session_calibration
    from normal_record_table group by _data`;

const recentDeleteCreateSql: string = `
    CREATE TABLE IF NOT EXISTS recent_delete_record_table (
        id INTEGER,
        title TEXT,
        _data TEXT PRIMARY KEY,
        date_added LONG,
        file_size LONG,
        duration LONG,
        record_mode LONG,
        speech_text LONG,
        angle_path TEXT,
        is_file_uploaded LONG,
        transfer_voice TEXT,
        voiceList TEXT,
        is_support_session_calibration LONG,
        phone_number TEXT,
        delete_time LONG,
        location TEXT,
        type TEXT)`;

enum OperationStatus {
  SUCCESS = 'SUCCESS',
  FAIL = 'FAIL'
}

/**
 * 增删改操作类型
 */
enum OperationType {
  OPERATION_DELETE = 'DEL',
  OPERATION_ADD = 'ADD',
  OPERATION_MODIFY = 'MOD',
  OPERATION_OPEN = 'OPEN'
}

/**
 * 为普通录音的title创建索引normal_record_title
 */
const CREATE_INDEX_FOR_NORMAL_RECORD_TITLE = `
      create index if not exists normal_record_title on normal_record_table(title)`;

/**
 * 为普通录音最近删除表的title创建索引recent_delete_record_title
 */
const CREATE_INDEX_FOR_RECENT_DELETE_RECORD_TITLE = `
      create index if not exists recent_delete_record_title on recent_delete_record_table(title)`;

const DROP_OLD_RDB: string = `drop table 'normal_record_table'`;
const RENAME_TEMP_RDB: string = `alter table 'normal_record_table_tmp' rename to 'normal_record_table'`;

class DatabaseManager {
  private context: Context;
  /**
   * 普通录音数据库
   */
  private rdbStore?: relationalStore.RdbStore;
  /**
   * 通话录音数据库
   */
  private dataShareHelper?: dataShare.DataShareHelper;
  private auditLogManager: AuditLogManager = AuditLogManager.getInstance();
  private restoreType: string = '';
  private static instance?: DatabaseManager;
  private static lock = false;
  private static isInit = false;
  private static initPromise: Promise<void> | null = null;
  private recordCompare: intl.Collator = new intl.Collator(i18n.System.getSystemLocale(), {
    sensitivity: 'case',
    numeric: false,
    caseFirst: 'lower',
    usage: 'sort',
    collation: 'dict',
    ignorePunctuation: false
  });

  private constructor() {
    LogUtil.info(TAG + ' DatabaseManager constructor.');
    this.context = GlobalContext.getUIAbilityContext();
  }

  public static getDataBaseManager(): DatabaseManager {
    LogUtil.info(TAG + ' getDataBaseManager start.');
    if (!DatabaseManager.instance) {
      while (DatabaseManager.lock) {
      }
      DatabaseManager.lock = true;
      if (!DatabaseManager.instance) {
        DatabaseManager.instance = new DatabaseManager();
      }
      DatabaseManager.lock = false;
    }
    return DatabaseManager.instance;
  }

  public async init(context: Context, callback?: (rdbStore: relationalStore.RdbStore) => void): Promise<void> {
    LogUtil.info(TAG + ' DatabaseManager init.');
    this.context = context;
    await this.initRdbStore();
    await this.initDataShareHelper();
    await this.updateRdb();
    if (this.rdbStore) {
      callback?.(this.rdbStore);
    }
  }

  public async checkDataShareHelper(context: Context): Promise<void> {
    LogUtil.info(TAG + ' check DataShareHelper.');
    if (!this.context) {
      this.context = context;
    }
    if (!this.dataShareHelper) {
      await this.initDataShareHelper();
    }
  }

  public async destroy(): Promise<void> {
    try {
      LogUtil.info(TAG + ' DatabaseManager destroy.');
      await this.rdbStore?.close();
      this.dataShareHelper?.off('dataChange', CALL_RECORD_DATABASE_URI);
      this.dataShareHelper?.close();
      DatabaseManager.instance = undefined;
    } catch (err) {
      LogUtil.error(TAG + ` destroy occur error, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  /**
   * 获取Rdb数据库版本号
   * @returns
   */
  public getRdbVersion(): number {
    if (this.rdbStore) {
      return this.rdbStore.version;
    }
    return -1;
  }

  /**
   1、录音机新需求使用地理位置作为录音文件名，需要在数据库中新增一个location字段
   2、云同步需要设置_data为主键，所以要将原来的主键id改成_data
   */
  public async updateRdb(): Promise<void> {
    if (!this.rdbStore) {
      LogUtil.error(TAG + ' updateRdb error, rdbStore is undefined.');
      return;
    }
    LogUtil.info(TAG + ' updateRdb, old Rdb version: ' + this.getRdbVersion());
    try {
      if (this.rdbStore.version === 0) {
        LogUtil.info(TAG + ' updateRdb, CREATE_TEMP_RDB');
        await this.rdbStore.executeSql(CREATE_TEMP_RDB);
        LogUtil.info(TAG + ' updateRdb, INSERT_TO_TEMP_RDB');
        await this.rdbStore.executeSql(INSERT_TO_TEMP_RDB);
        LogUtil.info(TAG + ' updateRdb, DROP_OLD_RDB');
        await this.rdbStore.executeSql(DROP_OLD_RDB);
        LogUtil.info(TAG + ' updateRdb, RENAME_TEMP_RDB');
        await this.rdbStore.executeSql(RENAME_TEMP_RDB);
        LogUtil.info(TAG + ' updateRdb, add column phoneNumber');
        await this.rdbStore.executeSql('ALTER TABLE normal_record_table ADD COLUMN phone_number TEXT');
        LogUtil.info(TAG + ' updateRdb, add column delete_time');
        await this.rdbStore.executeSql('ALTER TABLE normal_record_table ADD COLUMN delete_time TEXT');
        this.rdbStore.version = 2;
      } else if (this.rdbStore.version === 1) {
        LogUtil.info(TAG + ' updateRdb, add column phoneNumber');
        await this.rdbStore.executeSql('ALTER TABLE normal_record_table ADD COLUMN phone_number TEXT');
        LogUtil.info(TAG + ' updateRdb, add column delete_time');
        await this.rdbStore.executeSql('ALTER TABLE normal_record_table ADD COLUMN delete_time TEXT');
        this.rdbStore.version = 2;
      }

      // tag数据库列属性变更，新增数据插入失败，需要将原表的数据拷贝到新表，同时删除旧表，重命名新表。
      if (this.rdbStore.version === 2) {
        await this.rdbStore.executeSql(TAG_CREATE_SQL_TMP);
        await this.rdbStore.executeSql(INSERT_TO_TEMP_TAG_RDB);
        await this.rdbStore.executeSql('DROP TABLE tag');
        await this.rdbStore.executeSql('ALTER TABLE tag_tmp RENAME TO tag');
        this.rdbStore.version = 3;
      }

      if (this.rdbStore.version === 3) {
        let hasTypeFiled = await this.hasFiledInTable(RECENT_DELETE_RECORD_DATABASE_NAME, TYPE_FIELD);
        if (!hasTypeFiled) {
          LogUtil.info(TAG + ' updateRdb, add column type');
          await this.rdbStore.executeSql('ALTER TABLE recent_delete_record_table ADD COLUMN type TEXT');
        }
        this.rdbStore.version = 4;
      }

      //添加实时转写是否完整的标识字段
      if (this.rdbStore.version === 4) {
        LogUtil.info(TAG + ' updateRdb, add column incomplete');
        await this.rdbStore.executeSql('ALTER TABLE recognize_ai ADD COLUMN incomplete LONG');
        this.rdbStore.version = 5;
      }

      // 在normal表和最近删除表中以title建立索引
      if (this.rdbStore.version === 5) {
        LogUtil.info(TAG + ' updateRdb, add index title');
        await this.rdbStore.executeSql(CREATE_INDEX_FOR_NORMAL_RECORD_TITLE);
        await this.rdbStore.executeSql(CREATE_INDEX_FOR_RECENT_DELETE_RECORD_TITLE);
        this.rdbStore.version = 6;
      }
    } catch (err) {
      LogUtil.error(TAG + ` updateRdb error, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  /**
   * 获取关系数据库存储对象
   * 如果已初始化过，则直接返回之前获取的对象
   * 如果没有初始化过，则使用接口获取对象，并执行数据库建表命令，如果表未创建，则会创建一张新的表
   *
   * @param createTableSql 创建新表使用的 SQL
   * @return 关系数据库存储对象
   */
  private async initRdbStore(): Promise<void> {
    if (this.rdbStore) {
      LogUtil.info(TAG + ' RdbStore already init.');
      return;
    }

    try {
      this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
      await this.rdbStore.executeSql(singleCreateSql);
      await this.rdbStore.executeSql(tagCreateSql);
      await this.rdbStore.executeSql(sharedPrefsCreateSql);
      await this.rdbStore.executeSql(recentDeleteCreateSql);
      await this.rdbStore.executeSql(RECOGNIZE_AI_TABLE_CREATE_SQL_FINISH);
      await this.rdbStore.executeSql(CREATE_FA_RDB);
      LogUtil.info(TAG + ' Get RdbStore successfully');
    } catch (error) {
      let err = error as BusinessError;
      LogUtil.error(TAG + ' Get RdbStore failed, err : ' + err.message + ' err.code : ' + err.code);
      if (err.code === DATABASE_CORRUPTED_ERR) {
        LogUtil.info(TAG + ' Database corrupted, try to restore');
        // 直接以损坏重建的方式开库
        STORE_CONFIG.allowRebuild = true;
        this.restoreType = OperationType.OPERATION_OPEN;
        await this.databaseRestore();
        try {
          this.rdbStore = await relationalStore.getRdbStore(this.context, STORE_CONFIG);
          await this.rdbStore.executeSql(singleCreateSql);
          await this.rdbStore.executeSql(tagCreateSql);
          await this.rdbStore.executeSql(sharedPrefsCreateSql);
          await this.rdbStore.executeSql(recentDeleteCreateSql);
          await this.rdbStore?.executeSql(RECOGNIZE_AI_TABLE_CREATE_SQL_FINISH);
          await this.rdbStore.executeSql(CREATE_FA_RDB);
          LogUtil.info(TAG + ' open database RdbStore successfully');
        } catch (e) {
          LogUtil.error(TAG + ' open database RdbStore failed, err : ' + e);
        }
      }
    }
  }

  /**
   * 获取rdbStore
   *
   * @return relationalStore.RdbStore
   */
  public getRdbStore(): relationalStore.RdbStore | undefined {
    return this.rdbStore;
  }

  /**
   * 所有调用口仅初始化一次数据库
   *
   * @param useContext
   * @returns
   */
  public async initDatabase(useContext: Context): Promise<void> {
    if (DatabaseManager.isInit) {
      return;
    }
    if (DatabaseManager.initPromise === null) {
      LogUtil.warn(TAG + `initDatabase begin`);
      DatabaseManager.initPromise = (async () => {
        try {
          await this.init(useContext); // 封装初始化逻辑
          DatabaseManager.isInit = true;
        } catch (err) {
          DatabaseManager.initPromise = null; // 允许重试
          LogUtil.error(TAG + ` initDatabase failed, code: ${err?.code}, message: ${err?.message}`);
        }
      })();
    }
    await DatabaseManager.initPromise; // 所有调用等待同一Promise
  }

  public getDataShareHelper(): dataShare.DataShareHelper | undefined {
    return this.dataShareHelper;
  }

  private async initDataShareHelper(): Promise<void> {
    if (this.dataShareHelper) {
      LogUtil.info(TAG + ' getDataShareHelper success.')
      return;
    }

    try {
      this.dataShareHelper = await dataShare.createDataShareHelper(this.context, CALL_RECORD_DATABASE_URI);
      LogUtil.info(TAG + ' createDataShareHelper success.');
    } catch (err) {
      LogUtil.error(TAG + ` createDataShareHelper failed, code: ${err?.code}, message: ${err?.message}`);
      this.dataShareHelper = undefined;
    }
  }

  /**
   * 按照指定的字段以及指定的顺序分批查询数据表中所有数据，并返回查询结果
   * @param tableName 数据库表名
   * @returns 查询结果
   */
  private async getResultSetWithPredicates(tableName: string):
    Promise<RecordData[]> {
    LogUtil.info(TAG + ' getResultSetWithPredicates begin.');
    let start = 0;
    let end = 1000;
    let result: RecordData[] = [];
    let values: sendableRelationalStore.ValuesBucket[] = [];
    let isNormalTable = tableName === NORMAL_RECORD_DATABASE_NAME;

    do {
      const task = new taskpool.Task('GET_RESULT_SET_WITH_PREDICATES', queryWithPredicates, this.context, tableName,
        start, end);
      values = await taskpool.execute(task) as sendableRelationalStore.ValuesBucket[];
      let records = isNormalTable ? values.map(item => this.generateRecordDataFromValueBucket(item)) :
        values.map(item => this.generateRecentDeleteRecordDataFromValueBucket(item));
      LogUtil.info(TAG + ' getResultSetWithPredicates: ' + records.length);
      result.push(...records);
      start = end;
      end += 1000;
    } while (values.length > 0)

    return result;
  }

  /**
   * 对records记录进行排序，默认排序方式为创建时间降序，创建时间相同，按照name字段排序
   * @param records 录音数组
   * @param sortType 排序方式
   */
  public sortRecords(records: RecordData[], sortType: string) {
    switch (sortType) {
      case SortType.SORT_TIME_ASC:
        records.sort((a, b) => {
          if (a.date !== b.date) {
            return a.date - b.date;
          }
          return this.recordCompare.compare(a.name, b.name);
        });
        break;
      case SortType.SORT_NAME_ASC:
        records.sort((a, b) => {
          return this.recordCompare.compare(a.name, b.name);
        });
        break;
      default:
        records.sort((a, b) => {
          if (a.date !== b.date) {
            return b.date - a.date;
          }
          return -this.recordCompare.compare(a.name, b.name);
        });
        break;
    }
  }

  // 查询列表数据
  public async getAllDbQuery(tableName: string, isSort: boolean = true): Promise<RecordData[]> {
    // 查询normal与最近删除
    let results: RecordData[] = [];
    if (tableName === RECENT_DELETE_RECORD_DATABASE_NAME) {
      results = await this.getResultSetWithPredicates(tableName);
      // 最近删除的录音按照删除时间降序排序
      results.sort((a, b) => b.deleteTime - a.deleteTime);
    } else {
      let sortType = await PreferencesUtil.get(SortConstants.PRE_KEY, SortType.SORT_TIME_DESC) as string;
      LogUtil.log(TAG + ' getAllDbQuery sort type:' + sortType);
      results = await this.getResultSetWithPredicates(tableName);
      if (isSort) {
        this.sortRecords(results, sortType);
      }
    }
    return results;
  }

  public async getNormalRecordDataFromDb(key: string, value: string): Promise<RecordData[]> {
    let resultSet: relationalStore.ResultSet | undefined;
    let result: RecordData[] = [];
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' getNormalRecordDataFromDb failed: rdbStore is undefined.');
        return result;
      }
      LogUtil.info(TAG + ' getNormalRecordDataFromDb key : ' + key);
      const predicates = new relationalStore.RdbPredicates(NORMAL_RECORD_DATABASE_NAME);
      predicates.equalTo(key, value);
      resultSet = await this.rdbStore.query(predicates);
      LogUtil.info(TAG + ' getNormalRecordDataFromDb : ' + resultSet.rowCount);
      if (resultSet.goToNextRow()) {
        result.push(this.generateRecordDataFromValueBucket(resultSet.getSendableRow()));
      }
      return result;
    } catch (error) {
      LogUtil.error(TAG + ' getNormalRecordDataFromDb failed : ' + error);
    } finally {
      resultSet?.close();
    }
    return [];
  }

  public async getCallRecordDataFromDb(key: string, value: string): Promise<RecordData[]> {
    let recordDataList: RecordData[] = [];
    let resultSet: DataShareResultSet | undefined;
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' getCallRecordDataFromDb error, dataShareHelper is null');
        return recordDataList;
      }
      LogUtil.info(TAG + ' getCallRecordDataFromDb key: ' + key + ', value: ' + value);
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo(key, value);
      resultSet = await this.dataShareHelper.query(CALL_RECORD_DATABASE_URI, predicates, []);
      LogUtil.info(TAG + ' getCallRecordDataFromDb: ' + resultSet.rowCount);
      return this.parseCallRecord(resultSet);
    } catch (err) {
      LogUtil.error(TAG + ' getCallRecordDataFromDb length error: ' + err);
      return recordDataList;
    } finally {
      resultSet?.close();
    }
  }

  public async getRecentDeleteRecordDataFromDb(key: string, value: string): Promise<RecordData[]> {
    let resultSet: relationalStore.ResultSet | undefined;
    let result: RecordData[] = [];
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' getRecentDeleteRecordDataFromDb failed: rdbStore is undefined.');
        return result;
      }
      LogUtil.info(TAG + ' getRecentDeleteRecordDataFromDb key : ' + key);
      const predicates = new relationalStore.RdbPredicates(RECENT_DELETE_RECORD_DATABASE_NAME);
      predicates.equalTo(key, value);
      resultSet = await this.rdbStore.query(predicates);
      LogUtil.info(TAG + ' getRecentDeleteRecordDataFromDb : ' + resultSet.rowCount);
      if (resultSet.goToNextRow()) {
        result.push(this.generateRecentDeleteRecordDataFromValueBucket(resultSet.getSendableRow()));
      }
      return result;
    } catch (error) {
      LogUtil.error(TAG + ' getRecentDeleteRecordDataFromDb failed : ' + error);
    } finally {
      resultSet?.close();
    }
    return [];
  }

  // 查询单个打标记
  public async queryTagByRecord(path: string): Promise<MarkData[]> {
    let resultSet: relationalStore.ResultSet | undefined;
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' getSingleDbQueryMark error, rdbStore is null');
        return [];
      }
      const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
      predicates.equalTo('_data', path);
      predicates.orderByAsc('time_in_session');
      resultSet = await this.rdbStore.query(predicates);
      return this.getMarkListFromResultSet(resultSet);
    } catch (error) {
      LogUtil.error(TAG + ' getAllFingerprints failed: ' + error);
    } finally {
      resultSet?.close();
    }
    return [];
  }

  //增插入一行数据
  public async saveRecord(rows: relationalStore.ValuesBucket[]): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' saveRecord error, rdbStore is null');
        return 0;
      }
      let count = await this.rdbStore.batchInsert(NORMAL_RECORD_DATABASE_NAME, rows);
      LogUtil.info(TAG + ' saveRecord success, count: ' + count);
      return count;
    } catch (error) {
      LogUtil.info(TAG + ` saveRecord error, code: ${error?.code}, message: ${error?.message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_ADD;
        await this.databaseRestore();
        try {
          let count = await this.rdbStore?.batchInsert(NORMAL_RECORD_DATABASE_NAME, rows) as number;
          LogUtil.info(TAG + ' restore saveRecord success. count : ' + count);
          return count;
        } catch (err) {
          LogUtil.error(TAG + ` restore saveRecord error, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  //增插入一行数据
  public async saveRecentDeleteRecord(row: relationalStore.ValuesBucket[]): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' saveRecentDeleteRecord error, rdbStore is null');
        return 0;
      }
      let count = await this.rdbStore.batchInsert(RECENT_DELETE_RECORD_DATABASE_NAME, row);
      LogUtil.info(TAG + ' saveRecentDeleteRecord success, count: ' + count);
      return count;
    } catch (error) {
      LogUtil.info(TAG + ` saveRecentDeleteRecord error, code: ${error?.code}, message: ${error?.message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_ADD;
        await this.databaseRestore();
        try {
          let count = await this.rdbStore?.batchInsert(RECENT_DELETE_RECORD_DATABASE_NAME, row) as number;
          LogUtil.info(TAG + ' restore saveRecentDeleteRecord success. count : ' + count);
          return count;
        } catch (err) {
          LogUtil.error(TAG + ` restore saveRecentDeleteRecord error, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  //增插入多条数据
  public async dbBatchInsert(tableName: string, row: Array<relationalStore.ValuesBucket>): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' dbBatchInsert error, rdbStore is null');
        return 0;
      }
      if (row.length === 0) {
        LogUtil.error(TAG + ' do not dbBatchInsert, row length is null');
        return 0;
      }
      let ret = await this.rdbStore.batchInsert(tableName, row);
      LogUtil.info(TAG + ' dbBatchInsert success, inserted count: ' + ret);
      return ret;
    } catch (err) {
      LogUtil.error(TAG + ` addInsert failed, code: ${err?.code}, message: ${err?.message}`);
      if (err.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_ADD;
        await this.databaseRestore();
        try {
          let ret = await this.rdbStore?.batchInsert(tableName, row) as number;
          LogUtil.info(TAG + ' restore dbBatchInsert success, inserted count: ' + ret);
          return ret;
        } catch (err) {
          LogUtil.error(TAG + ` restore dbBatchInsert failed, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  /**
   * 插入标记
   * @param row
   * @returns
   */
  public async insertTag(row: relationalStore.ValuesBucket): Promise<number> {
    try {
      if (!this.rdbStore || row.length === 0) {
        LogUtil.error(TAG + ' insertTag error, rdbStore is null or row length is 0.');
        return 0;
      }
      let ret = await this.rdbStore.insert(TAG_DATABASE_NAME, row);
      LogUtil.info(TAG + ' insertTag success, inserted count: ' + ret);
      return ret;
    } catch (error) {
      LogUtil.error(TAG + ` insertTag failed, code: ${error?.code} , message: ${error?.message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_ADD;
        await this.databaseRestore();
        try {
          let ret = await this.rdbStore?.insert(TAG_DATABASE_NAME, row) as number;
          LogUtil.info(TAG + ' restore insertTag success, inserted count: ' + ret);
          return ret;
        } catch (err) {
          LogUtil.error(TAG + ` restore insertTag failed, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  /**
   * 删除标记
   * @param row
   * @returns
   */
  public async deleteTag(filePath: string, timeInSession: number): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' deleteTag error, rdbStore is null.');
        return 0;
      }
      const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
      predicates.equalTo('_data', filePath);
      predicates.equalTo('time_in_session', timeInSession);
      let ret = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG + ' deleteTag success, delete count: ' + ret);
      return ret;
    } catch (error) {
      LogUtil.error(TAG + ` deleteTag failed, code: ${error?.code} , message: ${error?.message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_DELETE;
        await this.databaseRestore();
        try {
          const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
          predicates.equalTo('_data', filePath);
          predicates.equalTo('time_in_session', timeInSession);
          let ret = await this.rdbStore?.delete(predicates) as number;
          LogUtil.info(TAG + ' deleteTag success, delete count: ' + ret);
          return ret;
        } catch (err) {
          LogUtil.error(TAG + ` deleteTag failed again, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  /**
   * 重命名录音文件的时候，批量更新该录音文件中的标记
   * @param filePath
   * @param timeInSession
   * @param val
   * @returns
   */
  public async batchUpdateTag(oldPath: string, newPath: string): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateTag error, rdbStore is null.');
        return 0;
      }
      const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
      predicates.equalTo('_data', oldPath);
      let ret = await this.rdbStore.update({ '_data': newPath }, predicates);
      LogUtil.info(TAG + ' updateTag success, update count: ' + ret);
      return ret;
    } catch (err) {
      LogUtil.error(TAG + ` updateTag failed, code: ${err?.code}, message: ${err?.message}`);
      if (err.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_MODIFY;
        await this.databaseRestore();
        const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
        predicates.equalTo('_data', oldPath);
        let ret = await this.rdbStore?.update({ '_data': newPath }, predicates) as number;
        LogUtil.info(TAG + ' updateTag success, update count: ' + ret);
        return ret;
      }
      return 0;
    }
  }

  /**
   * 更新标记
   * @param row
   * @returns
   */
  public async updateTag(filePath: string, timeInSession: number, val: relationalStore.ValuesBucket): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateTag error, rdbStore is null.');
        return 0;
      }
      const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
      predicates.equalTo('_data', filePath);
      predicates.equalTo('time_in_session', timeInSession);
      let ret = await this.rdbStore.update(val, predicates);
      LogUtil.info(TAG + ' updateTag success, update count: ' + ret);
      return ret;
    } catch (error) {
      LogUtil.error(TAG + ` updateTag failed, code: ${error?.code} , message: ${error?.message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_MODIFY;
        await this.databaseRestore();
        try {
          const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
          predicates.equalTo('_data', filePath);
          predicates.equalTo('time_in_session', timeInSession);
          let ret = await this.rdbStore?.update(val, predicates) as number;
          LogUtil.info(TAG + ' updateTag success, update count: ' + ret);
          return ret;
        } catch (err) {
          LogUtil.error(TAG + ` updateTag failed again, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  // update normal record
  public async updateNormalRecordDatabase(oldPath: string, row: relationalStore.ValuesBucket): Promise<void> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateDatabase error, rdbStore is null');
        return;
      }
      const predicates = new relationalStore.RdbPredicates(NORMAL_RECORD_DATABASE_NAME);
      predicates.equalTo('_data', oldPath);
      let count = await this.rdbStore.update(row, predicates);
      LogUtil.info(TAG + ' updateDatabase success count: ' + count);
    } catch (error) {
      LogUtil.error(TAG + ' updateDatabase failed: ' + error);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_MODIFY;
        await this.databaseRestore();
        const predicates = new relationalStore.RdbPredicates(NORMAL_RECORD_DATABASE_NAME);
        predicates.equalTo('_data', oldPath);
        let count = await this.rdbStore?.update(row, predicates);
        LogUtil.info(TAG + ' restore updateDatabase success count: ' + count);
      }
    }
  }

  // update call record
  public async updateCallRecordDatabase(paths: string[], row: ValuesBucket): Promise<number> {
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' updateCallRecordDatabase error, dataShareHelper is null');
        return 0;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.in('file_path', paths);
      let count = 0;
      if (paths.length > CALL_RECORD_UPDATE_LIMIT) {
        let result =
          await this.dataShareHelper.batchUpdate({ CALL_RECORD_DATABASE: [{ values: row, predicates: predicates }] });
        count = result[CALL_RECORD_DATABASE][0];
      } else {
        count = await this.dataShareHelper.update(CALL_RECORD_DATABASE_URI, predicates, row);
      }
      await this.dataShareHelper.notifyChange(CALL_RECORD_DATABASE_URI);
      LogUtil.info(TAG + ' updateCallRecordDatabase success count: ' + count);
      return count;
    } catch (err) {
      LogUtil.error(TAG + ` updateCallRecordDatabase failed, code: ${err?.code}, message: ${err?.message}`);
      return 0;
    }
  }

  /**
   * 删除某一项
   *
   * @param PARMASInfo
   */
  public async removeNormalRecordData(filePath: Array<string>): Promise<number> {
    LogUtil.info(TAG + ' removeNormalRecordData begin, count to delete: ' + filePath.length);
    if (filePath.length === 0) {
      LogUtil.info(TAG + ' removeNormalRecordData selected length 0, return');
      return 0;
    }
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' removeNormalRecordData error, rdbStore is null');
        return 0;
      }
      const predicates = new relationalStore.RdbPredicates(NORMAL_RECORD_DATABASE_NAME);
      predicates.in('_data', filePath);
      let count = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG + ' removeNormalRecordData successfully: ' + count);
      return count;
    } catch (error) {
      LogUtil.info(TAG + ' removeNormalRecordData failed: ' + error);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_DELETE;
        await this.databaseRestore();
        try {
          const predicates = new relationalStore.RdbPredicates(NORMAL_RECORD_DATABASE_NAME);
          predicates.in('_data', filePath);
          let count = await this.rdbStore?.delete(predicates);
          return count || 0;
        } catch (err) {
          LogUtil.error(TAG + ` delete failed, code: ${err?.code}, message: ${err?.message}`);
        }
      }
      return 0;
    }
  }

  public async removeCallRecordData(paths: Array<string>): Promise<void> {
    LogUtil.info(TAG + ' removeCallRecordData: ' + paths.length);
    if (paths.length === 0) {
      LogUtil.info(TAG + ' removeCallRecordData selected length 0, return');
      return;
    }
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' removeCallRecordData error, dataShareHelper is null');
        return;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.in('file_path', paths);
      let number = await this.dataShareHelper.delete(CALL_RECORD_DATABASE_URI, predicates);
      LogUtil.info(TAG + ' removeCallRecordData success, count: ' + number);
      await this.dataShareHelper.notifyChange(CALL_RECORD_DATABASE_URI);
    } catch (err) {
      LogUtil.info(TAG + ` removeCallRecordData failed, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  public async removeRecentDeleteRecordData(data: Array<string>): Promise<number> {
    LogUtil.info(TAG + ' removeRecentDeleteRecordData.');
    if (data.length === 0) {
      LogUtil.info(TAG + ' removeRecentDeleteRecordData selected length 0, return');
      return 0;
    }
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' removeRecentDeleteRecordData error, rdbStore is null');
        return 0;
      }
      const predicates = new relationalStore.RdbPredicates(RECENT_DELETE_RECORD_DATABASE_NAME);
      predicates.in('_data', data);
      let count = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG + ' removeRecentDeleteRecordData successfully: ' + count);
      return count
    } catch (error) {
      LogUtil.info(TAG + ' removeRecentDeleteRecordData failed: ' + error);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_DELETE;
        await this.databaseRestore();
        try {
          const predicates = new relationalStore.RdbPredicates(RECENT_DELETE_RECORD_DATABASE_NAME);
          predicates.in('_data', data);
          return await this.rdbStore?.delete(predicates) || 0;
        } catch (err) {
          LogUtil.error(TAG + ' removeRecentDeleteRecordData delete failed: ' + err);
        }
      }
      return 0;
    }
  }

  public async markCallRecordMovedRecycleBin(callRecordList: string[]): Promise<number> {
    if (callRecordList.length > 0) {
      LogUtil.info(TAG + ' markCallRecordMovedRecycleBin count: ' + callRecordList.length);
      return await this.updateCallRecordDatabase(callRecordList, { 'is_deleted': 1 });
    }
    return 0;
  }

  public async markCallRecordRecoverFromRecycleBin(callRecordList: string[]): Promise<void> {
    if (callRecordList.length > 0) {
      LogUtil.info(TAG + ' markCallRecordRecoverFromRecycleBin count: ' + callRecordList.length);
      await this.updateCallRecordDatabase(callRecordList, { 'is_deleted': 0 });
    }
  }

  /**
   * 删除指定录音文件下的标记
   *
   */
  public async batchRemoveTag(recordPath: string[]): Promise<void> {
    LogUtil.info(TAG + ' batchRemoveTag tag of files count: ' + recordPath.length);
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' batchRemoveTag error, rdbStore is null');
        return;
      }
      const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
      predicates.in('_data', recordPath);
      let count = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG + ' batchRemoveTag successfully, count: ' + count);
    } catch (error) {
      LogUtil.info(TAG + ' batchRemoveTag failed: ' + error);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_DELETE;
        await this.databaseRestore();
        try {
          const predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
          predicates.in('_data', recordPath);
          let count = await this.rdbStore?.delete(predicates);
          LogUtil.info(TAG + ' batchRemoveTag successfully, count: ' + count);
        } catch (err) {
          LogUtil.error(TAG + ' batchRemoveTag failed again: ' + err);
        }
      }
    }
  }

  public async batchInsertTag(recordPath: string, row: Array<relationalStore.ValuesBucket>): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' batchInsertTag error, rdbStore is null');
        return 0;
      }
      let predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
      predicates.equalTo('_data', recordPath);
      let count = await this.rdbStore.delete(predicates);
      if (count > 0) {
        LogUtil.info(TAG + ' tag already exist delete them first, count: ' + count);
      }
      count = await this.rdbStore.batchInsert(TAG_DATABASE_NAME, row);
      LogUtil.info(TAG + ' batchInsertTag success, count: ' + count);
      return count;
    } catch (error) {
      LogUtil.error(`${TAG} addInsert failed: ${(error as BusinessError).message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_ADD;
        await this.databaseRestore();
        try {
          let predicates = new relationalStore.RdbPredicates(TAG_DATABASE_NAME);
          predicates.equalTo('_data', recordPath);
          let count = await this.rdbStore?.delete(predicates) as number;
          if (count > 0) {
            LogUtil.info(TAG + ' tag already exist delete them first, count: ' + count);
          }
          count = await this.rdbStore?.batchInsert(TAG_DATABASE_NAME, row) as number;
          LogUtil.info(TAG + ' batchInsertTag success, count: ' + count);
          return count;
        } catch (err) {
          LogUtil.info(TAG + ' batchInsertTag failed, error: ' + err);
        }
      }
      return 0;
    }
  }

  private async databaseRestore() {
    try {
      const backupPath = getContext().databaseDir + '/rdb/recorderSoundBackup.db';
      if (!fs.access(backupPath)) {
        LogUtil.info(TAG + ' no backup file');
        this.closeRdb(this.rdbStore);
        this.rdbStore = await relationalStore.getRdbStore(getContext(), STORE_CONFIG)
        await this.rdbStore.executeSql(singleCreateSql);
        await this.rdbStore.executeSql(tagCreateSql);
        await this.rdbStore.executeSql(sharedPrefsCreateSql);
        await this.rdbStore.executeSql(recentDeleteCreateSql);
        await this.rdbStore.executeSql(RECOGNIZE_AI_TABLE_CREATE_SQL_FINISH);
        await this.rdbStore.executeSql(CREATE_FA_RDB);
        return;
      }
      this.rdbStore = await relationalStore.getRdbStore(getContext(), STORE_CONFIG);
      await this.rdbStore?.restore(backupPath);
      this.auditLogManager.backupAuditLog(this.restoreType, OperationStatus.SUCCESS);
      LogUtil.info(TAG + ' Restore successfully this.rdbStore : ' + this.rdbStore.version);
    } catch (err) {
      this.auditLogManager.backupAuditLog(this.restoreType, OperationStatus.FAIL);
      LogUtil.info(TAG + ` Restore err, code: ${err?.code}, message: ${err?.message}`);
    }
    await this.closeRdb(this.rdbStore);
    try {
      this.rdbStore = await relationalStore.getRdbStore(getContext(), STORE_CONFIG)
      await this.rdbStore.executeSql(singleCreateSql);
      await this.rdbStore.executeSql(RECOGNIZE_AI_TABLE_CREATE_SQL_FINISH);
      await this.rdbStore.executeSql(tagCreateSql);
      await this.rdbStore.executeSql(sharedPrefsCreateSql);
      await this.rdbStore.executeSql(recentDeleteCreateSql);
      await this.rdbStore.executeSql(CREATE_FA_RDB);
    } catch (err) {
      LogUtil.error(TAG + ` databaseRestore error, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  private async closeRdb(rdbStore: relationalStore.RdbStore | undefined) {
    try {
      await rdbStore?.close();
      rdbStore = undefined;
    } catch (err) {
      LogUtil.error(TAG + ` closeRdb err, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  private generateRecordDataFromValueBucket(value: sendableRelationalStore.ValuesBucket): RecordData {
    let item: RecordData = new RecordData();
    item.id = value.get('id') as number;
    item.title = value.get('title') as string;
    item.location = value.get('location') as string;
    item.name = item.title?.substring(0, item.title?.lastIndexOf('.')) || '';
    item.duration = value.get('duration') as number;
    item._data = value.get('_data') as string;
    item.date = value.get('date_added') as number;
    item.size = value.get('file_size') as number;
    item.recordMode = value.get('record_mode') as number;
    item.speechText = value.get('speech_text') as number;
    item.anglePath = value.get('angle_path') as string;
    item.isFileUploaded = value.get('is_file_uploaded') as number;
    item.transferVoice = value.get('transfer_voice') as string;
    item.isSupportSessionCalibration = value.get('is_support_session_calibration') as number;
    item.voiceList = value.get('voiceList') as string;
    item.type = RecordType.AUDIO_RECORD;
    return item;
  }

  public getRestDays(delete_time: number): number {
    const deleteDuration = (Date.now() - delete_time) / (24 * 60 * 60 * 1000);
    let restDays = CommonConstants.RECYCLE_DAYS_LIMIT - Math.floor(deleteDuration);
    restDays = restDays <= 0 ? 1 : (restDays > 30 ? 30 : restDays);
    return restDays;
  }

  private generateRecentDeleteRecordDataFromValueBucket(value: sendableRelationalStore.ValuesBucket): RecordData {
    let context = GlobalContext.getUIAbilityContext();
    let item: RecordData = new RecordData();
    item.id = value.get('id') as number;
    item.title = value.get('title') as string;
    item.location = value.get('location') as string;
    item.duration = value.get('duration') as number;
    item._data = value.get('_data') as string;
    item.date = value.get('date_added') as number;
    item.size = value.get('file_size') as number;
    item.recordMode = value.get('record_mode') as number;
    item.speechText = value.get('speech_text') as number;
    item.anglePath = value.get('angle_path') as string;
    item.isFileUploaded = value.get('is_file_uploaded') as number;
    item.transferVoice = value.get('transfer_voice') as string;
    item.isSupportSessionCalibration = value.get('is_support_session_calibration') as number;
    item.voiceList = value.get('voiceList') as string;
    item.deleteTime = value.get('delete_time') as number;
    item.phoneNumber = value.get('phone_number') as string;
    if (item.phoneNumber) {
      item.name = item.title || '';
    } else {
      item.name = item.title?.substring(0, item.title?.lastIndexOf('.')) || '';
    }
    let restDays = this.getRestDays(item.deleteTime);
    item.remainDaysTip =
      context.resourceManager.getPluralStringValueSync($r('app.plural.remaining_days_plural').id, restDays);
    item.type = value.get('type') as string;
    return item;
  }

  private async getMarkListFromResultSet(resultSet: relationalStore.ResultSet): Promise<MarkData[]> {
    const fingerMarkList: MarkData[] = [];
    while (resultSet.goToNextRow()) {
      const item: MarkData = new MarkData(
        resultSet.getString(resultSet.getColumnIndex('content')),
        resultSet.getLong(resultSet.getColumnIndex('time_in_session')),
        resultSet.getLong(resultSet.getColumnIndex('countNum')),
        false,
        resultSet.getString(resultSet.getColumnIndex('id')),
        resultSet.getLong(resultSet.getColumnIndex('type')),
        resultSet.getString(resultSet.getColumnIndex('_data')),
      );
      fingerMarkList.push(item);
    }
    LogUtil.info(TAG + ' getMarkListFromResultSet length ' + fingerMarkList.length);
    return fingerMarkList;
  }

  private parseCallRecord(resultSet: DataShareResultSet): RecordData[] {
    let recordDataList: RecordData[] = [];
    while (resultSet.goToNextRow()) {
      let item: RecordData = new RecordData();
      item.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      // 通话录音中item.title始终保存的是display_name，item.name始终保存的是用来录音机界面显示的字段
      item.contacts = resultSet.getString(resultSet.getColumnIndex('title'));
      // 修正之前出错的title名称
      if (Util.isHistoricalDirtyData(item.contacts)) {
        item.contacts = '';
      }
      item.title = ContactsManagerUtil.getInstance().getTitleFromFilePath(
        resultSet.getString(resultSet.getColumnIndex('file_path'))
      );
      if (!item.contacts) {
        item.name = ContactsManagerUtil.getInstance().getContactNameFromDisplayName(item.title);
      } else {
        item.name = item.contacts;
      }
      item.duration = Number(resultSet.getString(resultSet.getColumnIndex('duration')));
      item.date = resultSet.getLong(resultSet.getColumnIndex('recorder_added'));
      item.phoneNumber = resultSet.getString(resultSet.getColumnIndex('phone_number'));
      if (!item.phoneNumber) {
        // 如果通话录音记录来自于双框架手机，并且用户在双框架手机上进行过重命名，然后克隆到单框架，此时phone_number字段可能为空
        // 判断录音是否是通话录音是通过phoneNumber是否为空来判断的，所以这种情况下给phoneNumber赋一个初始值
        LogUtil.error(TAG + ' phoneNumber maybe null if user rename call record in old device then clone');
        item.phoneNumber = '0';
      }
      item._data = resultSet.getString(resultSet.getColumnIndex('file_path'));
      item.delete = resultSet.getLong(resultSet.getColumnIndex('is_deleted'));
      LogUtil.info(TAG + ' parseCallRecord is_deleted ' + item.delete);
      LogUtil.info(TAG + ' parseCallRecord title ' + AnonymousUtil.anonymous(item.title));
      recordDataList.push(item);
    }
    LogUtil.info(TAG + ' parseCallRecord length ' + recordDataList.length);
    return recordDataList;
  }

  private generateCallRecordData(item: SendableRecordData): RecordData {
    let result: RecordData = new RecordData();
    result.id = item.id;
    result.title = item.title;
    result.contacts = item.contacts;
    result.name = item.name;
    result.duration = item.duration;
    result.date = item.date;
    result.phoneNumber = item.phoneNumber;
    result._data = item._data;
    result.delete = item.delete;
    //转换拼音
    result.phonetic = item.phonetic;
    result.initials = item.initials;
    result.type = RecordType.CALL_RECORD;
    return result;
  }

  /**
   * 按照指定的字段以及指定的顺序分批查询通话录音数据表中所有数据，并返回查询结果
   * @param uri 通话录音datashare Uri
   * @returns 查询结果
   */
  private async getCallRecordWithPredicates(uri: string):
    Promise<RecordData[]> {
    LogUtil.info(TAG + ' getCallRecordWithPredicates begin.');
    let start = 0;
    let end = 4000;
    let result: RecordData[] = [];
    let values: SendableRecordData[] = [];
    do {
      const task = new taskpool.Task('GET_CALL_RECORDS', queryCallRecordWithPredicates,
        this.context, uri, start, end);
      values = await taskpool.execute(task) as SendableRecordData[];
      LogUtil.info(TAG + ' getCallRecordWithPredicates: ' + values.length);
      let records = values.map(item => this.generateCallRecordData(item));
      result.push(...records);
      start = end;
      end += 4000;
    } while (values.length > 0)
    DataShareUtil.closeDataShareHelper();
    LogUtil.info(TAG + ' getCallRecordWithPredicates end.');
    return result;
  }

  // 通话录音数据库
  public async getInitialCallRecordList(): Promise<RecordData[]> {
    let recordDataList: RecordData[] = [];
    try {
      let sortType = await PreferencesUtil.get(SortConstants.PRE_KEY, SortType.SORT_TIME_DESC) as string;
      ContactsManagerUtil.getInstance().reset();
      recordDataList = await this.getCallRecordWithPredicates(CALL_RECORD_DATABASE_URI);
      this.sortRecords(recordDataList, sortType)
    } catch (err) {
      LogUtil.error(TAG + ' getInitialCallRecordList length error: ' + err);
    }
    return recordDataList;
  }

  // 获取通话录音总条数
  public async getCallRecordCount(): Promise<number> {
    let count: number = 0;
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' getCallRecordCount error, dataShareHelper is null');
        return 0;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.orderByDesc('recorder_added');
      let resultSet = await this.dataShareHelper.query(CALL_RECORD_DATABASE_URI, predicates, []);
      count = resultSet.rowCount;
      LogUtil.error(TAG + ' getCallRecordCount length: ' + count);
      resultSet.close();
      return count;
    } catch (err) {
      LogUtil.error(`${TAG} getCallRecordCount length error, code: ${err.code}, message: ${err.message}`);
    }
    return count;
  }

  // 获取未删除的通话录音数量
  public async getNormalCallRecordCount(): Promise<number> {
    let count: number = 0;
    let resultSet: DataShareResultSet | undefined;
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' getNormalCallRecordCount error, dataShareHelper is null');
        return 0;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('is_deleted', 0);
      resultSet = await this.dataShareHelper.query(CALL_RECORD_DATABASE_URI, predicates, []);
      count = resultSet.rowCount;
      LogUtil.error(TAG + ' getNormalCallRecordCount length: ' + count);
      return count;
    } catch (err) {
      LogUtil.error(`${TAG} getNormalCallRecordCount error, code: ${err.code}, message: ${err.message}`);
    } finally {
      resultSet?.close();
    }
    return count;
  }

  /**
   * 获取新增的通话录音
   * @returns
   */
  public async getRecordOfTheNewCall(): Promise<RecordData | undefined> {
    let resultSet: DataShareResultSet | undefined;
    try {
      if (!this.dataShareHelper) {
        LogUtil.error(TAG + ' getRecordOfTheNewCall error, dataShareHelper is null');
        return;
      }
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.orderByDesc('recorder_added').limit(1, 0);
      resultSet = await this.dataShareHelper.query(CALL_RECORD_DATABASE_URI, predicates, []);
      let recordDataArray = this.parseCallRecord(resultSet);
      if (recordDataArray.length === 1) {
        return recordDataArray[0];
      }
      return;
    } catch (err) {
      LogUtil.error(`${TAG} getRecordOfTheNewCall error, code: ${err.code}, message: ${err.message}`);
      return;
    } finally {
      resultSet?.close();
    }
  }

  public registerDataChangeToDataShare(callback: AsyncCallback<void>): void {
    try {
      if (this.dataShareHelper) {
        // 监听通话录音数据库变化，dataShareHelper要唯一
        this.dataShareHelper.on('dataChange', CALL_RECORD_DATABASE_URI, callback);
        LogUtil.info(TAG + ' registerDataChangeToDataShare success.');
      }
    } catch (err) {
      LogUtil.error(TAG + ` registerDataChangeToDataShare error, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  public async scanFiles(
    normalRecordList: RecordData[],
    recentDeleteList: RecordData[],
    fileName: string,
    sandboxAudios: string[]
  ): Promise<RecordData[]> {
    LogUtil.info(`${TAG} scanFiles.`);
    let normalRecord = normalRecordList.map(item => item._data.substring(item._data.lastIndexOf('/') + 1));
    let recentDelete = recentDeleteList.map(item => item._data.substring(item._data.lastIndexOf('/') + 1));

    const newFilenames =
      sandboxAudios.filter(item => !normalRecord.includes(item) && !recentDelete.includes(item) && item !== 'fileShare'
        && !(fileName && item.startsWith(fileName) && FileUtil.AUDIO_SUFFIX.some(suffix => item.endsWith(suffix))));

    // newFilenames.length > 0时，说明沙箱有手工推送文件
    if (newFilenames.length > 0) {
      // 既要将文件存数据库，也要推送到normalRecordList供页面展示
      normalRecordList = await this.saveScanFiles(normalRecordList, newFilenames);
    }

    return normalRecordList;
  }

  private async saveScanFiles(normalRecordList: RecordData[], filenames: string[]): Promise<RecordData[]> {
    LogUtil.info(TAG + ' saveScanFiles.');
    let context = GlobalContext.getUIAbilityContext();
    let filesDir = context.filesDir;
    let rows: relationalStore.ValuesBucket[] = [];
    for (let filename of filenames) {
      LogUtil.info(`${TAG} saveScanFiles, filename: ${filename}`);
      let filePath = filesDir + '/' + filename;

      try {
        let stat = await FileUtil.stat(filePath);
        let date = stat.modifyTime;
        LogUtil.info(`${TAG} saveScanFiles, filename.date: ${date}`);
        const duration = await FileUtil.getDuration(filePath);
        if (duration > 0) {
          // 合并波形采样数据
          await SampleUtil.recoverSamplesToRecordFile(filePath);
          const userFilepath = PathUtil.USER_FILEPATH;
          const newFileName = await FileUtil.getFreeNewFilename(filename, userFilepath);
          const newFilePath = `${userFilepath}/${newFileName}`;
          const ok = await FileUtil.moveFile(filePath, newFilePath);
          if (ok) {
            filename = newFileName;
            filePath = newFilePath;
          }

          stat = await FileUtil.stat(filePath);
          rows.push({
            'id': stat.inode,
            'title': filename, // 文件名
            '_data': filePath,
            'date_added': date, // 创建时间
            'file_size': stat.size,
            'duration': duration, // 录制时长
            'voiceList': '', // 录音音频振幅数据列表
          });

          let item: RecordData = new RecordData();
          item.id = stat.inode;
          item.title = filename;
          item.name = item.title.substring(0, item.title.lastIndexOf('.')) || '';
          item.duration = duration;
          item._data = filePath;
          item.date = date;
          item.size = stat.size;
          item.type = RecordType.AUDIO_RECORD;
          normalRecordList.push(item);
        } else {
          LogUtil.error(TAG + ' metaData?.duration === 0, del ' + filename);
          fs.rmdirSync(filePath);
        }
      } catch (error) {
        LogUtil.error(TAG + ' saveScanFiles error : ' + error);
      }
    }
    this.dbBatchInsert('normal_record_table', rows);
    return normalRecordList;
  }

  /**
   * 克隆和备份场景下，获取新机上已经存在的录音记录的ValuesBucket，用于去重操作
   * @param config
   * @param tableName
   * @returns
   */
  public async getNewDeviceRecordDataValueBuckets(tableName: string): Promise<relationalStore.ValuesBucket[]> {
    LogUtil.info(TAG + ' getNewDeviceRecordDataValueBuckets');
    let result: relationalStore.ValuesBucket[] = [];
    let resultSet: relationalStore.ResultSet | undefined;
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' getNewDeviceRecordDataValueBuckets error, rdbStore is null');
        return result;
      }
      let predicates = new relationalStore.RdbPredicates(tableName);
      resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        result.push(resultSet.getRow());
      }
      LogUtil.info(TAG + ' getNewDeviceRecordDataValueBuckets: ' + resultSet.rowCount);
    } catch (error) {
      LogUtil.error(`${TAG} getNewDeviceRecordDataValueBuckets failed, error: ${error.code}, ${error.message}`);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_ADD;
        await this.databaseRestore();
        try {
          let predicates = new relationalStore.RdbPredicates(tableName);
          resultSet = await this.rdbStore?.query(predicates);
          while (resultSet?.goToNextRow()) {
            result.push(resultSet?.getRow());
          }
        } catch (err) {
          LogUtil.error(`${TAG} getNewDeviceRecordDataValueBuckets failed again, error: ${err.code}, ${err.message}`);
        }
      }
    } finally {
      resultSet?.close();
    }
    return result;
  }

  //通过_data,time_in_session删除tag表
  public async deleteNormalTagByDataTimeInSession(data: string, timeInSession: number) {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' removeNormalRecordData error, rdbStore is null');
        return;
      }
      this.rdbStore.beginTransaction();
      let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(DatabaseConstants.TAG_TABLE);
      predicates.equalTo('_data', data);
      predicates.and();
      predicates.equalTo('time_in_session', timeInSession);
      await this.rdbStore.delete(predicates);
      this.rdbStore.commit();
    } catch (error) {
      LogUtil.error(`${TAG} deleteNormalTagByDataTimeInSession message: ${(error as BusinessError).message} code: ${(error as BusinessError).code}`);
    }
  }

  public async queryRecordTransferData(data: string): Promise<TransferData[]> {
    let transferData: TransferData[] = [];
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' queryRecordTransferData error, rdbStore is null');
        return transferData;
      }
      let predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.equalTo('record_path', data);
      let resultSet = await this.rdbStore.query(predicates);
      LogUtil.info(TAG + `resultSet:${resultSet.columnCount}`);
      if (resultSet.goToRow(0)) {
        let item = this.parseTransferData(resultSet);
        transferData.push(item);
      }

      resultSet.close();
      LogUtil.info(TAG + ' queryRecordTransferData length ' + transferData.length);
      return transferData;
    } catch (error) {
      LogUtil.error(`${TAG} queryRecordTransferData message: ${(error as BusinessError).message} code: ${(error as BusinessError).code}`);
      return transferData;
    }
  }

  //增插入一行TransferData数据
  public async saveTransferData(data: TransferData): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' saveTransferData error, rdbStore is null');
        return 0;
      }
      let insertData: relationalStore.ValuesBucket = this.getSaveTransferData(data);
      LogUtil.info(TAG + `saveTransferData start.`);
      let count: number = await this.rdbStore.insert(DatabaseConstants.RECOGNIZE_AI_TABLE, insertData);
      this.rdbStore.commit();
      LogUtil.info(TAG + ' saveTransferData success, count is: ' + count);
      return count;
    } catch (error) {
      LogUtil.info(TAG + ` saveTransferData error, code: ${error?.code} , message: ${error?.message}`);
      return 0;
    }
  }

  getSaveTransferData(data: TransferData) {
    let insertData: relationalStore.ValuesBucket = {
      'id': data.id,
      'session_id': data.sessionId,
      'record_path': data.recordPath,
      'file_uri': data.fileUri,
      'domain': data.domain,
      'create_time': data.createTime,
      'state': data.state,
      'json_path': data.jsonPath,
      'source_type': data.sourceType,
      'summary_text': data.summaryText,
      'incomplete': data.incomplete,
    }
    return insertData;
  }

  getUpdateTransferData(data: TransferData) {
    let insertData: relationalStore.ValuesBucket = {
      'session_id': data.sessionId,
      'domain': data.domain,
      'state': data.state,
      'json_path': data.jsonPath,
      'summary_text': data.summaryText,
      'file_size': data.fileSize
    }
    return insertData;
  }

  public async updateTransferData(data: TransferData): Promise<number> {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateTransferData error, rdbStore is null');
        return 0;
      }
      let insertData: relationalStore.ValuesBucket = this.getUpdateTransferData(data);
      this.rdbStore.beginTransaction();
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      if (data.recordPath) {
        predicates.equalTo('id', data.id);
      } else {
        return 0;
      }
      LogUtil.info(TAG + `updateTransferData start.`)
      let count: number = await this.rdbStore.update(insertData, predicates);
      this.rdbStore.commit();
      LogUtil.info(TAG + `updateTransferData success.count:${count}`);
      return count;
    } catch (err) {
      LogUtil.info(TAG + ` updateTransferData error, code: ${err?.code}, message: ${err?.message}`);
      return 0;
    }
  }

  /**
   * 删除指定录音文件下的转写数据
   *
   */
  public async removeTransferData(recordPaths: string[]): Promise<void> {
    LogUtil.info(TAG + ' removeTransferData length: ' + recordPaths.length);
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' removeTransferData error, rdbStore is null');
        return;
      }
      if (recordPaths.length === 0) {
        LogUtil.error(TAG + ' removeTransferData error, recordPaths count is 0');
        return;
      }
      let predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.in('record_path', recordPaths);
      let count = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG + ' removeTransferData successfully, count: ' + count);
    } catch (error) {
      LogUtil.info(TAG + ' removeTransferData failed: ' + error);
    }
  }

  public async updateTransDateDatabase(oldPath: string, row: relationalStore.ValuesBucket) {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateTransDateRecordPath error, rdbStore is null');
        return;
      }
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.equalTo('record_path', oldPath);
      let count = await this.rdbStore.update(row, predicates);
      LogUtil.info(TAG + ' updateTransDateRecordPath success count: ' + count);
    } catch (error) {
      LogUtil.error(TAG + ' updateTransDateRecordPath failed: ' + error);
      if (error.code === DATABASE_CORRUPTED_ERR) {
        this.restoreType = OperationType.OPERATION_MODIFY;
        await this.databaseRestore();
        const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
        predicates.equalTo('_data', oldPath);
        let count = await this.rdbStore?.update(row, predicates);
        LogUtil.info(TAG + ' restore updateTransDateRecordPath success count: ' + count);
      }
    }
  }

  public async updateTransferDateWithId(id: string, row: relationalStore.ValuesBucket) {
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateTransferDateWithId error, rdbStore is null');
        return;
      }
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.equalTo('id', id);
      let count = await this.rdbStore.update(row, predicates);
      LogUtil.info(TAG + ' updateTransferDateWithId success count: ' + count);
    } catch (err) {
      LogUtil.error(TAG + ` updateTransferDateWithId failed, code: ${err.code}, message: ${err.message}`);
    }
  }

  public async getTransStatus(recordPath: string) {
    let status: number = -1;
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' getTransStatus error, rdbStore is null');
        return status;
      }
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.equalTo('record_path', recordPath);
      let resultSet = await this.rdbStore.query(predicates);
      if (resultSet.goToRow(0)) {
        status = resultSet.getLong(resultSet.getColumnIndex('state')) as number;
      }
      resultSet.close();
      LogUtil.info(TAG + ' getTransStatus status ' + status);
      return status;
    } catch (err) {
      LogUtil.error(TAG + ` getTransStatus failed, code: ${err?.code}, message: ${err?.message}`);
      return status;
    }
  }

  public async getTransId(recordPath: string) {
    let transId: string = '';
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' getTransId error, rdbStore is null');
        return transId;
      }
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.equalTo('record_path', recordPath);
      let resultSet = await this.rdbStore.query(predicates);
      LogUtil.info(TAG + ` resultSet : ${resultSet.columnCount}`);
      if (resultSet.goToRow(0)) {
        transId = resultSet.getString(resultSet.getColumnIndex('id')) as string;
      }
      resultSet.close();
      LogUtil.info(TAG + ' getTransId id : ' + transId);
      return transId;
    } catch (err) {
      LogUtil.error(TAG + ` getTransId failed, code: ${err?.code}, message: ${err?.message}`);
      return transId;
    }
  }

  public deleteAudioFile(files: string[], callback: Callback<void>): void {
    const task = new taskpool.Task('DELETE_FILE', deleteFileTask, files);
    taskpool.execute(task).then((res) => {
      LogUtil.info(TAG + ' deleteAudioFile success: ' + res + ' delete file count: ' + files.length);
      callback();
    }).catch((error: Error) => {
      LogUtil.info(TAG + ' deleteAudioFile error: ' + error.message);
    });
  }

  // 更新当前联系人记录的通话记录个数
  public async updateCallRecordNameIndex(contact: string, count: number): Promise<void> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' updateCallRecordNameIndex error, rdbStore is null');
        return;
      }
      let predicates = new relationalStore.RdbPredicates('call_record_index_table').equalTo('contact', contact);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet.columnCount === 0) {
        await this.rdbStore.insert('call_record_index_table', { 'contact': contact, 'count': count });
      } else {
        await this.rdbStore.update({ 'count': count }, predicates);
      }
      LogUtil.info(TAG + ' updateCallRecordNameIndex success');
    } catch (error) {
      LogUtil.info(TAG + ' updateCallRecordNameIndex failed: ' + error);
    } finally {
      resultSet?.close();
    }
  }

  // 查询每个联系人的通话记录个数
  public async queryCallRecordCountGroupByContact(): Promise<Map<string, number>> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    let result: Map<string, number> = new Map();
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ' queryCallRecordCountGroupByContact error, rdbStore is null');
        return result;
      }
      let predicates = new relationalStore.RdbPredicates('call_record_index_table');
      resultSet = await this.rdbStore.query(predicates);
      while (resultSet.goToNextRow()) {
        let row = resultSet.getRow();
        result.set(row['contact'] as string, row['count'] as number);
      }
      LogUtil.info(TAG + ' queryCallRecordCountGroupByContact count: ' + result.size);
      return result;
    } catch (error) {
      LogUtil.error(TAG + ' queryCallRecordCountGroupByContact failed: ' + error);
      return result;
    } finally {
      resultSet?.close();
    }
  }

  // 插入到最近删除表中
  public async insertToRecentDeleteTable(items: RecordData[], type: RecordType): Promise<number> {
    LogUtil.info(TAG + ' insertToRecentDeleteTable, count: ' + items.length);
    let rows: ValuesBucket[] = items.map(item => {
      let deleteTime = Date.now();
      item.deleteTime = deleteTime;
      return {
        'id': item.date,
        // 通话录音的文件名item.name是经过特殊处理的，移动到回收站的时候需要保存，普通录音的文件名直接保存item.title即可
        'title': item.phoneNumber ? item.name : item.title, // 文件名
        '_data': item._data,
        'date_added': item.date, // 创建时间
        'file_size': item.size,
        'duration': item.duration, // 录制时长
        'phone_number': item.phoneNumber || '',
        'delete_time': deleteTime, // 删除时间
        'location': item.location,
        'record_mode': item.recordMode,
        'speech_text': item.speechText,
        'angle_path': item.anglePath,
        'is_file_uploaded': item.isFileUploaded,
        'transfer_voice': item.transferVoice,
        'is_support_session_calibration': item.isSupportSessionCalibration,
        'voiceList': item.voiceList,
        'type': type
      } as ValuesBucket
    })
    return await this.saveRecentDeleteRecord(rows);
  }

  // 插入到录音表中
  public async insertToNormalRecordTable(items: RecordData[]): Promise<number> {
    LogUtil.info(TAG + ' insertToNormalRecordTable, count: ' + items.length);
    let rows: ValuesBucket[] = items.map(item => {
      return {
        'id': item.phoneNumber ? item.id : item.date,
        'title': item.phoneNumber ? item.name : item.title, // 文件名
        '_data': item._data,
        'date_added': item.date, // 创建时间
        'file_size': item.size,
        'duration': item.duration, // 录制时长
        'phone_number': item.phoneNumber || '',
        'delete_time': item.deleteTime, // 删除时间
        'location': item.location,
        'record_mode': item.recordMode,
        'speech_text': item.speechText,
        'angle_path': item.anglePath,
        'is_file_uploaded': item.isFileUploaded,
        'transfer_voice': item.transferVoice,
        'is_support_session_calibration': item.isSupportSessionCalibration,
        'voiceList': item.voiceList
      } as ValuesBucket
    })
    LogUtil.info(TAG + ' insertToNormalRecordTable, data length: ' + rows.length);
    return await this.saveRecord(rows);
  }

  // 查询是否有卡片数据
  public async queryHasFormData(): Promise<boolean> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ` queryHasFormData rdbStore is undefined`);
        return false;
      }
      const predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(FA_FORM_TABLE);
      // 只查询一条数据即可
      predicates.limitAs(1);
      resultSet = await this.rdbStore.query(predicates, [FADbProperties.FORM_ID]);
      LogUtil.info(TAG + ' queryHasFormData, data length: ' + resultSet.rowCount);
      return resultSet.rowCount === 1;
    } catch (error) {
      LogUtil.info(TAG + ' queryHasFormData failed: ' + error);
      return false;
    } finally {
      resultSet?.close();
    }
  }

  public async queryTransferDataWithRecords(recordPaths: string[]): Promise<TransferData[]> {
    const transferData: TransferData[] = [];
    if (!this.rdbStore) {
      return transferData;
    }
    if (!recordPaths || recordPaths.length === 0) {
      return transferData;
    }
    let resultSet: relationalStore.ResultSet | undefined;
    try {
      const predicates = new relationalStore.RdbPredicates(DatabaseConstants.RECOGNIZE_AI_TABLE);
      predicates.in('record_path', recordPaths);
      resultSet = await this.rdbStore.query(predicates);
      LogUtil.info(TAG + ' queryTransferDataWithRecords count' + resultSet.rowCount);
      while (resultSet.goToNextRow()) {
        let item = this.parseTransferData(resultSet);
        transferData.push(item);
      }
      return transferData;
    } catch (err) {
      LogUtil.info(`${TAG} queryTransferDataWithRecords failed, code: ${err.code}, message: ${err.message}`);
    } finally {
      resultSet?.close();
    }
    return transferData;
  }

  private parseTransferData(resultSet: relationalStore.ResultSet): TransferData {
    let item: TransferData = {
      id: resultSet.getString(resultSet.getColumnIndex('id')),
      recordPath: resultSet.getString(resultSet.getColumnIndex('record_path')),
      sessionId: resultSet.getString(resultSet.getColumnIndex('session_id')),
      fileUri: resultSet.getString(resultSet.getColumnIndex('file_uri')),
      domain: resultSet.getString(resultSet.getColumnIndex('domain')),
      state: resultSet.getLong(resultSet.getColumnIndex('state')),
      createTime: resultSet.getLong(resultSet.getColumnIndex('create_time')),
      jsonPath: resultSet.getString(resultSet.getColumnIndex('json_path')),
      sourceType: resultSet.getLong(resultSet.getColumnIndex('source_type')),
      summaryText: resultSet.getString(resultSet.getColumnIndex('summary_text')),
      fileSize: resultSet.getLong(resultSet.getColumnIndex('file_size')),
      incomplete: resultSet.getLong(resultSet.getColumnIndex('incomplete')),
    }
    return item;
  }

  // 判断某个表是否包含某个字段
  /* instrument ignore next */
  async hasFiledInTable(tableName: string, field: string): Promise<boolean> {
    let resultSet: relationalStore.ResultSet | undefined = undefined;
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ` hasFiledInTable rdbStore is undefined`);
        return false;
      }
      const predicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates(tableName);
      predicates.limitAs(1);
      resultSet = await this.rdbStore.query(predicates);
      if (resultSet && resultSet.columnNames) {
        LogUtil.info(TAG + ' hasFiledInTable, data length: ' + resultSet.columnCount);
        return resultSet.columnNames.indexOf(field) > 0;
      }
    } catch (err) {
      LogUtil.info(TAG + ` hasFiledInTable failed: code: ${err?.code}, message: ${err?.message}`);
    } finally {
      resultSet?.close();
    }
    return false;
  }
}

@Concurrent
async function deleteFileTask(files: string[]): Promise<boolean> {
  LogUtil.info(' SoundRecorder_DatabaseManager deleteFileTask begin.');
  let promise: Promise<void>[] = [];
  files.forEach((item) => {
    promise.push(new Promise<void>((resolve, reject) => {
      try {
        fs.unlinkSync(item);
        resolve();
      } catch (e) {
        reject(e);
      }
    }));
  })
  await Promise.all(promise).then(() => {
    LogUtil.info(' SoundRecorder_DatabaseManager deleteFileTask done.');
    return true;
  }).catch((err: Error) => {
    LogUtil.info(' SoundRecorder_DatabaseManager deleteFileTask failed: ' + err.message);
    return false;
  });
  return false;
}

@Concurrent
async function queryWithPredicates(context: common.ApplicationContext, tableName: string, start: number, end: number):
  Promise<sendableRelationalStore.ValuesBucket[]> {
  const STORE_CONFIG: relationalStore.StoreConfig = {
    name: 'recorderSound.db',
    securityLevel: relationalStore.SecurityLevel.S2
  };
  let resultSet: relationalStore.ResultSet | undefined;
  let rdbStore: relationalStore.RdbStore | undefined;
  let values: sendableRelationalStore.ValuesBucket[] = [];
  if (!context) {
    LogUtil.error(' SoundRecorder_DatabaseManager queryWithPredicates failed, context is null.');
    return values;
  }
  try {
    rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
    if (!rdbStore) {
      LogUtil.error(' SoundRecorder_DatabaseManager queryWithPredicates failed, rdbStore is null.');
      return values;
    }
    LogUtil.error(' SoundRecorder_DatabaseManager queryWithPredicates start.');
    let predicates = new relationalStore.RdbPredicates(tableName);
    predicates.offsetAs(start).limitAs(end - start);
    resultSet = await rdbStore.query(predicates);
    while (resultSet.goToNextRow()) {
      values.push(resultSet.getSendableRow());
    }
  } catch (error) {
    LogUtil.error(' SoundRecorder_DatabaseManager queryWithPredicates failed: ' + error);
  } finally {
    resultSet?.close();
    rdbStore?.close();
  }
  return values;
}

@Concurrent
async function queryCallRecordWithPredicates(context: common.ApplicationContext, uri: string,
  start: number, end: number): Promise<SendableRecordData[]> {
  let dataShareHelper: dataShare.DataShareHelper | undefined;
  let resultSet: DataShareResultSet | undefined;
  let result: SendableRecordData[] = [];
  const tag = 'SoundRecorder_DatabaseManager';
  if (!context) {
    LogUtil.error(`${tag} queryCallRecordWithPredicates failed, context is null.`);
    return result;
  }
  try {
    dataShareHelper = await DataShareUtil.getDataShareHelper(context, uri);
    if (!dataShareHelper) {
      LogUtil.error(`${tag} queryCallRecordWithPredicates failed, dataShareHelper is null.`);
      return result;
    }
    LogUtil.info(`${tag} queryCallRecordWithPredicates start.`);
    let predicates = new dataSharePredicates.DataSharePredicates();
    predicates.limit(end - start, start);
    resultSet = await dataShareHelper.query(uri, predicates, []);
    LogUtil.info(`${tag} queryCallRecordWithPredicates query results: ${resultSet.rowCount}`);
    return await ContactsManagerUtil.processResultSet(resultSet);
  } catch (err) {
    LogUtil.error(`${tag} queryCallRecordWithPredicates failed, code: ${err.code}, message: ${err.message}`);
  } finally {
    resultSet?.close();
  }
  return result;
}

export default DatabaseManager.getDataBaseManager();