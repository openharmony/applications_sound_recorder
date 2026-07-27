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
 * 实况常量
 *
 *
 * @since 2024-07-15
 */
export namespace NotificationConstants {

  export enum UpdateNotificationMode {
    UPDATE_BY_STATE = 0,
    UPDATE_BY_DARK_MODE = 1
  }

  export enum PixMapSizeType {
    ICON_SIZE = 0,
    ICON_SIZE_CAPSULE = 1
  }

  export enum PixMapSizeNumber {
    // 18 * 3.5
    CAPSULE_ICON_SIZE = 63,
    // 40 * 3.5
    MEDIUM_ICON_SIZE = 140,
    // 通知小图标建议尺寸 128 * 128
    APP_ICON_SIZE = 128
  }

  export const NOTIFICATION_ID: number = 1003;
}