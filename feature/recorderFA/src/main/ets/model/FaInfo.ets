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

export default class FaInfo {
  // 卡片ID long类型
  public formId: number | undefined;
  // 卡片名称
  public formName: string | undefined;
  /**
   * 卡片尺寸信息
   * 1 -> 1x2
   * 2 -> 2x2
   * ...
   */
  public specificationId: number | undefined;
  // 创建、修改时间
  public createTime: number | undefined;
  public updateTime: number | undefined;

  constructor(faCardRecord: Record<string, Object> = {}) {
    this.formId = faCardRecord?.formID as number;
    this.formName = faCardRecord?.formName as string;
    this.specificationId = faCardRecord?.specificationID as number;
    this.createTime = faCardRecord?.createTime as number;
    this.updateTime = faCardRecord?.updateTime as number;
  }
}

