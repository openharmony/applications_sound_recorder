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

import fs from '@ohos.file.fs';
import ArrayList from '@ohos.util.ArrayList';
import { LogUtil } from '../utils/LogUtil';
import { taskpool } from '@kit.ArkTS';
import { FileUtil } from '../utils/FileUtil';

/**
 * 波形图数据保存录音文件中的一些常量数据
 */
export class SampleDataConstant {
  public static readonly LEN_HEAD_TOTAL_LENGTH: number = 4;
  public static readonly LEN_HEAD_UUID: number = 4;
  public static readonly LEN_HEAD_UUID_AFTER: number = 16;
  public static readonly LEN_BODY_END_LENGTH: number = 4;
  public static readonly LEN_BODY_END_TAG: number = 4;
  public static readonly SAMPLE_LEN: number = 2;
  public static readonly UUID: string = 'uuid';
  public static readonly UUID_AFTER: number[] = [0x0, 0x0, 0x0, 0x0];
  public static readonly END_TAG: number[] = [0xFF, 0xFF, 0xFF, 0xFF];
  public static readonly RECORD_FILE_SUFFIX: string = '.m4a'; // 录音文件后缀
  public static readonly SAMPLE_FILE_SUFFIX: string = '.tmp'; // 临时保存波形数据的文件后缀
  // 每秒多少个采样数据
  public static readonly SAMPLES_PRE_SECOND: number = 6;
  // 振幅值转波形值的比例，参照双框架源码: rate = 最大振幅 / 波形图可显示的最大值 —— 32768 / 230 ≈ 140
  public static AMPLITUDE_TO_WAVE_RATE: number = 140;
  // 波形图文件的最大大小为200M，录制时长大约为1846小时
  public static readonly MAX_WAVE_FILE_SIZE = 200 * 1024 * 1024;
}

const TAG: string = 'SoundRecorder_SampleUtil';

export default class SampleUtil {
  /**
   * 构建波形图数据的字节数组
   *
   * @param samples 波形数据
   * @returns DataView
   */
  public static buildWaveSampleBytes(samples: number[]): DataView {
    LogUtil.info(TAG + ': buildWaveSampleBytes start. Samples length: ' + samples.length);
    let headLen: number = getHeadDataLength();
    let sampleDataLen: number = samples.length * 2;
    let tailDataLen: number = getTailDataLength();
    let totalLen: number = headLen + sampleDataLen + tailDataLen;
    let buffer: ArrayBuffer = new ArrayBuffer(totalLen);
    let dataView: DataView = new DataView(buffer);
    let offset: number = 0;
    // total length
    dataView.setInt32(offset, totalLen, false);
    offset += SampleDataConstant.LEN_HEAD_TOTAL_LENGTH;
    // uuid
    for (let i = 0; i < SampleDataConstant.UUID.length; i++) {
      dataView.setInt8(offset + i, SampleDataConstant.UUID.charCodeAt(i));
    }
    offset += SampleDataConstant.LEN_HEAD_UUID;
    // 16 bytes: 0x00 0x00 0x00 0x00
    for (let i = 0; i < SampleDataConstant.UUID_AFTER.length; i++) {
      dataView.setInt32(offset + i * 4, SampleDataConstant.UUID_AFTER[i]);
    }
    offset += SampleDataConstant.LEN_HEAD_UUID_AFTER;
    // raw samples
    for (let sample of samples) {
      dataView.setInt16(offset, sample, true);
      offset += SampleDataConstant.SAMPLE_LEN;
    }
    // body length
    let bodyLen: number = sampleDataLen + tailDataLen;
    dataView.setInt32(offset, bodyLen, true);
    offset += SampleDataConstant.LEN_BODY_END_LENGTH;
    // end mark
    for (let i = 0; i < SampleDataConstant.END_TAG.length; i++) {
      dataView.setInt8(offset + i, SampleDataConstant.END_TAG[i]);
    }
    LogUtil.info(TAG + ': buildWaveSampleBytes end. DataView bytes length: ' + dataView.byteLength);
    return dataView;
  }

