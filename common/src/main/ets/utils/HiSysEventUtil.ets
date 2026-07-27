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

import { BusinessError } from '@ohos.base';
import hilog from '@ohos.hilog';
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtil } from './LogUtil';
import hiSysEvent from '@ohos.hiSysEvent';
import { storageStatistics } from '@kit.CoreFileKit';
import { PreferencesUtil } from './PreferencesUtil';

const TAG = 'SoundRecorder_Common_Sys_EventReport';

export class HiSysEventName {

  /**
   * 打开录音机app（包含点击图标进入、桌面卡片进入、通话录音进入、语音触发进入）
   */
  public static readonly ENTER_APP = 'ENTER_APP';

  /**
   * 开始录音（包含应用内、快捷方式）
   */
  public static readonly START_RECORD = 'START_RECORD';

  /**
   * 录音列表界面-单击一条录音
   */
  public static readonly RECORD_LIST_ITEM_CLICKED = 'RECORD_LIST_ITEM_CLICKED';

  /**
   * 录音列表界面-开始录音
   */
  public static readonly ADD_RECORD = 'ADD_RECORD';

  /**
   * 录音列表界面-播放录音
   */
  public static readonly PLAY_SINGLE_AUDIO = 'PLAY_SINGLE_AUDIO';

  /**
   * 录音界面-暂停录音
   */
  public static readonly PAUSE_RECORD = 'PAUSE_RECORD';

  /**
   * 录音界面-继续录音
   */
  public static readonly RESUME_RECORD = 'RESUME_RECORD';

  /**
   * 录音结束，保存录音
   */
  public static readonly SAVE_RECORD = 'SAVE_RECORD';

  /**
   * 录音列表界面-长按录音列表
   */
  public static readonly LOGNPRESS_ON_RECORD_LIST = 'LOGNPRESS_ON_RECORD_LIST';

  /**
   * 长按多选操作-选择录音
   */
  public static readonly SELECT_ITEM_ON_RECORD_LIST = 'SELECT_ITEM_ON_RECORD_LIST';

  /**
   * 长按多选操作-取消选择录音项
   */
  public static readonly CNCL_SEL_ON_REC_LIST = 'CNCL_SEL_ON_REC_LIST';

  /**
   * 长按多选操作-分享录音
   */
  public static readonly SHARE_RECORD_LIST = 'SHARE_RECORD_LIST';

  /**
   * 长按多选操作-删除录音
   */
  public static readonly DELETE_RECORD_LIST = 'DELETE_RECORD_LIST';

  /**
   * 长按多选操作-更多-重命名录音列表
   */
  public static readonly RENAME_RECORD_LIST = 'RENAME_RECORD_LIST';

  /**
   * 长按多选操作-全选/取消全选录音文件
   */
  public static readonly SELECT_ALL_RECORD_LIST = 'SELECT_ALL_RECORD_LIST';

  /**
   * 播放录音界面-播放录音
   */
  public static readonly PLAY_DETAIL_PLAY0 = 'PLAY_DETAIL_PLAY0';

  /**
   * 播放录音界面-暂停录音
   */
  public static readonly PLAY_DETAIL_PAUSE0 = 'PLAY_DETAIL_PAUSE0';

  /**
   * 录音界面-点击快速标记
   */
  public static readonly ADD_QUICK_TAG = 'ADD_QUICK_TAG';

  /**
   * 播放录音界面-点击快速标记
   */
  public static readonly ADD_QUICK_TAG_PLAYBACK = 'ADD_QUICK_TAG_PLAYBACK';

  /**
   * 播放/录音界面-左滑删除标记
   */
  public static readonly DELETE_TAG = 'DELETE_TAG';

  /**
   * 录音界面-点击标记重命名标记
   */
  public static readonly RENAME_TAG = 'RENAME_TAG';

  /**
   * 录音界面-确认标记重命名
   */
  public static readonly SAVE_RENAME_TAG = 'SAVE_RENAME_TAG';

  /**
   * 录音列表界面右上角-进入关于页面
   */
  public static readonly ENTER_ABOUT_PAGE = 'ENTER_ABOUT_PAGE';

  /**
   * 录音列表界面右上角-进入数据同步页面
   */
  public static readonly DATA_UPDATE_PAGE = 'DATA_UPDATE_PAGE';

