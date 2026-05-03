import {
  CallHandler,
  ExecutionContext,
  Injectable,
  Logger,
  NestInterceptor,
} from '@nestjs/common';
import { Request, Response } from 'express';
import { Observable } from 'rxjs';
import { tap } from 'rxjs/operators';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');

  intercept(context: ExecutionContext, next: CallHandler): Observable<unknown> {
    const req = context.switchToHttp().getRequest<Request>();
    const { method, originalUrl, ip } = req;
    const userAgent = req.headers['user-agent'] ?? '';
    const start = Date.now();

    return next.handle().pipe(
      tap({
        next: () => {
          const res = context.switchToHttp().getResponse<Response>();
          const ms = Date.now() - start;
          this.logger.log(
            `${method} ${originalUrl} ${res.statusCode} ${ms}ms — ${ip} "${userAgent}"`,
          );
        },
        error: (err: { status?: number }) => {
          const ms = Date.now() - start;
          this.logger.error(
            `${method} ${originalUrl} ${err.status ?? 500} ${ms}ms — ${ip} "${userAgent}"`,
          );
        },
      }),
    );
  }
}
