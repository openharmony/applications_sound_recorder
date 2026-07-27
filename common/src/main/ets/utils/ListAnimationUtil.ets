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
import { CommonConstants } from '../constants/CommonConstants';
import { LazyDataSource, RecordData } from '../model/RecordData';
import { LogUtil } from './LogUtil';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';

const TAG = 'SoundRecorder_AnimationUtil';

export class ListAnimationUtil {
  /**
   * 例如：
   * 1
   * 2
   * 3
   * 4
   * 5
   * 删除2和4，则3要上移一个item的高度，5要上移2个item的高度
   *
   * @param recordDataGroupList 录音分组列表
   * @param deletedItems 待删除的录音记录
   * @param screenHeight 屏幕高度
   */
  /* instrument ignore next */
  public static deleteAnimation(recordDataList: LazyDataSource<RecordData>, deletedItems: RecordData[],
    deletedItemsIndex: number[], screenHeight: number): void {
    LogUtil.info(TAG + ' deleteAnimation start.');

    // 删除之前通话录音和普通录音总条数
    let translateItems: number[] = ListAnimationUtil.getTranslateItems(recordDataList, deletedItems, deletedItemsIndex);

    let translateCount = Math.ceil(px2vp(screenHeight) / (deletedItems[0].itemHeight + 12));
    LogUtil.info(TAG + ' screenHeight: ' + screenHeight + ' translate item count: ' + translateCount);
    hiTraceMeter.startTrace('deleteAnimation', 1);

    for (let i = 0; i < translateItems.length; i++) {
      const element: RecordData = recordDataList.getData(translateItems[i]);
      // 为了避免大量的item执行移动动效，导致删除卡死，应用app_freeze，只对屏幕高度范围内的item执行删除动画，剩余的直接移动，不做动画
      if (i < translateCount) {
        animateTo({
          curve: Curve.Friction,
          duration: CommonConstants.DURATION_350,
          delay: (translateItems[i] - translateItems[0]) * CommonConstants.LIST_ITEM_ANIMATION_DELAY
        }, () => {
          element.offsetY = 0;
        });
      } else {
        element.offsetY = 0;
      }
    }
    hiTraceMeter.finishTrace('deleteAnimation', 1);
  }

  private static getTranslateItems(recordDataList: LazyDataSource<RecordData>, deletedItems: RecordData[],
    deletedItemsIndex: number[]): number[] {
    let translateItems: number[] = [];
    for (let i = 0; i < deletedItems.length; i++) {
      // deletedItems[i]是要被删除的item，那么需要移动的item就是从deletedItems[i]的下一个开始算起
      let start = deletedItemsIndex[i];

      // 考虑到一次可能删除多条录音记录，那么每条录音记录移动的距离就跟它前面删除的item的个数有关
      // 例如：1，2，3，4，5; 删除2和4，那么3要移动一个item的高度，5则要移动2个item的高度
      let end: number = 0;
      if (i + 1 < deletedItems.length) {
        end = deletedItemsIndex[i + 1];
      } else {
        end = recordDataList.totalCount();
      }

      LogUtil.info(TAG + ' deleteAnimation start: ' + start + ' end: ' + end);
      // start到end之间的item，需要移动i + 1个item的高度，需要移动的item的索引保存到translateItems数组中
      for (let j = start; j < end; j++) {
        let recordData: RecordData = recordDataList.getData(j);
        recordData.offsetY = recordData.itemHeight * (i + 1) + 12;
        translateItems.push(j);
      }
    }
    return translateItems;
  }
}