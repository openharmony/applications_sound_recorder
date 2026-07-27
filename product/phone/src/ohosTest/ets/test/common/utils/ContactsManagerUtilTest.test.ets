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
import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium';
import ContactsManagerUtil from '@ohos/common/src/main/ets/utils/ContactsManagerUtil';
import { RecordData } from '@ohos/common';

export default function ContactsManagerUtilTest() {
  describe('getContactNameFromDisplayName_testSuite', () => {

    it('should_return_contacts_when_displayName_is_contactName_timestamp', 0, () => {
      let displayName = "张三_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三");
    });

    it('should_return_phoneNumber_when_displayName_is_contactPhoneNumber_timestamp', 0, () => {
      let displayName = "18612345678_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("18612345678");
    });

    it('should_return_displayName_when_displayName_timestamp_only_13_numbers', 0, () => {
      let displayName = "18612345678_2024103016201";
      let result = getContactName(displayName);
      expect(result).assertEqual("18612345678_2024103016201");
    });

    it('should_return_displayName_when_displayName_does_not_contain_underline', 0, () => {
      let displayName = "张三#20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三#20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_1', 0, () => {
      let displayName = "张三/_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三/_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_2', 0, () => {
      let displayName = "张三:_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三:_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_3', 0, () => {
      let displayName = "张三*_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三*_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_4', 0, () => {
      let displayName = "张三？_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三？_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_5', 0, () => {
      let displayName = "张三\'_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三\'_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_6', 0, () => {
      let displayName = "张三<_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三<_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_7', 0, () => {
      let displayName = "张三>_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三>_20241030162010");
    });

    it('should_return_displayName_when_displayName_contains_special_char_8', 0, () => {
      let displayName = "张三|_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三|_20241030162010");
    });

    it('should_return_contactName_before_at_when_displayName_contains_special_char_at', 0, () => {
      let displayName = "张三@10_20241030162010";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三");
    });

    it('should_return_contactName_when_user_custom_displayName_does_not_contain_dot', 0, () => {
      let displayName = "张三";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三");
    });

    it('should_return_contactName_without_suffix_when_user_custom_displayName_contains_dot', 0, () => {
      let displayName = "张三.1";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三");
    });

    it('should_return_contacts_when_user_custom_displayName_contains_at_symbol', 0, () => {
      let displayName = "张三@123.1";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三@123");
    });

    it('should_return_contacts_when_user_custom_displayName_does_not_contain_at_symbol', 0, () => {
      let displayName = "张三_123.1";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三_123");
    });

    it('should_return_contacts_when_user_custom_displayName_contains_dot_and_at_symbol', 0, () => {
      let displayName = "张三.1@123.1";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三.1@123");
    });

    it('should_return_contacts_when_user_custom_displayName_contains_dot_and_at_symbol_and_spaces', 0, () => {
      let displayName = "张三.1 @123.1";
      let result = getContactName(displayName);
      expect(result).assertEqual("张三.1 @123");
    });

    it('should_return_CallRecord_id_when_phoneNumber_is_not_null', 0, () => {
      let record: RecordData = new RecordData();
      record.phoneNumber = '1234567890';
      record.id = 1;
      let contactsmanagerutil: ContactsManagerUtil = ContactsManagerUtil.getInstance();
      const result = contactsmanagerutil.addCallRecordPrefix(record);
      expect(result).assertEqual('CallRecord_1');
    });

    it('should_return_id_toString_when_phoneNumber_is_empty', 0, () => {
      let record: RecordData = new RecordData();
      record.id = 1
      let contactsmanagerutil: ContactsManagerUtil = ContactsManagerUtil.getInstance();
      const result = contactsmanagerutil.addCallRecordPrefix(record);
      expect(result).assertEqual('1');
    });
  });
}

function getContactName(displayName: string) {
  let contactsmanagerutil: ContactsManagerUtil = ContactsManagerUtil.getInstance();
  let result = contactsmanagerutil.getContactNameFromDisplayName(displayName);
  return result;
}
