// instrument ignore file

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

import preferences from '@ohos.data.preferences';
import { LogUtil } from './LogUtil';
import { BusinessError, Callback } from '@ohos.base';
import common from '@ohos.app.ability.common';
import GlobalContext from './GlobalContext';

const TAG: string = 'PreferencesUtil : ';

// UserConfigs
export const APP_CONFIG = 'recorderSound_settings.xml';

/**
 * Preferences工具类
 *
 * @since 2023-08-10
 */
export class PreferencesUtil {
  /**
   * 获取key-value
   * @param key
   * @param defValue
   * @returns
   */
  static async get(key: string, defValue: preferences.ValueType): Promise<preferences.ValueType> {
    try {
      let context = GlobalContext.getUIAbilityContext();
      if (!context) {
        context = getContext() as common.UIAbilityContext;
      }
      preferences.removePreferencesFromCacheSync(context, APP_CONFIG);
      const preference = await preferences.getPreferences(context, APP_CONFIG);
      return await preference.get(key, defValue);
    } catch (e) {
      LogUtil.error(`${TAG} preferences get key: ${key} error: ${(e as BusinessError).message}`)
      return defValue;
    }
  }

  /**
   * 判断是否存在
   *
   * @param key
   * @returns
   */
  static async has(key: string): Promise<boolean> {
    try {
      const context = await preferences.getPreferences(getContext() as common.UIAbilityContext,
        APP_CONFIG);
      return await context.has(key);
    } catch (e) {
      LogUtil.error(`${TAG} preferences has key: ${key} error: ${(e as BusinessError).message}`)
      return false;
    }
  }

  /**
   * 新增/更新
   *
   * @param key
   * @param value
   * @returns
   */
  static async put(key: string, value: preferences.ValueType): Promise<void> {
    try {
      let ctx = GlobalContext.getUIAbilityContext();
      if (!ctx) {
        ctx = getContext() as common.UIAbilityContext;
      }
      const context = await preferences.getPreferences(ctx, APP_CONFIG);
      await context.put(key, value);
      await context.flush();
    } catch (e) {
      LogUtil.error(`${TAG} preferences put key: ${key} error: ${(e as BusinessError).message}`)
    }
  }

  /**
   * 新增/更新 （使用flushSync同步方法保存）
   *
   * @param key
   * @param value
   * @returns
   */
  static async putFlushSync(key: string, value: preferences.ValueType): Promise<void> {
    try {
      const context = await preferences.getPreferences(getContext() as common.UIAbilityContext, APP_CONFIG);
      await context.put(key, value);
      context.flushSync();
    } catch (e) {
      LogUtil.error(`${TAG} preferences putFlushSync key: ${key} error: ${(e as BusinessError).message}`)
    }
  }

  /**
   * 删除
   *
   * @param key
   * @returns
   */
  static async delete(key: string): Promise<void> {
    try {
      const context = await preferences.getPreferences(getContext() as common.UIAbilityContext,
        APP_CONFIG);
      await context.delete(key);
      await context.flush();
    } catch (e) {
      LogUtil.error(`${TAG} preferences delete key: ${key} error: ${(e as BusinessError).message}`)
    }
  }

  /**
   * 注册数据变化监听
   *
   * @param key
   * @returns
   */
  static async on(observer: Callback<string>): Promise<void> {
    try {
      const context = await preferences.getPreferences(getContext() as common.UIAbilityContext,
        APP_CONFIG);
      context.on('change', observer);
    } catch (e) {
      LogUtil.error(`${TAG} preferences on change error: ${(e as BusinessError).message}`)
    }
  }

  static async off(observer: Callback<string>): Promise<void> {
    try {
      const context = await preferences.getPreferences(getContext() as common.UIAbilityContext,
        APP_CONFIG);
      context.off('change', observer);
    } catch (e) {
      LogUtil.error(`${TAG} preferences off change error: ${(e as BusinessError).message}`)
    }
  }
}