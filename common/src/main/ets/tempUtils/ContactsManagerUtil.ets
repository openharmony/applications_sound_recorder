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

import { RecordData } from '../model/RecordData';
import { LogUtil } from './LogUtil';
import { dataShare, dataSharePredicates } from '@kit.ArkData';
import { taskpool } from '@kit.ArkTS';
import { CommonConstants } from '../constants/CommonConstants';
import DatabaseManager from './DatabaseManager';
import DataShareResultSet from '@ohos.data.DataShareResultSet';
import { SendableRecordData } from '../model/SendableRecordData';
import { Util } from './Util';
import { PathUtil } from './PathUtil';

const TAG = 'SoundRecorder_ContactsManagerUtil';

export default class ContactsManagerUtil {
  private static instance?: ContactsManagerUtil;

  private contactsOccurrencesTimeMap: Map<string, number> = new Map<string, number>();

  private constructor() {
    LogUtil.info(TAG + ` set ContactsManagerUtil singleton, create an instance.`);
  }

  public static getInstance(): ContactsManagerUtil {
    if (ContactsManagerUtil.instance) {
      return ContactsManagerUtil.instance;
    }
    ContactsManagerUtil.instance = new ContactsManagerUtil();
    return ContactsManagerUtil.instance;
  }

  static async processResultSet(resultSet: DataShareResultSet): Promise<SendableRecordData[]> {
    const fetchItem = (resultSet: DataShareResultSet): SendableRecordData => {
      const item = new SendableRecordData();
      item.id = resultSet.getLong(resultSet.getColumnIndex('id'));
      item.contacts = resultSet.getString(resultSet.getColumnIndex('title'));
      // 处理出错数据
      if (item.contacts.indexOf('_') !== -1) {
        item.contacts = '';
      }
      // 通话录音中item.title始终保存的是display_name，item.name始终保存的是用来录音机界面显示的字段
      item.title = ContactsManagerUtil.getInstance().getTitleFromFilePath(
        resultSet.getString(resultSet.getColumnIndex('file_path'))
      );
      if (!item.contacts) {
        item.name = ContactsManagerUtil.getInstance().getContactNameFromDisplayName(item.title);
      } else {
        item.name = item.contacts;
      }
      item.date = resultSet.getLong(resultSet.getColumnIndex('recorder_added'));
      item.duration = Number(resultSet.getString(resultSet.getColumnIndex('duration')));
      item.phoneNumber = resultSet.getString(resultSet.getColumnIndex('phone_number'));
      if (!item.phoneNumber) {
        // 如果通话录音记录来自于双框架手机，并且用户在双框架手机上进行过重命名，然后克隆到单框架，此时phone_number字段可能为空
        // 判断录音是否是通话录音是通过phoneNumber是否为空来判断的，所以这种情况下给phoneNumber赋一个初始值
        item.phoneNumber = '0';
      }
      item._data = resultSet.getString(resultSet.getColumnIndex('file_path'));
      item.delete = resultSet.getLong(resultSet.getColumnIndex('is_deleted'));
      return item;
    };

    const result: SendableRecordData[] = [];
    while (resultSet.goToNextRow()) {
      result.push(fetchItem(resultSet));
    }
    return result;
  }

  /**
   * 如果从file_path中获取到的名称为修改过的名称则不带 "_" 直接返回其名称
   * 如果带"_", 则未经更改，其file_path的名称是初始化名称，其名称携带时间戳
   * display_name携带的是非时间戳而是时间字符串，故将其时间戳转化为时间字符串
   * @param filePath
   * @returns 文件名称
   */
  public getTitleFromFilePath(filePath: string): string {
    if (!filePath) {
      return '';
    }
    let filePaths = filePath.split('/');
    if (filePaths.length === 0) {
      return '';
    }
    if (filePaths[filePaths.length - 1].indexOf('_') === -1) {
      return filePaths[filePaths.length - 1];
    }
    let pathName = filePaths[filePaths.length - 1];
    const timestamp = pathName.substring(pathName.indexOf('_') + 1, pathName.indexOf('.'));
    const time = Util.getTimeFormatFromTimestamp(timestamp);
    return pathName.replace(timestamp, time);
  }

