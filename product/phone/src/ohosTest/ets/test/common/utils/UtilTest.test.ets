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

import { describe, expect, it, MockKit } from '@ohos/hypium';
import { LogUtil, Util } from '@ohos/common';

const TAG: string = 'SoundRecorder_UtilTest';
const NORMAL_CHAR: string = 'normal';
const SPECIAL_CHAR: string = 'special***';

export default function UtilTest() {
  describe('UtilTest', () => {
    /**
     * @tc.number:UtilTest_001
     * @tc.name: Util工具类测试
     */
    it('UtilTest_001', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_001 start');
      let timeFormat = new Date().getTime();
      expect(Util.timeFormat(timeFormat)).assertInstanceOf('String');
      LogUtil.info(TAG + ' UtilTest_001 end');
    });

    /*
     * @tc.number:UtilTest_002
     * @tc.name:获取日期格式工具测试类
     */

    it('UtilTest_002', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_002 start');
      expect(Util.getDateFormat(0)).assertInstanceOf('String');
      LogUtil.info(TAG + ' UtilTest_002 end');
    });

    /*
     * @tc.number:UtilTest_003
     * @tc.name:获取时间格式工具测试类
     */
    it('UtilTest_003', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_003 start');
      expect(Util.getTimeFormat(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_003 end');
    });

    it('atc_should_return_empty_string_when_timestamp_is_negative', 0, () => {
      let result: ESObject = Util.timeFormat(-1000);
      expect(result).assertEqual('');
    });

    it('atc_should_return_time_string_with_hour_when_hasHour_is_true_and_timestamp_is_positive', 0, () => {
      let result: ESObject = Util.timeFormat(3600000);
      expect(result).assertEqual('01:00:00');
    });

    it('atc_should_return_time_string_without_hour_when_hasHour_is_false_and_timestamp_is_positive', 0, () => {
      let result: ESObject = Util.timeFormat(3600000, false);
      expect(result).assertEqual('01:00:00');
    });

    it('atc_should_return_time_string_with_correct_format_when_timestamp_is_positive', 0, () => {
      let result: ESObject = Util.timeFormat(3600000);
      expect(result).assertEqual('01:00:00');
    });

    it('atc_should_return_00:00.00_when_timestamp_is_less_than_or_equal_to_0', 0, () => {
      let result: ESObject = Util.timeFormatMs(-1000);
      expect(result).assertEqual('00:00.00');
    });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_0_but_less_than_1_minute', 0, () => {
      let result: ESObject = Util.timeFormatMs(5000);
      expect(result).assertEqual('00:05.00');
    });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_1_minute_but_less_than_1_hour', 0, () => {
      let result: ESObject = Util.timeFormatMs(60000);
      expect(result).assertEqual('01:00.00');
    });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_1_hour_but_less_than_10_hours', 0, () => {
      let result: ESObject = Util.timeFormatMs(3600000);
      expect(result).assertEqual('01:00:00');
    });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_10_hours_but_less_than_100_hours', 0,
      () => {
        let result: ESObject = Util.timeFormatMs(36000000);
        expect(result).assertEqual('10:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_100_hours_but_less_than_1000_hours', 0,
      () => {
        let result: ESObject = Util.timeFormatMs(360000000);
        expect(result).assertEqual('100:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_1000_hours_but_less_than_10000_hours', 0,
      () => {
        let result: ESObject = Util.timeFormatMs(3600000000);
        expect(result).assertEqual('1000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_10000_hours_but_less_than_100000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(36000000000);
        expect(result).assertEqual('10000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_100000_hours_but_less_than_1000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(360000000000);
        expect(result).assertEqual('100000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_1000000_hours_but_less_than_10000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(3600000000000);
        expect(result).assertEqual('1000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_10000000_hours_but_less_than_100000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(36000000000000);
        expect(result).assertEqual('10000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_100000000_hours_but_less_than_1000000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(360000000000000);
        expect(result).assertEqual('100000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_1000000000_hours_but_less_than_10000000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(3600000000000000);
        expect(result).assertEqual('1000000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_10000000000_hours_but_less_than_100000000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(36000000000000000);
        expect(result).assertEqual('10000000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_100000000000_hours_but_less_than_1000000000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(360000000000000000);
        expect(result).assertEqual('100000000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_1000000000000_hours_but_less_than_10000000000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(3600000000000000000);
        expect(result).assertEqual('1000000000000:00:00');
      });

    it('atc_should_return_00:00.00_when_timestamp_is_greater_than_or_equal_to_10000000000000_hours_but_less_than_100000000000000_hours',
      0, () => {
        let result: ESObject = Util.timeFormatMs(36000000000000000000);
        expect(result).assertEqual('10000000000000:00:00');
      });

    it('atc_should_return_correct_date_format_when_date_is_valid', 0, () => {
      let date: ESObject = 1633030400000; // February 5, 2022
      let result: ESObject = Util.getDateFormat(date);
      expect(result).assertEqual('2021/10/01');
    });

    it('atc_should_return_correct_date_format_when_date_is_invalid', 0, () => {
      let date: ESObject = 123456789; // Invalid date
      let result: ESObject = Util.getDateFormat(date);
      expect(result).assertEqual('1970/01/02');
    });

    it('atc_should_return_correct_time_format_when_date_is_valid', 0, () => {
      let date: ESObject = 1633030400000;
      let result: ESObject = Util.getTimeFormat(date);
      expect(result).assertEqual('03:33:20');
    });

    it('atc_should_return_correct_time_format_when_date_is_invalid', 0, () => {
      let date: ESObject = 123456789;
      let result: ESObject = Util.getTimeFormat(date);
      expect(result).assertEqual('18:17:36');
    });

    /*
    * @tc.number:UtilTest_004
    * @tc.name:获取日期工具测试类
    */
    it('UtilTest_004', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_004 start');
      expect(Util.getDate()).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_004 end');
    });

    /*
    * @tc.number:UtilTest_005
    * @tc.name:获取时间工具测试类
    */

    it('UtilTest_005', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_005 start');
      expect(Util.getTime()).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_005 end');
    });

    /*
    * @tc.number:UtilTest_005
    * @tc.name:时间补0工具测试类
    */
    it('UtilTest_006', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_006 start');
      expect(Util.addZero(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_006 end');
    });
    it('UtilTest_007', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_007 start');
      expect(Util.addZero(10)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_007 end');
    });

    /*
    * @tc.number:UtilTest_008
    * @tc.name:时间补0工具测试类
    */
    it('UtilTest_008', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_008 start');
      expect(Util.duration2Time(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_008 end');
    });

    it('UtilTest_009', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_009 start');
      expect(Util.duration2Time(1000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_009 end');
    });

    it('UtilTest_010', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_010 start');
      expect(Util.duration2Time(36000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_010 end');
    });

    it('UtilTest_011', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_011 start');
      expect(Util.duration2Time(360000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_011 end');
    });

    it('UtilTest_012', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_012 start');
      expect(Util.duration2Time(2160000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_012 end');
    });

    it('UtilTest_013', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_013 start');
      expect(Util.duration2Time(32400000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_013 end');
    });

    it('UtilTest_014', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_014 start');
      expect(Util.duration2Time(129600000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_014 end');
    });

    /*
     * @tc.number:UtilTest_015
     * @tc.name:时间补0工具测试类
     */

    it('UtilTest_015', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_015 start');
      expect(Util.encrypt('')).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_015 end');
    });

    /*
     * @tc.number:UtilTest_016
     * @tc.name:时间补0工具测试类
     */
    it('UtilTest_016', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_016 start');
      expect(Util.decrypt('')).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_016 end');
    });

    /*
    * @tc.number:UtilTest_017
    * @tc.name:特殊字符工具测试类
    */
    it('UtilTest_017', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_017 start');
      expect(Util.specialCharValidator(NORMAL_CHAR)).assertFalse();
      expect(Util.specialCharValidator(SPECIAL_CHAR)).assertTrue();
      LogUtil.info(TAG + ' UtilTest_017 end');
    });

    it('should_return_time_string_with_hour_when_hour_more_than_0_hasHour_is_true', 0, () => {
      let result = Util.timeFormat(60 * 60 * 1000);
      expect(result).assertEqual('01:00:00');
    });

    it('should_return_time_string_with_hour_when_hour_more_than_0_hasHour_is_false', 0, () => {
      let result = Util.timeFormat(60 * 60 * 1000, false);
      expect(result).assertEqual('01:00:00');
    });

    it('should_return_time_string_with_hour_when_hour_less_than_1_hasHour_is_true', 0, () => {
      let result = Util.timeFormat(40 * 60 * 1000);
      expect(result).assertEqual('00:40:00');
    });

    it('should_return_time_string_with_hour_when_hour_less_than_1_hasHour_is_false', 0, () => {
      let result = Util.timeFormat(40 * 60 * 1000, false);
      expect(result).assertEqual('40:00');
    });

    it('should_return_time_string_with_hour_when_timestamp_negative', 0, () => {
      let result = Util.timeFormat(-40 * 60 * 1000, false);
      expect(result).assertEqual('');
    });

    it('should_return_correct_time_when_timestamp_is_less_than_or_equal_to_0', 0, () => {
      let result = Util.timeFormatMs(-1000);
      expect(result).assertEqual('00:00.00');
    });

    it('should_return_correct_time_when_timestamp_is_greater_than_0_but_less_than_1_minute', 0, () => {
      let result = Util.timeFormatMs(5000);
      expect(result).assertEqual('00:05.00');
    });

    it('should_return_correct_time_when_timestamp_is_greater_than_or_equal_to_1_minute_but_less_than_1_hour', 0, () => {
      let result = Util.timeFormatMs(60000);
      expect(result).assertEqual('01:00.00');
    });

    it('should_return_correct_time_when_timestamp_is_greater_than_or_equal_to_1_hour_but_less_than_1_day', 0, () => {
      let result = Util.timeFormatMs(3600000);
      expect(result).assertEqual('01:00:00');
    });

    it('should_return_correct_time_when_timestamp_is_greater_than_or_equal_to_1_day_but_less_than_1_month', 0, () => {
      let result = Util.timeFormatMs(31536000000);
      expect(result).assertEqual('8760:00:00');
    });

    it('should_return_correct_time_when_timestamp_is_greater_than_or_equal_to_1_month_but_less_than_1_year', 0, () => {
      let result = Util.timeFormatMs(267840000000);
      expect(result).assertEqual('74400:00:00');
    });

    it('should_return_correct_time_when_timestamp_is_greater_than_or_equal_to_1_year', 0, () => {
      let result = Util.timeFormatMs(315360000000);
      expect(result).assertEqual('87600:00:00');
    });

    it('should_return_correct_date_format_when_date_is_valid', 0, () => {
      let date = 1633030400000; // 2021-10-01 03:33:20
      let result = Util.getDateFormat(date);
      expect(result).assertEqual('2021/10/01');
    });

    it('should_return_correct_time_format_when_date_is_valid', 0, () => {
      let date = 1633072400000; // 2021-10-01 15:13:20
      let result = Util.getTimeFormat(date);
      expect(result).assertEqual('15:13:20');
    });

    it('should_return_correct_time_format_1_when_date_is_valid', 0, () => {
      let date = 1633072400000; // 2021-10-01 15:13:20
      let result = Util.getTimeFormat1(date);
      expect(result).assertEqual('15:13');
    });

    it('should_return_correct_date_and_time_format', 0, () => {
      let date: number = 1633070400000; // 2021-10-01 14:40:00
      let result: string = Util.getDateAndTimeFormat(date);
      expect(result).assertEqual('2021/10/01 14:40');
    });

    it('should_return_true_when_string_contains_001', 0, () => {
      const result = Util.specialCharValidator('\\1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_002', 0, () => {
      const result = Util.specialCharValidator(':1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_003', 0, () => {
      const result = Util.specialCharValidator('*1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_004', 0, () => {
      const result = Util.specialCharValidator('?1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_005', 0, () => {
      const result = Util.specialCharValidator('<1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_006', 0, () => {
      const result = Util.specialCharValidator('>1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_007', 0, () => {
      const result = Util.specialCharValidator('|1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_contains_008', 0, () => {
      const result = Util.specialCharValidator('"1234');
      expect(result).assertEqual(true);
    });

    it('should_return_true_when_string_does_not_contain_special_char', 0, () => {
      const result = Util.specialCharValidator('1234');
      expect(result).assertEqual(false);
    });

    /*
    * @tc.number:UtilTest_timeFormat
    * @tc.name:时间格式转换为秒工具测试类
    */
    it('UtilTest_timeFormat_001', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormat_001 start');
      expect(Util.timeFormat(0, false)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormat_001 end');
    });

    it('UtilTest_timeFormat_002', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormat_002 start');
      expect(Util.timeFormat(-40 * 60 * 1000, false)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormat_002 end');
    });

    it('UtilTest_timeFormat_003', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormat_003 start');
      expect(Util.timeFormat(60 * 60, true)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormat_003 end');
    });

    it('UtilTest_timeFormat_004', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormat_004 start');
      expect(Util.timeFormat(60 * 60, false)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormat_004 end');
    });

    it('UtilTest_timeFormat_005', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormat_005 start');
      expect(Util.timeFormat(40 * 60 * 1000, true)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormat_005 end');
    });

    it('UtilTest_timeFormat_006', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormat_006 start');
      expect(Util.timeFormat(40 * 60 * 1000, false)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormat_006 end');
    });

    /*
    * @tc.number:UtilTest_timeFormatMs
    * @tc.name:时间格式转换为毫秒工具测试类
    */
    it('UtilTest_timeFormatMs_001', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_001 start');
      expect(Util.timeFormatMs(0)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_001 end');
    });

    it('UtilTest_timeFormatMS_002', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormatMS_002 start');
      expect(Util.timeFormatMs(-1)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormatMS_002 end');
    });

    it('UtilTest_timeFormatMs_003', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_003 start');
      expect(Util.timeFormatMs(3600)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_003 end');
    });

    it('UtilTest_timeFormatMs_004', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_004 start');
      expect(Util.timeFormatMs(36 * 1000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_004 end');
    });

    it('UtilTest_timeFormatMs_005', 0, async () => {
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_005 start');
      expect(Util.timeFormatMs(40 * 60 * 1000)).assertInstanceOf("String");
      LogUtil.info(TAG + ' UtilTest_timeFormatMs_005 end');
    });
  });
}