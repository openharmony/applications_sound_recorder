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

import {
  AnonymousUtil,
  DatabaseManager,
  FileUtil,
  GlobalContext,
  Helps,
  LazyDataSource,
  LogUtil,
  PathChanger,
  PathUtil,
  Preferences,
  PreferencesUtil,
  Props,
  RecordData,
  RecordDataGroupArray,
  RecordType,
  SendableRecordData,
  SystemUtil
} from '@ohos/common';
import SortType, { SortConstants } from '@ohos/common/src/main/ets/constants/DataSortType';
import { CallRecordDbManager, RecordDbManager } from '@ohos/databaseManager';
import FileWatcherEvent from '../event/FileWatcherEvent';
import CallRecordWatcher from '../watcher/CallRecordWatcher';
import RecordWatcher from '../watcher/RecordWatcher';
import { taskpool } from '@kit.ArkTS';

const TAG = 'SoundRecorder_FileManager';
const BATCH_SIZE: number = 2000;
const SCAN_RESULT_LENGTH: number = 2;
const CALL_RECORD_GROUP_ID: string = 'group.1435681907172981696';

interface OwnerResult {
  readonly recordData?: RecordData;
  readonly list?: LazyDataSource<RecordData>;
}

class FileManager {
  private static instance?: FileManager;
  public onCallRecordDirRemoved = Helps.debounce(async () => {
    LogUtil.info(`${TAG} CallRecord dir removed.`);
    await CallRecordDbManager.clearRecord();
    await this.clearRecognizeAiByDirPath(PathUtil.CALLRECORD_FILEPATH);
    await RecordDbManager.clearTagsByDirPath(PathUtil.CALLRECORD_FILEPATH);
    this.clearCallRecordUIList();
    FileWatcherEvent.updateGroupListCount();
    FileUtil.checkCallRecordFileDir();
  });
  private recordDataGroup?: RecordDataGroupArray;
  private recordingFilepath: string = '';

  private constructor() {
  }

  public static getInstance(): FileManager {
    if (!FileManager.instance) {
      FileManager.instance = new FileManager();
    }
    return FileManager.instance;
  }

  public setRecordingFilepath(path: string): void {
    this.recordingFilepath = path;
  }

  public init(recordDataGroup?: RecordDataGroupArray) {
    this.recordDataGroup = recordDataGroup;
  }

  public track(): void {
    if (FileUtil.checkUserFileDir()) {
      LogUtil.info(`${TAG} Sounds path ready.`);
      RecordWatcher.start();
    }
    if (SystemUtil.HAS_VOICE_CAPABILITY && FileUtil.checkCallRecordFileDir()) {
      LogUtil.info(`${TAG} CallRecord path ready.`);
      CallRecordWatcher.start();
    }
  }

  public unTrack(): void {
    RecordWatcher.stop();
    CallRecordWatcher.stop();
  }

  public async insertRecord(path: string): Promise<void> {
    if (!FileUtil.exists(path)) {
      return;
    }
    const pathChanger = AppStorage.get<PathChanger>(Props.PATH_CHANGER);
    if (pathChanger?.newPath === path) {
      return;
    }
    if (await RecordDbManager.hasRecord(path)) {
      return;
    }
    const recordData = await this.pathAsRecord(path);
    if (recordData.duration === 0) {
      return;
    }
    recordData.type = RecordType.AUDIO_RECORD;

    LogUtil.info(`${TAG} insert record.`);
    await RecordDbManager.insertNormalRecords([recordData]);
    const result = this.getOwnerResult(path);
    const record = result.recordData;
    if (!record) {
      this.recordDataGroup?.normalRecordList.addItem(recordData);
      this.recordDataGroup?.allRecordList.addItem(recordData);
      FileWatcherEvent.updateGroupListCount();
    }
  }

  public async removeRecord(path: string): Promise<void> {
    LogUtil.info(`${TAG} remove record.`);
    this.removeRecordFromUIList(path);
    await this.removeRecognizeAiResultFile(path);
    await this.removeRecordsFromDb(path);
    FileWatcherEvent.updateGroupListCount();
  }

  public async updateRecord(oldPath: string, newPath: string): Promise<void> {
    LogUtil.info(`${TAG} update record.`);
    this.refreshUIList(oldPath, newPath);
    await this.updateRecognizeAiResultFile(oldPath, newPath);
    await RecordDbManager.updateRecordToTables(oldPath, newPath);
  }

