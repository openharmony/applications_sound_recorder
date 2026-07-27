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
import { beforeAll, describe, it } from '@ohos/hypium';
import { Driver, ON } from '@kit.TestKit';
import { AnonymousUtil, ConfigData, LogUtil } from '@ohos/common';
import { Delay, Director, Keyword } from '@ohos/common/test';
import { AvSessionManager, RecordManager } from '@ohos/recorder';
import { media } from '@kit.MediaKit';
import fs from '@ohos.file.fs';

const TAG = 'SoundRecorder_AudioRecordItemComponentTest';

const recorderStateCallback = async () => {
};

const onErrorCallback = () => {
};

export default function AudioRecordItemComponentTest() {
  describe('AudioRecordItemComponentTest', () => {
    beforeAll(async () => {
      await AudioRecordItemComponentTestBefore();
    });
    it('AudioRecordItemComponentTest_01', 0, async () => {
      await AudioRecordItemComponentTestPart1();
    });
    it('AudioRecordItemComponentTest_02', 0, async () => {
      await AudioRecordItemComponentTestPart2();
    });
    it('AudioRecordItemComponentTest_03', 0, async () => {
      await AudioRecordItemComponentTestPart3();
    });
  })
}

async function AudioRecordItemComponentTestBefore(): Promise<void> {
  const dr: Driver = Driver.create();
  await Director.startRecording(TAG, dr);
  await dr.delayMs(Delay.S_5)
  await Director.stopRecording(TAG, dr);
}

async function AudioRecordItemComponentTestPart1(): Promise<void> {
  //列表页播放
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_01 start');
  const dr: Driver = Driver.create();
  // 点击播放
  let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.MS_200);
  if (playBtn) {
    await playBtn.click();
    LogUtil.info(TAG + ' playBtn clicked');
    await dr.delayMs(Delay.S_1);
    //暂停
    await playBtn.click();
    LogUtil.info(TAG + ' playBtn pause clicked');
    await dr.delayMs(Delay.MS_200);
    //继续播放
    await dr.assertComponentExist(ON.id('playBtn'));
    await playBtn.click();
    LogUtil.info(TAG + ' playBtn play clicked');
    await dr.delayMs(Delay.S_5);
    LogUtil.info(TAG + ' AudioRecordItemComponentTest_01 end');
  }
}

async function AudioRecordItemComponentTestPart2(): Promise<void> {
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_02 start');
  const dr: Driver = Driver.create();
  // 点击进入播放详情页
  let list = await dr.findComponents(ON.type('ListItem'));
  await Director.clickAudioItem(dr, list[1]);
  //进入播放页面
  LogUtil.info(TAG + ' audioList clicked');
  // 暂停
  let playBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
  await playBtn.click();
  await dr.delayMs(Delay.MS_200);
  // 倍速播放
  let doubleSpeedBtn = await dr.waitForComponent(ON.id('doubleSpeed'), Delay.S_1);
  await doubleSpeedBtn.click();
  LogUtil.info(TAG + ' doubleSpeedBtn clicked');
  // 点击标记
  let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
  await dr.delayMs(Delay.S_1);
  await playMarkBtn.click();
  LogUtil.info(TAG + ' playMarkBtn clicked');
  // 删除标记
  const markBadge = await dr.waitForComponent(ON.text(Keyword.MARK), Delay.S_1);
  await Director.deleteRecordMark(TAG, dr, markBadge);
  // 继续播放
  await dr.assertComponentExist(ON.id('playPause'));
  let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
  await playPauseBtn.click();
  await dr.delayMs(Delay.S_3);
  LogUtil.info(TAG + ' playPauseBtn clicked');

  AvSessionManager.getInstance().seek(0);
  LogUtil.info(TAG + ' AvSessionManager seek');
  // 返回上一页
  await dr.pressBack();
  await dr.delayMs(Delay.S_1);
  LogUtil.info(TAG + ' backPage clicked');
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_02 end');
}

async function AudioRecordItemComponentTestPart3(): Promise<void> {
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_03 start');
  const dr: Driver = Driver.create();
  await dr.delayMs(Delay.MS_200);

  //写入录音文件
  await writeFile(recorderStateCallback, onErrorCallback, dr);

  // 点击录音
  let recordButton = await dr.waitForComponent(ON.id('recorderBtn'), Delay.S_1);
  await recordButton.click();
  await dr.delayMs(Delay.S_1);

  //结束录音
  await dr.assertComponentExist(ON.id('recordBtn'));
  let endRecordBtn = await dr.waitForComponent(ON.id('recordBtn'), Delay.S_1);
  AppStorage.setOrCreate('jumpFromContacts', true);
  LogUtil.info(TAG + ' setOrCreate jumpFromContacts true');
  await endRecordBtn.click();
  LogUtil.info(TAG + ' endRecordBtn clicked');

  await dr.delayMs(Delay.S_3);
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_03 end');
}

async function writeFile(recorderStateCallback: () => Promise<void>, onErrorCallback: () => void, dr: Driver) {
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_03 start write file');
  const recordManager = RecordManager.getInstance();
  await recordManager.initAvRecorder();
  let avProfile: media.AVRecorderProfile = {
    audioBitrate: 100000,
    audioChannels: 2,
    audioCodec: media.CodecMimeType.AUDIO_AAC,
    audioSampleRate: 48000,
    fileFormat: media.ContainerFormatType.CFT_MPEG_4A, // 封装格式，当前只支持m4a
  };
  let filesDir = '/data/storage/el2/base/haps/phone/files';
  let fileName = new Date().getTime().toString();
  let filePath = filesDir + '/' + fileName + ConfigData.FileType;
  LogUtil.info(TAG + ' writeFile fileName : ' + AnonymousUtil.anonymous(fileName));
  try {
    let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
    let avConfig: media.AVRecorderConfig = {
      audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
      profile: avProfile,
      url: `fd://${file.fd}`
    };
    recordManager.setAvRecorderConfig(TAG, file.fd,
      filePath, avConfig, recorderStateCallback, onErrorCallback);
    await dr.delayMs(Delay.MS_200);
    recordManager.start();
    await dr.delayMs(Delay.S_3);
    recordManager.pause();
    recordManager.release();
  } catch (error) {
    LogUtil.error(TAG + ' open file error : ' + error);
  }
  await dr.delayMs(Delay.S_1);
  LogUtil.info(TAG + ' AudioRecordItemComponentTest_03 end write file');
}
