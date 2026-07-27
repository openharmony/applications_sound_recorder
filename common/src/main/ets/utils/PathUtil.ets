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

import { DeviceUtil } from './DeviceUtil';
import { LogUtil } from './LogUtil';
import { RecordType } from '../enums/RecordType';
import { RecordData } from '../model/RecordData';
import deviceInfo from '@ohos.deviceInfo';

const TAG = 'SoundRecorder_PathUtil';

enum SandboxFilepath {
  PRODUCT_PHONE = '/data/storage/el2/base/haps/phone/files',
  PRODUCT_PC = '/data/storage/el2/base/haps/pc/files'
}

enum UserFilepath {
  PHONE = '/storage/Users/currentUser/Sounds',
  PC = '/storage/Users/currentUser/Music/SoundRecorder',
  PAD = '/storage/Users/currentUser/Music/SoundRecorder'
}

const USER_FILEPATH: string = getUserFilepath();
const CALLRECORD_FILEPATH: string = `${USER_FILEPATH}/CallRecord`;
const HEADSETRECORD_FILEPATH: string = `${USER_FILEPATH}/AudioAccessoryManager`;

export class PathUtil {
  public static readonly USER_FILEPATH: string = USER_FILEPATH;
  public static readonly CALLRECORD_FILEPATH: string = CALLRECORD_FILEPATH;
  public static readonly CALLRECORD_GROUP_PREFIX = '/data/storage/el2/group';
  public static readonly SANDBOX_FILEPATH: string = getSandboxFilePath();
  public static readonly I18N_USER_FILEPATH: ResourceStr = getI18nUserFilepath();
  public static readonly HEADSETRECORD_FILEPATH: string = HEADSETRECORD_FILEPATH;
  public static readonly CALLRECORD_SANBOX_FILEPATH: string = '/CallRecord';
  public static readonly HEADSETRECORD_SANBOX_FILEPATH: string = '/AudioAccessoryManager';

  public static filename(path: string): string {
    path = normalizePath(path);
    const idx = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
    return path.slice(idx + 1);
  }

  public static basename(path: string): string {
    const base = PathUtil.filename(path);
    const lastDot = base.lastIndexOf('.');
    return lastDot > 0 ? base.slice(0, lastDot) : base;
  }

  public static extname(path: string): string {
    const base = PathUtil.filename(path);
    const lastDot = base.lastIndexOf('.');
    return lastDot > 0 ? base.slice(lastDot) : '';
  }

  public static dirname(path: string): string {
    path = normalizePath(path);
    if (!path) {
      return '.';
    }
    const idx = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
    if (idx < 0) {
      return '.';
    }
    if (idx === 0) {
      return path[0];
    }
    return path.slice(0, idx);
  }


  public static getTransResultSanboxPath(context: Context, record: RecordData): string {
    if (record.type === RecordType.HEADSET_RECORD) {
      return context.filesDir + PathUtil.HEADSETRECORD_SANBOX_FILEPATH;
    }
    if (record.phoneNumber) {
      return context.filesDir + PathUtil.CALLRECORD_SANBOX_FILEPATH;
    } else {
      return context.filesDir;
    }
  }
}

function getI18nUserFilepath(): ResourceStr {
  if (DeviceUtil.isPhone()) {
    return $r('app.string.user_filepath_on_phone');
  }
  if (DeviceUtil.isPC()) {
    return $r('app.string.user_filepath_on_pc');
  }
  if (DeviceUtil.isTablet()) {
    return $r('app.string.user_filepath_on_pad');
  }

  LogUtil.error(`${TAG} no support device type.`);

  return '';
}

function getUserFilepath(): string {
  if (DeviceUtil.isPhone()) {
    return UserFilepath.PHONE;
  }
  if (DeviceUtil.isPC()) {
    return UserFilepath.PC
  }
  if (DeviceUtil.isTablet()) {
    return UserFilepath.PAD
  }

  LogUtil.error(`${TAG} no support device type.`);
  //todo没有识别到设备类型 会导致移动文件失败
  return UserFilepath.PHONE;
}

function getSandboxFilePath(): string {
  if (DeviceUtil.isPhone() || DeviceUtil.isTablet()) {
    return SandboxFilepath.PRODUCT_PHONE;
  }
  if (DeviceUtil.isPC()) {
    return SandboxFilepath.PRODUCT_PC
  }

  LogUtil.error(`${TAG} no support device type.`);
  // todo没有识别到设备类型 会导致扫描沙箱目录的时候为空删除数据 先返回手机沙箱目录
  return SandboxFilepath.PRODUCT_PHONE
  // return '';
}

function normalizePath(path: string | undefined | null): string {
  return (path ?? '').replace(/[/\\]+$/, '');
}