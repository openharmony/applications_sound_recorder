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
import { relationalStore } from '@kit.ArkData';

/**
 * 数据库常量
 *
 * @since 2024-09-09
 */
export namespace DatabaseConstants {

  export const NORMAL_RECORD_TABLE: string = 'normal_record_table';

  export const TableField = {
    ID: 'id',
    TITLE: 'title',
    DATE: 'date_added'
  };

  export const TAG_TABLE: string = 'tag';

  export const RECOGNIZE_AI_TABLE: string = 'recognize_ai';

  export const RECENT_DELETE_RECORD_TABLE: string = 'recent_delete_record_table';
}

/**
 * FA 表列名
 */
export class FADbProperties {

  // 卡片ID long类型
  public static readonly FORM_ID = 'formID';

  // 卡片名称
  public static readonly FORM_NAME = 'formName';

  /**
   * 卡片尺寸信息
   * 1 -> 1x2
   * 2 -> 2x2
   * ...
   */
  public static readonly SPECIFICATION_ID = 'specificationId';

  // 创建、修改时间
  public static readonly CREATE_TIME = 'createTime';
  public static readonly UPDATE_TIME = 'updateTime';

  // 卡片数据表
  public static readonly FA_FORM_INFO_COLUMNS = [
    FADbProperties.FORM_ID,
    FADbProperties.FORM_NAME,
    FADbProperties.SPECIFICATION_ID,
    FADbProperties.CREATE_TIME,
    FADbProperties.UPDATE_TIME
  ];
}


