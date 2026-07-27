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

const TAG: string = 'SoundRecorder_Record2x1FormTest';

export default function Record2x1FormTest() {
  describe('Record2x1FormTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:Record2x1FormTest_001
    * @tc.name: 录音机卡片2x1创建、录音、文件保存正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片2x1创建、录音、文件保存正常
    */
    it('Record2x1FormTest_001', 0, async () => {
      LogUtil.info(TAG + ' Record2x1FormTest_001 start');
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
      await dr.assertComponentExist(ON.text('卡片'));
      let cardBtn = await dr.findComponent(ON.text('卡片'));
      await cardBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x1FormTest_001 cardBtn');
      // 卡片添加至桌面
      await dr.assertComponentExist(ON.text('添加至桌面'));
      const addHomeBtn = await dr.waitForComponent(ON.text('添加至桌面'), Delay.S_1);
      await addHomeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x1FormTest_001 addHomeBtn');
      //
      await Director.lookUpStringButton(TAG, dr, '录音机');
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x1FormTest_001 end');
    });

    /*
    * @tc.number:Record2x1FormTest_002
    * @tc.name: 录音机卡片2x1录音开始、录音结束正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片2x1录音开始、录音结束正常
    */
    it('Record2x1FormTest_002', 0, async () => {
      LogUtil.info(TAG + ' Record2x1FormTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 开始录音
      await dr.assertComponentExist(ON.id('startRecord2x1FaBtn'));
      let startRecordBtn = await Director.lookUpStringCard(TAG, dr, 'startRecord2x1FaBtn');
      await startRecordBtn.click();
      await dr.delayMs(Delay.S_5);
      LogUtil.info(TAG + ' Record2x1FormTest_002 startRecord2x1FaBtn');
      // 结束录音
      await dr.assertComponentExist(ON.id('endRecord2x1FaBtn'));
      let endRecordBtn = await dr.waitForComponent(ON.id('endRecord2x1FaBtn'), Delay.S_1);
      await endRecordBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' Record2x1FormTest_002 end');
    });

    /*
    * @tc.number:Record2x1FormTest_003
    * @tc.name: 录音机卡片进入应用正常
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机卡片进入应用正常
    */
    it('Record2x1FormTest_003', 0, async () => {
      LogUtil.info(TAG + ' Record2x1FormTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 进入录音机页面
      await dr.assertComponentExist(ON.id('record_fa_2x1_title'));
      let startRecordBtn = await Director.lookUpStringCard(TAG, dr, 'record_fa_2x1_title');
      await startRecordBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' Record2x1FormTest_003 end');
    });
  });
}