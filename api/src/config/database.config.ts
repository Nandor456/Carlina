import { registerAs } from '@nestjs/config';
import { TypeOrmModuleOptions } from '@nestjs/typeorm';

export default registerAs(
  'database',
  (): TypeOrmModuleOptions => ({
    type: 'postgres',
    host: process.env.DB_HOST ?? 'localhost',
    port: parseInt(process.env.DB_PORT ?? '5436', 10),
    username: process.env.DB_USERNAME ?? 'carlina',
    password: process.env.DB_PASSWORD ?? 'carlina_password',
    database: process.env.DB_NAME ?? 'carlina_db',
    synchronize: process.env.DB_SYNC === 'true',
    autoLoadEntities: true,
    logging: process.env.NODE_ENV === 'development',
  }),
);
