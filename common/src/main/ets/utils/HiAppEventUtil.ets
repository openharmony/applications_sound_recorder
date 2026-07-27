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

import hiAppEvent from '@ohos.hiviewdfx.hiAppEvent';
import { BusinessError } from '@ohos.base'
import hilog from '@ohos.hilog';
import bundleManager from '@ohos.bundle.bundleManager';
import { LogUtil } from './LogUtil';

const TAG = 'SoundRecorder_Common_EventReport';

export class HiAppEventName {
  /**
   * 打开录音机app（包含点击图标进入、桌面卡片进入、通话录音进入、语音触发进入）
   */
  public static readonly ENTER_APP = 'ENTER_APP'
  /**
   * 开始录音（包含应用内、快捷方式）
   */
  public static readonly START_RECORD = 'START_RECORD'
  /**
   * 录音列表界面-单击一条录音
   */
  public static readonly RECORD_LIST_ITEM_CLICKED = 'RECORD_LIST_ITEM_CLICKED'
  /**
   * 录音列表界面-开始录音
   */
  public static readonly ADD_RECORD = 'ADD_RECORD'
  /**
   * 录音列表界面-播放录音
   */
  public static readonly PLAY_SINGLE_AUDIO = 'PLAY_SINGLE_AUDIO'
  /**
   * 录音界面-暂停录音
   */
  public static readonly PAUSE_RECORD = 'PAUSE_RECORD'
  /**
   * 录音界面-继续录音
   */
  public static readonly RESUME_RECORD = 'RESUME_RECORD'
  /**
   * 录音结束，保存录音
   */
  public static readonly SAVE_RECORD = 'SAVE_RECORD'
  /**
   * 录音列表界面-长按录音列表
   */
  public static readonly LOGNPRESS_ON_RECORD_LIST = 'LOGNPRESS_ON_RECORD_LIST'
  /**
   * 长按多选操作-选择录音
   */
  public static readonly SELECT_ITEM_ON_RECORD_LIST = 'SELECT_ITEM_ON_RECORD_LIST'
  /**
   * 长按多选操作-取消选择录音项
   */
  public static readonly CNCL_SEL_ON_REC_LIST = 'CNCL_SEL_ON_REC_LIST'
  /**
   * 长按多选操作-分享录音
   */
  public static readonly SHARE_RECORD_LIST = 'SHARE_RECORD_LIST'
  /**
   * 长按多选操作-删除录音
   */
  public static readonly DELETE_RECORD_LIST = 'DELETE_RECORD_LIST'
  /**
   * 长按多选操作-更多-重命名录音列表
   */
  public static readonly RENAME_RECORD_LIST = 'RENAME_RECORD_LIST'
  /**
   * 长按多选操作-全选/取消全选录音文件
   */
  public static readonly SELECT_ALL_RECORD_LIST = 'SELECT_ALL_RECORD_LIST'
  /**
   * 播放录音界面-播放录音
   */
  public static readonly PLAY_DETAIL_PLAY0 = 'PLAY_DETAIL_PLAY0'
  /**
   * 播放录音界面-暂停录音
   */
  public static readonly PLAY_DETAIL_PAUSE0 = 'PLAY_DETAIL_PAUSE0'
  /**
   * 录音界面-点击快速标记
   */
  public static readonly ADD_QUICK_TAG = 'ADD_QUICK_TAG'
  /**
   * 播放录音界面-点击快速标记
   */
  public static readonly ADD_QUICK_TAG_PLAYBACK = 'ADD_QUICK_TAG_PLAYBACK'
  /**
   * 播放/录音界面-左滑删除标记
   */
  public static readonly DELETE_TAG = 'DELETE_TAG'
  /**
   * 录音界面-点击标记重命名标记
   */
  public static readonly RENAME_TAG = 'RENAME_TAG'
  /**
   * 录音界面-确认标记重命名
   */
  public static readonly SAVE_RENAME_TAG = 'SAVE_RENAME_TAG'
  /**
   * 录音列表界面右上角-进入关于页面
   */
  public static readonly ENTER_ABOUT_PAGE = 'ENTER_ABOUT_PAGE'
  /**
   * 长按多选操作-更多-重命名确认
   */
  public static readonly RENAME_CONFIRM = 'RENAME_CONFIRM'
  /**
   * 长按多选操作-删除确认
   */
  public static readonly DELETE_CONFIRM = 'DELETE_CONFIRM'
  /**
   * 长按多选操作-更多-打开文件详细信息
   */
  public static readonly OPEN_FILE_DETAIL = 'OPEN_FILE_DETAIL'
  /**
   * 进入播放录音界面（包含应用内、快捷方式）
   */
  public static readonly DIRECTION_VIEW = 'DIRECTION_VIEW'
  /**
   * 播放录音界面-多倍速1倍速
   */
  public static readonly MULTIPLE_SPEED_NORMAL = 'MULTIPLE_SPEED_NORMAL'
  /**
   * 播放录音界面-多倍速2倍速
   */
  public static readonly MULTIPLE_SPEED_DOUBLE = 'MULTIPLE_SPEED_DOUBLE'
  /**
   * 播放录音界面-更多-分享
   */
  public static readonly SHARE_MENU = 'SHARE_MENU'
  /**
   * 播放录音界面-更多-重命名文件
   */
  public static readonly RENAME_TRACK_ON_PLAYING = 'RENAME_TRACK_ON_PLAYING'
  /**
   * 播放录音界面-更多-确认重命名确认
   */
  public static readonly RENAME_TRACK_CONFIRM_ON_PLAYING = 'RENAME_TRACK_CONFIRM_ON_PLAYING'
  /**
   * 播放录音界面-更多-删除文件
   */
  public static readonly DELETE_TRACK_ON_PLAYING = 'DELETE_TRACK_ON_PLAYING'
  /**
   * 播放录音界面-更多-确认删除文件
   */
  public static readonly DELETE_TRACK_CONFIRM_ON_PLAYING = 'DELETE_TRACK_CONFIRM_ON_PLAYING'
  /**
   * 播放录音界面-更多-进入详情页面
   */
  public static readonly ENTER_ABOUT_PAGE_ON_PLAYING = 'ENTER_ABOUT_PAGE_ON_PLAYING'
  /**
   * 播放录音界面-点击标记时间
   */
  public static readonly PLAY_TAG = 'PLAY_TAG'
  /**
   * 播放录音界面-点击标记重命名
   */
  public static readonly RENAME_TAG_ON_PLAYING = 'RENAME_TAG_ON_PLAYING'
  /**
   * 播放录音界面-点击标记确认重命名
   */
  public static readonly RENAME_TAG_CONFIRM_ON_PLAYING = 'RENAME_TAG_CONFIRM_ON_PLAYING'
  /**
   * 录音机-录音列表界面-左滑文件
   */
  public static readonly RECORD_SWIPE_OPEN = 'RECORD_SWIPE_OPEN'
  /**
   * 录音列表界面-左滑文件-分享
   */
  public static readonly SWIPE_SHARE = 'SWIPE_SHARE'
  /**
   * 录音列表界面-左滑文件-删除
   */
  public static readonly SWIPE_DELETE = 'SWIPE_DELETE'
  /**
   * 录音列表界面-左滑文件-确认删除
   */
  public static readonly SWIPE_DELETE_CONFIRM = 'SWIPE_DELETE_CONFIRM'
  /**
   * 播放模式-关闭扬声器（听筒模式）
   */
  public static readonly HANDSET_MODE = 'HANDSET_MODE'
  /**
   * 通话录音列表-播放
   */
  public static readonly PLAY_CALL_RECORD = 'PLAY_CALL_RECORD'
  /**
   * 通话录音列表-暂停
   */
  public static readonly PAUSE_PLAY_CALL_RECORD = 'PAUSE_PLAY_CALL_RECORD'
  /**
   * 通话录音列表-播放时拖动进度
   */
  public static readonly DRAG_SEEKBAR_PLAY_CALL_RECORD = 'DRAG_SEEKBAR_PLAY_CALL_RECORD'
  /**
   * 列表/播放-切换扬声器模式:开/关
   */
  public static readonly SPEAKER_SWITCH = 'SPEAKER_SWITCH'
  /**
   * 播放录音界面-跳过静音
   */
  public static readonly SKIP_MUTE = 'SKIP_MUTE'
  /**
   * 播放录音界面-拖动波形图
   */
  public static readonly MOVE_WAVE_AND_SEEK = 'MOVE_WAVE_AND_SEEK'
  /**
   * 通话录音列表-点击通话录音入口条目
   */
  public static readonly CLICK_CALL_RECORD_ENTRANCE = 'CLICK_CALL_RECORD_ENTRANCE'
}

