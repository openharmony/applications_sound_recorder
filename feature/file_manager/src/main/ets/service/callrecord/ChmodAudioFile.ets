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
import { common } from '@kit.AbilityKit';
import { GlobalContext, LogUtil, SystemUtil } from '@ohos/common';
import ChmodAudioFileProxy, { ChmodOptions } from './ChmodAudioFileProxy';
import { preferences } from '@kit.ArkData';

const IS_CHMOD: string = 'isChmod'
const FIRST_LAUNCH_KEY: string = 'isFirstLaunch'

const TAG = 'SoundRecorder_ChmodAudioFile';

export class ChmodAudioFile {
  private static instance?: ChmodAudioFile;
  private proxy?: ChmodAudioFileProxy;
  private connId?: number;

  private constructor() {
  }

  public static getInstance(): ChmodAudioFile {
    if (!ChmodAudioFile.instance) {
      ChmodAudioFile.instance = new ChmodAudioFile();
    }
    return ChmodAudioFile.instance;
  }

  public release(): void {
    ChmodAudioFile.instance = undefined;
  }

  public async tryStart(): Promise<void> {
    if (!SystemUtil.HAS_VOICE_CAPABILITY) {
      return;
    }
    try {
      let context = GlobalContext.getUIAbilityContext();
      const prefs = await preferences.getPreferences(context, IS_CHMOD);
      const isFirstLaunch = await prefs.get(FIRST_LAUNCH_KEY, true);
      if (isFirstLaunch) {
        LogUtil.info(`${TAG} trystart ChmodAudioFile`);
        this.start();
        prefs.put(FIRST_LAUNCH_KEY, false);
        prefs.flush();
      }
    } catch (err) {
      LogUtil.error(`${TAG} tryStart failed.`);
    }
  }

  private async start(): Promise<void> {
    return new Promise(async (resolve, reject) => {
      this.connectSA().then((abilityName: string) => {
        LogUtil.info(`${TAG} connect ok, conn-id: ${this.connId}, abilityName: ${abilityName}.`);
        this.proxy?.start(this.getChmodOptions(resolve, reject));
      }).catch(() => {
        reject();
      });
    })
  }

  private connectSA(): Promise<string> {
    return new Promise<string>((resolve, reject) => {
      try {
        const request: Want = {
          bundleName: 'com.ohos.callrecorder',
          abilityName: 'com.ohos.callrecorder.FilePermissionAbility'
        };
        const ctx = GlobalContext.getUIAbilityContext();
        this.connId = ctx?.connectServiceExtensionAbility(request, this.getConnSaOptions(resolve, reject));
      } catch (err) {
        reject(err);
        LogUtil.error(`${TAG} failed to call migration service ability.`);
      }
    })
  }

  private getChmodOptions(resolve: () => void, reject: () => void): ChmodOptions {
    return {
      onFinished: () => {
        LogUtil.info(`${TAG} chmod ok.`);
        this.disconnectSA();
        reject();
      }
    }
  }

  private reset(): void {
    this.proxy = undefined;
    this.connId = undefined;
  }

  private disconnectSA(): void {
    if (typeof this.connId !== 'number') {
      LogUtil.error(`${TAG} failed to disconnect sa, conn-id invalid.`);
      return;
    }
    try {
      const ctx = GlobalContext.getUIAbilityContext();
      ctx?.disconnectServiceExtensionAbility(this.connId);
      LogUtil.info(`${TAG} disconnect sa ok, conn-id: ${this.connId}`);
      this.reset();
    } catch (err) {
      LogUtil.error(`${TAG} failed to disconnect sa, code: ${err.code}, message: ${err.message}`);
    }
  }

  private getConnSaOptions(resolve: (abilityName: string) => void, reject: () => void): common.ConnectOptions {
    return {
      onConnect: (element, proxy) => {
        LogUtil.info(`${TAG} onConnect, abilityName: ${element.abilityName}`);
        if (!proxy) {
          this.reset();
          reject();
          return;
        }
        this.proxy = new ChmodAudioFileProxy(proxy);
        resolve(element.abilityName);
      },
      onDisconnect: (element) => {
        LogUtil.info(`${TAG} onDisconnect, abilityName: ${element.abilityName}`);
        this.reset();
        reject();
      },
      onFailed: (code) => {
        LogUtil.error(`${TAG} onFailed, code: ${code}`);
        this.reset();
        reject();
      }
    }
  }
}

export default ChmodAudioFile.getInstance();