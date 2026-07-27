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
import { Permissions } from '@ohos.abilityAccessCtrl';

/**
 * Common constants.
 */
export class CommonConstants {
  /**
   * State of player or recorder.
   */
  public static readonly IDLE: string = 'idle';
  public static readonly INITIALIZED: string = 'initialized';
  public static readonly PREPARED: string = 'prepared';
  public static readonly PLAYING: string = 'playing';
  public static readonly PAUSED: string = 'paused';
  public static readonly COMPLETED: string = 'completed';
  public static readonly STARTED: string = 'started';
  public static readonly STOPPED: string = 'stopped';
  public static readonly RELEASED: string = 'released';
  public static readonly ERROR: string = 'error';
  /**
   * Config of recorder.
   */
  public static readonly BIT_RATE: number = 48000;
  public static readonly CHANNEL: number = 2;
  public static readonly SAMPLE_RATE: number = 48000;
  public static readonly LATITUDE: number = 30;
  public static readonly LONGITUDE: number = 130;
  /**
   * Constants of time.
   */
  public static readonly TIME_10: number = 10;
  public static readonly TIME_60: number = 60;
  public static readonly TIME_100: number = 100;
  public static readonly TIME_180: number = 180;
  public static readonly TIME_300: number = 300;
  public static readonly TIME_600: number = 600;
  public static readonly TIME_800: number = 800;
  public static readonly TIME_1000: number = 1000;
  public static readonly TIME_3600: number = 3600;
  public static readonly TIME_60000: number = 60000;
  public static readonly TIME_600000: number = 600000;
  public static readonly NUMBER_2: number = 2;
  public static readonly NUMBER_3: number = 3;
  public static readonly STRING_0: string = '0';
  public static readonly STRING_SLASH: string = '/';
  public static readonly STRING_COLON: string = ':';
  public static readonly STRING_COLON_0: string = ':0';
  public static readonly STRING_TIME: string = '00:00:00';
  //拼音转换的连接符
  public static readonly SPELL_SEPARATE: string = '*';
  //空字符串
  public static readonly EMPTY_STR: string = '';
  //全拼类型
  public static readonly FULL_SPELL: string = 'full_spell';
  //首字母类型
  public static readonly INITIAL: string = 'initial';
  //匹配类型-全拼
  public static readonly PHONETIC_MATCH: string = '0';
  //匹配类型-首字母
  public static readonly INITIALS_MATCH: string = '1';
  //匹配类型-模糊
  public static readonly LIKE_MATCH: string = '2';
  /**
   * Initial value of time scale.
   */
  public static readonly TIME_SCALE: Array<string> = ['00:00', '00:01', '00:02', '00:03', '00:04'];
  /**
   * Constants of checking permissions.
   */
  public static readonly NUMBER_5: number = 5;
  public static readonly TITLE: string = '警告';
  public static readonly MESSAGE: string = '没有权限，请自行去<设置>添加权限';
  /**
   * Size of components.
   */
  public static readonly FULL_SIZE: string = '100%';
  public static readonly POSITION_X: string = '50%';
  public static readonly POSITION_Y: string = '90%';
  public static readonly ICON_POSITION_X: string = '75%';
  public static readonly ICON_POSITION_Y: string = '92%';
  public static readonly TIME_SLIDER_WIDTH: string = '20%';
  public static readonly TIME_SLIDER_IMAGE_WIDTH: string = '120%';
  public static readonly INIT_TRANSLATE: string = '0%';
  public static readonly TRANSLATE_TEXT: string = '20%'; //
  public static readonly TRANSLATE_IMAGE: string = '16.6%'; //

  public static readonly DEFAULT_LONG_PRESS_TIME: number = 500;

  public static readonly SIZE_PER_MINUTE: number = 2.6 // 每分钟录制音频大小，包括音频文件，缓存，数据库等 2.6M
  public static readonly SIXTY_MINUTE: number = 60 // 可录制小于一小时时提示
  public static readonly THIRTY_MINUTE: number = 30 // 限制录音时间

  public static readonly CALL_RECORD_URI_PREFIX = 'file://';
  public static readonly CALL_RECORD_URI_PREFIX_GROUP = '/data/storage/el2/group';

