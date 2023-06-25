/**
 * Copyright (c) 2022 HiHope Open Source Organization.
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
import { RecordController, MediaController, RecordState } from '@ohos/recorder'
import router from '@ohos.router';
import mediaLibrary from '@ohos.multimedia.mediaLibrary'
import prompt from '@ohos.prompt';
import call from '@ohos.telephony.call';

const TIME_INTERVAL_S = 2;
const TIME_COUNT = 2 * 2 + 1;
const VOICE_FREQUENCY = 25;

@Entry
@Component
struct RecordingPage {
  @State currentTime: number = 0
  @State state: RecordState = RecordState.IDLE
  private recordController: RecordController = new RecordController()
  @State fileAsset: mediaLibrary.FileAsset = undefined
  heightList: Array<number> = []
  mIntervalId = -1

  async aboutToAppear() {
    let that = this
    this.recordController.setTimeUpdateListener((currentTimeMs: number) => {
      if (Math.floor(currentTimeMs / (TIME_COUNT / 2 * 1000 * TIME_INTERVAL_S / VOICE_FREQUENCY)) - Math.floor(this.currentTime / (TIME_COUNT / 2 * 1000 * TIME_INTERVAL_S / VOICE_FREQUENCY)) == 1) {
        that.heightList.splice(0, 1)
        that.heightList.push(this.recordController.getSoundVolume())
      }
      this.currentTime = currentTimeMs
    })
    this.recordController.setStateUpdateListener((state) => {
      this.state = state
    })
    this.recordController.initAudioRecorder()
    this.fileAsset = await MediaController.createAudioFile()
    let fd = await this.fileAsset.open('Rw')
    this.recordController.startRecorder(`fd://${fd}`)
    this.initHeightList()
  }

  aboutToDisappear() {
    if (this.state != RecordState.IDLE) {
      this.recordController.stop()
    }
  }

  initHeightList() {
    this.heightList = []
    for (let index = 0; index < VOICE_FREQUENCY; index++) {
      this.heightList.push(0)
    }
  }

  build() {
    Column() {
      Row() {
        Row() {
          Image($r("app.media.ic_back"))
            .width($r("app.float.wh_value_32"))
            .height($r("app.float.wh_value_32"))
            .margin({ left: $r("app.float.distance_32"), right: $r("app.float.distance_16") })
          Text($r("app.string.title"))
            .fontColor($r("app.color.text_color"))
            .fontSize($r("app.float.font_40"))
            .lineHeight($r("app.float.wh_value_37_5"))
        }
        .onClick(() => {
          router.back()
        })

        Image($r("app.media.ic_clock_enhance"))
          .width($r("app.float.wh_value_32"))
          .height($r("app.float.wh_value_32"))
          .margin({ right: $r("app.float.distance_32") })
      }
      .height($r("app.float.wh_value_56"))
      .width(ConfigData.WH_100_100)
      .justifyContent(FlexAlign.SpaceBetween)

      Stack({ alignContent: Alignment.Top }) {
        Column() {
          Row() {
            ForEach(Array.from(Array(TIME_COUNT + 1).keys()), (item) => {
              Column() {
                Text(Util.timeFormat(((item - (TIME_COUNT - 1) / 2) * 1000 * TIME_INTERVAL_S + Math.floor(this.currentTime / (1000 * TIME_INTERVAL_S)) * (1000 * TIME_INTERVAL_S)), false))
                  .textAlign(TextAlign.Center)
                  .fontColor($r("app.color.text_color"))
                  .fontSize($r("app.float.font_20"))
                  .opacity($r("app.float.opacity_6"))
                Row() {
                  ForEach(Array.from(Array(5).keys()), (scaleItem) => {
                    Rect()
                      .width($r("app.float.wh_value_2_5"))
                      .fill($r("app.color.text_color"))
                      .height(scaleItem == 2 ? $r("app.float.wh_value_26_5") : $r("app.float.wh_value_13_5"))
                      .opacity(scaleItem == 2 ? $r("app.float.opacity_4") : $r("app.float.opacity_2"))
                  }, scaleItem => scaleItem)
                }.width(ConfigData.WH_100_100)
                .alignItems(VerticalAlign.Top)
                .height($r("app.float.wh_value_26_5"))
                .justifyContent(FlexAlign.SpaceAround)
              }.width((100 / TIME_COUNT) + "%")
            }, item => item)
          }
          .offset({
            x: (-(100 / TIME_COUNT) * (this.currentTime % (TIME_INTERVAL_S * 1000) / (TIME_INTERVAL_S * 1000))) + "%"
          })

          Row() {
            Row() {
              Row() {
                ForEach(Array.from(Array(VOICE_FREQUENCY).keys()), (item) => {
                  Rect()
                    .width($r("app.float.wh_value_2_5"))
                    .fill($r("app.color.text_color"))
                    .height(this.heightList[item])
                    .opacity($r("app.float.opacity_2"))
                }, item => item)
              }.width(ConfigData.WH_100_100)
              .justifyContent(FlexAlign.SpaceAround)
              .offset({
                x: (-(100 / VOICE_FREQUENCY) * (this.currentTime % (TIME_COUNT / 2 * 1000 * TIME_INTERVAL_S / VOICE_FREQUENCY) / (TIME_COUNT / 2 * 1000 * TIME_INTERVAL_S / VOICE_FREQUENCY) - 1)) + "%"
              })
            }
            .clip(true)
            .width(ConfigData.WH_50_100)
            .height(ConfigData.WH_100_100)
          }
          .justifyContent(FlexAlign.Start)
          .width(ConfigData.WH_100_100)
          .height($r("app.float.wh_value_266_5"))
          .backgroundColor($r("app.color.shadow_color"))
        }

        Column() {
          Rect()
            .height($r("app.float.wh_value_304"))
            .width($r("app.float.wh_value_2_5"))
            .fill($r("app.color.pointer_color"))
          Circle()
            .height($r("app.float.wh_value_10_5"))
            .width($r("app.float.wh_value_10_5"))
            .fill($r("app.color.pointer_color"))
        }.margin({ top: $r("app.float.distance_16") })

      }.width(ConfigData.WH_100_100)
      .height($r("app.float.wh_value_346_5"))


      Text(Util.timeFormatMs(this.currentTime))
        .fontColor($r("app.color.text_color"))
        .fontSize($r("app.float.font_96"))
        .lineHeight($r("app.float.wh_value_85_5"))
      Text($r("app.string.predict_hint"))
        .fontColor($r("app.color.text_color"))
        .fontSize($r("app.float.font_28"))
        .opacity($r("app.float.opacity_6"))
        .visibility(this.currentTime > (10 * 1000) ? Visibility.Hidden : Visibility.Visible)
      Blank()
      Row() {
        Column() {
          Image($r("app.media.ic_clock_mark"))
            .width($r("app.float.wh_value_32"))
            .height($r("app.float.wh_value_32"))
          Text($r("app.string.mark"))
            .fontColor($r("app.color.text_color"))
            .fontSize($r("app.float.font_20"))
            .lineHeight($r("app.float.wh_value_18_5"))
        }
        .justifyContent(FlexAlign.Center)
        .height($r("app.float.wh_value_64"))
        .width($r("app.float.wh_value_64"))
        .borderRadius($r("app.float.wh_value_64"))

        Column() {
          Image(this.state == RecordState.IDLE ? $r("app.media.ic_clock_record") : $r("app.media.ic_clock_stop"))
            .width($r("app.float.wh_value_32"))
            .height($r("app.float.wh_value_32"))
        }
        .justifyContent(FlexAlign.Center)
        .height($r("app.float.wh_value_64"))
        .width($r("app.float.wh_value_64"))
        .borderRadius($r("app.float.wh_value_64"))
        .backgroundColor($r("app.color.white"))
        .onClick(async () => {
          if (this.state == RecordState.IDLE) {
            let hasCall = await call.hasCall()
            if (hasCall) {
              prompt.showToast({ message: $r('app.string.has_call_hint') })
            } else {
              this.recordController.initAudioRecorder()
              this.fileAsset = await MediaController.createAudioFile()
              let fd = await this.fileAsset.open('Rw')
              this.recordController.startRecorder(`fd://${fd}`)
            }
          } else {
            this.recordController.stop(() => {
              this.initHeightList()
              MediaController.saveFileDuration(this.fileAsset.title, this.currentTime)
              router.replace({
                url: "pages/index"
              })
            })
          }
        })

        Column() {
          Image(this.state == RecordState.RUNNING ? $r("app.media.ic_clock_suspend") : $r("app.media.ic_clock_play"))
            .width($r("app.float.wh_value_32"))
            .height($r("app.float.wh_value_32"))
          Text(this.state == RecordState.RUNNING ? $r("app.string.pause") : $r("app.string.continue_record"))
            .fontColor($r("app.color.text_color"))
            .fontSize($r("app.float.font_20"))
            .lineHeight($r("app.float.wh_value_18_5"))
        }
        .justifyContent(FlexAlign.Center)
        .height($r("app.float.wh_value_64"))
        .width($r("app.float.wh_value_64"))
        .borderRadius($r("app.float.wh_value_64"))
        .onClick(() => {
          if (this.state == RecordState.RUNNING) {
            this.recordController.pause()
          } else {
            this.recordController.resume()
          }
        })
      }
      .margin({ bottom: $r("app.float.wh_value_32") })
      .width(ConfigData.WH_100_100)
      .padding({ left: $r("app.float.distance_80"), right: $r("app.float.distance_80") })
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .height(ConfigData.WH_100_100)
    .width(ConfigData.WH_100_100)
    .backgroundColor($r("app.color.background_color"))
  }
}