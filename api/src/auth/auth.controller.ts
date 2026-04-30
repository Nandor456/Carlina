import {
  Controller,
  Post,
  Get,
  Body,
  UseGuards,
  Req,
  Res,
  HttpCode,
  HttpStatus,
  ConflictException,
  BadRequestException,
} from '@nestjs/common';
import type { Request, Response } from 'express';
import { AuthService } from './auth.service.js';
import { UsersService } from '../users/users.service.js';
import { LocalAuthGuard } from './guards/local-auth.guard.js';
import { AuthGuard } from '@nestjs/passport';
import { AuthenticatedGuard } from './guards/authenticated.guard.js';
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
  async register(@Body() dto: RegisterDto, @Req() req: Request) {
    const existing = await this.usersService.findByEmail(dto.email);
    if (existing) throw new ConflictException('Email already in use');

    const user = await this.authService.register(
      dto.email,
      dto.password,
      dto.fullName,
    );

    await new Promise<void>((resolve, reject) =>
      req.logIn(user, (err) => (err ? reject(err) : resolve())),
    );
    return this.safeUser(user);
  }

  // ── Login (local) ─────────────────────────────────────────
  @UseGuards(LocalAuthGuard)
  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Req() req: Request) {
    return this.safeUser(req.user as User);
  }

  // ── Google login (mobile) ─────────────────────────────────
  @Post('google')
  @HttpCode(HttpStatus.OK)
  async googleMobileLogin(
    @Body('idToken') idToken: string | undefined,
    @Req() req: Request,
  ) {
    if (!idToken) throw new BadRequestException('Missing Google ID token');

    const user = await this.authService.validateGoogleIdToken(idToken);
    await new Promise<void>((resolve, reject) =>
      req.logIn(user, (err) => (err ? reject(err) : resolve())),
    );
    return this.safeUser(user);
  }

  // ── Logout ────────────────────────────────────────────────
  @UseGuards(AuthenticatedGuard)
  @Post('logout')
  @HttpCode(HttpStatus.OK)
  logout(@Req() req: Request, @Res() res: Response) {
    req.logout(() => {
      req.session.destroy(() => {
        res.clearCookie('connect.sid');
        res.json({ message: 'Logged out' });
      });
    });
  }

  // ── Current user ──────────────────────────────────────────
  @UseGuards(AuthenticatedGuard)
  @Get('me')
  me(@Req() req: Request) {
    return this.safeUser(req.user as User);
  }

  // ── Google OAuth ──────────────────────────────────────────
  @Get('google')
  @UseGuards(AuthGuard('google'))
  googleLogin() {
    // Passport redirects to Google
  }

  @Get('google/callback')
  @UseGuards(AuthGuard('google'))
  googleCallback(@Req() req: Request, @Res() res: Response) {
    // On success passport has already established the session
    res.redirect(process.env.FRONTEND_URL ?? 'http://localhost:3001');
  }

  private safeUser(user: User) {
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { passwordHash, ...safe } = user;
    return safe;
  }
}
