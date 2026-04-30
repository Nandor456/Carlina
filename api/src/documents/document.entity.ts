import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { Relation } from 'typeorm';
import { Vehicle } from '../vehicles/vehicle.entity.js';

export enum DocumentType {
  RCA = 'RCA',
  ITP = 'ITP',
  ROVINIETA = 'ROVINIETA',
}

export enum DocumentStatus {
  ACTIVE = 'ACTIVE',
  EXPIRING_SOON = 'EXPIRING_SOON',
  EXPIRED = 'EXPIRED',
}

@Entity('documents')
export class Document {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  vehicleId: string;

  @ManyToOne(() => Vehicle, (vehicle) => vehicle.documents, {
    onDelete: 'CASCADE',
  })
  @JoinColumn({ name: 'vehicleId' })
  vehicle: Relation<Vehicle>;

  @Column({ type: 'enum', enum: DocumentType })
  documentType: DocumentType;

  @Column({ type: 'date' })
  issueDate: string;

  @Column({ type: 'date' })
  expirationDate: string;

  @Column({
    type: 'enum',
    enum: DocumentStatus,
    default: DocumentStatus.ACTIVE,
  })
  status: DocumentStatus;

  @CreateDateColumn()
  createdAt: Date;

  @UpdateDateColumn()
  updatedAt: Date;
}
