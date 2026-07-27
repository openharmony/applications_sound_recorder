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
import {
  AnonymousUtil,
  AuditLogManager,
  CommonConstants,
  ConfigData,
  ContinuousTask,
  DatabaseManager,
  DeviceUtil,
  DFXEnumConstants,
  FileUtil,
  GlobalContext,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  NotificationConstants,
  NotificationManagerUtil,
  PathUtil,
  Props,
  Util
} from '@ohos/common';
import RecordingData from '@ohos/common/src/main/ets/model/RecordingData';
import { LayoutData } from '@ohos/common/src/main/ets/model/LayoutData';
import { PreferencesUtil } from '@ohos/common/src/main/ets/utils/PreferencesUtil';
import MediaController from '../controller/MediaController';
import { abilityAccessCtrl, common, Context } from '@kit.AbilityKit';
import { geoLocationManager } from '@kit.LocationKit';
import { BusinessError, screenLock } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { RecordManager } from '../controller/RecordManager';
import { MarkDataGroup, RecordData, RecordDataGroupArray } from '@ohos/common/src/main/ets/model/RecordData';
import { audio } from '@kit.AudioKit';
import { AccessibilityUtil } from '@ohos/common/src/main/ets/utils/Util';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import SortType, { SortConstants } from '@ohos/common/src/main/ets/constants/DataSortType';
import { i18n, intl } from '@kit.LocalizationKit';
import Settings from '@ohos.settings';
import { notificationManager } from '@kit.NotificationKit';
import { FileManager } from '@ohos/fileManager';
import { TransferData } from '@ohos/common/src/main/ets/model/TransferData';
import fileUri from '@ohos.file.fileuri';
import util from '@ohos.util';
import AudioSDKManager from '../audiokit/manager/AudioSDKManager';
import RecordStateManager from '../audiokit/manager/RecordStateManager';
import { GlobalRecordState } from '../audiokit/constant/AudioConstant';
import { media } from '@kit.MediaKit';

const TAG = 'SoundRecorder_BaseViewModel';

export class BaseViewModel {
  private static baseViewModel: BaseViewModel;
  /**
   * 页面布局实体
   */
  public layoutData: LayoutData;
  public recordingData: RecordingData;
  private defaultRingMode: number = -1;
  //录音2G规则检测周期
  private recorderProcessCheckTime: number = CommonConstants.TIME_600000;
  //录音2G规则检测次数
  private recorderProcessCheckTimeNumber: number = 0;
  private recorderProcessCheckTimer: number = -1;
  private markList: MarkDataGroup;
  private recordDataGroupList: RecordDataGroupArray = new RecordDataGroupArray();
  private markListSubscribers: Array<(tag: string, markList: MarkDataGroup) => void> = [];
  private sortType: string = SortType.SORT_TIME_DESC;
  private context: common.UIAbilityContext | Context = GlobalContext.getUIAbilityContext();
  private recordCompare: intl.Collator = new intl.Collator(i18n.System.getSystemLocale(), {
    sensitivity: 'case',
    numeric: false,
    caseFirst: 'lower',
    usage: 'sort',
    collation: 'dict',
    ignorePunctuation: false
  });
  private isShutdown = false;

  constructor() {
    LogUtil.info(TAG + ` constructor`);
    this.recordingData = new RecordingData();
    this.context = GlobalContext.getUIAbilityContext() ?? GlobalContext.getServiceAbilityContext();
    this.context.eventHub.on('isShutdown', this.shutdownCallback);
    this.layoutData = new LayoutData();
    this.markList = new MarkDataGroup();
  }

  private shutdownCallback = (isShutdown: boolean) => {
    this.isShutdown = isShutdown;
  }

  /**
   * 获取ViewModel单例。
   *
   * @return ViewModel 单例
   */
  public static getInstance(): BaseViewModel {
    if (!BaseViewModel.baseViewModel) {
      BaseViewModel.baseViewModel = new BaseViewModel();
    }

    return BaseViewModel.baseViewModel;
  }