  /**
   * 从录音文件中读取出波形数据
   *
   * @param path 文件路径
   * @returns 波形数据
   */
  /* instrument ignore next */
  public static async readWaveSamplesFromFile(path: string): Promise<number[]> {
    LogUtil.info(`${TAG} read wave samples from file.`);
    if (!verifySamples(path)) {
      AppStorage.setOrCreate('hasSamples', false);
      return await padEndSamples(path, []);
    }
    let samples = await readSamples(path);
    AppStorage.setOrCreate('hasSamples', samples.length > 0);
    // fix samples 迁移数据
    samples = await SampleUtil.fixSamples(path, samples);
    return samples;
  }

  /**
   * 按照录音文件的录音时长，对采样数据的Size进行“修正”
   * 多余的采样将进行缩减，缺少的采样将进行增补
   *
   * @param path
   * @param samples
   * @returns
   */
  /* instrument ignore next */
  public static async fixSamples(pathOrTime: string | number, samples: number[]): Promise<number[]> {
    // 拿到确切的录音时长
    let audioDuration: number = 0;
    if (typeof pathOrTime === 'number') {
      audioDuration = pathOrTime;
    } else {
      audioDuration = await FileUtil.getDuration(pathOrTime);
    }
    LogUtil.info(`${TAG} fix samples, audioDuration: ${audioDuration}`);
    // 期望的采样数据长度
    const expectSize = Math.ceil(audioDuration / 1000 * SampleDataConstant.SAMPLES_PRE_SECOND);

    try {
      const task = new taskpool.Task('FIX_SAMPLES', fixSamples, TAG, samples, expectSize);
      samples = await taskpool.execute(task) as number[];
    } catch (e) {
      LogUtil.error(`${TAG} failed to fix samples, code: ${e.code}, message: ${e.message}`);
      return samples;
    }

    return samples;
  }

  /**
   * 将振幅转成波形图上的竖线
   *
   * @param sample
   * @returns
   */
  public static sampleToWaveLine(sample: number): number {
    return Math.floor(sample / SampleDataConstant.AMPLITUDE_TO_WAVE_RATE);
  }

  /**
   * 将波形数据写入到录音文件
   *
   * @param path 录音文件路径
   * @param samples 波形数据
   */
  /* instrument ignore next */
  public static writeWaveSamplesToFile(path: string, samples: number[]): void {
    LogUtil.info(TAG + ': writeWaveSamplesToFile start. Samples length: ' + samples.length);
    let buffer: ArrayBuffer = SampleUtil.buildWaveSampleBytes(samples).buffer;
    let fileStat: fs.Stat = fs.statSync(path);
    let fileFd: number = -1;
    let result: number = -1;
    try {
      fileFd = fs.openSync(path, fs.OpenMode.WRITE_ONLY).fd;
      result = fs.writeSync(fileFd, buffer, {
        offset: fileStat.size
      });
      LogUtil.info(TAG + ': writeWaveSamplesToFile end. Result: ' + result);
    } catch (e) {
      LogUtil.error(`${TAG} failed to get duration, code: ${e.code}, message: ${e.message}`);
    } finally {
      fs.closeSync(fileFd);
    }
  }

  /**
   * 紧急情况临时保存波形数据（如用户在录音过程中杀死应用）
   */
  /* instrument ignore next */
  public static saveSamplesEmergency(recordFilePath: string, samples: ArrayList<number>): boolean {
    LogUtil.info(TAG + ': saveSamplesTemporarily start.');
    try {
      let path = recordFilePath.replace(SampleDataConstant.RECORD_FILE_SUFFIX, SampleDataConstant.SAMPLE_FILE_SUFFIX);
      let tmpFile = fs.openSync(path, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE);
      // 将 Json 写入 .tmp 文件
      let result = fs.writeSync(tmpFile.fd, JSON.stringify(samples.convertToArray()));
      fs.closeSync(tmpFile.fd);
      LogUtil.info(TAG + ': saveSamplesTemporarily success. ' + result);
      return result > 0;
    } catch (err) {
      LogUtil.error(TAG + ` saveSamplesEmergency failed, code: ${err?.code}, message: ${err?.message}`);
    }
    return false;
  }

