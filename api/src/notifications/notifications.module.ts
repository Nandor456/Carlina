import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service.js';
import { DocumentsModule } from '../documents/documents.module.js';

@Module({
  imports: [DocumentsModule],
  providers: [NotificationsService],
})
export class NotificationsModule {}
