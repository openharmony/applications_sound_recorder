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

import type Want from '@ohos.app.ability.Want';
import type common from '@ohos.app.ability.common';

/**
 * Provide methods make the host (data owner) application can conveniently wrap shared data,
 * make show the system share panel.
 *
 * @namespace systemShare
 * @syscap SystemCapability.Collaboration.SystemShare
 * @since 4.1.0(11)
 */
declare namespace systemShare {

  /**
   * Describe the shared data.
   *
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  class SharedData {
    /**
     * Create shared data with shared record
     *
     * @param { SharedRecord } record - Record will add into shared data
     * @throws { BusinessError } 401 - Parameter error.
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    constructor(record: SharedRecord);

    /**
     * Add a record into shared data
     *
     * @param { SharedRecord } record - Record will add into shared data.
     * @throws { BusinessError } 401 - Parameter error.
     * @throws { BusinessError } 1003700001 - The number of records exceeds the maximum.
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    addRecord(record: SharedRecord): void;

    /**
     * Get all records of shared data
     *
     * @returns { Array<SharedRecord> } Return the records of shared data
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    getRecords(): Array<SharedRecord>;
  }

  /**
   * Describe the shared record
   *
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  interface SharedRecord {
    /**
     * Indicates the uniform type descriptor of shared record,
     * for details,see {@link @ohos.data.uniformTypeDescriptor}.
     *
     * @type { string }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    utd: string;

    /**
     * Indicates the content of shared record, information that does not
     * require authorization, including but not limited to text, HTML text, and URL.
     *
     * @type { string }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    content?: string;

    /**
     * Indicates the uri of shared record.
     *
     * @type { string }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    uri?: string;

    /**
     * Indicates the title of shared record
     *
     * @type { string }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    title?: string;

    /**
     * Indicates the label of shared record
     *
     * @type { string }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    label?: string;

    /**
     * Indicates the description of shared record
     *
     * @type { string }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    description?: string;

    /**
     * Indicates the thumbnail of shared record
     *
     * @type { Uint8Array }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    thumbnail?: Uint8Array;

    /**
     * Indicates the extra data of shared record. The content
     * is forwarded to the target application without permission authorization.
     *
     * @type { Record<string, string | number | boolean | Array<string | number | boolean>> }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    extraData?: Record<string, string | number | boolean | Array<string | number | boolean>>;
  }

  /**
   * Defines the offset property.
   * @typedef Offset
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  interface Offset {
    /**
     * Coordinate x of the Position.
     *
     * @type {number}
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    x: number;

    /**
     * Coordinate y of the Position.
     *
     * @type {number}
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    y: number;
  }

  /**
   * Defines the size property.
   *
   * @typedef Size
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  interface Size {
    /**
     * Defines the width property.
     *
     * @type {number}
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    width: number;

    /**
     * Defines the height property.
     *
     * @type {number}
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    height: number;
  }

  /**
   * Defines share controller anchor.
   * @typedef ShareControllerAnchor
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  interface ShareControllerAnchor {
    /**
     * Indicates the window offset of share controller
     * can set Precise coordinates, or set the Coordinates of the upper left vertex of the component
     * then set the size of the selected content area.
     *
     * @type { Offset }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    windowOffset: Offset;

    /**
     * Indicates the size of the selected content area.
     *
     * @type { Size }
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    size?: Size;
  }

  /**
   * Shared data preview mode definitions.
   *
   * @enum { number }
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  enum SharePreviewMode {
    /**
     * Indicates the default preview mode.
     *
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    DEFAULT = 0,

    /**
     * Indicates the detail preview mode.
     *
     * @syscap SystemCapability.Collaboration.SystemShare
     * @since 4.1.0(11)
     */
    DETAIL
  }

  /**
   * Selection mode definitions.
   *
   * @enum { number }
   * @syscap SystemCapability.Collaboration.SystemShare
   * @since 4.1.0(11)
   */
  enum SelectionMode {

    SINGLE = 0,


    BATCH = 1
  }


  interface ShareControllerOptions {

    selectionMode?: SelectionMode;

    anchor?: ShareControllerAnchor | string;

    previewMode?: SharePreviewMode;
  }

  class ShareController {

    constructor(data: SharedData);


    show(context: common.UIAbilityContext, options: ShareControllerOptions): Promise<void>;

    on(event: 'dismiss', callback: () => void): void;

    off(event: 'dismiss', callback: () => void): void;
  }

  interface ContactInfo {
    contactType: string;
    contactId: string;
  }

  function getSharedData(want: Want): Promise<SharedData>;

  function getContactInfo(want: Want): Promise<ContactInfo>;
}

export default systemShare;