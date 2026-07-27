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

/*
* @param: content 占位符填充字串资源ID
* @param: color 占位符填充字串颜色ID
* @param: weight 占位符填充字串字体样式
* @param: onClick 占位符点击事件
**/
export interface PlaceholderProps {
  placeholderContent: Resource | string;
  fontColor?: ResourceColor;
  fontWeight?: FontWeight;
  fontSize: Resource | VP;
  onClick?: () => void;
  decorationStyle?:TextDecorationStyle;
  decorationColor?:ResourceColor;
  decorationType?:TextDecorationType;
}

/*
* @param: mContent 主干句填充字串资源ID
* @param: mFontSize 主干句填充字串字体大小
* @param: mFontColor 主干句填充字串颜色ID
* @param: mFontWeight 主干句字体样式
* @param: mTextAlign 主干句文本段落在水平方向的对齐方式
* @param: mTextCase 主干句文本大小写
* @param: mTextOverflow 主干句文本超长时的显示方式
**/
export interface MainSentenceProps {
  mContent: ResourceStr,
  mFontSize: Resource | VP,
  mFontColor?: ResourceColor,
  mFontWeight?: FontWeight,
  mTextAlign?: TextAlign,
  mTextCase?: TextCase,
  mTextOverflow?: textOverflowType,
  mMaxLines?: number
}

//文本超长时的显示方式默认参数值
interface textOverflowType {
  overflow: TextOverflow
}

/*拆分排序后的主干句和占位符*/
export interface StringData {
  placeholder: PlaceholderProps;
  mainSentence: string;
}