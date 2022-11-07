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
import router from '@ohos.router';
import { AudioController, AudioState, MediaController, RecordData } from '@ohos/recorder'

@Entry
@Component
struct Index {
  @State recordList: Array<RecordData> = []
  @State selectedIndex: number = -1
  @State currentTime: number = 0
  private audioController: AudioController = new AudioController()
  @State state: AudioState = AudioState.IDLE;
  @State filterText: string = "";
  private deleteRecord: RecordData = undefined
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
    offset: { dy: -64, dx: 0 }
  })

  async getAudios() {
    this.recordList = await MediaController.queryAllAudios()
  }

  aboutToAppear() {
    globalThis.abilityContext.requestPermissionsFromUser(['ohos.permission.MICROPHONE', 'ohos.permission.WRITE_MEDIA', 'ohos.permission.READ_MEDIA'], () => {
      this.getAudios()
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
          .width($r("app.float.wh_value_32"))
          .height($r("app.float.wh_value_32"))
          .margin({ right: $r("app.float.distance_32") })

        Image($r("app.media.public_more"))
          .width($r("app.float.wh_value_32"))
          .height($r("app.float.wh_value_32"))
          .margin({ right: $r("app.float.distance_32") })
      }
      .height($r("app.float.wh_value_56"))
      .width(ConfigData.WH_100_100)
      .justifyContent(FlexAlign.End)

      Row() {
        Text($r("app.string.title"))
          .fontSize($r("app.float.font_48"))
          .fontColor($r("app.color.text_color"))
          .fontWeight(500)
          .margin({ left: $r("app.float.distance_32") })
      }
      .height($r("app.float.wh_value_56"))
      .width(ConfigData.WH_100_100)

      Column() {
        Stack({ alignContent: Alignment.Start }) {
          TextInput({ placeholder: $r("app.string.search_recording_files") })
            .width(ConfigData.WH_100_100)
            .height($r("app.float.wh_value_53_5"))
            .backgroundColor($r("app.color.white"))
            .borderRadius($r("app.float.distance_53_5"))
            .padding({ left: $r("app.float.distance_53_5") })
            .onChange((value) => {
              this.filterText = value
            })
          Image($r("app.media.ic_record_search"))
            .width($r("app.float.wh_value_32"))
            .height($r("app.float.wh_value_32"))
            .margin({ left: $r("app.float.wh_value_16") })
        }.width(ConfigData.WH_100_100)
        .height($r("app.float.wh_value_53_5"))

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
                        .fontSize($r("app.float.font_32"))
                        .width($r("app.float.wh_value_280"))
                        .lineHeight($r("app.float.wh_value_28"))
                      Text(Util.getDateFormat(item.data.date))
                        .fontColor($r("app.color.text_color"))
                        .opacity($r("app.float.opacity_6"))
                        .fontSize($r("app.float.font_28"))
                        .width($r("app.float.wh_value_280"))
                        .lineHeight($r("app.float.wh_value_25_5"))
                    }

                    Row() {
                      Text(Util.timeFormat(item.data.duration))
                        .fontColor($r("app.color.text_color"))
                        .opacity($r("app.float.opacity_6"))
                        .fontSize($r("app.float.font_28"))
                        .margin({ right: $r("app.float.distance_2_5") })
                      Image((item.i == this.selectedIndex && this.state == AudioState.RUNNING) ? $r("app.media.ic_record_stop") : $r("app.media.ic_record_play"))
                        .width($r("app.float.wh_value_32"))
                        .height($r("app.float.wh_value_32"))
                    }
                  }
                  .height($r("app.float.wh_value_85_5"))
                  .width(ConfigData.WH_100_100)
                  .justifyContent(FlexAlign.SpaceBetween)
                  .padding({ left: $r("app.float.distance_21_5"), right: $r("app.float.distance_21_5") })
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
                        .width($r("app.float.wh_value_433"))
                        .onChange((value: number, mode: SliderChangeMode) => {
                          if (mode == SliderChangeMode.End || mode == 3) {
                            this.currentTime = value
                            this.audioController.seek(value)
                          }
                        })

                      Row() {
                        Text(Util.timeFormat(this.currentTime))
                          .fontColor($r("app.color.text_color"))
                          .opacity($r("app.float.opacity_6"))
                          .fontSize($r("app.float.font_20"))
                          .margin({ right: $r("app.float.distance_2_5") })
                        Text(Util.timeFormat(item.data.duration))
                          .fontColor($r("app.color.text_color"))
                          .opacity($r("app.float.opacity_6"))
                          .fontSize($r("app.float.font_20"))
                          .margin({ right: $r("app.float.distance_2_5") })
                      }
                      .width($r("app.float.wh_value_405"))
                      .justifyContent(FlexAlign.SpaceBetween)

                    }.height($r("app.float.wh_value_85_5"))
                    .width(ConfigData.WH_100_100)
                  }
                }
              }.visibility(item.data.title.indexOf(this.filterText) >= 0 ? Visibility.Visible : Visibility.None)
            }, item => item.i)

          }.width(ConfigData.WH_100_100)
          .backgroundColor($r("app.color.white"))
          .borderRadius($r("app.float.wh_value_32"))
          .divider({
            strokeWidth: $r("app.float.wh_value_1"),
            color: $r("app.color.shadow_color"),
            startMargin: $r("app.float.distance_16"),
            endMargin: $r("app.float.distance_16")
          })
        }.margin({ top: $r("app.float.distance_22_5") })
        .flexShrink(1)

        Blank()
        Row() {
          Image($r("app.media.ic_clock_record"))
            .width($r("app.float.wh_value_32"))
            .height($r("app.float.wh_value_32"))
        }
        .width($r("app.float.wh_value_64"))
        .height($r("app.float.wh_value_64"))
        .justifyContent(FlexAlign.Center)
        .borderRadius($r("app.float.wh_value_32"))
        .backgroundColor($r("app.color.white"))
        .shadow({ radius: $r("app.float.distance_16"), color: $r("app.color.shadow_color") })
        .margin({ bottom: $r("app.float.distance_32"), top: $r("app.float.distance_16") })
        .onClick(() => {
          this.audioController.stop()
          router.replace({
            url: "pages/RecordingPage"
          })
        })
      }
      .height(ConfigData.WH_100_100)
      .flexShrink(1)
      .justifyContent(FlexAlign.Center)
      .padding({
        left: $r("app.float.distance_16"),
        right: $r("app.float.distance_16"),
        top: $r("app.float.distance_6_5")
      })

    }
    .height(ConfigData.WH_100_100)
    .width(ConfigData.WH_100_100)
    .backgroundColor($r("app.color.background_color"))
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
        .fontSize($r("app.float.font_28"))
        .fontColor($r("app.color.text_color"))
        .opacity($r("app.float.opacity_6"))
        .width(ConfigData.WH_100_100)
        .margin({ left: $r("app.float.distance_16") })
      Text($r("app.string.delete_hint"))
        .fontSize($r("app.float.font_32"))
        .margin($r("app.float.distance_16"))
        .fontColor($r("app.color.text_color"))
      Row() {
        Text($r("app.string.cancel"))
          .fontSize($r("app.float.font_32"))
          .fontColor($r("app.color.text_color"))
          .width($r("app.float.wh_value_64"))
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.controller.close()
          })
          .fontColor($r("app.color.hint_color"))
        Divider().vertical(true).opacity($r("app.float.opacity_4"))
        Text($r("app.string.delete"))
          .fontSize($r("app.float.font_32"))
          .textAlign(TextAlign.Center)
          .width($r("app.float.wh_value_64"))
          .onClick(() => {
            if (this.confirm) {
              this.confirm()
              this.controller.close()
            }
          })
          .fontColor($r("app.color.warn_color"))
      }.height($r("app.float.wh_value_32"))
      .width(ConfigData.WH_100_100)
      .padding({ left: $r("app.float.wh_value_32"), right: $r("app.float.wh_value_32") })
      .justifyContent(FlexAlign.SpaceAround)
    }.padding($r("app.float.distance_24"))
  }
}