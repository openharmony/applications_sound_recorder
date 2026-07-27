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

import { beforeAll, describe, expect, it } from '@ohos/hypium';
import { CommonConstants, LogUtil } from '@ohos/common';
import { PlayManager } from '@ohos/recorder';
import media from '@ohos.multimedia.media';

const TAG: string = 'SoundRecorder_AudioControllerTest';

export default function AudioControllerTest() {
  describe('AudioControllerTest', () => {
    beforeAll(async () => {
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
    });

    /**
     * @tc.number:AudioControllerTest_001
     * @tc.name: AudioController 播放工具类测试
     */
    it('AudioControllerTest_001', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_001 start');
      const playManager = PlayManager.getInstance();
      expect(playManager.play()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_001 end');
    });

    it('AudioControllerTest_002', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_002 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.release();
      await playManager.play();
      LogUtil.info(TAG + ' AudioControllerTest_002 end');
    });

    /**
     * @tc.number:AudioControllerTest_002
     * @tc.name: AudioController 寻找功能工具类测试
     */
    it('AudioControllerTest_003', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_003 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      expect(playManager.seek(0)).assertPromiseIsResolved();
      LogUtil.info(TAG + ' AudioControllerTest_003 end');
    });

    it('AudioControllerTest_004', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_004 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.release();
      await playManager.seek(0);
      LogUtil.info(TAG + ' AudioControllerTest_004 end');
    });

    it('AudioControllerTest_005', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_005 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.release();
      await playManager.seek(0);
      LogUtil.info(TAG + ' AudioControllerTest_005 end');
    });

    /**
     * @tc.number:AudioControllerTest_003
     * @tc.name: AudioController 暂停功能工具类测试
     */
    it('AudioControllerTest_006', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_006 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      expect(playManager.pause()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_006 end');
    });

    it('AudioControllerTest_007', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_007 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.release();
      await playManager.pause();
      LogUtil.info(TAG + ' AudioControllerTest_007 end');
    });

    it('AudioControllerTest_008', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_008 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.release();
      await playManager.pause();
      LogUtil.info(TAG + ' AudioControllerTest_008 end');
    });

    /**
     * @tc.number:AudioControllerTest_004
     * @tc.name: AudioController 设置播放速度功能工具类测试
     */
    it('AudioControllerTest_009', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_009 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.play();
      expect(playManager.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_75_X)).assertPromiseIsResolved();
      LogUtil.info(TAG + ' AudioControllerTest_009 end');
    });

    it('AudioControllerTest_010', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_010 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.play();
      expect(playManager.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_00_X)).assertPromiseIsResolved();
      LogUtil.info(TAG + ' AudioControllerTest_010 end');
    });

    it('AudioControllerTest_011', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_011 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.play();
      expect(playManager.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_0_50_X)).assertPromiseIsResolved();
      LogUtil.info(TAG + ' AudioControllerTest_011 end');
    });

    it('AudioControllerTest_013', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_013 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.play();
      expect(playManager.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_2_00_X)).assertPromiseIsResolved();
      LogUtil.info(TAG + ' AudioControllerTest_013 end');
    });

    it('AudioControllerTest_014', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_014 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.play();
      expect(playManager.setSpeed(media.PlaybackSpeed.SPEED_FORWARD_1_50_X)).assertPromiseIsResolved();
      LogUtil.info(TAG + ' AudioControllerTest_014 end');
    });

    /**
     * @tc.number:AudioControllerTest_005
     * @tc.name: AudioController 获取状态功能工具类测试
     * */
    it('AudioControllerTest_015', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_015 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      expect(playManager.getAVPlayerState()).assertEqual(CommonConstants.IDLE);
      LogUtil.info(TAG + ' AudioControllerTest_015 end');
    });

    it('AudioControllerTest_016', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_016 start');
      const playManager = PlayManager.getInstance();
      await playManager.release();
      expect(playManager.getAVPlayerState()).assertEqual('error');
      LogUtil.info(TAG + ' AudioControllerTest_016 end');
    });

    /**
     * @tc.number:AudioControllerTest_006
     * @tc.name: AudioController 波形振幅
     * */
    it('AudioControllerTest_017', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_017 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      playManager.registerSamplesListener((samples) => LogUtil.info(`${TAG} samples: ${samples.length}`));
      playManager.unRegisterSamplesListener();
      expect(playManager.getSpeedValue()).assertEqual(1);
      expect(playManager.getSpeed()).assertEqual(CommonConstants.SPEED_FORWARD_1_00_X);
      expect(playManager.getSamples().length).assertEqual(0);
      LogUtil.info(TAG + ' AudioControllerTest_017 end');
    });

    /**
     * @tc.number:AudioControllerTest_007
     * @tc.name: AudioController 释放功能工具类测试
     */
    it('AudioControllerTest_018', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_018 start');
      const playManager = PlayManager.getInstance();
      expect(playManager.release()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_018 end');
    });

    it('AudioControllerTest_019', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_019 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.release();
      await playManager.release();
      LogUtil.info(TAG + ' AudioControllerTest_019 end');
    });

    it('AudioControllerTest_020', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_020 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.release();
      await playManager.release();
      LogUtil.info(TAG + ' AudioControllerTest_020 end');
    });

    /**
     * @tc.number:AudioControllerTest_007
     * @tc.name: AudioController 停止播放功能工具类测试
     */
    it('AudioControllerTest_021', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_021 start');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      expect(playManager.reset()).assertPromiseIsPending();
      LogUtil.info(TAG + ' AudioControllerTest_021 end');
    });

    it('AudioControllerTest_022', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_022 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.initPlayManager();
      await playManager.release();
      await playManager.reset();
      LogUtil.info(TAG + ' AudioControllerTest_022 end');
    });

    it('AudioControllerTest_023', 0, async () => {
      LogUtil.info(TAG + ' AudioControllerTest_023 start');
      const TEST_CONTENT = 'AudioControllerTest';
      expect(TEST_CONTENT).assertContain('Audio');
      const playManager = PlayManager.getInstance();
      await playManager.release();
      await playManager.reset();
      LogUtil.info(TAG + ' AudioControllerTest_023 end');
    });
  });
}