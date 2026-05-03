import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as path from 'path';
import * as crypto from 'crypto';
import { Attachment, AttachmentKind } from './attachment.entity.js';
import { CreateAttachmentDto } from './dto/create-attachment.dto.js';
import { UpdateAttachmentDto } from './dto/update-attachment.dto.js';
import { VehiclesService } from '../vehicles/vehicles.service.js';
import { LocalStorageService } from '../storage/local-storage.service.js';
import type { Response } from 'express';

const ALLOWED_MIMES = new Set([
  'application/pdf',
  'image/jpeg',
  'image/png',
  'image/webp',
]);

const MIME_EXT: Record<string, string> = {
  'application/pdf': 'pdf',
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
};

// Magic-byte signatures for allowed types
const MAGIC: Array<{ mime: string; bytes: number[]; offset?: number }> = [
  { mime: 'application/pdf', bytes: [0x25, 0x50, 0x44, 0x46] }, // %PDF
  { mime: 'image/jpeg', bytes: [0xff, 0xd8, 0xff] },
  { mime: 'image/png', bytes: [0x89, 0x50, 0x4e, 0x47] },
  { mime: 'image/webp', bytes: [0x52, 0x49, 0x46, 0x46], offset: 0 },
];

function detectMime(buffer: Buffer): string | null {
  for (const { mime, bytes, offset = 0 } of MAGIC) {
    if (bytes.every((b, i) => buffer[offset + i] === b)) {
      if (mime === 'image/webp') {
        const webp = [0x57, 0x45, 0x42, 0x50];
        if (!webp.every((b, i) => buffer[8 + i] === b)) continue;
      }
      return mime;
    }
  }
  return null;
}

@Injectable()
export class AttachmentsService {
  private readonly logger = new Logger(AttachmentsService.name);

  constructor(
    @InjectRepository(Attachment)
    private readonly repo: Repository<Attachment>,
    private readonly vehiclesService: VehiclesService,
    private readonly storage: LocalStorageService,
  ) {}

  async findAllForVehicle(
    vehicleId: string,
    userId: string,
  ): Promise<Attachment[]> {
    await this.vehiclesService.findOne(vehicleId, userId);
    return this.repo.find({
      where: { vehicleId },
      order: { createdAt: 'DESC' },
      select: [
        'id',
        'vehicleId',
        'kind',
        'originalFilename',
        'mimeType',
        'sizeBytes',
        'expirationDate',
        'notes',
        'createdAt',
        'updatedAt',
      ],
    });
  }

  async findOne(id: string, userId: string): Promise<Attachment> {
    const attachment = await this.repo.findOne({
      where: { id },
      relations: ['vehicle'],
    });
    if (!attachment) throw new NotFoundException('Attachment not found');
    if (attachment.vehicle.userId !== userId) throw new ForbiddenException();
    return attachment;
  }

  async create(
    userId: string,
    vehicleId: string,
    dto: CreateAttachmentDto,
    file: Express.Multer.File,
  ): Promise<Omit<Attachment, 'storedPath' | 'vehicle'>> {
    await this.vehiclesService.findOne(vehicleId, userId);

    const detectedMime = detectMime(file.buffer);
    if (!detectedMime || !ALLOWED_MIMES.has(detectedMime)) {
      throw new BadRequestException(
        'Unsupported file type. Allowed: PDF, JPEG, PNG, WebP.',
      );
    }

    const ext = MIME_EXT[detectedMime];
    const filename = `${crypto.randomUUID()}.${ext}`;
    const storedPath = await this.storage.saveBuffer(
      `attachments/${vehicleId}`,
      filename,
      file.buffer,
    );

    const originalFilename = this.sanitizeFilename(file.originalname);

    const attachment = this.repo.create({
      vehicleId,
      kind: dto.kind ?? AttachmentKind.OTHER,
      originalFilename,
      storedPath,
      mimeType: detectedMime,
      sizeBytes: file.size,
      expirationDate: dto.expirationDate ?? null,
      notes: dto.notes ?? null,
    });

    const saved = await this.repo.save(attachment);
    const {
      storedPath: _sp,
      vehicle: _v,
      ...safe
    } = saved as Attachment & { vehicle?: unknown };
    void _sp;
    void _v;
    return safe;
  }

  async streamFile(id: string, userId: string, res: Response): Promise<void> {
    const attachment = await this.findOne(id, userId);
    res.setHeader('Content-Type', attachment.mimeType);
    res.setHeader(
      'Content-Disposition',
      `inline; filename="${encodeURIComponent(attachment.originalFilename)}"`,
    );
    this.storage.streamFile(attachment.storedPath, res);
  }

  async update(
    id: string,
    userId: string,
    dto: UpdateAttachmentDto,
  ): Promise<Attachment> {
    const attachment = await this.findOne(id, userId);
    if (dto.kind !== undefined) attachment.kind = dto.kind;
    if (dto.expirationDate !== undefined)
      attachment.expirationDate = dto.expirationDate;
    if (dto.notes !== undefined) attachment.notes = dto.notes;
    return this.repo.save(attachment);
  }

  async remove(id: string, userId: string): Promise<void> {
    const attachment = await this.findOne(id, userId);
    const { storedPath } = attachment;
    await this.repo.remove(attachment);
    await this.storage.delete(storedPath).catch((err: unknown) => {
      this.logger.warn(`Could not delete file ${storedPath}: ${String(err)}`);
    });
  }

  private sanitizeFilename(name: string): string {
    return (
      path
        .basename(name)
        .replace(/[^\w.-]/g, '_')
        .slice(0, 255) || 'file'
    );
  }
}
