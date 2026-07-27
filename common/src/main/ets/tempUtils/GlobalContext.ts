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

import { common, Context } from '@kit.AbilityKit';

enum Ctx {
  UI_ABILITY = 0,
  BACKUP_ABILITY = 1,
}

class GlobalContext {
  private static instance?: GlobalContext;
  private cache = new Map<Ctx, Context>();

  private constructor() {
  }

  public static getInstance(): GlobalContext {
    if (!GlobalContext.instance) {
      GlobalContext.instance = new GlobalContext();
    }
    return GlobalContext.instance;
  }

  public getBackupAbilityContext(): Context {
    return this.getContext(Ctx.BACKUP_ABILITY);
  }

  public setBackupAbilityContext(ctx: Context): void {
    this.setContext(Ctx.BACKUP_ABILITY, ctx);
  }

  public getUIAbilityContext(): common.UIAbilityContext {
    return this.getContext(Ctx.UI_ABILITY) as common.UIAbilityContext;
  }

  public setUIAbilityContext(ctx: common.UIAbilityContext): void {
    this.setContext(Ctx.UI_ABILITY, ctx);
  }

  private getContext(key: Ctx): Context | undefined {
    return this.cache.get(key);
  }

  private setContext(key: Ctx, ctx: Context): void {
    this.cache.set(key, ctx);
  }
}

export default GlobalContext.getInstance();