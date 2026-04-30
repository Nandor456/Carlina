import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from './user.entity.js';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User)
    private readonly usersRepo: Repository<User>,
  ) {}

  async findById(id: string): Promise<User | null> {
    return this.usersRepo.findOneBy({ id });
  }

  async findByEmail(email: string): Promise<User | null> {
    return this.usersRepo.findOneBy({ email });
  }

  async findByGoogleId(googleId: string): Promise<User | null> {
    return this.usersRepo.findOneBy({ googleId });
  }

  async createLocal(
    email: string,
    password: string,
    fullName?: string,
  ): Promise<User> {
    const passwordHash = await bcrypt.hash(password, 12);
    const user = this.usersRepo.create({ email, passwordHash, fullName });
    return this.usersRepo.save(user);
  }

  async findOrCreateGoogle(profile: {
    googleId: string;
    email: string;
    fullName?: string;
    avatarUrl?: string;
  }): Promise<User> {
    let user = await this.findByGoogleId(profile.googleId);
    if (user) return user;

    // Link to existing account by email if one exists
    user = await this.findByEmail(profile.email);
    if (user) {
      user.googleId = profile.googleId;
      if (profile.avatarUrl) user.avatarUrl = profile.avatarUrl;
      return this.usersRepo.save(user);
    }

    const newUser = this.usersRepo.create({
      googleId: profile.googleId,
      email: profile.email,
      fullName: profile.fullName ?? null,
      avatarUrl: profile.avatarUrl ?? null,
      passwordHash: null,
    });
    return this.usersRepo.save(newUser);
  }

  async validatePassword(user: User, password: string): Promise<boolean> {
    if (!user.passwordHash) return false;
    return bcrypt.compare(password, user.passwordHash);
  }

  async updateFcmToken(userId: string, token: string): Promise<void> {
    await this.usersRepo.update(userId, { fcmToken: token });
  }
}
