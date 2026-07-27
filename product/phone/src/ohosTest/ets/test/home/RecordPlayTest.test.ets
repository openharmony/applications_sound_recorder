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

const TAG: string = 'SoundRecorder_PlayTest';

export default function RecordPlayTest() {
  describe('RecordPlayTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_5);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:RecordPlayTest_001
    * @tc.name: 录音机播放验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机播放正常
    */
    it('RecordPlayTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordPlayTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击播放
      await dr.assertComponentExist(ON.id('playBtn'));
      let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
      await playBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' playBtn clicked');
      // 拉进度条
      const slider = await dr.findComponent(ON.type('Slider'));
      const rect = await slider.getBounds();
      const p = await slider.getBoundsCenter();
      await dr.fling({
        x: rect.left, y: p.y
      }, {
        x: rect.left + 160, y: p.y
      }, 5, 600);
      // 暂停播放
      await dr.assertComponentExist(ON.id('playBtn'));
      playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_5);
      await playBtn.click();
      await dr.delayMs(Delay.MS_200);
      LogUtil.info(TAG + ' playBtn pause clicked');

      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);;
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);

      //进入播放页面
      LogUtil.info(TAG + ' audioList clicked');

      // 开始播放
      await dr.assertComponentExist(ON.id('playBtn'));
      playBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_3);
      await dr.delayMs(Delay.MS_200);

      // 点击标记
      let playMarkBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
      await playMarkBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' playMarkBtn clicked');
      // 重命名标记
      let markBadge = await dr.waitForComponent(ON.text(Keyword.MARK), Delay.S_1);
      const newName = Date.now().toString(36);
      await Director.renameRecordMark(TAG, dr, markBadge, newName);
      // 删除标记
      markBadge = await dr.waitForComponent(ON.text(newName), Delay.S_1);
      await Director.deleteRecordMark(TAG, dr, markBadge);
      // 继续播放
      await dr.assertComponentExist(ON.id('playBtn'));
      let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
      await playPauseBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' playPauseBtn clicked');
      // 开启扬声器
      let buttonState = await dr.waitForComponent(ON.id('disableDoubleSpeed'), Delay.S_1);
      LogUtil.info(TAG + ' buttonState : ' + JSON.stringify(buttonState));
      if (buttonState) {
        await dr.assertComponentExist(ON.id('putOutside'));
        let putOutsideBtn = await dr.waitForComponent(ON.id('putOutside'), Delay.S_1);
        await putOutsideBtn.click();
        await dr.delayMs(500);
        LogUtil.info(TAG + ' putOutsideBtn clicked');
      }
      // 倍速播放
      await dr.assertComponentExist(ON.id('doubleSpeed'));
      let doubleSpeedBtn = await dr.waitForComponent(ON.id('doubleSpeed'), Delay.S_1);
      await doubleSpeedBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' doubleSpeedBtn clicked');
      // 暂停播放
      await dr.assertComponentExist(ON.id('playPause'));
      playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
      await playPauseBtn.click();
      LogUtil.info(TAG + ' playPauseBtn clicked');
      await dr.delayMs(Delay.S_1);
      // 返回上一页
      await dr.pressBack();
      LogUtil.info(TAG + ' backPage clicked');
      LogUtil.info(TAG + ' RecordPlayTest_001 end');
    });

    /*
    * @tc.number:RecordPlayTest_002
    * @tc.name: 录音机播放音频分享、重命名、删除、详情验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机播放音频分享、重命名、删除、详情正常
    */
    it('RecordPlayTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordPlayTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' audioList clicked');
      await dr.assertComponentExist(ON.id('playPause'));
      let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
      await playPauseBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' playPauseBtn clicked');
      // 点击右上角图标
      let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
      await evenMoreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' evenMoreBtn clicked');
      // 校验弹窗信息
      await dr.assertComponentExist(ON.text(Keyword.SHARE));
      await dr.assertComponentExist(ON.text(Keyword.RENAME));
      await dr.assertComponentExist(ON.text(Keyword.DELETE));
      await dr.assertComponentExist(ON.text(Keyword.DETAIL));
      //点击分享
      let shareBtn = await dr.waitForComponent(ON.text(Keyword.SHARE), Delay.S_1);
      await shareBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' shareBtn clicked');
      // 效验分享弹窗
      await dr.assertComponentExist(ON.text(Keyword.SHARE));
      await Director.closeShareModal(TAG, dr);
      await dr.assertComponentExist(ON.id('evenMore'));
      evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
      await evenMoreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' evenMoreBtn clicked');
      // 点击重命名
      let renameBtn = await dr.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
      await renameBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' renameBtn clicked');
      // 效验重命名弹窗
      await dr.assertComponentExist(ON.text(Keyword.RENAME));
      let renameResult = await dr.waitForComponent(ON.type('TextInput'), Delay.S_5);
      await renameResult.inputText(Date.now().toString(36));
      await dr.delayMs(Delay.S_1);
      let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
      await confirmBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' confirmBtn clicked');
      evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
      await evenMoreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' evenMoreBtn clicked');
      // 点击删除
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
      evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
      await evenMoreBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' evenMoreBtn clicked');
      // 点击详情
      let infoBtn = await dr.waitForComponent(ON.text(Keyword.DETAIL), Delay.S_1);
      await infoBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' infoBtn clicked');
      // 效验详情弹窗
      await dr.assertComponentExist(ON.text(Keyword.DETAIL));
      let closeBtn = await dr.waitForComponent(ON.text(Keyword.CLOSE), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' closeBtn clicked');
      // 返回上一页
      await dr.pressBack();
      LogUtil.info(TAG + ' backPage clicked');
      LogUtil.info(TAG + ' RecordPlayTest_002 end');
    });

    /*
    * @tc.number:RecordPlayTest_003
    * @tc.name: 通话录音播放验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 通话录音播放验证正常
    */
    it('RecordPlayTest_003', 0, async () => {
      LogUtil.info(TAG + ' RecordPlayTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        await callRecord.click();
        await dr.delayMs(Delay.S_1);
        // 播放通话录音
        await dr.assertComponentExist(ON.id('callPlayBtn'));
        let callPlayBtn = await dr.waitForComponent(ON.id('callPlayBtn'), Delay.S_1);
        await callPlayBtn.click();
        LogUtil.info(TAG + ' callPlayBtn clicked');
        await dr.delayMs(Delay.S_1);
        await dr.fling({
          x: 346, y: 1137
        }, {
          x: 890, y: 1137
        }, 5, 600);
        // 暂停播放
        callPlayBtn = await dr.waitForComponent(ON.id('callPlayBtn'), Delay.S_1);
        await callPlayBtn.click();
        LogUtil.info(TAG + ' callPlayBtn clicked');
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' RecordPlayTest_003 end');
      }
    });

    /*
    * @tc.number:RecordPlayTest_004
    * @tc.name: 通话录音详情页验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 通话录音详情页验证正常
    */
    it('RecordPlayTest_004', 0, async () => {
      LogUtil.info(TAG + ' RecordPlayTest_004 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        await callRecord.click();
        await dr.delayMs(Delay.S_1);
        let firstCall = await dr.waitForComponent(ON.type('ListItem')
          .isAfter(ON.text(Keyword.CALL_RECORDING)), Delay.S_1);
        await firstCall.click();
        await dr.delayMs(Delay.S_1);
        // 标记
        await dr.assertComponentExist(ON.id('playMark'));
        let markBtn = await dr.waitForComponent(ON.id('playMark'), Delay.S_1);
        await markBtn.click();
        LogUtil.info(TAG + ' markBtn clicked');
        await dr.delayMs(Delay.S_1);
        // 标记重命名
        let callMarkRename = await dr.waitForComponent(ON.text(Keyword.MARK), Delay.S_1);
        await callMarkRename.click();
        LogUtil.info(TAG + ' callMarkRename clicked');
        await dr.delayMs(Delay.S_1);
        let callRename = await dr.waitForComponent(ON.type('TextInput'), Delay.S_5);
        await callRename.inputText('mark');
        let playMarkConfirm = await dr.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
        await playMarkConfirm.click();
        LogUtil.info(TAG + ' playMarkConfirm clicked');
        await dr.delayMs(Delay.S_1);
        // 删除标记
        await dr.swipe(560, 1368, 136, 1368, 600);
        let playMarkDeleteBtn = await dr.waitForComponent(ON.id('playMarkDelete'), Delay.S_1);
        await playMarkDeleteBtn.click();
        LogUtil.info(TAG + ' playMarkDeleteBtn clicked');
        await dr.delayMs(Delay.S_1);
        //  详情页重命名
        await dr.assertComponentExist(ON.id('evenMore'));
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
        await evenMoreBtn.click();
        LogUtil.info(TAG + ' evenMoreBtn clicked');
        await dr.delayMs(Delay.S_1);
        let renameTab = await dr.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
        await renameTab.click();
        LogUtil.info(TAG + ' renameTab clicked');
        await dr.delayMs(Delay.S_1);
        let result = await dr.waitForComponent(ON.type('TextInput'), Delay.S_5);
        await result.inputText('info');
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
        await confirmBtn.click();
        LogUtil.info(TAG + ' confirmBtn clicked');
        await dr.delayMs(Delay.S_1);
        // 继续播放
        await dr.assertComponentExist(ON.id('playPause'));
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        LogUtil.info(TAG + ' playPauseBtn clicked');
        await dr.delayMs(Delay.S_1);
        await dr.swipe(0, 1381, 400, 1381, 600);
        LogUtil.info(TAG + ' RecordPlayTest_004 end');
      }
    });

    /*
    * @tc.number:RecordPlayTest_005
    * @tc.name: 通话录音删除、全选、更多验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 通话录音删除、全选、更多验证正常
    */
    it('RecordPlayTest_005', 0, async () => {
      LogUtil.info(TAG + ' RecordPlayTest_005 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 展开通话录音
      let arrowUpBtn = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      if (arrowUpBtn) {
        await arrowUpBtn.click();
        LogUtil.info(TAG + ' arrowUpBtn clicked');
        await dr.delayMs(Delay.S_1);

        // 通话录音
        let longCall = await dr.waitForComponent(ON.type('ListItem')
          .isAfter(ON.text(Keyword.CALL_RECORDING)), Delay.S_1);
        LogUtil.info(TAG + ' selectAllBtn clicked longCall');
        if (longCall) {
          await longCall.longClick();
          await dr.delayMs(Delay.S_1);
          await dr.swipe(0, 1381, 400, 1381, 600);
          longCall = await dr.waitForComponent(ON.type('ListItem')
            .isAfter(ON.text(Keyword.CALL_RECORDING)), Delay.S_1);
          await longCall.longClick();
          await dr.delayMs(Delay.S_1);
          // 点击删除
          let deleteBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
          await deleteBtn.click();
          LogUtil.info(TAG + ' deleteBtn clicked');
          await dr.delayMs(Delay.S_1);
          await dr.click(902, 2543);
          await dr.delayMs(Delay.S_1);
          longCall = await dr.waitForComponent(ON.type('ListItem')
            .isAfter(ON.text(Keyword.CALL_RECORDING)), Delay.S_1);
          if (longCall) {
            await longCall.longClick();
            await dr.delayMs(Delay.S_1);
            // 点击全选
            let selectAllBtn = await dr.waitForComponent(ON.text(Keyword.SELECT_ALL), Delay.S_1);
            LogUtil.info(TAG + ' selectAllBtn clicked selectAllBtn');
            await selectAllBtn.click();
            LogUtil.info(TAG + ' selectAllBtn clicked');
            await dr.delayMs(Delay.S_1);
            // 取消全选
            let unSelectAllBtn = await dr.waitForComponent(ON.text(Keyword.DESELECT_ALL), Delay.S_1);
            LogUtil.info(TAG + ' selectAllBtn clicked unSelectAllBtn');
            await unSelectAllBtn.click();
            LogUtil.info(TAG + ' unSelectAllBtn clicked');
            await dr.delayMs(Delay.S_1);
            let firstItem = await dr.waitForComponent(ON.type('ListItem')
              .isAfter(ON.text(Keyword.CALL_RECORDING)), Delay.S_1);
            await firstItem.click();
            LogUtil.info(TAG + ' firstItem clicked');
            await dr.delayMs(Delay.S_1);
            // 点击更多
            await dr.assertComponentExist(ON.text(Keyword.MORE));
            let moreBtn = await dr.waitForComponent(ON.text(Keyword.MORE), Delay.S_1);
            await moreBtn.click();
            LogUtil.info(TAG + ' moreBtn clicked');
            await dr.delayMs(Delay.S_1);
            // 点击详情
            await dr.assertComponentExist(ON.text(Keyword.DETAIL));
            let infoBtn = await dr.waitForComponent(ON.text(Keyword.DETAIL), Delay.S_1);
            await infoBtn.click();
            LogUtil.info(TAG + ' infoBtn clicked');
            await dr.delayMs(Delay.S_1);
            let closeBtn = await dr.waitForComponent(ON.text(Keyword.CLOSE), Delay.S_1);
            await closeBtn.click();
            LogUtil.info(TAG + ' closeBtn clicked');
            await dr.delayMs(Delay.S_1);
            moreBtn = await dr.waitForComponent(ON.text(Keyword.MORE), Delay.S_1);
            await moreBtn.click();
            LogUtil.info(TAG + ' moreBtn clicked');
            await dr.delayMs(Delay.S_1);
            // 点击重命名
            let renameBtn = await dr.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
            await renameBtn.click();
            LogUtil.info(TAG + ' renameBtn clicked');
            await dr.delayMs(Delay.S_1);
            let renameResult = await dr.waitForComponent(ON.type('TextInput'), Delay.S_5);
            await renameResult.inputText('call');
            let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
            await confirmBtn.click();
            LogUtil.info(TAG + ' confirmBtn clicked');
            await dr.delayMs(Delay.S_1);
            LogUtil.info(TAG + ' RecordPlayTest_005 end');
          }
        }
      }
    });

    /*
    * @tc.number:RecordPlayTest_006
    * @tc.name: 通话录音删除验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 通话录音删除验证正常
    */
    it('RecordPlayTest_006', 0, async () => {
      LogUtil.info(TAG + ' RecordPlayTest_006 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 展开通话录音
      let arrowUpBtn = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      if (arrowUpBtn) {
        await arrowUpBtn.click();
        LogUtil.info(TAG + ' arrowUpBtn clicked');
        await dr.delayMs(Delay.S_1);
        // 删除通话录音
        await dr.swipe(630, 977, 136, 977, 600);
        await dr.delayMs(Delay.S_1);
        await dr.assertComponentExist(ON.id('callDeleteBtn'));
        let deleteBtn = await dr.waitForComponent(ON.id('callDeleteBtn'), Delay.S_1);
        await deleteBtn.click();
        LogUtil.info(TAG + ' deleteBtn clicked');
        await dr.delayMs(Delay.S_1);
        let delBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
        await delBtn.click();
        LogUtil.info(TAG + ' delBtn clicked');
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' RecordPlayTest_006 end');
      }
    });
  })
}