  /**
   * 长按多选操作-更多-重命名确认
   */
  public static readonly RENAME_CONFIRM = 'RENAME_CONFIRM';

  /**
   * 长按多选操作-删除确认
   */
  public static readonly DELETE_CONFIRM = 'DELETE_CONFIRM';

  /**
   * 长按多选操作-更多-打开文件详细信息
   */
  public static readonly OPEN_FILE_DETAIL = 'OPEN_FILE_DETAIL';

  /**
   * 进入播放录音界面（包含应用内、快捷方式）
   */
  public static readonly DIRECTION_VIEW = 'DIRECTION_VIEW';

  /**
   * 播放录音界面-多倍速1倍速
   */
  public static readonly MULTIPLE_SPEED_NORMAL = 'MULTIPLE_SPEED_NORMAL';

  /**
   * 播放录音界面-多倍速1倍速
   */
  public static readonly MULTIPLE_SPEED = 'MULTIPLE_SPEED';

  /**
   * 播放录音界面-多倍速2倍速
   */
  public static readonly MULTIPLE_SPEED_DOUBLE = 'MULTIPLE_SPEED_DOUBLE';

  /**
   * 播放录音界面-更多-分享
   */
  public static readonly SHARE_MENU = 'SHARE_MENU';

  /**
   * 播放录音界面-更多-重命名文件
   */
  public static readonly RENAME_TRACK_ON_PLAYING = 'RENAME_TRACK_ON_PLAYING';

  /**
   * 播放录音界面-更多-确认重命名确认
   */
  public static readonly RENAME_TRACK_CONFIRM_ON_PLAYING = 'RENAME_TRACK_CONFIRM_ON_PLAYING';

  /**
   * 播放录音界面-更多-删除文件
   */
  public static readonly DELETE_TRACK_ON_PLAYING = 'DELETE_TRACK_ON_PLAYING';

  /**
   * 播放录音界面-更多-确认删除文件
   */
  public static readonly DELETE_TRACK_CONFIRM_ON_PLAYING = 'DELETE_TRACK_CONFIRM_ON_PLAYING';

  /**
   * 播放录音界面-更多-进入详情页面
   */
  public static readonly ENTER_ABOUT_PAGE_ON_PLAYING = 'ENTER_ABOUT_PAGE_ON_PLAYING';

  /**
   * 播放录音界面-点击标记时间
   */
  public static readonly PLAY_TAG = 'PLAY_TAG';

  /**
   * 播放录音界面-点击标记重命名
   */
  public static readonly RENAME_TAG_ON_PLAYING = 'RENAME_TAG_ON_PLAYING';

  /**
   * 播放录音界面-点击标记确认重命名
   */
  public static readonly RENAME_TAG_CONFIRM_ON_PLAYING = 'RENAME_TAG_CONFIRM_ON_PLAYING';

  /**
   * 录音机-录音列表界面-左滑文件
   */
  public static readonly RECORD_SWIPE_OPEN = 'RECORD_SWIPE_OPEN';

  /**
   * 录音列表界面-左滑文件-分享
   */
  public static readonly SWIPE_SHARE = 'SWIPE_SHARE';

  /**
   * 录音列表界面-左滑文件-删除
   */
  public static readonly SWIPE_DELETE = 'SWIPE_DELETE';

  /**
   * 录音列表界面-左滑文件-确认删除
   */
  public static readonly SWIPE_DELETE_CONFIRM = 'SWIPE_DELETE_CONFIRM';

  /**
   * 播放模式-关闭扬声器（听筒模式）
   */
  public static readonly HANDSET_MODE = 'HANDSET_MODE';

  /**
   * 通话录音列表-播放
   */
  public static readonly PLAY_CALL_RECORD = 'PLAY_CALL_RECORD';

  /**
   * 通话录音列表-暂停
   */
  public static readonly PAUSE_PLAY_CALL_RECORD = 'PAUSE_PLAY_CALL_RECORD';

  /**
   * 通话录音列表-播放时拖动进度
   */
  public static readonly DRAG_SEEKBAR_PLAY_CALL_RECORD = 'DRAG_SEEKBAR_PLAY_CALL_RECORD';

  /**
   * 列表/播放-切换扬声器模式:开/关
   */
  public static readonly SPEAKER_SWITCH = 'SPEAKER_SWITCH';

