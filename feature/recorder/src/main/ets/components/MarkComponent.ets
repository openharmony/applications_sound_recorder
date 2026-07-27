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

import { AccessibilityUtil, Util } from '@ohos/common/src/main/ets/utils/Util'
import DatabaseManager from '@ohos/common/src/main/ets/utils/DatabaseManager'
import relationalStore from '@ohos.data.relationalStore'
import I18n from '@ohos.i18n'
import {
  CommonConstants,
  DeviceUtil,
  HiSysEventName,
  HiSysEventUtil,
  LogUtil,
  MarkData,
  RenameDialogComponent
} from '@ohos/common'
import { PlayManager } from '../controller/PlayManager'
import { BusinessError } from '@kit.BasicServicesKit'
import { JSON } from '@kit.ArkTS'
import { SideBarMode } from './SideBarComponent'
import { Configuration } from '@kit.ArkUI'
import { WaveCommand } from './WaveView'
import display from '@ohos.display';
import { vibrator } from '@kit.SensorServiceKit'

const TAG = 'SoundRecorder_MarkComponent';
const MARK_NAME_MAX_LENGTH: number = 83;

@Component
export struct MarkComponent {
  private player: PlayManager = PlayManager.getInstance();
  @State isHover: boolean = false;
  private textValue: string = '';
  @Prop page: string = 'Mark'
  @ObjectLink item: MarkData;
  @Prop recordPage: String = 'play';
  @Prop isSelect: Boolean = false;
  @State isFlag: boolean = false
  @Prop state: string = '';
  @State isClickTooOften: boolean = true; // 设置标记是否可点击, 快速点击时, 最快每隔500ms才能点击一次
  @Link currentTimePlay: number;
  @StorageProp('isDarkMode') isDarkMode: boolean = false;

  @StorageLink('fontSizeScale') fontSizeScale: number = CommonConstants.TEXT_SIZE_NORMAL;
  @State textError: Resource | undefined = $r('app.string.mark_no_name');
  @State isListItemMenuShown: boolean = false;
  @Consume sideFolderNameFlag: number;
  private index: number = 0;
  @Consume waveCommand: WaveCommand;
  @StorageProp('isScreenLock') @Watch('onScreenLockChange') isScreenLock: boolean = false;
  @StorageProp('foldDisplayMode') foldDisplayMode: number = 0;

