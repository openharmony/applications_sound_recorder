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
import { AnonymousUtil } from '@ohos/common';
import { afterEach, beforeEach, describe, expect, it } from '@ohos/hypium';

export default function AnonymousUtilTest() {
  describe('anonymous_testSuite', () => {

    it('should_return_anonymized_string_when_value_length_is_even_and_reserve_length_is_even', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 2;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12**56");
    });

    it('should_return_anonymized_string_when_value_length_is_even_and_reserve_length_is_odd', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 3;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1***56");
    });

    it('should_return_anonymized_string_when_value_length_is_odd_and_reserve_length_is_even', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 2;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1**45");
    });

    it('should_return_anonymized_string_when_value_length_is_odd_and_reserve_length_is_odd', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 3;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1***5");
    });

    it('should_return_anonymized_string_when_reserveLength_small_or_equals_zero', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 0;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");

      reserveLength = -1;
      result = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");
    });

    it('should_return_anonymized_string_when_reg_is_specific_string', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 2;
      let reg: string = "-";
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1--45");
    });

    it('should_return_anonymized_string_when_value_length_smaller_than_reserve_length', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 7;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("******");
    });

    it('should_return_anonymized_string_when_value_length_equals_reserve_length', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 6;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("******");
    });

    it('should_return_anonymized_string_when_reserveLength_small_zero', 0, () => {
      let value: string = "12345";
      let reserveLength: number = -1;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");
    });

    it('should_return_anonymized_string_when_value_length_is_even_and_reserve_length_is_even_1', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 2;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12**56");
    });

    it('should_return_anonymized_string_when_value_length_is_even_and_reserve_length_is_odd_1', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 3;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1***56");
    });

    it('should_return_anonymized_string_when_value_length_is_odd_and_reserve_length_is_even_1', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 2;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1**45");
    });

    it('should_return_anonymized_string_when_value_length_is_odd_and_reserve_length_is_odd_1', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 3;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1***5");
    });

    it('should_return_anonymized_string_when_reserveLength_small_or_equals_zero_1', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 0;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");

      reserveLength = -1;
      result = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");
    });

    it('should_return_anonymized_string_when_reg_is_specific_string_1', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 2;
      let reg: string = "-";
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1--45");
    });

    it('should_return_anonymized_string_when_value_length_smaller_than_reserve_length_1', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 7;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("******");
    });

    it('should_return_anonymized_string_when_value_length_equals_reserve_length_1', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 6;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("******");
    });

    it('should_return_anonymized_string_when_reserveLength_small_zero_1', 0, () => {
      let value: string = "12345";
      let reserveLength: number = -1;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");
    });

    it('should_return_anonymized_string_when_value_length_is_even_and_reserve_length_is_even_2', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 2;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12**56");
    });

    it('should_return_anonymized_string_when_value_length_is_even_and_reserve_length_is_odd_2', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 3;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1***56");
    });

    it('should_return_anonymized_string_when_value_length_is_odd_and_reserve_length_is_even_2', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 2;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1**45");
    });

    it('should_return_anonymized_string_when_value_length_is_odd_and_reserve_length_is_odd_2', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 3;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1***5");
    });

    it('should_return_anonymized_string_when_reserveLength_small_or_equals_zero_2', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 0;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");

      reserveLength = -1;
      result = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");
    });

    it('should_return_anonymized_string_when_reg_is_specific_string_2', 0, () => {
      let value: string = "12345";
      let reserveLength: number = 2;
      let reg: string = "-";
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("1--45");
    });

    it('should_return_anonymized_string_when_value_length_smaller_than_reserve_length_2', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 7;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("******");
    });

    it('should_return_anonymized_string_when_value_length_equals_reserve_length_2', 0, () => {
      let value: string = "123456";
      let reserveLength: number = 6;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("******");
    });

    it('should_return_anonymized_string_when_reserveLength_small_zero_2', 0, () => {
      let value: string = "12345";
      let reserveLength: number = -1;
      let reg: string = '*';
      let result: string = AnonymousUtil.anonymous(value, reserveLength, reg);
      expect(result).assertEqual("12345");
    });
  });
}
