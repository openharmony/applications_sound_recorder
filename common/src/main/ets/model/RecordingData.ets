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

/**
 * RecoringData
 */
export default class RecordingData {
  private currentLocation: string = '';
  private fileName: string = '';
  private filePath: string = '';
  private savedRecordName: string = '';
  private createTime: number = 0;
  private startQuickTrans: boolean = false;
  private transferDataId: string = '';
  private jsonFilePath: string = '';
  private jsonFileUri: string = '';
  //录音实时转写不完整标识
  private incomplete: boolean = false;

  public setSavedRecordName(value: string) {
    this.savedRecordName = value;
  }

  public getSavedRecordName(): string {
    return this.savedRecordName;
  }

  public setFilePath(value: string) {
    this.filePath = value;
  }

  public getFilePath(): string {
    return this.filePath;
  }

  public setFileName(value: string) {
    this.fileName = value;
  }

  public getFileName(): string {
    return this.fileName;
  }

  public setCreateTime(value: number) {
    this.createTime = value;
  }

  public getCreateTime(): number {
    return this.createTime;
  }

  public setCurrentLocation(value: string) {
    this.currentLocation = value;
  }

  public getCurrentLocation(): string {
    return this.currentLocation;
  }

  public setStartQuickTrans(value: boolean) {
    this.startQuickTrans = value;
  }

  public getStartQuickTrans(): boolean {
    return this.startQuickTrans;
  }

  public setTransferDataId(value: string) {
    this.transferDataId = value;
  }

  public getTransferDataId(): string {
    return this.transferDataId;
  }

  public setJsonFilePath(value: string) {
    this.jsonFilePath = value;
  }

  public getJsonFilePath(): string {
    return this.jsonFilePath;
  }

  public setJsonFileUri(value: string) {
    this.jsonFileUri = value;
  }

  public getJsonFileUri(): string {
    return this.jsonFileUri;
  }

  public setIncomplete(value: boolean) {
    this.incomplete = value;
  }

  public getIncomplete(): boolean {
    return this.incomplete;
  }
}