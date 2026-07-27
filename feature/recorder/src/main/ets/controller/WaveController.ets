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
// 定义常量
/**
 * Constants of canvas & wave settings 波形图常量设置
 **/
// lrc and wave begin
export const LRC_LIST_VIEW_SCROLL_OFFSET: number = 3
export const WAVE_MIN_VOLUME_HEIGHT: number = 1
export const WAVE_VIEW_CELL_WIDTH: number = 60
export const WAVE_VIEW_TAG_LINE_WIDTH: number = 2
export const WAVE_VIEW_CURSOR_LINE_WIDTH: number = 2
export const WAVE_VIEW_CURSOR_CIRCLE_RADIUS: number = 4
export const WAVE_VIEW_HANDLE_LINE_WIDTH: number = 4
export const WAVE_VIEW_HANDLE_SPACE_WIDTH: number = 4
export const WAVE_VIEW_TOUCH_SPACE_WIDTH: number = 20
export const WAVE_VIEW_FRAME_LINE_WIDTH: number = 2
export const WAVE_VIEW_FRAME_WIDTH: number = 5
export const WAVE_VIEW_PADDING_TOP: number = 36
export const WAVE_VIEW_TIMER_TEXT_MARGIN_TOP: number = 12
export const WAVE_VIEW_GRADUATION_VERTICAL_LINE_HEIGHT: number = 14
export const WAVE_VIEW_GRADUATION_VERTICAL_SHORT_LINE_HEIGHT: number = 10
export const WAVE_VIEW_TAG_IMAGE_SIZE: number = 3
export const WAVE_VIEW_SCALE_TEXT_SIZE: number = 18
export const WAVE_VIEW_HORIZONTAL_LINE_HEIGHT: number = 1
export const WAVE_VIEW_OFFSET_START: number = 30
export const WAVE_VIEW_TOP_BOTTOM_BORDER_WIDTH_FOR_INK: number = 0.5
// lrc  and wave end
export const VOLUME_MAX:number = 32768 // 声音振幅最大数
export const ZOOM:number = 1.0

// 构造6s的录音时长数据
export interface RecordObj {
  time: number,
  voice: number
}

const mGraduationIntervalTime = 500
const mGraduationIntervalWidth = 15

let numArr: RecordObj[] = []
for (let i = 0; i < 30000; i = i + 120) {
  let voiceItem: RecordObj = {
    time: i,
    voice: Number((Math.random() * 130 * 0.6).toFixed(1))
  }
  numArr.push(voiceItem)
}

export class VoiceData {
  public numArr: RecordObj[] = numArr
}

export class WaveController {
  /**
   * Margin to time.
   * 宽度转换为时长，屏幕宽度 * 物理单位刻度时长 / 物理单位刻度宽度 = 屏幕宽度 * 500 / 15
   * @param margin margin distance
   * @return time
   */
  public margin2Time(margin: number): number { // 宽度转换为时间，
    // 屏幕宽度 * (2000 * 1 / 4) / (60 * DEFAULT_SCALE = 1 / 4)
    return margin * mGraduationIntervalTime / mGraduationIntervalWidth
  }

  /**
   * Time to margin.
   * 时长转换为宽度，时长 * 物理单位刻度宽度 / 物理单位刻度时长 = 时长 * 15 / 500
   * @param time time
   * @return margin distance
   */
  public time2Margin(time: number): number {
    // 音频时长 * (60 * DEFAULT_SCALE = 1 / 4) / (2000 * 1 / 4)
    return time * mGraduationIntervalWidth / mGraduationIntervalTime
  }
}
