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
import { FileUtil, PathUtil } from '@ohos/common';
import { describe, expect, it } from '@ohos/hypium';
import { common } from '@kit.AbilityKit';

export default function FileUtilTest() {
  describe('FileUtil.exists_test', () => {
    it('FileUtil.exists_test_001', 0, () => {
      const path: string = '/storage/Users/currentUser';
      const result: boolean = FileUtil.exists(path);

      expect(result).assertEqual(true);
    });

    it('FileUtil.exists_test_002', 0, () => {
      const path: string = '/storage/Users/currentUser_1';
      const result: boolean = FileUtil.exists(path);

      expect(result).assertEqual(false);
    });
  });

  describe('FileUtil.moveFile_test', () => {
    it('FileUtil.moveFile_test_001', 0, async () => {
      const path1: string = `${PathUtil.USER_FILEPATH}/a.txt`;
      if (!FileUtil.createFile(path1)) {
        return expect().assertFail();
      }
      const path2: string = `${PathUtil.USER_FILEPATH}/b.txt`;
      const result = await FileUtil.moveFile(path1, path2);

      expect(result).assertEqual(true);
      expect(FileUtil.removeFile(path2)).assertEqual(true);
    });

    it('FileUtil.moveFile_test_002', 0, async () => {
      const ctx = AppStorage.get<common.UIAbilityContext>('pageContext');
      if (!ctx) {
        return expect().assertFail();
      }
      const path1: string = `${ctx.tempDir}/a.txt`;
      if (!FileUtil.createFile(path1)) {
        return expect().assertFail();
      }
      const path2: string = `${PathUtil.USER_FILEPATH}/b.txt`;
      const result = await FileUtil.moveFile(path1, path2);
      expect(result).assertTrue();
      expect(FileUtil.removeFile(path2)).assertEqual(true);
    });

    it('FileUtil.moveFile_test_003', 0, async () => {
      const ctx = AppStorage.get<common.UIAbilityContext>('pageContext');
      if (!ctx) {
        return expect().assertFail();
      }
      const path1: string = `${ctx.tempDir}/a.txt`;
      if (!FileUtil.createFile(path1)) {
        return expect().assertFail();
      }
      const path2: string = `${ctx.tempDir}/b.txt`;
      const result = await FileUtil.moveFile(path1, path2);

      expect(result).assertEqual(true);
      expect(FileUtil.removeFile(path2)).assertEqual(true);
    });
  });

  describe('FileUtil.parseFilename_test', () => {
    it('FileUtil.parseFilename_test_001', 0, () => {
      const filename: string = 'report 2.pdf';
      const result = FileUtil.parseFilename(filename);

      expect(result.basename).assertEqual('report');
      expect(result.index).assertEqual(2);
      expect(result.extname).assertEqual('.pdf');
    });

    it('FileUtil.parseFilename_test_002', 0, () => {
      const filename: string = 'image.png';
      const result = FileUtil.parseFilename(filename);

      expect(result.basename).assertEqual('image');
      expect(result.index).assertEqual(1);
      expect(result.extname).assertEqual('.png');
    });

    it('FileUtil.parseFilename_test_003', 0, () => {
      const filename: string = 'archive';
      const result = FileUtil.parseFilename(filename);

      expect(result.basename).assertEqual('archive');
      expect(result.index).assertEqual(1);
      expect(result.extname).assertEqual('');
    });
  });

  describe('FileUtil.isAudioFile_test', () => {
    it('FileUtil.isAudioFile_test_001', 0, () => {
      const filename: string = 'a.m4a';
      const result = FileUtil.isAudioFile(filename);

      expect(result).assertEqual(true);
    });

    it('FileUtil.isAudioFile_test_002', 0, () => {
      const filename: string = 'a.wav';
      const result = FileUtil.isAudioFile(filename);

      expect(result).assertEqual(true);
    });

    it('FileUtil.isAudioFile_test_003', 0, () => {
      const filename: string = 'a.amr';
      const result = FileUtil.isAudioFile(filename);

      expect(result).assertEqual(true);
    });

    it('FileUtil.isAudioFile_test_004', 0, () => {
      const filename: string = 'a.mp3';
      const result = FileUtil.isAudioFile(filename);

      expect(result).assertEqual(false);
    });

    it('FileUtil.isAudioFile_test_005', 0, () => {
      const filename: string = 'a.mp4';
      const result = FileUtil.isAudioFile(filename);

      expect(result).assertEqual(false);
    });
  });

  describe('FileUtil.genNewFilename_test', () => {
    it('FileUtil.genNewFilename_test_001', 0, () => {
      const original: string = 'a.m4a';
      const existingFiles: string[] = ['a.m4a'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('a 2.m4a');
    });

    it('FileUtil.genNewFilename_test_002', 0, () => {
      const original: string = 'a.m4a';
      const existingFiles: string[] = ['a.m4a', 'a 3.m4a'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('a 2.m4a');
    });

    it('FileUtil.genNewFilename_test_003', 0, () => {
      const original: string = 'a 2.m4a';
      const existingFiles: string[] = ['a 2.m4a', 'a 3.m4a', 'a 4.m4a', 'a 5.m4a'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('a.m4a');
    });

    it('FileUtil.genNewFilename_test_004', 0, () => {
      const original: string = '雁塔区 19} .m4a';
      const existingFiles: string[] = ['a 2.m4a', 'a 3.m4a', 'a 4.m4a', 'a 5.m4a', '雁塔区 19} .m4a'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('雁塔区 19}  2.m4a');
    });

    it('FileUtil.genNewFilename_test_005', 0, () => {
      const original: string = 'test';
      const existingFiles: string[] = [];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('test');
    });

    it('FileUtil.genNewFilename_test_006', 0, () => {
      const original: string = 'test';
      const existingFiles: string[] = ['test'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('test 2');
    });

    it('FileUtil.genNewFilename_test_007', 0, () => {
      const original: string = 'test 2';
      const existingFiles: string[] = ['test', 'test 2'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('test 3');
    });

    it('FileUtil.genNewFilename_test_008', 0, () => {
      const original: string = 'test';
      const existingFiles: string[] = ['test', 'test 3'];
      const result: string = FileUtil.genNewFilename(original, existingFiles);

      expect(result).assertEqual('test 2');
    });
  });
}