import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';

import { AppModule } from './app.module.js';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor.js';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.useGlobalInterceptors(new LoggingInterceptor());
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  const isProd = process.env.NODE_ENV === 'production';
  const allowedOrigins = (process.env.FRONTEND_URL ?? '')
    .split(',')
    .map((o) => o.trim())
    .filter(Boolean);

  app.enableCors({
    origin: isProd
      ? allowedOrigins.length > 0
        ? allowedOrigins
        : false
      : true,
    credentials: true,
  });

  app.setGlobalPrefix('api');

  const port = parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(port);
  console.log(`Carlina API listening on port ${port}`);
}

bootstrap().catch((err: unknown) => {
  console.error('Failed to bootstrap Carlina API', err);
  process.exit(1);
});
