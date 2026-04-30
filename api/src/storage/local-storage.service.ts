import { Injectable, NotFoundException } from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import type { Response } from 'express';

@Injectable()
export class LocalStorageService {
  private readonly root: string;

  constructor() {
    this.root = path.resolve(process.env.STORAGE_ROOT ?? './uploads');
    fs.mkdirSync(this.root, { recursive: true });
  }

  /** Save `buffer` as `<subdir>/<filename>` under the storage root. */
  async saveBuffer(subdir: string, filename: string, buffer: Buffer): Promise<string> {
    const dir = path.join(this.root, subdir);
    fs.mkdirSync(dir, { recursive: true });
    const relativePath = path.join(subdir, filename);
    await fs.promises.writeFile(path.join(this.root, relativePath), buffer);
    return relativePath;
  }

  /** Delete the file at the given relative path (silently ignores if already gone). */
  async delete(relativePath: string): Promise<void> {
    const abs = path.join(this.root, relativePath);
    await fs.promises.unlink(abs).catch(() => undefined);
  }

  /** Resolve a relative path to an absolute path for streaming. */
  absolutePath(relativePath: string): string {
    return path.join(this.root, relativePath);
  }

  /** Stream the file to the response. Sets Content-Type from caller. */
  streamFile(relativePath: string, res: Response): void {
    const abs = path.join(this.root, relativePath);
    if (!fs.existsSync(abs)) throw new NotFoundException('File not found');
    fs.createReadStream(abs).pipe(res);
  }

  /** Check whether a file exists. */
  exists(relativePath: string): boolean {
    return fs.existsSync(path.join(this.root, relativePath));
  }
}