  public static readonly DEFAULT_HIGHLIGHT_INDEX : number = -1;
  public static readonly STORAGE_2GB_TO_B: number = 2147483648;
  public static readonly darkModeLight: number = 1;
  public static readonly darkModeGray: number = 0;
  public static readonly maxFileNumbers: number = 10000;

  public static readonly CALL_RECORD = 0;
  public static readonly NORMAL_RECORD = 1;

  /**
   * Call state
   */
  public static readonly CALL_STATE_BEFORE_IN_CALL: number = 9;
  public static readonly CALL_STATE_DISCONNECTED: number = 6;

  /**
   * Play speed
   */
  public static readonly SPEED_FORWARD_0_50_X: number = 5;
  public static readonly SPEED_FORWARD_1_00_X: number = 1;
  public static readonly SPEED_FORWARD_1_50_X: number = 6;
  public static readonly SPEED_FORWARD_2_00_X: number = 4;

  /**
   * Duration
   */
  public static readonly DURATION_350: number = 350;
  public static readonly DURATION_300: number = 300;

  // AvRecorder从 PREPARED 到 STARTED 的起步延迟
  public static readonly RECORDER_PREPARED_TO_STARTED_DELAY: number = 130;
  // AvRecorder从 PAUSE 到 STARTED 的起步延迟
  public static readonly RECORDER_PAUSE_TO_STARTED_DELAY: number = 90;
  //保存当前倍速，可用于状态恢复
  public static readonly CURRENT_SPEED: string = 'current_speed';
  //保存当前选中的录音item，可用于状态恢复
  public static readonly CURRENT_FOCUS_RECORD: string = 'current_focus_record';

  /**
   * 标记播放详情界面是否显示（用于PC热启动后，判断是否可向播放界面发送事件）
   */
  public static readonly STORAGE_PLAY_PAGE_APPEAR: string = 'play_page_appear';

  /**
   * AvPlayer从开始播放到收到时间变化的误差值，小于该误差值则任务AvPlayer已经从头播放，进度条与波形图需从0开始
   */
  public static readonly DEVIATION_FOR_AV_PLAYER_START: number = 200;

  /**
   * System text size magnification times
   */
  public static readonly TEXT_SIZE_SMALL: number = 0.85;
  public static readonly TEXT_SIZE_NORMAL: number = 1;
  public static readonly TEXT_SIZE_LARGE: number = 1.15;
  public static readonly TEXT_SIZE_EXTRA_LARGE: number = 1.3;
  public static readonly TEXT_SIZE_HUGE: number = 1.45;
  public static readonly TEXT_SIZE_HUGE_LEVEL2: number = 1.75;
  public static readonly TEXT_SIZE_HUGE_LEVEL3: number = 2;
  public static readonly TEXT_SIZE_HUGE_LEVEL4: number = 3.2;

  /**
   * 基于不同的宽度，列表会有不同的左右margin
   */
  public static readonly NAV_WIDTH_SMALL: number = 600;
  public static readonly NAV_WIDTH_MEDIUM: number = 840;
  public static readonly NAV_WIDTH_LARGE: number = 1440;

  /**
   * 双到单克隆
   */
  public static readonly DOUBLE_TO_SINGLE_CLONE = '99.99.99.999';

  /**
   * 双到单升级
   */
  public static readonly DOUBLE_TO_SINGLE_UPDATE = '0.0.0.0';

  /**
   * 删除元素动效参数
   */
  public static readonly SCALING_RATIO_PERCENT_75 = 0.75;
  public static readonly SCALING_RATIO_PERCENT_85 = 0.85;
  public static readonly OFFSET_AMOUNT_30 = 30;

  public static readonly OFFSET_AMOUNT_20 = 20;

  public static readonly COORDINATE_OF_TRANSFORMATION_CENTER_0 = 0;

  public static readonly LIST_ITEM_ANIMATION_DELAY = 16.67;

  public static readonly LIST_SELECTED_ITEM_ANIMATION_DURATION = 300;

  /**
   * 操作返回状态码
   */
  public static readonly SUCCESS: number = 1;
  public static readonly FAILURE: number = 0;