interface IParams {
  PNAMEID: string,
  PVERSIONID: string,
  VALUE?: string | number,
  DURATION?: string | number,
  DELETE?: string | number,
}

export class HiAppEventUtil {
  private static readonly RECORDER_DOMAIN: string = 'recorder_ue';
  private static readonly PNAMEID: string = 'com.ohos.soundrecorder';
  private static PVERSIONID: string = ''

  public static eventDotting(eventName: string, value?: string | number | null,
                             duration?: string | number | null,
                             deleteStr?: string | number | null,
                             saveMark?: string | number) {
    if (!HiAppEventUtil.PVERSIONID) {
      HiAppEventUtil.getApplicationVersion();
    }
    let params: IParams = {
      PNAMEID: HiAppEventUtil.PNAMEID,
      PVERSIONID: HiAppEventUtil.PVERSIONID
    }
    value && (params.VALUE = value);
    duration && (params.DURATION = duration);
    deleteStr && (params.DELETE = deleteStr);
    saveMark && (params.DELETE = saveMark);
    hilog.info(0x0000, 'params', JSON.stringify(params))
    HiAppEventUtil.reportEvent(eventName, params);
  }

  private static reportEvent(name: string, params: object): void {
    hiAppEvent.write({
      domain: HiAppEventUtil.RECORDER_DOMAIN,
      name,
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params
    }).then(() => {
      hilog.info(0x0000, 'testTag', `HiAppEvent success to write event`)
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', `HiAppEvent err.code: ${err.code}, err.message: ${err.message}`)
    })
  }

  public static getApplicationVersion() {
    let bundleFlag = bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT;
    try {
      bundleManager.getBundleInfoForSelf(bundleFlag, (error, data) => {
        if (error) {
          LogUtil.error(TAG + ` getBundleInfoForSelf failed', message: ${error.message}`);
        } else {
          LogUtil.info(TAG + ` getBundleInfoForSelf successfully', name: ${data.name}
          versionName: ${data.versionName}`);
          HiAppEventUtil.PVERSIONID = data?.versionName;
        }
      });
    } catch (err) {
      let message = (err as BusinessError).message;
      LogUtil.error(TAG + ` getBundleInfoForSelf failed: %{public}s', message: ${message}`);
    }
  }
}