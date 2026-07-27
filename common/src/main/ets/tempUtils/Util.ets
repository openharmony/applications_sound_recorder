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
import { CommonConstants as Const } from '../constants/CommonConstants';
import fs from '@ohos.file.fs';
import I18n from '@ohos.i18n';
import { LogUtil } from '../utils/LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { accessibility } from '@kit.AccessibilityKit';
import Settings from '@ohos.settings';
import { display, promptAction } from '@kit.ArkUI';
import { bundleManager, common, uriPermissionManager, wantConstant } from '@kit.AbilityKit';
import fileuri from '@ohos.file.fileuri';
import GlobalContext from '../utils/GlobalContext';
import { vibrator } from '@kit.SensorServiceKit';

const TAG = 'SoundRecorder_Util';
const SPECIAL_CHAR = ['\\', '/', ':', '*', '?', '<', '>', '|', '"'];
const DEFAULT_DPI_VALUE: string = 'system_default_dpi_value';
const STANDARD_DPI: number = 160;
const stringMapRestore: Map<number, string> = new Map();
const XIAOYI_BUNDLE = 'com.hmos.vassistant'
const SOUNDER_RECORD = 'com.ohos.soundrecorder';
const promptBottom = 108;
const promptBottomForPc = -108;
const defaultToastBottom = 80

export class Util {
  /**
   * 获取设备默认的densityPixel
   *
   * @returns densityPixels
   * @throws { BusinessError } 1400001 - Invalid display or screen.
   */
  // instrument ignore next
  static getDefaultDensityPixels(context: Context): number {
    let dpiValue: string = '';
    try {
      // 优先从设置中获取 DPI 值
      dpiValue = Settings.getValueSync(context, DEFAULT_DPI_VALUE, '');

      // 如果设置中没有值，则从显示设置中获取
      if (!dpiValue) {
        const displayInfo = display.getDefaultDisplaySync();
        dpiValue = displayInfo.densityDPI.toString();
      }
    } catch (error) {
      LogUtil.error(TAG + ' 获取显示设置失败: ' + error);
      throw new Error('无法获取 DPI 信息');
    }

    // 将 DPI 转换为像素密度
    const densityPixels = Number(dpiValue) / STANDARD_DPI;

    // 记录日志
    LogUtil.info(`${TAG} DPI 值: ${dpiValue}, 计算得到的像素密度: ${densityPixels}`);

    return densityPixels;
  }

  // instrument ignore next
  static getDensityPixels(): number {
    let densityPixels: number = 0;
    try {
      densityPixels = display.getDefaultDisplaySync().densityPixels;
    } catch (error) {
      LogUtil.error(TAG + ' getDensityPixels error');
    }
    return densityPixels;
  }

  // instrument ignore next
  static getDensityDPI(): number {
    let densityDPI: number = 0;
    try {
      densityDPI = display.getDefaultDisplaySync().densityDPI;
    } catch (error) {
      LogUtil.error(TAG + ' getDensityDPI error');
    }
    return densityDPI;
  }

