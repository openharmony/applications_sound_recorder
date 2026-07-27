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
// instrument ignore file

import { displaySync } from '@kit.ArkGraphics2D';
import { LogUtil } from './LogUtil';

const TAG = 'SoundRecorder_DisplaySyncUtil';
const EXPECTED_FPS = 20;

let displaySyncUtil: DisplaySyncUtil | undefined = undefined;

export class DisplaySyncUtil {
  private displaySync: displaySync.DisplaySync | null = null;

  private callbacks: Callback<void>[] = [];

  private isStartListen: boolean = false;

  private constructor() {
    LogUtil.info(TAG + ' DisplaySyncUtil constructor.');
    let range: ExpectedFrameRateRange = {
      expected: 20,
      min: 0,
      max: 60
    };
    this.displaySync = displaySync.create();
    this.displaySync?.setExpectedFrameRateRange(range);
    this.displaySync?.on('frame', () => this.callbacks.forEach(callback => callback()));
  }

  static getInstance(): DisplaySyncUtil {
    if (!displaySyncUtil) {
      displaySyncUtil = new DisplaySyncUtil();
    }
    return displaySyncUtil;
  }

  private startListenDisplaySync(): void {
    if (!this.isStartListen) {
      this.displaySync?.start();
      this.isStartListen = true;
    }
  }

  private stopListenDisplaySync(): void {
    if (this.isStartListen) {
      this.displaySync?.stop();
      this.isStartListen = false;
    }
  }

  public registerDisplaySyncCallback(callback: Callback<void>): void {
    LogUtil.info(TAG + ' registerDisplaySyncCallback.');
    this.callbacks.push(callback);
    this.startListenDisplaySync();
    LogUtil.info(TAG + ' DisplaySyncCallback count: ' + this.callbacks.length);
  }

  public unregisterDisplaySyncCallback(callback: Callback<void>): void {
    LogUtil.info(TAG + ' unregisterDisplaySyncCallback.');
    this.callbacks.splice(this.callbacks.indexOf(callback), 1);
    if (this.callbacks.length == 0) {
      this.stopListenDisplaySync();
    }
    LogUtil.info(TAG + ' DisplaySyncCallback count: ' + this.callbacks.length);
  }

  public destroy(): void {
    LogUtil.info(TAG + ' DisplaySyncUtil destroy.');
    this.callbacks = [];
    this.displaySync?.stop();
    this.displaySync?.off('frame');
  }
}