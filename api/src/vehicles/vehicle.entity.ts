import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  OneToMany,
  JoinColumn,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import type { Relation } from 'typeorm';
import { User } from '../users/user.entity.js';
import { Document } from '../documents/document.entity.js';

@Entity('vehicles')
export class Vehicle {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ type: 'varchar' })
  userId!: string;

  @ManyToOne(() => User, (user) => user.vehicles, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'userId' })
  user!: Relation<User>;

  @Column({ type: 'varchar', length: 20 })
  licensePlate!: string;

  @Column({ type: 'varchar', length: 100 })
  make!: string;

  @Column({ type: 'varchar', length: 100 })
  model!: string;

  // Explicit type required: reflect-metadata emits "Object" for union types (number | null)
  @Column({ type: 'smallint', nullable: true })
  year?: number | null;

  // Explicit type required: reflect-metadata emits "Object" for (string | null)
  @Column({ type: 'varchar', nullable: true, length: 17 })
  vin?: string | null;

  @Column({ type: 'varchar', nullable: true })
  imagePath?: string | null;

  @Column({ type: 'varchar', nullable: true })
  imageMimeType?: string | null;

  @OneToMany(() => Document, (doc) => doc.vehicle, { cascade: true })
  documents!: Relation<Document[]>;

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;

  /** Strip internal file-system path; expose only the boolean for the client. */
  toJSON() {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { imagePath, imageMimeType, ...rest } = this as Record<
      string,
      unknown
    >;
    return { ...rest, hasImage: this.imagePath !== null };
  }
}