  /**
   * 回收站参数
   */
  public static readonly RECYCLE_DAYS_LIMIT: number = 30;
  /**
   * search status
   */
  //非搜索状态
  public static readonly NOT_SEARCH: number = 0;
  //搜索结果为空
  public static readonly SEARCH_RESULTS_EMPTY: number = 1;
  //有搜索结果
  public static readonly HAS_SEARCH_RESULTS: number = 2;
  /**
   * update search result flag
   */
  public static readonly DELETE: string = 'delete';
  public static readonly UPDATE: string = 'update';

  public static readonly ZERO: number = 0;
  public static readonly ONE: number = 1;
  public static readonly TWO: number = 2;
  public static readonly THREE: number = 3;
  public static readonly FOUR: number = 4;
  public static readonly FIVE: number = 5;
  public static readonly SIX: number = 6;
  public static readonly SEVEN: number = 7;
  public static readonly EIGHT: number = 8;
  public static readonly NINE: number = 9;
  public static readonly TEN: number = 10;
  public static readonly ONE_HUNDRED: number = 100;
  public static readonly ONE_THOUSAND: number = 1000;
  public static readonly TEN_THOUSAND: number = 10000;
  //双框架（-1转写失败,2转写中，3转写成功） 对应单框架（0转写失败,1转写中,2转成写成功）
  public static readonly STATE_DOUBLE_FAIL: number = -1;
  public static readonly STATE_DOUBLE_TRANSLATING: number = 2;
  public static readonly STATE_DOUBLE_SUCCESS: number = 3;
  public static readonly STATE_SINGLE_FAIL: number = 0;
  public static readonly STATE_SINGLE_TRANSLATING: number = 1;
  public static readonly STATE_SINGLE_SUCCESS: number = 2;

  //小艺语音转文本中间需要第24位需要加冒号
  public static readonly CIPHER_TEXT: string = ':';
  //小艺语音转文本中间需要第24位需要加冒号
  public static readonly CIPHER_24TH: number = 24;
  public static readonly SPEAKER_BG_COLOR: string = 'app.color.speaker_background_';
  public static readonly SPEAKER_CIRCLE_COLOR: string = 'app.color.speaker_circle_';

  //显示状态
  public static readonly SCREEN_FULL:string = 'screen_full';
  public static readonly SCREEN_ONE_THREE: string = 'screen_one_three';
  public static readonly SCREEN_HALF: string = 'screen_half';
  public static readonly SCREEN_TWO_THREE: string = 'screen_two_three';
  public static readonly SCREEN_WIDTH_FULL: string = 'screen_width_full';
  public static readonly SCREEN_WIDTH_HALF: string = 'screen_width_half';

  //登录状态
  public static readonly NOT_LOGIN: number = 0;
  public static readonly LOGIN: number = 1;
  public static readonly LOGIN_DEFAULT_VALUE: number = 2;

  //弹框文字提示，删除/恢复
  public static readonly DIALOG_DELETING: string = 'deleting_dialog';
  public static readonly DIALOG_RECOVERING: string = 'recovering_dialog';

  // 通话录音更新接口数据大小限制
  public static readonly CALL_RECORD_UPDATA_MAX: number = 1000;

  // pad 显示缩放大小
  public static readonly PAD_DISPLAY_SIZE_SCALE_NORMAL: number = 1;
  public static readonly PAD_DISPLAY_SIZE_SCALE_LARGER: number = 2;

  //标记
  public static readonly MARK_BASE: string = 'Tag';
  public static readonly MARK_BO: string = 'རྟགས་འགོད།';
  public static readonly MARK_UG: string = 'بەلگە';
  public static readonly MARK_CN: string = '标记';
  public static readonly MARK_HK_TW: string = '標記';
  public static readonly MARK_ZX: string = '[TS_882680]_Tag';

  // 路径前缀
  public static readonly LOCAL_URI_PREFIX: string = '/storage/Users/currentUser/appdata';
  public static readonly SANDBOX_PREFIX: string = 'data/storage/';
  public static readonly BUNDLE_NAME: string = 'com.ohos.soundrecorder';

  public static readonly XIAOYI_BUNDLE = 'com.hmos.vassistant';

  // 转写状态
  public static readonly TRANS_NOT_START = 0;
  public static readonly TRANS_PROCESSING = 1;
  public static readonly TRANS_DONE = 2;
  public static readonly TRANS_DONE_IN_DOUBLE_FRAME = 3;

