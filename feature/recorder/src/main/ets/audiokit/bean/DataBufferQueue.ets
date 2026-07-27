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

import { Queue } from '@kit.ArkTS';
import { LogUtil } from '@ohos/common';

const TAG = '[DataBufferQueueTAG]';

/**
 * 目标数据长度
 */
const TARGET_DATA_LEN = 160;

/**
 * 数据分包队列
 *
 * 耳机上报的PCM数据流每包长度为3584，实时转写接收流每包限制长度160
 * 需要做分包处理，剩余包长不足160，拼接到下一个包
 */
export class DataBufferQueue {
  /**
   * 数据队列，先进先出，入队的item为长度160的数组
   */
  private dataQueue: Queue<number[]>;
  /**
   * 剩余数据缓存
   */
  private temp: number[];

  constructor() {
    this.dataQueue = new Queue();
    this.temp = [];
  }

  /**
   * 添加数据流到队列
   * @param buffer 耳机录音pcm数据流
   */
  public add(buffer: number[]): void {
    try {
      for (const data of buffer) {
        this.temp.push(data);
        if (this.temp.length === TARGET_DATA_LEN) {
          this.dataQueue.add(this.temp);
          this.temp = [];
        }
      }
    } catch (error) {
      LogUtil.error(`${TAG} add data to queue fail: ${error?.code} ${error?.message}`);
    }
  }

  /**
   * 从队列取出数据流
   * @returns 长度为TARGET_DATA_LEN的数据流
   */
  public pop(): number[] {
    try {
      if (this.dataQueue.length <= 0) {
        return [];
      }
      return this.dataQueue.pop();
    } catch (error) {
      LogUtil.error(`${TAG} pop data from queue fail: ${error?.code} ${error?.message}`);
      return [];
    }
  }
}