import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, LessThanOrEqual, MoreThan, Between } from 'typeorm';
import { Document, DocumentStatus, DocumentType } from './document.entity.js';
import { CreateDocumentDto } from './dto/create-document.dto.js';
import { UpdateDocumentDto } from './dto/update-document.dto.js';
import { VehiclesService } from '../vehicles/vehicles.service.js';

@Injectable()
export class DocumentsService {
  constructor(
    @InjectRepository(Document)
    private readonly docsRepo: Repository<Document>,
    private readonly vehiclesService: VehiclesService,
  ) {}

  // ── CRUD ────────────────────────────────────────────────────

  async findAllForVehicle(vehicleId: string, userId: string): Promise<Document[]> {
    // Ownership check via VehiclesService
    await this.vehiclesService.findOne(vehicleId, userId);
    return this.docsRepo.find({
      where: { vehicleId },
      order: { documentType: 'ASC' },
    });
  }

  async findOne(id: string, userId: string): Promise<Document> {
    const doc = await this.docsRepo.findOne({
      where: { id },
      relations: ['vehicle'],
    });
    if (!doc) throw new NotFoundException('Document not found');
    if (doc.vehicle.userId !== userId) throw new ForbiddenException();
    return doc;
  }

  async create(
    userId: string,
    vehicleId: string,
    dto: CreateDocumentDto,
  ): Promise<Document> {
    // Ownership check
    await this.vehiclesService.findOne(vehicleId, userId);

    // Upsert: only one document per type per vehicle
    const existing = await this.docsRepo.findOne({
      where: { vehicleId, documentType: dto.documentType },
    });
    if (existing) {
      throw new ConflictException(
        `A ${dto.documentType} document already exists for this vehicle. Use PATCH to update it.`,
      );
    }

    const doc = this.docsRepo.create({
      ...dto,
      vehicleId,
      status: this.computeStatus(dto.expirationDate),
    });
    return this.docsRepo.save(doc);
  }

  async update(
    id: string,
    userId: string,
    dto: UpdateDocumentDto,
  ): Promise<Document> {
    const doc = await this.findOne(id, userId);
    if (dto.issueDate) doc.issueDate = dto.issueDate;
    if (dto.expirationDate) {
      doc.expirationDate = dto.expirationDate;
      doc.status = this.computeStatus(dto.expirationDate);
    }
    return this.docsRepo.save(doc);
  }

  async remove(id: string, userId: string): Promise<void> {
    const doc = await this.findOne(id, userId);
    await this.docsRepo.remove(doc);
  }

  // ── Status helpers ──────────────────────────────────────────

  /** Derives DocumentStatus from the expiration date relative to today. */
  computeStatus(expirationDateStr: string): DocumentStatus {
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const expiry = new Date(expirationDateStr);
    expiry.setHours(0, 0, 0, 0);

    const msPerDay = 1000 * 60 * 60 * 24;
    const daysLeft = Math.floor((expiry.getTime() - today.getTime()) / msPerDay);

    if (daysLeft < 0) return DocumentStatus.EXPIRED;
    if (daysLeft <= 30) return DocumentStatus.EXPIRING_SOON;
    return DocumentStatus.ACTIVE;
  }

  /**
   * Called daily by the cron job to refresh the `status` column for every
   * document, keeping the denormalised field in sync with the current date.
   */
  async refreshAllStatuses(): Promise<void> {
    const allDocs = await this.docsRepo.find();
    const updated = allDocs.map((doc) => ({
      ...doc,
      status: this.computeStatus(doc.expirationDate),
    }));
    await this.docsRepo.save(updated);
  }

  /**
   * Returns documents whose expiration date is exactly `days` days from today.
   * Used by the notification cron job.
   */
  async findExpiringIn(days: number): Promise<Document[]> {
    const target = new Date();
    target.setHours(0, 0, 0, 0);
    target.setDate(target.getDate() + days);

    const dayStart = new Date(target);
    const dayEnd = new Date(target);
    dayEnd.setHours(23, 59, 59, 999);

    return this.docsRepo.find({
      where: {
        expirationDate: Between(
          dayStart.toISOString().split('T')[0],
          dayEnd.toISOString().split('T')[0],
        ) as unknown as string,
      },
      relations: ['vehicle', 'vehicle.user'],
    });
  }

  /** Returns all documents that are already expired (used for bulk queries). */
  findExpired(): Promise<Document[]> {
    const today = new Date().toISOString().split('T')[0];
    return this.docsRepo.find({
      where: { expirationDate: LessThanOrEqual(today) as unknown as string },
      relations: ['vehicle', 'vehicle.user'],
    });
  }

  /** Returns all documents expiring within the next `days` days. */
  findExpiringSoon(days: number): Promise<Document[]> {
    const today = new Date();
    const future = new Date();
    future.setDate(today.getDate() + days);

    return this.docsRepo.find({
      where: {
        expirationDate: Between(
          today.toISOString().split('T')[0],
          future.toISOString().split('T')[0],
        ) as unknown as string,
      },
      relations: ['vehicle', 'vehicle.user'],
    });
  }
}
