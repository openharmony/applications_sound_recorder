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
import { GlobalContext, LogUtil, MarkData } from '@ohos/common';
import { FADbProperties } from '@ohos/common/src/main/ets/constants/DatabaseConstants';
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager';
import FaInfo from '../model/FaInfo';
import { BusinessError } from '@kit.BasicServicesKit';
import { util } from '@kit.ArkTS';
import { formInfo, formProvider } from '@kit.FormKit';

const TAG: string = 'SoundRecorder_FormDbManager';
const FA_FORM_TABLE: string = 'fa_form_info';
// 查询限制条数
const FORM_QUERY_LIMIT: number = 100;
/**
 * 卡片数据库管理类
 */
export class FormDbManager {
  // 单例
  private static instance: FormDbManager;
  private rdbStore?: relationalStore.RdbStore;
  private cachedFormIds: Set<number> = new Set();

  /**
   * 获取唯一实例
   *
   * @returns 实例
   */
  public static getInstance(): FormDbManager {
    if (!FormDbManager.instance) {
      FormDbManager.instance = new FormDbManager();
    }
    return FormDbManager.instance;
  }

  constructor() {
    this.refreshRdbStore();
  }

  /**
   * 注册卡片 ID（内存缓存，确保 DB 未就绪时也能刷新卡片 UI）
   */
  public registerFormId(formId: number): void {
    if (formId > 0) {
      this.cachedFormIds.add(formId);
      LogUtil.info(TAG + ` registerFormId cache formId: ${formId}`);
    }
  }

  public unregisterFormId(formId: number): void {
    if (formId > 0) {
      this.cachedFormIds.delete(formId);
    }
  }

  private refreshRdbStore(): void {
    this.rdbStore = DatabaseManager.getRdbStore();
  }

  private async ensureRdbReady(): Promise<boolean> {
    this.refreshRdbStore();
    if (this.rdbStore) {
      return true;
    }
    const context = GlobalContext.getUIAbilityContext() ?? GlobalContext.getServiceAbilityContext();
    if (!context) {
      LogUtil.error(TAG + ' ensureRdbReady context is null');
      return false;
    }
    try {
      await DatabaseManager.init(context);
      this.refreshRdbStore();
      return !!this.rdbStore;
    } catch (err) {
      LogUtil.error(TAG + ` ensureRdbReady failed, code: ${err?.code}, message: ${err?.message}`);
      return false;
    }
  }

  /**
   * 查询所有formid，最多100条
   *
   * @returns 卡片ID数组
   */
  public async queryAllFormId(): Promise<number[]> {
    const dbFormIds = await this.queryAllFormIdFromDb();
    const mergedIds = new Set<number>();
    dbFormIds.forEach((formId: number) => {
      mergedIds.add(formId);
    });
    this.cachedFormIds.forEach((formId: number) => {
      mergedIds.add(formId);
    });
    const result: number[] = [];
    mergedIds.forEach((formId: number) => {
      result.push(formId);
    });
    LogUtil.info(TAG + ` queryAllFormId count: ${result.length}, cache: ${this.cachedFormIds.size}`);
    return result;
  }

  private async queryAllFormIdFromDb(): Promise<number[]> {
    let result: number[] = [];
    await this.ensureRdbReady();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(FA_FORM_TABLE);
    predicates.limitAs(FORM_QUERY_LIMIT);
    try {
      if (!this.rdbStore) {
        LogUtil.error(TAG + ` queryAllFormIdFromDb rdbStore is undefined`);
        return result;
      }
      let resultSet = await this.rdbStore.query(predicates, [FADbProperties.FORM_ID]);
      if (!resultSet) {
        LogUtil.error(TAG + ` queryAllFormIdFromDb resultSet invalid!`);
        return result;
      }
      let hasNext = resultSet.goToFirstRow();
      while (hasNext) {
        let formId: number = Number(resultSet.getString(resultSet.getColumnIndex(FADbProperties.FORM_ID)));
        result.push(formId);
        hasNext = resultSet.goToNextRow();
      }
      resultSet.close();
      return result;
    } catch (e) {
      LogUtil.error(TAG + `queryAllFormIdFromDb error: ${e} , the stack is ${e?.stack}`);
      return result;
    }
  }

  public async insertMarkToDb(mark: MarkData): Promise<number> {
    let markValueBucket: relationalStore.ValuesBucket = {
      'id': util.generateRandomUUID(true),
      'type': mark.type,
      'time_in_session': mark.markDuration,
      'content': mark.title,
      '_data': mark._data,
      'countNum': mark.count,
    };
    LogUtil.info(TAG + ' Tag is: ' + JSON.stringify(markValueBucket));
    return await DatabaseManager.insertTag(markValueBucket);
  }