  /**
   * 从缓存中获取宽度进行初始化。
   *
   */
  /* instrument ignore next */
  public async initSideNavBar() {
    let sideBarWidth = await PreferencesUtil.get(CommonConstants.WIN_SIDE_BAR_WIDTH, 0) as number;
    let navBarWidth = await PreferencesUtil.get(CommonConstants.WIN_NAV_BAR_WIDTH, 0) as number;
    this.layoutData.setSpSideBarWidth(sideBarWidth);
    this.layoutData.setSpNavBarWidth(navBarWidth);
  }

  /**
   * 获取页面布局实体对象
   *
   * @returns 页面布局实体对象
   */
  /* instrument ignore next */
  public getLayoutData(): LayoutData {
    return this.layoutData;
  }

  /**
   * 获取正在录音的数据对象
   *
   * @returns 页面布局实体对象
   */
  public getRecordingData(): RecordingData {
    return this.recordingData;
  }

  /**
   * 设置正在录音的数据对象
   *
   * @returns 页面布局实体对象
   */
  /* instrument ignore next */
  public setRecordingData(recordingData: RecordingData): void {
    this.recordingData = recordingData;
  }

  /* instrument ignore next */
  setTransIncomplete(incomplete: boolean) {
    this.recordingData.setIncomplete(incomplete);
  }

