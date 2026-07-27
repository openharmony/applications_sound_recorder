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
import { Driver, MatchPattern, ON, UiDirection } from '@ohos.UiTest';
import { LogUtil } from '@ohos/common';
import { Delay, Director, Keyword } from '@ohos/common/test';

const TAG = 'SoundRecorder_RecodingSoundRecorderTest';

export default function RecordingPageTest() {
  describe('RecordingPageTest', () => {
    /*
    * @tc.number:RecordingPageTest_001
    * @tc.name: 录音机页面入口验证
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 进入录音机页面正常
    */
    it('RecordingPageTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_001 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);

      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 点击标记
      let markBtn = await dr.waitForComponent(ON.id('markBtn'), Delay.S_1);
      await markBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' markBtn clicked');
      // 重命名标记
      let markBadge = await dr.waitForComponent(ON.text(Keyword.MARK), Delay.S_1);
      const newName = Date.now().toString(36);
      await Director.renameRecordMark(TAG, dr, markBadge, newName);
      // 删除标记
      markBadge = await dr.waitForComponent(ON.text(newName), Delay.S_1);
      await Director.deleteRecordMark(TAG, dr, markBadge);
      // 暂停录音
      await Director.resumeRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 继续录音
      await Director.resumeRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 结束录音
      await Director.stopRecording(TAG, dr);
      LogUtil.info(TAG + ' RecordingPageTest_001 end');
    });

    /*
    * @tc.number:RecordingPageTest_002
    * @tc.name: 录音机录音交互
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机录音交互:左滑
    */
    it('RecordingPageTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_002 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 左滑并判断是否中断
      let point = await dr.getDisplaySize();
      await dr.swipe(0, point.y - 800, 500, point.y - 800, 10000);
      const recordBtn = await dr.waitForComponent(ON.id('recordBtn'), Delay.S_1);
      await dr.delayMs(Delay.S_1);
      expect(recordBtn).assertNull();
      LogUtil.info(TAG + ' RecordingPageTest_002 end');
    });

    /*
    * @tc.number:RecordingPageTest_003
    * @tc.name: 录音机录音交互
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机录音交互:关闭
    */
    it('RecordingPageTest_003', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_003 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 点击关闭
      const closeBtn = await dr.waitForComponent(ON.id('BackButton'), Delay.S_1);
      await closeBtn.click();
      await dr.delayMs(Delay.S_1);
      const recordBtn = await dr.waitForComponent(ON.id('recordBtn'), Delay.S_1);
      expect(recordBtn).assertNull();
      LogUtil.info(TAG + ' RecordingPageTest_003 end');
    });

    /*
    * @tc.number:RecordingPageTest_004
    * @tc.name: 录音机录音并发
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机与录屏并发验证
    */
    it('RecordingPageTest_004', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_004 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 暂停录音
      await Director.resumeRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 下拉至播控中心页面
      let point = await dr.getDisplaySize();
      await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击屏幕录制
      const screenRecordTitle = await dr.waitForComponent(ON.text('屏幕录制'), Delay.S_1);
      const screenRecordBtn = await screenRecordTitle.getBoundsCenter();
      await dr.click(screenRecordBtn.x - 50, screenRecordBtn.y - 100);
      await dr.delayMs(Delay.S_1);
      // 继续录音
      await Director.resumeRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 下拉至播控中心页面
      await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 关闭屏幕录制
      await dr.click(screenRecordBtn.x - 50, screenRecordBtn.y - 100);
      await dr.delayMs(Delay.S_3);
      // 结束录音
      await Director.stopRecording(TAG, dr);
      LogUtil.info(TAG + ' RecordingPageTest_004 end');
    });

    it('RecordingPageTest_005', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_005 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 结束录音
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      // 下拉至播控中心页面
      let point = await dr.getDisplaySize();
      await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击屏幕录制
      const screenRecordTitle = await dr.waitForComponent(ON.text('屏幕录制'), Delay.S_1);
      const screenRecordBtn = await screenRecordTitle.getBoundsCenter();
      await dr.click(screenRecordBtn.x - 50, screenRecordBtn.y - 100);
      await dr.delayMs(Delay.S_1);
      // 开始录音
      await Director.startRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 下拉至播控中心页面
      await dr.swipe(point.x - 50, 0, point.x - 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 关闭屏幕录制
      await dr.click(screenRecordBtn.x - 50, screenRecordBtn.y - 100);
      await dr.delayMs(Delay.S_3);
      // 结束录音
      await Director.stopRecording(TAG, dr);
      LogUtil.info(TAG + ' RecordingPageTest_005 end');
    });

    /*
    * @tc.number:RecordingPageTest_006
    * @tc.name: 录音机后台录音
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: 录音机后台录音
    */
    it('RecordingPageTest_006', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_006 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 暂停录音
      await Director.resumeRecording(TAG, dr);
      await dr.delayMs(Delay.S_3);
      // 返回首页
      await dr.pressHome();
      await dr.delayMs(Delay.S_3);
      // 点击录音机
      let clickBtn = await Director.lookUpStringButton(TAG, dr, '录音机');
      const clickPoint = await clickBtn.getBoundsCenter();
      await dr.click(clickPoint.x, clickPoint.y - 100);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' clickBtn');
      await dr.assertComponentExist(ON.id('recordBtn'));
      // 结束录音
      await Director.stopRecording(TAG, dr);
      LogUtil.info(TAG + ' RecordingPageTest_006 end');
    });

    it('RecordingPageTest_007', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_007 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 返回首页
      await dr.pressHome();
      await dr.delayMs(Delay.S_3);
      // 点击录音机
      let clickBtn =  await Director.lookUpStringButton(TAG, dr, '录音机');
      const clickPoint = await clickBtn.getBoundsCenter();
      await dr.click(clickPoint.x, clickPoint.y - 100);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' clickBtn');
      await dr.assertComponentExist(ON.id('recordBtn'));
      // 结束录音
      await Director.stopRecording(TAG, dr);
      LogUtil.info(TAG + ' RecordingPageTest_007 end');
    });

    it('RecordingPageTest_008', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_008 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 下拉至通知中心页面
      await dr.swipe(50, 0, 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击暂停录音
      const resumeBtn = await dr.waitForComponent(ON.id('.*?(com\\..\\.hmos\\.soundrecorder)(.*?)(started).*', MatchPattern.REG_EXP), Delay.S_1);
      await resumeBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' resumeBtn');
      // 点击继续录音
      const reStartBtn = await dr.waitForComponent(ON.id('.*?(com\\.\\.hmos\\.soundrecorder)(.*?)(paused).*', MatchPattern.REG_EXP), Delay.S_1);
      await reStartBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' reStartBtn');
      // 点击空白处返回录音机
      const clickBtn = await dr.waitForComponent(ON.id('.*?(com\\.\\.hmos\\.soundrecorder)(.*?)(started).*', MatchPattern.REG_EXP), Delay.S_1);
      const rect = await clickBtn.getBounds();
      await dr.delayMs(Delay.S_1);
      await dr.click(rect.left - 100, rect.top);
      // 停止录音
      await Director.stopRecording(TAG, dr);
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' RecordingPageTest_008 end');
    });

    it('RecordingPageTest_009', 0, async () => {
      LogUtil.info(TAG + ' RecordingPageTest_009 start');
      const dr = Driver.create();
      await Director.startRecording(TAG, dr);
      // 效验跳转到录音页面
      await dr.assertComponentExist(ON.text(Keyword.RECORDING));
      await dr.delayMs(Delay.S_3);
      // 下拉至通知中心页面
      await dr.swipe(50, 0, 50, 580, 10000);
      await dr.delayMs(Delay.S_1);
      // 点击停止录音
      const stopBtn = await dr.waitForComponent(ON.id('.*?(com\\.\\.hmos\\.soundrecorder)(.*?)(stopped).*', MatchPattern.REG_EXP), Delay.S_1);
      await stopBtn.click();
      await dr.delayMs(Delay.S_1);
      LogUtil.info(TAG + ' stopBtn');
      // 返回录音机判断是否停止
      let point = await dr.getDisplaySize();
      await dr.swipe(0, point.y - 800, 500, point.y - 800, 10000);
      await dr.delayMs(Delay.S_1);
      await dr.assertComponentExist(ON.id('recorderBtn'));
      LogUtil.info(TAG + ' RecordingPageTest_009 end');
    });
  })
}