  /**
   * 播放录音界面-跳过静音
   */
  public static readonly SKIP_MUTE = 'SKIP_MUTE';

  /**
   * 播放录音界面-拖动波形图
   */
  public static readonly MOVE_WAVE_AND_SEEK = 'MOVE_WAVE_AND_SEEK';

  /**
   * 通话录音列表-点击通话录音入口条目
   */
  public static readonly CLICK_CALL_RECORD_ENTRANCE = 'CLICK_CALL_RECORD_ENTRANCE';

  /**
   * 后台录音-实况胶囊-暂停/继续录音
   */
  public static readonly BACK_REC_PAUSE = 'BACK_REC_PAUSE';

  /**
   * 后台录音-实况胶囊-结束录音
   */
  public static readonly BACK_REC_STOP = 'BACK_REC_STOP';

  /**
   * 后台播放-播控中心-暂停/继续播放
   */
  public static readonly BACK_PLAY_PAUSE = 'BACK_PLAY_PAUSE';

  /**
   * 录音机-悬浮窗-分享录音
   */
  public static readonly SHARE_FLOAT_RECORD_LIST = 'SHARE_FLOAT_RECORD_LIST';

  /**
   * 录音机-悬浮窗-删除录音
   */
  public static readonly DELETE_FLOAT_RECORD_LIST = 'DELETE_FLOAT_RECORD_LIST';

  /**
   * 录音机-录音列表界面-长滑动删除
   */
  public static readonly LONG_SWIPE_DELETE = 'LONG_SWIPE_DELETE';

  /**
   * 录音机-录音列表界面-暂停播放录音
   */
  public static readonly PAUSE_SINGLE_AUDIO = 'PAUSE_SINGLE_AUDIO';

  /**
   * 录音机-录音列表界面-拖动进度条
   */
  public static readonly DRAG_SEEKBAR_PLAY_RECORD = 'DRAG_SEEKBAR_PLAY_RECORD';

  /**
   * 录音机-长滑动删除确认
   */
  public static readonly LONG_SWIPE_DELETE_CONFIRM = 'LONG_SWIPE_DELETE_CONFIRM';

  /**
   * 录音机-悬浮窗-删除确认
   */
  public static readonly DELETE_FLOAT_RECORD_LIST_CONFIRM = 'DELETE_FLOAT_RECORD_LIST_CONFIRM';

  /**
   * 录音机-录音过程中退到后台
   */
  public static readonly RECORD_BACK = 'RECORD_BACK';

  /**
<<<<<<< HEAD
   * 录音机-文本界面-生成摘要
   */
  public static readonly TEXT_SUMMARY_REQUEST = 'TEXT_SUMMARY_REQUEST';

  /**
   * 录音机-将摘要添加会文本页面
   */
  public static readonly ADD_SUM_TO_TEXT = 'ADD_SUM_TO_TEXT';

  /**
   * 隐私空间-录音机-录音文件迁移-数据查询
   */
  public static readonly MIGRATION_RECORD_QUERY = 'MIGRATION_RECORD_QUERY';

  /**
   * 隐私空间-录音机-录音文件迁移-写入数据
   */
  public static readonly MIGRATION_RECORD_WRITE = 'MIGRATION_RECORD_WRITE';

  /**
   * 隐私空间-录音机-录音文件迁移-文件校验
   */
  public static readonly MIGRATION_RECORD_APPLY = 'MIGRATION_RECORD_APPLY';

  /**
   * 隐私空间-录音机-录音文件迁移-删除原数据
   */
  public static readonly MIGRATION_RECORD_DELETE = 'MIGRATION_RECORD_DELETE';

  /**
   * 录音机-进入语音转写页
   */
  public static readonly ENTER_TEXT_PAGE = 'ENTER_TEXT_PAGE';

  /**
   * 录音机-文本界面-添加标记
   */
  public static readonly TEXT_ADD_TAG = 'TEXT_ADD_TAG';

  /**
   * 录音机-文本界面-开始播放
   */
  public static readonly TEXT_PLAY = 'TEXT_PLAY';

  /**
   * 录音机-文本界面-暂停播放
   */
  public static readonly TEXT_PAUSE = 'TEXT_PAUSE';

  /**
   * 录音机-文本界面-倍速播放
   */
  public static readonly TEXT_MULTIPLE_SPEED = 'TEXT_MULTIPLE_SPEED';

