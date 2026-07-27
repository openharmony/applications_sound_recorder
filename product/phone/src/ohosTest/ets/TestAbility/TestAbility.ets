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

import UIAbility from '@ohos.app.ability.UIAbility';
import AbilityDelegatorRegistry from '@ohos.app.ability.abilityDelegatorRegistry';
import hilog from '@ohos.hilog';
import { Hypium } from '@ohos/hypium';
import testsuite from '../test/List.test';
import window from '@ohos.window';
import common from '@ohos.app.ability.common';
import Want from '@ohos.app.ability.Want';
import AbilityConstant from '@ohos.app.ability.AbilityConstant';

const TAG: number = 0x0000;
type AbilityDelegator = AbilityDelegatorRegistry.AbilityDelegator;
type AbilityDelegatorArgs = AbilityDelegatorRegistry.AbilityDelegatorArgs;

export default class TestAbility extends UIAbility {
  async invokeSoundRecorder(delegator: AbilityDelegator) {
    const bundleName = 'com.ohos.soundrecorder';
    try {
      await delegator.startAbility({
        bundleName,
        abilityName: 'MainAbility'
      });
      hilog.info(TAG, 'testTag', '%{public}s', `${bundleName}.MainAbility start success`);
    } catch (e) {
      hilog.info(TAG, 'testTag', '%{public}s',
        `failed to ${bundleName}.MainAbility. code: ${e.code}, message: ${e.message}`);
    }
  }

  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    hilog.info(TAG, 'testTag', '%{public}s', 'TestAbility onCreate');
    hilog.info(TAG, 'testTag', '%{public}s', 'want param:' + JSON.stringify(want) ?? '');
    hilog.info(TAG, 'testTag', '%{public}s', 'launchParam:' + JSON.stringify(launchParam) ?? '');
    const delegator: AbilityDelegator = AbilityDelegatorRegistry.getAbilityDelegator();
    const delegatorArgs: AbilityDelegatorArgs = AbilityDelegatorRegistry.getArguments();
    hilog.info(TAG, 'testTag', '%{public}s', 'start run testcase!!!');
    await this.invokeSoundRecorder(delegator);
    AppStorage.setOrCreate<common.UIAbilityContext>('pageContext', this.context);
    Hypium.hypiumTest(delegator, delegatorArgs, testsuite);
  }

  onDestroy(): void {
    hilog.info(TAG, 'testTag', '%{public}s', 'TestAbility onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(TAG, 'testTag', '%{public}s', 'TestAbility onWindowStageCreate');
    windowStage.loadContent('testability/pages/Index', (err, data) => {
      if (err.code) {
        hilog.error(TAG, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err) ?? '');
        return;
      }
      hilog.info(TAG, 'testTag', 'Succeeded in loading the content. Data: %{public}s',
        JSON.stringify(data) ?? '');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(TAG, 'testTag', '%{public}s', 'TestAbility onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(TAG, 'testTag', '%{public}s', 'TestAbility onForeground');
  }

  onBackground(): void {
    hilog.info(TAG, 'testTag', '%{public}s', 'TestAbility onBackground');
  }
}