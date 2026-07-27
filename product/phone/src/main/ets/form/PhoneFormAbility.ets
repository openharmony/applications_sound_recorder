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

import { FormExtensionAbility, formBindingData } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { DatabaseManager, GlobalContext, LogUtil } from '@ohos/common';
import {
  FormDbManager,
  FORM_PARAM_DIMENSION_KEY,
  FORM_PARAM_IDENTITY_KEY,
  FORM_PARAM_NAME_KEY,
  Record2x1FormController,
  Record2x2FormController,
  IFormController
} from '@ohos/recorderFA';

const TAG: string = 'SoundRecorder_PhoneFormAbility';
const FORM_2X1: string = 'Record2x1Form';
const FORM_2X2: string = 'Record2x2Form';

export default class PhoneFormAbility extends FormExtensionAbility {
  private record2x1Controller: Record2x1FormController = new Record2x1FormController();
  private record2x2Controller: Record2x2FormController = new Record2x2FormController();

  onCreate(want: Want): void {
    LogUtil.info(TAG + ' onCreate');
    GlobalContext.setServiceAbilityContext(this.context);
    DatabaseManager.init(this.context);
  }

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formName = want?.parameters?.[FORM_PARAM_NAME_KEY] as string;
    const formId = want?.parameters?.[FORM_PARAM_IDENTITY_KEY] as string;
    const dimension = want?.parameters?.[FORM_PARAM_DIMENSION_KEY] as number;
    LogUtil.info(TAG + ` onAddForm formName: ${formName}, formId: ${formId}`);
    const controller = this.getController(formName);
    const data = controller.onAddForm(this.context, want);
    if (formId) {
      FormDbManager.getInstance().addCardInfoInner(Number(formId), this.getSpecificationId(formName, dimension),
        formName ?? '');
    } else {
      LogUtil.error(TAG + ' onAddForm formId is empty');
    }
    return data;
  }

  onRemoveForm(formId: string): void {
    LogUtil.info(TAG + ' onRemoveForm formId: ' + formId);
    this.getController('').onRemoveForm(this.context, formId);
    FormDbManager.getInstance().deleteCardInfoByFormID([Number(formId)]);
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    LogUtil.info(TAG + ` onChangeFormVisibility status: ${JSON.stringify(newStatus)}`);
  }

  private getController(formName: string): IFormController {
    if (formName === FORM_2X2) {
      return this.record2x2Controller;
    }
    return this.record2x1Controller;
  }

  private getSpecificationId(formName: string, dimension: number): number {
    if (formName === FORM_2X2) {
      return 2;
    }
    if (formName === FORM_2X1) {
      return 1;
    }
    return dimension ?? 0;
  }
}
