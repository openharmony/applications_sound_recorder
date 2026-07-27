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

import { beforeAll, describe, expect, it } from '@ohos/hypium';
import { Driver, ON, UiDirection } from '@ohos.UiTest';
import { LogUtil } from '@ohos/common';
import { Delay, Director, Keyword } from '@ohos/common/test';

const TAG: string = 'SoundRecorder_Record2x2FormTest';

export default function Record2x2FormTest() {
  describe('Record2x2FormTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:Record2x2FormTest_001
    * @tc.name: 录音机卡片2x2创建、录音、文件保存正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片2x2创建、录音、文件保存正常
    */
    it('Record2x2FormTest_001', 0, async () => {
      LogUtil.info(TAG + ' Record2x2FormTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 返回首页
      await dr.pressHome();
      await dr.delayMs(Delay.S_3);
      // 长按录音机
      let longClickBtn = await Director.lookUpStringButton(TAG, dr, '录音机');
      const longClickPoint = await longClickBtn.getBoundsCenter();
      await dr.longClick(longClickPoint.x, longClickPoint.y - 100);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_001 longClick');
      // 选择卡片服务
      let cardBtn = await dr.findComponent(ON.text('卡片'));
      await cardBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x2FormTest_001 cardBtn');
      // 选中2x2
      await dr.assertComponentExist(ON.id('startRecord2x1FaBtn'));
      let cardto2x2Btn = await dr.findComponent(ON.id('startRecord2x1FaBtn'));
      const point = await cardto2x2Btn.getBoundsCenter();
      await dr.swipe(point.x + 200, point.y + 300, point.x - 600, point.y + 300, 600);
      await dr.delayMs(Delay.S_1);
      // 卡片添加至桌面
      const addHomeBtn = await dr.waitForComponent(ON.text('添加至桌面'), Delay.S_1);
      await addHomeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_001 addHomeBtn');
      await Director.lookUpStringButton(TAG, dr, '录音机');
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_001 end');
    });

    /*
    * @tc.number:Record2x2FormTest_002
    * @tc.name: 录音机卡片2x2录音开始、录音结束正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片2x2录音开始、录音结束正常
    */
    it('Record2x2FormTest_002', 0, async () => {
      LogUtil.info(TAG + ' Record2x2FormTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 开始录音
      let startRecordBtn = await Director.lookUpStringCard(TAG, dr, 'recorder2x2FaBtn');
      await startRecordBtn.click();
      await dr.delayMs(Delay.S_5);
      LogUtil.info(TAG + ' Record2x2FormTest_002 startRecordBtn');
      // 结束录音
      await dr.assertComponentExist(ON.id('fa_recordBtn'));
      let endRecordBtn = await dr.waitForComponent(ON.id('fa_recordBtn'), Delay.S_1);
      await endRecordBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x2FormTest_002 endRecordBtn');
      LogUtil.info(TAG + ' Record2x2FormTest_002 end');
    });

    /*
    * @tc.number:Record2x2FormTest_003
    * @tc.name: 录音机卡片进入应用正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片进入应用正常
    */
    it('Record2x2FormTest_003', 0, async () => {
      LogUtil.info(TAG + ' Record2x2FormTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 进入录音机页面
      await dr.assertComponentExist(ON.id('record_fa_2x2_title'));
      let startRecordBtn = await dr.waitForComponent(ON.id('record_fa_2x2_title'), Delay.S_1);
      await startRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_003 startRecordBtn');
      // 返回首页
      await dr.pressHome();
      await dr.delayMs(Delay.S_3);
      // 右滑主页至录音机
      await Director.lookUpStringButton(TAG, dr, '录音机');
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_003 end');
    });

    /*
    * @tc.number:Record2x2FormTest_003
    * @tc.name: 录音机卡片标记、暂停、恢复功能正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片标记、暂停、恢复功能正常
    */
    it('Record2x2FormTest_004', 0, async () => {
      LogUtil.info(TAG + ' Record2x2FormTest_004 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 开始录音
      let startRecordBtn = await Director.lookUpStringCard(TAG, dr, 'recorder2x2FaBtn');
      await startRecordBtn.click();
      await dr.delayMs(Delay.S_5);
      LogUtil.info(TAG + ' Record2x2FormTest_004 startRecordBtn');
      // 暂停录音
      await dr.assertComponentExist(ON.id('fa_resumeBtn'));
      let pauseRecordBtn = await dr.waitForComponent(ON.id('fa_resumeBtn'), Delay.S_1);
      await pauseRecordBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x2FormTest_004 pauseRecordBtn');
      // 恢复录音
      await dr.assertComponentExist(ON.id('fa_resumeBtn'));
      let restartRecordBtn = await dr.waitForComponent(ON.id('fa_resumeBtn'), Delay.S_1);
      await restartRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_004 restartRecordBtn');
      // 标记录音
      await dr.assertComponentExist(ON.id('fa_markBtn'));
      let markRecordBtn = await dr.waitForComponent(ON.id('fa_markBtn'), Delay.S_1);
      await markRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_004 markRecordBtn');
      // 结束录音
      await dr.assertComponentExist(ON.id('fa_recordBtn'));
      let endRecordBtn = await dr.waitForComponent(ON.id('fa_recordBtn'), Delay.S_1);
      await endRecordBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x2FormTest_004 end');
    });

    /*
    * @tc.number:Record2x2FormTest_003
    * @tc.name: 录音机主页、2x2卡片状态是否同步
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机主页、2x2卡片状态是否同步
    */
    it('Record2x2FormTest_005', 0, async () => {
      LogUtil.info(TAG + ' Record2x2FormTest_005 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 开始录音
      let startRecordBtn = await Director.lookUpStringCard(TAG, dr, 'recorder2x2FaBtn');
      await startRecordBtn.click();
      await dr.delayMs(Delay.S_5);
      LogUtil.info(TAG + ' Record2x2FormTest_005 startRecordBtn');
      // 暂停录音
      let pauseRecordBtn = await dr.waitForComponent(ON.id('fa_resumeBtn'), Delay.S_1);
      await pauseRecordBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x2FormTest_005 pauseRecordBtn');
      // 进入主页
      let clickRecordBtn = await dr.waitForComponent(ON.id('record_fa_2x2_recording'), Delay.S_1);
      await clickRecordBtn.click();
      await dr.delayMs(Delay.S_3);
      await dr.assertComponentExist(ON.id('resumeBtn'));
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_005 clickRecordBtn');
      // 返回首页
      await dr.pressHome();
      await dr.delayMs(Delay.S_3);
      // 恢复录音
      let restartRecordBtn = await Director.lookUpStringCard(TAG, dr, 'fa_resumeBtn');
      await restartRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_005 restartRecordBtn');
      // 标记录音
      let markRecordBtn = await dr.waitForComponent(ON.id('fa_markBtn'), Delay.S_1);
      await markRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x2FormTest_005 markRecordBtn');
      // 进入主页
      let wRecordBtn = await dr.waitForComponent(ON.id('record_fa_2x2_recording'), Delay.S_1);
      await wRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.MARK));
      LogUtil.info(TAG + ' Record2x2FormTest_005 assert markRecordBtn');
      // 结束录音
      let endRecordBtn = await dr.waitForComponent(ON.id('recordBtn'), Delay.S_1);
      await endRecordBtn.click();
      await dr.delayMs(Delay.S_5);
      LogUtil.info(TAG + ' Record2x2FormTest_005 end');
    });
  });
}