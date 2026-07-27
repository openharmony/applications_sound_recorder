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

import consent from '@hms-security/consent';
import consentGrsSys from '@hms-security/consent_grs_system';
import type common from '@ohos.app.ability.common';
import { DeviceUtil, LogUtil } from '@ohos/common';
import { util } from '@kit.ArkTS';
import { AAID } from '@kit.PushKit';
import { BusinessError } from '@ohos.base';
import { bundleManager } from '@kit.AbilityKit';

const TAG = 'SoundRecorder_ConsentManager';
const AGREEMENT_NO: number = DeviceUtil.isPC() ? 20000021 : 20000007;
const CLIENT_NAME: string = DeviceUtil.isPC() ? 'sound-recorder-hmos-pc' : 'sound-recorder-hmos';
const CLIENT_VERSION: string = '5.0.0.0';
const DEFAULT_AAID: string = '00000000-0000-0000-0000-000000000000';
const CLEAR_AGREIGHT: string = '0';

export enum StandardContentTag {
  PERSONAL_DATA = 0
}

export class ConsentManager {
  private client: consent.Agreement | null = null;
  public context: common.Context | undefined = undefined;
  private static instance?: ConsentManager;
  private static lock = false;

  private constructor() {
    LogUtil.info(TAG + ` set ConsentManager singleton, create an instance.`);
  }

  public static getInstance(): ConsentManager {
    if (!ConsentManager.instance) {
      while (ConsentManager.lock) {
      }
      ConsentManager.lock = true;
      if (!ConsentManager.instance) {
        ConsentManager.instance = new ConsentManager();
      }
      ConsentManager.lock = false;
    }
    return ConsentManager.instance;
  }


  /**
   * 获取client实例
   *
   * @returns consent.Agreement
   */
  private async getClient(): Promise<consent.Agreement | null> {
    LogUtil.info(TAG + ' getClient start');
    // 创建客户端信息
    let clientInfo = new consent.ClientInfo();
    // 客户端名称
    clientInfo.name = CLIENT_NAME;
    clientInfo.version = this.getClientVersion();
    // 应用aaid
    clientInfo.aaid = DEFAULT_AAID;
    clientInfo.deviceId = this.getUUID();
    // 设备Id类型, 支持上报ODID和UDID
    clientInfo.deviceIdType = consent.DeviceIdType.UDID;
    // 设备类型, 按照实际情况传入
    clientInfo.deviceType = consent.DeviceType.PHONE;
    try {
      let grsClient: consentGrsSys.ConsentGrsSysClient = new consentGrsSys.ConsentGrsSysClient(this.context!);
      let extendOption: consent.ExtendOption = new consent.ExtendOption();
      extendOption.grsClient = grsClient;
      // 生成客户端实例
      this.client = new consent.Agreement(this.context!, clientInfo, extendOption);
      LogUtil.info(TAG + ' getClient start end');
    } catch (err) {
      LogUtil.error(TAG + ` getClientInfo Error, code: ${err?.code}, message: ${err?.message}`);
    }
    return this.client;
  }

  private getClientVersion(): string {
    let versionName = CLIENT_VERSION;
    try {
      const bundleInfo =
        bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION);
      versionName = bundleInfo.versionName;
    } catch (err) {
      LogUtil.error(TAG + ` getBundleInfoForSelfSync failed, code: ${err.code}, message: ${err.message}`)
    }
    LogUtil.info(TAG + ' Client Version:' + versionName);
    return versionName;
  }

  async getUrl(needClearAgreight: boolean, standardTag?: StandardContentTag): Promise<string[]> {
    let urls: string[] = [];
    try {
      let client: consent.Agreement | null = await this.getClient();
      if (client === null) {
        LogUtil.info(TAG + ' client is null.');
        return urls;
      }
      LogUtil.info(TAG + ' get client success.');
      // 创建请求
      let urlReq = new consent.GetUrlRequest(this.getUUID());
      urlReq.accessNetwork = false;
      urlReq.country = 'CN';
      // 创建单条请求，consent一次接口调用可以处理多条记录，单次最大32条
      let singleReq = new consent.GetUrlSingleRequest();
      if (standardTag) {
        singleReq.contentTag = standardTag;
      }
      // 协议号；协议Id
      singleReq.agrType = AGREEMENT_NO;
      singleReq.setTrsp();
      if (needClearAgreight) {
        singleReq.setAgr8(CLEAR_AGREIGHT);
      }
      urlReq.add(singleReq);
      let getUrlPromise = client.getUrl(urlReq).then((value) => {
        if (value) {
          let url: string = value.getUrl(singleReq);
          urls.push(url);
        }
      }).catch((error: BusinessError) => {
        LogUtil.info(TAG + ' urlReq error: ' + error.code + ' message: ' + error.message)
      })
      await getUrlPromise;
      LogUtil.info(TAG + ' client.getUrl urls: ' + urls.length);
      return urls;
    } catch (err) {
      LogUtil.error(TAG + ` getUrl catch err, code: ${err?.code}, message: ${err?.message}`);
      return urls;
    }
  }

  public getUUID(): string {
    let uuid: string = util.generateRandomUUID();
    return uuid;
  }
}