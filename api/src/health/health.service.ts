import { Injectable, Optional } from '@nestjs/common';
import { DataSource } from 'typeorm';

export type HealthStatus = 'ok' | 'degraded';

export interface HealthCheckResponse {
    status: HealthStatus;
    timestamp: string;
    uptimeSeconds: number;
    db: {
        ok: boolean;
        latencyMs: number;
        error?: string;
    };
}

@Injectable()
export class HealthService {
    constructor(@Optional() private readonly dataSource?: DataSource) { }

    async check(): Promise<HealthCheckResponse> {
        const timestamp = new Date().toISOString();
        const uptimeSeconds = Math.floor(process.uptime());

        const startedAt = Date.now();
        let ok = false;
        let error: string | undefined;

        try {
            if (!this.dataSource) {
                throw new Error('Database not configured');
            }

            if (!this.dataSource.isInitialized) {
                throw new Error('Database connection not initialized');
            }

            await this.dataSource.query('SELECT 1');
            ok = true;
        } catch (err) {
            ok = false;
            if (process.env.NODE_ENV !== 'production') {
                error = err instanceof Error ? err.message : String(err);
            }
        }

        const latencyMs = Date.now() - startedAt;

        return {
            status: ok ? 'ok' : 'degraded',
            timestamp,
            uptimeSeconds,
            db: {
                ok,
                latencyMs,
                ...(error ? { error } : {}),
            },
        };
    }
}
