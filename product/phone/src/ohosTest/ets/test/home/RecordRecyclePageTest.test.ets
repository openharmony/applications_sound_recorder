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
import { Director } from '@ohos/common/src/ohosTest/ets/Director';
import { Delay } from '@ohos/common/src/ohosTest/ets/Delay';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { Keyword } from '@ohos/common/src/ohosTest/ets/Keyword';

const TAG = 'SoundRecorder_RecyclePageSoundRecordTest';

export default function RecordRecyclePageTest() {
  describe('RecordRecyclePageTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });

    /**
     * 验证录音、通话录音、最近删除页面切换
     */
    it('RecordRecyclePageTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);

      // 进入最近删除页面
      let sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.RECENTLY_DELETED));
      let recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);

      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_001 end');
    });

    it('RecordRecyclePageTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);

      // 进入通话录音页面
      let sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.CALL_RECORDING));
      let recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.CALL_RECORDING), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);

      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_002 end');
    });

    /*
    * @tc.number:RecordRecyclePageTest_003
    * @tc.name: 最近删除界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 最近删除界面悬浮菜单功能验证
    */
    it('RecordRecyclePageTest_003', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.MULTI_SELECT));
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
      // 退出全选模式
      LogUtil.info(TAG + ' quitBtn clicked');
      let quitBtn = await dr.findComponent(ON.id('cancelBtn'));
      await quitBtn.click();
      await dr.delayMs(Delay.S_1);
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_003 end');
    });

    it('RecordRecyclePageTest_004', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_004 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      // 点击永久删除
      let deleteBtn = await dr.findComponent(ON.text(Keyword.RECORDING_DELETE));
      await deleteBtn.click();
      await dr.delayMs(Delay.S_3);
      // 校验永久删除弹窗,点击取消按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' cancelBtn clicked');
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_004 end');
    });

    it('RecordRecyclePageTest_005', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_005 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      // 点击永久删除
      let deleteBtn = await dr.findComponent(ON.text(Keyword.RECORDING_DELETE));
      await deleteBtn.click();
      await dr.delayMs(Delay.S_3);
      // 校验永久删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' cancelBtn clicked');
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_005 end');
    });

    it('RecordRecyclePageTest_006', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_006 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      // 点击恢复
      await dr.assertComponentExist(ON.text(Keyword.RESTORE));
      let deleteBtn = await dr.findComponent(ON.text(Keyword.RESTORE));
      await deleteBtn.click();
      await dr.delayMs(Delay.S_3);
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_006 end');
    });

    it('RecordRecyclePageTest_007', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_007 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      // 多选
      await dr.assertComponentExist(ON.text(Keyword.MULTI_SELECT));
      let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.MULTI_SELECT));
      await floatMenuMultiSelect.click();
      await dr.delayMs(Delay.S_1);
      // 删除
      await dr.assertComponentExist(ON.text(Keyword.DELETE));
      let deleteBtn = await dr.findComponent(ON.text(Keyword.DELETE));
      await deleteBtn.click();
      await dr.delayMs(Delay.S_3);
      // 校验永久删除弹窗,点击取消按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' cancelBtn clicked');
      // 退出全选模式
      LogUtil.info(TAG + ' quitBtn clicked');
      let quitBtn = await dr.findComponent(ON.id('cancelBtn'));
      await quitBtn.click();
      await dr.delayMs(Delay.S_1);
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_007 end');
    });

    it('RecordRecyclePageTest_008', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_008 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.MULTI_SELECT));
      let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.MULTI_SELECT));
      await floatMenuMultiSelect.click();
      await dr.delayMs(Delay.S_1);
      // 点击恢复
      await dr.assertComponentExist(ON.text(Keyword.RESTORE));
      let deleteBtn = await dr.findComponent(ON.text(Keyword.RESTORE));
      await deleteBtn.click();
      await dr.delayMs(Delay.S_3);
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_008 end');
    });

    /*
    * @tc.number:RecordRecyclePageTest_009
    * @tc.name: 最近删除界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 最近删除界面左滑菜单功能验证
    */
    it('RecordRecyclePageTest_009', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_009 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 左滑音频
      let topItem = await Director.getFirstAudioItem(dr);
      let point = await topItem.getBoundsCenter();
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 左滑点击恢复按钮
      await dr.assertComponentExist(ON.id('recentDeleteRecover'));
      let restoreTab = await dr.waitForComponent(ON.id('recentDeleteRecover'), Delay.S_1);
      await restoreTab.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' restoreTab clicked');
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_009 end');
    });

    it('RecordRecyclePageTest_010', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_010 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 左滑音频
      let topItem = await Director.getFirstAudioItem(dr);
      let point = await topItem.getBoundsCenter();
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 点击永久删除按钮
      await Director.clickSwipeDelBtn(TAG, topItem, dr);
      // 校验永久删除弹窗,点击取消按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' cancelBtn clicked');
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_010 end');
    });

    it('RecordRecyclePageTest_011', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_011 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 左滑音频
      let topItem = await Director.getFirstAudioItem(dr);
      let point = await topItem.getBoundsCenter();
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 点击永久删除按钮
      await Director.clickSwipeDelBtn(TAG, topItem, dr);
      // 校验永久删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' cancelBtn clicked');
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_011 end');
    });

    /*
    * @tc.number:RecordRecyclePageTest_012
    * @tc.name: 最近删除界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 最近删除界面更多菜单功能验证
    */
    it('RecordRecyclePageTest_012', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_012 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      // 回到主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_012 end');
    });

    it('RecordRecyclePageTest_013', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_013 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
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
      let closeBtn = await dr.waitForComponent(ON.id('cancelBtn'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      // 回到主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_013 end');
    });

    it('RecordRecyclePageTest_014', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_014 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击全部删除
      let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.DELETE_ALL));
      await floatMenuMultiSelect.click();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_1);
      // 回到主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_014 end');
    });

    it('RecordRecyclePageTest_015', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_015 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击全部删除
      let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.DELETE_ALL));
      await floatMenuMultiSelect.click();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_1);
      // 回到主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_015 end');
    });

    it('RecordRecyclePageTest_016', 0, async () => {
      LogUtil.info(TAG + ' RecordRecyclePageTest_016 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 进入删除页面
      await Director.deleteToRecyclePage(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击更多菜单
      await dr.assertComponentExist(ON.id('indexMore'));
      let moreBtn = await dr.waitForComponent(ON.id('indexMore'), Delay.S_1);
      await moreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' moreBtn clicked');
      // 点击全部删除
      let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.RESTORE_ALL));
      await floatMenuMultiSelect.click();
      await dr.delayMs(Delay.S_1);
      // 回到主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecyclePageTest_016 end');
    });
  });
}