  /**
   * Time format is converted to seconds
   *
   * @param timestamp
   * @param hasHour
   */
  // instrument ignore next
  static timeFormat(timestamp: number, hasHour: boolean = true): string {
    if (timestamp < 0) {
      return '';
    }

    const totalSeconds = Math.floor(timestamp / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    if (!hasHour && hours === 0) {
      return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
    }

    return `${hours.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}:${seconds.toString()
      .padStart(2, '0')}`;
  }

  /**
   * Time format is converted to milliseconds
   *
   * @param timestamp
   */
  // instrument ignore next
  static timeFormatMs(timestamp: number): string {
    if (timestamp <= 0) {
      return '00:00.00';
    }

    const totalSeconds = Math.floor(timestamp / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;
    const milliseconds = timestamp % 1000;

    if (hours > 0) {
      return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:${String(seconds)
        .padStart(2, '0')}`;
    } else {
      return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}.${String(Math.floor(milliseconds /
        10)).padStart(2, '0')}`;
    }
  }

  /**
   * Gets the date at the specified time
   *
   * @param date
   */
  // instrument ignore next
  static getDateFormat(date: number): string {
    if (typeof date !== 'number' || isNaN(date)) {
      return '1970/01/01';
    }
    const nowDate = new Date(date);
    const year = nowDate.getFullYear();
    const month = String(nowDate.getMonth() + 1).padStart(2, '0');
    const day = String(nowDate.getDate()).padStart(2, '0');
    return `${year}/${month}/${day}`;
  }

  /**
   * Gets the hour, minute and second of the specified time
   *
   * @param date
   */
  /* instrument ignore next */
  static getTimeFormat(date: number): string {
    if (typeof date !== 'number' || isNaN(date)) {
      return '00:00:00';
    }
    const nowDate = new Date(date);
    const hours = nowDate.getHours().toString().padStart(2, '0');
    const minutes = nowDate.getMinutes().toString().padStart(2, '0');
    const seconds = nowDate.getSeconds().toString().padStart(2, '0');
    return `${hours}:${minutes}:${seconds}`;
  }

  /**
   * Obtain a time string through a timestamp
   * @param timestamp
   * @returns Time string
   */
  static getTimeFormatFromTimestamp(timestamp: string): string {
    if (typeof timestamp !== 'string' || !/^\d+$/.test(timestamp) || timestamp.length !== 13) {
      return timestamp;
    }

    const date = new Date(Number(timestamp));
    const year = date.getFullYear().toString();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');

    return `${year}${month}${day}${hours}${minutes}${seconds}`;
  }

  /**
   * @param date
   * @returns
  * Gets the hour and minute of the specified time
   *
   * @param date
   */
  static getTimeFormat1(date: number): string {
    if (typeof date !== 'number' || isNaN(date)) {
      return '00:00';
    }
    const nowDate = new Date(date);
    const hours = nowDate.getHours().toString().padStart(2, '0');
    const minutes = nowDate.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }

  /**
   * Gets the date, the hour, minute and second of the specified time
   *
   * @param date
   */
  static toDateTimeString(date: number): string {
    const dateTime = new Date(date);
    return `${dateTime.toLocaleDateString()} ${dateTime.toLocaleTimeString()}`;
  }

  /**
   * Gets the current time date
   */
  /* instrument ignore next */
  static getDate(): string {
    const date = new Date();
    return date.toLocaleDateString('en-US', {
      year: 'numeric',
      month: '2-digit',
      day: '2-digit'
    }).replace(/\/|-/g, '');
  }

  /**
   * Gets the hour, minute and second of the current time
   */
  /* instrument ignore next */
  static getTime(): string {
    const now = new Date();
    return now.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit'
    }).replace(/:/g, '');
  }

  /**
   * If the number is less than 10, add "0".
   *
   * @param num
   */
  // instrument ignore next
  static addZero(num: number): string {
    return num.toString().padStart(2, '0');
  }

  /**
   * Convert duration to time.
   * @param duration
   * @returns time
   */
  // instrument ignore next
  static duration2Time(duration: number): string {
    const totalSeconds = Math.floor(duration / 1000);
    const hours = Math.floor(totalSeconds / 3600);
    const minutes = Math.floor((totalSeconds % 3600) / 60);
    const seconds = totalSeconds % 60;

    const format = (num: number) => num.toString().padStart(2, '0');

    if (hours === 0) {
      return `${format(minutes)}:${format(seconds)}`;
    } else {
      return `${format(hours)}:${format(minutes)}:${format(seconds)}`;
    }
  }