  /**
   * 将临时保存的波形图数据合并到对应录音文件中
   */
  /* instrument ignore next */
  public static async recoverSamplesToRecordFile(recordFilePath: string): Promise<void> {
    LogUtil.info(TAG + ': mergeSamplesToRecordFile start.');
    // 波形数据文件名
    let sampleTmpFilePath: string = recordFilePath
      .replace(SampleDataConstant.RECORD_FILE_SUFFIX, SampleDataConstant.SAMPLE_FILE_SUFFIX);
    if (sampleTmpFilePath === recordFilePath) {
      LogUtil.error(TAG + ': sampleTmpFilePath equals recordFilePath please check');
      return;
    }

    try {
      const fileStat: fs.Stat = fs.statSync(sampleTmpFilePath);
      LogUtil.error(TAG + 'recoverSamplesToRecordFile ' + fileStat.size); // E level for commercial maintenance
      if (fileStat.size < SampleDataConstant.MAX_WAVE_FILE_SIZE) {
        let content: string = fs.readTextSync(sampleTmpFilePath);
        // 解析出波形数据
        let samples: number[] = JSON.parse(content) as Array<number>;
        // 波形数据和录音文件合并
        samples = await SampleUtil.fixSamples(recordFilePath, samples);
        SampleUtil.writeWaveSamplesToFile(recordFilePath, samples);
        LogUtil.info(TAG + ': mergeSamplesToRecordFile success.');
      }
    } catch (err) {
      LogUtil.error(TAG + ` mergeSamplesToRecordFile failed, code: ${err?.code}, message: ${err?.message}`);
    }
    try {
      // 删除 .tmp 文件
      fs.unlink(sampleTmpFilePath);
    } catch (err) {
      LogUtil.error(TAG + ` unlink tmp file failed, code: ${err?.code}, message: ${err?.message}`);
    }
    LogUtil.info(TAG + ': mergeSamplesToRecordFile end.');
  }
}

function getTailDataLength(): number {
  return SampleDataConstant.LEN_BODY_END_LENGTH + SampleDataConstant.LEN_BODY_END_TAG;
}

function getHeadDataLength(): number {
  return SampleDataConstant.LEN_HEAD_TOTAL_LENGTH + SampleDataConstant.LEN_HEAD_UUID +
  SampleDataConstant.LEN_HEAD_UUID_AFTER;
}

/**
 * 校验samples是否合法
 * @param path
 * @returns
 */
/* instrument ignore next */
function verifySamples(path: string): boolean {
  // instrument ignore if
  if (!path) {
    LogUtil.error(`${TAG} failed to verify samples, path is empty.`);
    return false;
  }
  const headLen: number = getHeadDataLength();
  const tailDataLen: number = getTailDataLength();
  let fileFd = -1;
  try {
    const fileStat: fs.Stat = fs.statSync(path);
    fileFd = fs.openSync(path, fs.OpenMode.READ_ONLY).fd;
    let buffer: ArrayBuffer = new ArrayBuffer(tailDataLen);
    fs.readSync(fileFd, buffer, {
      offset: fileStat.size - buffer.byteLength
    });
    const bodyLen: number = new DataView(buffer).getInt32(0, true);
    // instrument ignore if
    if (bodyLen <= 0 || bodyLen >= fileStat.size / 2) {
      // 采样数据大小超过了文件的一半，这肯定不可能。
      LogUtil.error(`${TAG} failed to verify samples, the size of the sampled data exceeds half of the file.`);
      return false;
    }
    buffer = new ArrayBuffer(headLen + bodyLen)
    fs.readSync(fileFd, buffer, {
      offset: fileStat.size - buffer.byteLength
    });
    const dataView: DataView = new DataView(buffer);
    const totalLen: number = dataView.getInt32(0, false);
    // instrument ignore if
    if (totalLen - bodyLen !== headLen) {
      // 采样数据长度不对
      LogUtil.error(`${TAG} failed to verify samples, the sampling data length is incorrect.`);
      return false;
    }
  } catch (e) {
    LogUtil.error(`${TAG} failed to verify samples, cause: code: ${e.code}, message: ${e.message}.`);
    return false;
  } finally {
    fs.closeSync(fileFd);
  }

  return true;
}

/**
 * 读取samples
 * @param path
 * @returns
 */
