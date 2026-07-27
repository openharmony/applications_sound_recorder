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

import DatabaseManager from '../utils/DatabaseManager';
import { LogUtil } from '../utils/LogUtil';
import fs from '@ohos.file.fs';
import { RecordData } from '../model/RecordData';
import { Callback } from '@ohos.base';
import I18n from '@ohos.i18n';
import { CommonConstants } from '../constants/CommonConstants';
import { CustomContentDialog } from '@ohos.arkui.advanced.Dialog';
import { AnonymousUtil } from '../utils/AnonymousUtil';
import { AccessibilityUtil, Util } from '../utils/Util';
import { DeviceUtil } from '../utils/DeviceUtil';
import { fileUri } from '@kit.CoreFileKit';
import { PathUtil } from '../utils/PathUtil';
import { FileUtil } from '../utils/FileUtil';
import { RecordType } from '../enums/RecordType';

const TAG = 'SoundRecorder_RenameDialog';
const RENAME_MAX_LENGTH: number = 83;

@CustomDialog
export struct RenameDialog {
  private manager = getContext(this).resourceManager;
  private renameController: CustomDialogController;
  private inputValue?: string;
  private isInputValid: boolean = false;
  public confirmCallback?: Callback<string>;
  @State errorMsg: Resource | undefined = $r('app.string.no_name');
  @Prop recordBeforeRename: RecordData;
  @Consume canFocus: boolean;

  // 校验重命名输入框字数并提示
  private async validAndSetIsNum(value: string): Promise<boolean> {
    this.errorMsg = undefined;
    if (!this.recordBeforeRename) {
      LogUtil.info(TAG + ' input value is null.');
      return false;
    }
    if (value === this.recordBeforeRename?.name) {
      LogUtil.info(TAG + ' input value is same, will not validate');
      if (value.length >= RENAME_MAX_LENGTH) {
        this.errorMsg = $r('app.string.maximum_length');
      }
      return true;
    }
    value = value.trim();
    this.errorMsg = undefined;
    if (value.length >= RENAME_MAX_LENGTH) {
      this.errorMsg = $r('app.string.maximum_length');
    }
    //校验输入框是否有内容
    if (value.length === 0) {
      this.errorMsg = $r('app.string.no_name');
      return false;
    }
    //判断命名不能包含 /\:*?"<>|
    if (Util.specialCharValidator(value)) {
      this.errorMsg = $r('app.string.rename_filter');
      return false;
    }

    //校验命名是否重复
    if (!this.recordBeforeRename?.phoneNumber) {
      const title = value + '.' + this.recordBeforeRename?.title.split('.').pop();
      //查询列表中名称是否存在
      let result = await DatabaseManager.getNormalRecordDataFromDb('title', title);
      let resultRecent = await DatabaseManager.getRecentDeleteRecordDataFromDb('title', title);
      if (result.concat(resultRecent).length) {
        LogUtil.info(TAG + ' query record: ' + AnonymousUtil.anonymous(title) + ' count: ' + result.length);
        this.errorMsg = $r('app.string.rename_over');
        return false;
      }
    } else {
      let result = await DatabaseManager.getCallRecordDataFromDb('title', value);
      if (result.length) {
        LogUtil.info(TAG + ' query call record: ' + value + ' count: ' + result.length);
        this.errorMsg = $r('app.string.rename_over');
        return false;
      }
    }

    return true;
  }

  private async renameRecord(inputValue: string, newTitle: string, oldPath: string, newPath: string) {
    try {
      LogUtil.info(TAG + ' renameRecord ');
      await fs.rename(oldPath, newPath);
      if (newPath.startsWith(CommonConstants.CALL_RECORD_URI_PREFIX) ||
        newPath.startsWith(CommonConstants.CALL_RECORD_URI_PREFIX_GROUP) ||
        newPath.startsWith(PathUtil.CALLRECORD_FILEPATH)) {
        await DatabaseManager.updateCallRecordDatabase([oldPath], {
          'title': inputValue,
          'display_name': PathUtil.filename(newPath),
          'file_path': newPath
        });
      } else {
        await DatabaseManager.updateNormalRecordDatabase(oldPath, {
          'title': newTitle,
          '_data': newPath
        });
      }
      await DatabaseManager.batchUpdateTag(oldPath, newPath);
      await this.renameTransFileAndUpdateDatabase(oldPath, newPath);
      LogUtil.info(TAG + ' rename file success.');
      if (this.confirmCallback) {
        LogUtil.info(TAG + ' confirm callback ');
        this.confirmCallback(inputValue);
      }
    } catch (e) {
      LogUtil.error(`${TAG} failed to rename, code: ${e.code}, message: ${e.message}`);
    }
  }

