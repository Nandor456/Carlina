import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { readFileSync } from 'fs';
import { initializeApp, getApps, cert } from 'firebase-admin/app';
import { getMessaging, type Messaging } from 'firebase-admin/messaging';

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

function pickString(
  obj: Record<string, unknown>,
  keys: string[],
): string | undefined {
  for (const key of keys) {
    const value = obj[key];
    if (typeof value === 'string' && value.trim().length > 0) {
      return value;
    }
  }
  return undefined;
}

@Injectable()
export class FirebaseService implements OnModuleInit {
  private readonly logger = new Logger(FirebaseService.name);
  private messaging: Messaging | null = null;

  onModuleInit() {
    const filePath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH?.trim();
    const base64 = process.env.FIREBASE_SERVICE_ACCOUNT?.trim();

    if (!filePath && !base64) {
      this.logger.warn(
        'Neither FIREBASE_SERVICE_ACCOUNT_PATH nor FIREBASE_SERVICE_ACCOUNT set — push notifications disabled',
      );
      return;
    }

    try {
      const json = filePath
        ? readFileSync(filePath, 'utf-8')
        : Buffer.from(base64!, 'base64').toString('utf-8');
      const parsed: unknown = JSON.parse(json);
      if (!isRecord(parsed)) {
        throw new Error('Firebase service account JSON is invalid');
      }

      const projectId = pickString(parsed, ['project_id', 'projectId']);
      const clientEmail = pickString(parsed, ['client_email', 'clientEmail']);
      const privateKey = pickString(parsed, ['private_key', 'privateKey']);

      if (!projectId || !clientEmail || !privateKey) {
        throw new Error(
          'Firebase service account JSON is missing required fields',
        );
      }

      const serviceAccount = { projectId, clientEmail, privateKey };
      this.logger.log('Firebase service account loaded successfully');

      if (getApps().length === 0) {
        initializeApp({ credential: cert(serviceAccount) });
      }

      this.messaging = getMessaging();
      this.logger.log('Firebase Admin SDK initialized');
    } catch (err) {
      this.logger.error('Failed to initialize Firebase Admin SDK', err);
    }
  }

  async sendPush(
    fcmToken: string,
    title: string,
    body: string,
    data: Record<string, string>,
  ): Promise<void> {
    if (!this.messaging) return;

    try {
      await this.messaging.send({
        token: fcmToken,
        notification: { title, body },
        data,
      });
    } catch (err) {
      this.logger.error(`Push failed for token ${fcmToken.slice(0, 10)}…`, err);
    }
  }
}
