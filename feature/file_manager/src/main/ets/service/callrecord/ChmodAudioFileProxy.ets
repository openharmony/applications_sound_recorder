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
import { BusinessError } from '@kit.BasicServicesKit';
import { rpc } from '@kit.IPCKit';
import { LogUtil } from '@ohos/common';

const TAG = 'SoundRecorder_ChmodAudioFileProxy';

type onFinished = () => void;

export interface ChmodOptions {
  onFinished: onFinished,
}

interface ChmodAudioFileService {
  start: (options: ChmodOptions) => void
}

const CODE_SUCCESS: number = 0;
const MESSAGE_SUCCESS: string = 'success';

enum CommandCode {
  ALLFILES = 1001,
}

class ProgressServerCallback extends rpc.RemoteObject {
  private options: ChmodOptions;

  constructor(options: ChmodOptions) {
    super('progress_callback');
    this.options = options;
  }
}

export default class ChmodAudioFileProxy implements ChmodAudioFileService {
  public static readonly TK: string = 'idl.FilePermission';
  private proxy: rpc.IRemoteObject;

  constructor(proxy: rpc.IRemoteObject) {
    this.proxy = proxy;
  }

  start(callback: ChmodOptions) {
    const options = new rpc.MessageOption();
    const data = rpc.MessageSequence.create();
    const reply = rpc.MessageSequence.create();
    const psc = new ProgressServerCallback(callback);

    data.writeInterfaceToken(ChmodAudioFileProxy.TK);
    data.writeRemoteObject(psc);
    this.proxy.sendMessageRequest(CommandCode.ALLFILES, data, reply, options)
      .then((result: rpc.RequestResult) => {
        if (result.errCode !== CODE_SUCCESS) {
          LogUtil.error(`${TAG} failed to connect.`);
          callback.onFinished();
          return;
        }
        const code = result.reply.readInt();
        const message = result.reply.readString();
        if (code !== CODE_SUCCESS) {
          LogUtil.error(`${TAG} failed to chmod.`);
          callback.onFinished();
          return;
        }
        LogUtil.info(`${TAG} chmod ok, code: ${code}, message: ${message}`);
        callback.onFinished();
      })
      .catch((err: BusinessError) => {
        LogUtil.error(`${TAG} failed to send message request, action: start, code: ${err.code}, message: ${err.message}`);
        callback.onFinished();
      })
      .finally(() => {
        data.reclaim();
        reply.reclaim();
      });
  }
}