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

import media from '@ohos.multimedia.media';
import { LogUtil } from '@ohos/common';
import Notification from '@ohos.notification';

const NOTIFY_INTERVAL_MS = 60;
const NOTIFY_ID = 10023;
const TAG = 'RecordController : ';

let audioConfig = {
  audioEncodeBitRate: 22050,
  audioSampleRate: 22050,
  numberOfChannels: 2,
  uri: '',
  location: { latitude: 31, longitude: 118 },
  audioEncoderMime: media.CodecMimeType.AUDIO_AAC,
  fileFormat: media.ContainerFormatType.CFT_MPEG_4A,
}

export enum RecordState {
  IDLE,
  RUNNING,
  PAUSED,
}

export class RecordController {
  private beforePauseTime: number = 0;
  private startTimestamp: number = 0;
  private notifierId: number = -1;
  private state: RecordState = RecordState.PAUSED;
  private currentTimeMs: number = 0;
  private audioRecorder: media.AudioRecorder = undefined;
  private timeUpdateListener: (currentTimeMs: number) => void = undefined;
  private stateUpdateListener: (RecordState) => void = undefined;

  /**
   * Notification time update
   */
  private notifyTimeChanges() {
    if (this.timeUpdateListener) {
      this.timeUpdateListener(this.currentTimeMs);
    }
  }

  /**
   * Notification of status updates
   */
  private async notifyStateChanges() {
    if (this.stateUpdateListener) {
      LogUtil.info(`${TAG} state update. ${this.state}`);
      this.stateUpdateListener(this.state);
    }
  }

  /**
   * Set the time update listener
   *
   * @param listener
   */
  public setTimeUpdateListener(listener: (currentTimeMs: number) => void) {
    LogUtil.info(`${TAG} setTimeUpdateListener.`);
    this.timeUpdateListener = listener;
  }

  /**
   * Set the status update listener
   *
   * @param listener
   */
  public setStateUpdateListener(listener: (RecordState) => void) {
    LogUtil.info(`${TAG} setStateUpdateListener.`);
    this.stateUpdateListener = listener;
  }

  /**
   * init AudioRecorder
   */
  initAudioRecorder() {
    LogUtil.info(`${TAG} initAudioRecorder.`);
    let recording_hint
    let suspend_record_hint
    globalThis.abilityContext.resourceManager.getString($r('app.string.recording_hint').id).then((value) => {
      recording_hint = value
    })
    globalThis.abilityContext.resourceManager.getString($r('app.string.suspend_record_hint').id).then((value) => {
      suspend_record_hint = value
    })
    this.audioRecorder = media.createAudioRecorder();
    this.audioRecorder.on('prepare', () => {
      LogUtil.info(`${TAG} audioRecorder prepare success.`);
      this.audioRecorder.start();
    });
    this.audioRecorder.on('start', () => {
      LogUtil.info(`${TAG} audioRecorder start success.`);
      this.publishNotification(recording_hint)
      this.startTime();
    });
    this.audioRecorder.on('pause', () => {
      LogUtil.info(`${TAG} audioRecorder pause success`);
      this.publishNotification(suspend_record_hint)
      clearInterval(this.notifierId);
      this.notifierId = -1;
      this.beforePauseTime += new Date().getTime() - this.startTimestamp;
      this.state = RecordState.PAUSED;
      this.notifyStateChanges();
    });
    this.audioRecorder.on('resume', () => {
      LogUtil.info(`${TAG} audioRecorder resume success`);
      this.publishNotification(recording_hint)
      this.startTime();
    });
    this.audioRecorder.on('stop', () => {
      LogUtil.info(`${TAG} audioRecorder stop success`);
      this.logoutNotification()
      this.audioRecorder.release();
      clearInterval(this.notifierId);
      this.notifierId = -1;
      this.state = RecordState.IDLE;
      this.currentTimeMs = 0;
      this.notifyStateChanges();
      this.notifyTimeChanges();
    });
  }

  /**
   * Gets the sound size of the recording
   */
  getSoundVolume() { //todo
    return Math.random() * 100 + 5;
  }

  /**
   * Recorder start
   *
   * @param pathName
   */
  startRecorder(pathName) {
    if (typeof (this.audioRecorder) != 'undefined') {
      audioConfig.uri = pathName;
      LogUtil.info(`${TAG} audioRecorder prepare.`);
      this.audioRecorder.prepare(audioConfig);
    } else {
      LogUtil.error(`${TAG} case failed, audioRecorder is null.`);
    }
  }

  /**
   * start Time
   */
  startTime() {
    this.state = RecordState.RUNNING;
    this.startTimestamp = new Date().getTime();
    LogUtil.info(`${TAG} audioRecorder show time update start`);
    this.notifierId = setInterval(() => {
      let timestamp = new Date().getTime();
      this.currentTimeMs = this.beforePauseTime + timestamp - this.startTimestamp;
      this.notifyTimeChanges();
    }, NOTIFY_INTERVAL_MS);
    this.notifyStateChanges();
  }

  /**
   * Recorder pause
   */
  pause() {
    if (typeof (this.audioRecorder) != `undefined`) {
      LogUtil.info(`${TAG} audioRecorder pause`);
      this.audioRecorder.pause();
    }
  }

  /**
   * Recorder resume
   */
  resume() {
    if (typeof (this.audioRecorder) != `undefined`) {
      LogUtil.info(`${TAG} audioRecorder resume`);
      this.audioRecorder.resume();
    }
  }

  /**
   * Recorder stop
   */
  stop(callback?) {
    if (typeof (this.audioRecorder) != `undefined`) {
      LogUtil.info(`${TAG} audioRecorder stop`);
      this.audioRecorder.stop();
      if (callback) {
        callback();
      }
    }
  }

  /**
   * publish Notification
   */
  publishNotification(text) {
    var notificationRequest = {
      id: NOTIFY_ID,
      content: {
        contentType: Notification.ContentType.NOTIFICATION_CONTENT_BASIC_TEXT,
        normal: {
          title: text,
          text: ``,
          additionalText: ``
        }
      }
    }
    Notification.publish(notificationRequest)
  }

  /**
   * logout Notification
   */
  logoutNotification() {
    Notification.cancel(NOTIFY_ID)
  }
}