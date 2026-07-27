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

import { describe, expect, it } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { LogUtil } from '@ohos/common';
import { Delay, Director, Keyword, } from '@ohos/common/test';

const TAG: string = 'SoundRecorder_PlayCallRecordMenuPageTest';

export default function PlayCallRecordMenuPageTest() {
  describe('PlayCallRecordMenuPageTest', () => {

    /*
    * @tc.number:PlayCallRecordMenuPageTest_001
    * @tc.name: 播放详情界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放详情界面断言
    */
    it('PlayCallRecordMenuPageTest_001', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_001 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
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
        // 关闭详情页
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_001 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_002
    * @tc.name: 播放详情界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放详情界面分享功能验证
    */
    it('PlayCallRecordMenuPageTest_002', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_002 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playPauseBtn clicked');
        // 点击右上角图标
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
        await evenMoreBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' evenMoreBtn clicked');
        //点击分享
        let shareBtn = await dr.waitForComponent(ON.text(Keyword.SHARE), Delay.S_1);
        await shareBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' shareBtn clicked');
        // 效验分享弹窗
        await dr.assertComponentExist(ON.text(Keyword.SHARE));
        await Director.closeShareModal(TAG, dr);
        // 关闭详情页
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_002 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_003
    * @tc.name: 播放详情界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放详情界面重命名功能验证
    */
    it('PlayCallRecordMenuPageTest_003', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_003 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playPauseBtn clicked');
        // 点击右上角图标
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
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
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
        await confirmBtn.click();
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_003 end');
    });

    it('PlayCallRecordMenuPageTest_004', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_004 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playPauseBtn clicked');
        // 点击右上角图标
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
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
        // 关闭详情页
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_004 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_005
    * @tc.name: 播放详情界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放详情界面详情功能验证
    */
    it('PlayCallRecordMenuPageTest_005', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_005 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playPauseBtn clicked');
        // 点击右上角图标
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
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
        // 关闭详情页
        closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_005 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_006
    * @tc.name: 播放详情界面
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播放详情界面删除功能验证
    */
    it('PlayCallRecordMenuPageTest_006', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_006 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playPauseBtn clicked');
        // 点击右上角图标
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
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
        // 关闭详情页
        let closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_006 end');
    });

    it('PlayCallRecordMenuPageTest_007', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_007 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 播放录音
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        let playPauseBtn = await dr.waitForComponent(ON.id('playPause'), Delay.S_1);
        await playPauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playPauseBtn clicked');
        // 点击右上角图标
        let evenMoreBtn = await dr.waitForComponent(ON.id('evenMore'), Delay.S_1);
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
        let cancelBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
        await cancelBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' cancelBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_007 end');
    });
    /*
    * @tc.number:PlayCallRecordMenuPageTest_008
    * @tc.name: 录音机主页菜单
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机主页菜单分享验证
    */

    it('PlayCallRecordMenuPageTest_008', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_008 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
        // 校验弹窗信息
        await dr.assertComponentExist(ON.text(Keyword.MULTI_SELECT));
        await dr.assertComponentExist(ON.text(Keyword.SHARE));
        await dr.assertComponentExist(ON.text(Keyword.RENAME));
        await dr.assertComponentExist(ON.text(Keyword.DELETE));
        await dr.assertComponentExist(ON.text(Keyword.DETAIL));
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_008 end');
    });

    it('PlayCallRecordMenuPageTest_009', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_009 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
        // 点击分享
        let shareBtn = await dr.waitForComponent(ON.text(Keyword.SHARE), Delay.S_1);
        await shareBtn.click();
        LogUtil.info(TAG + ' shareBtn clicked');
        await dr.delayMs(Delay.S_1);
        // 效验分享页面
        await dr.assertComponentExist(ON.text(Keyword.SHARE));
        await Director.closeShareModal(TAG, dr);
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_009 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_010
    * @tc.name: 录音机主页菜单
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机主页菜单重命名功能验证
    */
    it('PlayCallRecordMenuPageTest_010', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_010 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
        // 点击重命名
        let renameBtn = await dr.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
        await renameBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' renameBtn clicked');
        // 效验重命名弹窗
        await dr.assertComponentExist(ON.text(Keyword.RENAME));
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
        await confirmBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_010 end');
    });

    it('PlayCallRecordMenuPageTest_011', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_011 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
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
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_011 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_012
    * @tc.name: 录音机主页菜单
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机主页菜单详情功能验证
    */
    it('PlayCallRecordMenuPageTest_012', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_012 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
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
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_012 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_013
    * @tc.name: 录音机主页菜单
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机主页菜单删除功能验证
    */
    it('PlayCallRecordMenuPageTest_013', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_013 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
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
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_013 end');
    });

    it('PlayCallRecordMenuPageTest_014', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_014 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
        // 点击删除
        let deletionBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
        await deletionBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' deletionBtn clicked');
        // 效验删除弹窗
        await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
        let cancelBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
        await cancelBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_014 end');
    });

    /*
    * @tc.number:PlayCallRecordMenuPageTest_015
    * @tc.name: 录音机主页菜单
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机主页菜单多选功能验证
    */
    it('PlayCallRecordMenuPageTest_015', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_015 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
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
        }
        // 关闭页面
        await dr.assertComponentExist(ON.id('cancelBtn'));
        let closeBtn = await dr.waitForComponent(ON.id('cancelBtn'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_015 end');
    });

    it('PlayCallRecordMenuPageTest_016', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_016 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
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
        // 关闭页面
        let closeBtn = await dr.waitForComponent(ON.id('cancelBtn'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_016 end');
    });

    it('PlayCallRecordMenuPageTest_017', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_017 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        let top1 = await Director.getTop1AudioItem(dr);
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
        let floatMenuMultiSelect = await dr.findComponent(ON.text(Keyword.MULTI_SELECT));
        await floatMenuMultiSelect.click();
        await dr.delayMs(Delay.S_1);
        // 点击分享
        let shareBtn = await dr.waitForComponent(ON.text(Keyword.SHARE), Delay.S_1);
        await shareBtn.click();
        LogUtil.info(TAG + ' shareBtn clicked');
        await dr.delayMs(Delay.S_1);
        // 效验分享页面
        await dr.assertComponentExist(ON.text(Keyword.SHARE));
        await Director.closeShareModal(TAG, dr);
        // 关闭页面
        let closeBtn = await dr.waitForComponent(ON.id('cancelBtn'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' closeBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_017 end');
    });

    /*
    * @tc.number:PlayRecordMenuPageTest_019
    * @tc.name: 录音机左滑菜单
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机左滑菜单功能验证
    */
    it('PlayCallRecordMenuPageTest_018', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_018 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
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
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_018 end');
    });

    it('PlayCallRecordMenuPageTest_019', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_019 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 获取录音位置
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
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
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_019 end');
    });

    it('PlayCallRecordMenuPageTest_020', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_020 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
        // 左滑音频
        await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
        await dr.delayMs(Delay.S_1);
        // 点击删除按钮
        await Director.clickSwipeDelBtn(TAG, top1, dr);
        // 校验删除弹窗,点击删除按钮
        await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
        await confirmBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' confirmBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_020 end');
    });

    it('PlayCallRecordMenuPageTest_021', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_021 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 获取录音位置
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
        // 左滑音频
        await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
        await dr.delayMs(Delay.S_1);
        // 点击重命名按钮
        let deletesTab = await dr.waitForComponent(ON.id('indexRename'), Delay.S_1);
        await deletesTab.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' deletesTab clicked');
        // 效验重命名弹窗
        await dr.assertComponentExist(ON.text(Keyword.RENAME));
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
        await confirmBtn.click();
        await dr.delayMs(Delay.S_1);
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_021 end');
    });

    it('PlayCallRecordMenuPageTest_022', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_022 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
        // 左滑音频
        await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
        await dr.delayMs(Delay.S_1);
        // 点击重命名按钮
        let deletesTab = await dr.waitForComponent(ON.id('indexRename'), Delay.S_1);
        await deletesTab.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' deletesTab clicked');
        // 效验重命名弹窗
        await dr.assertComponentExist(ON.text(Keyword.RENAME));
        let renameResult = await dr.waitForComponent(ON.type('TextInput'), Delay.S_5);
        await renameResult.inputText(Date.now().toString(36));
        await dr.delayMs(Delay.S_1);
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
        await confirmBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' confirmBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_022 end');
    });

    it('PlayCallRecordMenuPageTest_023', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_023 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 获取录音文件坐标
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
        // 左滑音频
        await dr.swipe(point.x, point.y, point.x - 800, point.y, 600);
        await dr.delayMs(Delay.S_1);
        // 点击删除按钮
        await Director.clickSwipeDelBtn(TAG, top1, dr);
        // 校验删除弹窗,点击取消按钮
        await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
        let cancelsBtn = await dr.waitForComponent(ON.text(Keyword.CANCEL), Delay.S_1);
        await cancelsBtn.click();
        LogUtil.info(TAG + ' cancelsBtn clicked');
        await dr.delayMs(Delay.S_1);
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_023 end');
    });

    it('PlayCallRecordMenuPageTest_024', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_024 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        const top1 = await Director.getTop1AudioItem(dr);
        const point = await top1.getBoundsCenter();
        await dr.delayMs(Delay.S_1);
        // 左滑音频
        await dr.swipe(point.x, point.y, point.x - 400, point.y, 600);
        await dr.delayMs(Delay.S_1);
        // 点击删除按钮
        await Director.clickSwipeDelBtn(TAG, top1, dr);
        // 校验删除弹窗,点击删除按钮
        await dr.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
        let confirmBtn = await dr.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
        await confirmBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' confirmBtn clicked');
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_024 end');
    });

    /*
     * @tc.number:PlayCallRecordMenuPageTest_025
     * @tc.name: 录音机菜单弹出位置
     * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
     * @tc.desc: 录音机菜单弹出位置
     */
    it('PlayCallRecordMenuPageTest_025', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_025 start');
      // 定义Driver类
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 长按操作
        const top1 = await Director.getTop1AudioItem(dr);
        let point = await top1.getBounds();
        await top1.longClick();
        await dr.delayMs(Delay.S_1);
        // 获取菜单页面坐标点
        let clickBtn = await dr.waitForComponent(ON.id('multi_select'), Delay.S_1);
        const clickPoint = await clickBtn.getBounds();
        expect(point.bottom).assertLess(clickPoint.top);
        // 回到主页
        let back = await dr.getDisplaySize();
        await dr.swipe(0, back.y - 800, 500, back.y - 800, 10000);
        // 校验分享页面
        await dr.assertComponentExist(ON.id('recorderBtn'));
        await dr.delayMs(Delay.S_1);
      }
      LogUtil.info(TAG + ' PlayCallRecordMenuPageTest_025 end');
    });
  })
}