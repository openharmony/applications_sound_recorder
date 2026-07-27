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
import { CommonConstants, LogUtil } from '@ohos/common';
import SampleUtil from '@ohos/common/src/main/ets/utils/SampleUtil';
import { describe, expect, it, beforeAll } from '@ohos/hypium';
import { RecordManager } from '@ohos/recorder';
import { ArrayList } from '@kit.ArkTS';

const TAG: string = 'SoundRecorder_AvRecorderTest';

export default function AvRecorderTest() {
  describe('avRecorderTest', () => {
    beforeAll(async () => {
      const recordManager = RecordManager.getInstance();
      await recordManager.initAvRecorder();
    });
    /**
     * @tc.number:avRecorderTest_001
     * @tc.name: avRecorder工具类测试
     */
    it("AvRecorderTest_001", 0, () => {
      const recordManager = RecordManager.getInstance();
      LogUtil.info(TAG + ' AudioControllerTest_001 start');
      expect(recordManager.start()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_001 end');
    });

    /**
     * @tc.number:AvRecorderTest_002
     * @tc.name: 暂停录制对应的流程工具测试
     */
    it("AvRecorderTest_002", 0, () => {
      const recordManager = RecordManager.getInstance();
      LogUtil.info(TAG + ' AudioControllerTest_002 start');
      expect(recordManager.pause()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_002 end');
    });

    /**
     * @tc.number:AvRecorderTest_002
     * @tc.name: 恢复录制对应的流程工具测试
     */
    it("AvRecorderTest_003", 0, () => {
      const recordManager = RecordManager.getInstance();
      LogUtil.info(TAG + ' AudioControllerTest_003 start');
      expect(recordManager.resume()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_003 end');
    });

    /**
     * @tc.number:AvRecorderTest_004
     * @tc.name: 获取音频振幅和时长的流程测试
     */
    it("AvRecorderTest_004", 0, () => {
      const recordManager = RecordManager.getInstance();
      recordManager.getAmplitude((sample) => {
        LogUtil.info(TAG + ' AudioControllerTest_004 getAmplitude : ' + sample);
      });
      recordManager.updateCallState(9);
      recordManager.updateCallState(6);
      LogUtil.info(TAG + ' AudioControllerTest_004 addSample');
      let duration = recordManager.getRecorderDuration();
      LogUtil.info(TAG + ' AudioControllerTest_004 getRecorderDuration');
      expect(duration).assertEqual(0);
    });

    /**
     * @tc.number:AvRecorderTest_005
     * @tc.name: 获取录音时长
     */
    it("AvRecorderTest_005", 0, () => {
      const recordManager = RecordManager.getInstance();
      recordManager.calculateRecordTime(CommonConstants.PREPARED);
      recordManager.calculateRecordTime(CommonConstants.STARTED);
      recordManager.calculateRecordTime(CommonConstants.STOPPED);
      recordManager.calculateRecordTime(CommonConstants.RELEASED);
      recordManager.calculateRecordTime(CommonConstants.ERROR);
      expect(recordManager.getRecordTime()).assertEqual(0);
    });
    /**
     * @tc.number:AvRecorderTest_006
     * @tc.name: SampleUtil
     */
    it("AvRecorderTest_006", 0, async () => {
      const recordManager = RecordManager.getInstance();
      expect(recordManager.getRealtimeWaves().length).assertEqual(0);
      let samples: number[] = await SampleUtil.fixSamples(0, []);
      expect(samples.length).assertEqual(0);
      expect(SampleUtil.sampleToWaveLine(0)).assertEqual(0);
    });
  })
}