/* instrument ignore next */
async function readSamples(path: string): Promise<number[]> {
  LogUtil.info(`${TAG} read samples.`);

  const headLen = getHeadDataLength();
  const tailLen = getTailDataLength()

  try {
    const task = new taskpool.Task('TAKEOUT_SAMPLES', takeoutSamples, TAG, path, headLen, tailLen);
    const samples: number[] = await taskpool.execute(task) as number[];
    LogUtil.info(`${TAG} read samples success, samples length: ${samples.length}`);

    return samples;
  } catch (e) {
    LogUtil.error(`${TAG} failed to read samples, code: ${e.code}, message: ${e.message}`);
    return [];
  }
}

/**
 * 取出samples
 * @param tag
 * @param path
 * @param headLen
 * @param tailLen
 * @returns
 */
@Concurrent
async function takeoutSamples(tag: string, path: string, headLen: number, tailLen: number): Promise<number[]> {
  LogUtil.info(`${tag} take out samples.`);
  const samples: number[] = [];
  let fileFd = -1;

  try {
    const fileStat: fs.Stat = fs.statSync(path);
    fileFd = fs.openSync(path, fs.OpenMode.READ_ONLY).fd;
    let buffer: ArrayBuffer = new ArrayBuffer(tailLen);
    fs.readSync(fileFd, buffer, {
      offset: fileStat.size - buffer.byteLength
    });
    const bodyLen: number = new DataView(buffer).getInt32(0, true);
    buffer = new ArrayBuffer(headLen + bodyLen);
    fs.readSync(fileFd, buffer, {
      offset: fileStat.size - buffer.byteLength
    });
    const dataView: DataView = new DataView(buffer);
    for (let i = 0; i < bodyLen - tailLen; i += 2) {
      samples.push(dataView.getInt16(headLen + i, true));
    }
    LogUtil.info(`${tag} take out samples success, samples length: ${samples.length}`);
  } catch (e) {
    LogUtil.error(`${tag} failed to take out samples, code: ${e.code}, message: ${e.message}`);
    return samples;
  } finally {
    fs.closeSync(fileFd);
  }

  return samples;
}

/**
 * pad end sample
 * @param path
 * @param samples
 * @returns
 */
/* instrument ignore next */
async function padEndSamples(path: string, samples: number[]): Promise<number[]> {
  let sampleSize = samples.length;
  const duration = await FileUtil.getDuration(path);
  const expectSize: number = Math.ceil(duration / 1000 * SampleDataConstant.SAMPLES_PRE_SECOND);

  if (expectSize > sampleSize) {
    samples.push(...Array(expectSize - sampleSize).fill(500));
  }

  return samples;
}

@Concurrent
function fixSamples(tag: string, samples: number[], expectSize: number): number[] {
  let samplesSize = samples.length;
  let diffSize = expectSize - samplesSize;
  LogUtil.info(`${tag} fix samples start, expectSize: ${expectSize}, samplesSize: ${samplesSize}, diffSize: ${diffSize}`);
  if (diffSize === 0) {
    return samples;
  }
  if (diffSize > 0) {
    // 扩增样本
    if (samples.length === 0 || diffSize > samples.length / 3) {
      samples.push(...Array(diffSize).fill(500));
    } else {
      let step = Math.floor(samples.length / (diffSize + 1));
      for (let i = 0; i < diffSize; i++) {
        let insertIndex = (diffSize - i) * step - 1;
        samples.splice(insertIndex, 0, samples[insertIndex + 1]);
      }
    }
  } else {
    // 缩减样本
    diffSize = Math.abs(diffSize);
    let step = Math.floor(samples.length / (diffSize + 1));
    for (let i = 0; i < diffSize; i++) {
      let removeIndex = (diffSize - i) * step - 1;
      if (removeIndex >= 0 && removeIndex < samples.length) {
        samples.splice(removeIndex, 1);
      }
    }
  }

  samplesSize = samples.length;
  diffSize = expectSize - samplesSize;
  LogUtil.info(`${tag} fix samples end, expectSize: ${expectSize}, samplesSize: ${samplesSize}, diffSize: ${diffSize}`);

  return samples;
}