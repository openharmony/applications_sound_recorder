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

export class Util {

  /**
   * Time format is converted to seconds
   * @param timestamp
   * @param hasHour
   */
  timeFormat(timestamp: number, hasHour: boolean =  true): string {
    if (timestamp < 0) {
      return ""
    }
    let timeStr = ""
    let hour = Math.floor(timestamp % (24 * 60 * 60 * 1000) / (60 * 60 * 1000))
    if (hasHour || hour > 0) {
      timeStr += this.addZero(hour) + ":"
    }
    let min = Math.floor(timestamp % (60 * 60 * 1000) / (60 * 1000))
    timeStr += this.addZero(min) + ":"
    let sec = Math.floor(timestamp % (60 * 1000) / 1000)
    timeStr += this.addZero(sec)
    return timeStr
  }

  /**
   * Time format is converted to milliseconds
   * @param timestamp
   */
  timeFormatMs(timestamp: number): string {
    if (timestamp <= 0) {
      return "00:00.00"
    }
    let timeStr = ""
    let hour = Math.floor(timestamp % (24 * 60 * 60 * 1000) / (60 * 60 * 1000))
    if (hour > 0) {
      timeStr += this.addZero(hour) + ":"
    }
    let min = Math.floor(timestamp % (60 * 60 * 1000) / (60 * 1000))
    timeStr += this.addZero(min) + ":"
    let sec = Math.floor(timestamp % (60 * 1000) / 1000)
    timeStr += this.addZero(sec)
    if (hour < 1) {
      let mSec = Math.floor(timestamp % 1000 / 10)
      timeStr += "." + this.addZero(mSec)
    }
    return timeStr
  }

  /**
   * Gets the date at the specified time
   * @param date
   */
  getDateFormat(date: number): string {
    let nowDate = new Date(date)
    return nowDate.getFullYear() + "/" + this.addZero(nowDate.getMonth() + 1) + "/" + this.addZero(nowDate.getDate())
  }

  /**
   * Gets the hour, minute and second of the specified time
   * @param date
   */
  getTimeFormat(date: number): string {
    let nowDate = new Date(date)
    return this.addZero(nowDate.getHours()) + ":" + this.addZero(nowDate.getMinutes()) + ":" + this.addZero(nowDate.getSeconds())
  }

  /**
   * Gets the current time date
   */
  getDate(): string {
    let nowDate = new Date()
    return nowDate.getFullYear() + this.addZero(nowDate.getMonth() + 1) + this.addZero(nowDate.getDate())
  }

  /**
   * Gets the hour, minute and second of the current time
   */
  getTime(): string {
    let nowDate = new Date()
    return this.addZero(nowDate.getHours()) + this.addZero(nowDate.getMinutes()) + this.addZero(nowDate.getSeconds())
  }

  /**
   * If the number is less than 10, add "0".
   * @param num
   */
  addZero(num: number): string{
    return (num < 10 ? "0" + num : num).toString()
  }
}

let util = new Util();

export default util as Util;