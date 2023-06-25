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

import { ConfigData } from '@ohos/common'
import { recordList } from './recordList'
import { RecordingPage } from './RecordingPage'
import { StateController } from '@ohos/recorder'

@Entry
@Component
struct Index {
  private stateController = new StateController()

  build() {
    Row() {
      Column() {
        recordList({ stateController: this.stateController })
      }
      .padding({
        left: $r("app.float.distance_12"),
        right: $r("app.float.distance_12"),
        top: $r("app.float.distance_8"),
        bottom: $r("app.float.distance_8"),
      })
      .width($r("app.float.wh_value_256"))
      .height(ConfigData.WH_100_100)

      Divider().vertical(true).opacity($r("app.float.opacity_2"))
      Column() {
        RecordingPage({ stateController: this.stateController })
      }
      .height(ConfigData.WH_100_100)
      .width($r("app.float.wh_value_383"))

    }
    .backgroundColor($r("app.color.background_color"))
    .width(ConfigData.WH_100_100)
    .height(ConfigData.WH_100_100)
  }
}

