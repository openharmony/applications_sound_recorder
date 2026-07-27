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
import { resourceManager } from '@kit.LocalizationKit';

const TAG = 'SoundRecorder_ResourceManagerUtil';

/**
 * resource方法基类
 *
 * @since 2024-05-23
 */

class ResourceManagerUtil {
  public resourceToString(title: Resource, context: Context): string {
    let resource: resourceManager.Resource = {
      bundleName: title.bundleName,
      moduleName: title.moduleName,
      id: title.id
    };
    let titleString: string = context.resourceManager.getStringSync(resource);
    return titleString;
  }

  /* instrument ignore next */
  public resourceStrToString(resource: ResourceStr, context: Context, ...args: Array<string | number>): string {
    let resStr: string = '';
    if (typeof resource === 'string') {
      return resource as string;
    }
    resStr = context.resourceManager.getStringSync(resource.id, ...args);
    return resStr;
  }
}

export default new ResourceManagerUtil();