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
import { Driver, ON } from '@ohos.UiTest';
import { LogUtil } from '@ohos/common';
import { Delay, Director, Keyword, } from '@ohos/common/test';

const TAG: string = 'SoundRecorder_EditRecordTest';

export default function EditRecordTest() {
  describe('EditRecordTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:EditRecordTest_001
    * @tc.name: 编辑录音
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录制过程中标记
    */
    it('EditRecordTest_001', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);

      // 点击标记
      await dr.assertComponentExist(ON.id('markBtn'));
      let playMarkBtn = await dr.waitForComponent(ON.id('markBtn'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_001 end');
    });

    it('EditRecordTest_002', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);

      // 点击标记
      await dr.assertComponentExist(ON.id('markBtn'));
      let playMarkBtn = await dr.waitForComponent(ON.id('markBtn'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      const list = await dr.waitForComponent(ON.id('markNameText'), Delay.S_1);
      const rect = await list.getBounds();
      let y = Math.floor((rect.bottom - rect.top) / 2);
      LogUtil.info(TAG + ' left: ' + rect.left + ' right: ' + rect.right + ' top: ' + rect.top + ' bottom: ' + rect.bottom);
      await dr.swipe(rect.right, rect.top + y, rect.right + 500, rect.top + y, 600);
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_002 end');
    });

    /*
    * @tc.number:EditRecordTest_003
    * @tc.name: 编辑录音
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放过程中标记
    */
    it('EditRecordTest_003', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' audioList clicked');
      // 点击标记
      await dr.assertComponentExist(ON.id('playMark'));
      let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_003 end');
    });

    it('EditRecordTest_004', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_004 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' audioList clicked');
      // 点击标记
      await dr.assertComponentExist(ON.id('playMark'));
      let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      const list = await dr.waitForComponent(ON.id('markNameText'), Delay.S_1);
      const rect = await list.getBounds();
      let y = Math.floor((rect.bottom - rect.top) / 2);
      LogUtil.info(TAG + ' left: ' + rect.left + ' right: ' + rect.right + ' top: ' + rect.top + ' bottom: ' + rect.bottom);
      await dr.swipe(rect.right, rect.top + y, rect.right + 500, rect.top + y, 600);
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_004 end');
    });

    /*
    * @tc.number:EditRecordTest_005
    * @tc.name: 编辑录音
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录制过程中重命名、删除标记
    */
    it('EditRecordTest_005', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_005 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);

      // 点击标记
      await dr.assertComponentExist(ON.id('markBtn'));
      let setMarkBtn = await dr.waitForComponent(ON.id('markBtn'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await setMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 重命名标记
      let markBadge = await dr.waitForComponent(ON.text(Keyword.MARK), Delay.S_1);
      const newName = Date.now().toString(36);
      await Director.renameRecordMark(TAG, dr, markBadge, newName);
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_005 end');
    });

    it('EditRecordTest_006', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_006 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);

      // 点击标记
      await dr.assertComponentExist(ON.id('markBtn'));
      let setMarkBtn = await dr.waitForComponent(ON.id('markBtn'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await setMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 删除标记
      let markBadge = await dr.waitForComponent(ON.text('标记'), Delay.S_1);
      await Director.deleteRecordMark(TAG, dr, markBadge);
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_006 end');
    });

    /*
    * @tc.number:EditRecordTest_007
    * @tc.name: 编辑录音
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放过程中重命名、删除标记
    */
    it('EditRecordTest_007', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_007 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' audioList clicked');
      // 点击标记
      await dr.assertComponentExist(ON.id('playMark'));
      let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 重命名标记
      let markBadge = await dr.waitForComponent(ON.text(Keyword.MARK), Delay.S_1);
      const newName = Date.now().toString(36);
      await Director.renameRecordMark(TAG, dr, markBadge, newName);
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_007 end');
    });

    it('EditRecordTest_008', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_008 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' audioList clicked');
      // 点击标记
      await dr.assertComponentExist(ON.id('playMark'));
      let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 删除标记
      let markBadge = await dr.waitForComponent(ON.text('标记'), Delay.S_1);
      await Director.deleteRecordMark(TAG, dr, markBadge);
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_008 end');
    });

    it('EditRecordTest_009', 0, async () => {
      LogUtil.info(TAG + ' EditRecordTest_009 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' audioList clicked');
      // 点击标记
      await dr.assertComponentExist(ON.id('playMark'));
      let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
      for (let i = 0; i < 10; i++) {
        await playMarkBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 删除标记
      let markBadge = await dr.waitForComponent(ON.text('标记'), Delay.S_1);
      await markBadge.click();
      await dr.delayMs(Delay.S_1);
      // 关闭录音页
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' EditRecordTest_009 end');
    });
  })
}