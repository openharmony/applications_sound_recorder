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

export enum RecorderMigrationType {
  QUERY_RECORD = 0,
  READ_RECORD = 1,
  OPEN_RECORD = 2,
  WRITE_RECORD = 3,
  APPLY_RECORD = 4,
  DELETE_RECORD = 5
}

export enum CallBackCodeType {
  CODE_SUCCESS = 0,
  CODE_FAILED = -1
}
