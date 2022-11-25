/**
 * Copyright (c) 2022 Huawei Device Co., Ltd.
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

import mediaLibrary from '@ohos.multimedia.mediaLibrary';
import media from '@ohos.multimedia.media';
import { LogUtil } from '@ohos/common';

export enum AudioState {
  /**
   * The initial state
   */
  IDLE,
  /**
   * Continuously update time starting from IDLE state or PAUSED state
   */
  RUNNING,
  /**
   * Click Pause from the RUNNING state
   */
  PAUSED,
}

const NOTIFY_INTERVAL_MS = 50;
const TAG = "AudioController : ";

export class AudioController {
  private audioPlayer: media.AudioPlayer = undefined;
  private state: AudioState = AudioState.IDLE;
  private playFile: mediaLibrary.FileAsset = undefined;
  private dataLoad: boolean = false;
  private finishListener: () => void = undefined;
  private currentTimeMs: number = 0;
  private intervalId: number = -1;
  private timeUpdateListener: (currentTimeMs: number) => void = undefined;
  private stateUpdateListener: (AudioState) => void = undefined;

  /**
   * Set the time update listener
   *
   * @param listener
   */
  public setTimeUpdateListener(listener: (currentTimeMs: number) => void) {
    LogUtil.info(`${TAG} setTimeUpdateListener`);
    this.timeUpdateListener = listener;
  }

  /**
   * Set the status update listener
   *
   * @param listener
   */
  public setStateUpdateListener(listener: (AudioState) => void) {
    LogUtil.info(`${TAG} setStateUpdateListener`);
    this.stateUpdateListener = listener;
  }

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
      LogUtil.info(`${TAG} state update ${this.state}`);
      this.stateUpdateListener(this.state);
    }
  }

  /**
   * Initialize the audio player
   *
   * @param playSrc
   * @param callback
   */
  initAudioPlayer(playSrc: mediaLibrary.FileAsset, callback: () => void) {
    LogUtil.info(`${TAG} initAudioPlayer`);
    this.playFile = playSrc;
    this.dataLoad = false;
    this.release();
    LogUtil.info(`${TAG} createAudioPlayer`);
    this.audioPlayer = media.createAudioPlayer();
    this.audioPlayer.on('dataLoad', () => {
      this.dataLoad = true;
      LogUtil.info(`${TAG} audioPlayer dataLoad success`);
      if (callback) {
        callback();
      }
    })
    this.audioPlayer.on('stop', () => {
      LogUtil.info(`${TAG} audioPlayer stop success`);
      this.release();
    })
    this.audioPlayer.on('error', (error) => {
      LogUtil.error(`${TAG} audioPlayer error. info:${error}`);
    })
    this.audioPlayer.on('timeUpdate', (num) => {
      LogUtil.info(`${TAG} audioPlayer timeUpdate. time:${num}`);
    })
    this.audioPlayer.on('audioInterrupt', (num) => {
      LogUtil.warn(`${TAG} audioPlayer audioInterrupt. time:${num}`);
    })
    this.audioPlayer.on('finish', () => {
      LogUtil.info(`${TAG} audioPlayer finish.`);
      clearInterval(this.intervalId);
      this.intervalId = -1;
      this.state = AudioState.IDLE;
      this.notifyStateChanges();
    })
    LogUtil.info(`${TAG} audioPlayer reset.`)
    this.audioPlayer.reset();
    LogUtil.info(`${TAG} read FileAsset`);
    let fdPath = playSrc.open('r');
    fdPath.then(fdNumber => {
      LogUtil.info(`${TAG} audioPlayer set src`);
      this.audioPlayer.src = `fd://${fdNumber}`;
    });
  }

  /**
   * audioPlayer play
   */
  play() {
    if (typeof (this.audioPlayer) != `undefined`) {
      this.audioPlayer.on('play', () => {
        LogUtil.info(`${TAG} audioPlayer play success`);
        this.startTimer();
      });
      if (this.dataLoad) {
        LogUtil.info(`${TAG} audioPlayer play`);
        this.audioPlayer.play();
      } else {
        this.audioPlayer.on('dataLoad', () => {
          LogUtil.info(`${TAG} audioPlayer dataLoad success`);
          this.dataLoad = true;
          LogUtil.info(`${TAG} audioPlayer play`);
          this.audioPlayer.play();
        });
      }
    }
  }

  /**
   * audioPlayer seek time
   *
   * @param timeMs
   */
  seek(timeMs: number) {
    if (typeof (this.audioPlayer) != `undefined`) {
      LogUtil.info(`${TAG} audioPlayer time to jump. time:` + timeMs);
      this.audioPlayer.seek(timeMs);
    }
  }

  /**
   * audioPlayer pause
   */
  pause() {
    if (typeof (this.audioPlayer) != `undefined`) {
      this.audioPlayer.on('pause', () => {
        LogUtil.info(`${TAG} audioPlayer pause success`);
        this.stopTimer();
      });
      LogUtil.info(`${TAG} audioPlayer pause`);
      this.audioPlayer.pause();
    }
  }

  /**
   * audioPlayer stop
   */
  stop() {
    if (typeof (this.audioPlayer) != `undefined` && this.state != AudioState.IDLE) {
      LogUtil.info(`${TAG} audioPlayer stop`);
      this.state = AudioState.IDLE;
      this.notifyStateChanges();
      clearInterval(this.intervalId);
      this.intervalId = -1;
    }
  }

  /**
   * audioPlayer continue play
   */
  continuePlay() {
    if (typeof (this.audioPlayer) != `undefined`) {
      LogUtil.info(`${TAG} audioPlayer continue play`);
      this.audioPlayer.play();
    }
  }

  /**
   * startTimer
   */
  startTimer() {
    if (this.intervalId != -1) {
      return;
    }
    this.state = AudioState.RUNNING;
    this.notifyStateChanges();
    LogUtil.info(`${TAG} audioPlayer show time update start`);
    this.intervalId = setInterval(() => {
      this.currentTimeMs = this.audioPlayer.currentTime;
      this.notifyTimeChanges();
    }, NOTIFY_INTERVAL_MS);
  }

  /**
   * stopTimer
   */
  stopTimer() {
    if (this.intervalId == -1) {
      return;
    }
    this.state = AudioState.PAUSED;
    this.notifyStateChanges();
    LogUtil.info(`${TAG} audioPlayer show time update stop`);
    clearInterval(this.intervalId);
    this.intervalId = -1;
  }

  /**
   * audioPlayer release
   */
  release() {
    if (typeof (this.audioPlayer) != `undefined`) {
      this.currentTimeMs = 0;
      this.notifyTimeChanges();
      LogUtil.info(`${TAG} audioPlayer release`);
      this.audioPlayer.release();
      this.audioPlayer = undefined;
    }
  }

}