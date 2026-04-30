import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DocumentsService } from '../documents/documents.service.js';
import { UsersService } from '../users/users.service.js';
import { FirebaseService } from '../firebase/firebase.service.js';
import { Document } from '../documents/document.entity.js';

/** Days-before-expiry thresholds that trigger a notification (0 = expires today). */
const ALERT_THRESHOLDS = [30, 7, 1, 0] as const;

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(
    private readonly documentsService: DocumentsService,
    private readonly usersService: UsersService,
    private readonly firebaseService: FirebaseService,
  ) {}

  /**
   * Runs every day at 08:00 (Europe/Bucharest).
   *
   * 1. Refreshes the `status` column on all documents.
   * 2. Queries documents expiring in exactly 0, 1, 7, and 30 days.
   * 3. Dispatches push notifications via FCM.
   */
  @Cron(CronExpression.EVERY_DAY_AT_8AM, {
    name: 'document-expiry-check',
    timeZone: 'Europe/Bucharest',
  })
  async handleDocumentExpiryCheck(): Promise<void> {
    this.logger.log('Running daily document expiry check…');

    await this.documentsService.refreshAllStatuses();

    for (const days of ALERT_THRESHOLDS) {
      const expiring = await this.documentsService.findExpiringIn(days);

      if (expiring.length === 0) continue;

      this.logger.log(
        `Found ${expiring.length} document(s) expiring in ${days} day(s)`,
      );

      for (const doc of expiring) {
        await this.dispatchPushNotification(doc, days);
      }
    }

    this.logger.log('Document expiry check complete.');
  }

  // ── Dispatch ────────────────────────────────────────────────

  private async dispatchPushNotification(
    doc: Document,
    daysLeft: number,
  ): Promise<void> {
    const userId = doc.vehicle?.user?.id;
    if (!userId) return;

    const user = await this.usersService.findById(userId);
    if (!user?.fcmToken) {
      this.logger.debug(`User ${userId} has no FCM token — skipping`);
      return;
    }

    const { title, body } = this.buildPayload(doc, daysLeft);
    await this.firebaseService.sendPush(user.fcmToken, title, body, {
      documentId: doc.id,
      vehicleId: doc.vehicleId,
      documentType: doc.documentType,
      expirationDate: doc.expirationDate,
      daysLeft: String(daysLeft),
    });

    this.logger.debug(`[PUSH] → user ${userId}: "${title}"`);
  }

  // ── Payload builder ─────────────────────────────────────────

  private buildPayload(
    doc: Document,
    daysLeft: number,
  ): { title: string; body: string } {
    const plate = doc.vehicle?.licensePlate ?? 'your vehicle';
    const type = doc.documentType;

    if (daysLeft === 0) {
      return {
        title: `${type} expires today!`,
        body: `The ${type} for ${plate} expires today. Renew it now to avoid fines.`,
      };
    }

    const label = daysLeft === 1 ? 'tomorrow' : `in ${daysLeft} days`;
    return {
      title: `${type} expiring ${label}!`,
      body: `The ${type} for ${plate} expires on ${doc.expirationDate}. Renew it to avoid fines.`,
    };
  }
}