  public async updateRecognizeAi(oldPath: string, newPath: string): Promise<void> {
    await this.updateRecognizeAiResultFile(oldPath, newPath);
    await RecordDbManager.updateRecordToRecognizeAi(oldPath, newPath);
  }

  public getOwnerResult(filepath: string): OwnerResult {
    if (!this.recordDataGroup) {
      return {};
    }

    let list = this.recordDataGroup.normalRecordList;
    let recordData = list.getAll().find(item => item._data === filepath);
    if (recordData) {
      return { recordData, list };
    }

    list = this.recordDataGroup.recentDeleteList;
    recordData = list.getAll().find(item => item._data === filepath);
    if (recordData) {
      return { recordData, list };
    }

    list = this.recordDataGroup.callRecordList;
    recordData = list.getAll().find(item => item._data === filepath);
    if (recordData) {
      return { recordData, list };
    }

    if (filepath.startsWith(PathUtil.HEADSETRECORD_FILEPATH)) {
      let list = this.recordDataGroup.headsetRecordList;
      let recordData = list.getAll().find(item => item._data === filepath);
      if (recordData) {
        return { recordData, list };
      }
    }

    return {};
  }

  public async removeCallRecord(path: string): Promise<void> {
    LogUtil.info(`${TAG} remove call record.`);
    this.removeRecordFromUIList(path);
    await CallRecordDbManager.deleteRecords([path]);
    this.removeRecordRelatedTables([path]);
    FileWatcherEvent.updateGroupListCount();
  }

  public async insertCallRecord(path: string): Promise<void> {
    if (!FileUtil.exists(path)) {
      return;
    }
    if (await CallRecordDbManager.hasRecord(path)) {
      return;
    }
    const recordData = await this.pathAsCallRecord(path);
    if (recordData.duration === 0) {
      return;
    }

    LogUtil.info(`${TAG} insert call record.`);
    await CallRecordDbManager.insertRecords([recordData]);
    const result = this.getOwnerResult(path);
    const record = result.recordData;
    if (!record) {
      this.recordDataGroup?.callRecordList.addItem(recordData);
      this.recordDataGroup?.allRecordList.addItem(recordData);
      FileWatcherEvent.updateGroupListCount();
    }
  }

  public async updateCallRecord(oldPath: string, newPath: string): Promise<void> {
    this.refreshUIList(oldPath, newPath);
    await CallRecordDbManager.updateRecord(oldPath, newPath);
    await this.updateRecognizeAi(oldPath, newPath);
    await RecordDbManager.updateCallRecordRecordToTables(oldPath, newPath);
    // 此处更新下title字段，确保重命名后通话录音命名不出问题
    const lastSlashIndex = newPath.lastIndexOf('/'); // 传入方确保路径正确性/
    await DatabaseManager.getCallRecordDataFromDb('title', newPath.substring(lastSlashIndex + 1));
  }

  public refreshUIList(oldPath: string, newPath: string): void {
    if (!oldPath || !newPath) {
      LogUtil.error(`${TAG} old path or new path, invalid.`);
      return;
    }

    const result = this.getOwnerResult(oldPath);
    const record = result.recordData;
    if (record) {
      record.name = PathUtil.basename(newPath);
      record.title = PathUtil.filename(newPath);
      record._data = newPath;
    }

    // 刷新全部录音页签
    const recordData = this.recordDataGroup?.allRecordList.getAll().find(item => item._data === oldPath);
    if (recordData) {
      recordData.name = PathUtil.basename(newPath);
      recordData.title = PathUtil.filename(newPath);
      recordData._data = newPath;
    }
  }

  // 检查沙箱和文管中的文件是否是同一个录音，通过SHA256值比较
  private async isSandboxAndFileManageFileEqual(sandboxPath: string, fileManagePath: string):
    Promise<boolean> {
    if (!FileUtil.exists(sandboxPath)) {
      LogUtil.error(`${TAG} checkSandboxAndFileManageSameAudioFile, sandbox file is not exists`);
      return false;
    }

    if (!FileUtil.exists(fileManagePath)) {
      LogUtil.error(`${TAG} checkSandboxAndFileManageSameAudioFile, file manage file is not exists`);
      return false;
    }

    return FileUtil.isFileHashesEqual(sandboxPath, fileManagePath);
  }

