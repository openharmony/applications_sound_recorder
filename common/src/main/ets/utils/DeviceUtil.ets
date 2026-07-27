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

import deviceInfo from '@ohos.deviceInfo';
import { display } from '@kit.ArkUI';
import { LogUtil } from './LogUtil';
import { DeviceType } from '../enums/DeviceType';
import window from '@ohos.window';
import systemParameterEnhance from '@ohos.systemParameterEnhance';
import systemParameter from '@ohos.systemParameterEnhance';
import { CommonConstants } from '../constants/CommonConstants';

const TAG: string = 'SoundRecorder_DeviceUtil';
const FOLD_PRODUCT_TYPE = 'const.window.foldscreen.type';
const DEFAULTS_FOLD_TYPE = '0,0,0,0';
const SMALL_FOLD_SCREEN_LEM_START_VALUE: string = '2,';

export class DeviceUtil {
  private static isLemSmallFold: boolean | undefined = undefined;
  private static foldScreenProperty: string | undefined = undefined;

  /**
   * 获取设备类型
   * @returns
   */
  public static getDeviceType(): string {
    return deviceInfo.deviceType;
  }

  /**
   * 获取设备折叠状态
   * @returns
   */
  public static getFoldStatus(): display.FoldStatus {
    let foldStatus: display.FoldStatus = display.FoldStatus.FOLD_STATUS_UNKNOWN;
    try {
      foldStatus = display.getFoldStatus();
    } catch (error) {
      LogUtil.error(TAG + ' getFoldStatus failed');
    }
    return foldStatus;
  }

  /**
   * 是否手机
   * @returns
   */
  public static isPhone(): boolean {
    return DeviceUtil.getDeviceType() === DeviceType.PHONE;
  }

  /**
   * 是否PC
   * @returns
   */
  public static isPC(): boolean {
    return DeviceUtil.getDeviceType() === DeviceType.PC;
  }

  /**
   * 是否PAD或三折叠完全展开态（三块屏全亮）
   * @returns
   */
  public static isTabletOrTripleGStatus(): boolean {
    return DeviceUtil.getDeviceType() === DeviceType.TABLET || DeviceUtil.isTripleFoldGStatus();
  }

  /**
   * 是否PAD
   * @returns
   */
  public static isTablet(): boolean {
    return DeviceUtil.getDeviceType() === DeviceType.TABLET;
  }

  /**
   * 是否小折叠新产品VXXX
   * @returns
   */
  public static isSmallFoldVer(): boolean {
    try {
      let productValue: string = systemParameterEnhance.getSync(FOLD_PRODUCT_TYPE, DEFAULTS_FOLD_TYPE);
      let result: string[] = productValue?.split(',');
      if (result.length > 0) {
        return Number.parseInt(result[0]) === 4;
      } else {
        return false;
      }
    } catch (error) {
      LogUtil.error(TAG + ` getSync error, code: ${error?.code}, message: ${error?.message}`);
      return false;
    }
  }

  /**
   * 判断当前设备是否是小折叠屏手机Lem
   *
   * @returns true:是小折叠Lem设备, false:非小折叠Lem设备
   */
  public static isSmallFoldLem(): boolean {
    if (DeviceUtil.isLemSmallFold !== undefined) {
      return DeviceUtil.isLemSmallFold;
    }
    let productProperty: string = DeviceUtil.getFoldScreenProperty();
    DeviceUtil.isLemSmallFold = productProperty.startsWith(SMALL_FOLD_SCREEN_LEM_START_VALUE);
    return DeviceUtil.isLemSmallFold;
  }

  /**
   * 获取产品属性const.window.foldscreen.type
   *
   * @returns 属性值
   */
  public static getFoldScreenProperty(): string {
    if (DeviceUtil.foldScreenProperty !== undefined) {
      return DeviceUtil.foldScreenProperty;
    }
    let property: string = '';
    try {
      property = systemParameter.getSync(FOLD_PRODUCT_TYPE);
    } catch (error) {
      LogUtil.error(TAG + `getFoldScreenProperty error: ${error}`);
    }
    DeviceUtil.foldScreenProperty = property;
    return property;
  }

  /**
   * 是否横屏
   * @returns
   */
  public static isLandscape(): boolean {
    try {
      const rotation = display.getDefaultDisplaySync()?.orientation;
      // 车机适配
      if (rotation === undefined) {
        let width = AppStorage.get('windowWidthOri') as number;
        let height = AppStorage.get('windowHeight') as number;
        if ( width > height) {
          return true;
        }
      }
      return rotation === display.Orientation.LANDSCAPE || rotation === display.Orientation.LANDSCAPE_INVERTED;
    } catch (error) {
      LogUtil.error(TAG + ' isLandscape getDefaultDisplaySync meet error');
      return false;
    }
  }