  // 转写错误码
  public static readonly TRANS_ERROR_HTTP = 10911;
  public static readonly TRANS_ERROR_INVALID_ARGUMENT = 13900020;

  //是否是三折叠设备
  public static readonly IS_TRIPLE_FOLD_DEVICE: string = 'is_triple_fold_device';

  // pc显示
  public static readonly WIN_SIDE_BAR_WIDTH: string = 'sideBarWidth';
  public static readonly WIN_NAV_BAR_WIDTH: string = 'navBarWidth';

  /**
   * 迁移弹窗dfx打点value值
   */
  public static readonly CONFIRM: number = 1;
  public static readonly CANCEL: number = 0;

  /**
   * 迁移dfx打点:开始 0 结束 1
   */
  public static readonly START: number = 0;
  public static readonly FINISH: number = 1;

  /**
   * 迁移dfx打点完成率：100%：Y，非100%：N
   */
  public static readonly COMPLETION_STATUS_Y: string = 'Y';
  public static readonly COMPLETION_STATUS_N: string = 'N';

  /**
   * 隐私空间录音文件迁移打点枚举
   */
  public static readonly MIGRATION_SUCCESS: number = 0;
  public static readonly MIGRATION_FAILED: number = 1;
  public static readonly MIGRATION_DUPLICATE: number = 2;
  public static readonly MIGRATION_SOUND_RECORDER: number = 1;
  public static readonly MIGRATION_CALL_RECORDER: number = 2;
  public static readonly MIGRATION_V_ASSISTANT: number = 2;

  /**
   * want.param关键字
   */
  public static readonly CALLER_ABILITY_NAME: string = 'ohos.aafwk.param.callerAbilityName';
  public static readonly CALLER_BUNDLE_NAME: string = 'ohos.aafwk.param.callerBundleName';
  public static readonly CALLER_APP_IDENTIFIER: string = 'ohos.aafwk.param.callerAppIdentifier';

  // 联系人ability名称
  public static readonly ABILITY_NAME_CONTACTS: string = 'com.ohos.contacts.MainAbility';
  // 小艺bundle名称
  public static readonly BUNDLE_NAME_VASSISTANT: string = '';
  // 桌面bundle名称
  public static readonly BUNDLE_NAME_SCENEBOARD: string = 'com.ohos.sceneboard';
  // 音频管家bundle名称
  public static readonly BUNDLE_NAME_AUDIOACCESSORYMANAGER: string = '';

  // 联系人appIdentifier
  public static readonly CONTACTS_APP_IDENTIFIER: string = '5765880207853624761';
  // 小艺appIdentifier
  public static readonly VASSISTANT_APP_IDENTIFIER: string = '';
  // 音频管家appIdentifier
  public static readonly AUDIO_ACCESSORY_APP_IDENTIFIER: string = '';

  /**
   * RPC code
   */
  public static readonly SOUND_RECORDER_SERVICE_KEY: string = 'SoundRecorderServiceKey';
  public static readonly TOKEN_ERROR_CODE: number = 401;
  public static readonly TOKEN_ERROR_MESSAGE: string = 'token error';

  /**
   * 转文本接收事件
   */
  public static readonly TRANSCRIPTION_RESULT: string = 'transcription.result';
  public static readonly TRANSCRIPTION_PROCESSING: string = 'transcription.processing';
  public static readonly TRANSCRIPTION_SUMMARY_START: string = 'transcription.summary.start';
  public static readonly TRANSCRIPTION_RESULT_RETRANS: string = 'transcription.result.retrans';
  public static readonly SUMMARY_AUTO_ADD: string = 'summary.auto.add';
  public static readonly SUMMARY_DELETE: string = 'summary.delete';
  public static readonly SUMMARY_ADDORIGINAL_RESULT: string = 'summary.addOriginal.result';
  public static readonly TRANSCRIPTION_TEXT_JUMP: string = 'transcription.text.jump';

  /**
   * 长时设置能效资源的参数
   */
  public static readonly PERMANENT_TIMEOUT_VALUE: number = 0;

  /*
   * 未完整转写标记
   */
  public static readonly INCOMPLETE_VALUE: number = 1;
}