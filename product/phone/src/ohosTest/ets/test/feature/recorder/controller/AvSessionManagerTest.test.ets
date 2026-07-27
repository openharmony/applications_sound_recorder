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
import { CommonConstants, LogUtil } from '@ohos/common';
import { AvSessionManager } from '@ohos/recorder';
import avSession from '@ohos.multimedia.avsession';

const TAG: string = 'SoundRecorder_AvSessionManagerTest';

export default function AvSessionManagerTest() {

  describe('AvSessionManagerTest', () => {

    it('AvSessionManagerTest_001', 0, async () => {
      LogUtil.info(TAG + ' AvSessionManagerTest_001 start');
      const avSessionManager = AvSessionManager.getInstance();
      avSessionManager.updatePlaybackState(0, 1, 'playing', 'SoundRecorder_AvSessionManager');
      let currentState: avSession.AVPlaybackState = avSessionManager.getCurrentState();
      expect(currentState.speed).assertEqual(CommonConstants.SPEED_FORWARD_1_00_X);
      expect(currentState.state).assertEqual(avSession.PlaybackState.PLAYBACK_STATE_PLAY);
      LogUtil.info(TAG + ' AvSessionManagerTest_001 end');
    });

    it('AvSessionManagerTest_002', 0, async () => {
      LogUtil.info(TAG + ' AvSessionManagerTest_002 start');
      const avSessionManager = AvSessionManager.getInstance();
      avSessionManager.setSpeed(0, 1);
      let currentState: avSession.AVPlaybackState = avSessionManager.getCurrentState();
      expect(currentState.speed).assertEqual(CommonConstants.SPEED_FORWARD_1_00_X);
      LogUtil.info(TAG + ' AvSessionManagerTest_002 end');
    });

    it('AvSessionManagerTest_003', 0, async () => {
      LogUtil.info(TAG + ' AvSessionManagerTest_003 start');
      const avSessionManager = AvSessionManager.getInstance();
      avSessionManager.seek(1);
      let currentState: avSession.AVPlaybackState = avSessionManager.getCurrentState();
      expect(currentState.position?.elapsedTime).assertEqual(1);
      LogUtil.info(TAG + ' AvSessionManagerTest_003 end');
    });

  });
}