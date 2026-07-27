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

import fs, { WatchEvent } from '@ohos.file.fs';
import { FileUtil, Helps, LogUtil, PathUtil } from '@ohos/common';
import FileManager from '../manager/FileManager';

enum Event {
  IN_CLOSE_WRITE = 0x8,
  IN_MOVED_FROM = 0x40,
  IN_MOVED_TO = 0x80,
  IN_CREATE = 0x100,
  IN_DELETE = 0x200,
  IN_MOVE_SELF = 0x800
}

enum Action {
  DELETE = -1,
  INSERT = 1,
  MOVE_TO = 2,
  MOVE_FROM = 3,
}

const events = Event.IN_MOVED_FROM | Event.IN_MOVED_TO | Event.IN_CREATE | Event.IN_DELETE | Event.IN_MOVE_SELF |
Event.IN_CLOSE_WRITE;

interface CacheItem {
  action: Action;
  path: string;
  cookie: number
}

const TAG = 'SoundRecorder_FileWatcher';

export abstract class FileWatcher {
  /**
   * 延迟500ms，意在捕获文管操作，避开新增录音、迁移过程场景
   */
  private static readonly DISPATCH_DELAY = 500;
  private cache: CacheItem[] = [];
  private path: string;
  private watcher?: fs.Watcher;
  private subDir: string[] = [];
  private timer: number = -1;

  constructor(path: string, subDir: string[] = []) {
    this.path = path;
    this.subDir = subDir;
  }

  public start(): void {
    try {
      if (!this.watcher) {
        this.watcher = this.createWatcher(this.path);
      }
      if (this.watcher) {
        this.watcher.start();
        LogUtil.info(`${TAG} start ok.`);
      }
    } catch (e) {
      LogUtil.error(`${TAG} failed to start, code: ${e.code}, message: ${e.message}`);
    }
  }

  public stop(): void {
    try {
      if (this.watcher) {
        this.watcher.stop();
        this.watcher = undefined;
        LogUtil.info(`${TAG} stop ok.`);
      }
    } catch (e) {
      LogUtil.error(`${TAG} failed to stop, code: ${e.code}, message: ${e.message}`);
    }
  }

  protected abstract onDelete(path: string): Promise<void>;

  protected abstract onInsert(path: string): Promise<void>;

  protected abstract onSelfDelete(): Promise<void>;

  protected abstract onSubDirDelete(dir: string): Promise<void>;

  protected abstract onRename(oldPath: string, newPath: string): Promise<void>;

  protected abstract onSubDirCreate(dir: string): Promise<void>;

  private createWatcher(path: string): fs.Watcher | undefined {
    let watcher: fs.Watcher | undefined;

    try {
      watcher = fs.createWatcher(path, events, (e: WatchEvent) => {
        this.storeCache(e);
      });
    } catch (e) {
      LogUtil.error(`${TAG} failed to create watcher, code: ${e.code}, message: ${e.message}`);
    }

    return watcher;
  }

  private isDelete(event: Event): boolean {
    return [Event.IN_DELETE, Event.IN_MOVE_SELF].includes(event);
  }

  private isInsert(event: Event): boolean {
    return [Event.IN_CREATE, Event.IN_CLOSE_WRITE].includes(event);
  }

  private isMove(event: Event): boolean {
    return [Event.IN_MOVED_FROM, Event.IN_MOVED_TO].includes(event);
  }

  // 需要处理同文件覆盖场景，覆盖操作对应的事件依次为IN_DELETE，IN_CREATE，IN_CLOSE_WRITE
  private handleInsertAction(event: Event, cookie: number, path: string) {
    if (event == Event.IN_CLOSE_WRITE && this.cache.length >= 2) {
      let oneItem = this.cache[this.cache.length-2];
      let twoItem = this.cache[this.cache.length-1];
      if (oneItem.action === Action.DELETE && twoItem.action === Action.INSERT && oneItem.path === twoItem.path &&
        twoItem.path === path) {
        this.cache.pop();
        this.cache.pop();
      }
    } else {
      this.cache.push({ cookie, action: Action.INSERT, path });
    }
  }

  private storeCache(e: WatchEvent): void {
    if (this.timer !== -1) {
      clearTimeout(this.timer);
    }
    const event = e.event;
    const path = e.fileName;
    const cookie = e.cookie;

    if (this.isDelete(event)) {
      this.cache.push({ cookie, action: Action.DELETE, path });
    } else if (this.isInsert(event)) {
      this.handleInsertAction(event, cookie, path);
    } else if (this.isMove(event)) {
      if (event === Event.IN_MOVED_FROM) {
        this.cache.push({ cookie, action: Action.MOVE_FROM, path });
      } else if (event === Event.IN_MOVED_TO) {
        this.cache.push({ cookie, action: Action.MOVE_TO, path });
      }
    }
    this.timer = setTimeout(() => {
      this.takeCache();
    }, FileWatcher.DISPATCH_DELAY);
  }

  private shakeoutCache(): CacheItem[] {
    return this.cache
      .reverse()
      .filter((x, index, arr) => index === arr.findIndex(y => y.action === x.action && y.path === x.path))
      .reverse();
  }

  private async takeCache() {
    this.cache = this.shakeoutCache();
    while (this.cache.length > 0) {
      const item = this.cache.shift();
      if (item === undefined) {
        continue;
      }
      if (!FileUtil.isAudioFile(item.path)) {
        this.dispatchDir(item);
        continue;
      }
      if (item.action === Action.DELETE) {
        await this.onDelete(item.path);
      } else if (item.action === Action.INSERT) {
        await this.onInsert(item.path)
      } else if (item.action === Action.MOVE_TO) {
        await this.onInsert(item.path)
      } else if (item.action === Action.MOVE_FROM) {
        let isRename = false;
        let moveToIndex = -1;
        for (let i = 0; i < this.cache.length; i++) {
          if (this.cache[i].action === Action.MOVE_TO && item.cookie === this.cache[i].cookie) {
            isRename = true;
            moveToIndex = i;
            break;
          }
        }
        if (isRename) {
          await this.onRename(item.path, this.cache[moveToIndex].path);
          this.cache.splice(moveToIndex, 1);
        } else {
          await this.onDelete(item.path);
        }
      }
    }
    this.timer = -1;
  }

  private async dispatchDir(item: CacheItem): Promise<void> {
    const path = item.path;
    if (item.action === Action.INSERT) {
      if (this.isSubDir(path)) {
        await this.onSubDirCreate(PathUtil.basename(path));
      }
    }

    if (item.action !== Action.DELETE) {
      return;
    }

    if (path === this.path) {
      await this.onSelfDelete();
    } else if (this.isSubDir(path)) {
      await this.onSubDirDelete(PathUtil.basename(path));
    }
  }

  private isSubDir(path: string): boolean {
    return this.subDir.map(dir => `${this.path}/${dir}`).some(i => i === path);
  }
}