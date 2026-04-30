import {
  Injectable,
  NotFoundException,
  ForbiddenException,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as crypto from 'crypto';
import type { Response } from 'express';
import { Vehicle } from './vehicle.entity.js';
import { CreateVehicleDto } from './dto/create-vehicle.dto.js';
import { UpdateVehicleDto } from './dto/update-vehicle.dto.js';
import { LocalStorageService } from '../storage/local-storage.service.js';
import { processVehicleImage, detectImageMime, isAllowedImageMime } from '../storage/image.util.js';

@Injectable()
export class VehiclesService {
  private readonly logger = new Logger(VehiclesService.name);

  constructor(
    @InjectRepository(Vehicle)
    private readonly vehiclesRepo: Repository<Vehicle>,
    private readonly storage: LocalStorageService,
  ) {}

  findAllForUser(userId: string): Promise<Vehicle[]> {
    return this.vehiclesRepo.find({
      where: { userId },
      relations: ['documents'],
      order: { createdAt: 'ASC' },
    });
  }

  async findOne(id: string, userId: string): Promise<Vehicle> {
    const vehicle = await this.vehiclesRepo.findOne({
      where: { id },
      relations: ['documents'],
    });
    if (!vehicle) throw new NotFoundException('Vehicle not found');
    if (vehicle.userId !== userId) throw new ForbiddenException();
    return vehicle;
  }

  create(userId: string, dto: CreateVehicleDto): Promise<Vehicle> {
    const vehicle = this.vehiclesRepo.create({ ...dto, userId });
    return this.vehiclesRepo.save(vehicle);
  }

  async update(
    id: string,
    userId: string,
    dto: UpdateVehicleDto,
  ): Promise<Vehicle> {
    const vehicle = await this.findOne(id, userId);
    Object.assign(vehicle, dto);
    return this.vehiclesRepo.save(vehicle);
  }

  async remove(id: string, userId: string): Promise<void> {
    const vehicle = await this.findOne(id, userId);
    if (vehicle.imagePath) {
      await this.storage.delete(vehicle.imagePath).catch((err: unknown) => {
        this.logger.warn(`Could not delete image ${vehicle.imagePath}: ${String(err)}`);
      });
    }
    await this.vehiclesRepo.remove(vehicle);
  }

  async setImage(id: string, userId: string, buffer: Buffer): Promise<Vehicle> {
    const vehicle = await this.findOne(id, userId);

    const detectedMime = detectImageMime(buffer);
    if (!isAllowedImageMime(detectedMime)) {
      throw new BadRequestException(
        'Unsupported image format. Allowed: JPEG, PNG, WebP, HEIC.',
      );
    }

    const { buffer: processed, mimeType, ext } = await processVehicleImage(buffer);
    const filename = `${id}-${crypto.randomUUID()}.${ext}`;
    const storedPath = await this.storage.saveBuffer('vehicles', filename, processed);

    if (vehicle.imagePath) {
      await this.storage.delete(vehicle.imagePath).catch((err: unknown) => {
        this.logger.warn(`Could not delete old image ${vehicle.imagePath}: ${String(err)}`);
      });
    }

    vehicle.imagePath = storedPath;
    vehicle.imageMimeType = mimeType;
    return this.vehiclesRepo.save(vehicle);
  }

  async clearImage(id: string, userId: string): Promise<Vehicle> {
    const vehicle = await this.findOne(id, userId);
    if (vehicle.imagePath) {
      await this.storage.delete(vehicle.imagePath).catch((err: unknown) => {
        this.logger.warn(`Could not delete image ${vehicle.imagePath}: ${String(err)}`);
      });
      vehicle.imagePath = null;
      vehicle.imageMimeType = null;
      return this.vehiclesRepo.save(vehicle);
    }
    return vehicle;
  }

  async streamImage(id: string, userId: string, res: Response): Promise<void> {
    const vehicle = await this.findOne(id, userId);
    if (!vehicle.imagePath) throw new NotFoundException('No image for this vehicle');
    res.setHeader('Content-Type', vehicle.imageMimeType ?? 'image/webp');
    res.setHeader('Cache-Control', 'private, max-age=86400');
    this.storage.streamFile(vehicle.imagePath, res);
  }
}