  /**
   * 录音机-文本界面-拖动进度条
   */
  public static readonly TEXT_DRAG_SEEKBAR = 'TEXT_DRAG_SEEKBAR';

  /**
   * 录音机-克隆信息
   */
  public static readonly CLONE_ANALYSIS = 'CLONE_ANALYSIS';

  /**
   * 导航栏-进入录音列表
   */
  public static readonly NAV_ENTER_MAIN = 'NAV_ENTER_MAIN';

  /**
   * 导航栏-进入通话列表
   */
  public static readonly NAV_ENTER_CALL = 'NAV_ENTER_CALL';

  /**
   * 导航栏-进入最近删除
   */
  public static readonly NAV_ENTER_DEL = 'NAV_ENTER_DEL';

  /**
   * 导航栏-进入耳机录音列表
   */
  public static readonly NAV_ENTER_HEADSET = 'NAV_ENTER_HEADSET';

  /**
   * 最近删除页-右上角多选
   */
  public static readonly DEL_MULTI_SEL = 'DEL_MULTI_SEL';

  /**
   * 最近删除页-右上角全部恢复
   */
  public static readonly DEL_RECOVER_ALL = 'DEL_RECOVER_ALL';

  /**
   * 最近删除页-右上角全部删除
   */
  public static readonly DEL_DELETE_ALL = 'DEL_DELETE_ALL';

  /**
   * 最近删除页-播放
   */
  public static readonly DEL_PLAY = 'DEL_PLAY';

  /**
   * 最近删除页-暂停
   */
  public static readonly DEL_PAUSE = 'DEL_PAUSE';

  /**
   * 最近删除页-长按多选
   */
  public static readonly DEL_PRESS_SEL = 'DEL_PRESS_SEL';

  /**
   * 最近删除页-长按恢复
   */
  public static readonly DEL_PRESS_RECOVER = 'DEL_PRESS_RECOVER';

  /**
   * 最近删除页-长按删除
   */
  public static readonly DEL_PRESS_DELETE = 'DEL_PRESS_DELETE';

  /**
   * 最近删除页-多选恢复
   */
  public static readonly DEL_RECOVER_MUL = 'DEL_RECOVER_MUL';

  /**
   * 最近删除页-多选删除
   */
  public static readonly DEL_DELETE_MUL = 'DEL_DELETE_MUL';

  /**
   * 最近删除页-确认永久删除
   */
  public static readonly DEL_CONFIRM_DEL = 'DEL_CONFIRM_DEL';

  /**
   * 录音机-文本界面-开始转文本
   */
  public static readonly TEXT_START_TRANSCRIPTION = 'TEXT_START_TRANSCRIPTION';

  /**
   * 录音机-文本界面-转文本结束
   */
  public static readonly TEXT_END_TRANSCRIPTION = 'TEXT_END_TRANSCRIPTION';

  /**
   * 录音机-左滑文件_重命名
   */
  public static readonly SWIPE_RENAME = 'SWIPE_RENAME';

  /**
   * 录音机-搜索_发起一次有效搜索
   */
  public static readonly SEARCH_START = 'SEARCH_START';

  /**
   * 录音机-搜索_点击搜索结果进入播放录音视图界面
   */
  public static readonly SEARCH_TAP_RESULT = 'SEARCH_TAP_RESULT';

  /**
   * 录音机-搜索_未搜索到结果
   */
  public static readonly SEARCH_NO_RESULT = 'SEARCH_NO_RESULT';

  /**
   * 录音机-列表界面更多_排序
   */
  public static readonly SORT = 'SORT';

  /**
   * 录音机-列表界面更多_排序-选择排序规则
   */
  public static readonly SORT_CHANGE = 'SORT_CHANGE';

  /**
   * 录音机-用户分区打点
   */
  public static readonly USER_DATA_SIZE = 'USER_DATA_SIZE';


  /**
   * 录音机-列表界面-迁移任务成功率与完成率、迁移任务耗时
   */
  public static readonly MOVE_RECORD = 'MOVE_RECORD';

  /**
   * 录音机-列表界面-迁移任务弹窗-点击迁移提示的同意
   */
  public static readonly MOVE_RECORD_CONFIRM = 'MOVE_RECORD_CONFIRM';

