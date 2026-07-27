import { appTasks } from '@ohos/hvigor-ohos-plugin';

import { hvigor, getHvigorNode } from '@ohos/hvigor';

let uploadTestCases: ((config: object) => void) | undefined;
try {
  uploadTestCases = require('@ohos/hypium-plugin').uploadTestCases;
} catch (e) {
  // Optional for local builds.
}

const config = {
  hvigor: hvigor,
  hvigorNode: getHvigorNode(__filename),
  templateEngName: 'SoundRecorderTest', // CDE任务模板中维护的模板英文名称
  modulesConfig: [ // 以能编译出hap包的模块为一个维度。取build-profile.json5里的module配置，表示你想对接DT流水线的模块有哪些，不对接的模块不要列在这里。
    {
      moduleName: 'phone'
    }
  ]
}

if (uploadTestCases) {
  uploadTestCases(config); // 执行上述配置的模块测试，并上传对应的用例信息。注意：本地调试时该方法务必注释掉，不然会影响流水线文本用例
}

export default {
  system: appTasks, /* Built-in plugin of Hvigor. It cannot be modified. */
  plugins: []         /* Custom plugin to extend the functionality of Hvigor. */
}