  /**
   * 开始录音
   *
   * @returns 页面布局实体对象
   */
  public async startRecording(tag: string, context: Context, recorderStateCallback: Callback<string>,
    onErrorCallback?: Callback<BusinessError>): Promise<void> {
    LogUtil.info(TAG + ` startRecording start from: ${tag}`);
    RecordStateManager.changeRecordState(GlobalRecordState.COMMON_RECORDING);
    this.recordingData = new RecordingData();
    this.recordingData.setCurrentLocation(context.resourceManager.getStringSync($r('app.string.untitledRecording')));
    const locationGrantStatus = await MediaController.checkAccessToken('ohos.permission.LOCATION');
    const nonPreciseLocationGrant = await MediaController.checkAccessToken('ohos.permission.APPROXIMATELY_LOCATION');
    // instrument ignore if
    if ((locationGrantStatus !== abilityAccessCtrl.GrantStatus.PERMISSION_DENIED ||
      nonPreciseLocationGrant !== abilityAccessCtrl.GrantStatus.PERMISSION_DENIED) &&
      geoLocationManager.isLocationEnabled()) {
      LogUtil.info(TAG + ' isLocationEnabled true.');
      //位置权限检擦通过和位置按钮已开启，说明定位可以用，把开启了定位的录音先用时间命名
      this.recordingData.setCurrentLocation(Util.dateFormat(new Date(), 'M月d日'));
      // todo 先注释现在逆地理编码接口无法使用
      // this.getCurrentLocation();
    }
    let avProfile: media.AVRecorderProfile = {
      audioBitrate: 148000, // 音频比特率
      audioChannels: 2, // 音频声道数
      audioCodec: media.CodecMimeType.AUDIO_AAC, // 音频编码格式，当前只支持aac
      audioSampleRate: 48000, // 音频采样率
      fileFormat: media.ContainerFormatType.CFT_MPEG_4A, // 封装格式，当前只支持m4a
    };
    let filesDir = context.filesDir;
    let createTime = new Date().getTime();
    let fileName = createTime.toString();
    let filePath = filesDir + '/' + fileName + ConfigData.FileType;
    this.recordingData.setCreateTime(createTime);
    this.recordingData.setFileName(fileName);
    this.recordingData.setFilePath(filePath);
    try {
      let file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: avProfile,
        url: `fd://${file.fd}`
      };
      await RecordManager.getInstance().setAvRecorderConfig(tag, file.fd,
        filePath, avConfig, recorderStateCallback, this.baseRecorderStateCallback, onErrorCallback);
    } catch (error) {
      LogUtil.error(TAG + ' open file error : ' + error);
    }
  }


  /* instrument ignore next */
  private getCurrentLocation() {
    LogUtil.info(TAG + ' getCurrentLocation start.')
    let requestInfo: geoLocationManager.CurrentLocationRequest = {
      'priority': geoLocationManager.LocationRequestPriority.FIRST_FIX,
      'scenario': geoLocationManager.LocationRequestScenario.UNSET,
      'maxAccuracy': 0
    };
    geoLocationManager.getCurrentLocation(requestInfo).then((result) => {
      LogUtil.info(TAG + `getCurrentLocation---${JSON.stringify(result)}.`)
      let reverseGeocodeRequest: geoLocationManager.ReverseGeoCodeRequest = {
        'latitude': result.latitude,
        'longitude': result.longitude,
        'maxItems': 1
      };
      geoLocationManager.getAddressesFromLocation(reverseGeocodeRequest).then((data) => {
        LogUtil.info(TAG + ' getAddressesFromLocation result.');
        if (data[0].roadName) {
          this.recordingData.setCurrentLocation(data[0].roadName as string);
        } else if (data[0].subLocality) {
          this.recordingData.setCurrentLocation(data[0].subLocality as string);
        } else if (data[0].subAdministrativeArea) {
          this.recordingData.setCurrentLocation(data[0].subAdministrativeArea as string);
        }
        LogUtil.info(TAG + ' getCurrentLocation end.')
      }).catch((err: BusinessError) => {
        LogUtil.info(TAG + ` getAddressesFromLocation error, code: ${err?.code}, message: ${err?.message}`);
      })
    }).catch((err: BusinessError) => {
      LogUtil.info(TAG + ` getCurrentLocation error, code: ${err?.code}, message: ${err?.message}`);
    })
  }

  // instrument ignore next
  private baseRecorderStateCallback = async (state: string) => {
    LogUtil.info(TAG + ' avRecorder state changed to ' + state);
    const recordManager = RecordManager.getInstance();
    if (state === 'prepared') {
      recordManager.start();
    }
    if (state === 'started') {
      this.setSilentRingMode();
      this.recorderProcessCheck();
    }
    if (state === 'paused') {
      this.clearRecorderProcessTimer();
      this.restoreRingMode();
    }
    if (state === 'released') {
      this.clearRecorderProcessTimer();
      NotificationManagerUtil.getInstance().cancelNotification();
      let duration: number = recordManager.getRecorderDuration();
      AppStorage.setOrCreate('shortCutStartRecord', false);
      AppStorage.setOrCreate('recordingFromLock', false);
      // 优先使用从录音文件中获取到的时长，避免误差
      if (duration !== 0) {
        // 保存数据提前，需要的主页面中的事件需要延迟执行
        await this.saveData();
      }
      this.restoreRingMode();
    }
    LogUtil.info(TAG + ' play state changed, state = ' + state);
    this.toastWhenStateChanged(state);
  }

  /* instrument ignore next */
  async saveData(): Promise<void> {
    let context = GlobalContext.getUIAbilityContext();
    let inBackground = AppStorage.get(Props.IS_IN_BACKGROUND) as boolean;
    try {
      if (!fs.accessSync(this.recordingData.getFilePath())) {
        LogUtil.error(TAG + ' filePath does not exist, return.');
        return;
      }
      const stat = await FileUtil.stat(this.recordingData.getFilePath());
      const num = await DatabaseManager.saveRecord([{
        'id': stat.inode,
        'title': this.recordingData.getFileName() + ConfigData.FileType, // 文件名
        '_data': this.recordingData.getFilePath(),
        'date_added': this.recordingData.getCreateTime(), // 创建时间
        'file_size': this.getSize(this.recordingData.getFileName() + ConfigData.FileType),
        'duration': RecordManager.getInstance().getRecorderDuration(), // 优先使用从录音文件中获取到的时长，避免误差
        'voiceList': '', // 录音音频振幅数据列表
        'location': this.recordingData.getCurrentLocation(), // 地理位置
      }]);
      if (num > 0) {
        await this.renameData();
        let fileName = this.recordingData.getFileName();
        this.clearMarkList();
        LogUtil.info(TAG + ' save recorder data success, title: ' + AnonymousUtil.anonymous(fileName));

        if (DeviceUtil.isPC()) {
          let message: string = context.resourceManager.getStringSync($r('app.string.end_unmute_notification'));
          Util.showToast(message, true, inBackground);
        } else {
          let message: string = context.resourceManager.getStringSync($r('app.string.end_recording'));
          Util.showToast(message, false, inBackground);
        }
        AuditLogManager.getInstance().saveRecordAuditLog(
          AnonymousUtil.anonymous(fileName), 'SUCCESS');
        // 延迟500ms弹出新添加的录音文件信息，上一个弹窗默认持续时间为1500ms，延迟500msIndex页面中事件已经出现
        setTimeout(() => {
          this.showSaveFileToastCallback(context, inBackground, fileName);
        }, 500)
      } else {
        AuditLogManager.getInstance().saveRecordAuditLog('', 'FAIL');
      }
      let stopRecordTime = new Date().getTime();
      context?.eventHub?.emit('addIndexList', stopRecordTime, this.recordingData.getFilePath());
    } catch (err) {
      LogUtil.info(TAG + ` save data error, code: ${err?.code}, message: ${err?.message}`);
    }
  }

  private showSaveFileToastCallback(context: Context, inBackground: boolean, fileName: string): void {
    let timerOut = setTimeout(() => {
      let message = context?.resourceManager.getStringSync($r('app.string.store_as_filename').id, fileName)
      Util.showToast(message, DeviceUtil.isPC(), inBackground);
      clearTimeout(timerOut);
    }, 1000);
  }

  getSize(name: string): number {
    let pathDir = this.context.filesDir;
    let curpathDir = pathDir + '/' + name;
    let stat = fs.statSync(curpathDir);
    return stat.size
  }

  // instrument ignore next
  async renameData() {
    const currentLocation = this.recordingData.getCurrentLocation()
    const filesDir = PathUtil.USER_FILEPATH;
    const newTitle = await FileUtil.getFreeNewFilename(currentLocation + ConfigData.FileType,
      this.context.filesDir, filesDir);
    const oldPath = this.recordingData.getFilePath();
    const newPath = filesDir + '/' + newTitle;
    const ok = await FileUtil.moveFile(oldPath, newPath);
    if (!ok) {
      LogUtil.error(`${TAG} failed to move file.`);
      return;
    }
    FileManager.setRecordingFilepath('');
    const savedName = newTitle.substring(0, newTitle.lastIndexOf('.')) || '';

    this.context.eventHub.emit('updateFaFileName', savedName);
    if (this.isShutdown) {
      this.context.eventHub.emit('updateFaFileNameWhenKill', '');
    }
    this.recordingData.setFilePath(newPath);
    this.recordingData.setFileName(newTitle);
    const stat = await FileUtil.stat(newPath);
    await DatabaseManager.updateNormalRecordDatabase(oldPath || '', {
      'id': stat.inode,
      'title': newTitle,
      '_data': newPath
    });
    await DatabaseManager.batchUpdateTag(oldPath, newPath);
    if (!DeviceUtil.isPC()) {
      await this.transferDataUpdate(savedName, newPath);
    }
    let backFromRecordingPage = AppStorage.get('backFromRecordingPage') as boolean;
    // instrument ignore if
    if (!backFromRecordingPage) {
      this.context.eventHub.emit('deleteMarkList');
    }
  }

  /* instrument ignore next */
  async transferDataUpdate(savedName: string, newPath: string) {
    let startQuickTrans = this.recordingData.getStartQuickTrans();
    if (!startQuickTrans) {
      return;
    }
    let transferDataId = this.recordingData.getTransferDataId();
    let newJsonName = savedName + ConfigData.JsonFileType;
    let newJsonPath = getContext(this).filesDir + '/' + newJsonName;
    let oldJsonPath = this.recordingData.getJsonFilePath();
    let oldJsonUri = this.recordingData.getJsonFileUri();
    LogUtil.info(TAG + 'newJsonName:' + newJsonName);
    LogUtil.info(TAG + 'newJsonPath:' + newJsonPath);
    LogUtil.info(TAG + 'oldJsonPath:' + oldJsonPath);
    LogUtil.info(TAG + 'oldJsonUri:' + oldJsonUri);

    let transferFile: fs.File | undefined;
    try {
      await FileUtil.moveFile(oldJsonPath, newJsonPath);
      transferFile = fs.openSync(oldJsonUri, fs.OpenMode.READ_WRITE);
      fs.copyFileSync(transferFile.fd, newJsonPath);
      LogUtil.info(TAG + 'transferDataId:' + transferDataId);
      await DatabaseManager.updateTransferDateWithId(transferDataId, {
        'record_path': newPath,
        'json_path': newJsonPath,
        'state': 2,
        'incomplete': this.recordingData.getIncomplete()
      });
    } catch (e) {
      LogUtil.error(TAG + 'update quick transfer Data failed.');
    } finally {
      fs.close(transferFile);
    }
  }

  /**
   * 设置静音模式
   */
  /* instrument ignore next */
  public setSilentRingMode(): void {
    LogUtil.info(TAG + ': setSilentRingMode start.');
    let audioManager = audio.getAudioManager();
    let audioVolumeManager: audio.AudioVolumeManager = audioManager.getVolumeManager();
    let groupId: number = audio.DEFAULT_VOLUME_GROUP_ID;
    audioVolumeManager.getVolumeGroupManager(groupId,
      (err: BusinessError, value: audio.AudioVolumeGroupManager) => {
        if (err) {
          LogUtil.error(TAG + ': setSilentRingMode error. ' + err);
          return;
        }
        // 保存开始的铃声模式
        this.defaultRingMode = value.getRingerModeSync();
        // 设置静音
        value.setRingerMode(audio.AudioRingMode.RINGER_MODE_SILENT);
        LogUtil.info(TAG + ': setSilentRingMode RINGER_MODE_SILENT success.');
      });
  }

  /**
   * 恢复原本的铃声模式
   */
  /* instrument ignore next */
  public restoreRingMode(): void {
    LogUtil.info(TAG + ': restoreRingMode start.');
    let audioManager = audio.getAudioManager();
    let audioVolumeManager: audio.AudioVolumeManager = audioManager.getVolumeManager();
    let groupId: number = audio.DEFAULT_VOLUME_GROUP_ID;
    audioVolumeManager.getVolumeGroupManager(groupId,
      (err: BusinessError, value: audio.AudioVolumeGroupManager) => {
        if (err) {
          LogUtil.error(TAG + ': restoreRingMode error. ' + err);
          return;
        }
        let currentRingMode = value.getRingerModeSync();
        if (this.defaultRingMode >= 0 && currentRingMode === audio.AudioRingMode.RINGER_MODE_SILENT) {
          // 说明录音期间，用户没有修改录音状态，可以恢复状态
          value.setRingerMode(this.defaultRingMode);
        } else {
          // 录音期间，用户修改了静音模式，这是就不恢复一开始的状态了
          LogUtil.info(TAG + ': restoreRingMode skiped.');
        }
        LogUtil.info(TAG + ': restoreRingMode success.');
      });
  }

  /* instrument ignore next */
  private async recorderProcessCheck() {
    let fsInfo = await fs.lstat(this.recordingData.getFilePath());
    let inBackground = AppStorage.get<boolean>(Props.IS_IN_BACKGROUND);
    if (fsInfo.size < CommonConstants.STORAGE_2GB_TO_B) {
      let recorderProcessCheckTimeNumber = this.recorderProcessCheckTimeNumber;
      let recorderProcessCheckTime = this.recorderProcessCheckTime;
      if (recorderProcessCheckTimeNumber < 12) {
        this.recorderProcessCheckTimeNumber = recorderProcessCheckTimeNumber + 1;
      } else {
        this.recorderProcessCheckTimeNumber = 0;
        this.recorderProcessCheckTime =
          recorderProcessCheckTime / 2 > CommonConstants.TIME_60000 ? recorderProcessCheckTime / 2 :
            CommonConstants.TIME_60000;
      }
      this.recorderProcessCheckTimer = setTimeout(() => {
        this.recorderProcessCheck();
      }, this.recorderProcessCheckTime);
    } else {
      this.clearRecorderProcessTimer();
      LogUtil.info(TAG + ` recorderProcessCheck`);
      let message: string = this.context?.resourceManager.getStringSync($r('app.string.size_upper_limit'))
      Util.showToast(message, DeviceUtil.isPC(), inBackground);
      const recordManager = RecordManager.getInstance();
      recordManager.pause();
      setTimeout(() => {
        recordManager.release();
      }, 2000);
    }
  }

  public clearRecorderProcessTimer() {
    clearTimeout(this.recorderProcessCheckTimer);
  }

  /**
   * 显示Toast当状态变化时
   */
  /* instrument ignore next */
  private toastWhenStateChanged(state: string): void {
    let isScreenLock = AppStorage.get('isScreenLock') as boolean;
    let inBackground = AppStorage.get<boolean>(Props.IS_IN_BACKGROUND);
    let isScreenReaderEnabled =
      Settings.getValueSync(getContext(this), 'accessibility_screenreader_enabled', '') === '1';
    if (isScreenLock || isScreenReaderEnabled) {
      LogUtil.info(TAG + ' do not show toast when screen locked or screenReader enabled');
      return;
    }
    switch (state) {
      case CommonConstants.STARTED:
        if (DeviceUtil.isPC()) {
          let message: string = this.context.resourceManager.getStringSync($r('app.string.start_mute_notification'));
          Util.showToast(message, true, inBackground);
        } else {
          let message: string = this.context.resourceManager.getStringSync($r('app.string.start_recording'))
          Util.showToast(message, false, inBackground);
        }
        break;
      case CommonConstants.PAUSED:
        if (DeviceUtil.isPC()) {
          let message: string = this.context.resourceManager.getStringSync($r('app.string.pause_unmute_notification'));
          Util.showToast(message, true, inBackground);
        } else {
          let message: string = this.context.resourceManager.getStringSync($r('app.string.pause_recording'));
          Util.showToast(message, false, inBackground);
        }
        break;
    }
  }

  /**
   * 获取标记列表
   *
   * @returns 标记对象
   */
  /* instrument ignore next */
  public getMarkList(): MarkDataGroup {
    return this.markList;
  }

  /**
   * 清除MarkList
   *
   */
  private clearMarkList(): void {
    this.markList = new MarkDataGroup();
  }


  /**
   * 赋值标记列表，并通知所有订阅对象
   *
   * @param 标记对象
   */
  public setMarkList(tag: string, newMarkList: MarkDataGroup): void {
    this.markList.content.updateAllData(newMarkList.content.getAll());
    this.notifyMarkListSubscribers(tag);
  }

  /**
   * 其他类注册一个回调函数，当markList变化时，这个回调函数会被调用。
   *
   * @param callback 回调函数
   */
  /* instrument ignore next */
  public subscribeMarkList(callback: (tag: string, markList: MarkDataGroup) => void): void {
    this.markListSubscribers.push(callback);
  }

  /**
   * 取消markList注册。
   *
   * @param callback 回调函数
   */
  /* instrument ignore next */
  public unsubscribeMarkList(callback: (tag: string, markList: MarkDataGroup) => void): void {
    this.markListSubscribers = this.markListSubscribers.filter(subscriber => subscriber !== callback);
  }

  private notifyMarkListSubscribers(tag: string): void {
    this.markListSubscribers.forEach((callback) => {
      callback(tag, this.markList);
    });
  }

  /* instrument ignore next */
  public broadcastWhenUpdateMarkList() {
    if (AccessibilityUtil.isOpenTouchGuide()) {
      let markCount: number = this.markList.content.getAll().length;
      let counts: number[] = this.markList.content.getAll().map((item) => {
        return item.count;
      })
      let maxCount = Math.max(...counts);
      let minCount = Math.min(...counts);
      if (markCount > 0) {
        let broadcastContent: string =
          AccessibilityUtil.getMarkListBroadCastContent(this.markList.content.getAll().length, minCount, maxCount);
        AccessibilityUtil.sendAnnounceAccessibilityEvent(broadcastContent);
      }
    }
  }

  /* instrument ignore next */
  public async syncNormalRecordListFromDb(reason: string): Promise<void> {
    LogUtil.info(TAG + ' begin to syncNormalRecordListFromDb: ' + reason);
    hiTraceMeter.startTrace('syncNormalRecordListFromDb', 1);

    // 获取回收站中录音记录
    hiTraceMeter.startTrace('queryRecentDeleteTable', 1);
    let recentDeleteList = await DatabaseManager.getAllDbQuery('recent_delete_record_table');
    this.recordDataGroupList.recentDeleteList.deleteAll();
    this.recordDataGroupList.recentDeleteList.batchPushItem(recentDeleteList);
    hiTraceMeter.finishTrace('queryRecentDeleteTable', 1);
    LogUtil.info(TAG + ' recentDeleteList length: ' + recentDeleteList.length);

    hiTraceMeter.startTrace('queryNormalRecordTable', 1);
    let normalRecordList = await DatabaseManager.getAllDbQuery('normal_record_table', false);
    normalRecordList =
      await DatabaseManager.scanFiles(normalRecordList, recentDeleteList, this.recordingData.getFileName(), []);
    await this.sortNormalRecordList(normalRecordList);
    this.recordDataGroupList.normalRecordList.deleteAll();
    this.recordDataGroupList.normalRecordList.batchPushItem(normalRecordList);
    hiTraceMeter.finishTrace('queryNormalRecordTable', 1);
    LogUtil.info(TAG + ' normalRecordList length: ' + normalRecordList.length);

    hiTraceMeter.finishTrace('syncNormalRecordListFromDb', 1);
  }

  /* instrument ignore next */
  async sortNormalRecordList(normalRecordList: RecordData[]) {
    this.sortType = await PreferencesUtil.get(SortConstants.PRE_KEY, SortType.SORT_TIME_DESC) as string;
    LogUtil.info(TAG + ' sortNormalRecordList sortType: ' + this.sortType);
    if (typeof this.sortType === 'number') {
      LogUtil.error(TAG + ' sortType is invalid: number');
      this.sortType = String(this.sortType);
      await PreferencesUtil.put(SortConstants.PRE_KEY, this.sortType);
    }
    this.sortRecord(normalRecordList);
  }

  /* instrument ignore next */
  private sortRecord(list: RecordData[]) {
    if (this.sortType === SortType.SORT_TIME_ASC) {
      list.sort((a, b) => a.date - b.date);
    } else if (this.sortType === SortType.SORT_TIME_DESC) {
      list.sort((a, b) => b.date - a.date);
    } else if (this.sortType === SortType.SORT_NAME_ASC) {
      list.sort((a: RecordData, b: RecordData) => {
        return this.recordCompare.compare(a.name, b.name);
      });
    }
  }


  // 获取转文本文件路径
  /* instrument ignore next */
  public async getJsonFileUri(): Promise<string> {
    this.recordingData.setStartQuickTrans(true);
    let transferDataId = util.generateRandomUUID(true);
    let sharedAudioFilePath = this.getSharedUuidPath(transferDataId);
    let uri = fileUri.getUriFromPath(sharedAudioFilePath);
    let jsonFileName = this.recordingData.getFileName() + ConfigData.JsonFileType;
    let jsonFilePath = getContext(this).filesDir + '/' + jsonFileName;
    let jsonFileUri = '';
    let file: fs.File | null = null;
    try {
      FileUtil.mkdirIfNotExists(getContext(this).filesDir);
      if (!fs.accessSync(jsonFilePath)) {
        file = fs.openSync(jsonFilePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
        fs.copyFileSync(file.fd, jsonFilePath);
      } else {
        file = fs.openSync(jsonFilePath, fs.OpenMode.READ_WRITE);
      }
      jsonFileUri = await Util.grandTranPermission(jsonFilePath);
    } catch (error) {
      LogUtil.error(TAG + `fail to grant uri permission: ${error?.code}, ${error?.message}`);
      if (file !== null) {
        fs.closeSync(file);
      }
    } finally {
      if (file !== null) {
        fs.closeSync(file);
      }
    }

    //实时转写数据存储
    let transferData = {
      id: transferDataId,
      recordPath: this.recordingData.getFilePath(),
      sessionId: '',
      fileUri: uri,
      state: 0,
      createTime: new Date().getTime(),
      jsonPath: jsonFilePath,
      sourceType: 0,
      incomplete: 0
    } as TransferData;
    DatabaseManager.saveTransferData(transferData);
    //转写数据缓存至当前录音信息中
    this.recordingData.setTransferDataId(transferDataId);
    this.recordingData.setJsonFilePath(jsonFilePath);
    this.recordingData.setJsonFileUri(jsonFileUri);
    return jsonFileUri;
  }

  /* instrument ignore next */
  private getSharedUuidPath(transferDataId: string): string {
    let jsonfilePath = getContext(this).distributedFilesDir + '/' + transferDataId + ConfigData.FileType;
    return jsonfilePath;
  }
}