  /**
   * 录音机-列表界面-迁移任务弹窗-点击迁移剩余提示的同意
   */
  public static readonly MOVE_REMAIN_RECORD_CONFIRM = 'MOVE_REMAIN_RECORD_CONFIRM';

  /**
   * 录音机-列表界面-迁移任务-迁移中点停止
   */
  public static readonly STOP_MOVE_RECORD = 'STOP_MOVE_RECORD';

  /**
   * 录音机-列表界面-迁移中点停止-弹出取消迁移提示，点击确认取消
   */
  public static readonly STOP_MOVE_RECORD_CONFIRM = 'STOP_MOVE_RECORD_CONFIRM';

  /**
   * 录音机-列表界面-迁移任务-点击失败重试
   */
  public static readonly RETRY_MOVE_RECORD = 'RETRY_MOVE_RECORD';

  /**
   * 录音机-列表界面-迁移任务-点击失败重试
   */
  public static readonly MOVE_RECORD_DIALOG = 'MOVE_RECORD_DIALOG';

  /**
   * 录音机-录音界面-进入语音转写
   */
  public static readonly ENTER_RECORD_TEXT_PAGE = 'ENTER_RECORD_TEXT_PAGE';

  /**
   * 录音机-语音转写隐私声明
   */
  public static readonly TEXT_PAGE_PRIVACY = 'TEXT_PAGE_PRIVACY';

  /**
   * 录音机-摘要生成隐私声明
   */
  public static readonly TEXT_SUMMARY_PRIVACY = 'TEXT_SUMMARY_PRIVACY';

}

export enum HiSysEventStatus {

  /**
   * 参数success的失败值
   */
  FAILURE = 0,

  /**
   * 参数success的成功值
   */
  SUCCESS = 1
}

interface IParams {
  PNAMEID?: string,
  PVERSIONID?: string,
  VALUE?: string | number,
  DURATION?: string | number,
  SUCCESS?: string | number,
  FROM?: string | number,
  NUM?: string | number,
  FILEID?: string | number | number[] | string[],
  NAMES?: string | number,
  PAGE?: string | number,
  ENTER_FROM?: string | number,
  STATE?: string | number,
  ENTRANCE?: string | number,
  DELETE?: string | number,
  RECORD_TIME?: string | number,
  AUDIO_DATA?: string | number,
  TABLE_DATA?: string | number,
  ERROR_INFO?: string,
  MODE?: string | number,
  RESULT?: string | number,
  COMPONENT_NAME?: string,
  PARTITION_NAME?: string,
  FILE_OR_FOLDER_PATH?: string[],
  FILE_OR_FOLDER_SIZE?: number[],
  SUCCESS_RATE?: string | number,
  COMPLETION_RATE?: string | number,
  CALL_RECORD_NUM?: string | number,
  NORMAL_RECORD_NUM?: string | number,
  FILE_TYPE?: number,
  USERID?: number,
  TAGS?: number,
  FILE_SIZE?: number | number[],
  REMAINING_FILE_COUNT?: string | number
}

export class HiSysEventUtil {
  private static readonly RECORDER_DOMAIN: string = 'RECORDER_UE';
  private static readonly FILE_MANAGEMENT_DOMAIN: string = 'FILEMANAGEMENT';
  private static readonly PNAMEID: string = 'com.ohos.soundrecorder';
  private static readonly FILE_OR_FOLDER_PATH: string[] = ['/data/storage/el1/bundle', '/data/storage/el2/base/',
    '/data/storage/el2/database/'];
  private static readonly USER_DATA_DOTTING_TIME_KEY: string = 'userDataDottingTimestamp';
  private static readonly USER_DATA_DOTTING_INTERVAL = 1000 * 60 * 60 * 24;
  private static PVERSIONID: string = '';

