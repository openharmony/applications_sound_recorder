/**
 * Copyright (c) 2022 HiHope Open Source Organization.
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

import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { Util } from '@ohos/common';
import { RecordController, RecordState, StateController, ControlState } from '@ohos/recorder';

export default function abilityTest() {
  describe('ActsAbilityTest', function () {

    it('StateControllerStart', 0, async function () {
      let mStateController = new StateController();
      let testState = false;
      mStateController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(ControlState.START);
          testState = false;
        }
      });
      testState = true;
      mStateController.start();
    })

    it('StateControllerEnd', 0, async function () {
      let mStateController = new StateController();
      let testState = false;
      mStateController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(ControlState.END);
          testState = false;
        }
      });
      mStateController.start();
      testState = true;
      setTimeout(() => {
        mStateController.end();
      }, 100);
    })

    it('addZeroMin', 0, async function () {
      let num = 0;
      let res = Util.addZero(num);
      expect(res).assertEqual('00');
    })

    it('addZeroMinus', 0, async function () {
      let num = -1;
      let res = Util.addZero(num);
      expect(res).assertEqual('0-1');
    })

    it('addZeroMax', 0, async function () {
      let num = 9;
      let res = Util.addZero(num);
      expect(res).assertEqual('09');
    })

    it('addZeroOver', 0, async function () {
      let num = 10;
      let res = Util.addZero(num);
      expect(res).assertEqual('10');
    })

    it('addZeroNaN', 0, async function () {
      let num = NaN;
      let res = Util.addZero(num);
      expect(res).assertEqual('NaN');
    })

    it('getTime', 0, async function () {
      let nowDate = new Date();
      let time = Util.getTime();
      let res = false;
      if (parseInt(time.substring(0, 2)) == nowDate.getHours() && parseInt(time.substring(2, 4)) == nowDate.getMinutes() && parseInt(time.substring(4, 6)) == nowDate.getSeconds()) {
        res = true;
      }
      expect(res).assertTrue();
    })

    it('getDate', 0, async function () {
      let nowDate = new Date();
      let time = Util.getDate();
      let res = false;
      if (parseInt(time.substring(0, 4)) == nowDate.getFullYear() && parseInt(time.substring(4, 6)) == nowDate.getMonth() + 1 && parseInt(time.substring(6, 8)) == nowDate.getDate()) {
        res = true;
      }
      expect(res).assertTrue();
    })

    it('getTimeFormatZero', 0, async function () {
      let time = 0;
      let res = Util.getTimeFormat(time);
      expect(res).assertEqual('00:00:00');
    })

    it('getTimeFormat', 0, async function () {
      let time = new Date('2022-11-11T11:11:11').getTime();
      let res = Util.getTimeFormat(time);
      expect(res).assertEqual('11:11:11');
    })

    it('getDateFormat', 0, async function () {
      let time = new Date('2022-11-11T11:11:11').getTime();
      let res = Util.getDateFormat(time);
      expect(res).assertEqual('2022/11/11');
    })

    it('getDateFormatZero', 0, async function () {
      let time = 0;
      let res = Util.getDateFormat(time);
      expect(res).assertEqual('1970/01/01');
    })

    it('timeFormatMsZero', 0, async function () {
      let time = 0;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('00:00.00');
    })

    it('timeFormatMsMinus', 0, async function () {
      let time = -1;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('00:00.00');
    })

    it('timeFormatMsMin', 0, async function () {
      let time = 9;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('00:00.00');
    })

    it('timeFormatMsMs', 0, async function () {
      let time = 10;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('00:00.01');
    })

    it('timeFormatMsSecond', 0, async function () {
      let time = 1000;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('00:01.00');
    })

    it('timeFormatMsMinute', 0, async function () {
      let time = 60 * 1000;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('01:00.00');
    })

    it('timeFormatMsHour', 0, async function () {
      let time = 60 * 60 * 1000;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('01:00:00');
    })

    it('timeFormatMsDay', 0, async function () {
      let time = 24 * 60 * 60 * 1000;
      let res = Util.timeFormatMs(time);
      expect(res).assertEqual('00:00.00');
    })

    it('timeFormatMinus', 0, async function () {
      let time = -1;
      let res = Util.timeFormat(time);
      expect(res).assertEqual('');
    })

    it('timeFormatZeroH', 0, async function () {
      let time = 0;
      let res = Util.timeFormat(time);
      expect(res).assertEqual(`00:00:00`);
    })

    it('timeFormatZero', 0, async function () {
      let time = 0;
      let res = Util.timeFormat(time, false);
      expect(res).assertEqual(`00:00`);
    })

    it('timeFormatMinH', 0, async function () {
      let time = 999;
      let res = Util.timeFormat(time);
      expect(res).assertEqual(`00:00:00`);
    })

    it('timeFormatMin', 0, async function () {
      let time = 999;
      let res = Util.timeFormat(time, false);
      expect(res).assertEqual(`00:00`);
    })

    it('timeFormatSecondH', 0, async function () {
      let time = 1000;
      let res = Util.timeFormat(time);
      expect(res).assertEqual(`00:00:01`);
    })

    it('timeFormatSecond', 0, async function () {
      let time = 1000;
      let res = Util.timeFormat(time, false);
      expect(res).assertEqual(`00:01`);
    })

    it('timeFormatMinuteH', 0, async function () {
      let time = 60 * 1000;
      let res = Util.timeFormat(time);
      expect(res).assertEqual(`00:01:00`);
    })

    it('timeFormatMinute', 0, async function () {
      let time = 60 * 1000;
      let res = Util.timeFormat(time, false);
      expect(res).assertEqual(`01:00`);
    })

    it('timeFormatHour', 0, async function () {
      let time = 60 * 60 * 1000;
      let res = Util.timeFormat(time);
      expect(res).assertEqual(`01:00:00`);
    })

    it('timeFormatDay', 0, async function () {
      let time = 24 * 60 * 60 * 1000;
      let res = Util.timeFormat(time, false);
      expect(res).assertEqual(`00:00`);
    })

    it('RecordControllerStartTime', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(RecordState.RUNNING);
          testState = false;
        }
      });
      testState = true;
      mRecordController.startTime();
    })

    it('RecordStartTime', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setTimeUpdateListener((time) => {
        if (testState) {
          expect(time > 0).assertTrue();
          testState = false;
        }
      });
      testState = true;
      mRecordController.startTime();
    })

    it('RecordControllerPause', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(RecordState.PAUSED);
          testState = false;
        }
      });
      mRecordController.startTime();
      testState = true;
      setTimeout(() => {
        mRecordController.pause();
      }, 100);
    })

    it('RecordControllerResume', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(RecordState.RUNNING);
          testState = false;
        }
      });
      mRecordController.startTime();
      mRecordController.pause();
      testState = true;
      setTimeout(() => {
        mRecordController.resume();
      }, 100);
    })

    it('RecordControllerPauseStop', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(RecordState.IDLE);
          testState = false;
        }
      });
      mRecordController.startTime();
      mRecordController.pause();
      setTimeout(() => {
        mRecordController.stop(() => {
          testState = true;
        });
      }, 100);
    })

    it('RecordControllerStop', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setStateUpdateListener((state) => {
        if (testState) {
          expect(state).assertEqual(RecordState.IDLE);
          testState = false;
        }
      });
      mRecordController.startTime();
      setTimeout(() => {
        mRecordController.stop(() => {
          testState = true;
        });
      }, 100);
    })

    it('RecordStop', 0, async function () {
      let mRecordController = new RecordController();
      mRecordController.initAudioRecorder();
      let testState = false;
      mRecordController.setTimeUpdateListener((time) => {
        if (testState) {
          expect(time).assertEqual(0);
          testState = false;
        }
      });
      mRecordController.startTime();
      setTimeout(() => {
        mRecordController.stop(() => {
          testState = true;
        });
      }, 100);
    })

  })
}