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

import IFormController from './IFormController';
import Want from '@ohos.app.ability.Want';
import { formBindingData, formInfo } from '@kit.FormKit';
import { FORM_PARAM_IDENTITY_KEY } from '../constants/FormConstants';

const TAG = 'SoundRecorder_Record2x1FormController';
/**
 * 录音2x1卡片Controller
 *
 */
export default class Record2x1FormController implements IFormController {
  public static readonly RECORDER_FORM_2X1: string = 'Record2x1Form';
  onAddForm(context: Context, want: Want): formBindingData.FormBindingData {
    let formData: Record<string, Object> = {};
    if (want && want.parameters) {
      formData = {
        'formId': String(want.parameters[FORM_PARAM_IDENTITY_KEY]),
      };
    }
    return formBindingData.createFormBindingData(formData);
  }

  onCastToNormalForm(context: Context, formId: string): void {
    throw new Error('Method not implemented.');
  }

  onUpdateForm(context: Context, formId: string): void {
    throw new Error('Method not implemented.');
  }

  onChangeFormVisibility(context: Context, newStatus: Record<string, number>): void {
    throw new Error('Method not implemented.');
  }

  onFormEvent(context: Context, formId: string, message: string): void {
    throw new Error('Method not implemented.');
  }

  onRemoveForm(context: Context, formId: string): void {
  }

  onAcquireFormState(context: Context, want: Want): formInfo.FormState {
    throw new Error('Method not implemented.');
  }

}