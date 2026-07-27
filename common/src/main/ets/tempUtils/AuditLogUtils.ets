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
import { fileIo as fs, WriteOptions } from '@kit.CoreFileKit';
import hilog from '@ohos.hilog';
import { zlib } from '@kit.BasicServicesKit';


/**
 * 1、确定写的路径, hap写到共享内存/data/storage/el2/log/audit, sa直接写到 data/log
 * 2、创建 x个log文件, 一个写满, 再写另一个, 依次循环交替写
 * 3、应用写审计日志时, 可能存在1200条/s极限速度, 可以先缓存到某个列表里, 满了后再写到文件里
 * 4、落盘的日志是.csv格式, 内容是按字段写, 以逗号区分, 便于后续的展示
 * 5、限制条件：写到缓存string最大1200条; 一个应用日志限额总默认10M, 2个文件; 每条数据平均200~300字节;
 * 6、文件满后重命名, 然后压缩
 *
 * 文件读写:
 */

/**
 * 增删改操作类型
 */
export enum OperationType {
  OPERATION_DELETE = 'DEL',
  OPERATION_ADD = 'ADD',
  OPERATION_MOVE = 'MOV',
  OPERATION_RENAME = 'RNAME',
  OPERATION_COPY = 'CP'
}

/**
 * 可能原因的类型
 */
export enum CauseType {
  // 用户行为
  USER_BEHAVIOR = 'USER BEHAVIOR',
  // 数据库损坏
  DB_CORRUPTION = 'DB CORRUPTION',
  // 无法读取文件
  FAILED_TO_READ_FILE = 'FAILED TO READ FILE',
  // HWID注销
  HWID_LOGOUT = 'HWID LOGOUT',
  // 无法安装用户帐户
  FAILED_TO_MOUNT_USER_ACCOUNT = 'FAILED TO MOUNT USER ACCOUNT'
}

/**
 * 文件类型, 如音乐/图片/视频等
 */
export enum FileType {
  PICTURE = 'PIC',
  VIDEO = 'VID',
  AUDIO = 'AUD',
  PDF = 'PDF',
  EXE = 'EXE',
  TEXT = 'TXT',
  XLS = 'XLS',
  DOC = 'DOC',
  PPT = 'PPT',
  COMPRESSED = 'ZIP/TAR',
  UNKNOWN = 'UNKNOWN'
}

const TAG = '[Recorder]';
const DOMAIN = 0x0500;

export class AuditLogUtils {
  private static readonly MAX_DISK_LOG_SIZE = 6 * 1024 * 1024; // 一个应用审计日志可存储的最大限额 6M
  private static readonly MAX_SINGLE_FILE_LOG_SIZE = 3 * 1024 * 1024; // 一个日志文件最大限额3M, 存满则进行压缩(约10:1压缩比)
  private static readonly MAX_AUDIT_LOG_SIZE = 2 * 1024; // 一条审计日志最大为 2kb
  private static readonly MAX_LOG_FILE_COUNT = 10; // 落盘日志文件个数, 10个300k约3M
  private static readonly MAX_MEMORY_LOG_COUNT = 1200; // 1200 lines 批量写最大1200条

  private static readonly LOG_PATH_DIR_SANDBOX = '/data/storage/el2/log/audit'; // hap 日志落盘路径
  private static readonly LOG_PATH_DIR_DATA_LOG = '/data/log/hiaudit'; // sa 日志落盘路径

  // 需应用修改
  private static readonly LOG_NAME = 'soundrecorder'; //落盘日志文件名称
  private static readonly LOG_PATH_DIR = AuditLogUtils.LOG_PATH_DIR_SANDBOX; //hap用沙箱, 有system权限的sa直接用/data/log
  private static readonly LOG_FILE_PATH = AuditLogUtils.LOG_PATH_DIR + '/' + AuditLogUtils.LOG_NAME + '_audit.csv';
  private static instance?: AuditLogUtils;
  private static lock = false;

  private constructor() {
    this.mkdirSync(AuditLogUtils.LOG_PATH_DIR);
  }

  /* instrument ignore next */
  public static getInstance(): AuditLogUtils {
    if (!AuditLogUtils.instance) {
      while (AuditLogUtils.lock) {
      }
      AuditLogUtils.lock = true;
      if (!AuditLogUtils.instance) {
        AuditLogUtils.instance = new AuditLogUtils();
      }
      AuditLogUtils.lock = false;
    }
    return AuditLogUtils.instance;
  }

