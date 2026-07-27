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
export class LayoutData {
  private defaultSideBarWidth: number = 0;

  private defaultNavBarWidth: number = 0;

  private spSideBarWidth: number = 0;

  private spNavBarWidth: number = 0;

  private lgWindowWidth: number = 0;

  public getDefaultSideBarWidth(): number {
    return this.defaultSideBarWidth;
  }

  public setDefaultSideBarWidth(width: number) {
    this.defaultSideBarWidth = width;
  }

  public getDefaultNavBarWidth(): number {
    return this.defaultNavBarWidth;
  }

  public setDefaultNavBarWidth(width: number) {
    this.defaultNavBarWidth = width;
  }

  public getSpSideBarWidth(): number {
    return this.spSideBarWidth;
  }

  public setSpSideBarWidth(width: number) {
    this.spSideBarWidth = width;
  }

  public getSpNavBarWidth(): number {
    return this.spNavBarWidth;
  }

  public setSpNavBarWidth(width: number) {
    this.spNavBarWidth = width;
  }

  public getLgWindowWidth(): number {
    return this.lgWindowWidth;
  }

  public setLgWindowWidth(width: number) {
    this.lgWindowWidth = width;
  }
}