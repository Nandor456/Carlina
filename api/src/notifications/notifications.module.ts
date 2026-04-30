import { Module } from '@nestjs/common';
import { NotificationsService } from './notifications.service.js';
import { DocumentsModule } from '../documents/documents.module.js';
import { UsersModule } from '../users/users.module.js';
import { FirebaseModule } from '../firebase/firebase.module.js';

@Module({
  imports: [DocumentsModule, UsersModule, FirebaseModule],
  providers: [NotificationsService],
})
export class NotificationsModule {}
