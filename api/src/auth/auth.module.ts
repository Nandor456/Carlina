import { Module } from '@nestjs/common';
import { PassportModule } from '@nestjs/passport';
import { UsersModule } from '../users/users.module.js';
import { AuthService } from './auth.service.js';
import { AuthController } from './auth.controller.js';
import { LocalStrategy } from './strategies/local.strategy.js';
import { GoogleStrategy } from './strategies/google.strategy.js';
import { SessionSerializer } from './session.serializer.js';

@Module({
  imports: [
    UsersModule,
    PassportModule.register({ session: true }),
  ],
  providers: [AuthService, LocalStrategy, GoogleStrategy, SessionSerializer],
  controllers: [AuthController],
})
export class AuthModule {}
