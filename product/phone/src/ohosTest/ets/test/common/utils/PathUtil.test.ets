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
import { PathUtil } from '@ohos/common';

export default function PathUtilTest() {
  describe('extname_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('atc_should_return_empty_string_when_path_has_no_extension', 0, () => {
      const path = 'test';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('');
    });

    it('atc_should_return_extension_when_path_has_extension', 0, () => {
      const path = 'test.txt';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('.txt');
    });

    it('atc_should_return_extension_when_path_has_multiple_extensions', 0, () => {
      const path = 'test.tar.gz';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('.gz');
    });

    it('atc_should_return_extension_when_path_has_multiple_split', 0, () => {
      const path = '//test.tar.gz';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('.gz');
    });

    it('atc_should_return_extension_when_path_has_extension_with_dots', 0, () => {
      const path = 'test..txt';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('.txt');
    });

    it('atc_should_return_extension_when_path_has_extension_with_ dots_and_ slashes', 0, () => {
      const path = 'test/../test.txt';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('.txt');
    });

    it('atc_should_return_extension_when_path_has_extension_with_ dots_and_ slashes_and_multiple_extensions', 0, () => {
      const path = 'test/../test.tar.gz';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('.gz');
    });

    it('atc_should_return_empty_string_when_path_is_empty', 0, () => {
      const path = '';
      const result = PathUtil.extname(path);
      expect(result).assertEqual('');
    });
  });

  describe('basename_testSuite', () => {

    it('atc_should_return_base_name_when_path_has_extension_txt', 0, () => {
      const path: ESObject = 'path/to/file.txt';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('file');
    });

    it('atc_should_return_base_name_when_path_has_extension_json', 0, () => {
      const path: ESObject = 'path/to/file.json';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('file');
    });

    it('atc_should_return_base_name_when_path_has_multiple_extensions', 0, () => {
      const path: ESObject = 'path/to/file.txt.gz';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('file.txt');
    });

    it('atc_should_return_base_name_when_path_has_gz_extensions', 0, () => {
      const path: ESObject = 'path/to/file/txt.gz';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('txt');
    });

    it('atc_should_return_base_name_when_path_contains_dot', 0, () => {
      const path: ESObject = 'path/to/file.txt';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('file');
    });

    it('atc_should_return_base_name_when_path_contains_split', 0, () => {
      const path: ESObject = 'path/to//file.txt';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('file');
    });

    it('atc_should_return_base_name_when_path_does_not_contain_dot', 0, () => {
      const path: ESObject = 'path/to/file';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('file');
    });

    it('atc_should_return_base_name_when_path_is_just_a_dot', 0, () => {
      const path: ESObject = '.';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('.');
    });

    it('atc_should_return_base_name_when_path_is_empty', 0, () => {
      const path: ESObject = '';
      const result: ESObject = PathUtil.basename(path);
      expect(result).assertEqual('');
    });
  });

  describe('dirname_testSuite', () => {

    beforeEach(() => {

    });
    afterEach(() => {

    });

    it('atc_should_return_current_directory_when_path_has_extension_txt', 0, () => {
      const path: ESObject = 'path/to/file.txt';
      const result: ESObject = PathUtil.dirname(path);
      expect(result).assertEqual('path/to');
    });

    it('atc_should_return_current_directory_when_path_has_extension_json', 0, () => {
      const path: ESObject = 'path/to/file.json';
      const result: ESObject = PathUtil.dirname(path);
      expect(result).assertEqual('path/to');
    });

    it('atc_should_return_current_directory_when_path_has_multiple_extensions', 0, () => {
      const path: ESObject = 'path/to/file.txt.gz';
      const result: ESObject = PathUtil.dirname(path);
      expect(result).assertEqual('path/to');
    });

    it('atc_should_return_current_directory_when_path_has_multiple_split', 0, () => {
      const path: ESObject = 'path/to//file.txt';
      const result: ESObject = PathUtil.dirname(path);
      expect(result).assertEqual('path/to/');
    });

    it('atc_should_return_current_directory_when_path_has_multiple_split_extensions', 0, () => {
      const path: ESObject = 'path/to//file.txt.gz';
      const result: ESObject = PathUtil.dirname(path);
      expect(result).assertEqual('path/to/');
    });

    it('atc_should_return_current_directory_when_path_has_no_extension', 0, () => {
      const path: ESObject = 'path/to/file';
      const result: ESObject = PathUtil.dirname(path);
      expect(result).assertEqual('path/to');
    });

    it('atc_should_return_current_directory_when_path_is_empty', 0, () => {
      const result = PathUtil.dirname('');
      expect(result).assertEqual('.');
    });

    it('atc_should_return_current_directory_when_path_has_no_separators', 0, () => {
      const result = PathUtil.dirname('somefile.txt');
      expect(result).assertEqual('.');
    });

    it('atc_should_return_current_directory_when_path_is_invalid', 0, () => {
      const result = PathUtil.dirname('someinvalidpath');
      expect(result).assertEqual('.');
    });

  });
}