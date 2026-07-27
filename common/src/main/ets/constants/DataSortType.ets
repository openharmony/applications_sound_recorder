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
export default class SortType {
  //时间 由远到近
  public static readonly SORT_TIME_ASC = '1';
  //时间 由近到远
  public static readonly SORT_TIME_DESC = '0';
  //名称
  public static readonly SORT_NAME_ASC = '2';

  public static getAllSortType(): string[] {
    return [
      SortType.SORT_TIME_ASC,
      SortType.SORT_TIME_DESC,
      SortType.SORT_NAME_ASC
    ]
  }
}

export class SortConstants {
  //存储到preference使用的key
  public static readonly PRE_KEY = 'sort_mode';
  //初始化过去第一个录音数据（平板环境使用）
  public static readonly INIT_GET_FIRST = 'init_get_first';
  //添加新录音后获取第一个录音数据（平板环境使用）
  public static readonly AFTER_ADD_GET_FIRST = 'after_add_get_first';
  //排序单选组
  public static readonly SORT_GROUP: string = 'data_sort_radio_group';
}