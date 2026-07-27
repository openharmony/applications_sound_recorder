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

import { LogUtil } from '../../../index';
import { Delay, Keyword } from '../../../test';
import { Component, Driver, ON } from '@ohos.UiTest';

export class Director {
  /**
   * 开启录音
   * 初始化，完成同意使用、授权麦克风&位置
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  public static async startRecording(tag: string, driver: Driver): Promise<void> {
    // 点击同意
    const agreeButton = await driver.waitForComponent(ON.text(Keyword.AGREE), Delay.S_1);
    // instrument ignore if
    if (agreeButton) {
      await agreeButton.click();
      LogUtil.info(`${tag} agree to use sound recorder.`);
    }

    // 点击录音
    const recordButton = await driver.waitForComponent(ON.id('recorderBtn'), Delay.S_1);
    await recordButton.click();
    LogUtil.info(`${tag} recordButton clicked.`);

    // 授予麦克风权限
    const permitBtn = await driver.waitForComponent(ON.text(Keyword.ALLOW), Delay.S_1);
    if (permitBtn) {
      await permitBtn.click();
      LogUtil.info(`${tag} permitBtn clicked.`);
    }

    // 授予位置信息权限
    const allowForThisUsingBtn = await driver.waitForComponent(ON.text(Keyword.ALLOW_FOR_THIS_USING), Delay.S_3);
    // instrument ignore if
    if (allowForThisUsingBtn) {
      await allowForThisUsingBtn.click();
      LogUtil.info(`${tag} allowForThisUsingBtn clicked.`);
    }
    const allowOnlyDuringUsingBtn = await driver.waitForComponent(ON.text(Keyword.ALLOW_ONLY_DURING_USING), Delay.S_3);
    // instrument ignore if
    if (allowOnlyDuringUsingBtn) {
      await allowOnlyDuringUsingBtn.click();
      LogUtil.info(`${tag} allowOnlyDuringUsingBtn clicked.`);
    }
  }

  /**
   * 停止录音
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  public static async stopRecording(tag: string, driver: Driver): Promise<void> {
    const recordBtn = await driver.waitForComponent(ON.id('recordBtn'), Delay.S_1);
    await recordBtn.click();
    LogUtil.info(`${tag} recordBtn clicked.`);
  }

  /**
   * 暂停或继续录音
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  public static async resumeRecording(tag: string, driver: Driver): Promise<void> {
    const resumeBtn = await driver.waitForComponent(ON.id('resumeBtn'), Delay.S_1);
    await resumeBtn.click();
    LogUtil.info(`${tag} resumeBtn clicked.`);
  }

  /**
   * 删除录音标记
   * @param tag 测试套tag
   * @param driver 上下文driver
   * @param markBadge 上下文mark badge
   */
  public static async deleteRecordMark(tag: string, driver: Driver, markBadge: Component): Promise<void> {
    await markBadge.longClick();
    await driver.delayMs(Delay.S_1);
    LogUtil.info(`${tag} markBadge clicked.`);

    await driver.assertComponentExist(ON.text(Keyword.DELETE));
    const deleteBtn = await driver.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
    await deleteBtn.click();
    await driver.delayMs(Delay.S_1);
    LogUtil.info(`${tag} deleteBtn clicked.`);
  }

  /**
   * 重命名录音标记
   * @param tag 测试套tag
   * @param driver 上下文driver
   * @param markBadge 上下文mark badge
   * @param newName new name
   */
  public static async renameRecordMark(tag: string, driver: Driver, markBadge: Component,
    newName: string): Promise<void> {
    await markBadge.longClick();
    await driver.delayMs(Delay.S_1);
    LogUtil.info(`${tag} markBadge clicked.`);

    await driver.assertComponentExist(ON.text(Keyword.RENAME));
    const renameBtn = await driver.waitForComponent(ON.text(Keyword.RENAME), Delay.S_1);
    await renameBtn.click();
    await Director.checkInputMethodPopUp(tag, driver);
    await driver.delayMs(Delay.S_1);
    LogUtil.info(`${tag} renameBtn clicked.`);

    const renameInput = await driver.waitForComponent(ON.type('TextInput'), Delay.S_3);
    await renameInput.inputText(newName);
    let confirmRenameBtn = await driver.waitForComponent(ON.text(Keyword.CONFIRM), Delay.S_1);
    await confirmRenameBtn.click();
    await driver.delayMs(Delay.S_1);
    LogUtil.info(`${tag} confirmRenameBtn clicked.`);
  }

  /**
   * 避让处理
   * 当前dt执行时，点击音频跳转播放页会点到进度条上，导致dt执行失败
   * @param driver 上下文driver
   * @param target audio item
   */
  public static async clickAudioItem(driver: Driver, target: Component): Promise<void> {
    const rt = await target.getBounds();
    const point = await target.getBoundsCenter();
    const x = Math.floor(rt.left + (point.x - rt.left) / 2);
    const y = Math.floor(rt.top + (point.y - rt.top) / 2);
    await driver.click(x, y);
  }

  /**
   * 获取列表第1条录音
   * @param driver
   * @returns
   */
  public static async getTop1AudioItem(driver: Driver): Promise<Component> {
    const list = await driver.findComponents(ON.type('ListItem'));
    return list[1];
  }