  /**
   * 扫描沙箱
   */
  public async scanSandboxFileDir(targetRecords: RecordData[]): Promise<RecordData[]> {
    LogUtil.info(`${TAG} scan sandbox, target records: ${targetRecords.length}`);

    const invalidPaths: string[] = this.deleteInvalidRecord(targetRecords);
    if (invalidPaths.length > 0) {
      await RecordDbManager.deleteNormalOrRecentDeletedRecords(invalidPaths);
      await RecordDbManager.deleteRecordsFromRecognizeAi(invalidPaths);
      LogUtil.info(`${TAG} invalid sandbox-records: ${invalidPaths.length}`);
    }

    const sandboxFilepath = PathUtil.SANDBOX_FILEPATH;
    let paths = await FileUtil.scanAudioAs(sandboxFilepath);
    if (paths.length === 0) {
      return [];
    }

    const targetFiles =
      new Set(targetRecords.filter(record => record._data.startsWith(sandboxFilepath)).map(record => record._data));

    paths = paths.filter(path => !targetFiles.has(path) && path !== this.recordingFilepath);

    if (paths.length === 0) {
      return [];
    }

    LogUtil.info(`${TAG} sandbox no-db records: ${paths.length}`);
    const resolvedPaths: string[] = [];
    const destDir = PathUtil.USER_FILEPATH;
    for (const originPath of paths) {
      const filename = PathUtil.filename(originPath);

      // 对于沙箱中没有录入db的录音文件，如果在文管中存在同名文件，且SHA256值相同，此处则不处理。
      const fileManageFile = destDir + '/' + filename;
      const isSame = await this.isSandboxAndFileManageFileEqual(originPath, fileManageFile);
      if (isSame) {
        LogUtil.info(`${TAG} sandbox file and file manage file is same, continue`);
        continue;
      }

      const newFileName = await FileUtil.getFreeNewFilename(filename, destDir);
      const newPath = `${destDir}/${newFileName}`;
      const ok = await FileUtil.moveFile(originPath, newPath);
      if (!ok) {
        resolvedPaths.push(originPath);
        LogUtil.error(`${TAG} can't move file from sandbox to user file dir`);
      } else {
        resolvedPaths.push(newPath);
      }
    }

    const records = await this.pathsAsRecords(resolvedPaths);
    await RecordDbManager.insertNormalRecords(records);
    return records;
  }

  /**
   * 扫描UserFile目录
   */
  public async scanUserFileDir(...groupRecords: RecordData[][]): Promise<RecordData[]> {
    const targetRecords = groupRecords.flat();
    LogUtil.info(`${TAG} scan user file dir, target records: ${targetRecords.length}`);

    let result = await Promise.all([
      FileUtil.scanAudioAs(PathUtil.USER_FILEPATH),
      FileUtil.scanAudioAs(PathUtil.SANDBOX_FILEPATH)
    ]);
    if (!Array.isArray(result) || result.length !== SCAN_RESULT_LENGTH) {
      return [];
    }
    let paths = result[0];
    let sandboxPaths = result[1];
    const filePaths = new Set(paths.concat(sandboxPaths));
    const invalidPaths: string[] = groupRecords.map(records => this.getInvalidPaths(records, filePaths)).flat();
    if (invalidPaths.length > 0) {
      for (let i = 0; i < invalidPaths.length; i += BATCH_SIZE) {
        try {
          const batchPaths: string[] = invalidPaths.slice(i, i + BATCH_SIZE);
          await RecordDbManager.deleteNormalOrRecentDeletedRecords(batchPaths);
          await RecordDbManager.deleteRecordsFromRecognizeAi(batchPaths);
        } catch (e) {
          LogUtil.error(`${TAG} failed to deleteNormalOrRecentDeletedRecords, code: ${e.code}, message: ${e.message}`);
        }
      }
      groupRecords.forEach(records => {
        this.deleteInvalidTargetRecords(records, filePaths)
      });
      LogUtil.info(`${TAG} total invalid records: ${invalidPaths.length}`);
    }

    if (paths.length === 0) {
      return [];
    }

    const targetFiles = new Set(targetRecords.filter(record => record._data.startsWith(PathUtil.USER_FILEPATH))
      .map(record => record._data));
    paths = paths.filter(path => !targetFiles.has(path));

    if (paths.length === 0) {
      return [];
    }

    LogUtil.info(`${TAG} user file dir, no-db records: ${paths.length}`);
    const records = await this.pathsAsRecords(paths);
    await RecordDbManager.insertNormalRecords(records);

    // 添加普通录音标记
    for (let i = 0; i < records.length; i++) {
      records[i].type = RecordType.AUDIO_RECORD;
    }

    return records;
  }

