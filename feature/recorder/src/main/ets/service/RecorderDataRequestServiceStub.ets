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

import { rpc } from '@kit.IPCKit';
import { LogUtil } from '@ohos/common';
import { ServiceRequestCode, ServiceResultCode } from '../audiokit/constant/AudioConstant';

const TAG = '[RecorderDataRequestServiceStubTag]';
const RECORDER_SERVICE_REQUEST_INTERFACE_KEY = 'com.ohos.soundrecorder.servicekey';

export default class RecorderDataRequestServiceStub extends rpc.RemoteObject {
  constructor() {
    super(TAG);
  }

  onRemoteMessageRequest(code: number, data: rpc.MessageSequence, reply: rpc.MessageSequence,
    _options: rpc.MessageOption): boolean {
    try {
      const reqId: string = data.readInterfaceToken();
      if (reqId !== RECORDER_SERVICE_REQUEST_INTERFACE_KEY) {
        LogUtil.error(`${TAG} invalid interfaceToken: ${reqId}`);
        this.handleReplyMessage(reply, ServiceResultCode.FAIL_INVALID_TOKEN, 'invalid interfaceToken');
        return false;
      }
      switch (code) {
        case ServiceRequestCode.REQUEST_RECORDING:
          return this.requestRecording(data, reply);
        default:
          LogUtil.error(`${TAG} invalid request code: ${code}`);
          this.handleReplyMessage(reply, ServiceResultCode.FAIL_INVALID_REQUEST_CODE, 'invalid request code');
          return false;
      }
    } catch (error) {
      LogUtil.error(`${TAG} rpc request error: [${error?.code}][${error?.message}]`);
      this.handleReplyMessage(reply, ServiceResultCode.FAIL_RPC_ERROR, error?.message ?? '');
      return false;
    }
  }

  handleReplyMessage(reply: rpc.MessageSequence, code: ServiceResultCode, msg: string): void {
  }

  requestRecording(data: rpc.MessageSequence, reply: rpc.MessageSequence): boolean {
    return false;
  }
}