  public addCardInfoInner(cardId: number, cardType: number, formName: string): void {
    this.registerFormId(cardId);
    this.addCardInfoAsync(cardId, cardType, formName).then((result: number) => {
      LogUtil.info(TAG + ' addCardInfoInner end ' + cardId + ' result: ' + result);
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` addCardInfoInner failed, code: ${err?.code}, message: ${err?.message}`);
    });
  }

  /**
   * 通过 FormKit 主动拉取本应用已上桌的全部卡片实例，把 formId 注入内存缓存。
   * 用于修复：未点击过的卡片 formId 不在缓存/DB 中，导致同步状态时只能拿到当前一张 id。
   */
  public async refreshAllFormIdsFromSystem(): Promise<void> {
    try {
      const forms: formInfo.RunningFormInfo[] = await formProvider.getPublishedRunningFormInfos();
      if (!forms || forms.length === 0) {
        return;
      }
      for (const info of forms) {
        const formId = Number(info?.formId);
        if (formId > 0) {
          this.registerFormId(formId);
        }
      }
      LogUtil.info(TAG + ` refreshAllFormIdsFromSystem count: ${forms.length}, cache: ${this.cachedFormIds.size}`);
    } catch (err) {
      LogUtil.error(TAG + ` refreshAllFormIdsFromSystem failed, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  public async addCardInfoAsync(cardId: number, cardType: number, formName: string): Promise<number> {
    if (!cardId) {
      return -1;
    }
    this.registerFormId(cardId);
    LogUtil.info(TAG + ' addFormInfoInner ' + cardId + ' cardType ' + cardType);
    const time: number = Date.now();
    const cardInfo: Record<string, number | string> = {
      'formID': cardId,
      'specificationID': cardType,
      'createTime': time,
      'updateTime': time,
      'formName': formName,
    };
    await this.deleteCardInfoByFormID([cardId]);
    return await this.insertFaCardInfo(new FaInfo(cardInfo));
  }

  /**
   * 新增卡片信息
   *
   * @param faCardInfo 卡片元数据对象
   * @returns 是否新增成功
   */
  public async insertFaCardInfo(faCardInfo: FaInfo): Promise<number> {
    const ready = await this.ensureRdbReady();
    if (!ready || !this.rdbStore) {
      LogUtil.error(TAG + ' insertFaCardInfo rdbStore is undefined');
      return -1;
    }
    let faData: relationalStore.ValuesBucket | undefined = this.buildFaValueBucket(faCardInfo);
    if (!faData) {
      return -1;
    }
    try {
      const result = await this.rdbStore.insert(FA_FORM_TABLE, faData);
      if (faCardInfo.formId) {
        this.registerFormId(faCardInfo.formId);
      }
      return result;
    } catch (err) {
      LogUtil.error(TAG + ' insertFaCardInfo error:' + err);
      return -1;
    }
  }

  /**
   * 根据卡片ID批量删除卡片信息
   *
   * @param formIdArr 卡片id数组
   * @returns 是否成功
   */
  public async deleteCardInfoByFormID(formIdArr: Array<number>): Promise<number> {
    formIdArr.forEach((formId: number) => this.unregisterFormId(formId));
    if (!formIdArr || formIdArr.length === 0) {
      LogUtil.warn(TAG + ` deleteCardInfoByFormID formIdArr is wrong`);
      return -1;
    }
    await this.ensureRdbReady();
    let predicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates(FA_FORM_TABLE);
    predicates.in(FADbProperties.FORM_ID, formIdArr);
    if (!this.rdbStore) {
      LogUtil.error(TAG + ` deleteCardInfoByFormID rdbStore is undefined`);
      return -1;
    }
    try {
      const result = await this.rdbStore.delete(predicates);
      LogUtil.info(TAG + ` deleteCardInfoByFormID result : ${result}`);
      return result;
    } catch (e) {
      LogUtil.error(TAG + ` deleteCardInfoByFormID error , the msg is : ${e}`);
      return (e as BusinessError).code;
    }
  }

  public buildFaValueBucket(faCardInfo: FaInfo): relationalStore.ValuesBucket | undefined {
    if (!faCardInfo || !faCardInfo.formId) {
      LogUtil.warn(TAG + ` Build CardInfoBucket error , the cardinfo or formid is undefined`)
      return undefined
    }
    return {
      'formID': faCardInfo.formId || -1,
      'formName': faCardInfo.formName || '',
      'specificationId': faCardInfo.specificationId || 0,
      'createTime': faCardInfo.createTime || Date.now(),
      'updateTime': faCardInfo.updateTime || Date.now(),
    }
  }
}