  /**
   * 获取最近删除页面列表第1条录音
   * @param driver
   * @returns
   */
  public static async getFirstAudioItem(driver: Driver): Promise<Component> {
    const list = await driver.findComponents(ON.type('ListItem'));
    return list[0];
  }

  /**
   * 手动点击输入法弹窗
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  // instrument ignore next
  public static async checkInputMethodPopUp(tag: string, driver: Driver): Promise<void> {
    // 输入法弹窗点击同意
    const agreeButton = await driver.waitForComponent(ON.text(Keyword.AGREE), Delay.S_1);
    if (agreeButton) {
      await agreeButton.click();
      LogUtil.info(`${tag} pop-up click agree.`);
    } else {
      LogUtil.info(`${tag} pop-up click agree error.`);
    }
    // 输入法弹窗点击下一步
    const nextStepButton = await driver.waitForComponent(ON.text(Keyword.NEXT_STEP), Delay.S_1);
    if (nextStepButton) {
      await nextStepButton.click();
      LogUtil.info(`${tag} pop-up click next step.`);
    } else {
      LogUtil.info(`${tag} pop-up click next step error.`);
    }
  }

  /**
   * 寻找包含指定字段的卡片
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  // instrument ignore next
  public static async lookUpStringCard(tag: string, driver: Driver, stringid: string): Promise<Component> {
    // 检测当前页面是否存在2x2卡片
    let recordBtn = await driver.waitForComponent(ON.id(stringid), Delay.S_1);
    while (!recordBtn) {
      await driver.fling({ x: 900, y: 1000 }, { x: 400, y: 1000 }, 5, 6000);
      await driver.delayMs(Delay.S_1);
      LogUtil.info(tag + ' lookUp2x2Card fling');
      recordBtn = await driver.waitForComponent(ON.id(stringid), Delay.S_1);
    }
    return recordBtn;
  }

  /**
   * 寻找包含指定字段的按钮
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  // instrument ignore next
  public static async lookUpStringButton(tag: string, driver: Driver, textstring: string): Promise<Component> {
    // 检测当前页面是否存在2x2卡片
    let recordBtn = await driver.waitForComponent(ON.text(textstring), Delay.S_1);
    while (!recordBtn) {
      await driver.fling({ x: 900, y: 1000 }, { x: 400, y: 1000 }, 5, 6000);
      await driver.delayMs(Delay.S_1);
      LogUtil.info(tag + ' lookUp2x2Card fling');
      recordBtn = await driver.waitForComponent(ON.text(textstring), Delay.S_1);
    }
    return recordBtn;
  }

  /**
   * 删除录音文件并进入最近删除页面
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  // instrument ignore next
  public static async deleteToRecyclePage(tag: string, driver: Driver): Promise<void> {
    // 点击删除
    let topItem = await Director.getTop1AudioItem(driver);
    await topItem.longClick();
    await driver.delayMs(Delay.S_1);
    let deletionBtn = await driver.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
    await deletionBtn.click();
    await driver.delayMs(Delay.S_1);
    LogUtil.info(tag + ' deletionBtn clicked');

    // 校验删除弹窗,点击删除按钮
    await driver.assertComponentExist(ON.text(Keyword.DELETE_RECORD));
    let confirmBtn = await driver.waitForComponent(ON.text(Keyword.DELETE), Delay.S_1);
    await confirmBtn.click();
    await driver.delayMs(Delay.S_1);
    LogUtil.info(tag + ' confirmBtn clicked');

    // 进入最近删除页面
    let sideBarButton = await driver.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
    await sideBarButton.click();
    await driver.delayMs(Delay.S_1);
    let recentlyDeleted = await driver.waitForComponent(ON.text(Keyword.RECENTLY_DELETED), Delay.S_1);
    await recentlyDeleted.click();
    await driver.delayMs(Delay.S_1);
  }

  /**
   * 进入录音页面
   * @param tag 测试套tag
   * @param driver 上下文driver
   */
  // instrument ignore next
  public static async BackToRecordingPage(tag: string, driver: Driver): Promise<void> {
    let sideBarButton = await driver.waitForComponent(ON.id('side_bar_button'), Delay.S_1);
    await sideBarButton.click();
    await driver.delayMs(Delay.S_1);
    let recorderBtn = await driver.waitForComponent(ON.text(Keyword.RECORDING), Delay.S_1);
    await recorderBtn.click();
    await driver.delayMs(Delay.S_1);
  }

  public static async closeShareModal(tag: string, dr: Driver): Promise<void> {
    const titleCmp = await dr.waitForComponent(ON.id('HdsTitleBar'), Delay.S_1);
    const rt = await titleCmp.getBounds();
    const point = await titleCmp.getBoundsCenter();
    const x = rt.right - 110;
    const y = point.y;
    await dr.click(x, y);
    await dr.delayMs(Delay.S_1);
    LogUtil.info(`${tag} close share modal`);
  }

  public static async clickSwipeDelBtn(tag: string, cmp: Component, dr: Driver): Promise<void> {
    const rt = await cmp.getBounds();
    const p = await cmp.getBoundsCenter();
    const x = rt.right - 160
    const y = p.y;
    await dr.click(x, y);
    await dr.delayMs(Delay.S_1);
    LogUtil.info(`${tag} delete btn clicked`);
  }
}