  /**
   * 联系人命名整体规则：
   * 1、 张三 张三 1 张三 2 依次递增，并且持久化到title字段中；
   * 2、 中间序号丢失也不插空，例如 张三  张三 2 新增的张三的电话为张三 3
   * 3、 序号从第一个出现的该联系人的序号开始算起，例如 张三 10 则新增的张三的电话为张三 11
   * @param displayName
   * @returns
   */
  /* instrument ignore next */
  public getContactNameFromDisplayName(displayName: string): string {
    let contactName = displayName;
    let suffixIndex = displayName.lastIndexOf('.');
    if (suffixIndex !== -1) {
      contactName = displayName.substring(0, displayName.lastIndexOf('.'));
    }

    // 如果用户没有重命名过通话录音，则display_name字段的命名规则是：联系人 or 电话号码_时间戳，该格式是固定的
    // 例如：张三@157 xxxx xxx_20241030162010，张三_20241030162010，157 xxxx xxxx_20241030162010，这三种形式
    let regOfContact = /^[^/:*？'<>|]+_\d{14}$/;

    // 如果contactName不是上面的形式，说明是用户重命名过的通话录音，直接返回用户重命名之后的通话录音名字
    if (!regOfContact.test(contactName)) {
      return contactName;
    }

    // 拆出来联系人
    let contacts = contactName.substring(0, displayName.lastIndexOf('_'));
    // 如果联系人部分包含@，则取@之前的部分，这部分是保存的联系人名字
    let i = contacts.indexOf('@');
    if (i !== -1) {
      contacts = contacts.substring(0, i);
    }
    return contacts;
  }

  /* instrument ignore next */
  private getContactNameAndIndexFromTitle(title: string,
    contactName: string): Record<string, string | number | boolean> {
    let lastIndexOfSpace = title.lastIndexOf(' ');
    let tempContact = title.substring(0, lastIndexOfSpace);
    let index: string = '';
    if (tempContact === contactName) {
      // tempContact === contactName: 形如 张三 1这种形式的联系人
      index = title.substring(lastIndexOfSpace + 1);
    } else {
      // title === contactName：形如 0755 2856 0888 这种形式的联系人
      index = '0';
    }
    const reg = /^\d+$/; // 一个或多个数字
    if (reg.test(index) && (tempContact === contactName || title === contactName)) {
      // 当前展示在录音机里面的名字满足联系人 + ' ' + 序号的格式，获取其中的序号
      return {'isParticularFormat': true, 'index': Number(index)};
    }
    return {'isParticularFormat': false, 'index': 0};
  }

  public reset(): void {
    LogUtil.info(TAG + ' reset contactsOccurrencesTimeMap');
    this.contactsOccurrencesTimeMap.clear();
  }

  /**
   * 根据phoneNumber给通话录音的id增加前缀CallRecord_
   * @param record 录音数据
   * @returns 通话录音增加前缀，非通话录音不增加
   */
  /* instrument ignore next */
  public addCallRecordPrefix(record: RecordData): string {
    return record.phoneNumber ? 'CallRecord_' + record.id : record.id?.toString();
  }

  /**
   * 根据phoneNumber批量给通话录音的id增加前缀CallRecord_
   * @param record 录音数据数组
   * @returns 通话录音增加前缀，非通话录音不增加
   */
  public batchAddCallRecordPrefix(record: RecordData[]): Array<string> {
    let idList = record.map((item) =>{
      return this.addCallRecordPrefix(item);
    })
    return idList;
  }

  /* instrument ignore next */
  public updateCallRecordIndex(context: Context, recordDataList: RecordData[]): void {
    // item.contacts中存储的是通话录音数据库中的title字段，该字段为空，说明没有被重命名过
    let contacts = recordDataList.map(item => item.contacts);
    let files: string[] = [];
    let newTitles: string[] = [];
    // 先处理已重命名的录音
    for (let i = recordDataList.length - 1; i >= 0; i--) {
      if (contacts[i]) {
        // contacts[i] 非空即通话录音数据库中的title字段不为空，标识通话录音文件已经被重命名过
        // recordDataList[i].title中存储的是通话录音数据库中的display_name字段，该字段中含有联系人和电话号码信息
        let contactName = this.getContactNameFromDisplayName(recordDataList[i].title);
        let record = this.getContactNameAndIndexFromTitle(contacts[i], contactName);
        if (record['isParticularFormat'] as boolean) {
          // 如果通话录音数据库中的title字段保存的是 联系人 + ' ' + 序号 这种格式的命名，那么将该联系人的序号更新，更新原则是始终记住当前最大序号
          let currentIndex = this.contactsOccurrencesTimeMap.get(contactName) || 1;
          this.contactsOccurrencesTimeMap.set(contactName, Math.max(record['index'] as number, currentIndex));
        }
        recordDataList[i].name = contacts[i];
      }
    }
    // 再处理未重命名的录音
    for (let i = recordDataList.length - 1; i >= 0; i--) {
      if (!contacts[i]) {
        // recordDataList[i].title中存储的是通话录音数据库中的display_name字段，该字段中含有联系人和电话号码信息
        let contactName = this.getContactNameFromDisplayName(recordDataList[i].title);
        if (!this.contactsOccurrencesTimeMap.has(contactName)) {
          this.contactsOccurrencesTimeMap.set(contactName, 1);
          recordDataList[i].name = contactName;
        } else {
          let tmplIndex = this.contactsOccurrencesTimeMap.get(contactName) || 1;
          tmplIndex++;
          // 为该联系人累加序号
          this.contactsOccurrencesTimeMap.set(contactName, tmplIndex);
          // recordDataList[i].name中存储的是最终要显示在录音机界面上的带序号的名字
          recordDataList[i].name = contactName + ' ' + tmplIndex;
        }

        // 如果通话录音数据库中的title字段没有被重命名过，那么使用刚更新的recordDataList[i].name为其重命名，将需要重命名的数据准备好
        files.push(recordDataList[i]._data);
        newTitles.push(recordDataList[i].name);
      }
    }

    // 使用taskpool更新通话录音数据库中的title字段
    this.startUpdateTitleTask(context, files, newTitles);
  }

  /* instrument ignore next */
  /**
   * 此函数为新增的通话录音数据更改title，而新的命名通话录音已做处理无需进行二次加工
   * 若是name为空，则从title中取出相关名称去掉后缀
   * @param newCallRecord
   * @returns
   */
  public async updateNewCallRecordName(newCallRecord: RecordData): Promise<void> {
    if (!newCallRecord.name) {
      LogUtil.info(TAG + ' The call recording does not have a name; it is obtained from the title.');
      newCallRecord.name = PathUtil.basename(newCallRecord.title);
    }
    await DatabaseManager.updateCallRecordDatabase([newCallRecord._data], { 'title': newCallRecord.name });
  }

  /* instrument ignore next */
  public startUpdateTitleTask(context: Context, files: string[], newTitles: string[]): void {
    if (!context || files.length === 0) {
      LogUtil.info(TAG + ' startUpdateSoundRecordDisplayNameTask error.');
      return;
    }
    let task = new taskpool.Task(updateSoundRecordDisplayName, context, files, newTitles);
    taskpool.execute(task).then(() => {
      LogUtil.info(TAG + ' updateSoundRecordDisplayNameTask success.');
    }).catch((error: Error) => {
      LogUtil.info(TAG + ' updateSoundRecordDisplayNameTask error: ' + error.message);
    });
  }
}

@Concurrent
async function updateSoundRecordDisplayName(context: Context, files: string[],
  displayName: string[]): Promise<boolean> {
  const TAG = 'SoundRecorder_ContactsManagerUtil';
  const CALL_RECORD_URI = 'datashare:///com.ohos.callrecorder.datashareAbility/call_record/record_log';

  LogUtil.info(TAG + ' updateSoundRecordDisplayNameTask begin: ' + files.length);
  let dataShareHelper: dataShare.DataShareHelper | undefined = undefined;
  try {
    dataShareHelper = await dataShare.createDataShareHelper(context, CALL_RECORD_URI);
    for (let i = 0; i < files.length; i++) {
      let predicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('file_path', files[i]);
      await dataShareHelper.update(CALL_RECORD_URI, predicates, { 'title': displayName[i] });
    }
    LogUtil.info(TAG + ' updateSoundRecordDisplayNameTask done.');
    return true;
  } catch (err) {
    LogUtil.error(TAG + ' updateSoundRecordDisplayNameTask failed: ' + err);
    return false;
  } finally {
    dataShareHelper?.close();
  }
}