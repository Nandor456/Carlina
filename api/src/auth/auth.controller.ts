import {
  Controller,
  Post,
  Get,
  Patch,
  Body,
  UseGuards,
  Req,
  HttpCode,
  HttpStatus,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthService } from './auth.service.js';
import { UsersService } from '../users/users.service.js';
import { LocalAuthGuard } from './guards/local-auth.guard.js';
import { JwtAuthGuard } from './guards/jwt-auth.guard.js';
import { RegisterDto } from './dto/register.dto.js';
import { User } from '../users/user.entity.js';

@Controller('auth')
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly usersService: UsersService,
  ) {}

  // ── Register ──────────────────────────────────────────────
  @Post('register')
  async register(@Body() dto: RegisterDto) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) throw new ConflictException('Email already in use');

    const user = await this.authService.register(
      dto.email,
      dto.password,
      dto.fullName,
    );

    return { ...this.safeUser(user), ...this.authService.generateToken(user) };
  }

  // ── Login (local) ─────────────────────────────────────────
  @UseGuards(LocalAuthGuard)
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Req() req: Request) {
    const user = req.user as User;
    return { ...this.safeUser(user), ...this.authService.generateToken(user) };
  }

  // ── Google login (mobile) ─────────────────────────────────
  @Post('google')
  @HttpCode(HttpStatus.OK)
  async googleMobileLogin(@Body('idToken') idToken: string | undefined) {
    if (!idToken) throw new BadRequestException('Missing Google ID token');

    const user = await this.authService.validateGoogleIdToken(idToken);
    return { ...this.safeUser(user), ...this.authService.generateToken(user) };
  }

  // ── Current user ──────────────────────────────────────────
  @UseGuards(JwtAuthGuard)
  @Get('me')
  me(@Req() req: Request) {
    return this.safeUser(req.user as User);
  }

  // ── FCM token registration ────────────────────────────────
  @UseGuards(JwtAuthGuard)
  @Patch('fcm-token')
  @HttpCode(HttpStatus.NO_CONTENT)
  async registerFcmToken(
    @Req() req: Request,
    @Body('token') token: string | undefined,
  ) {
    if (!token) throw new BadRequestException('Missing token');
    const user = req.user as User;
    await this.usersService.updateFcmToken(user.id, token);
  }

  private safeUser(user: User) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { passwordHash, ...safe } = user;
    return safe;
  }
}
