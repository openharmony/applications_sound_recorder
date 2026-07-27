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

import { CommonConstants } from '../constants/CommonConstants';
import { RecordData } from './RecordData';

@Observed
export class SearchResult {
  public isTitle: boolean = false;
  public title: string = CommonConstants.EMPTY_STR;
  public isCallRecord: boolean = false;
  public record: RecordData = new RecordData();
  public lastOne: boolean = false;
  public isFocus: boolean = false;

  public constructor(isTitle: boolean, title: string, isCallRecord?: boolean, record?: RecordData, lastOne?: boolean,
    isFocus?: boolean)

  public constructor(isTitle?: boolean, title?: string, isCallRecord?: boolean, record?: RecordData, lastOne?: boolean,
    isFocus?: boolean)

  public constructor(isTitle: boolean, title: string, isCallRecord: boolean, record: RecordData, lastOne: boolean,
    isFocus: boolean)

  public constructor(isTitle?: boolean, title?: string, isCallRecord?: boolean, record?: RecordData, lastOne?: boolean,
    isFocus?: boolean) {
    this.isTitle = isTitle ? isTitle : false;
    this.title = title ? title : CommonConstants.EMPTY_STR;
    this.isCallRecord = isCallRecord ? isCallRecord : false;
    this.record = record ? record : new RecordData();
    this.lastOne = lastOne ? lastOne : false;
    this.isFocus = isFocus ? isFocus : false;
  }
}