import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { MulterModule } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { Attachment } from './attachment.entity.js';
import { AttachmentsService } from './attachments.service.js';
import { AttachmentsController } from './attachments.controller.js';
import { VehiclesModule } from '../vehicles/vehicles.module.js';

@Module({
  imports: [
    TypeOrmModule.forFeature([Attachment]),
    VehiclesModule,
    MulterModule.register({ storage: memoryStorage() }),
  ],
  providers: [AttachmentsService],
  controllers: [AttachmentsController],
})
export class AttachmentsModule {}