  /**
   * dfx打点事件共用调用接口
   * @param eventName 事件名称，详情请见HiSysEventName
   * @param paramMap 事件参数，可选参数
   * VALUE: string | number
   * DURATION: string | number
   * SUCCESS: string | number
   * FROM: string | number
   * NUM: string | number
   * FILEID: string | number
   * NAMES: string | number
   * PAGE: string | number
   * ENTER_FROM: string | number
   * STATE: string | number
   * ENTRANCE: string | number
   * DELETE: string | number
   */
  public static eventDotting(eventName: string, paramMap?: IParams) {
    let delayTime = 0;
    if (!HiSysEventUtil.PVERSIONID) {
      HiSysEventUtil.getApplicationVersion();
      delayTime = 100;
    }
    setTimeout(() =>{
      let params: IParams = paramMap as IParams ?? {};
      params.PNAMEID = HiSysEventUtil.PNAMEID
      params.PVERSIONID = HiSysEventUtil.PVERSIONID
      LogUtil.error(TAG + ` eventName : ${eventName}`);
      LogUtil.error(TAG + ` params : ${JSON.stringify(params)}`);
      HiSysEventUtil.reportEvent(HiSysEventUtil.RECORDER_DOMAIN, eventName, hiSysEvent.EventType.BEHAVIOR, params);
    }, delayTime);
  }

  /**
   * 用户分区打点
   */
  public static userDataDotting() {
    HiSysEventUtil.isLastUserDataDottingMoreThanInterval().then((value: boolean) => {
      if (value) {
        storageStatistics.getCurrentBundleStats().then((bundleStats: storageStatistics.BundleStats) => {
          let eventName = 'USER_DATA_SIZE';
          let params: IParams = {};
          params.COMPONENT_NAME = 'sound_recorder';
          params.PARTITION_NAME = '/data';
          params.FILE_OR_FOLDER_PATH = HiSysEventUtil.FILE_OR_FOLDER_PATH;

          let dataSizeArray: number[] = [0, 0, 0];
          dataSizeArray[0] = bundleStats.appSize;
          dataSizeArray[2] = bundleStats.dataSize;
          params.FILE_OR_FOLDER_SIZE = dataSizeArray;
          LogUtil.info(`${TAG} eventName: ${eventName}, params: ${JSON.stringify(params)}`);
          HiSysEventUtil.reportEvent(HiSysEventUtil.FILE_MANAGEMENT_DOMAIN, eventName, hiSysEvent.EventType.STATISTIC,
            params);
        }).catch((err: BusinessError) => {
          LogUtil.error(`${TAG} getCurrentBundleStats err, err.code: ${err.code}, err.message: ${err.message}`);
        });
      }
    }).catch((err: BusinessError) => {
      LogUtil.error(`${TAG} isLastUserDataDottingMoreThanInterval err, err.code: ${err.code},
      err.message: ${err.message}`);
    });
  }

  /* instrument ignore next */
  private static reportEvent(domain:string, name: string, eventType: hiSysEvent.EventType, params: object): void {
    hiSysEvent.write({
      domain: domain,
      name: name,
      eventType: eventType,
      params: params
    }).then(() => {
      LogUtil.info(`${TAG} eventName: ${name}, HiSysEvent success to write event`);
      if (domain === HiSysEventUtil.FILE_MANAGEMENT_DOMAIN) {
        PreferencesUtil.put(HiSysEventUtil.USER_DATA_DOTTING_TIME_KEY, Date.now());
      }
    }).catch((err: BusinessError) => {
      LogUtil.error(`${TAG} eventName: ${name}, HiSysEvent write failed, err.code: ${err.code},
       err.message: ${err.message}`);
    })
  }

  private static async isLastUserDataDottingMoreThanInterval(): Promise<boolean> {
    let defValue = 0;
    let lastUserDataDottingTimestamp = await PreferencesUtil.get(HiSysEventUtil.USER_DATA_DOTTING_TIME_KEY,
      defValue) as number;
    if (typeof lastUserDataDottingTimestamp !== 'number' || lastUserDataDottingTimestamp === defValue) {
      return true;
    }
    let nowTime = Date.now();
    if (nowTime - lastUserDataDottingTimestamp <= HiSysEventUtil.USER_DATA_DOTTING_INTERVAL) {
      return false;
    }
    return true;
  }

  /* instrument ignore next */
  public static getApplicationVersion() {
    let bundleFlags = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
    try {
      bundleManager.getBundleInfoForSelf(bundleFlags, (err, data) => {
        if (err) {
          LogUtil.error(TAG + ` getBundleInfoForSelf failed', message: ${err.message}`);
        } else {
          LogUtil.info(TAG + ` getBundleInfoForSelf successfully', message: ${JSON.stringify(data)}`);
          HiSysEventUtil.PVERSIONID = data?.versionName;
        }
      });
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG + ` getBundleInfoForSelf failed: %{public}s', message: ${message}`);
    }
  }
}