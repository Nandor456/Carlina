import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { FamilyLink } from './family-link.entity.js';
import { FamilyService } from './family.service.js';
import { FamilyController } from './family.controller.js';
import { Vehicle } from '../vehicles/vehicle.entity.js';
import { User } from '../users/user.entity.js';

@Module({
  imports: [TypeOrmModule.forFeature([FamilyLink, Vehicle, User])],
  providers: [FamilyService],
  controllers: [FamilyController],
})
export class FamilyModule {}
