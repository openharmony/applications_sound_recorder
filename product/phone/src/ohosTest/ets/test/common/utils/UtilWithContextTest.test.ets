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
import { LogUtil, Util } from '@ohos/common';
import deviceInfo from '@ohos.deviceInfo';
import I18n from '@ohos.i18n';

const TAG: string = 'SoundRecorder_UtilWithContextTest';
const DEVICE_PRODUCT_MODEL_ALN: string = 'ALN-AL00';
const ALN_DEFAULT_DENSITY_PIXELS: number = 3.25;
const TEST_CONCAT_STR: string = '_test_concat_str';
const EXPECT_STR_SUFFIX: string = '总时长 ';
const LANGUAGE_ZH_HANS: string = 'zh-Hans';

export default function UtilWithContextTest() {
  describe('UtilWithContextTest', () => {
    /*
    * @tc.number:UtilWithContextTest_01
    * @tc.name: UtilWithContextTest_01
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: getDefaultDensityPixels接口获取默认显示大小测试
    */
    it('UtilWithContextTest_01', 0, async () => {
      LogUtil.info(`${TAG} UtilWithContextTest_01 start`);
      let defaultDP: number = Util.getDefaultDensityPixels(getContext());
      LogUtil.info(`${TAG} current defaultDP: ${defaultDP}`);
      let productModel: string = deviceInfo.productModel;
      if (productModel === DEVICE_PRODUCT_MODEL_ALN) {
        expect(defaultDP).assertEqual(ALN_DEFAULT_DENSITY_PIXELS);
      }
      LogUtil.info(`${TAG} UtilWithContextTest_01 end`);
    });

    /*
    * @tc.number:UtilWithContextTest_02
    * @tc.name: UtilWithContextTest_02
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: getFormatStringSync拼接字符串测试
    */
    it('UtilWithContextTest_02', 0, async () => {
      LogUtil.info(`${TAG} UtilWithContextTest_02 start`);
      let testResource: Resource = $r('app.string.total_duration');
      let durationBroadcastText: string = Util.getFormatStringSync(testResource, TEST_CONCAT_STR);
      let expectText: string = `${EXPECT_STR_SUFFIX}${TEST_CONCAT_STR}`;
      if (I18n.System.getSystemLanguage() === LANGUAGE_ZH_HANS) {
        expect(durationBroadcastText).assertEqual(expectText);
      }
      LogUtil.info(`${TAG} UtilWithContextTest_02 end`);
    });

    /*
    * @tc.number:UtilWithContextTest_03
    * @tc.name: UtilWithContextTest_03
    * @tc.type: 0 || TestType.FUNCTION  || Level.LEVEL0
    * @tc.desc: getAnyStrFormatStringSync拼接字符串测试
    */
    it('UtilWithContextTest_03', 0, async () => {
      LogUtil.info(`${TAG} UtilWithContextTest_03 start`);
      let testResource: Resource = $r('app.string.store_as_filename');
      let durationBroadcastText: string = Util.getAnyStrFormatStringSync(testResource, TEST_CONCAT_STR);
      let expectText: string = `保存为${TEST_CONCAT_STR}`;
      if (I18n.System.getSystemLanguage() === LANGUAGE_ZH_HANS) {
        expect(durationBroadcastText).assertEqual(expectText);
      }
      LogUtil.info(`${TAG} UtilWithContextTest_03 end`);
    });
  });
}
