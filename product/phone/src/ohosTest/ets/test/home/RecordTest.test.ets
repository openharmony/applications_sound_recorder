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
import { Delay, Director, Keyword } from '@ohos/common/test';
import { abilityDelegatorRegistry } from '@kit.TestKit';

const TAG: string = 'SoundRecorder_RecordTest';
const delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();

export default function RecordTest() {
  describe('RecordTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 返回首页
      await dr.pressHome();
      await dr.delayMs(Delay.S_1);
      await dr.swipe(900, 2250, 200, 2250, 10000);
      await dr.delayMs(Delay.S_3);
      // 触发小文件夹提示窗
      let knownBUtton = await dr.waitForComponent(ON.text(Keyword.KNOWN), Delay.S_1);
      if (knownBUtton) {
        await knownBUtton.click();
      }
      await dr.delayMs(Delay.S_1);
      await dr.pressHome();

      // 进入设置
      let settingsButton = await Director.lookUpStringButton('TestAbility', dr, Keyword.APP_SETTINGS);
      LogUtil.info(`${TAG} settingsButton found!`)
      const ClickPoint = await settingsButton.getBoundsCenter();
      LogUtil.info(`${TAG} x : ${ClickPoint.x}, y : ${ClickPoint.y}`);
      await dr.click(ClickPoint.x, ClickPoint.y - 100);
      LogUtil.info(`${TAG} settingsButton click !`)
      await dr.delayMs(Delay.S_1);
      // 列表上滑，找搜索框
      await dr.swipe(500, 500, 500, 1500, 10000);
      await dr.delayMs(Delay.S_1);
      let searcgFiled = await dr.waitForComponent(ON.id('__SearchField__homPageSearchInput'), Delay.S_1);
      await searcgFiled.click();
      await dr.delayMs(Delay.S_1);
      // 触发输入法授权页面
      let agreeBUtton = await dr.waitForComponent(ON.text(Keyword.AGREE), Delay.S_1);
      if (agreeBUtton) {
        await agreeBUtton.click();
      }
      await dr.delayMs(Delay.S_1);
      // 点击选择9键
      await dr.click(1119, 1454);
      await dr.delayMs(Delay.S_1);
      let nextBUtton = await dr.waitForComponent(ON.text(Keyword.NEXT_STEP), Delay.S_1);
      if (nextBUtton) {
        await nextBUtton.click();
      }
      await dr.delayMs(Delay.S_1);
      // 返回到设置首页
      await dr.pressBack();
      await dr.delayMs(Delay.S_1);

      // 下滑列表，找到应用和元服务组件
      await dr.swipe(500, 2000, 500, 500, 10000);
      await dr.delayMs(Delay.S_1);
      let appAndServicbutton = await dr.waitForComponent(ON.id('application_and_service_settings.title'), Delay.S_1);
      await appAndServicbutton.click();
      await dr.delayMs(Delay.S_1);
      // 下滑列表，找到未成年人模式
      await dr.swipe(500, 2000, 500, 300, 5000);
      await dr.delayMs(Delay.S_3);
      let childrenMode = await dr.waitForComponent(ON.text(Keyword.CHILD_MODE), Delay.S_1);
      await childrenMode.click();
      await dr.delayMs(Delay.S_1);
      let NotificationSet= await dr.waitForComponent(ON.text(Keyword.NOTIFICATION), Delay.S_1);
      await NotificationSet.click();
      await dr.delayMs(Delay.S_1);
      let topNotification= await dr.waitForComponent(ON.text(Keyword.TOP_SHOW_NOTIFICATION), Delay.S_1);
      await dr.delayMs(Delay.S_1);
      // 如果有topNotification，则说明允许通知开启，需要点击关闭开关
      if (topNotification) {
        await dr.click(1110, 708);
      }
      await dr.pressBack();
      await dr.delayMs(Delay.S_1);
      await dr.pressBack();
      await dr.delayMs(Delay.S_1);
      await dr.pressBack();
      await dr.delayMs(Delay.S_1);
      await dr.swipe(500, 500, 500, 1500, 10000);
      await dr.delayMs(Delay.S_1);
      await dr.pressHome();
      await dr.delayMs(Delay.S_1);
      // 打开录音机
      const bundleName = abilityDelegatorRegistry.getArguments().bundleName;
      const want: Want = {
        bundleName: bundleName,
        abilityName: 'MainAbility'
      };
      await delegator.startAbility(want);

      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:RecordTest_001
    * @tc.name: 录音分享、删除、全选、更多验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音分享、删除、全选、更多正常
    */
    it('RecordTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_5);
      // 长按操作
      let top1 = await Director.getTop1AudioItem(dr);
      await top1.longClick();
      await dr.delayMs(Delay.S_1);

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
      }

      // 退出编辑模式
      LogUtil.info(TAG + ' quitBtn clicked');
      let quitBtn = await dr.findComponent(ON.id('cancelBtn'));
      await quitBtn.click();
      await dr.delayMs(Delay.S_5);

      top1 = await Director.getTop1AudioItem(dr);
      await top1.longClick();
      // 点击分享
      let shareBtn = await dr.waitForComponent(ON.text(Keyword.SHARE), Delay.S_1);
      await shareBtn.click();
      LogUtil.info(TAG + ' shareBtn clicked');
      await dr.delayMs(Delay.S_1);
      // 效验分享页面
      await dr.assertComponentExist(ON.text(Keyword.SHARE));
      await Director.closeShareModal(TAG, dr);
      // 点击删除
      top1 = await Director.getTop1AudioItem(dr);
      await top1.longClick();
      let deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deletionBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deletionBtn clicked');
      // 效验删除弹窗
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' cancelBtn clicked');

      // 点击详情
      top1 = await Director.getTop1AudioItem(dr);
      await top1.longClick();
      let detailsBtn = await dr.waitForComponent(ON.text(Keyword.DETAIL), Delay.S_1);
      await detailsBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' detailsBtn clicked');
      // 效验详情弹窗
      await dr.assertComponentExist(ON.text(Keyword.CLOSE));
      let closeBtn = await dr.waitForComponent(ON.text(Keyword.CLOSE), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      // 校验重命名弹窗
      top1 = await Director.getTop1AudioItem(dr);
      await top1.longClick();
      await dr.assertComponentExist(ON.text(Keyword.RENAME));
      let reNameBtn = await dr.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
      await reNameBtn.click();
      await Director.checkInputMethodPopUp(TAG, dr);
      await dr.delayMs(Delay.S_1);
      let cancelRenameBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelRenameBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' cancelRenameBtn clicked');

      // 重新重命名
      top1 = await Director.getTop1AudioItem(dr);
      await top1.longClick();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' morelBtn clicked');
      let renameBtn = await dr.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
      await renameBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' renameBtn clicked');
      let renameResult = await dr.waitForComponent(ON.type('TextInput'), Delay.S_5);
      await renameResult.inputText(Date.now().toString(36));
      let confirmRenameBtn = await dr.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
      await confirmRenameBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmRenameBtn clicked');
      LogUtil.info(TAG + ' RecordTest_001 end');
    });

    /*
    * @tc.number:RecordTest_002
    * @tc.name: 录音分享、删除验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音分享、删除正常
    */
    it('RecordTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      const top1 = await Director.getTop1AudioItem(dr);
      const point = await top1.getBoundsCenter();
      // 左滑音频
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 点击分享按钮
      let ShareTab = await dr.waitForComponent(ON.id('indexShare'), Delay.S_1);
      await ShareTab.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' ShareTab clicked');
      // 校验分享页面
      await dr.assertComponentExist(ON.text(Keyword.SHARE));
      await Director.closeShareModal(TAG, dr);
      // 左滑音频
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 点击删除按钮
      await Director.clickSwipeDelBtn(TAG, top1, dr);
      // 校验删除弹窗,点击取消按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      let cancelsBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelsBtn.click();
      LogUtil.info(TAG + ' cancelsBtn clicked');
      await dr.delayMs(Delay.S_1);
      // 左滑音频
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 左滑点击删除按钮
      await Director.clickSwipeDelBtn(TAG, top1, dr);
      // 校验删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      let confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await confirmBtn.click();
      LogUtil.info(TAG + ' confirmBtn clicked');

      LogUtil.info(TAG + ' RecordTest_002 end');
    });
  })
}