  /**
   * 扫描CallRecord目录
   */
  public async scanCallRecordFileDir(targetRecords: RecordData[]): Promise<RecordData[]> {
    LogUtil.info(`${TAG} scan call-record file dir, target records: ${targetRecords.length}`);

    let pathPrefix = await GlobalContext.getUIAbilityContext().getGroupDir(CALL_RECORD_GROUP_ID);
    let sandboxPaths = `${pathPrefix}/CallRecord`;
    let result = await Promise.all([
      FileUtil.scanAudioAs(PathUtil.CALLRECORD_FILEPATH),
      FileUtil.scanAudioAs(sandboxPaths)
    ]);
    if (!Array.isArray(result) || result.length !== SCAN_RESULT_LENGTH) {
      return [];
    }
    let paths = result[0];
    let callRecordPaths = result[1];
    const pathFiles = new Set(paths.concat(callRecordPaths));
    const invalidPaths: string[] = this.getInvalidPaths(targetRecords, pathFiles);
    if (invalidPaths.length > 0) {
      for (let i = 0; i < invalidPaths.length; i += BATCH_SIZE) {
        try {
          const batchPaths: string[] = invalidPaths.slice(i, i + BATCH_SIZE);
          await CallRecordDbManager.deleteRecords(batchPaths);
          await RecordDbManager.deleteRecordsFromRecognizeAi(batchPaths);
        } catch (e) {
          LogUtil.error(`${TAG} failed to deleteRecords, code: ${e.code}, message: ${e.message}`);
        }
      }
      this.deleteInvalidTargetRecords(targetRecords, pathFiles);
      LogUtil.info(`${TAG} invalid call-records: ${invalidPaths.length}`);
    }

    if (paths.length === 0) {
      return [];
    }

    const targetFiles = new Set(targetRecords.filter(record => record._data.startsWith(PathUtil.CALLRECORD_FILEPATH))
      .map(record => record._data));
    paths = paths.filter(path => !targetFiles.has(path));

    if (paths.length === 0) {
      return [];
    }

    LogUtil.info(`${TAG} call-record dir, no-db records: ${paths.length}`);
    const records = await this.pathsAsCallRecords(paths);
    await CallRecordDbManager.insertRecords(records);

    // 添加通话录音标记
    for (let i = 0; i < records.length; i++) {
      records[i].type = RecordType.CALL_RECORD;
    }

    return records;
  }

  private deleteInvalidRecord(targetRecords: RecordData[]): string[] {
    const invalidPaths: string[] = [];
    for (let i = targetRecords.length - 1; i >= 0; i--) {
      const path = targetRecords[i]._data;
      if (!FileUtil.exists(path)) {
        targetRecords.splice(i, 1);
        invalidPaths.push(path);
      }
    }
    return invalidPaths;
  }

  private getInvalidPaths(targetRecords: RecordData[], filePaths: Set<string>): string[] {
    const invalidPaths: string[] = Array.from(targetRecords.filter(record => !filePaths.has(record._data))
      .map(invalidRecord => invalidRecord._data).values());
    return invalidPaths;
  }

  private deleteInvalidTargetRecords(targetRecords: RecordData[], filePaths: Set<string>) {
    const validRecords = targetRecords.filter(record => filePaths.has(record._data));
    targetRecords.length = 0;
    targetRecords.push(...validRecords);
  }

  private clearSpecificTypeRecordInAllRecordUIList(specificType: RecordType) {
    if (this.recordDataGroup === undefined) {
      LogUtil.error(`${TAG} this.recordDataGroup is undefined`);
      return;
    }
    let removeRecords: RecordData[] = [];
    for (let i = 0; i < this.recordDataGroup.allRecordList.totalCount(); i++) {
      const item = this.recordDataGroup.allRecordList.getData(i);
      const recordType = item.type;
      if (recordType === specificType) {
        removeRecords.push(item);
      }
    }
    for (let i = 0; i < removeRecords.length; i++) {
      const item = removeRecords[i];
      this.recordDataGroup?.allRecordList.deleteItem(item);
    }
  }

  private clearCallRecordUIList(): void {
    this.recordDataGroup?.callRecordList.deleteAll();
    this.clearSpecificTypeRecordInAllRecordUIList(RecordType.CALL_RECORD);
  }

  private async clearRecognizeAiByDirPath(dirPath: string): Promise<void> {
    const rows = await RecordDbManager.queryRecognizeAiRecordsByDirPath(dirPath);
    rows.forEach(row => FileUtil.removeFile(row.json_path as string));
    await RecordDbManager.clearRecognizeAiRecordsByDirPath(dirPath);
  }

