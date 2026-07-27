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

const TAG: string = 'SoundRecorder_RecordMoreMenuPageTest';

export default function RecordMoreMenuPageTest() {
  describe('RecordMoreMenuPageTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });
    /*
    * @tc.number:RecordMoreMenuPageTest_001
    * @tc.name: 更多界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 更多界面
    */
    it('RecordMoreMenuPageTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 回到主页
      await moreBtn.click();
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_001 end');
    });

    /*
    * @tc.number:RecordMoreMenuPageTest_002
    * @tc.name: 更多界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 更多界面多选验证
    */
    it('RecordMoreMenuPageTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击多选
      let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.MULTI_SELECT));
      await floatMenuMultiSelect.click();
      await dr.delayMs(Delay.S_1);
      // 点击取消全选
      let selectAllBtn = await dr.waitForComponent(ON.text(Keyword.DESELECT_ALL), Delay.S_1);
      if (selectAllBtn) {
        await selectAllBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' cancelSelectAllBtn clicked');
        await dr.delayMs(Delay.S_1);
        selectAllBtn = await dr.waitForComponent(ON.text(Keyword.SELECT_ALL), Delay.S_1);
        await selectAllBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' selectAllBtn clicked');
      } else {
        selectAllBtn = await dr.waitForComponent(ON.text(Keyword.SELECT_ALL), Delay.S_1);
        await selectAllBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      // 关闭页面
      await dr.assertComponentExist(ON.id('cancelBtn'));
      let closeBtn = await dr.waitForComponent(ON.id('cancelBtn'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_002 end');
    });

    /*
    * @tc.number:RecordMoreMenuPageTest_003
    * @tc.name: 更多界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 更多界面关于、隐私声明、个人信息清单功能验证
    */
    it('RecordMoreMenuPageTest_003', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击关于
      await dr.assertComponentExist(ON.text('关于'));
      let aboutBtn = await dr.waitForComponent(ON.text('关于'), Delay.S_1);
      await aboutBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' aboutBtn clicked');
      // 关闭页面
      let point = await dr.getDisplaySize();
      await dr.swipe(0, point.y - 800, 500, point.y - 800, 10000);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_003 end');
    });

    it('RecordMoreMenuPageTest_004', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_004 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击关于
      await dr.assertComponentExist(ON.text('隐私声明'));
      let aboutBtn = await dr.waitForComponent(ON.text('隐私声明'), Delay.S_1);
      await aboutBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' aboutBtn clicked');
      // 关闭页面
      let point = await dr.getDisplaySize();
      await dr.swipe(0, point.y - 800, 500, point.y - 800, 10000);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_004 end');
    });

    it('RecordMoreMenuPageTest_005', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_005 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击关于
      await dr.assertComponentExist(ON.text('收集个人信息清单'));
      let aboutBtn = await dr.waitForComponent(ON.text('收集个人信息清单'), Delay.S_1);
      await aboutBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' aboutBtn clicked');
      // 关闭页面
      let point = await dr.getDisplaySize();
      await dr.swipe(0, point.y - 800, 500, point.y - 800, 10000);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_005 end');
    });

    /*
    * @tc.number:RecordMoreMenuPageTest_006
    * @tc.name: 更多界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 更多界面排序功能验证
    */
    it('RecordMoreMenuPageTest_006', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_006 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击关于
      await dr.assertComponentExist(ON.text('排序'));
      let aboutBtn = await dr.waitForComponent(ON.text('排序'), Delay.S_1);
      await aboutBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' aboutBtn clicked');
      // 排序
      await dr.assertComponentExist(ON.id('sort_time_desc'));
      let sortBtn = await dr.waitForComponent(ON.id('sort_time_desc'), Delay.S_1);
      await sortBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' sortBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_006 end');
    });

    it('RecordMoreMenuPageTest_007', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_007 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击关于
      await dr.assertComponentExist(ON.text('排序'));
      let aboutBtn = await dr.waitForComponent(ON.text('排序'), Delay.S_1);
      await aboutBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' aboutBtn clicked');
      // 排序
      await dr.assertComponentExist(ON.id('sort_time_desc'));
      let sortBtn = await dr.waitForComponent(ON.id('sort_time_asc'), Delay.S_1);
      await sortBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' sortBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_007 end');
    });

    it('RecordMoreMenuPageTest_008', 0, async () => {
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_008 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击关于
      await dr.assertComponentExist(ON.text('排序'));
      let aboutBtn = await dr.waitForComponent(ON.text('排序'), Delay.S_1);
      await aboutBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' aboutBtn clicked');
      // 排序
      await dr.assertComponentExist(ON.id('sort_name'));
      let sortBtn = await dr.waitForComponent(ON.id('sort_name'), Delay.S_1);
      await sortBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' sortBtn clicked');
      LogUtil.info(TAG + ' RecordMoreMenuPageTest_008 end');
    });
  })
}