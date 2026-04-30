import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { DocumentsService } from '../documents/documents.service.js';
import { Document } from '../documents/document.entity.js';

/** Days-before-expiry thresholds that trigger a notification. */
const ALERT_THRESHOLDS = [1, 7, 30] as const;

@Injectable()
export class NotificationsService {
  private readonly logger = new Logger(NotificationsService.name);

  constructor(private readonly documentsService: DocumentsService) {}

  /**
   * Runs every day at 08:00 (Europe/Bucharest).
   *
   * 1. Refreshes the `status` column on all documents.
   * 2. Queries documents expiring in exactly 1, 7, and 30 days.
   * 3. Builds and dispatches push notification payloads.
   *
   * Replace `this.dispatchPushNotification` with your FCM / APNs client.
   */
  @Cron(CronExpression.EVERY_DAY_AT_8AM, {
    name: 'document-expiry-check',
    timeZone: 'Europe/Bucharest',
  })
  async handleDocumentExpiryCheck(): Promise<void> {
    this.logger.log('Running daily document expiry check…');

    // Step 1 — keep status column current
    await this.documentsService.refreshAllStatuses();

    // Step 2 — notify for each threshold
    for (const days of ALERT_THRESHOLDS) {
      const expiring = await this.documentsService.findExpiringIn(days);

      if (expiring.length === 0) continue;

      this.logger.log(
        `Found ${expiring.length} document(s) expiring in ${days} day(s)`,
      );

      for (const doc of expiring) {
        const payload = this.buildPayload(doc, days);
        await this.dispatchPushNotification(payload);
      }
    }

    this.logger.log('Document expiry check complete.');
  }

  // ── Payload builder ─────────────────────────────────────────

  private buildPayload(
    doc: Document,
    daysLeft: number,
  ): PushNotificationPayload {
    const plate = doc.vehicle?.licensePlate ?? 'your vehicle';
    const label = daysLeft === 1 ? 'tomorrow' : `in ${daysLeft} days`;

    return {
      userId: doc.vehicle?.user?.id ?? '',
      title: `${doc.documentType} expiring ${label}!`,
      body: `The ${doc.documentType} for ${plate} expires on ${doc.expirationDate}. Renew it to avoid fines.`,
      data: {
        documentId: doc.id,
        vehicleId: doc.vehicleId,
        documentType: doc.documentType,
        expirationDate: doc.expirationDate,
        daysLeft,
      },
    };
  }

  /**
   * Stub — replace with real FCM / APNs / OneSignal call.
   * The payload is already shaped for FCM's `send()` API.
   */
  private async dispatchPushNotification(
    payload: PushNotificationPayload,
  ): Promise<void> {
    this.logger.debug(
      `[PUSH] → user ${payload.userId}: "${payload.title}"`,
    );
    // TODO: await fcmAdmin.messaging().send({ ... })
  }
}

interface PushNotificationPayload {
  userId: string;
  title: string;
  body: string;
  data: {
    documentId: string;
    vehicleId: string;
    documentType: string;
    expirationDate: string;
    daysLeft: number;
  };
}
