import { Injectable } from '@nestjs/common';
import { PassportSerializer } from '@nestjs/passport';
import { UsersService } from '../users/users.service.js';
import { User } from '../users/user.entity.js';

@Injectable()
export class SessionSerializer extends PassportSerializer {
  constructor(private readonly usersService: UsersService) {
    super();
  }

  serializeUser(
    user: User,
    done: (err: Error | null, id?: string) => void,
  ): void {
    done(null, user.id);
  }

  async deserializeUser(
    id: string,
    done: (err: Error | null, user?: User | null) => void,
  ): Promise<void> {
    const user = await this.usersService.findById(id);
    done(null, user);
  }
}