  /**
   * Format file size.
   * @param bytes
   * @returns string
   */
  public static formatFileSizeFlexible(bytes: number): string {
    if (bytes === 0) {
      return '0 B';
    }

    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const exponent = Math.min(Math.floor(Math.log2(bytes) / 10), units.length - 1);
    const size = bytes / (1 << (exponent * 10)); // 1 << 10 = 1024

    // 根据大小自动调整小数位数
    let formattedSize: string;
    if (size >= 10) {
      formattedSize = size.toFixed(1);
    } else if (size >= 1) {
      formattedSize = size.toFixed(2);
    } else {
      formattedSize = size.toFixed(3);
    }

    return `${formattedSize} ${units[exponent]}`;
  }

  // 将每个字符替换为Unicode码
  /* instrument ignore next */
  static encrypt(str: string): string {
    return str.split('').map(c => c.charCodeAt(0)).join(' ');
  }


  // 将Unicode码转换为字符
  /* instrument ignore next */
  static decrypt(encryptedStr: string): string {
    // 按空格分割字符串并转换为数字数组
    const encryptedChars = encryptedStr.split(' ')
      .map(char => parseInt(char, 10))
      .filter(num => !isNaN(num)); // 过滤掉无法转换的字符

    // 将数字转换为字符并拼接
    return encryptedChars
      .map(num => String.fromCharCode(num))
      .join('');
  }

  // instrument ignore next
  static changeShadowColor(resource: string, context: Context) {
    try {
      if (!context || typeof resource !== 'string') {
        return '';
      }

      // 确保颜色字符串以#开头
      let color = resource.startsWith('#') ? resource : `#${resource}`;
      // 提取颜色值部分
      let colorValue = color.substring(1);

      // 处理不同长度的颜色值
      if (colorValue.length === 6) {
        // 对于6位颜色值，直接处理
        return `#${'4d' + colorValue}`;
      } else if (colorValue.length === 8) {
        // 对于8位颜色值（带透明度），处理后6位
        return `#${'4d' + colorValue.substring(2)}`;
      }

      return '';
    } catch (error) {
      console.error('生成阴影颜色时出错:', error);
      return '';
    }
  }

  /* instrument ignore next */
  static specialCharValidator(name: string): boolean {
    let str = name.trim();
    let result: boolean = false;
    for (let key of SPECIAL_CHAR) {
      if (str.includes(key)) {
        result = true;
        break;
      }
    }
    return result;
  }

  // instrument ignore next
  static getCopyFileDir(context: Context): string {
    try {
      let isShareDieAccess = fs.accessSync(context.filesDir + '/fileShare');
      if (isShareDieAccess) {
        fs.rmdirSync(context.filesDir + '/fileShare');
      }
      fs.mkdirSync(context.filesDir + '/fileShare');
      return context.filesDir + '/fileShare';
    } catch (error) {
      LogUtil.error(`${TAG} mkdirSync code: ${(error as BusinessError).code}`);
      return '';
    }
  }

  // instrument ignore next
  static getSharePathToCopy(path: string, shareTitle: string, context: Context, isMultiShare?: boolean): string {
    let desPath: string = '';
    try {
      if (isMultiShare) {
        const dir = context.filesDir + '/fileShare';
        if (!fs.accessSync(dir)) {
          fs.mkdirSync(dir);
        }
        desPath = dir + '/' + shareTitle;
      } else {
        desPath = Util.getCopyFileDir(context) + '/' + shareTitle;
      }
      fs.copyFileSync(path, desPath);
    } catch (error) {
      LogUtil.error(`${TAG} getSharePathToCopy code: ${(error as BusinessError).code}`);
    }
    return desPath;
  }

  // instrument ignore next
  static getSharePathToCopyNoDelete(path: string, shareTitle: string, context: Context): string {
    let desPath: string = Util.getCopyFileDirNoDelete(context) + '/' + shareTitle;
    try {
      fs.copyFileSync(path, desPath);
    } catch (error) {
      LogUtil.error(`${TAG} getSharePathToCopy code: ${(error as BusinessError).code}`);
    }
    return desPath;
  }