  // 标记重命名弹框
  renameDialog: CustomDialogController = new CustomDialogController({
    builder: RenameDialogComponent({
      primaryTitle: $r('app.string.file_rename'),
      contentBuilder: () => {
        this.buildRenameContent();
      },
      cancelButton: {
        value: $r('app.string.cancel'),
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          this.textValue = '';
          this.isFlag = false;
          LogUtil.info(`${TAG} Callback when the first button is clicked`);
          this.renameDialog.close();
        },
        fontColor: '#FB654E',
        background: Color.Transparent,
      },
      confirmButton: {
        value: $r('app.string.on_sure'),
        buttonStyle: ButtonStyleMode.TEXTUAL,
        action: () => {
          if (this.isFlag) {
            this.onAccept(this.textValue);
          } else {
            // 文件名不可用上报无障碍事件，播报提醒
            AccessibilityUtil.sendAnnounceAccessibilityEvent(getContext().resourceManager.getStringSync(this.textError) ?? '');
          }
        },
        fontColor: '#FB654E',
        background: Color.Transparent,
      },
    }),
    cornerRadius: DeviceUtil.isPC() ? $r('app.float.distance_16') : $r('app.float.distance_32')
  });

  // 重命名的弹框内容，即TextInput
  @Builder
  buildRenameContent(): void {
    Column() {
      TextInput({ text: this.textValue, placeholder: $r('app.string.rename_marker') })
        .id(`mark_input_${this.index}`)
        .maxLength(MARK_NAME_MAX_LENGTH)
        .backgroundColor(Color.Transparent)
        .enableKeyboardOnFocus(true)
        .defaultFocus(true)
        .showError(this.textError)
        .showUnderline(true)
        .padding({ bottom: 8, left: 12, right: 12 })
        .lineHeight(I18n.System.getSystemLanguage() === 'bo' ? 32 : -1)
        .onChange((value: string) => {
          this.validAndSetIsNum(value);
          this.textValue = value;
        })
        .onSubmit((enterKey: EnterKeyType, event: SubmitEvent) =>{
          if (enterKey === EnterKeyType.Done) {
            if (this.isFlag) {
              this.onAccept(this.textValue);
            } else {
              // 文件名不可用上报无障碍事件，播报提醒
              AccessibilityUtil.sendAnnounceAccessibilityEvent(getContext().resourceManager.getStringSync(this.textError) ?? '');
            }
          }
        })
        .caretColor($r('app.color.themed_red'))
        .selectedBackgroundColor($r('app.color.themed_red'))
    }
  }

  //重命名确认按钮调用接口
  onAccept(inputValue: string): void {
    if (this.isFlag) {
      this.item.title = inputValue;
      this.item.type = 1;
      let obj: relationalStore.ValuesBucket = {
        type: 1,
        content: this.item.title
      }
      DatabaseManager.updateTag(this.item._data, this.item.markDuration, obj);
      if (this.page === 'RecordPlayPage') {
        HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TAG_CONFIRM_ON_PLAYING);
      } else {
        HiSysEventUtil.eventDotting(HiSysEventName.SAVE_RENAME_TAG);
      }
      Util.showToast($r('app.string.renamed'), DeviceUtil.isPC());
      this.renameDialog.close()
    }
  }

  private getContentMargin(): Padding {
    if (this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL3) {
      return {
        top: 20,
        bottom: 20,
      };
    } else if (this.fontSizeScale === CommonConstants.TEXT_SIZE_HUGE_LEVEL4) {
      return {
        top: 24,
        bottom: 24,
      };
    } else {
      return {
        top: 16,
        bottom: 16,
      };
    }
  }

  private renameDialogShow() {
    this.textValue = this.item.title;
    this.isFlag = false;
    this.renameDialog.open();
    if (this.page === 'RecordingPage') {
      HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TAG);
    } else if (this.page === 'RecordPlayPage') {
      HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TAG_ON_PLAYING);
    }
  }

  private renameDialogClose() {
    this.renameDialog?.close();
  }

  aboutToAppear(): void {
    getContext().eventHub.on('renameDialogShow', this.renameDialogShow);
    getContext().eventHub.on('renameDialogClose', this.renameDialogClose.bind(this));
  }

  aboutToDisappear(): void {
    getContext().eventHub.off('renameDialogShow', this.renameDialogShow);
    getContext().eventHub.off('renameDialogClose', this.renameDialogClose.bind(this));
  }

  @Builder
  markIndex(): void {
    Button({type: ButtonType.Circle}) {
      Text(this.item.count.toString())
        .width($r('app.float.wh_value_22'))
        .height($r('app.float.wh_value_20'))
        .fontSize(DeviceUtil.isPC() ? $r('app.float.font_12_fp') :
          this.item.count >= CommonConstants.ONE_HUNDRED ? (this.item.count >= CommonConstants.ONE_THOUSAND ?
          $r('app.float.font_9') : $r('app.float.font_12')) : $r('app.float.font_14'))
        .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
        .maxLines(CommonConstants.ONE)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .fontWeight(FontWeight.Regular)
        .textAlign(TextAlign.Center)
        .fontColor(this.item.isSelect ? $r('sys.color.ohos_id_color_background')
          : $r('sys.color.ohos_id_color_text_primary'))
        .animation({curve: Curve.Sharp, duration: 200})
        .accessibilityText(getContext().resourceManager.getStringSync($r('app.string.serial_number'),
          this.item.count > 9 ? this.item.count.toString() : '0' + this.item.count))
    }
    .backgroundColor(this.item.isSelect ? $r('sys.color.ohos_id_color_spinner_icon')
      : $r('sys.color.ohos_id_color_hover'))
    .margin({
      right: $r('app.float.wh_value_6'),
      left: $r('app.float.wh_value_6')
    })
    .width($r('app.float.wh_value_28'))
    .height($r('app.float.wh_value_28'))
    .flexShrink(0)
  }

  @Builder
  markName(): void {
    Text(this.getDefaultTagName(this.item.title))
      .id(`mark_name_${this.index}`)
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .fontSize(14)
      .maxFontScale(CommonConstants.TEXT_SIZE_HUGE)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .maxLines(1)
      .flexGrow(1)
      .fontWeight(FontWeight.Medium)
      .constraintSize({
        minWidth: $r('app.float.wh_value_28'),
        maxWidth: $r('app.float.wh_value_148')
      })
      .height($r('app.float.wh_value_19'))
      .margin({
        left: Configuration.getLocale().dir === 'ltr' ? 0 : $r('app.float.margin_size_8'),
        right: Configuration.getLocale().dir === 'rtl' ? 0 : $r('app.float.margin_size_8'),
      })
      .flexShrink(1)
      .id('markNameText')
  }

  @Builder
  markTimePoint(): void {
    Text(Util.timeFormat(this.item.markDuration || 0))
      .accessibilityText(AccessibilityUtil.getDurationText(this.item.markDuration))
      .maxLines(1)
      .flexShrink(0)
      .fontColor($r('sys.color.ohos_id_color_text_primary'))
      .fontSize(24)
      .maxFontScale(CommonConstants.TEXT_SIZE_HUGE_LEVEL3)
      .fontWeight(FontWeight.Medium)
      .id('markPointTime')
      .onClick(async () => {
        LogUtil.info(`${TAG} click mark to seek. this.page : ${this.page}`);
        if (this.page === 'RecordingPage' || this.isListItemMenuShown) {
          LogUtil.info(`${TAG} RecordingPage not support seek!`);
          return;
        }
        if (this.isClickTooOften) {
          // 设置点击间隔500ms
          this.isClickTooOften = false
          this.currentTimePlay = this.item.markDuration;
          AppStorage.setOrCreate('isSeeked', true);
          PlayManager.getInstance().seek(this.item.markDuration).then((value) =>{
            LogUtil.info(TAG + ' Clicking the flag is successful.');
            HiSysEventUtil.eventDotting(HiSysEventName.PLAY_TAG, { VALUE: value });
          }).catch((err: BusinessError) =>{
            LogUtil.error(TAG + ` Failed to click the flag. code: ${err?.code}, message: ${err?.message}`);
            HiSysEventUtil.eventDotting(HiSysEventName.PLAY_TAG, { VALUE: CommonConstants.FAILURE });
          });
          const timer = setTimeout(() => {
            this.isClickTooOften = true;
            clearTimeout(timer);
          }, 500);
        }
      })
  }

  @Builder
  markListStandardLayout(): void {
    Row() {
      this.markIndex();
      Column() {
        this.markName();
      }
      .height($r('app.float.wh_value_40'))
      .justifyContent(FlexAlign.Center)
    }
    .constraintSize({
      minWidth: $r('app.float.wh_value_76'),
      maxWidth: $r('app.float.wh_value_224')
    })
    .height($r('app.float.wh_value_40'))
    .flexShrink(1)
  }

  @Builder
  listItemContextMenu() {
    Column() {
      MenuItem({ content: $r('app.string.file_rename') }).width('224vp')
        .id(`mark_rename_${this.index}`)
        .onClick(() => {
          this.isListItemMenuShown = false;
          this.textValue = this.getDefaultTagName(this.item.title);
          this.isFlag = false;
          this.renameDialog.open();
          if (this.page === 'RecordingPage') {
            HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TAG);
          } else if (this.page === 'RecordPlayPage') {
            HiSysEventUtil.eventDotting(HiSysEventName.RENAME_TAG_ON_PLAYING);
          }
        })
      MenuItem({ content: $r('app.string.delete') }).width('224vp')
        .id(`mark_delete_${this.index}`)
        .onClick(() => {
          this.isListItemMenuShown = false;
          this.waveCommand = WaveCommand.MARK;
          getContext(this)?.eventHub?.emit('deleteMark', this.item.markDuration);
        })
    }
  }

  @Styles
  pressedStyles() {
    .backgroundColor($r('sys.color.ohos_id_color_click_effect'))
    .borderRadius($r('app.float.wh_value_20'))
  }

  @Styles
  normalStyles() {
    .backgroundColor($r('sys.color.comp_background_list_card'))
    .borderRadius($r('app.float.wh_value_20'))
  }

  build() {
    Flex({
      direction: FlexDirection.Row,
      alignItems: ItemAlign.Center,
      wrap: FlexWrap.NoWrap,
      justifyContent: FlexAlign.SpaceBetween
    }) {
      this.markListStandardLayout();
    }
    .accessibilityDescription(this.getAccessibilityDesc())
    .accessibilityGroup(true, { accessibilityPreferred: true })
    .stateStyles({
      normal: this.normalStyles,
      pressed: this.pressedStyles,
    })
    .onMouse((event: MouseEvent) => {
      if (event.button === MouseButton.Left && event.action === MouseAction.Press && this.isListItemMenuShown) {
        LogUtil.info(`${TAG} Exceptions in the Display and Hidden Mark Menu`);
        // 避免显示菜单变量在点击事件时，显隐变量未重置成缺省值
        this.isListItemMenuShown = false;
      }
      if (event.button === MouseButton.Right && event.action === MouseAction.Press) {
        this.isListItemMenuShown = true;
      }
    })
    .gestureAttrs()
    .onClick(() => {
      LogUtil.info(`${TAG} click mark to seek. this.page : ${this.page}`);
      if (this.page === 'RecordingPage' || this.isListItemMenuShown) {
        LogUtil.info(`${TAG} RecordingPage not support seek!`);
        return;
      }
      this.processMarkClick();
    })
    .onAccessibilityActionIntercept((action: AccessibilityAction) => {
      if (action === AccessibilityAction.ACCESSIBILITY_CLICK) {
        if (this.page !== 'RecordingPage') {
          let broadcastContent: string =
            getContext().resourceManager.getStringSync($r('app.string.mark_position_at_talkback'));
          broadcastContent += getContext().resourceManager.getStringSync($r('app.string.serial_number'),
            this.item.count > 9 ? this.item.count.toString() + ' ' + this.getDefaultTagName(this.item.title) :
              '0' + this.item.count + ' ' + this.getDefaultTagName(this.item.title))
          AccessibilityUtil.sendAnnounceAccessibilityEvent(broadcastContent);
          this.processMarkClick();
        }
        return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
      } else {
        return AccessibilityActionInterceptResult.ACTION_CONTINUE;
      }
    })
  }

  private processMarkClick() {
    if (this.isClickTooOften) {
      // 设置点击间隔500ms
      this.isClickTooOften = false
      this.currentTimePlay = this.item.markDuration;
      this.player.seek(this.item.markDuration);
      const timer = setTimeout(() => {
        this.isClickTooOften = true;
        clearTimeout(timer);
      }, 500);
    }
  }

  private getAccessibilityDesc(): string {
    const doubleClickStr = Util.getFormatStringSync($r('app.string.accessibility_double_click'), '');
    const longPressStr = Util.getFormatStringSync($r('app.string.accessibility_long_press'), '');
    if (this.page == 'RecordingPage') {
      return `${longPressStr}`;
    } else {
      return `${doubleClickStr} ${longPressStr}`;
    }
  }

  @Styles
  gestureAttrs() {
    .parallelGesture(LongPressGesture({ repeat: false, duration: 500 })
      .onAction(async () => {
        this.isListItemMenuShown = true;
        Util.startVibration();
      }))
    .bindContextMenu(this.isListItemMenuShown, this.listItemContextMenu(), {
      placement: Placement.BottomLeft,
      onDisappear: () => {
        this.isListItemMenuShown = false;
      }
    })
  }

  // 校验重命名输入框字数并提示
  private validAndSetIsNum(value: string): void {
    this.isFlag = true;
    //校验输入框是否有内容
    if (value.length === 0) {
      this.textError = $r('app.string.mark_no_name');
      this.isFlag = false;
    } else {
      if (value.length >= MARK_NAME_MAX_LENGTH) {
        this.textError = $r('app.string.maximum_length');
      } else {
        this.textError = undefined;
      }
      //判断命名不能包含 /\:*?'<>|
      if (Util.specialCharValidator(value)) {
        this.isFlag = false;
        this.textError = $r('app.string.mark_filter');
      }
    }
  }

  // 默认标记多语言显示，重命名后显示重命名名字
  private getDefaultTagName(value: string): string {
    if (CommonConstants.MARK_BASE === value || CommonConstants.MARK_BO === value ||
      CommonConstants.MARK_UG === value || CommonConstants.MARK_CN === value ||
      CommonConstants.MARK_HK_TW === value || CommonConstants.MARK_ZX === value) {
      return getContext(this).resourceManager.getStringSync($r('app.string.mark'));
    }
    return value;
  }

  onScreenLockChange(): void {
    LogUtil.info(TAG + ' screenStateChange, isScreenLock=' + this.isScreenLock);
    if (!this.isScreenLock && DeviceUtil.isSmallFoldVer() &&
      this.foldDisplayMode === display.FoldStatus.FOLD_STATUS_FOLDED) {
      this.renameDialog.close();
    }
  }
}