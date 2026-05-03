// Augment Express.Request with Passport + express-session properties so
// TypeScript knows about req.user, req.isAuthenticated(), req.session, etc.
import type { User as UserEntity } from '../users/user.entity.js';

declare global {
  namespace Express {
    // Passport uses Express.User for req.user — point it at our entity.
    // eslint-disable-next-line @typescript-eslint/no-empty-object-type
    interface User extends UserEntity {}
  }
}

declare module 'express' {
  interface Request {
    user?: UserEntity;
    isAuthenticated(): boolean;
    isUnauthenticated(): boolean;
    logIn(user: UserEntity, done: (err: unknown) => void): void;
    logIn(
      user: UserEntity,
      options: Record<string, unknown>,
      done: (err: unknown) => void,
    ): void;
    logout(done: (err: unknown) => void): void;
    session: Record<string, unknown> & {
      destroy(callback?: (err: unknown) => void): void;
    };
  }
}

export {};