  /**
   * 写单条审计日志
   * @param 字段封装类AuditLog
   * @returns true 为写成功
   */
  /* instrument ignore next */
  public writeAuditEvent(log: AuditLog): boolean {
    if (log == null) {
      hilog.error(DOMAIN, TAG, 'audit log is null.');
      return false;
    }

    let auditLogs: string = '';
    let fileSize: number = this.getFileSize(AuditLogUtils.LOG_FILE_PATH);
    if (fileSize === 0) {
      auditLogs = this.getAuditLogKeys(log); // 写title 字段
    }
    auditLogs += this.getAuditLogValues(log); // 日志转化成文本

    // 如果文件满了, 写不下, 需要另存为1个文件, 清空再写新的
    if (((fileSize + auditLogs.length) >= AuditLogUtils.MAX_SINGLE_FILE_LOG_SIZE)) {
      let time: string = AuditLogUtils.getFormatTime();
      let dstFilePath = AuditLogUtils.LOG_PATH_DIR + '/' + AuditLogUtils.LOG_NAME + '_audit_' + time;
      this.cleanUpLogFilePath(AuditLogUtils.LOG_FILE_PATH, dstFilePath, AuditLogUtils.LOG_PATH_DIR);

      fileSize = 0; // 文件清空, 重建一个
      auditLogs = this.getAuditLogKeys(log) + auditLogs; // 文件满了后, 新写文件需要把title也写上
    }

    let writeLen = this.writeToFile(AuditLogUtils.LOG_FILE_PATH, auditLogs);
    return writeLen > 0;
  }

