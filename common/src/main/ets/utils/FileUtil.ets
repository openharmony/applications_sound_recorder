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

import { BusinessError } from '@kit.BasicServicesKit';
import fs from '@ohos.file.fs';
import { media } from '@kit.MediaKit';
import { taskpool } from '@kit.ArkTS';
import { hiTraceMeter } from '@kit.PerformanceAnalysisKit';
import { LogUtil } from './LogUtil';
import { PathUtil } from './PathUtil';
import { PathChanger } from '../model/Optional';
import { Props } from '../constants/Props';
import { hash } from '@kit.CoreFileKit';

const TAG = 'SoundRecorder_FileUtil';

interface FileInfo {
  readonly basename: string;
  readonly index: number;
  readonly extname: string;
}

interface FileStat {
  readonly ino: string;
  readonly inode: number;
  readonly modifyTime: number;
  readonly size: number;
}

export class FileUtil {
  public static readonly AUDIO_SUFFIX: string[] = ['.m4a', '.wav', '.amr'];
  public static readonly TEMP_SUFFIX: string[] = ['.temp'];
  public static readonly JSON_SUFFIX: string[] = ['.json'];

  /**
   * 文件是否存在
   * @param path
   * @returns
   */
  public static exists(path: string): boolean {
    try {
      return fs.accessSync(path, fs.AccessModeType.EXIST);
    } catch (e) {
      LogUtil.error(`${TAG} failed to exists, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * 文件是否可读写
   * @param path
   * @returns
   */
  public static accessible(path: string): boolean {
    try {
      return fs.accessSync(path, fs.AccessModeType.READ_WRITE);
    } catch (e) {
      LogUtil.error(`${TAG} failed to accessible, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * copy file
   * @param src
   * @param dest
   * @returns
   */
  public static async copyFile(src: string, dest: string): Promise<boolean> {
    try {
      const result = await taskpool.execute<[string, string, string], Promise<boolean>>(copyFile, TAG, src, dest);
      return result;
    } catch (e) {
      LogUtil.error(`${TAG} failed to copy file, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * move file
   * @param src
   * @param dest
   * @returns
   */
  public static async moveFile(src: string, dest: string): Promise<boolean> {
    AppStorage.setOrCreate<PathChanger>(Props.PATH_CHANGER, { originPath: src, newPath: dest });
    try {
      const result = await taskpool.execute<[string, string, string], Promise<boolean>>(moveFile, TAG, src, dest);
      return result;
    } catch (e) {
      LogUtil.error(`${TAG} failed to move file, code: ${e.code}, message: ${e.message}`);
      return false;
    } finally {
      AppStorage.setOrCreate<PathChanger>(Props.PATH_CHANGER, undefined);
    }
  }

  public static async cleanResidue(): Promise<void> {
    const pathChanger = AppStorage.get<PathChanger>(Props.PATH_CHANGER);
    if (!pathChanger) {
      return;
    }
    if (!FileUtil.exists(pathChanger.originPath) || !FileUtil.exists(pathChanger.newPath)) {
      return;
    }
    const duration = await FileUtil.getDuration(pathChanger.newPath);
    if (duration !== 0) {
      return;
    }
    if (FileUtil.removeFile(pathChanger.newPath)) {
      LogUtil.info(`${TAG} clean residue ok.`);
    }
  }

  /**
   * 获取指定路径下 new name
   * @param originName
   * @param targetDir
   */
  public static async getFreeNewFilename(originName: string, ...targetDir: string[]): Promise<string> {
    if (targetDir.every(dir => !FileUtil.exists(`${dir}/${originName}`))) {
      return originName;
    }

    const fileInfo = FileUtil.parseFilename(originName);

    hiTraceMeter.startTrace('get-free-new-file-name', 0);
    const tasks = targetDir.map(dir => FileUtil.listAudioFile(dir, [fileInfo.basename]));
    const results = await Promise.allSettled(tasks);

    let existingFiles: string[] = [];
    for (const result of results) {
      if (result.status === 'fulfilled') {
        existingFiles.push(...result.value);
      }
    }
    hiTraceMeter.finishTrace('get-free-new-file-name', 0);

    hiTraceMeter.startTrace('get-free-new-file-name', 1);
    const newFileName = FileUtil.genNewFilename(fileInfo, existingFiles);
    hiTraceMeter.finishTrace('get-free-new-file-name', 1);

    return newFileName;
  }

  /**
   * 创建目录
   * @param path
   * @returns
   */
  public static mkdir(path: string): boolean {
    try {
      fs.mkdirSync(path, true);
      return true;
    } catch (e) {
      LogUtil.error(`${TAG} failed to mkdir, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * 创建目录
   * @param path
   * @returns
   */
  public static mkdirIfNotExists(path: string): boolean {
    if (FileUtil.exists(path)) {
      return true;
    }

    return FileUtil.mkdir(path);
  }

  /**
   * remove file
   * @param path
   * @returns
   */
  public static removeFile(path: string): boolean {
    try {
      fs.unlinkSync(path);
      return true;
    } catch (e) {
      LogUtil.error(`${TAG} failed to remove file, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * rename
   * @param path
   * @returns
   */
  public static rename(oldPath: string, newPath: string): boolean {
    try {
      fs.renameSync(oldPath, newPath);
      return true;
    } catch (e) {
      LogUtil.error(`${TAG} failed to rename, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * 列出文件夹下所有文件名
   * @param path
   * @param suffix
   * @param displayName
   */
  public static async listFile(path: string, suffix: string[] = [], displayName: string[] = []): Promise<string[]> {
    try {
      const result = await taskpool.execute
      <[string, string, string[], string[]], Promise<string[]>>(listFile, TAG, path, suffix, displayName);

      return result;
    } catch (e) {
      LogUtil.error(`${TAG} failed to list file, code: ${e.code}, message: ${e.message}`);
      return [];
    }
  }

  /**
   * 列出文件夹下音频文件名
   * @param path
   * @param displayName
   */
  public static listAudioFile(path: string, displayName?: string[]): Promise<string[]> {
    return FileUtil.listFile(path, FileUtil.AUDIO_SUFFIX, displayName);
  }

  /**
   * file stat
   * @param path
   */
  public static async stat(path: string): Promise<FileStat> {
    let ino = '';
    let inode = -1;
    let modifyTime = Date.now();
    let size = 0;

    try {
      const stat = await fs.stat(path);
      ino = stat.ino.toString();
      inode = Number(stat.ino & 0xFFFFFFFFn);
      modifyTime = stat.mtime * 1000;
      size = stat.size;
    } catch (e) {
      LogUtil.error(`${TAG} failed to stat, code: ${e.code}, message: ${e.message}`);
    }

    return {
      ino,
      inode,
      modifyTime,
      size
    };
  }

  public static async closeFile(fileFd: number | fs.File): Promise<boolean> {
    try {
      await fs.close(fileFd)
      return true;
    } catch (e) {
      LogUtil.error(`${TAG} failed to close file, code: ${e.code}, message: ${e.message}`);
      return false;
    }
  }

  /**
   * 获取时长
   * @param path
   */
  public static async getDuration(path: string): Promise<number> {
    try {
      const result = await taskpool.execute<[string, string], Promise<number>>(getDuration, TAG, path);
      return result;
    } catch (e) {
      LogUtil.error(`${TAG} failed to get duration, code: ${e.code}, message: ${e.message}`);
      return 0;
    }
  }

  /**
   * 扫描指定目录
   * @param path
   */
  public static async scanAudioAs(path: string): Promise<string[]> {
    if (!path) {
      LogUtil.error(`${TAG} path invalid.`);
      return [];
    }

    const filenames = await FileUtil.listAudioFile(path);
    return filenames.map(filename => `${path}/${filename}`);
  }

  /**
   * 检测UserFile目录
   */
  public static checkUserFileDir(): boolean {
    return FileUtil.mkdirIfNotExists(PathUtil.USER_FILEPATH) && FileUtil.accessible(PathUtil.USER_FILEPATH);
  }

  /**
   * 检测CallRecordFile目录
   */
  public static checkCallRecordFileDir(): boolean {
    return FileUtil.mkdirIfNotExists(PathUtil.CALLRECORD_FILEPATH) && FileUtil.accessible(PathUtil.CALLRECORD_FILEPATH);
  }

  /**
   * create file
   * @param path
   */
  public static createFile(path: string): boolean {
    if (FileUtil.exists(path)) {
      return true;
    }

    let file: fs.File | undefined;
    try {
      file = fs.openSync(path, fs.OpenMode.CREATE);
    } catch (e) {
      LogUtil.error(`${TAG} failed to create file, code: ${e.code}, message: ${e.message}`);
      return false;
    } finally {
      if (file) {
        FileUtil.closeFile(file);
      }
    }

    return true;
  }

  /**
   * Parses a file name into its basename, optional numeric index, and extension.
   *
   * @param filename The file name to parse.
   * @returns An object containing the `basename`, `index`, and `extname` properties.
   *
   * @example
   * parseFilename('report 2.pdf') -> { basename: 'report', index: 2, extname: '.pdf' }
   * parseFilename('image.png') -> { basename: 'image', index: 1, extname: '.png' }
   * parseFilename('archive') -> { basename: 'archive', index: 1, extname: '' }
   */
  public static parseFilename(filename: string): FileInfo {
    const regex = /^(?<basename>.*?)(?: (?<index>\d+))?(?<extname>\.[^.]*)?$/u;
    const match = filename.match(regex);

    if (!match?.groups) {
      return { basename: filename, index: 1, extname: '' };
    }

    const groups = match.groups;
    const basename = groups.basename;
    const index = groups.index;
    const extname = groups.extname;

    return {
      basename,
      index: index ? Number.parseInt(index, 10) : 1,
      extname: extname ?? ''
    };
  }

  public static isAudioFile(filename: string): boolean {
    return FileUtil.AUDIO_SUFFIX.some(extname => filename.endsWith(extname));
  }

  /**
   * Generates a new file name based on the original file name and a list of existing file names,
   * ensuring that the new file name does not conflict with any existing ones.
   *
   * @param original - The original file name as a string or a `FileInfo` object.
   * @param existingFiles - An array of existing file names to check for conflicts.
   * @returns A new file name that does not conflict with any in `existingFiles`.
   *
   * @example
   * genNewFilename('a.m4a', ['a.m4a']) -> 'a 2.m4a'
   * genNewFilename('a.m4a', ['a.m4a', 'a 3.m4a']) -> 'a 2.m4a'
   * genNewFilename('a 2.m4a', ['a 2.m4a', 'a 3.m4a', 'a 4.m4a', 'a 5.m4a']) -> 'a.m4a'
   * genNewFilename('雁塔区 19} .m4a', ['a 2.m4a', 'a 3.m4a', 'a 4.m4a', 'a 5.m4a', '雁塔区 19} .m4a']) ->  '雁塔区 19}  2.m4a'
   */
  public static genNewFilename(original: string | FileInfo, existingFiles: string[]): string {
    const originalInfo = typeof original === 'string' ? FileUtil.parseFilename(original) : original;
    const originalBasename = originalInfo.basename;
    const originalExtname = originalInfo.extname;

    // 使用 Set 和 map 进行高效索引收集
    const indices = new Set(existingFiles.map(FileUtil.parseFilename)
      .filter(fileInfo => fileInfo.basename === originalBasename && fileInfo.extname === originalExtname)
      .map(fileInfo => fileInfo.index));

    // 优先返回未被占用的原始文件名
    if (!indices.has(1)) {
      return originalExtname ? `${originalBasename}${originalExtname}` : originalBasename;
    }

    // 找到最小可用索引
    let i = 2;
    while (indices.has(i)) {
      i++;
    }

    return originalExtname ? `${originalBasename} ${i}${originalExtname}` : `${originalBasename} ${i}`;
  }

  public static async getHash(path: string): Promise<string> {
    try {
      const hashValue = await hash.hash(path, 'sha256');
      return hashValue;
    } catch (err) {
      LogUtil.error(`${TAG} failed to get hash, code: ${err.code}, message: ${err.message}`);
      return Promise.reject(err);
    }
  }

  /**
   * 检查两个文件的hash值是否相等
   */
  public static async isFileHashesEqual(path1: string, path2: string): Promise<boolean> {
    try {
      const hash1 = await FileUtil.getHash(path1);
      const hash2 = await FileUtil.getHash(path2);
      LogUtil.error(`${TAG} file1 hash value: ${hash1}, file2 hash value: ${hash2}`);
      return hash1 === hash2;
    } catch (err) {
      LogUtil.error(`${TAG} isFileHashesEqual failed, code: ${err.code}, message: ${err.message}`);
      return false;
    }
  }

  /**
   * 通过文件路径获取json文件二进制
   * @param path
   */
  /* instrument ignore next */
  public static async getArrayBufferByPath(path: string): Promise<Uint8Array | null> {
    if (!FileUtil.exists(path)) {
      LogUtil.error(`${TAG} the path does not exist.`);
      return null;
    }
    let file: fs.File | undefined = undefined;
    try {
      file = await fs.open(path, fs.OpenMode.READ_ONLY);
      const stats = await fs.stat(path);
      const chunkSize = 4000;
      const chunks: Uint8Array[] = [];
      let offset = 0;
      while (offset < stats.size) {
        const readSize = Math.min(chunkSize, stats.size - offset);
        const buffer = new ArrayBuffer(readSize);
        await fs.read(file.fd, buffer, { offset, length: readSize });
        chunks.push(new Uint8Array(buffer));
        offset += readSize;
      }
      await fs.close(file.fd);

      if (chunks.length === 0) {
        LogUtil.error(`${TAG} the file empty.`);
        return new Uint8Array(0);
      }
      let totalLength = chunks.reduce((sum, arr) => sum + arr.length, 0);
      let result = new Uint8Array(totalLength);
      let offset1 = 0;
      chunks.forEach(arr => {
        result.set(arr, offset1);
        offset1 += arr.length;
      });
      LogUtil.info(`${TAG} read json success.`);
      return result;
    } catch (err) {
      await fs.close(file?.fd);
      LogUtil.error(`${TAG} failed to read JSON file: ${(err as BusinessError).message}.`);
      return null;
    }
  }

  /**
   * 通过将Uint8Array数据写到json文件中
   *
   * @param path
   * @param data
   */
  /* instrument ignore next */
  public static async writeBufferToJsonFile(path: string, data: Uint8Array): Promise<boolean> {
    const pathTemp: string = `${path}.temp`;
    try {
      if (FileUtil.exists(path)) {
        FileUtil.removeFile(path);
      }
      const mainPath: string = path.substring(0, path.lastIndexOf('/'));
      if (!FileUtil.exists(mainPath) && !FileUtil.mkdir(mainPath)) {
        LogUtil.error(`${TAG} failed to mkdir path.`);
        return false;
      }
      await FileUtil.deleteTempFile(mainPath);
      const file = await fs.open(pathTemp, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      let offset = 0;
      const chunkSize = 4000;
      while (offset < data.length) {
        const writeSize = Math.min(chunkSize, data.length - offset);
        const chunk = data.slice(offset, offset + writeSize);
        await fs.write(file.fd, chunk.buffer, { offset: offset, length: writeSize });
        offset += writeSize;
      }
      await fs.close(file);
      FileUtil.rename(pathTemp, path);
      return true;
    } catch (err) {
      FileUtil.removeFile(pathTemp);
      LogUtil.error(`${TAG} failed to write JSON file:${(err as BusinessError).code}, ${(err as BusinessError).message}.`);
      return false;
    }
  }

  /**
   * 删除path文件夹目录下以.temp结尾的临时文件
   *
   * @param path 文件路径
   */
  /* instrument ignore next */
  public static async deleteTempFile(path: string): Promise<boolean> {
    try {
      const filenames = await FileUtil.listFile(path, FileUtil.TEMP_SUFFIX);
      filenames.forEach(filename => {
        const fullPath = path + filename;
        if (FileUtil.exists(fullPath)) {
          FileUtil.removeFile(fullPath);
        }
      });
      LogUtil.info(`${TAG} delete temp file ${filenames?.length} succeed.`);
      return true;
    } catch (err) {
      LogUtil.error(`${TAG} delete temp file failed, ${(err as BusinessError).message}.`);
      return false;
    }
  }

  /**
   * 同步接口, 获取当前路径下的对应后缀的文件名
   *
   * @param path 文件夹路径
   * @param suffix 文件后缀
   * @returns 文件名数组
   */
  public static listFileSync(path: string, suffix: string[]): string[] {
    try {
      const isNoSuffix = suffix.length === 0;
      const filenames: string[] = fs.listFileSync(path);
      const filteredNames: string[] = filenames.filter(filename => {
        return isNoSuffix || suffix.some(extname => filename.endsWith(extname));
      });
      return filteredNames;
    } catch (e) {
      LogUtil.error(TAG + ` listFileSync failed, code: ${e.code}, message: ${e.message}`);
    }
    return [];
  }

  /**
   * 获取对应文件的统计信息
   *
   * @param path 文件路径
   * @returns 统计信息
   */
  public static statSync(path: string): FileStat {
    let ino = '';
    let inode = -1;
    let modifyTime = Date.now();
    let size = 0;
    try {
      const stat = fs.statSync(path);
      ino = stat.ino.toString();
      inode = Number(stat.ino & 0xFFFFFFFFn);
      modifyTime = stat.mtime * 1000;
      size = stat.size;
    } catch (e) {
      LogUtil.error(TAG + ` statSync failed, code: ${e.code}, message: ${e.message}`);
    }
    return {
      ino,
      inode,
      modifyTime,
      size
    };
  }

  /**
   * 获取对应文件夹占用的硬盘总量
   *
   * @param path 文件夹路径
   * @param fileNames 文件名
   * @returns 文件占用的硬盘总量
   */
  public static getSpecificFileSize(path: string, fileNames: string[]): number {
    let totalSize: number = 0;
    try {
      for (let fileName of fileNames) {
        const filePath = `${path}/${fileName}`
        const statSync = FileUtil.statSync(filePath);
        totalSize += statSync.size;
      }
    } catch (e) {
      LogUtil.error(TAG + ` getSpecificFileSize failed, code: ${e.code}, message: ${e.message}`);
    }
    return totalSize;
  }

  /**
   * 获取转义后的字符串，防止value中含有特殊字符，可扩展
   *
   * @param value 需要转义的字符串（目前包含% _ \ 三个）
   * @returns 转义字符串
   */
  public static getEscapeString(value: string): string {
    return value.replace(/[%_\\]/g, '\\$&');
  }

}

@Concurrent
async function moveFile(tag: string, src: string, dest: string): Promise<boolean> {
  try {
    hiTraceMeter.startTrace('move-file', 0);
    await fs.moveFile(src, dest);
    hiTraceMeter.finishTrace('move-file', 0);
    return true;
  } catch (e) {
    LogUtil.error(`${tag} failed to move file, code: ${e.code}, message: ${e.message}`);
    return false;
  }
}

@Concurrent
async function copyFile(tag: string, src: string, dest: string): Promise<boolean> {
  try {
    hiTraceMeter.startTrace('copy-file', 0);
    await fs.copyFile(src, dest);
    hiTraceMeter.finishTrace('copy-file', 0);
    return true;
  } catch (e) {
    LogUtil.error(`${tag} failed to copy file, code: ${e.code}, message: ${e.message}`);
    return false;
  }
}

@Concurrent
async function listFile(
  tag: string,
  path: string,
  suffix: string[] = [],
  displayName: string[] = []
): Promise<string[]> {
  const t1 = Date.now();
  let result: string[] = [];

  try {
    const filenames = await fs.listFile(path);
    const isSuffixEmpty = suffix.length === 0;
    const isDisplayNameEmpty = displayName.length === 0;

    result = filenames.filter(filename => {
      const isValidSuffix = isSuffixEmpty || suffix.some(extname => filename.endsWith(extname));
      if (!isValidSuffix) {
        return false;
      }
      const isValidDisplayName = isDisplayNameEmpty || displayName.some(name => filename.includes(name));
      return isValidDisplayName;
    });
  } catch (e) {
    LogUtil.error(`${tag} failed to list file, code: ${e.code}, message: ${e.message}`);
  }

  const t2 = Date.now();
  LogUtil.info(`${tag} list file, elapsed time: ${t2 - t1}ms, result: ${result.length}`);

  return result;
}

@Concurrent
async function getDuration(tag: string, path: string): Promise<number> {
  let fileFd = -1;
  let duration = 0;
  let extractor: media.AVMetadataExtractor | undefined = undefined;

  if (canIUse('SystemCapability.Multimedia.Media.AVMetadataExtractor')) {
    try {
      extractor = await media.createAVMetadataExtractor();
      const file = fs.openSync(path, fs.OpenMode.READ_ONLY);
      fileFd = file.fd;
      extractor.fdSrc = { fd: fileFd };
      const metaData = await extractor.fetchMetadata();
      duration = Number(metaData.duration ?? 0);
    } catch (e) {
      LogUtil.error(`${tag} failed to get duration, code: ${e.code}, message: ${e.message}`);
    } finally {
      if (fileFd > -1) {
        fs.close(fileFd).catch((e: BusinessError) => {
          LogUtil.error(`${tag} failed to close file, code: ${e.code}, message: ${e.message}`);
        });
      }
      extractor?.release().catch((e: BusinessError) => {
        LogUtil.error(`${tag} failed to release extractor, code: ${e.code}, message: ${e.message}`);
      });
    }
  }

  return duration;
}