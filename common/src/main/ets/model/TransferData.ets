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
export interface TransferData {
  /**
   * 转写结果uuid，生成后唯一
   */
  id: string,

  /**
   * 录音文件的路径
   */
  recordPath: string,

  /**
   * 转写任务的sessionId，一次转写对应唯一一个sessionId，小艺组件通过该id查询转写任务的状态
   */
  sessionId: string,

  /**
   * 与小艺组件共享的转写结果json文件存储URI
   */
  fileUri: string,

  /**
   * 语音对应的领域，提供给小艺，用以进行更加精确的转写
   */
  domain: string,

  /**
   * 转写任务状态，0表示开始转写，1表示转写中，2表示转写完成
   */
  state: number,

  /**
   * 语音转文本完成时间
   */
  createTime: number,

  /**
   * 转写结果json文件存放路径
   */
  jsonPath: string,

  /**
   * 当前就是0
   */
  sourceType: number,

  /**
   * 摘要内容
   */
  summaryText: string,

  /**
   * 录音文件时长，单位毫秒
   */
  fileSize: number,

  /**
   * 实时转写不完整标识
   */
  incomplete: number
}

export interface RecordTag {
  /**
   * 标记的时间点
   */
  milliseconds: string,

  /**
   * 标记处对应的文本
   */
  taggedText: string
}