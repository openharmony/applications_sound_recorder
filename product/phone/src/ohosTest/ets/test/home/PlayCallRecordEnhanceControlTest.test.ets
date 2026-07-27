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
import { Driver, ON, UiDirection } from '@ohos.UiTest';
import { LogUtil } from '@ohos/common';
import { Delay, Director, Keyword, } from '@ohos/common/test';

const TAG: string = 'SoundRecorder_PlayCallRecordEnhanceControlTest';

export default function PlayCallRecordEnhanceControlTest() {
  describe('PlayCallRecordEnhanceControlTest', () => {
    beforeAll(async () => {
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:PlayCallRecordEnhanceControlTest_001
    * @tc.name: 录音机通话录音文件列表进度条
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机通话录音文件列表进度条
    */
    it('PlayCallRecordEnhanceControlTest_001', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_001 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' playBtn clicked');
        // 再次点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let rePlayBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await rePlayBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_001 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_002', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_002 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 拉进度条
        await dr.assertComponentExist(ON.id('progressSlider'));
        const slider = await dr.findComponent(ON.id('progressSlider'));
        const rect = await slider.getBounds();
        const p = await slider.getBoundsCenter();
        await dr.drag(rect.left, p.y, rect.left + 300, p.y, 600);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_002 end');
      }
    });

    /*
    * @tc.number:PlayCallRecordEnhanceControlTest_003
    * @tc.name: 录音机通话录音拖动波形图
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机通话录音拖动波形图
    */
    it('PlayCallRecordEnhanceControlTest_003', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_003 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 获取波形图position
        await dr.assertComponentExist(ON.id('id_canvas'));
        let rePlayBtn = await dr.waitForComponent(ON.id('id_canvas'), Delay.S_1);
        const rect = await rePlayBtn.getBounds();
        await dr.delayMs(Delay.S_1);
        const heightWave = Math.floor((rect.bottom - rect.top) / 2);
        const widthWave = Math.floor((rect.right - rect.left) / 2);
        LogUtil.info(TAG + ' audioList clicked');
        // 拖动波形图
        await dr.drag(rect.right - widthWave - 200, rect.top + heightWave, rect.right - 50, rect.top + heightWave, 800);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_003 end');
      }
    });

    /*
    * @tc.number:PlayCallRecordEnhanceControlTest_004
    * @tc.name: 录音机通话录音适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 控制中心录音机通话录音播控和显示
    */
    it('PlayCallRecordEnhanceControlTest_004', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_004 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击暂停
        const pauseBtn = await dr.waitForComponent(ON.id('control_center_media_card_play_or_pause'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击播放
        const reStartBtn = await dr.waitForComponent(ON.id('MediaCardComponent_debug_Image_pause'), Delay.S_1);
        await reStartBtn.click();
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_004 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_005', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_005 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击暂停
        const pauseBtn = await dr.waitForComponent(ON.id('control_center_media_card_play_or_pause'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击播放
        const reStartBtn = await dr.waitForComponent(ON.id('MediaCardComponent_debug_Image_pause'), Delay.S_1);
        await reStartBtn.click();
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_005 end');
      }
    });

    /*
    * @tc.number:PlayCallRecordEnhanceControlTest_006
    * @tc.name: 录音机通话录音适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播控中心录音机通话录音播控和显示
    */
    it('PlayCallRecordEnhanceControlTest_006', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_006 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        await dr.assertComponentExist(ON.id('mediaPublicIconStart'));
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('recorderBtn'));
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_006 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_007', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_007 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        await dr.assertComponentExist(ON.id('mediaPublicIconStart'));
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击暂停
        const pauseBtn = await dr.waitForComponent(ON.id('media_play_pause_No.0'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_007 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_008', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_008 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        await dr.assertComponentExist(ON.id('mediaPublicIconStart'));
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击暂停
        const pauseBtn = await dr.waitForComponent(ON.id('media_play_pause_No.0'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击恢复
        const reStartBtn = await dr.waitForComponent(ON.id('media_play_pause_No.0'), Delay.S_1);
        await reStartBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_008 end');
      }
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_009
    * @tc.name: 录音机通话录音适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机通话录音播控中心入口保持一致性
    */
    it('PlayCallRecordEnhanceControlTest_009', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_009 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('MediaCardComponent_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_009 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_010', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_010 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        await dr.assertComponentExist(ON.id('recorderBtn'));
        const pauseBtn = await dr.waitForComponent(ON.id('recorderBtn'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' pauseBtn clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('MediaCardComponent_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_010 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_011', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_011 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        await dr.assertComponentExist(ON.id('mediaPublicIconStart'));
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('media_play_pause_No.0'));
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_011 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_012', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_012 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        await dr.assertComponentExist(ON.id('recorderBtn'));
        const pauseBtn = await dr.waitForComponent(ON.id('recorderBtn'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' pauseBtn clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('media_play_pause_No.0'));
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_012 end');
      }
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_013
    * @tc.name: 录音机通话录音适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 通话录音非详情页录音机播控中心入口保持一致性
    */
    it('PlayCallRecordEnhanceControlTest_013', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_013 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('MediaCardComponent_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_013 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_014', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_014 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 停止播放
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('MediaCardComponent_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_014 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_015', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_015 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('media_play_pause_No.0'));
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_015 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_016', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_016 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 停止播放
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击调出播控中心
        const controlBtn = await dr.waitForComponent(ON.id('mediaPublicIconStart'), Delay.S_1);
        await controlBtn.click();
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('media_play_pause_No.0'));
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
        await backBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_016 end');
      }
    });

    /*
* @tc.number:PlayCallRecordEnhanceControlTest_017
* @tc.name: 录音机适配播控中心支持前后台播放
* @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
* @tc.desc: 通知栏录音机播控和显示
*/
    it('PlayCallRecordEnhanceControlTest_017', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_017 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击暂停
        const pauseBtn = await dr.waitForComponent(ON.id('ControlButtonGroup_debug_Image_pause'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击播放
        const reStartBtn = await dr.waitForComponent(ON.id('ControlButtonGroup_debug_Image_pause'), Delay.S_1);
        await reStartBtn.click();
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_017 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_018', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_018 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击暂停
        const pauseBtn = await dr.waitForComponent(ON.id('ControlButtonGroup_debug_Image_pause'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        // 点击播放
        const reStartBtn = await dr.waitForComponent(ON.id('ControlButtonGroup_debug_Image_pause'), Delay.S_1);
        await reStartBtn.click();
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_018 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_019', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_019 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 点击回到录音机主页
        const notifyRect =
          await dr.findComponent(ON.id('com.ohos.soundrecorder__0_6700_100_100_01_0'));
        const rect = await notifyRect.getBounds();
        await dr.click(rect.left + 50, rect.top + 50);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('recorderBtn'));
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_019 end');
      }
    });

    /*
     * @tc.number:PlayCallRecordEnhanceControlTest_020
     * @tc.name: 录音机适配播控中心支持前后台播放
     * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
     * @tc.desc: 录音机通知栏入口保持一致性
     */
    it('PlayCallRecordEnhanceControlTest_020', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_020 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('ControlButtonGroup_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_020 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_021', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_021 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击进入播放详情页
        const top1 = await Director.getTop1AudioItem(dr);
        await Director.clickAudioItem(dr, top1);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 暂停播放
        await dr.assertComponentExist(ON.id('recorderBtn'));
        const pauseBtn = await dr.waitForComponent(ON.id('recorderBtn'), Delay.S_1);
        await pauseBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' pauseBtn clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('ControlButtonGroup_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        // 关闭详情页
        await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
        const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
        await closeBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_021 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_022', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_022 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('ControlButtonGroup_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_022 end');
      }
    });

    it('PlayCallRecordEnhanceControlTest_023', 0, async () => {
      LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_014 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      let callRecord = await dr.waitForComponent(ON.id('arrowDown'), Delay.S_1);
      LogUtil.info(TAG + ' callRecord clicked');
      if (callRecord) {
        // 点击播放
        await dr.assertComponentExist(ON.id('playBtn'));
        let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' audioList clicked');
        // 停止播放
        await playBtn.click();
        await dr.delayMs(Delay.S_1);
        // 下拉控制中心
        let point = await dr.getDisplaySize();
        await dr.swipe(50, 0, 50, 580, 10000);
        await dr.delayMs(Delay.S_1);
        // 检验录音机按钮
        await dr.assertComponentExist(ON.id('ControlButtonGroup_debug_Image_pause'));
        await dr.delayMs(Delay.S_1);
        // 至录音机主页
        await dr.click(10, point.y - 10);
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' PlayCallRecordEnhanceControlTest_023 end');
      }
    });
  })
}