  private async updateRecognizeAiResultFile(originRecordPath: string, newRecordPath: string): Promise<void> {
    const rows = await RecordDbManager.queryRecognizeAiRecords(originRecordPath);
    const tasks = rows.map(async row => {
      const originJsonPath = row.json_path as string;
      if (!FileUtil.exists(originJsonPath)) {
        await RecordDbManager.deleteRecordsFromRecognizeAi([originRecordPath]);
        return;
      }
      const originRecordBasename = PathUtil.basename(originRecordPath);
      const newRecordBasename = PathUtil.basename(newRecordPath);
      if (originRecordBasename === newRecordBasename) {
        return;
      }
      const jsonExt = PathUtil.extname(originJsonPath);
      const newJsonPath = `${PathUtil.dirname(originJsonPath)}/${newRecordBasename}${jsonExt}`;
      if (!FileUtil.rename(originJsonPath, newJsonPath)) {
        LogUtil.error(`${TAG} failed to rename json-path file.`);
        return;
      }
      await RecordDbManager.updateRecognizeAiJsonPath(originJsonPath, newJsonPath);
    });
    await Promise.allSettled(tasks);
  }

  private removeRecordFromUIList(path: string): void {
    const result = this.getOwnerResult(path);
    if (result.recordData && result.list) {
      result.list.deleteItem(result.recordData);
      this.recordDataGroup?.allRecordList.deleteItem(result.recordData);
    }
  }

  /**
   * 删除转文本结果文件
   * @param recordPath
   */
  private async removeRecognizeAiResultFile(recordPath: string): Promise<void> {
    LogUtil.info(`${TAG} remove recognize-ai result file.`);
    const rows = await RecordDbManager.queryRecognizeAiRecords(recordPath);
    rows.forEach(row => FileUtil.removeFile(row.json_path as string));
  }

  private async removeRecordsFromDb(path: string): Promise<void> {
    LogUtil.info(`${TAG} remove records from db.`);
    await RecordDbManager.deleteRecordFromTables(path);
  }

  private async insertNewRecord(dataSource: LazyDataSource<RecordData>, newRecordData: RecordData) {
    let maxIndex: number = -1;
    dataSource.forEach(record => {
      if (record.index > maxIndex) {
        maxIndex = record.index;
      }
    });
    newRecordData.index = maxIndex + 1;
    if (dataSource) {
      dataSource.pushItem(newRecordData);
    }
  }

  //批量删除周边数据
  private removeRecordRelatedTables(paths: string[]): void {
    LogUtil.info(`${TAG} removeRecordRelatedTables.`);
    DatabaseManager.removeTransferData(paths);
    DatabaseManager.batchRemoveTag(paths);
    DatabaseManager.removeRecentDeleteRecordData(paths);
  }

  public async onCallRecordRename(oldPath: string, newPath: string): Promise<void> {
    await this.updateCallRecord(oldPath, newPath);
    return;
  }

  // 克隆时旧机将文管中的录音文件拷贝到了沙箱，这里进行清理
  public async cleanSandboxFileDir(
    fileName: string,
    sandboxAudios: string[],
    ...groupRecords: RecordData[][]
  ): Promise<void> {
    try {
      const context = GlobalContext.getUIAbilityContext();
      const dbDir = context.databaseDir + '/rdb/';
      const backupDBName = dbDir + 'recorderSoundBk.db';
      if (!FileUtil.exists(backupDBName)) {
        return;
      }

      const filesDir = context.filesDir;
      const targetRecords = groupRecords.flat();
      LogUtil.info(`${TAG} cleanSandboxFileDir scan user file dir, target records: ${targetRecords.length}`);
      const targetFiles = new Set(targetRecords.map(record => record._data));
      let task: taskpool.Task =
        new taskpool.Task(cleanSandboxFileDir, TAG, fileName, sandboxAudios, filesDir, dbDir, targetFiles);
      taskpool.execute(task);
    } catch (e) {
      LogUtil.error(`${TAG} failed to cleanSandboxFileDir, code: ${e.code}, message: ${e.message}`);
    }
  }

