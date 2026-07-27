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

export class JsonData {
  public isSpeakerHidden: boolean = false;
  public isFinal: boolean = false;
  public isTimeStampHidden: boolean = false;
  public speakingContent: SpeakingContent[] = [];
  public unSelectedSpeakerList: string[] = [];
}

export class SpeakingContent {
  public finalContent: string = '';
  public wordInfo: WordInfo[] = [];
  public speakerIndex: number = 1;
  public speakerInfo: string = '';
}

export class WordInfo {
  public content: string = '';
  public endTime: number = 0;
  public startTime: number = 0;
}

export class SingleJsonData {
  public summary: SummaryInfo = new SummaryInfo();
  public transcriptionResult: TranscriptionInfo[] = [];
  public transSetting: TransSettingInfo = new TransSettingInfo();
}

export class TransSettingInfo {
  public isShowingSpeaker: boolean = true;
  public isShowingTimestamp: boolean = true;
  public unSelectedSpeakerSet: string[] = [];
}

export class SummaryInfo {
  public content: string = '';
  public title: string = '';
}

export class TranscriptionInfo {
  public asrType: string = 'final';
  public replaceTextList: string[] = [];
  public clauses: ClausesInfo[] = [];
  public speakerBackgroundColor: SpeakerBackgroundColorInfo = new SpeakerBackgroundColorInfo();
  public speakerCircleColor: SpeakerCircleColorInfo = new SpeakerCircleColorInfo();
  public speakerId: number = 1;
  public speakerName: string = '';
  public speakingContent: string = '';
  public startOfSpeech: number = -1;
  public wordList: WordListInfo[] = [];
}

export class ClausesInfo {
  public endMilliseconds: number = 0;
  public isTagged: boolean = false;
  public startMilliseconds: number = 0;
  public taggedNumber: string = '';
  public text: string = '';
  public illustrations: string[] = [];
}

export class SpeakerBackgroundColorInfo {
  public bundleName: string = 'com.vassistant';
  public id: number = -1;
  public moduleName: string = 'aioffice';
  public params: string[] = [];
  public type: number = -1;
}

export class SpeakerCircleColorInfo {
  public bundleName: string = 'com.vassistant';
  public id: number = -1;
  public moduleName: string = 'aioffice';
  public params: string[] = [];
  public type: number = -1;
}

export class WordListInfo {
  public content: string = '';
  public endTime: number = 0;
  public startTime: number = 0;
}

export class SpeechInfo {
  public filePath: string = '';
  public startTime: number = -1;
  public endTime: number = 0;
  public speechText: string = '';
  public hmac: string = '';
  public iv: string = '';
}