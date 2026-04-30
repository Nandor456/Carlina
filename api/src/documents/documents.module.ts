import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Document } from './document.entity.js';
import { DocumentsService } from './documents.service.js';
import { DocumentsController } from './documents.controller.js';
import { VehiclesModule } from '../vehicles/vehicles.module.js';

@Module({
  imports: [TypeOrmModule.forFeature([Document]), VehiclesModule],
  providers: [DocumentsService],
  controllers: [DocumentsController],
  exports: [DocumentsService],
})
export class DocumentsModule {}
