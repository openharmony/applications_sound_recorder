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

@CustomDialog
export struct DeleteDialog {
  private controller: CustomDialogController;
  private confirm: () => void = async () => {};
  private cancel: () => void = async () => {};

  @Prop recordsToDelete: number;
  @Prop recordListLength: number;
  @StorageProp('navigationMode') navMode: number = 0;

  build() {
    Column() {
      if (this.recordsToDelete === 1) {
        Text($r('app.string.delete_hint'))
          .fontSize($r('app.float.font_delete_16'))
          .fontColor($r('sys.color.ohos_id_color_text_primary'))
          .padding({ bottom: 8 })
      } else {
        if (this.recordsToDelete === this.recordListLength) {
          Text($r('app.string.delete_all_record'))
            .fontSize($r('app.float.font_delete_16'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .padding({ bottom: 8 })
        } else {
          Text($r('app.plural.partial_delete_record_plural', this.recordsToDelete, this.recordsToDelete))
            .fontSize($r('app.float.font_delete_16'))
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
            .padding({ bottom: 8 })
        }
      }
      Row() {
        Button($r('app.string.cancel'))
          .layoutWeight(1).height($r('app.float.wh_value_40'))
          .margin({ right: 8 })
          .backgroundColor(Color.Transparent)
          .fontSize($r('app.float.wh_value_16'))
          .fontColor('#FB654E')
          .onClick(async () => {
            await this.cancel();
            this.controller.close();
          })
        Divider().vertical(true).opacity($r('app.float.opacity_4')).height($r('app.float.wh_value_24'))
        Button($r('app.string.delete'))
          .layoutWeight(1).height($r('app.float.wh_value_40'))
          .margin({ left: 8 })
          .backgroundColor(Color.Transparent)
          .fontSize($r('app.float.wh_value_16'))
          .fontColor('#FB654E')
          .onClick(async () => {
            await this.confirm();
            this.controller.close();
          })
      }.height('auto')
      .padding({ bottom: $r('sys.float.ohos_id_dialog_margin_bottom'),
        top: $r('sys.float.ohos_id_elements_margin_vertical_m') })
    }.backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
    .padding({ left: $r('sys.float.ohos_id_dialog_margin_bottom'),
      right: $r('sys.float.ohos_id_dialog_margin_bottom'), top: 24 })
  }
}