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
import { call } from '@kit.TelephonyKit';
import { DeviceUtil, HiSysEventName, HiSysEventUtil, Preferences, PreferencesUtil } from '@ohos/common';
import { RecordData } from '@ohos/common/src/main/ets/model/RecordData';
import { Configuration, curves } from '@kit.ArkUI';


const TAG = 'SoundRecorder_SideBarPage';

export enum SideBarMode {
  ALL_RECORDINGS,
  CALL_RECORDINGS,
  AUDIO_RECORDINGS,
  RECENT_DELETE_RECORDINGS
}

export const sideBarModeToNameMap = [
  $r('app.string.all_recordings'),
  $r('app.string.call_recording'),
  $r('app.string.audio_recordings'),
  $r('app.string.recent_delete')
]

@Component
export struct SideBarComponent {
  @Consume allRecordingCount: number;
  @Consume callRecordingCount: number;
  @Consume recordingCount: number;
  @Consume sideFolderName: String;
  @Consume isShowOverlay: boolean; // 蒙层是否显示
  @Consume isShowSideBar: boolean; // 侧边栏是否显示
  @Consume sideFolderNameFlag: number;
  @Consume recentDeleteRecordingCount: number;
  @Consume headsetRecordingCount: number;
  @StorageProp('statusBarHeight') statusBarHeight: number = 0;
  @StorageProp('currentBreakpoint') curBp: string = 'sm';
  @StorageProp('isDarkMode') isDarkMode: boolean = false;
  @StorageLink('isEditMode') isEditMode: boolean = false;
  @StorageLink('windowFocused') isWindowFocused: boolean = true;
  @Consume selectedRecordList: RecordData[];
  @StorageProp(Preferences.IS_USE_HEADSET_SYNC) isUseHeadsetSync: boolean = false;

  /* instrument ignore next */
  clickSideBar() {

  }

  /* instrument ignore next */
  async aboutToAppear(): Promise<void> {
    getContext().eventHub.on('clickSideBarButton', this.clickSideBar);
    this.isUseHeadsetSync = await PreferencesUtil.get(Preferences.IS_USE_HEADSET_SYNC, false) as boolean;
    AppStorage.setOrCreate(Preferences.IS_USE_HEADSET_SYNC, this.isUseHeadsetSync);
  }

  /* instrument ignore next */
  aboutToDisappear(): void {
    getContext().eventHub.off('clickSideBarButton', this.clickSideBar);
  }

  /* instrument ignore next */
  sideCloseAnimateTo() {
    if (this.curBp === 'lg') {
      return;
    }
    animateTo({
      curve: curves.cubicBezierCurve(0.2, 0.2, 0.1, 1),
      duration: 500,
    }, () => {
      this.isShowSideBar = false;
      this.isShowOverlay = false;
    })
  }

  checkedSelected(): string {
    let buttonName = '';
    if (this.sideFolderNameFlag === SideBarMode.ALL_RECORDINGS) {
      buttonName = getContext(this).resourceManager.getStringSync($r('app.string.all_recordings'));
    } else if (this.sideFolderNameFlag === SideBarMode.CALL_RECORDINGS) {
      buttonName = getContext(this).resourceManager.getStringSync($r('app.string.call_recording'));
    } else if (this.sideFolderNameFlag === SideBarMode.AUDIO_RECORDINGS) {
      buttonName = getContext(this).resourceManager.getStringSync($r('app.string.audio_recordings'));
    } else {
      buttonName = getContext(this).resourceManager.getStringSync($r('app.string.recent_delete'));
    }
    return buttonName;
  }

  @Builder
  IconBuilder(type: SideBarMode, icon: Resource) {
    Column() {
      SymbolGlyph(icon)
        .fontSize('24vp')
        .fontColor([type === this.sideFolderNameFlag ? $r('sys.color.icon_primary') :
          $r('sys.color.icon_secondary')])
    }
    .width(24)
    .height(24)
  }

  exitMultipleSelect() {
    if (this.isEditMode) {
      this.selectedRecordList = [];
      this.isEditMode = false;
      AppStorage.setAndLink('isEditMode', this.isEditMode);
    }
  }

