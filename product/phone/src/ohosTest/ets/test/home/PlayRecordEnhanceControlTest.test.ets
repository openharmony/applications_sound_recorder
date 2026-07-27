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
import { abilityDelegatorRegistry } from '@kit.TestKit';

const TAG: string = 'SoundRecorder_PlayRecordEnhanceControlTest';
const delegator: abilityDelegatorRegistry.AbilityDelegator = abilityDelegatorRegistry.getAbilityDelegator();

export default function PlayRecordEnhanceControlTest() {
  describe('PlayRecordEnhanceControlTest', () => {
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
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
    });

    /*
    * @tc.number:RecordPlayPageTest_001
    * @tc.name: 录音机文件列表进度条
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机文件列表进度条
    */
    it('PlayRecordEnhanceControlTest_001', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_001 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_001 end');
    });

    it('PlayRecordEnhanceControlTest_002', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_002 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_002 end');
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_003
    * @tc.name: 录音机拖动波形图
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机拖动波形图
    */
    it('PlayRecordEnhanceControlTest_003', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_003 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      await dr.drag(rect.right - widthWave - 200, rect.top + heightWave, rect.right -50, rect.top + heightWave, 800);
      await dr.delayMs(Delay.S_1);
      // 关闭详情页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_003 end');
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_004
    * @tc.name: 录音机适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 控制中心录音机播控和显示
    */
    it('PlayRecordEnhanceControlTest_004', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_004 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_004 end');
    });

    it('PlayRecordEnhanceControlTest_005', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_005 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_005 end');
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_006
    * @tc.name: 录音机适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 播控中心录音机播控和显示
    */
    it('PlayRecordEnhanceControlTest_006', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_006 start');
      const dr: Driver = Driver.create();
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_30);
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      await dr.assertComponentExist(ON.id('defaultLargeImage'));
      const backBtn = await dr.waitForComponent(ON.id('defaultLargeImage'), Delay.S_1);
      await backBtn.click();
      await dr.delayMs(Delay.S_1);
      // 检验录音机按钮
      await dr.assertComponentExist(ON.id('recorderBtn'));
      await dr.delayMs(Delay.S_1);
      // 关闭详情页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_006 end');
    });

    it('PlayRecordEnhanceControlTest_007', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_007 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' audioList clicked');
      // 下拉控制中心
      let point = await dr.getDisplaySize();
      await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击调出播控中心
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_007 end');
    });

    it('PlayRecordEnhanceControlTest_008', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_008 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' audioList clicked');
      // 下拉控制中心
      let point = await dr.getDisplaySize();
      await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击调出播控中心
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_008 end');
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_009
    * @tc.name: 录音机适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机播控中心入口保持一致性
    */
    it('PlayRecordEnhanceControlTest_009', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_009 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_009 end');
    });

    it('PlayRecordEnhanceControlTest_010', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_010 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_010 end');
    });

    it('PlayRecordEnhanceControlTest_011', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_011 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      // 关闭详情页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_011 end');
    });

    it('PlayRecordEnhanceControlTest_012', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_012 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      const playButton = await dr.waitForComponent(ON.id('media_play_pause_No.0'), Delay.S_1);
      await playButton.click();
      await dr.delayMs(Delay.S_1);
      await playButton.click();
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_012 end');
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_013
    * @tc.name: 录音机适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 非详情页录音机播控中心入口保持一致性
    */
    it('PlayRecordEnhanceControlTest_013', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_013 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      await playBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_013 end');
    });

    it('PlayRecordEnhanceControlTest_014', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_014 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_014 end');
    });

    it('PlayRecordEnhanceControlTest_015', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_015 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击播放
      await dr.assertComponentExist(ON.id('playBtn'));
      let playBtn = await dr.waitForComponent(ON.id('playBtn'), Delay.S_1);
      await playBtn.click();
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_015 end');
    });

    it('PlayRecordEnhanceControlTest_016', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_016 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_016 end');
    });

    /*
    * @tc.number:PlayRecordEnhanceControlTest_004
    * @tc.name: 录音机适配播控中心支持前后台播放
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 通知栏录音机播控和显示
    */
    it('PlayRecordEnhanceControlTest_017', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_017 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_017 end');
    });

    it('PlayRecordEnhanceControlTest_018', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_018 start');
      const dr: Driver = Driver.create();
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_018 end');
    });

    it('PlayRecordEnhanceControlTest_019', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_019 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
      LogUtil.info(TAG + ' audioList clicked');
      // 下拉控制中心
      let point = await dr.getDisplaySize();
      await dr.swipe(50, 0, 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击回到录音机主页
      const notifyRect = await dr.findComponent(ON.id('notification_media_card_play_or_pause'));
      const rect = await notifyRect.getBounds();
      await dr.click(rect.left - 50, rect.top + 50);
      await dr.delayMs(Delay.S_1);
      // 检验录音机按钮
      await dr.assertComponentExist(ON.id('recorderBtn'));
      await dr.delayMs(Delay.S_1);
      // 关闭详情页
      await dr.assertComponentExist(ON.id('backIconInNavDestinationTitleBar'));
      const closeBtn = await dr.waitForComponent(ON.id('backIconInNavDestinationTitleBar'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_019 end');
    });

    /*
     * @tc.number:PlayRecordEnhanceControlTest_020
     * @tc.name: 录音机适配播控中心支持前后台播放
     * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
     * @tc.desc: 录音机通知栏入口保持一致性
     */
    it('PlayRecordEnhanceControlTest_020', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_020 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_020 end');
    });

    it('PlayRecordEnhanceControlTest_021', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_021 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
      // 点击进入播放详情页
      const top1 = await Director.getTop1AudioItem(dr);
      await Director.clickAudioItem(dr, top1);
      await dr.delayMs(Delay.S_3);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_021 end');
    });

    it('PlayRecordEnhanceControlTest_022', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_022 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_022 end');
    });

    it('PlayRecordEnhanceControlTest_023', 0, async () => {
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_014 start');
      const dr: Driver = Driver.create();
      await dr.delayMs(Delay.S_1);
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
      LogUtil.info(TAG + ' PlayRecordEnhanceControlTest_023 end');
    });
  })
}