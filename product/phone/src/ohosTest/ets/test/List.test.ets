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

import AudioControllerTest from './feature/recorder/controller/AudioControllerTest.test';
import UtilTest from './common/utils/UtilTest.test';
import UtilWithContextTest from './common/utils/UtilWithContextTest.test';
import AccessibilityUtilTest from './common/utils/AccessibilityUtilTest.test';
import RecordIndexTest from './home/RecordIndexTest.test';
import RecordingPageTest from './home/RecordingPageTest.test';
import RecordPlayPageTest from './home/RecordPlayPageTest.test';
import RecordRecycleTest from './home/RecordRecycleTest.test';
import AvRecorderTest from './feature/recorder/controller/AvRecorderTest.test';
import NotificationUtilTest from './common/utils/NotificationUtilTest.test';
import NotificationUtilManagerTest from './common/utils/NotificationManagerUtilTest.test';
import AudioRecordItemComponentTest from './feature/recorder/controller/AudioRecordItemComponent.test';
import PlayRecordTest from './home/PlayRecordTest.test';
import RecordPlayTest from './home/RecordPlayTest.test';
import RecordTest from './home/RecordTest.test';
import RecordManagerTest from './feature/recorder/controller/RecordManagerTest.test';
import AvSessionManagerTest from './feature/recorder/controller/AvSessionManagerTest.test';
import ConsentManagerTest from './feature/recorder/controller/ConsentManagerTest.test';
import AnonymousUtilTest from './common/utils/AnonymousUtilTest.test';
import DeviceUtilTest from './common/utils/TransferDataUtilTest.test';
import HoverTextTipsUtilTest from './common/utils/HoverTextTipsUtilTest.test';
import ContactsManagerUtilTest from './common/utils/ContactsManagerUtilTest.test';
import DatabaseManagerTest from './common/utils/DatabaseManagerTest.test';
import FlexBoxTestTest from './common/model/FlexBoxTest.test';
import Record2x1FormTest from './home/Record2x1FormTest.test';
import Record2x2FormTest from './home/Record2x2FormTest.test';
import PlayRecordEnhanceControlTest from './home/PlayRecordEnhanceControlTest.test';
import PlayCallRecordEnhanceControlTest from './home/PlayCallRecordEnhanceControlTest.test';
import EditRecordTest from './home/EditRecordTest.test';
import PlayRecordMenuPageTest from './home/PlayRecordMenuPageTest.test';
import PlayCallRecordMenuPageTest from './home/PlayCallRecordMenuPageTest.test';
import RecordMoreMenuPageTest from './home/RecordMoreMenuPageTest.test';
import RecordRecyclePageTest from './home/RecordRecyclePageTest.test';
import EditCallRecordTest from './home/EditCallRecordTest.test';
import PathUtilTest from './common/utils/PathUtil.test';
import FileUtilTest from './common/utils/FileUtil.test';
import HelpsTest from './common/helps/Helps.test';

/**
 *如果报 execute time XXms 异常，在 IDE Run->Edit Configurations 中调整 Time Out
 */
export default function testsuite() {
  // UT
  HelpsTest();
  FileUtilTest();
  UtilTest();
  PathUtilTest();

  // DT
  PlayRecordEnhanceControlTest();
  PlayCallRecordEnhanceControlTest();
  AudioControllerTest();
  UtilWithContextTest();
  AccessibilityUtilTest();
  RecordIndexTest();
  RecordingPageTest();
  RecordPlayPageTest();
  AvRecorderTest();
  NotificationUtilTest();
  NotificationUtilManagerTest();
  AudioRecordItemComponentTest();
  PlayRecordTest();
  RecordPlayTest();
  RecordTest();
  PlayRecordMenuPageTest();
  PlayCallRecordMenuPageTest();
  EditRecordTest();
  EditCallRecordTest();
  RecordMoreMenuPageTest();
  RecordManagerTest();
  Record2x2FormTest();
  Record2x1FormTest();
  AvSessionManagerTest();
  ConsentManagerTest();
  RecordRecycleTest();
  RecordRecyclePageTest();
  AnonymousUtilTest();
  DeviceUtilTest();
  HoverTextTipsUtilTest();
  ContactsManagerUtilTest();
  DatabaseManagerTest();
  FlexBoxTestTest();
}