  private processClickEvent(resource: Resource, flag: number, eventName: string) {
    this.exitMultipleSelect();
    this.sideFolderName = getContext(this).resourceManager.getStringSync(resource);
    this.sideFolderNameFlag = flag;
    this.sideCloseAnimateTo();
    HiSysEventUtil.eventDotting(eventName);
  }

  /* instrument ignore next */
  build() {
    Column() {
      Scroll(new Scroller()) {
        Column({ space: DeviceUtil.isPC() ? 2 : 4 }) {
          if (!DeviceUtil.isPC()) {
            Column() {
              SideBarButton({
                iconBuilderParam: () => {
                  this.IconBuilder(SideBarMode.ALL_RECORDINGS, $r('sys.symbol.waveform_1'))
                },
                buttonName: $r('app.string.all_recordings'),
                sideFolderButtonCount: this.allRecordingCount
              })
            }
            .onClick((event: ClickEvent) => {
              this.processClickEvent($r('app.string.all_recordings'), SideBarMode.ALL_RECORDINGS,
                HiSysEventName.NAV_ENTER_MAIN);
            })
            .accessibilitySelected(this.checkedSelected() ===
              getContext(this).resourceManager.getStringSync($r('app.string.all_recordings')))
            .onAccessibilityActionIntercept((action: AccessibilityAction) => {
              if (action === AccessibilityAction.ACCESSIBILITY_CLICK) {
                this.processClickEvent($r('app.string.all_recordings'), SideBarMode.ALL_RECORDINGS,
                  HiSysEventName.NAV_ENTER_MAIN);
                return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
              } else {
                return AccessibilityActionInterceptResult.ACTION_CONTINUE;
              }
            })
          }

          Column() {
            SideBarButton({
              iconBuilderParam: () => {
                this.IconBuilder(SideBarMode.AUDIO_RECORDINGS, $r('sys.symbol.recordingtape_rectangle'))
              },
              buttonName: $r('app.string.audio_recordings'),
              sideFolderButtonCount: this.recordingCount
            })
          }
          .onClick((event: ClickEvent) => {
            this.processClickEvent($r('app.string.audio_recordings'), SideBarMode.AUDIO_RECORDINGS,
              HiSysEventName.NAV_ENTER_MAIN);
          })
          .accessibilitySelected(this.checkedSelected() ===
            getContext(this).resourceManager.getStringSync($r('app.string.audio_recordings')))
          .onAccessibilityActionIntercept((action: AccessibilityAction) => {
            if (action === AccessibilityAction.ACCESSIBILITY_CLICK) {
              this.processClickEvent($r('app.string.audio_recordings'), SideBarMode.AUDIO_RECORDINGS,
                HiSysEventName.NAV_ENTER_MAIN);
              return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
            } else {
              return AccessibilityActionInterceptResult.ACTION_CONTINUE;
            }
          })

          // 有通话功能才显示通话录音
          if (call.hasVoiceCapability()) {
            Column() {
              SideBarButton({
                iconBuilderParam: () => {
                  this.IconBuilder(SideBarMode.CALL_RECORDINGS, $r('sys.symbol.phone'))
                },
                buttonName: $r('app.string.call_recording'),
                sideFolderButtonCount: this.callRecordingCount
              })
            }
            .onClick((event: ClickEvent) => {
              this.processClickEvent($r('app.string.call_recording'), SideBarMode.CALL_RECORDINGS,
                HiSysEventName.NAV_ENTER_CALL);
            })
            .accessibilitySelected(this.checkedSelected() ===
              getContext(this).resourceManager.getStringSync($r('app.string.call_recording')))
            .onAccessibilityActionIntercept((action: AccessibilityAction) => {
              if (action === AccessibilityAction.ACCESSIBILITY_CLICK) {
                this.processClickEvent($r('app.string.call_recording'), SideBarMode.CALL_RECORDINGS,
                  HiSysEventName.NAV_ENTER_CALL);
                return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
              } else {
                return AccessibilityActionInterceptResult.ACTION_CONTINUE;
              }
            })
          }


          Column() {
            SideBarButton({
              iconBuilderParam: () => {
                this.IconBuilder(SideBarMode.RECENT_DELETE_RECORDINGS, $r('sys.symbol.trash'))
              },
              buttonName: $r('app.string.recent_delete'),
              sideFolderButtonCount: this.recentDeleteRecordingCount
            })
          }
          .onClick((event: ClickEvent) => {
            this.processClickEvent($r('app.string.recent_delete'), SideBarMode.RECENT_DELETE_RECORDINGS,
              HiSysEventName.NAV_ENTER_DEL);
          })
          .accessibilitySelected(this.checkedSelected() ===
            getContext(this).resourceManager.getStringSync($r('app.string.recent_delete')))
          .onAccessibilityActionIntercept((action: AccessibilityAction) => {
            if (action === AccessibilityAction.ACCESSIBILITY_CLICK) {
              this.processClickEvent($r('app.string.recent_delete'), SideBarMode.RECENT_DELETE_RECORDINGS,
                HiSysEventName.NAV_ENTER_DEL);
              return AccessibilityActionInterceptResult.ACTION_INTERCEPT;
            } else {
              return AccessibilityActionInterceptResult.ACTION_CONTINUE;
            }
          })
        }
        .justifyContent(FlexAlign.Start)
        .height('100%')
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
      .edgeEffect(EdgeEffect.Spring)
      .height('100%')
    }
    .padding({
      top: 72 + this.statusBarHeight, left: DeviceUtil.isPC() && !this.isShowSideBar ? 0 : 16,
      right: DeviceUtil.isPC() && !this.isShowSideBar ? 0 : 16
    })
    .backgroundColor(!this.isWindowFocused ? $r('sys.color.background_tertiary') :
      this.isDarkMode ? $r('sys.color.ohos_id_color_panel_bg') :
        $r('sys.color.ohos_id_color_sub_background'))
    .height('100%')
    .width('100%')
    .useEffect(DeviceUtil.isPC(), 1)
  }
}

@Component
struct SideBarButton {
  @Prop buttonName: Resource;
  @Prop sideFolderButtonCount: number;

