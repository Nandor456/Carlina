import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Vehicle } from '../vehicles/vehicle.entity.js';

export enum AttachmentKind {
  INSURANCE = 'INSURANCE',
  REGISTRATION = 'REGISTRATION',
  VIGNETTE = 'VIGNETTE',
  INSPECTION = 'INSPECTION',
  OTHER = 'OTHER',
}

@Entity('attachments')
export class Attachment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  vehicleId: string;

  @ManyToOne(() => Vehicle, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'vehicleId' })
  vehicle: Vehicle;

  @Column({ type: 'enum', enum: AttachmentKind, default: AttachmentKind.OTHER })
  kind: AttachmentKind;

  @Column({ type: 'varchar', length: 255 })
  originalFilename: string;

  @Column({ type: 'varchar' })
  storedPath: string;

  @Column({ type: 'varchar', length: 100 })
  mimeType: string;

  @Column({ type: 'integer' })
  sizeBytes: number;

  @Column({ type: 'date', nullable: true })
  expirationDate: string | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  notes: string | null;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
