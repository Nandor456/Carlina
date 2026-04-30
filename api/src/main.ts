import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { Pool } from 'pg';
import session from 'express-session';
import passport from 'passport';
import connectPgSimple from 'connect-pg-simple';

import { AppModule } from './app.module.js';

const PgStore = connectPgSimple(session);

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // ── Global validation ─────────────────────────────────────
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));

  // ── CORS ─────────────────────────────────────────────────
  app.enableCors({
    origin: true,
    credentials: true,
  });

  // ── Session store backed by PostgreSQL ───────────────────
  const pool = new Pool({
    host: process.env.DB_HOST ?? 'localhost',
    port: parseInt(process.env.DB_PORT ?? '5436', 10),
    user: process.env.DB_USERNAME ?? 'carlina',
    password: process.env.DB_PASSWORD ?? 'carlina_password',
    database: process.env.DB_NAME ?? 'carlina_db',
  });

  app.use(
    session({
      store: new PgStore({ pool, tableName: 'session', createTableIfMissing: true }),
      secret: process.env.SESSION_SECRET ?? 'dev_secret_change_me',
      resave: false,
      saveUninitialized: false,
      cookie: {
        maxAge: 7 * 24 * 60 * 60 * 1000, // 7 days
        httpOnly: true,
        secure: process.env.NODE_ENV === 'production',
        sameSite: 'lax',
      },
    }),
  );

  // ── Passport ──────────────────────────────────────────────
  app.use(passport.initialize());
  app.use(passport.session());

  // ── Global prefix ─────────────────────────────────────────
  app.setGlobalPrefix('api');

  const port = parseInt(process.env.PORT ?? '3000', 10);
  await app.listen(port);
  console.log(`AutoDoc Tracker API running on http://localhost:${port}/api`);
}

bootstrap();