  @Builder
  iconBuilder() {
  };

  @BuilderParam iconBuilderParam: () => void = this.iconBuilder;
  @Consume sideFolderName: String;

  build() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      Flex({
        direction: FlexDirection.Row,
        alignItems: ItemAlign.Center,
        wrap: FlexWrap.NoWrap,
        justifyContent: FlexAlign.SpaceBetween
      }) {
        Column() {
          this.iconBuilderParam()
        }
        .width(24)
        .height(24)
        .margin({
          left: $r('app.float.distance_8'),
          right: $r('app.float.distance_8')
        })

        Row() {
          Text(this.buttonName)
            .fontSize(16)
            .maxFontScale(1)
            .fontWeight(getContext(this).resourceManager.getStringSync(this.buttonName) === this.sideFolderName ?
              FontWeight.Bold : FontWeight.Medium)
            .fontColor($r('sys.color.font_primary'))
            .lineHeight(21)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .maxLines(1)
            .width('calc(100% - 64vp)')
          Text(`${this.sideFolderButtonCount}`)
            .maxLines(1)
            .fontSize(14)
            .maxFontScale(1)
            .fontWeight(FontWeight.Regular)
            .textAlign(TextAlign.End)
            .lineHeight(19)
            .fontFeature('\"ss01\" on')
            .width(64)
            .accessibilityText(getContext().resourceManager
              .getPluralStringValueSync($r('app.plural.count_list_info_two').id, this.sideFolderButtonCount))
        }
        .justifyContent(FlexAlign.SpaceBetween)
        .width('calc(100% - 40vp)')
      }
      .width('100%')
      .padding({
        top: DeviceUtil.isPC() ? 8 : 12,
        bottom: DeviceUtil.isPC() ? 8 : 12,
        left: Configuration.getLocale().dir === 'ltr' ? 0 : 8,
        right: Configuration.getLocale().dir === 'ltr' ? 8 : 0
      })
    }
    .backgroundColor(this.getBgColor())
    .width('100%')
    .borderRadius(DeviceUtil.isTripleFold() ? 16 : $r('sys.float.corner_radius_level4'))
    .padding(0)
  }

  getBgColor() {
    return getContext(this).resourceManager.getStringSync(this.buttonName) === this.sideFolderName ?
      $r('app.color.side_bar_item_background_selected') : Color.Transparent;
  }
}