  /**
   * 通过 path 解析出 record
   * @param path
   */
  public async pathAsRecord(path: string): Promise<RecordData> {
    const record = new RecordData();

    const stat = await FileUtil.stat(path);
    const duration = await FileUtil.getDuration(path);
    record.id = stat.inode;
    record.ino = stat.ino;
    record.title = PathUtil.filename(path);
    record.name = PathUtil.basename(path);
    record._data = path;
    record.size = stat.size;
    record.duration = duration;
    record.date = stat.modifyTime;

    return record;
  }

  /**
   * 通过 path 解析出 call record
   * @param path
   */
  public async pathAsCallRecord(path: string): Promise<RecordData> {
    const record = await this.pathAsRecord(path);
    record.phoneNumber = '0';
    record.type = RecordType.CALL_RECORD;
    return record;
  }

  /**
   * 通过 paths 解析出 records
   * @param paths
   */
  public async pathsAsRecords(paths: string[]): Promise<RecordData[]> {
    try {
      const results = await taskpool.execute
      <[string, string[]], Promise<SendableRecordData[]>>(pathsAsRecords, TAG, paths);
      let records: RecordData[] = [];
      for (let result of results) {
        let record: RecordData = new RecordData();
        record.id = result.id;
        record.ino = result.ino;
        record.title = result.title;
        record.name = result.name;
        record._data = result._data;
        record.size = result.size;
        record.duration = result.duration;
        record.date = result.date;
        records.push(record);
      }
      return records;
    } catch (e) {
      LogUtil.error(`${TAG} failed to paths as records, during execute task, code: ${e.code}, message: ${e.message}`);
      return [];
    }
  }

  /**
   * 通过 paths 解析出 call records
   * @param paths
   */
  public async pathsAsCallRecords(paths: string[]): Promise<RecordData[]> {
    const records = await this.pathsAsRecords(paths);

    return records.map(record => {
      record.phoneNumber = '0';
      return record;
    });
  }
}

@Concurrent
async function cleanSandboxFileDir(
  tag: string,
  fileName: string,
  sandboxAudios: string[],
  filesDir: string,
  dbDir: string,
  records: Set<string>
): Promise<void> {
  const newFileNames = sandboxAudios.filter(item => item !== 'fileShare' && !(fileName && item.startsWith(fileName)))
  if (newFileNames.length === 0) {
    return;
  }

  for (let i = 0; i < newFileNames.length; i++) {
    const sandBoxFilePath = filesDir + '/' + newFileNames[i];
    if (records.has(sandBoxFilePath)) {
      continue;
    }
    const fileManagerFilePath = PathUtil.USER_FILEPATH + '/' + newFileNames[i];
    if (!FileUtil.exists(fileManagerFilePath)) {
      continue;
    }
    const result = await FileUtil.isFileHashesEqual(sandBoxFilePath, fileManagerFilePath);
    if (result) {
      LogUtil.error(`${tag} cleanSandboxFileDir, delete sound file: ${AnonymousUtil.anonymous(sandBoxFilePath)}`);
      FileUtil.removeFile(sandBoxFilePath);
    }
  }

  let backupDBFiles: string[] = ['recorderSoundBk.db', 'recorderSoundBk.db-dwr',
    'recorderSoundBk.db-shm', 'recorderSoundBk.db-wal'];
  backupDBFiles = backupDBFiles.map(item => dbDir + item);
  for (let i = 0; i < backupDBFiles.length; i++) {
    LogUtil.error(`${tag} cleanSandboxFileDir, delete db file: ${AnonymousUtil.anonymous(backupDBFiles[i])}`);
    FileUtil.removeFile(backupDBFiles[i]);
  }
}

@Concurrent
async function pathsAsRecords(
  tag: string,
  paths: string[],
): Promise<SendableRecordData[]> {
  const t1 = Date.now();
  const records: SendableRecordData[] = [];

  const results = await Promise.all(paths.map(async (path: string) => {
    const duration = await FileUtil.getDuration(path);
    if (duration === 0) {
      LogUtil.error(`${tag} invalid audio file.`);
      return null;
    }

    const record = new SendableRecordData();
    const stat = await FileUtil.stat(path);
    record.id = stat.inode;
    record.ino = stat.ino;
    record.title = PathUtil.filename(path);
    record.name = PathUtil.basename(path);
    record._data = path;
    record.size = stat.size;
    record.duration = duration;
    record.date = stat.modifyTime;

    return record;
  }));

  for (const record of results) {
    if (record) {
      records.push(record);
    }
  }

  const t2 = Date.now();
  LogUtil.info(`${tag} paths as records, elapsed time: ${t2 - t1}ms, result: ${records.length}`);

  return records;
}

export default FileManager.getInstance();