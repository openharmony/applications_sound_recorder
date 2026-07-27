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

export const Events = {
  UPDATE_GROUP_LIST_COUNT: 'update.group.list.count',
  FLUSH_RECORDS_TO_UI_LIST: 'flush.records.to.ui.list',
  // migration
  MIGRATION_COMPLETED_COUNT_UPDATE: 'migration.completed.count.update',
  MIGRATION_FLOW_STATUS_UPDATE: 'migration.flow.status.update',
  MIGRATION_ITEM_UPDATE: 'migration.item.update',
  MIGRATION_TIPS_SHOW: 'migration.tips.show',
  MIGRATION_TOTAL_UPDATE: 'migration.total.update',
  MIGRATION_INSUFFICIENT_SPACE_TYPE: 'migration.space.insufficient.type',
} as const;