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
import { AudioRecordItemComponent } from './src/main/ets/components/AudioRecordItemComponent'
import { AudioRecordListComponent } from './src/main/ets/components/AudioRecordListComponent'
import { MarkListComponent } from './src/main/ets/components/MarkListComponent'
import { ProgressBarComponent } from './src/main/ets/components/ProgressBarComponent'
import { RequestPermissionDialog } from './src/main/ets/dialog/RequestPermissionDialog'
import { RecordPlayPage } from './src/main/ets/pages/RecordPlayPage'
import { SideBarComponent } from './src/main/ets/components/SideBarComponent'

export { RecorderState } from './src/main/ets/enums/RecorderState'

export { RecordManager } from './src/main/ets/controller/RecordManager'

export { PlayManager } from './src/main/ets/controller/PlayManager'

export { AvSessionManager } from './src/main/ets/controller/AvSessionManager'

export { default as MediaController } from './src/main/ets/controller/MediaController'

// export { ContinuousTask } from '../../common/src/main/ets/utils/ContinuousTask'

export { ScreenStateListener } from './src/main/ets/notification/ScreenStateListener'

export { FoldStateListener } from './src/main/ets/notification/FoldStateListener'

export { RecordNotification } from './src/main/ets/notification/RecordNotification'

// export {
//   RecordData, DataToast, RouterParams, LazyDataSource
// } from '../../common/src/main/ets/model/RecordData'

export { VoiceData, RecordObj } from './src/main/ets/controller/WaveController'


export { BaseViewModel } from './src/main/ets/viewModel/BaseViewModel'

export { RecorderDataRequestServiceImpl } from './src/main/ets/service/RecorderDataRequestServiceImpl';

export {
  AudioRecordListComponent,
  AudioRecordItemComponent,
  MarkListComponent,
  ProgressBarComponent,
  RequestPermissionDialog,
  RecordPlayPage,
  SideBarComponent
};
