/**
 * Copyright (c) 2021 Huawei Device Co., Ltd.
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
import { ConfigData, Util } from '@ohos/common'
import { AudioController, AudioState, MediaController, RecordData } from '@ohos/recorder'
import { StateController, ControlState } from '@ohos/recorder'

@Component
export struct recordList {
  @State recordList: Array<RecordData> = []
  @State selectedIndex: number = -1
  @State currentTime: number = 0
  private audioController: AudioController = new AudioController()
  @State state: AudioState = AudioState.IDLE;
  @State filterText: string = "";
  private deleteRecord: RecordData = undefined
  private stateController = new StateController()
  @State disable: boolean = false
  confirm: () => void = () => {
    MediaController.deleteRecord(this.deleteRecord.fileAsset.uri, () => {
      for (let i = this.recordList.length - 1;i >= 0; i--) {
        if (this.deleteRecord.fileAsset.uri == this.recordList[i].fileAsset.uri) {
          this.recordList.splice(i, 1)
        }
      }
    })
  }
  dialogController: CustomDialogController = new CustomDialogController({
    builder: DeleteRecordDialog({ deleteRecordTitle: this.deleteRecord.title, confirm: this.confirm }),
    autoCancel: true,
    alignment: DialogAlignment.Bottom,
    offset: { dy: -16, dx: 0 }
  })

  async getAudios() {
    this.recordList = await MediaController.queryAllAudios()
  }

  aboutToAppear() {
    globalThis.abilityContext.requestPermissionsFromUser(['ohos.permission.MICROPHONE', 'ohos.permission.WRITE_MEDIA', 'ohos.permission.READ_MEDIA'], (result) => {
      this.getAudios()
    })
    this.stateController.setStateUpdateListener((state) => {
      if (state == ControlState.START) {
        this.disable = true
        this.audioController.stop()
      } else {
        this.disable = false
        this.getAudios()
      }
    })
    this.audioController.setTimeUpdateListener((currentTime: number) => {
      this.currentTime = currentTime
    })
    this.audioController.setStateUpdateListener((state: AudioState) => {
      if (state == AudioState.IDLE) {
        this.selectedIndex = -1
      }
      this.state = state
    })
  }

  build() {
    Column() {
      Row() {
        Image($r("app.media.ic_clock_add"))
          .width($r("app.float.wh_value_12"))
          .height($r("app.float.wh_value_12"))
          .margin({ right: $r("app.float.distance_12") })

        Image($r("app.media.public_more"))
          .width($r("app.float.wh_value_12"))
          .height($r("app.float.wh_value_12"))
          .margin({ right: $r("app.float.distance_12") })
      }
      .height($r("app.float.wh_value_28"))
      .width(ConfigData.WH_100_100)
      .justifyContent(FlexAlign.End)

      Row() {
        Text($r("app.string.title"))
          .fontSize($r("app.float.font_30"))
          .fontColor($r("app.color.text_color"))
          .fontWeight(500)
          .margin({ left: $r("app.float.distance_12") })
      }
      .height($r("app.float.wh_value_21"))
      .width(ConfigData.WH_100_100)

      Column() {
        Stack({ alignContent: Alignment.Start }) {
          TextInput({ placeholder: $r("app.string.search_recording_files") })
            .placeholderFont({ size: $r("app.float.font_16") })
            .width(ConfigData.WH_100_100)
            .height($r("app.float.wh_value_21"))
            .backgroundColor($r("app.color.white"))
            .borderRadius($r("app.float.distance_21"))
            .padding({ left: $r("app.float.distance_21") })
            .onChange((value) => {
              this.filterText = value
            })
          Image($r("app.media.ic_record_search"))
            .width($r("app.float.wh_value_12"))
            .height($r("app.float.wh_value_12"))
            .margin({ left: $r("app.float.distance_6") })
        }.width(ConfigData.WH_100_100)
        .height($r("app.float.wh_value_21"))

        Column() {
          List() {
            ForEach([...this.recordList].reverse().map((value, index) => {
              return { i: index, data: value }
            }), (item) => {
              ListItem() {
                Column() {
                  Row() {
                    Column() {
                      Text(item.data.title)
                        .fontColor($r("app.color.text_color"))
                        .fontSize($r("app.float.font_16"))
                        .width($r("app.float.wh_value_105"))
                        .lineHeight($r("app.float.wh_value_10_5"))
                      Text(Util.getDateFormat(item.data.date))
                        .fontColor($r("app.color.text_color"))
                        .opacity($r("app.float.opacity_6"))
                        .fontSize($r("app.float.font_14"))
                        .width($r("app.float.wh_value_105"))
                        .lineHeight($r("app.float.wh_value_9_5"))
                    }

                    Row() {
                      Text(Util.timeFormat(item.data.duration))
                        .fontColor($r("app.color.text_color"))
                        .opacity($r("app.float.opacity_6"))
                        .fontSize($r("app.float.font_14"))
                        .margin({ right: $r("app.float.distance_2") })
                      Image((item.i == this.selectedIndex && this.state == AudioState.RUNNING) ? $r("app.media.ic_record_stop") : $r("app.media.ic_record_play"))
                        .width($r("app.float.wh_value_12"))
                        .height($r("app.float.wh_value_12"))
                    }
                  }
                  .height($r("app.float.wh_value_32"))
                  .width(ConfigData.WH_100_100)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ left: $r("app.float.distance_12"), right: $r("app.float.distance_12") })
                  .onClick(() => {
                    if (this.selectedIndex != item.i || this.state == AudioState.IDLE) {
                      this.selectedIndex = item.i
                      this.audioController.initAudioPlayer(item.data.fileAsset, () => {
                        this.audioController.play()
                      })
                    } else if (this.state == AudioState.RUNNING) {
                      this.audioController.pause()
                    } else if (this.state == AudioState.PAUSED) {
                      this.audioController.continuePlay()
                    }
                  })
                  .gesture(
                  LongPressGesture()
                    .onAction(() => {
                      this.audioController.stop()
                      this.deleteRecord = item.data
                      this.dialogController.open()
                    })
                  )

                  if (this.selectedIndex == item.i) {
                    Column() {
                      Slider({
                        value: this.currentTime,
                        min: 0,
                        max: item.data.duration,
                        style: SliderStyle.OutSet
                      })
                        .trackThickness($r("app.float.wh_value_2"))
                        .height($r("app.float.wh_value_8"))
                        .width($r("app.float.wh_value_232"))
                        .onChange((value: number, mode: SliderChangeMode) => {
                          if (mode == SliderChangeMode.End || mode == 3) {
                            this.currentTime = value
                            this.audioController.seek(value)
                          }
                        })
                        .offset({ y: $r("app.float.wh_value_minus_19") })

                      Row() {
                        Text(Util.timeFormat(this.currentTime))
                          .fontColor($r("app.color.text_color"))
                          .opacity($r("app.float.opacity_6"))
                          .fontSize($r("app.float.font_10"))
                          .margin({ right: $r("app.float.distance_2") })
                        Text(Util.timeFormat(item.data.duration))
                          .fontColor($r("app.color.text_color"))
                          .opacity($r("app.float.opacity_6"))
                          .fontSize($r("app.float.font_10"))
                          .margin({ right: $r("app.float.distance_2") })
                      }
                      .margin({ top: $r("app.float.distance_6") })
                      .width($r("app.float.wh_value_208"))
                      .justifyContent(FlexAlign.SpaceBetween)
                    }
                    .padding({ top: $r("app.float.distance_4") })
                    .height($r("app.float.wh_value_32"))
                    .width(ConfigData.WH_100_100)
                  }
                }
              }.visibility(item.data.title.indexOf(this.filterText) >= 0 ? Visibility.Visible : Visibility.None)
            }, item => item.i)

          }
          .width(ConfigData.WH_100_100)
          .backgroundColor($r("app.color.white"))
          .borderRadius($r("app.float.wh_value_12"))
          .divider({
            strokeWidth: $r("app.float.wh_value_0_5"),
            color: $r("app.color.shadow_color"),
            startMargin: $r("app.float.distance_12"),
            endMargin: $r("app.float.distance_12")
          })
          .enabled(!this.disable)
          .opacity(this.disable ? $r("app.float.opacity_6") : $r("app.float.opacity_full"))
        }
        .flexShrink(1)
        .margin({ top: $r("app.float.distance_8") })
      }
      .flexShrink(1)
      .margin({ top: $r("app.float.distance_6"), bottom: $r("app.float.distance_12") })
    }
    .width(ConfigData.WH_100_100)
    .height(ConfigData.WH_100_100)
  }
}

@CustomDialog
struct DeleteRecordDialog {
  private controller: CustomDialogController
  private deleteRecordTitle: string
  private confirm: () => void

  build() {
    Column() {
      Text(this.deleteRecordTitle)
        .fontSize($r("app.float.font_14"))
        .fontColor($r("app.color.text_color"))
        .opacity($r("app.float.opacity_6"))
        .width(ConfigData.WH_100_100)
        .margin({ left: $r("app.float.distance_6") })
      Text($r("app.string.delete_hint"))
        .fontSize($r("app.float.font_16"))
        .margin($r("app.float.distance_6"))
        .fontColor($r("app.color.text_color"))
      Row() {
        Text($r("app.string.cancel"))
          .fontSize($r("app.float.font_16"))
          .fontColor($r("app.color.text_color"))
          .width($r("app.float.wh_value_24"))
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close()
          })
          .fontColor($r("app.color.hint_color"))
        Divider().vertical(true).opacity($r("app.float.opacity_4"))
        Text($r("app.string.delete"))
          .fontSize($r("app.float.font_16"))
          .textAlign(TextAlign.Center)
          .width($r("app.float.wh_value_24"))
          .onClick(() => {
            if (this.confirm) {
              this.confirm()
              this.controller.close()
            }
          })
          .fontColor($r("app.color.warn_color"))
      }
      .height($r("app.float.wh_value_12"))
      .width(ConfigData.WH_100_100)
      .padding({ left: $r("app.float.wh_value_12"), right: $r("app.float.wh_value_12") })
      .justifyContent(FlexAlign.SpaceAround)
    }
    .padding($r("app.float.distance_12"))
  }
}