  // instrument ignore next
  static getCopyFileDirNoDelete(context: Context): string {
    try {
      let isShareDieAccess = fs.accessSync(context.filesDir + '/fileShare');
      if (!isShareDieAccess) {
        fs.mkdirSync(context.filesDir + '/fileShare');
      }
      return context.filesDir + '/fileShare';
    } catch (error) {
      LogUtil.error(`${TAG} mkdirSync code: ${(error as BusinessError).code}`);
      return '';
    }
  }

  /**
   * 获取string资源值并格式化
   *
   * @param resource Resource资源类
   * @param subStr 格式替换子串(%s)
   */
  // instrument ignore next
  static getFormatStringSync(resource: Resource, subStr: string, concatStr?: string): string {
    let result: string | undefined;
    if (stringMapRestore.has(resource.id)) {
      result = stringMapRestore.get(resource.id);
    } else {
      result = getContext().resourceManager.getStringSync(resource);
    }
    if (!result) {
      return '';
    }
    stringMapRestore.set(resource.id, result);
    if (concatStr) {
      return result.concat(concatStr);
    } else {
      return result.replace(new RegExp('%s', 'gm'), subStr);
    }
  }

  /**
   * number类型替换
   *
   * @param subStr 格式替换子串(%d)
   */
  // instrument ignore next
  public static getNumberFormatString(resource: Resource, subStr: string): string {
    try {
      const result = getContext().resourceManager.getStringSync(resource);
      if (!result) {
        return '';
      }
      const regex = new RegExp('%d', 'g');
      return result.replace(regex, subStr);
    } catch (error) {
      console.error('Error in getNumberFormatString:', error);
      return '';
    }
  }

  /**
   * 同步方式任意数量string类型替换
   *
   * @param resource Resource资源类
   * @param ...params 任意数量替换子串
   */
  // instrument ignore next
  public static getAnyStrFormatStringSync(resource: Resource, ...params: Array<string>): string {
    let result = getContext().resourceManager.getStringSync(resource);
    // instrument ignore if
    if (!result) {
      return '';
    }
    for (let i = 0; i < params.length; i++) {
      result = result.replace(new RegExp('%' + (i + 1) + '\\$s', 'gm'), params[i]);
    }
    return result;
  }

