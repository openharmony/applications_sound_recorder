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

import { describe, expect, it, MockKit, when } from '@ohos/hypium';
import { Driver, ON } from '@ohos.UiTest';
import { LogUtil } from '@ohos/common';
import { Delay, Keyword } from '@ohos/common/test';
import { BusinessError } from '@ohos.base';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import I18n from '@ohos.i18n';

const TAG: string = 'SoundRecorder_AccessibilityUtilTest';
const TEST_CONTENT = 'testContent';
const LANGUAGE_ZH_HANS: string = 'zh-Hans';
const MARK_COUNT_ONE: number = 1;
const MARK_COUNT_TWO: number = 2;

export default function AccessibilityUtilTest() {
  describe('AccessibilityUtilTest', () => {
    /*
    * @tc.number:AccessibilityUtilTest_01
    * @tc.name: AccessibilityUtilTest_01
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: AccessibilityUtil获取当前是否开启屏幕朗读接口验证
    */
    it('AccessibilityUtilTest_01', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_01 start');
      let isTouchGuide: boolean = AccessibilityUtil.isOpenTouchGuide();
      expect(isTouchGuide).assertFalse();
      LogUtil.info(TAG + ' AccessibilityUtilTest_01 end');
    });

    /*
    * @tc.number:AccessibilityUtilTest_02
    * @tc.name: AccessibilityUtilTest_02
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: sendAnnounceAccessibilityEvent 主动发起无障碍朗读接口验证
    */
    it('AccessibilityUtilTest_02', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_02 start');
      AccessibilityUtil.sendAnnounceAccessibilityEvent(TEST_CONTENT);
      expect(TEST_CONTENT).assertContain('test');
      LogUtil.info(TAG + ' AccessibilityUtilTest_02 end');
    });

    /*
    * @tc.number:AccessibilityUtilTest_03
    * @tc.name: AccessibilityUtilTest_03
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: sendFocusAccessibilityEvent 主动聚焦接口验证
    */
    it('AccessibilityUtilTest_03', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_03 start');
      try {
        const dr: Driver = Driver.create();
        await dr.delayMs(Delay.S_1);
        LogUtil.info(TAG + ' AccessibilityUtilTest_03 assert sound recorder text');
        await dr.assertComponentExist(ON.text(Keyword.SOUND_RECORDER));
        let titleComponent = await dr.waitForComponent(ON.text(Keyword.SOUND_RECORDER), Delay.S_5);
        let focused: boolean = await titleComponent.isFocused();
        expect(focused).assertFalse();
        AccessibilityUtil.sendFocusAccessibilityEvent(Keyword.SOUND_RECORDER);
        LogUtil.info(TAG + ' AccessibilityUtilTest_03 normal execution end');
      } catch (exception) {
        let errCode: number = (exception as BusinessError).code;
        let errMsg: string = (exception as BusinessError).message;
        LogUtil.info(`${TAG} Failed to execute, code : ${errCode}, message : ${errMsg}`);
      }
      LogUtil.info(TAG + ' AccessibilityUtilTest_03 end');
    });

    /*
    * @tc.number:AccessibilityUtilTest_04
    * @tc.name: AccessibilityUtilTest_04
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: getMarkListBroadCastContent 添加标签的无障碍行为测试
    */
    it('AccessibilityUtilTest_04', 0, async () => {
      LogUtil.info(`${TAG} AccessibilityUtilTest_04 start`);
      let expectFirst: string = '1项，共 1 项';
      let expectSecond: string = '1 至 2，共 2 项';
      // can not get result, need mock
      const mock = new MockKit();
      const mockFn = mock.mockFunc(AccessibilityUtil, AccessibilityUtil.getMarkListBroadCastContent);
      when(mockFn)(MARK_COUNT_ONE).afterReturn(expectFirst);
      when(mockFn)(MARK_COUNT_TWO).afterReturn(expectSecond);
      if (I18n.System.getSystemLanguage() === LANGUAGE_ZH_HANS) {
        // 添加第1个标签
        let broadCastTextFirst: string =
          AccessibilityUtil.getMarkListBroadCastContent(MARK_COUNT_ONE, MARK_COUNT_ONE, MARK_COUNT_ONE);
        // 添加第2个标签
        let broadCastTextSecond: string =
          AccessibilityUtil.getMarkListBroadCastContent(MARK_COUNT_TWO, MARK_COUNT_ONE, MARK_COUNT_TWO);
        expect(expectFirst).assertEqual(broadCastTextFirst);
        expect(expectSecond).assertEqual(broadCastTextSecond);
      }
      mock.clear(AccessibilityUtil);
      LogUtil.info(`${TAG} AccessibilityUtilTest_04 end`);
    });

    /*
* @tc.number:AccessibilityUtilTest_getDurationText
* @tc.name:获取时长工具测试类
*/
    it('AccessibilityUtilTest_getDurationText_001', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 start');
      expect(AccessibilityUtil.getDurationText(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 end');
    });

    it('AccessibilityUtilTest_getDurationText_002', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 start');
      expect(AccessibilityUtil.getDurationText(800)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 end');
    });

    it('AccessibilityUtilTest_getDurationText_003', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 start');
      expect(AccessibilityUtil.getDurationText(30000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 end');
    });

    it('AccessibilityUtilTest_getDurationText_004', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 start');
      expect(AccessibilityUtil.getDurationText(300000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 end');
    });

    it('AccessibilityUtilTest_getDurationText_005', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 start');
      expect(AccessibilityUtil.getDurationText(18000000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 end');
    });

    it('AccessibilityUtilTest_getDurationText_006', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 start');
      expect(AccessibilityUtil.getDurationText(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 end');
    });

    it('AccessibilityUtilTest_getDurationText_007', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 start');
      expect(AccessibilityUtil.getDurationText(800)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 end');
    });

    it('AccessibilityUtilTest_getDurationText_008', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 start');
      expect(AccessibilityUtil.getDurationText(30000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 end');
    });

    it('AccessibilityUtilTest_getDurationText_009', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 start');
      expect(AccessibilityUtil.getDurationText(300000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 end');
    });

    it('AccessibilityUtilTest_getDurationText_010', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 start');
      expect(AccessibilityUtil.getDurationText(18000000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 end');
    });

    it('AccessibilityUtilTest_getDurationText_011', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 start');
      expect(AccessibilityUtil.getDurationText(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 end');
    });

    it('AccessibilityUtilTest_getDurationText_012', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 start');
      expect(AccessibilityUtil.getDurationText(800)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 end');
    });

    it('AccessibilityUtilTest_getDurationText_013', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 start');
      expect(AccessibilityUtil.getDurationText(30000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 end');
    });

    it('AccessibilityUtilTest_getDurationText_014', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 start');
      expect(AccessibilityUtil.getDurationText(300000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 end');
    });

    it('AccessibilityUtilTest_getDurationText_015', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 start');
      expect(AccessibilityUtil.getDurationText(18000000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 end');
    });

    it('AccessibilityUtilTest_getDurationText_016', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 start');
      expect(AccessibilityUtil.getDurationText(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_001 end');
    });

    it('AccessibilityUtilTest_getDurationText_017', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 start');
      expect(AccessibilityUtil.getDurationText(800)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_002 end');
    });

    it('AccessibilityUtilTest_getDurationText_018', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 start');
      expect(AccessibilityUtil.getDurationText(30000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_003 end');
    });

    it('AccessibilityUtilTest_getDurationText_019', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 start');
      expect(AccessibilityUtil.getDurationText(300000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_004 end');
    });

    it('AccessibilityUtilTest_getDurationText_020', 0, async () => {
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 start');
      expect(AccessibilityUtil.getDurationText(18000000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' AccessibilityUtilTest_getDurationText_005 end');
    });
  })
}
