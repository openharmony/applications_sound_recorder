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

import { window } from '@kit.ArkUI';
import { LogUtil } from './LogUtil';

const TAG = 'SoundRecorder_WindowUtil';

export class WindowUtil {
  /**
   * 预设沉浸式
   * @param window stage
   */
  /* instrument ignore next */
  public static presetImmersive(stage: window.WindowStage) {
    try {
      if (canIUse('SystemCapability.Window.SessionManager')) {
        const win = stage.getMainWindowSync();
        // 设置隐藏标题栏，只显示右上角三键
        win.setWindowDecorVisible(false);
        // 设置标题栏(右上角三键)高度
        win.setWindowDecorHeight(64);
        // 设置三键按钮背板样式
        win.setDecorButtonStyle({ buttonBackgroundSize: 40 });
        // 获取窗口激活态信息
        win.on('windowHighlightChange', (data: boolean) => {
          LogUtil.info(`${TAG} Window highlight Change: ${data}`);
          AppStorage.setOrCreate('windowFocused', data);
        });
        LogUtil.info(`${TAG} preset immersive success.`);
      }
    } catch (err) {
      LogUtil.error(`${TAG} failed to preset immersive, code: ${err.code}, message: ${err.message}`);
    }
  }

  /**
   * 窗口是否处于悬浮窗状态
   */
  public static isFloating(): boolean {
    try {
      if (canIUse('SystemCapability.Window.SessionManager')) {
        const win = AppStorage.get<window.Window>('mainWindow');
        return win?.getWindowStatus() === window.WindowStatusType.FLOATING;
      }
    } catch (err) {
      LogUtil.error(`${TAG} failed to get window status, code: ${err.code}, message: ${err.message}`);
    }
    return false;
  }
}