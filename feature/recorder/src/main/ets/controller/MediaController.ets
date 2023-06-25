/**
 * Copyright (c) 2022 HiHope Open Source Organization.
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

import mediaLibrary from '@ohos.multimedia.mediaLibrary';
import { Util } from '@ohos/common';
import { RecordData } from '../model/RecordData';
import data_preferences from '@ohos.data.preferences';
import { LogUtil } from '@ohos/common';

const TAG = 'MediaController : ';

class MediaController {
  private mMediaLibrary: mediaLibrary.MediaLibrary = mediaLibrary.getMediaLibrary(globalThis.abilityContext);
  private preferences: data_preferences.Preferences = undefined;

  constructor() {
    this.initPreferences();
  }

  /**
   * delete Record
   *
   * @param deleteRecordUri
   * @param callback
   */
  deleteRecord(deleteRecordUri: string, callback: () => void) {
    LogUtil.info(`${TAG} delete Asset. uri: ${deleteRecordUri}`)
    this.mMediaLibrary.deleteAsset(deleteRecordUri).then(() => {
      LogUtil.info(`${TAG} delete Asset successs.`);
      callback();
    });
  }

  /**
   * init Preferences
   */
  async initPreferences() {
    LogUtil.info(`${TAG} initPreferences.`);
    this.preferences = await data_preferences.getPreferences(globalThis.abilityContext, 'myRecorderStore');
  }

  /**
   * save File Duration to preferences
   *
   * @param name
   * @param value
   */
  async saveFileDuration(name: string, value: number) {
    LogUtil.info(`${TAG} saveFileDuration. fileName : ${name}. duration:${value}`);
    if (this.preferences) {
      await this.preferences.put(name, value);
      this.preferences.flush();
      LogUtil.info(`${TAG} save File Duration end.`);
    }
  }

  /**
   * get File Duration from preferences
   *
   * @param name
   */
  async getFileDuration(name: string) {
    LogUtil.info(`${TAG} getFileDuration. fileName : ${name}.`);
    return this.preferences.get(name, 0);
  }

  /**
   * query All Audios
   */
  async queryAllAudios() {
    LogUtil.info(`${TAG} queryAllAudios`);
    let fileKeyObj = mediaLibrary.FileKey;
    let fetchOp = {
      selections: `${fileKeyObj.MEDIA_TYPE}=?`,
      selectionArgs: [`${mediaLibrary.MediaType.AUDIO}`],
    }
    LogUtil.info(`${TAG} getFileAssets`);
    const fetchFileResult = await this.mMediaLibrary.getFileAssets(fetchOp);
    LogUtil.info(`${TAG} Assets count : ${fetchFileResult.getCount()}`);
    let result: Array<RecordData> = [];
    if (fetchFileResult.getCount() > 0) {
      let fileAssets = await fetchFileResult.getAllObject();
      for (let i = 0; i < fileAssets.length; i++) {
        let record = new RecordData(fileAssets[i]);
        if (record.duration == 0) {
          await record.getDuration();
        }
        result.push(record);
      }
    }
    return result;
  }

  /**
   * create Audio File
   */
  async createAudioFile() {
    LogUtil.info(`${TAG} createAudioFile`);
    this.mMediaLibrary = mediaLibrary.getMediaLibrary(globalThis.abilityContext);
    let displayName = Util.getDate() + "_" + Util.getTime() + ".m4a";
    LogUtil.info(`${TAG} displayName : ${displayName}`);
    let publicPath = await this.mMediaLibrary.getPublicDirectory(mediaLibrary.DirectoryType.DIR_AUDIO);
    LogUtil.info(`${TAG} publicPath : ${publicPath}`);
    return await this.mMediaLibrary.createAsset(mediaLibrary.MediaType.AUDIO, displayName, publicPath);
  }
}

export default new MediaController();