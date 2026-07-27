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
import { FileUtil } from '../utils/FileUtil';
import { LogUtil } from '../utils/LogUtil';
import { PathUtil } from '../utils/PathUtil';
import { MarkData } from './MarkData';

const TAG = 'SoundRecorder_RecordData';

@Observed
export class MarkDataGroup {
  public content: LazyDataSource<MarkData> = new LazyDataSource();

  constructor(content?: LazyDataSource<MarkData>) {
    // instrument ignore if
    if (content) {
      this.content = content
    }
  }
}

@Observed
export class RecordData {
  public id: number = 0;
  public title: string = '';
  public contacts: string = '';
  public location: string = '';
  public name: string = '';
  public duration: number = 0;
  public _data: string = '';
  public date: number = 0;
  public flagSelect: boolean = false;
  public tag: string = '';
  public voiceList: string = '';
  public size: number = 0;
  public phoneNumber: string = '';
  public isNeedPlay: boolean = false; // means whether play immediately if av player state changed to prepared
  public jumpRecordPlayPageTime: number = 0;
  public isSwipeExpanded: boolean = false;
  public indexDelete: boolean = false;
  public index: number = -1;
  //拼音
  public phonetic: string = '';
  //首字母
  public initials: string = '';
  //匹配模式
  public matchType: string = '';
  //匹配起点
  public matchStart: number = 0;
  //匹配终点
  public matchEnd: number = 0;
  // this is not used temporary
  public recordMode: number = 0;
  public speechText: number = 0;
  public anglePath: string = '';
  public isFileUploaded: number = 0;
  public transferVoice: string = '';
  public isSupportSessionCalibration: number = 0;
  public offsetY: number = 0;
  public itemHeight: number = 0;
  public deleteTime: number = 0;
  public delete: number = 0;
  // 语音转写状态，0表示没有开始转写，1表示转写中，2表示转写完成
  public tranState: number = -1;
  public remainDaysTip: string = '';
  public preTranState: number = -1;
  //录音文件唯一标识 fs.stat.ino
  public ino: string = '';
  //录音类型，在最近删除恢复时需要判断选中的录音类型；后续可能还会新增别的录音类型
  public type: string = '';

  /* instrument ignore next */
  constructor(data?: RecordData) {
    if (!data) {
      return;
    }
    this.id = data.id;
    this.title = data.title;
    this.name = data.name;
    this.duration = data.duration;
    this._data = data._data;
    this.date = data.date;
    this.flagSelect = data.flagSelect;
    this.tag = data.tag;
    this.voiceList = data.voiceList;
    this.size = data.size;
    this.phoneNumber = data.phoneNumber;
    this.isNeedPlay = data.isNeedPlay; // means whether play immediately if av player state changed to prepared
    this.jumpRecordPlayPageTime = data.jumpRecordPlayPageTime;
    this.isSwipeExpanded = data.isSwipeExpanded;

    this.recordMode = data.recordMode;
    this.speechText = data.speechText;
    this.anglePath = data.anglePath;
    this.isFileUploaded = data.isFileUploaded;
    this.transferVoice = data.transferVoice;
    this.isSupportSessionCalibration = data.isSupportSessionCalibration;
    this.phonetic = data.phonetic;
    this.initials = data.initials;
    this.matchType = data.matchType;
    this.matchStart = data.matchStart;
    this.matchEnd = data.matchEnd;
    this.tranState = data.tranState;
    this.preTranState = data.tranState;
    this.ino = data.ino;
    this.type = data.type
  }
}

@Observed
export class LazyDataSource<T> implements IDataSource {
  public static LOAD_COUNT_PER_TIME = 100;
  private elements: T[];
  private listeners: Set<DataChangeListener>;

  constructor(elements: T[] = []) {
    this.elements = elements;
    this.listeners = new Set();
  }

  public updateAllData(newData: T[]) {
    this.elements = newData;
    this.reload();
  }

  public totalCount(): number {
    return this.elements.length;
  }

  public getData(index: number): T {
    return this.elements[index];
  }

  /* instrument ignore next */
  public indexOf(item: T): number {
    return this.elements.indexOf(item);
  }

  public findIndexOf(data: RecordData): number {
    return this.elements.findIndex(item => (item as RecordData)._data === data._data);
  }

  /* instrument ignore next */
  public pinItem(item: T, index: number): void {
    this.elements.splice(index, 1);
    this.elements.unshift(item);
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  /* instrument ignore next */
  public addItem(item: T) {
    this.elements.unshift(item);
    this.listeners.forEach(listener => listener.onDataAdd(0));
  }

  /* instrument ignore next */
  public pushItem(item: T) {
    this.elements.push(item);
    this.listeners.forEach(listener => listener.onDataAdd(this.elements.length - 1));
  }

  /* instrument ignore next */
  public batchPushItem(item: T[]) {
    for (let i = 0; i < item.length; i++) {
      this.elements.push(item[i]);
    }
    this.reload();
  }

  public reload() {
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  public insertItem(item: T, index: number) {
    this.elements.splice(index, 0, item);
    this.listeners.forEach(listener => listener.onDataAdd(index));
  }

  public insertItemWithOutNotify(item: T, index: number) {
    this.elements.splice(index, 0, item);
  }

  /* instrument ignore next */
  public insertItemsWithOutNotify(items: T[], index: number): void {
    this.elements.splice(index, 0, ...items);
  }

  /* instrument ignore next */
  public deleteItem(item: T): void {
    const index = this.elements.indexOf(item);
    if (index < 0) {
      return
    }
    this.elements.splice(index, 1);
    this.listeners.forEach(listener => listener.onDataReloaded());
  }

  /* instrument ignore next */
  public deleteItemByIndex(index: number): void {
    this.elements.splice(index, 1);
    this.listeners.forEach(listener => listener.onDataDelete(index));
  }

  public deleteItemByIndexWithOutNotify(index: number): void {
    this.elements.splice(index, 1);
  }

  /* instrument ignore next */
  public deleteItemByPredicate(predicate: (value: T) => boolean): void {
    let index = this.elements.findIndex(item => predicate(item));
    this.elements.splice(index, 1);
  }

  public registerDataChangeListener(listener: DataChangeListener): void {
    this.listeners.add(listener);
  }

  public unregisterDataChangeListener(listener: DataChangeListener): void {
    this.listeners.delete(listener);
  }

  public deleteAll(): void {
    this.elements.splice(0, this.elements.length);
    this.reload();
  }

  public updateData(index: number, newData: T): void {
    this.elements[index] = newData;
    this.listeners.forEach(listener => listener.onDataChange(index));
  }

  /* instrument ignore next */
  public forEach(predicate: (value: T) => void): void {
    for (let i = 0; i < this.elements.length; i++) {
      predicate(this.elements[i]);
    }
  }

  public getAll(): T[] {
    return this.elements;
  }
}

/* instrument ignore next */
export class RecordDataGroupArray extends Array {
  public allRecordList: LazyDataSource<RecordData> = new LazyDataSource();
  public callRecordList: LazyDataSource<RecordData> = new LazyDataSource();
  public normalRecordList: LazyDataSource<RecordData> = new LazyDataSource();
  public recentDeleteList: LazyDataSource<RecordData> = new LazyDataSource();
  public headsetRecordList: LazyDataSource<RecordData> = new LazyDataSource();

  constructor() {
    super();
  }
}

export interface DataToast {
  isShow: boolean,
  fileName: string,
  isInBackground: boolean
}

export interface RouterParams {
  time: number;
  obj: Record<string, Array<number>>;
  currentTimePlay?: number;
}