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
import { LogUtil } from './LogUtil';
import { BusinessError } from '@kit.BasicServicesKit';
import { accessibility } from '@kit.AccessibilityKit';
import Settings from '@ohos.settings';
import { display, promptAction } from '@kit.ArkUI';
import { bundleManager, common, uriPermissionManager, wantConstant } from '@kit.AbilityKit';
import fileuri from '@ohos.file.fileuri';
import GlobalContext from './GlobalContext';
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
   */
  // instrument ignore next
  static getDefaultDensityPixels(context: Context): number {
    let defaultDensityDPI: string = Settings.getValueSync(context, DEFAULT_DPI_VALUE, '');
    try {
      if (!defaultDensityDPI) {
        defaultDensityDPI = display.getDefaultDisplaySync().densityDPI.toString();
      }
    } catch (error) {
      LogUtil.error(TAG + ' getDefaultDisplaySync failed: ' + error);
    }
    let defaultDensityPixels: number = Number(defaultDensityDPI) / STANDARD_DPI;
    LogUtil.info(`${TAG} get defaultDensityDPI: ${defaultDensityDPI}, defaultDensityPixels: ${defaultDensityPixels}`);
    return defaultDensityPixels;
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
    let timeStr = '';
    let hour = Math.floor(timestamp / (60 * 60 * 1000));
    if (hasHour || hour > 0) {
      timeStr += Util.addZero(hour) + ':';
    }
    let min = Math.floor(timestamp % (60 * 60 * 1000) / (60 * 1000));
    timeStr += Util.addZero(min) + ':';
    let sec = Math.floor(timestamp % (60 * 1000) / 1000);
    timeStr += Util.addZero(sec);
    return timeStr;
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
    let timeStr = '';
    let hour = Math.floor(timestamp / (60 * 60 * 1000));
    if (hour > 0) {
      timeStr += Util.addZero(hour) + ':';
    }
    let min = Math.floor(timestamp % (60 * 60 * 1000) / (60 * 1000));
    timeStr += Util.addZero(min) + ':';
    let sec = Math.floor(timestamp % (60 * 1000) / 1000);
    timeStr += Util.addZero(sec);
    if (hour < 1) {
      let mSec = Math.floor(timestamp % 1000 / 10);
      timeStr += '.' + Util.addZero(mSec);
    }
    return timeStr;
  }

  /**
   * Gets the date at the specified time
   *
   * @param date
   */
  // instrument ignore next
  static getDateFormat(date: number): string {
    let nowDate = new Date(date);
    return nowDate.getFullYear() + '/' + Util.addZero(nowDate.getMonth() + 1) + '/' + Util.addZero(nowDate.getDate());
  }

  /**
   * Gets the hour, minute and second of the specified time
   *
   * @param date
   */
  /* instrument ignore next */
  static getTimeFormat(date: number): string {
    let nowDate = new Date(date);
    return Util.addZero(nowDate.getHours()) + ':' + Util.addZero(nowDate.getMinutes()) + ':' + Util.addZero(nowDate.getSeconds());
  }

  /**
   * Obtain a time string through a timestamp
   * @param timestamp
   * @returns Time string
   */
  static getTimeFormatFromTimestamp(timestamp: string): string {
    if (timestamp.length !== 13) {
      return timestamp;
    }
    let nowDate = new Date(Number(timestamp));
    return nowDate.getFullYear() + Util.addZero(nowDate.getMonth() + 1) + Util.addZero(nowDate.getDate()) +
      Util.addZero(nowDate.getHours()) + Util.addZero(nowDate.getMinutes()) + Util.addZero(nowDate.getSeconds());
  }

  /**
   * @param date
   * @returns
   * Gets the hour and minute of the specified time
   *
   * @param date
   */
  static getTimeFormat1(date: number): string {
    let nowDate = new Date(date);
    return Util.addZero(nowDate.getHours()) + ':' + Util.addZero(nowDate.getMinutes());
  }

  /**
   * Gets the date, the hour, minute and second of the specified time
   *
   * @param date
   */
  static getDateAndTimeFormat(date: number): string {
    return Util.getDateFormat(date) + ' ' + Util.getTimeFormat1(date);
  }

  /**
   * Gets the current time date
   */
  /* instrument ignore next */
  static getDate(): string {
    let nowDate = new Date();
    return nowDate.getFullYear() + Util.addZero(nowDate.getMonth() + 1) + Util.addZero(nowDate.getDate());
  }

  /**
   * Gets the hour, minute and second of the current time
   */
  /* instrument ignore next */
  static getTime(): string {
    let nowDate = new Date();
    return Util.addZero(nowDate.getHours()) + Util.addZero(nowDate.getMinutes()) + Util.addZero(nowDate.getSeconds());
  }

  /**
   * If the number is less than 10, add "0".
   *
   * @param num
   */
  // instrument ignore next
  static addZero(num: number): string {
    return num < 10 ? '0' + num : '' + num;
  }

  /**
   * Convert duration to time.
   * @param duration
   * @returns time
   */
  // instrument ignore next
  static duration2Time(duration: number): string {
    let temp = Math.floor(duration / Const.TIME_1000);
    let second = temp % Const.TIME_60 < Const.TIME_10
      ? Const.STRING_0 + temp % Const.TIME_60 : (temp % Const.TIME_60).toString();
    let minute = (Math.floor(temp / Const.TIME_60) % Const.TIME_60 < Const.TIME_10
      ? Const.STRING_0 + Math.floor(temp / Const.TIME_60) % Const.TIME_60
      : (Math.floor(temp / Const.TIME_60) % Const.TIME_60).toString()) + Const.STRING_COLON;
    let hour = (Math.floor(temp / Const.TIME_60 / Const.TIME_60) < Const.TIME_10
      ? Const.STRING_0 + Math.floor(temp / Const.TIME_60 / Const.TIME_60)
      : (Math.floor(temp / Const.TIME_60 / Const.TIME_60)).toString()) + Const.STRING_COLON;
    return hour + minute + second;
  }

  /**
   * Format file size.
   * @param bytes
   * @returns string
   */
  public static formatFileSizeFlexible(bytes: number): string {
    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];
    const index = Math.floor(Math.log(bytes) / Math.log(1024));
    const size = bytes / Math.pow(1024, index);
    return `${size.toFixed(2)} ${units[index]}`;
  }

  // 将每个字符替换为Unicode码
  /* instrument ignore next */
  static encrypt(str: string): string {
    let encryptedStr = '';
    for (let i = 0; i < str.length; i++) {
      encryptedStr += str.charCodeAt(i) + ' ';
    }
    return encryptedStr.trim();
  }


  // 将Unicode码转换为字符
  /* instrument ignore next */
  static decrypt(encryptedStr: string): string {
    const encryptedChars = encryptedStr.split(' ');
    let decryptedStr = '';
    for (let i = 0; i < encryptedChars.length; i++) {
      const num = Number(encryptedChars[i])
      decryptedStr += String.fromCharCode(num);
    }
    return decryptedStr;
  }

  // instrument ignore next
  static changeShadowColor(resource: string, context: Context) {
    if (context) {
      let backgroundColor: string = resource;
      let colorSize = 6;
      let shadowColor = '#' + '4d' + backgroundColor.substring(backgroundColor.length - colorSize);
      return shadowColor;
    }
    return '';
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
    let result = getContext().resourceManager.getStringSync(resource);
    if (!result) {
      return '';
    }
    return result.replace(new RegExp('%d', 'gm'), subStr);
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

  /**
   * 判断是否是历史脏数据
   * 名称_13位时间戳的形式，这种属于通话录音文件名称异常显示名称
   * @param name
   * @returns
   */
  static isHistoricalDirtyData(name: string): boolean {
    // 部分数据存在的是： 名称_13位时间戳的形式，这种属于通话录音文件名称异常显示名称
    if (/^[^/:*？'<>|]+_\d{13}$/.test(name)) {
      return true;
    }
    return false;
  }

  /**
   * 日期格式化
   * @param date {Date} 日期
   * @param format {string} 格式
   * @returns 日期格式化后的string字符串
   */
  // instrument ignore next
  static dateFormat(date: Date, format = 'YYYYMMdd_HHmmss'): string {
    const opt: Record<string, string> = {
      '[Y|y]+': date.getFullYear().toString(),
      'M+': (date.getMonth() + 1).toString(),
      'd+': date.getDate().toString(),
      'H+': date.getHours().toString(),
      'h+': (date.getHours() >= 12 ? date.getHours() - 12 : date.getHours()).toString(),
      'm+': date.getMinutes().toString(),
      's+': date.getSeconds().toString(),
      'q+': Math.floor((date.getMonth() + 3) / 3).toString(),
      'S+': date.getMilliseconds().toString()
    };
    Object.keys(opt).forEach((key: string) => {
      // match()方法检索正则表达式的匹配，如果没有找到任何匹配的文本，返回null，否则返回数组
      let matchRes = format.match(new RegExp(key, 'g'));
      // 如果匹配成功，则将匹配项依次替换
      matchRes && matchRes.forEach(matchedItem => {
        format = format.replace(matchedItem, opt[key].padStart(matchedItem.length, '0'));
      });
    })
    return format;
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
