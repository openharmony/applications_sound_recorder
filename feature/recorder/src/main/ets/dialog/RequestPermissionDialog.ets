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

import { LogUtil } from '@ohos/common'
import { BusinessError } from '@ohos.base'
import Want from '@ohos.app.ability.Want'
import common from '@ohos.app.ability.common'
import { Configuration } from '@kit.ArkUI'

const TAG: string = 'SoundRecorder_MediaLibraryPermissionDialog'

@CustomDialog
export struct RequestPermissionDialog {
  private controller: CustomDialogController;
  @Prop contentText: ResourceStr;
  @Prop describeText: ResourceStr;

  build() {
    Column() {
      Image($r('app.media.ic_public_music'))
        .matchTextDirection(Configuration.getLocale().dir == 'rtl' ? true : false)
        .width($r('app.float.wh_value_24'))
        .height($r('app.float.wh_value_24'))
      Column() {
        Flex({ alignItems: ItemAlign.Start }) {
          Text(this.contentText)
            .fontSize('16fp')
            .lineHeight($r('app.float.wh_value_24'))
        }
        .margin({
          top: $r('app.float.distance_16'),
        })


        Flex({ alignItems: ItemAlign.Start }) {
          Text(this.describeText)
            .fontSize('14fp')
            .fontColor('#69696B')
            .lineHeight($r('app.float.wh_value_24'))
        }
        .margin({
          top: $r('app.float.distance_2'),
          bottom: $r('app.float.distance_8'),
        })
      }
      .margin({
        left:  $r('app.float.distance_24'),
        right:  $r('app.float.distance_24')
      })

      Flex({ justifyContent: FlexAlign.SpaceBetween, alignItems: ItemAlign.Center }) {
        Button($r('app.string.cancel'))
          .width($r('app.float.wh_value_144'))
          .height($r('app.float.wh_value_40'))
          .onClick(() => {
            this.controller.close()
          })
          .backgroundColor('#fff')
          .fontSize($r('app.float.wh_value_16'))
          .fontColor('#FB654E')
        Divider().vertical(true)
          .height($r('app.float.distance_24'))
          .opacity($r('app.float.opacity_4'))
        Button($r('app.string.go_to_setting'))
          .width($r('app.float.wh_value_144'))
          .height($r('app.float.wh_value_40'))
          .onClick(() => {
            let context = getContext(this) as common.UIAbilityContext;
            let want: Want = {
              bundleName: 'com.ohos.settings',
              abilityName: 'com.ohos.settings.MainAbility',
              uri: 'application_info_entry',
              parameters: {
                pushParams: 'com.ohos.soundrecorder'
              }
            };
            context.startAbility(want).then(() => {
              LogUtil.info(TAG + `startAbility Successfully pulled up`);
            }).catch((err: BusinessError) => {
              LogUtil.error(TAG + `Failed to startAbility. Code: ${err.code}, message: ${err.message}`);
            });
            this.controller.close()
          })
          .backgroundColor('#fff')
          .fontSize($r('app.float.wh_value_16'))
          .fontColor('#FB654E')
      }.height($r('app.float.wh_value_56'))
      .padding({ bottom: $r('app.float.distance_16') })
      .margin({
        right: $r('app.float.distance_16'),
        left: $r('app.float.distance_16')
      })
    }
    .padding({
      top: $r('app.float.distance_24'),
      bottom: $r('app.float.distance_0')
    })
  }
}