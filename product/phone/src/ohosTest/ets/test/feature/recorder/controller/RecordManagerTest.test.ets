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

import { ArgumentMatchers, describe, expect, it, MockKit, when } from '@ohos/hypium';
import { LogUtil } from '@ohos/common';
import { RecordManager } from '@ohos/recorder';
import media from '@ohos.multimedia.media';
import ArrayList from '@ohos.util.ArrayList';

const TAG: string = 'SoundRecorder_RecordManagerTest';

export default function RecordManagerTest() {

  describe('RecordManagerTest', () => {

    it('RecordManagerTest_001', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_001 start');
      const recordManager = RecordManager.getInstance();
      recordManager.calculateRecordTime('');
      expect(recordManager.getRecordStartTime()).assertEqual(0);
      LogUtil.info(TAG + ' RecordManagerTest_001 end');
    });

    it('RecordManagerTest_002', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_002 start');
      const recordManager = RecordManager.getInstance();
      let avRecorder: media.AVRecorder = await media.createAVRecorder();
      let mock: MockKit = new MockKit();
      let obj: Object = mock.mockObject(avRecorder);
      let func: Function = mock.mockFunc(obj, avRecorder.start);
      when(func)(ArgumentMatchers.any).afterThrow('error');
      recordManager.avRecorder = avRecorder;
      recordManager.start();
      expect(recordManager.avRecorder.state).assertEqual('idle');
      LogUtil.info(TAG + ' RecordManagerTest_002 end');
    });

    it('RecordManagerTest_003', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_003 start');
      const recordManager = RecordManager.getInstance();
      let avRecorder: media.AVRecorder = await media.createAVRecorder();
      recordManager.avRecorder = avRecorder;
      recordManager.pause().then((res) => {
        expect(res).assertEqual(5400102);
      });
      LogUtil.info(TAG + ' RecordManagerTest_003 end');
    });

    it('RecordManagerTest_004', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_004 start');
      const recordManager = RecordManager.getInstance();
      let avRecorder: media.AVRecorder = await media.createAVRecorder();
      recordManager.avRecorder = avRecorder;
      recordManager.resume().then((res) => {
        expect(res).assertEqual(5400102);
      });
      LogUtil.info(TAG + ' RecordManagerTest_004 end');
    });

    it('RecordManagerTest_005', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_005 start');
      const recordManager = RecordManager.getInstance();
      let time: number = recordManager.getRecordTime();
      expect(time >= 0).assertTrue();
      LogUtil.info(TAG + ' RecordManagerTest_005 end');
    });

    it('RecordManagerTest_006', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_006 start');
      const recordManager = RecordManager.getInstance();
      await recordManager.initAvRecorder();
      expect(recordManager.avRecorder?.state).assertEqual('idle');
      LogUtil.info(TAG + ' RecordManagerTest_006 end');
    });

    it('RecordManagerTest_007', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_007 start');
      const recordManager = RecordManager.getInstance();
      recordManager.startAmplitudeTimer();
      expect(recordManager.getRecordTime() >= 0).assertTrue();
      LogUtil.info(TAG + ' RecordManagerTest_007 end');
    });

    it('RecordManagerTest_008', 0, async () => {
      LogUtil.info(TAG + ' RecordManagerTest_008 start');
      const recordManager = RecordManager.getInstance();
      let waves: ArrayList<number> = recordManager.getRealtimeWaves();
      expect(waves.length).assertLargerOrEqual(0);
      LogUtil.info(TAG + ' RecordManagerTest_008 end');
    });

  });
}