  /**
   * 是否界面布局有分栏
   * @returns
   */
  public static async isSplitStatus(): Promise<boolean> {
    try {
      const windowInfos: window.WindowInfo[] = await window.getVisibleWindowInfo();
      return windowInfos.some(item => item?.windowStatusType === window.WindowStatusType.SPLIT_SCREEN);
    } catch (err) {
      LogUtil.error(`${TAG} failed to get visible window info, code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }

  /**
   * @deprecated 即将废弃，字面量语义不规范，场景覆盖不合理
   * @returns
   */
  public static isPhoneNotFold(): boolean {
    if (DeviceUtil.isSmallFoldLem()) {
      return true;
    }
    if (DeviceUtil.isTripleFoldFStatus()) {
      return true;
    }
    if (DeviceUtil.isTripleFoldGStatus() || DeviceUtil.isTripleFoldMStatus()) {
      return false;
    }
    const currentFoldStatus = DeviceUtil.getFoldStatus();
    return DeviceUtil.isPhone() &&
      currentFoldStatus !== display.FoldStatus.FOLD_STATUS_EXPANDED &&
      currentFoldStatus !== display.FoldStatus.FOLD_STATUS_HALF_FOLDED;
  }

  /**
   * 是否展开
   * @returns
   */
  public static isExpanded(): boolean {
    if (DeviceUtil.isSmallFoldLem()) {
      return false;
    }
    const currentFoldStatus = DeviceUtil.getFoldStatus();
    return DeviceUtil.isPhone() && (currentFoldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED ||
      DeviceUtil.isTripleFoldMStatus() || DeviceUtil.isTripleFoldGStatus());
  }

  /**
   * 是否折叠
   * @returns
   */
  public static isFolded(): boolean {
    const currentFoldStatus = DeviceUtil.getFoldStatus();
    return DeviceUtil.isPhone() && (currentFoldStatus === display.FoldStatus.FOLD_STATUS_FOLDED ||
      DeviceUtil.isTripleFoldFStatus());
  }

  /**
   * 判断当前设备是否是三折叠
   *
   * @returns true:是三折叠设备
   */
  public static isTripleFold(): boolean {
    return AppStorage.get(CommonConstants.IS_TRIPLE_FOLD_DEVICE) as boolean;
  }

  /**
   * 是否是GRL的G态 三屏
   * @returns
   */
  public static isTripleFoldGStatus(): boolean {
    let isTripleFold = AppStorage.get(CommonConstants.IS_TRIPLE_FOLD_DEVICE) as boolean;
    const currentFoldStatus = DeviceUtil.getFoldStatus();
    return isTripleFold && (currentFoldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_EXPANDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_EXPANDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED_WITH_SECOND_HALF_FOLDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED_WITH_SECOND_HALF_FOLDED);
  }

  /**
   * 是否是GRL的M态 两屏
   * @returns
   */
  public static isTripleFoldMStatus(): boolean {
    let isTripleFold = AppStorage.get(CommonConstants.IS_TRIPLE_FOLD_DEVICE) as boolean;
    const currentFoldStatus = DeviceUtil.getFoldStatus();
    return isTripleFold && (currentFoldStatus === display.FoldStatus.FOLD_STATUS_EXPANDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_HALF_FOLDED);
  }

  /**
   * 是否是GRL的F态 一屏
   * @returns
   */
  public static isTripleFoldFStatus(): boolean {
    let isTripleFold = AppStorage.get(CommonConstants.IS_TRIPLE_FOLD_DEVICE) as boolean;
    const currentFoldStatus = DeviceUtil.getFoldStatus();
    return isTripleFold && (currentFoldStatus === display.FoldStatus.FOLD_STATUS_FOLDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_EXPANDED ||
      currentFoldStatus === display.FoldStatus.FOLD_STATUS_FOLDED_WITH_SECOND_HALF_FOLDED);
  }

  /**
   * 是否直板机
   * @returns
   */
  public static isBarPhone(): boolean {
    try {
      return DeviceUtil.isPhone() && !display.isFoldable();
    } catch (err) {
      LogUtil.error(`${TAG} failed to get isBarPhone, code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }
}