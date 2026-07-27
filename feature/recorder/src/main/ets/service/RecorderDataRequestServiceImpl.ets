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

import RecorderDataRequestServiceStub from './RecorderDataRequestServiceStub';
import { GlobalRecordState, ServiceResultCode } from '../audiokit/constant/AudioConstant';
import { rpc } from '@kit.IPCKit';
import { CommonConstants, GlobalContext, LogUtil, Util } from '@ohos/common';
import AudioSDKManager from '../audiokit/manager/AudioSDKManager';
import { audio } from '@kit.AudioKit';
import { AudioRecordInfo } from '../audiokit/bean/AudioRecordInfo';
import RecordStateManager from '../audiokit/manager/RecordStateManager';
import { RecordManager } from '../controller/RecordManager';
import { PlayManager } from '../controller/PlayManager';
import { statfs } from '@kit.CoreFileKit';

const TAG = '[RecorderDataRequestServiceImplTag]';

export class RecorderDataRequestServiceImpl extends RecorderDataRequestServiceStub {
  public avRecorder?: audio.AudioCapturer;

  constructor(context: ESObject) {
    super();
    AudioSDKManager.init(context);
  }

  public release(): void {
    AudioSDKManager.destroy();
  }

  handleReplyMessage(reply: rpc.MessageSequence, code: ServiceResultCode, msg: string): void {
    try {
      reply.writeInt(code);
      reply.writeString(msg);
      LogUtil.info(`${TAG} reply code[${code}] msg[${msg}]`);
    } catch (e) {
      LogUtil.error(`${TAG} handleReplyMessage fail: [${e?.code}][${e?.message}]`);
    }
  }

  requestRecording(data: rpc.MessageSequence, reply: rpc.MessageSequence): boolean {
    try {
      const json: string = data.readString();
      // 解析录音请求
      LogUtil.info(`${TAG} earbuds request recording success, recordInfo: [${json}]`);
      const recordInfo: AudioRecordInfo = JSON.parse(json);
      this.handleAudioRecordReq(recordInfo);
      this.handleReplyMessage(reply, ServiceResultCode.SUCCESS, 'request recording success');
      return true;
    } catch (e) {
      LogUtil.error(`${TAG} requestRecording fail: [${e?.code}][${e?.message}]`);
      this.handleReplyMessage(reply, ServiceResultCode.FAIL_RPC_ERROR, e?.message ?? '');
      return false;
    }
  }

  private async handleAudioRecordReq(info: AudioRecordInfo): Promise<void> {
    LogUtil.info(`${TAG} handleAudioRecordReq recordInfo: [${JSON.stringify(info)}]`);
    try {
      if (RecordStateManager.getCurrentRecordState() === GlobalRecordState.COMMON_RECORDING) {
        // 启动手机实时转写再启动耳机实时转写场景：先停止手机录音，保存手机录音文件，再启动耳机录音
        LogUtil.info(`${TAG} try to stop common recording`);
        await RecordManager.getInstance().release();
        setTimeout(() => {
          // 预留400ms，audioCapture正常关闭及手机录音文件保存成功后再启动耳机录音
          AudioSDKManager.onRecordStateChange(info);
        }, 400);
        return;
      }
      // 停止当前正在播放的录音文件
      await PlayManager.getInstance().reset();
      // 计算剩余空间
      if (!await this.calculateAvailableSpace()) {
        return;
      }
      AudioSDKManager.onRecordStateChange(info);
    } catch (e) {
      LogUtil.error(`${TAG} onRecordStateChange fail: ${e?.message}`);
    }
  }

  private async calculateAvailableSpace(): Promise<boolean> {
    LogUtil.info(`${TAG} into calculateAvailableSpace`);
    let context = GlobalContext.getServiceAbilityContext();
    const filesDir: string = context.filesDir + '/'
    const freeSize = await statfs.getFreeSize(filesDir);
    const leftSpace: number = freeSize / 1024 / 1024;
    const leftMinute: number = leftSpace / CommonConstants.SIZE_PER_MINUTE;
    if (leftMinute <= 30) {
      LogUtil.info(`${TAG} calculateAvailableSpace`);
      let message = context?.resourceManager.getStringSync($r('app.string.cannot_recording'));
      Util.showToast(message, false, true);
      return false;
    }
    return true;
  }
}