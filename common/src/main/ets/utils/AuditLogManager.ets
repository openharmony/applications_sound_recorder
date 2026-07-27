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
import { Props } from '../constants/Props';
import { AuditLogUtils, CauseType, OperationType, RecordAuditLog } from './AuditLogUtils';
import { LogUtil } from './LogUtil';


const TAG = 'SoundRecorder_AuditLogManager';

export class AuditLogManager {
  private static instance?: AuditLogManager;
  private static lock = false;

  private constructor() {
    LogUtil.info(TAG + ` set AuditLogManager singleton, create an instance.`);
  }

  /* instrument ignore next */
  public static getInstance(): AuditLogManager {
    if (!AuditLogManager.instance) {
      while (AuditLogManager.lock) {
      }
      AuditLogManager.lock = true;
      if (!AuditLogManager.instance) {
        AuditLogManager.instance = new AuditLogManager();
        AuditLogManager.instance.initAuditLog();
      }
      AuditLogManager.lock = false;
    }
    return AuditLogManager.instance;
  }

  private initAuditLog(): RecordAuditLog {
    const auditLog: RecordAuditLog = {
      happenTime: JSON.stringify(new Date()),
      packageName: 'com.ohos.soundrecorder',
      isForeground: false,
      isUserBehavior: true,
      cause: CauseType.USER_BEHAVIOR,
      operationType: '',
      operationScenario: '',
      operationCount: 0,
      operationStatus: '',
      extend: '',
      successCount: 0,
      failCount: 0,
      duplicateCount: 0
    };
    return auditLog;
  }

  /**
   * 重命名的维测日志
   * @param status 重命名状态
   * @param len 重命名数量，默认为1
   */
  /* instrument ignore next */
  public renameAuditLog(status: string, len?: number) {
    const renameAuditLog = this.initAuditLog();
    renameAuditLog.operationType = OperationType.OPERATION_RENAME;
    renameAuditLog.operationScenario = 'rename';
    renameAuditLog.operationStatus = status;
    renameAuditLog.operationCount = len ?? 1;
    renameAuditLog.isForeground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
    status === 'SUCCESS' ? renameAuditLog.successCount = len ?? 1 : renameAuditLog.failCount = len ?? 1;
    const res = AuditLogUtils.getInstance().writeAuditEvent(renameAuditLog);
    LogUtil.info(TAG + ' AuditLogUtils operation ： ' + res);
  }

  /**
   * 删除文件维测日志
   * @param status 删除状态：成功：success 失败：fail
   * @param deleteFrom 删除来源：左滑、多选、长按、详情页
   * @param len 删除数量，只有多选会多数量，其他默认为1
   */
  /* instrument ignore next */
  public deleteAuditLog(status: string, deleteFrom: string, len?: number) {
    const deleteAuditLog = this.initAuditLog();
    deleteAuditLog.operationType = OperationType.OPERATION_DELETE;
    deleteAuditLog.operationScenario = deleteFrom;
    deleteAuditLog.operationStatus = status;
    deleteAuditLog.operationCount = len ?? 1;
    deleteAuditLog.isForeground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
    status === 'SUCCESS' ? deleteAuditLog.successCount = len ?? 1 : deleteAuditLog.failCount = len ?? 1;
    const res = AuditLogUtils.getInstance().writeAuditEvent(deleteAuditLog);
    LogUtil.info(TAG + ' AuditLogUtils operation ： ' + res);
  }


  /**
   * 克隆升级维测日志
   * @param total 总数
   * @param successCount 成功数量
   * @param failCount  失败数量
   */
  /* instrument ignore next */
  public cloneAuditLog(total: number, successCount: number, failCount: number, duplicateCount?: number) {
    const cloneAuditLog = this.initAuditLog();
    cloneAuditLog.operationType = OperationType.OPERATION_COPY;
    cloneAuditLog.operationScenario = 'clone';
    cloneAuditLog.operationCount = total
    cloneAuditLog.successCount = successCount;
    cloneAuditLog.failCount = failCount;
    cloneAuditLog.duplicateCount = duplicateCount;
    cloneAuditLog.operationStatus = successCount > 0 && failCount === 0 ? 'SUCCESS' : 'FAIL'
    cloneAuditLog.isForeground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
    const res = AuditLogUtils.getInstance().writeAuditEvent(cloneAuditLog);
    LogUtil.info(TAG + ' AuditLogUtils operation ： ' + res);
  }

  /**
   * 保存文件维测日志
   * @param fileName 文件名称
   * @param status 操作状态
   */
  /* instrument ignore next */
  public saveRecordAuditLog(fileName: string, status: string) {
    const saveAuditLog = this.initAuditLog();
    saveAuditLog.extend = fileName;
    saveAuditLog.operationStatus = status
    saveAuditLog.operationType = OperationType.OPERATION_ADD;
    saveAuditLog.operationScenario = 'recording';
    saveAuditLog.operationCount = 1;
    saveAuditLog.successCount = 1;
    saveAuditLog.isForeground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
    status === 'SUCCESS' ? saveAuditLog.successCount = 1 : saveAuditLog.failCount = 1;
    const res = AuditLogUtils.getInstance().writeAuditEvent(saveAuditLog);
    LogUtil.info(TAG + ' AuditLogUtils operation ： ' + res);
  }


  /**
   * 备份数据库的维测日志
   * @param operationType 操作类型（增删改）
   * @param status 成功：SUCCESS 失败：FAIL
   */
  /* instrument ignore next */
  public backupAuditLog(operationType: string, status: string) {
    const backAuditLog = this.initAuditLog();
    backAuditLog.isUserBehavior = false;
    backAuditLog.cause = CauseType.DB_CORRUPTION;
    backAuditLog.operationType = operationType;
    backAuditLog.operationScenario = 'restore';
    backAuditLog.operationStatus = status;
    backAuditLog.isForeground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
    const res = AuditLogUtils.getInstance().writeAuditEvent(backAuditLog);
    LogUtil.info(TAG + ' AuditLogUtils operation ： ' + res);
  }
}