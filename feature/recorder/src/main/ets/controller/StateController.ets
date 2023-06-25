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

import { LogUtil } from '@ohos/common';

const TAG = 'ControlState : ';

export enum ControlState {
  START,
  END,
}

export class StateController {
  private state: ControlState = ControlState.END;
  private stateUpdateListener: (RecordState) => void = undefined;

  /**
   * Set the status update listener
   *
   * @param listener
   */
  public setStateUpdateListener(listener: (RecordState) => void) {
    this.stateUpdateListener = listener;
  }

  /**
   * Notification of status updates
   */
  private async notifyStateChanges() {
    if (this.stateUpdateListener) {
      this.stateUpdateListener(this.state);
    }
  }

  /**
   * Announce the start of recording
   */
  public start() {
    LogUtil.info(`${TAG} record start.`);
    this.state = ControlState.START;
    this.notifyStateChanges();
  }

  /**
   * Announce the end of recording
   */
  public end() {
    LogUtil.info(`${TAG} record end.`);
    this.state = ControlState.END;
    this.notifyStateChanges();
  }
}