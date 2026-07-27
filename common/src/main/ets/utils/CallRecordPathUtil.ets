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

import { FileUtil } from './FileUtil';
import { LogUtil } from './LogUtil';
import { PathUtil } from './PathUtil';
import { RecordData } from '../model/RecordData';

const TAG = 'SoundRecorder_CallRecordPathUtil';
const CALL_RECORD_GROUP_ID = 'group.1435681907172981696';
const CALL_RECORDER_BUNDLE = 'com.ohos.callrecorder';
const EMULATED_CALLRECORD_PATH = '/storage/emulated/0/Sounds/CallRecord';

export class CallRecordPathUtil {
  public static async resolvePlayPath(context: Context, recordData: RecordData): Promise<string> {
    const dbPath = recordData._data ?? '';
    if (!dbPath) {
      return dbPath;
    }
    if (CallRecordPathUtil.isMediaUriPath(dbPath)) {
      LogUtil.info(`${TAG} [RecordChain] resolvePlayPath media uri length:${dbPath.length}`);
      return dbPath;
    }
    if (FileUtil.exists(dbPath) && !CallRecordPathUtil.isCallRecorderSandboxPath(dbPath)) {
      return dbPath;
    }
    const fileNames = CallRecordPathUtil.collectCandidateNames(dbPath, recordData);
    const searchDirs = await CallRecordPathUtil.collectSearchDirs(context);
    for (const dir of searchDirs) {
      for (const name of fileNames) {
        const candidatePath = `${dir}/${name}`;
        if (FileUtil.exists(candidatePath)) {
          LogUtil.info(`${TAG} [RecordChain] resolvePlayPath hit, path length:${candidatePath.length}`);
          return candidatePath;
        }
      }
    }
    const scanned = await CallRecordPathUtil.scanDirsForMatch(searchDirs, recordData, fileNames);
    if (scanned !== '') {
      LogUtil.info(`${TAG} [RecordChain] resolvePlayPath scan hit, path length:${scanned.length}`);
      return scanned;
    }
    if (CallRecordPathUtil.isCallRecorderSandboxPath(dbPath)) {
      LogUtil.warn(`${TAG} [RecordChain] resolvePlayPath sandbox miss, path length:${dbPath.length}`);
      return '';
    }
    LogUtil.warn(`${TAG} [RecordChain] resolvePlayPath miss, keep dbPath length:${dbPath.length}`);
    return dbPath;
  }

  public static async reconcileRecordPath(context: Context, recordData: RecordData): Promise<boolean> {
    const oldPath = recordData._data ?? '';
    if (!oldPath) {
      return false;
    }
    const resolved = await CallRecordPathUtil.resolvePlayPath(context, recordData);
    if (resolved === '' || resolved === oldPath) {
      return false;
    }
    recordData._data = resolved;
    LogUtil.info(`${TAG} [RecordChain] reconcileRecordPath ok, new path length:${resolved.length}`);
    return true;
  }

  private static async collectSearchDirs(context: Context): Promise<string[]> {
    const dirs: string[] = [PathUtil.CALLRECORD_FILEPATH, EMULATED_CALLRECORD_PATH];
    try {
      const groupPrefix = await context.getGroupDir(CALL_RECORD_GROUP_ID);
      if (groupPrefix) {
        dirs.push(`${groupPrefix}/CallRecord`);
      }
    } catch (err) {
      LogUtil.warn(`${TAG} collectSearchDirs getGroupDir failed, code: ${err?.code}, message: ${err?.message}`);
    }
    const uniqueDirs: string[] = [];
    for (const dir of dirs) {
      if (dir && dir !== '' && uniqueDirs.indexOf(dir) < 0) {
        uniqueDirs.push(dir);
      }
    }
    return uniqueDirs;
  }

  private static async scanDirsForMatch(dirs: string[], recordData: RecordData,
    candidateNames: string[]): Promise<string> {
    const phone = CallRecordPathUtil.normalizePhone(recordData.phoneNumber);
    const title = recordData.title ?? '';
    const name = recordData.name ?? '';
    const contacts = recordData.contacts ?? '';
    for (const dir of dirs) {
      if (!FileUtil.exists(dir)) {
        continue;
      }
      let files: string[] = [];
      try {
        files = await FileUtil.scanAudioAs(dir);
      } catch (err) {
        LogUtil.warn(`${TAG} scanDirsForMatch list failed dir length:${dir.length}, ` +
          `code: ${err?.code}, message: ${err?.message}`);
        continue;
      }
      for (const filePath of files) {
        const base = PathUtil.filename(filePath);
        for (const cand of candidateNames) {
          if (base === cand) {
            return filePath;
          }
        }
        if (title !== '' && base.includes(title)) {
          return filePath;
        }
        if (name !== '' && name !== '0' && base.includes(name)) {
          return filePath;
        }
        if (contacts !== '' && base.includes(contacts)) {
          return filePath;
        }
        if (phone.length >= 4) {
          const tail = phone.slice(-4);
          if (base.includes(tail)) {
            return filePath;
          }
        }
      }
    }
    return '';
  }

  private static normalizePhone(phoneNumber: string | undefined): string {
    if (!phoneNumber || phoneNumber === '0') {
      return '';
    }
    return phoneNumber.replace(/\D/g, '');
  }

  private static collectCandidateNames(dbPath: string, recordData: RecordData): string[] {
    const names: string[] = [];
    const pushName = (name: string | undefined) => {
      if (!name || name === '') {
        return;
      }
      const baseName = PathUtil.filename(name);
      if (baseName !== '' && names.indexOf(baseName) < 0) {
        names.push(baseName);
      }
    };
    pushName(dbPath);
    pushName(recordData.name);
    pushName(recordData.title);
    pushName(recordData.contacts);
    return names;
  }

  public static isCallRecorderSandboxPath(path: string): boolean {
    return path.includes(CALL_RECORDER_BUNDLE) || path.includes('/haps/entry/files/CallRecord');
  }

  public static isMediaUriPath(path: string): boolean {
    return path.startsWith('file://');
  }
}
