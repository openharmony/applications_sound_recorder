#!/bin/bash
#
# Copyright (c) Huawei Device Co., Ltd. 2026. All rights reserved.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -ex
device_type=$1
echo "old NODE_HOME is ${NODE_HOME}"

# NODE_HOME的环境变量多配置了一个bin目录, 在这里去除掉
[[ "${NODE_HOME}" =~ .*\bin$ ]] && NODE_HOME=${NODE_HOME%\bin*}
echo "new NODE_HOME is ${NODE_HOME}"
echo "HM_SDK_HOME is ${HM_SDK_HOME}"
echo "OHOS_SDK_HOME is ${OHOS_SDK_HOME}"
echo "OHOS_BASE_SDK_HOME is ${OHOS_BASE_SDK_HOME}"
node -v
npm -v

# 初始化相关路径
APP_HOME="$(pwd -P)"
TOOLS_INSTALL_DIR=${APP_HOME}

# 获得签名jar文件
# cd ${APP_HOME}/signature
# chmod +x build.sh
# ./build.sh

function init_npm() {
  # npm config set registry
  # npm config set @ohos:registry
  npm config set strict-ssl false
}

function init_ohpm() {
  # 配置仓库地址
  # ohpm config set registry
  ohpm config set strict_ssl false
  # ohpm config set

  # 代理配置
  PASS_ENCODE=$(echo -ne ${ONLINE_PASSWD} | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
  ohpm config set no_proxy .com
  # config set http_proxy
  # ohpm config set https_proxy

  ohpm install --all
}

function init_har() {
  cd $1
  # 目前内网的ohpm仓库未准备好，过渡期间还是往npm仓库发布，所以需要package.json文件
  cp oh-package.json5 package.json
}

# src源码打包至Dtpipeline.zip
function copy_srccode_to_dtpipeline() {
    # 定义路径变量
    local base_output_phone="build/outputs/Soundrecorder/source"
    # 定义模块及其源代码路径
    local modules=(
        "common"
        "feature/recorder"
    )
    # 创建目录并复制文件
    for module in "${modules[@]}"; do
        # 创建目录
        mkdir -p "$base_output_phone/$module"
        # 复制文件
        if [ -d "$module/src" ]; then
            cp -r "$module/src" "$base_output_phone/$module"
        else
            echo "Warning: Source directory $module/src does not exist."
        fi
    done
    # 单独拷贝product
    mkdir -p "$base_output_phone/product/phone"
    cp -r "product/phone/src" "$base_output_phone/product/phone"
}

# 环境适配
function build() {
  # 根据业务情况适配local.properties
  cd ${APP_HOME}
  echo "sdk.dir=${HM_SDK_HOME}" >./local.properties
  echo "nodejs.dir=${NODE_HOME}" >>./local.properties

  # 根据业务情况，采用对应的构建命令，可以参考IDE构建日志中的命令
  cd ${APP_HOME}
  echo "clean"
  # ./signature/build.sh

  echo "----------------- clean --------------------"
  hvigorw clean --no-daemon --stacktrace

  echo "----------------- build phone default hap --------------------"
  hvigorw --mode module -p module=phone@default -p isOhosTest=true -p product=default -p buildMode=test -p ohos-test-coverage=true -p debuggable=false assembleHap --parallel --incremental --no-daemon --stacktrace
  echo "----------------- build phone ohosTest hap --------------------"
  hvigorw --mode module -p module=phone@ohosTest -p buildMode=test -p debuggable=false assembleHap packageTesting --parallel --incremental --no-daemon --stacktrace


  copy_srccode_to_dtpipeline

  echo "----------------- handle DTPipeline.zip --------------------"
  has_package_dtpipeline=0
  if [ -e "build/DTPipeline.zip" ]; then
    file_size=$(stat -c%s "build/DTPipeline.zip")
    if [ $file_size -gt 0 ]; then
      echo "DTPipeline.zip is normal"
      has_package_dtpipeline=1
      rm -rf build/DTPipeline.zip
    else
      has_package_dtpipeline=1
      rm -rf build/DTPipeline.zip
      echo "DTPipeline.zip size is 0"
    fi
  else
    has_package_dtpipeline=1
    echo "build/DTPipeline.zip is not exist"
  fi
  if [ $has_package_dtpipeline -eq 1 ]; then
    pushd build/outputs
    if [ $? -ne 0 ]; then
      echo "build/outputs is not exist"
      exit 1
    fi
    zip -r ../DTPipeline.zip ./*
    popd
  fi

  echo "----------------- build all release hap --------------------"
  hvigorw --mode module -p product=default -p buildMode=release -p debuggable=false assembleHap --parallel --incremental --no-daemon --stacktrace
}

function main() {
  local start_time=$(date '+%s')

  init_npm
  init_ohpm
  build

  local end_time=$(date '+%s')
  local elapsed_time=$(expr $end_time - $start_time)
  echo "build success in ${elapsed_time}s..."
}

main
