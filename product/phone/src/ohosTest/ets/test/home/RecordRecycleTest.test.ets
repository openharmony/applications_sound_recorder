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

import { describe, it } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { Director } from '@ohos/common/src/ohosTest/ets/Director';
import { Delay } from '@ohos/common/src/ohosTest/ets/Delay';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';
import { Keyword } from '@ohos/common/src/ohosTest/ets/Keyword';

const TAG = 'SoundRecorder_RecycleSoundRecordTest';

export default function RecordRecycleTest() {
  describe('RecordRecycleTest', () => {
    /**
     * 验证最近删除文件的播放、暂停播放功能
     */
    it('RecordRecycleTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordRecycleTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);

      // 点击删除
      let topItem = await Director.getTop1AudioItem(dr);
      await topItem.longClick();
      await dr.delayMs(Delay.S_1);
      let deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deletionBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deletionBtn clicked');

      // 校验删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      let confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await confirmBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmBtn clicked');

      // 进入最近删除页面
      let sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      let recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);

      // 点击播放
      let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
      await playBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' playBtn clicked');

      // 拖动进度条
      const slider = await dr.findComponent(ON.type('Slider'));
      const rect = await slider.getBounds();
      const p = await slider.getBoundsCenter();
      await dr.fling({
        x: rect.left, y: p.y
      }, {
        x: rect.left + 160, y: p.y
      }, 5, 600);

      // 暂停播放
      playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_5);
      await playBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' playBtn pause clicked');
      // 返回普通录音页面
      sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECORDING), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' RecordRecycleTest_001 end');
    });

    /**
     * 验证最近删除文件的全选、取消全选、恢复、永久删除功能（长按）
     */
    it('RecordRecycleTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordRecycleTest_002 start');
      // 定义Driver类
      let dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);

      // 点击删除
      let topItem = await Director.getTop1AudioItem(dr);
      await topItem.longClick();
      await dr.delayMs(Delay.S_1);
      let deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deletionBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deletionBtn clicked');

      // 校验删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      let confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await confirmBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmBtn clicked');

      // 进入最近删除页面
      let sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      let recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);
      // 长按操作
      let item = await Director.getFirstAudioItem(dr);
      await item.longClick();
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
        await dr.delayMs(Delay.S_1);
      }

      // 退出全选模式
      LogUtil.info(TAG + ' quitBtn clicked');
      let quitBtn = await dr.findComponent(ON.id('cancelBtn'));
      await quitBtn.click();
      await dr.delayMs(Delay.S_5);

      // 长按
      item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);

      // 点击恢复
      let recordingDelete = await dr.findComponent(ON.text(Keyword.RESTORE));
      await recordingDelete.click();
      await dr.delayMs(Delay.S_1);

      // 进入录音页面
      sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      let audioRecordings = await dr.waitForComponent(ON.text(Keyword.RECORDING), Delay.S_1);
      await audioRecordings.click();
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.id('indexPageRecordNameText'));

      // 点击删除
      item = await Director.getTop1AudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_1);
      deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deletionBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deletionBtn clicked');

      // 校验删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await confirmBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmBtn clicked');

      // 进入最近删除页面
      sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_3);

      // 长按操作
      item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_3);

      // 点击永久删除
      recordingDelete = await dr.findComponent(ON.text(Keyword.RECORDING_DELETE));
      await recordingDelete.click();
      await dr.delayMs(Delay.S_3);

      // 校验永久删除弹窗,点击取消按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let cancelBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
      await cancelBtn.click();
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' cancelBtn clicked');

      // 长按
      item = await Director.getFirstAudioItem(dr);
      await item.longClick();
      await dr.delayMs(Delay.S_3);

      // 点击永久删除
      recordingDelete = await dr.findComponent(ON.text(Keyword.RECORDING_DELETE));
      await recordingDelete.click();
      await dr.delayMs(Delay.S_3);

      // 校验永久删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let deleteBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deleteBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deleteBtn clicked');

      LogUtil.info(TAG + ' RecordRecycleTest_002 end');
    });

    /**
     * 验证最近删除文件的恢复、永久删除功能（左滑）
     */
    it('RecordRecycleTest_003', 0, async () => {
      LogUtil.info(TAG + ' RecordRecycleTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_5);

      // 进入录音页面
      let sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      let audioRecordings = await dr.waitForComponent(ON.text(Keyword.RECORDING), Delay.S_1);
      await audioRecordings.click();
      await dr.delayMs(Delay.S_1);

      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);

      // 点击删除
      let topItem = await Director.getTop1AudioItem(dr);
      await topItem.longClick();
      await dr.delayMs(Delay.S_1);
      let deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deletionBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deletionBtn clicked');

      // 校验删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      let confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await confirmBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmBtn clicked');

      // 进入最近删除页面
      sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      let recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);

      // 左滑音频
      topItem = await Director.getFirstAudioItem(dr);
      let point = await topItem.getBoundsCenter();
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);
      // 左滑点击恢复按钮
      let restoreTab = await dr.waitForComponent(ON.id('recentDeleteRecover'), Delay.S_1);
      await restoreTab.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' restoreTab clicked');

      // 进入录音页面
      sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      audioRecordings = await dr.waitForComponent(ON.text(Keyword.RECORDING), Delay.S_1);
      await audioRecordings.click();
      await dr.delayMs(Delay.S_1);

      // 点击删除
      topItem = await Director.getTop1AudioItem(dr);
      await topItem.longClick();
      await dr.delayMs(Delay.S_1);
      deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deletionBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deletionBtn clicked');

      // 校验删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
      confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await confirmBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmBtn clicked');

      // 进入最近删除页面
      sideBarButton = await dr.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
      await sideBarButton.click();
      await dr.delayMs(Delay.S_1);
      recentlyDeleted = await dr.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
      await recentlyDeleted.click();
      await dr.delayMs(Delay.S_1);

      // 左滑音频
      topItem = await Director.getFirstAudioItem(dr);
      point = await topItem.getBoundsCenter();
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

      // 左滑音频
      point = await topItem.getBoundsCenter();
      await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
      await dr.delayMs(Delay.S_1);

      // 点击永久删除
      await Director.clickSwipeDelBtn(TAG, topItem, dr);

      // 校验永久删除弹窗,点击删除按钮
      await dr.assertComponentExist(ON.text(Keyword.FOREVER_DELETE_TIPS));
      let deleteBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
      await deleteBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' deleteBtn clicked');
      // 回到录音机主页
      await Director.BackToRecordingPage(TAG, dr);
      LogUtil.info(TAG + ' RecordRecycleTest_003 end');
    });

  });
}