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

import { MainSentenceProps, PlaceholderProps, StringData } from './types';
import { LengthMetrics } from '@ohos.arkui.node';
import ResourceManagerUtil from '../utils/ResourceManagerUtil';
import GlobalContext from '../utils/GlobalContext';


export * from './types';

/*字符串分割正则表达式*/
const splitRegexp = new RegExp('%[0-9]?\\$?[sd]');
/*字符串匹配正则表达式*/
const matchAllRegexp = new RegExp('%[0-9]?\\$?[sd]', 'g');


/**
 * TextSpan组件，Span组件需要拆分整句来实现个别字段填充和样式变换，增加翻译的复杂性，自定义TextSpan组件可对整句进行文本填充，颜色改变样式以及占位符的替换
 * @param: mainContent 主干句（整句）的资源ID
 * @param: contents 需要填充的占位符的字串信息数组
 **/
@Component
export struct TextSpan {
  //主干句资源ID
  @Prop @Watch('resourceToString') mainContent: MainSentenceProps = {
    mContent: '',
    mFontSize: 14
  };
  //占位符填充资源信息
  @Prop @Watch('resourceToString') contents: PlaceholderProps[] = [{
    placeholderContent: '',
    fontSize: 14
  }];
  @Prop lineSpacing: number = 0;
  //主干句根据占位符分割后数组
  contentStr: string[] = [];
  //占位符填充顺序数组
  @State stringIndexSum: string[] = [];

  aboutToAppear(): void {
    this.resourceToString();
  }

  /**
   * 占位符匹配
   */
  isMatched(str: string): PlaceholderProps | undefined {
    for (const placeholder of this.stringIndexSum) {
      if (placeholder === str) {
        return this.contents[this.stringIndexSum.indexOf(placeholder)];
      }
    }
    return undefined;
  }

  /**
   * 字串占位符分割匹配
   */
  resourceToString(): void {
    let context = GlobalContext.getUIAbilityContext();
    const str = ResourceManagerUtil.resourceStrToString(this.mainContent.mContent, context);
    this.contentStr = str.split(splitRegexp)
    const matches = Array.from(str.matchAll(matchAllRegexp), (m) => m[0]);
    this.stringIndexSum.splice(0, this.stringIndexSum.length);
    /*分割后的数组下标标记*/
    let index = 1;
    matches.forEach((match) => {
      this.stringIndexSum.push(match);
      this.contentStr.splice(index, 0, match);
      index += 2;
      this.stringIndexSum = this.stringIndexSum.sort((a, b) => parseInt(a.substring(1, a.length - 1)) -
      parseInt(b.substring(1, b.length - 1)));
    });
  }

  /**
   * Span文本容器
   */
  @Builder
  splitSpan($$: StringData) {
    if ($$.placeholder) {
      Span($$.placeholder.placeholderContent)
        .fontWeight($$.placeholder.fontWeight)
        .fontColor($$.placeholder.fontColor)
        .fontSize($$.placeholder.fontSize)
        .onClick($$.placeholder.onClick)
        .decoration({
          type: $$.placeholder.decorationType ?? TextDecorationType.None,
          color: $$.placeholder.decorationColor,
          style: $$.placeholder.decorationStyle
        })
    } else {
      Span($$.mainSentence)
        .fontWeight(this.mainContent.mFontWeight)
        .fontColor(this.mainContent.mFontColor)
        .fontSize(this.mainContent.mFontSize)
    }
  }

  build() {
    Text() {
      ForEach(this.contentStr, (str: string) => {
        this.splitSpan({ placeholder: this.isMatched(str) as PlaceholderProps, mainSentence: str });
      })
    }
    .width('100%')
    .textAlign(this.mainContent.mTextAlign ?? TextAlign.Start)
    .textCase(this.mainContent.mTextCase ?? TextCase.Normal)
    .textOverflow(this.mainContent.mTextOverflow ?? { overflow: TextOverflow.Clip })
    .maxLines(this.mainContent.mMaxLines)
    .lineSpacing(LengthMetrics.vp(this.lineSpacing));
  }
}