  private async renameTransFileAndUpdateDatabase(oldPath: string, newPath: string) {
    try {
      const rows = await DatabaseManager.queryRecordTransferData(oldPath);
      for (let row of rows) {
        const oldJsonPath = row.jsonPath as string;
        const newName = PathUtil.basename(newPath);
        const jsonExt = PathUtil.extname(oldJsonPath);
        const newJsonPath = `${PathUtil.dirname(oldJsonPath)}/${newName}${jsonExt}`;
        if (!FileUtil.rename(oldJsonPath, newJsonPath)) {
          LogUtil.error(`${TAG} failed to rename json-path file.`);
          return;
        }
        await DatabaseManager.updateTransDateDatabase(oldPath, {
          'record_path': newPath,
          'JSON_PATH': newJsonPath,
          'file_uri': fileUri.getUriFromPath(newPath)
        });
      }
      LogUtil.info(TAG + ' rename trans file success.');
    } catch (e) {
      LogUtil.info(TAG + ' ai trans text not exist: ' + e);
      return;
    }
  }

  confirmRename(inputValue: string): void {
    if (!this.recordBeforeRename) {
      LogUtil.info(TAG + ' rename error focusRecord is null.');
      return;
    }
    inputValue = inputValue.trim();
    let fileSuf = this.recordBeforeRename.title.split('.').pop();

    let oldPath = this.recordBeforeRename._data;
    let newTitle = inputValue + '.' + fileSuf;
    const filesDir = oldPath.substring(0, oldPath.lastIndexOf('/'));
    let newPath = filesDir + '/' + newTitle;
    LogUtil.info(TAG + ' rename file old name: ' + AnonymousUtil.anonymous(this.recordBeforeRename.title) +
      ' new name: ' + AnonymousUtil.anonymous(newTitle));
    //每次新命名name赋值给重命名弹窗name
    this.renameRecord(inputValue, newTitle, oldPath, newPath);
  }

  @Builder
  buildContent(): void {
    Column() {
      TextInput({
        placeholder: $r('app.string.rename_speaker'),
        text: this.inputValue === undefined ? this.recordBeforeRename?.name : this.inputValue
      })
        .id('inputText')
        .caretColor($r('app.color.themed_red'))
        .selectedBackgroundColor($r('app.color.themed_red'))
        .maxLength(RENAME_MAX_LENGTH)
        .backgroundColor(Color.Transparent)
        .enableKeyboardOnFocus(true)
        .defaultFocus(true)
        .showError(this.errorMsg)
        .showUnderline(true)
        .lineHeight(I18n.System.getSystemLanguage() === 'bo' ? 32 : -1)
        .padding({
          bottom: $r('app.float.distance_8'),
          left: $r('app.float.distance_12'),
          right: $r('app.float.distance_12')
        })
        .onChange(async (value: string) => {
          this.inputValue = value;
          this.isInputValid = await this.validAndSetIsNum(this.inputValue);
        })
        .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) => {
          if (enterKey === EnterKeyType.Done) {
            if (this.isInputValid) {
              this.confirmRename(this.inputValue || '');
            } else {
              // 文件名不可用上报无障碍事件，播报提醒
              AccessibilityUtil.sendAnnounceAccessibilityEvent(this.manager.getStringSync(this.errorMsg) ?? '');
            }
          }
        })
        .onAppear(() => {
          LogUtil.info(TAG + ' TextInput onAppear');
          this.canFocus = false;
          focusControl.requestFocus('inputText');
        })
        .onDisAppear(() => {
          LogUtil.info(TAG + ' TextInput onDisAppear');
          this.canFocus = true;
        })
    }
  }

  build() {
    CustomContentDialog({
      primaryTitle: $r('app.string.file_rename'),
      contentBuilder: () => {
        this.buildContent()
      },
      buttons: [
        {
          value: $r('app.string.cancel'),
          fontColor: '#FB654E',
          background: Color.Transparent,
          buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
          action: () => {
            this.renameController.close()
            this.isInputValid = false;
            LogUtil.info(TAG + ' cancel rename. ');
          }
        },
        {
          value: $r('app.string.on_sure'),
          fontColor: '#FB654E',
          background: Color.Transparent,
          buttonStyle: DeviceUtil.isPC() ? ButtonStyleMode.NORMAL : ButtonStyleMode.TEXTUAL,
          action: () => {
            if (this.isInputValid) {
              LogUtil.info(TAG + ' confirmRename onclick')
              this.confirmRename(this.inputValue || '');
            } else {
              // 文件名不可用上报无障碍事件，播报提醒
              AccessibilityUtil.sendAnnounceAccessibilityEvent(this.manager.getStringSync(this.errorMsg) ?? '');
            }
          }
        }
      ]
    })
  }
}