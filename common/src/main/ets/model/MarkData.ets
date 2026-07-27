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

@Observed
export class MarkData {
  public id: string = '0';
  public count: number = 0;
  public type: number = 0;
  public markDuration: number = 0;
  public title: string = '';
  public _data: string = '';
  public isSelect: boolean = false;
  // 标记对象创建事件，作为更新UI的标识
  public createTime: number = Date.now();

  constructor(title: string, markDuration: number, count: number, isSelect: boolean,
              id?: string, type?: number, _data?: string) {
    this.title = title;
    this.markDuration = markDuration;
    this.count = count;
    this.isSelect = isSelect;
    this.id = id || '0';
    this.type = type || 0;
    this._data = _data || '';
  }
}