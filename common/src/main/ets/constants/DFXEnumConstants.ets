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
/**
 * DFX打点相关枚举信息
 */

export namespace DFXEnumConstants {

  /**
   * 进入录音界面来源名称(应用内：1，快捷方式：2, 插件：3)
   */
  export enum StartRecordResource {
    IN_APP = 1,
    SHORTCUT = 2,
    DESKTOP_CARD = 3,
    LOCKSCREEN_CARD = 4
  }

  /**
   * 进入播放录音界面来源名称(应用内：1，播控中心：2，通话录音：3，卡片：4）
   */
  export enum EnterRecordPlayWays {
    IN_APP = 1,
    PLAYBACK_CONTROL = 2,
    CALL_RECORD = 3,
    DESKTOP_CARD = 4
  }

  /**
   * 进入方式,0:点击图标进入、1:桌面卡片进入、2:通话录音进入、3:语音触发进入、4：桌面快捷方式
   */
  export enum EnterAppWays {
    CLICK_ICON,
    DESKTOP_CARD,
    CALL_RECORD,
    VOICE_TRIGGER,
    SHORTCUT,
    X_KEY,
    LOCK_SCREEN,
    AUDIO_MANAGER
  }

  /**
   * 实况操作来源：胶囊入口：1，通知中心入口：2，锁屏通知栏入口：3
   */
  export enum LiveVideoSource {
    CAPSULE_INLET = 1,
    LOCK_SCREEN_NOTIFICATION_BAR = 2
  }

  /**
   * 实况操作：暂停：0，继续：1
   */
  export enum RecordPlayOperations {
    PAUSE,
    RESUME
  }

  /**
   * 播控操作：播控中心入口：1，通知中心入口：2，锁屏通知栏入口：3
   */
  export enum PlaybackControlSource {
    PLAYBACK_CONTROL = 1,
    LOCK_SCREEN_NOTIFICATION_BAR = 2
  }

  /**
   * 排序方式：1：时间由近及远（默认）2：时间由远及近 3：名称排序
   */
  export enum SortBy {
    SORT_TIME_DESC = 1,
    SORT_TIME_ASC = 2,
    SORT_NAME_ASC = 3
  }

  /**
   * 添加标记动作来源（录音界面:1,桌面卡片:2）
   */
  export enum AddTagSource {
    IN_APP = 1,
    DESKTOP_CARD = 2,
  }
}