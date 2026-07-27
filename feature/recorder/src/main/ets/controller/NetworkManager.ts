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
import connection from '@ohos.net.connection';
import type { BusinessError, AsyncCallback } from '@ohos.base';
import { LogUtil } from '@ohos/common/src/main/ets/utils/LogUtil';

const TAG = 'NetworkManager ';
const UN_CONNECT = 0;

/**
 * 网络管理类
 *
 * @since 2025-08-30
 */
export class NetworkManager {
  private static instance: NetworkManager;

  private isNetworkConnect: boolean = false;

  private connection: connection.NetConnection = connection.createNetConnection();

  private callback: AsyncCallback<void> = (error: BusinessError) => {
    LogUtil.info(TAG + `register or unRegister is error:${JSON.stringify(error)}`);
  };

  private connectCallbackList: NetworkCallback[] = [];

  private constructor() {
  }

  /* instrument ignore next */
  public static getInstance(): NetworkManager {
    if (!NetworkManager.instance) {
      NetworkManager.instance = new NetworkManager();
    }
    return NetworkManager.instance;
  }

  /**
   * 网络是否连接
   *
   * @returns true表示连接，false表示未连接
   */
  /* instrument ignore next */
  public isConnect(): boolean {
    try {
      const netHandle = connection.getDefaultNetSync();
      this.isNetworkConnect = netHandle.netId !== UN_CONNECT;
    } catch (error) {
      this.isNetworkConnect = false;
    }
    LogUtil.info(TAG + ` isConnect: ${this.isNetworkConnect}`);
    return this.isNetworkConnect;
  }

  /**
   * 注册网络状态监听
   */
  /* instrument ignore next */
  public registerNetworkConnect(): void {
    LogUtil.info(TAG + ` registerNetworkConnect`);
    this.connection.register(this.callback);
    this.connection.on('netAvailable', (data: connection.NetHandle) => {
      LogUtil.info(TAG + 'true');
      this.isNetworkConnect = true;
      this.handleConnectCallback();
    });
    this.connection.on('netLost', () => {
      LogUtil.info(TAG + 'netLost');
      this.isNetworkConnect = false;
      this.handleConnectCallback();
    });
    this.connection.on('netUnavailable', () => {
      LogUtil.info(TAG + 'netUnavailable');
      this.isNetworkConnect = false;
      this.handleConnectCallback();
    });
  }

  private handleConnectCallback(): void {
    for (let index = 0; index < this.connectCallbackList.length; index++) {
      this.connectCallbackList[index].onConnectChange(this.isNetworkConnect);
    }
  }

  /**
   * 注销网络状态监听
   */
  /* instrument ignore next */
  public unRegisterNetworkConnect(): void {
    this.connection.unregister(this.callback);
  }

  /**
   * 添加回调
   *
   * @param callback 回调
   */
  /* instrument ignore next */
  public addNetworkCallback(callback: NetworkCallback): void {
    const index = this.connectCallbackList.indexOf(callback);
    if (index < 0) {
      this.connectCallbackList.push(callback);
    }
  }

  /**
   * 移除回调
   *
   * @param callback 回调
   */
  /* instrument ignore next */
  public removeNetworkCallback(callback: NetworkCallback): void {
    const index = this.connectCallbackList.indexOf(callback);
    if (index >= 0) {
      this.connectCallbackList.splice(index, 1);
    }
  }

  /**
   * 清空回调
   *
   * @param callback 回调
   */
  /* instrument ignore next */
  public clearNetworkCallback(): void {
    this.connectCallbackList = [];
  }
}

/**
 * 网络连接
 */
export interface NetworkCallback {
  onConnectChange: (isConnect: boolean) => void;
}