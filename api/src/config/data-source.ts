import 'dotenv/config';
import { DataSource } from 'typeorm';
import { Attachment } from '../attachments/attachment.entity.js';
import { Document } from '../documents/document.entity.js';
import { User } from '../users/user.entity.js';
import { Vehicle } from '../vehicles/vehicle.entity.js';

export default new DataSource({
  type: 'postgres',
  host: process.env.DB_HOST ?? 'localhost',
  port: parseInt(process.env.DB_PORT ?? '5436', 10),
  username: process.env.DB_USERNAME ?? 'carlina',
  password: process.env.DB_PASSWORD ?? 'carlina_password',
  database: process.env.DB_NAME ?? 'carlina_db',
  entities: [User, Vehicle, Document, Attachment],
  logging: process.env.NODE_ENV === 'development',
});
