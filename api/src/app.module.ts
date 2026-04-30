import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';

import databaseConfig from './config/database.config.js';
import { StorageModule } from './storage/storage.module.js';
import { AuthModule } from './auth/auth.module.js';
import { UsersModule } from './users/users.module.js';
import { VehiclesModule } from './vehicles/vehicles.module.js';
import { DocumentsModule } from './documents/documents.module.js';
import { AttachmentsModule } from './attachments/attachments.module.js';
import { NotificationsModule } from './notifications/notifications.module.js';

@Module({
  imports: [
    // ── Config ───────────────────────────────────────────────
    ConfigModule.forRoot({
      isGlobal: true,
      load: [databaseConfig],
      envFilePath: `.env.${process.env.NODE_ENV ?? 'development'}`,
    }),

    // ── Database ─────────────────────────────────────────────
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) =>
        config.get('database') as Record<string, unknown>,
    }),

    // ── Cron scheduler ───────────────────────────────────────
    ScheduleModule.forRoot(),

    // ── Feature modules ──────────────────────────────────────
    StorageModule,
    AuthModule,
    UsersModule,
    VehiclesModule,
    DocumentsModule,
    AttachmentsModule,
    NotificationsModule,
  ],
})
export class AppModule {}
