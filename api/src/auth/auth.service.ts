import { Injectable, UnauthorizedException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { OAuth2Client } from 'google-auth-library';
import { UsersService } from '../users/users.service.js';
import { User } from '../users/user.entity.js';

@Injectable()
export class AuthService {
  private readonly googleClient = new OAuth2Client();

  constructor(
    private readonly usersService: UsersService,
    private readonly jwtService: JwtService,
  ) { }

  generateToken(user: User): { accessToken: string } {
    return {
      accessToken: this.jwtService.sign({ sub: user.id, email: user.email }),
    };
  }

  async validateLocalUser(
    email: string,
    password: string,
  ): Promise<User | null> {
    const user = await this.usersService.findByEmail(email);
    if (!user) return null;
    const valid = await this.usersService.validatePassword(user, password);
    return valid ? user : null;
  }

  async validateGoogleUser(profile: {
    googleId: string;
    email: string;
    fullName?: string;
    avatarUrl?: string;
  }): Promise<User> {
    return this.usersService.findOrCreateGoogle(profile);
  }

  async validateGoogleIdToken(idToken: string): Promise<User> {
    try {
      const audiences = [
        process.env.GOOGLE_CLIENT_ID,
        process.env.GOOGLE_WEB_CLIENT_ID,
        process.env.GOOGLE_IOS_CLIENT_ID,
      ].filter((value): value is string => Boolean(value));

      const ticket = await this.googleClient.verifyIdToken({
        idToken,
        audience: audiences.length > 0 ? audiences : undefined,
      });
      const payload = ticket.getPayload();
      if (!payload?.sub || !payload.email) {
        throw new UnauthorizedException('Invalid Google account');
      }

      return this.validateGoogleUser({
        googleId: payload.sub,
        email: payload.email,
        fullName: payload.name,
        avatarUrl: payload.picture,
      });
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      throw new UnauthorizedException('Invalid Google ID token');
    }
  }

  async register(
    email: string,
    password: string,
    fullName?: string,
  ): Promise<User> {
    return this.usersService.createLocal(email, password, fullName);
  }
}
