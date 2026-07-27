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

import { AegAesGcm } from '@hw-agconnect/petal-aegis';
import { LogUtil } from './LogUtil';

const TAG: string = 'SoundRecorder_AesGcmUtil ';
/**
 * 加密解密
 */
export class AesGcmUtil {

  /**
   * 加密
   * @param key 密钥
   * @param cipherText 明文
   * @param iv iv
   * @returns
   */
  public static async encryptMessagePromise(key: string, cipherText: string, iv: string) {
    LogUtil.info(TAG + ' encryptMessagePromise cipherText:' + cipherText);
    //加密
    let encryptText: string = await AegAesGcm.ohAegAesGcmEncTextHex(cipherText, key, iv);
    LogUtil.info(TAG + ' encryptMessagePromise encryptText:' + encryptText);
    return encryptText;
  }

  /**
   * 解密消息
   * @param key 密钥
   * @param cipherText 密文
   * @returns
   */
  public static async decryptMessagePromise(key: string, cipherText?: string) {
    LogUtil.info(TAG + 'decryptMessagePromise start.');
    let decryptText: string = '';
    if (cipherText == null || cipherText == '') {
      return decryptText;
    }
    try {
      //解密
      decryptText = await AegAesGcm.ohAegAesGcmDecText(cipherText, key);
    } catch (err) {
      LogUtil.info(TAG + ' decryptMessagePromise err: ' + err);
      return '';
    }
    LogUtil.info(TAG + ' decryptMessagePromise decryptText:' + decryptText);
    return decryptText;
  }
}