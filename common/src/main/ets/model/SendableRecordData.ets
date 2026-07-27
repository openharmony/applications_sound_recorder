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
@Sendable
export class SendableRecordData {
  public id: number = 0;
  public location: string = '';
  public contacts: string = '';
  public title: string = '';
  public duration: number = 0;
  public name: string = '';
  public date: number = 0;
  public flagSelect: boolean = false;
  public isSwipeExpanded: boolean = false;
  public indexDelete: boolean = false;
  public tag: string = '';
  public _data: string = '';
  public size: number = 0;
  public voiceList: string = '';
  public phoneNumber: string = '';
  public isNeedPlay: boolean = false; // means whether play immediately if av player state changed to prepared
  public jumpRecordPlayPageTime: number = 0;
  public index: number = -1;
  //匹配起点
  public matchStart: number = 0;
  //匹配终点
  public matchEnd: number = 0;
  //匹配模式
  public matchType: string = '';
  //拼音
  public phonetic: string = '';
  //首字母
  public initials: string = '';
  // 用于控件当前录音是否允许显示进度条，在悬浮菜单场景中，需要改变该值控制进度条的隐藏
  public sliderCanShow: boolean = true;
  // this is not used temporary
  public isFileUploaded: number = 0;
  public speechText: number = 0;
  public recordMode: number = 0;
  public anglePath: string = '';
  public tranState: number = -1;
  public remainDaysTip: string = '';
  public preTranState: number = -1;
  public isSupportSessionCalibration: number = 0;
  public itemHeight: number = 0;
  public deleteTime: number = 0;
  public offsetY: number = 0;
  public transferVoice: string = '';
  public delete: number = 0;
  public ino: string = '';
  public type: string = '';
}