  // instrument ignore next
  static async getSharePathUri(originPath: string): Promise<string> {
    let sharePath = getContext().distributedFilesDir + '/' + originPath.substring(originPath.lastIndexOf('/') + 1);
    try {
      if (!fs.accessSync(originPath)) {
        fs.openSync(originPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      }
      await fs.copyFile(originPath, sharePath);
      return fileuri.getUriFromPath(sharePath);
    } catch (e) {
      LogUtil.info(TAG + ` getSharePathUri error ` + e);
      return '';
    }
  }

  /* instrument ignore next */
  static async grandTranPermission(originPath: string): Promise<string> {
    try {
      let uri = await Util.getSharePathUri(originPath);
      if (uri.indexOf('*') > -1) {
        // 不支持授权到带*的路径，其一是文件名不支持带*，其二是授权到*可能会导致权限放大
        LogUtil.info(`${TAG} grantUriPermission fail, can not grant file has *`);
        return '';
      }
      await uriPermissionManager.grantUriPermission(uri,
        wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION |
        wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION |
        wantConstant.Flags.FLAG_AUTH_PERSISTABLE_URI_PERMISSION,
        XIAOYI_BUNDLE);
      await uriPermissionManager.grantUriPermission(uri,
        wantConstant.Flags.FLAG_AUTH_READ_URI_PERMISSION |
        wantConstant.Flags.FLAG_AUTH_WRITE_URI_PERMISSION |
        wantConstant.Flags.FLAG_AUTH_PERSISTABLE_URI_PERMISSION, SOUNDER_RECORD)
      return uri;
    } catch (e) {
      LogUtil.info(TAG + ` grandTranPermission error ` + e);
      return '';
    }
  }

  /**
   * 判断当前某个应用服务是否可用状态
   *
   * @return true 可用状态；false 停用状态
   */
  /* instrument ignore next */
  static isBundleServiceEnable(bundleName: string): boolean {
    try {
      return bundleManager.isApplicationEnabledSync(bundleName);
    } catch (err) {
      return false;
    }
  }

  // instrument ignore next
  static startVibration(): void {
    vibrator.isSupportEffect('haptic.long_press.medium').then(val => {
      const params: vibrator.VibrateEffect = val ? {
        type: 'preset',
        effectId: 'haptic.long_press.medium',
        count: 1
      } : {
        type: 'time',
        duration: 50,
      }
      try {
        vibrator.startVibration(params, {
          id: 0,
          usage: 'touch'
        }, (error: BusinessError) => {
          if (error) {
            LogUtil.error(TAG + `Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
            return;
          }
          LogUtil.info(TAG + 'Succeed in starting vibration.');
        });
      } catch (err) {
        LogUtil.error(TAG + `touchVibrate error, code: ${err.code}, message: ${err.message}`);
      }
    }).catch((err: BusinessError) => {
      LogUtil.error(TAG + ` vibrate error, code: ${err.code}, message: ${err.message}`);
    })
  }

  // instrument ignore next
  static showToast(resource: Resource | string, isPC: boolean = false, inBackground: boolean = false) {
    try {
      if (isPC) {
        promptAction.showToast({
          message: resource,
          showMode: inBackground ? promptAction.ToastShowMode.TOP_MOST : promptAction.ToastShowMode.DEFAULT,
          alignment: Alignment.Bottom,
          offset: { dx: 0, dy: promptBottomForPc }
        })
      } else {
        promptAction.showToast({
          message: resource,
          bottom: inBackground ? defaultToastBottom : promptBottom,
          showMode: inBackground ? promptAction.ToastShowMode.TOP_MOST : promptAction.ToastShowMode.DEFAULT,
        })
      }
    } catch (error) {
      LogUtil.error(`${TAG} code: ${error.code}, message: ${error.message}`);
    }
  }

  /**
   * 设置定时器
   *
   * @param callback 回调处理
   * @param delay 延时时间
   * @param 定时器Id
   */
  /* instrument ignore next */
  public static delayExecute(callback: () => void, delay: number): number {
    let timeoutId: number = setTimeout(() => {
      callback();
      clearTimeout(timeoutId);
    }, delay);
    return timeoutId;
  }
}

interface IDurationCachedTmplMap {
  hour: string;
  hours: string;
  minute: string;
  minutes: string;
  second: string;
  seconds: string;
}

// 无障碍事件上报接口
export class AccessibilityUtil {
  /**
   * 主动聚焦
   * @param elementId： 要聚焦的组件id
   */
  /* instrument ignore next */
  static sendFocusAccessibilityEvent(elementId: string): void {
    let eventInfo: accessibility.EventInfo = {
      type: 'requestFocusForAccessibility',
      bundleName: 'com.ohos.soundrecorder',
      triggerAction: 'common',
      customId: elementId,
    };
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
      LogUtil.info(`Succeeded in send event`);
    }).catch((err: BusinessError) => {
      LogUtil.error(`Failed to send event, errcode: ${err.code}, errMsg: ${err.message}`);
    });
  }

  /**
   * 主动播报
   * @param content： 要播报的内容
   */
  static sendAnnounceAccessibilityEvent(content: string): void {
    let eventInfo: accessibility.EventInfo = {
      type: 'announceForAccessibility',
      bundleName: 'com.ohos.soundrecorder',
      triggerAction: 'common',
      textAnnouncedForAccessibility: content,
    };
    accessibility.sendAccessibilityEvent(eventInfo).then(() => {
      LogUtil.info(`Succeeded in send event`);
    }).catch((err: BusinessError) => {
      LogUtil.error(`Failed to send event, errcode: ${err.code}, errMsg: ${err.message}`);
    });
  }

  /**
   * 系统是否开启触摸浏览模式
   */
  static isOpenTouchGuide(): boolean {
    let isOpenTouchGuideSync: boolean = accessibility.isOpenTouchGuideSync();
    LogUtil.info(`${TAG} check isOpenTouchGuideSync status: ${isOpenTouchGuideSync}`);
    return isOpenTouchGuideSync;
  }

  /**
   * 当录音标记的列表发生刷新时，播报列表的内容
   * @param markCount： 当前标记列表的大小
   */
  // instrument ignore next
  static getMarkListBroadCastContent(markCount: number, minCount: number, maxCount: number): string {
    LogUtil.info(`${TAG} update mark list, current mark count: ${markCount}`);
    let context = GlobalContext.getUIAbilityContext();
    let broadcastContent: string = context.resourceManager.getStringSync($r('app.string.mark_added_talkback'));
    let markText: string = ' ' + context.resourceManager.getStringSync($r('app.string.mark'));
    broadcastContent += context.resourceManager.getStringSync($r('app.string.serial_number'),
      maxCount > 9 ? maxCount.toString() + markText : '0' + maxCount + markText);
    return broadcastContent;
  }

  /**
   * 无障碍模式下的时分秒Text
   * @param duration
   * @returns
   */
  // instrument ignore next
  private static preLang: string = I18n.System.getSystemLanguage();
  private static durationCachedTmpl: IDurationCachedTmplMap;
  private static updateDurationCachedTmpl() {
    const currLang = I18n.System.getSystemLanguage();
    let context = GlobalContext.getUIAbilityContext();
    if (!AccessibilityUtil.durationCachedTmpl || (currLang !== AccessibilityUtil.preLang)) {
      AccessibilityUtil.durationCachedTmpl = {
        hour: context?.resourceManager.getPluralStringValueSync($r('app.plural.hour_plural').id, 1),
        hours: context?.resourceManager.getPluralStringValueSync($r('app.plural.hour_plural').id, 2),
        minute: context?.resourceManager.getPluralStringValueSync($r('app.plural.minute_plural').id, 1),
        minutes: context?.resourceManager.getPluralStringValueSync($r('app.plural.minute_plural').id, 2),
        second: context?.resourceManager.getPluralStringValueSync($r('app.plural.second_plural').id, 1),
        seconds: context?.resourceManager.getPluralStringValueSync($r('app.plural.second_plural').id, 2),
      }
    }
    AccessibilityUtil.preLang = currLang;
  }

  // instrument ignore next
  static getDurationText(duration: number): string {
    try {
      AccessibilityUtil.updateDurationCachedTmpl();
      const tmpl = AccessibilityUtil.durationCachedTmpl;
      const list = Util.timeFormat(duration || 0).split(Const.STRING_COLON).map(it => Number(it));
      const hour = list[0];
      const minute = list[1];
      const second = list[2];
      const hourStr = hour > 1 ? tmpl.hours.replace('2', `${hour}`) : tmpl.hour.replace('1', `${hour}`);
      const minuteStr = minute > 1 ? tmpl.minutes.replace('2', `${minute}`) : tmpl.minute.replace('1', `${minute}`);
      const secondStr = second > 1 ? tmpl.seconds.replace('2', `${second}`) : tmpl.second.replace('1', `${second}`);
      return `${hourStr}${minuteStr}${secondStr}`.replace(/\s+/g, '');
    } catch (e) {
      LogUtil.error(`${TAG} getDurationText error: ${(e as BusinessError).message}`);
      return '';
    }
  }

  /**
   * 无障碍模式下获取录音机总时长Text
   * @param duration
   * @returns
   */
  static getTotalDurationText(duration: number): string {
    return Util.getFormatStringSync($r('app.string.total_duration'), AccessibilityUtil.getDurationText(duration))
      .replace(/\s+/g, '');
  }
}
