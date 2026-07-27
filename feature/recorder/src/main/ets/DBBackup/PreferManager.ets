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

import preferences from '@ohos.data.preferences';
import { GlobalContext, LogUtil } from '@ohos/common';
// 查看文件列表
const TAG = 'SoundRecorder_PreferManager';

class PreferManager {
    //  编译报错 原有逻辑暂时注释
    private preferenceTheme?: preferences.Preferences;

    /**
     * save File Duration to preferences
     *
     * @param name
     * @param value
     */
    // 存储数据
    async putPreference(name: string, value: string | number | boolean) {
        LogUtil.info(`${TAG} putPreference. name : ${name}. value:${value}`);
        const theme = this.preferenceTheme;
        if (theme) {
            await theme.put(name, value).then(() => {
                theme.flush()
            });
        }
    }

    /**
     * get File Duration from preferences
     *
     * @param name
     */

    // 获取数据
    async getPreference(name: string): Promise<string> {
        LogUtil.info(TAG + `Get begin`)
        let theme: string = ''
        if (this.preferenceTheme) {
            theme = await this.preferenceTheme.get(name, '') as string
        }
        return theme
    }

    //从内存中获取轻量级存储db文件
    async getPreferencesFromStorage(preferencesName: string) {
        LogUtil.info(TAG + this.preferenceTheme + 'this.preferenceTheme0');
        let context = GlobalContext.getBackupAbilityContext();
        try {
            this.preferenceTheme = await preferences.getPreferences(context, preferencesName);
        } catch (err) {
            LogUtil.error(`${TAG} getPreferences of preferenceTheme failed, code: ${err.code}, message: ${err.message}}`);
        }
        LogUtil.info(TAG + this.preferenceTheme + 'this.preferenceTheme1');
    }

    async hasSync(key: string): Promise<boolean> {
        let flag: boolean = false
        LogUtil.info('start find key');
        if (this.preferenceTheme) {
            LogUtil.info('start find key find in preferenceTheme');
            flag = this.preferenceTheme.hasSync(key);
        }
        LogUtil.info(TAG + flag + 'hasSync end');
        return flag;
    }
}

export default new PreferManager();