  /* instrument ignore next */
  private writeToFile(filePath: string, logStr: string): number {
    let writeLen = 0;
    let file: fs.File | null = null;

    try {
      file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let size: number = this.getFileSize(filePath);
      let options: WriteOptions = { offset: size, encoding: 'utf-8' };
      writeLen = fs.writeSync(file.fd, logStr, options);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `writrToFile error: code: ${e?.code} message ${e?.message} `);
    } finally {
      if (file != null) {
        fs.closeSync(file);
      }
    }
    return writeLen;
  }

  /* instrument ignore next */
  private writeToFileStream(filePath: string, logStr: string): number {
    let writeLen = 0;
    let writeStreamSync: fs.Stream | undefined;

    try {
      let size: number = this.getFileSize(filePath);
      let options: WriteOptions = { offset: size, length: logStr.length, encoding: 'utf-8' };
      writeStreamSync = fs.createStreamSync(filePath, 'w+');
      writeLen = writeStreamSync.writeSync(logStr, options);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `writrToFile error: code: ${e?.code} message ${e?.message} `);
    } finally {
      if (writeStreamSync != undefined) {
        writeStreamSync.flushSync();
        writeStreamSync.closeSync();
      }
    }
    return writeLen;
  }

  /**
   * 文件写满, 重命名新文件, 个数达到上限时老化最早的一个文件
   * @param srcFilePath
   * @param dstFilePath
   * @param logFileDir
   */
  /* instrument ignore next */
  private cleanUpLogFilePath(srcFilePath: string, dstFilePath: string, logFileDir: string): void {
    try {
      let tmpFilePath: string = dstFilePath + '.csv';
      // 重命名文件
      fs.renameSync(srcFilePath, tmpFilePath);
      // 异步把已满文件压缩File
      this.zipFile(tmpFilePath, dstFilePath + '.zip').then(
        () => {
          // 压缩完把原来文件删除
          fs.unlink(tmpFilePath);
        }
      );

      let logFileList = this.getFileListByOrder(logFileDir);
      while (logFileList.length >= AuditLogUtils.MAX_LOG_FILE_COUNT) {
        let oldestFile = logFileList.pop();
        fs.unlinkSync(oldestFile);
      }

    } catch (e) {
      hilog.error(DOMAIN, TAG, `renameSync or cleanOldestFile error: ${e?.message}`);
    }
  }

  /* instrument ignore next */
  private mkdirSync(dirPath: string): boolean {
    if (this.isFileExist(dirPath) && this.isDirectory(dirPath)) {
      return true;

    }

    try {
      fs.mkdirSync(dirPath);
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `mkdirSync error: ${e?.message}`);
      return false;
    }
  }

  /* instrument ignore next */
  private isFileExist(filePath: string): boolean {
    let isFileExist: boolean = false;
    try {
      isFileExist = fs.accessSync(filePath);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `file not exist: '${e.code}, ${e.message}`);
    }
    return isFileExist;
  }

  /* instrument ignore next */
  private isFile(filePath: string): boolean {
    let isFile: boolean = false;
    if (this.isFileExist(filePath)) {
      try {
        isFile = fs.statSync(filePath).isFile();
      } catch (e) {
        hilog.error(DOMAIN, TAG, `'isFile error:'${e.code}, ${e.message}`);
      }
    }
    return isFile;
  }

  /* instrument ignore next */
  private isDirectory(filePath: string): boolean {
    let isDir: boolean = false;
    if (this.isFileExist(filePath)) {
      try {
        isDir = fs.statSync(filePath).isDirectory();
      } catch (e) {
        hilog.error(DOMAIN, TAG, `'isDirectory error:'${e.code}, ${e.message}`);
      }
    }
    return isDir;
  }

  /* instrument ignore next */
  private getFileSize(filePath: string): number {
    let size: number = 0;
    try {
      size = fs.statSync(filePath).size;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getFileSize error: ${e.code}, ${e.message}`);
    }
    return size;
  }

  /* instrument ignore next */
  private getFileLastModifyTime(filePath: string): number {
    let time: number = 0;

    try {
      time = fs.statSync(filePath).mtime;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `getFileLastModifyTime error: ${e?.message}`);
    }
    return time;
  }

  /* instrument ignore next */
  private getFilesInDir(dirPath: string, recursive: boolean = false, relativePath: boolean = false): string[] {
    let result: string[] = [];
    if (!this.isDirectory(dirPath)) {
      hilog.info(DOMAIN, TAG, `getFilesInDir not dir`);
      return result;
    }

    let fileList: string[] = [];
    try {
      fileList = fs.listFileSync(dirPath, {
        recursion: recursive
      }).filter(file => this.isFile(`${dirPath}/${file}`));
      if (relativePath) {
        return fileList;
      }
    } catch (e) {
      hilog.info(DOMAIN, TAG, `get files error: ${e.code}, ${e.message}`);
      return result;
    }

    for (let fileName of fileList) {
      let filePath = `${dirPath}/${fileName}`;
      result.push(filePath);
    }

    return result;
  }

  /* instrument ignore next */
  private getFileListByOrder(dirPath: string): string[] {
    let fileList: string[] =
      this.getFilesInDir(dirPath).filter((logPath) => logPath.includes('_audit_') && logPath.includes('.zip'));
    if (fileList.length > 1) {
      fileList.sort((file1, file2) => this.getFileLastModifyTime(file2) - this.getFileLastModifyTime(file1));
    }
    return fileList;
  }

  /**
   * 将日志内容由 AuditLog封装类转换成以逗号相隔的字符串
   * @param obj
   * @returns
   */
  /* instrument ignore next */
  private getAuditLogValues(obj: AuditLog): string {
    let auditLog = Object.values(obj).join(', ') + '\n';
    if (auditLog.length >= AuditLogUtils.MAX_AUDIT_LOG_SIZE) {
      // 单条日志大于2kb则截断
      auditLog = auditLog.substring(0, AuditLogUtils.MAX_AUDIT_LOG_SIZE) + '\n';
      hilog.error(DOMAIN, TAG, 'The log size exceeds 2 KB, length: ' + auditLog.length);
    }
    return auditLog;
  }

  /**
   * 日志文件首行title字段
   * @param obj
   * @returns
   */
  /* instrument ignore next */
  private getAuditLogKeys(obj: AuditLog): string {
    return Object.keys(obj).join(', ') + '\n';
  }

  /* instrument ignore next */
  private async zipFile(srcPath: string, zipPath: string): Promise<boolean> {
    if (!this.isFileExist(srcPath)) {
      return false;
    }
    let options: zlib.Options = {
      level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
      memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
      strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
    };

    try {
      let errData = await zlib.compressFile(srcPath, zipPath, options);
      if (errData != null) {
        hilog.error(DOMAIN, TAG, ` zip file error: ${JSON.stringify(errData)}`);
        return false;
      }
      hilog.info(DOMAIN, TAG, ` zip file success`);
      return true;
    } catch (errData) {
      hilog.error(DOMAIN, TAG, ` errData is errCode:${errData.code}  message:${errData.message}`);
    }
    return false;
  }

  /**
   * 格式化时间 from yyyy-MM-dd HH:mm:ss:SSS to yyyyMMddHHmmssSSS
   * @returns
   */
  /* instrument ignore next */
  public static getFormatTime(): string {
    const date = new Date();
    const year = date.getFullYear();
    const month = (date.getMonth() + 1).toString().padStart(2, '0');
    const day = date.getDate().toString().padStart(2, '0');
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    const seconds = date.getSeconds().toString().padStart(2, '0');
    const milliseconds = date.getMilliseconds().toString().padStart(3, '0');

    return `${year}${month}${day}${hours}${minutes}${seconds}${milliseconds}`;
  }
}

/**
 * 日志字段封装类
 */
export interface AuditLog {
  // 发生时间
  happenTime: string;

  // 应用名称
  packageName: string;

  // 应用在前台还是后台
  isForeground: boolean;

  // 是否用户行为（界面操作产生的属于用户行为）
  isUserBehavior: boolean;

  // 可能原因
  cause: string;

  // 操作类型（增删改等）
  operationType: string;

  // 操作场景（克隆/恢复/云同步等）
  operationScenario: string;

  // 操作数量（如删除数量）
  operationCount: number;

  // 操作状态（成功/失败）
  operationStatus: string;

  // 	扩展内容
  extend: string;
}

/**
 * 实体文件日志字段封装类
 */
export interface DeleteFileAuditLog extends AuditLog {
  deleteType: string;
  deleteCount: string;
  fileTargetPath: string;
  fileName: string;
  fileCreateTime: string;
  fileSize: number;
}

export interface RecordAuditLog extends AuditLog {
  successCount?: number;
  failCount?: number;
  duplicateCount?: number
}

/**
 * 实体文件日志字段封装类
 */
export interface FileAuditLog extends AuditLog {
  fileType: string;
  filePath: string;
  fileTargetPath: string;
  fileName: string;
  fileCreateTime: string;
  fileSize: number;
}

/**
 * 数据库数据等日志字段封装类
 */
export interface DataAuditLog extends AuditLog {
  dbStatus: string;
  hwidStatus: string;
}