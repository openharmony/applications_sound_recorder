// Script for compiling build behavior. It is built in the build plug-in and cannot be modified currently.
// FA模型此处改为：
// import { legacyHapTasks as hapTasks } from '@ohos/hvigor-ohos-plugin';
import { hapTasks } from '@ohos/hvigor-ohos-plugin';
import * as path from 'path';
import { hvigor, getHvigorNode } from '@ohos/hvigor';

const mModule = getHvigorNode(__filename);
const ohosPlugin = hapTasks(mModule);

const onlineSignHapTaskName = "onlineSignHap";
let curTargetName = "default";
const mModuleName = mModule.getName();
const projectRootPath = process.cwd() + '/product';

const config = {
    hvigor: hvigor,
    packageConfig: {
        appName: 'SoundRecorder', // 与cde架构定义的模块名相同，每个模块流水线归档的hap名，必须配置
        commandParams: hvigor.getExtraConfig(), // hvigor 命令行参数
        module: mModule, // 当前模块对象,
        entryName: ''
        //packageType:'shared'  //配置这个参数时，该模块在hypium-plugin中按照hsp来打包和签名
    }
}

// 若是feature模块签名，此处填写依赖的entry模块名称
const entryName = '';

ohosPlugin.getNeedExecTargetServiceList().forEach(targetServices => {

    curTargetName = targetServices.getTargetData().getTargetName();

    // 注册在线签名任务和创建任务依赖
    const onlineSignTask = mModule.task(() => {
        // 构建的未签名的hap的输出根目录
        const moduleBuildOutputDir = path.resolve(projectRootPath, mModuleName, `build/default/outputs/${curTargetName }/`);

        // 未签名的hap包路径
        const inputFile = path.resolve(moduleBuildOutputDir, `${mModuleName}${entryName? '-' + entryName: ''}-${curTargetName }-unsigned.hap`);
        // 签名后的hap包路径
        const outputFile = path.resolve(moduleBuildOutputDir, `${mModuleName}${entryName? '-' + entryName: ''}-${curTargetName }-signed.hap`);

        // executeOnlineSign(inputFile, outputFile);

        // FA模型此处改为：
        // }, onlineSignHapTaskName).dependsOn(`${curTargetName}@LegacyPackageHap`);
    }, onlineSignHapTaskName).dependsOn(`${curTargetName}@PackageHap`);

    // 使用在线签名,可以把离线签名任务disable掉
    if (onlineSignTask.getEnabled()) {
        // mModule.getTaskByName(`${curTargetName}@SignHap`).setEnabled(false);
    }
});

let initTesting: ((config: object) => void) | undefined;
try {
    initTesting = require('@ohos/hypium-plugin').initTesting;
} catch (e) {
    // hypium plugin is optional for normal build; tests can enable it by installing the package.
}

if (initTesting) {
    initTesting(config);
}

// 将在线签名任务挂接在assembleHap任务上,如果需要在IDE上使用,assembleHap任务是固定的
mModule.getTaskByName("assembleHap").dependsOn(onlineSignHapTaskName);

module.exports = {
    ohos: ohosPlugin
}

export default {
    system: ohosPlugin,  /* Built-in plugin of Hvigor. It cannot be modified. */
    plugins:[]         /* Custom plugin to extend the functionality of Hvigor. */
}
