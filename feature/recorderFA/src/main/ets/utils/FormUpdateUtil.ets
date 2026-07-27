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
import { formBindingData, formProvider } from '@kit.FormKit';
import { LogUtil } from '@ohos/common';
import { BusinessError } from '@kit.BasicServicesKit';
import { FormDbManager } from '../storage/FormDbManager';
import { ArrayUtils } from './ArrayUtils';
import { FormCardErrorCode } from '../constants/FormConstants';

const TAG = 'SoundRecorder_FormUpdateUtil';
/**
 * 卡片更新工具类
 */
export class FormUpdateUtil {
  private static instance: FormUpdateUtil;
  /**
   * 获取唯一实例
   * @returns
   */
  public static getInstance(): FormUpdateUtil {
    if (!FormUpdateUtil.instance) {
      FormUpdateUtil.instance = new FormUpdateUtil();
    }
    return FormUpdateUtil.instance;
  }

  /**
   * 更新所有卡片或指定卡片集
   * @param data 数据
   */
  public updateAllForm(data: formBindingData.FormBindingData) {
    if (!data) {
      LogUtil.info(TAG + ` data is null, updateAllForm return`);
      return;
    }
    FormDbManager.getInstance().refreshAllFormIdsFromSystem().then(() => {
      FormDbManager.getInstance().queryAllFormId().then((formIds: number[]) => {
        if (ArrayUtils.isEmpty(formIds)) {
          LogUtil.warn(TAG + ' updateAllForm skipped, no formId found');
          return;
        }
        LogUtil.info(TAG + ` updateAllForm formIds: ${formIds.join(',')}`);
        formIds.forEach((formId: number) => {
          this.updateForm(String(formId), data);
        })
      })
    })
  }

  /**
   * 根据卡片ID更新卡片数据
   * @param formId 卡片ID
   * @param data 卡片数据
   */
  private updateForm(formId: string, data: formBindingData.FormBindingData) {
    if (!data || !formId) {
      LogUtil.info(TAG + ` updateCard return、`);
      return;
    }
    formProvider.updateForm(formId, data).then(() => {
      LogUtil.info(TAG + ` updateForm success formId: ${formId}`);
    }).catch((error: BusinessError) => {
      LogUtil.error(TAG + ` updateCard error: ${error}`);
      if ((error as BusinessError).code === FormCardErrorCode.CARD_NOT_EXIST) {
        FormDbManager.getInstance().deleteCardInfoByFormID([Number(formId)]).then((value: number) => {
          LogUtil.info(TAG + ' delete invalid card ' + formId);
        })
      }
    });
  }

  /**
   * 更新所有卡片或指定卡片集文件名
   * @param data 数据
   * @param formIdArray 卡片id数组,没有时刷新所有FA卡片
   */
  public async updateFileNameAllForm(data: formBindingData.FormBindingData): Promise<void> {
    if (!data) {
      LogUtil.info(TAG + ` data is null, syncUpdateAllForm return`);
      return Promise.reject();
    }
    const formIds = await FormDbManager.getInstance().queryAllFormId();
    if (!ArrayUtils.isEmpty(formIds)) {
      await Promise.all(formIds.map(async (formId: number) => {
        await this.updateFileName(String(formId), data);
      }));
    }
  }

  private async updateFileName(formId: string, data: formBindingData.FormBindingData): Promise<void> {
    if (!data || !formId) {
      LogUtil.info(TAG + ` updateFileName return、`);
      return;
    }
    try {
      await formProvider.updateForm(formId, data);
    } catch (error) {
      LogUtil.error(TAG + ` updateFileName error: ${error}`);
      if ((error as BusinessError).code === FormCardErrorCode.CARD_NOT_EXIST) {
        try {
          await FormDbManager.getInstance().deleteCardInfoByFormID([Number(formId)]);
          LogUtil.info(TAG + ' delete invalid card ' + formId);
        } catch (err) {
          LogUtil.error(TAG + ` Failed to delete invalid card, code: ${err?.code}, message: ${err?.message}`);
        }
      }
    }
  }
}