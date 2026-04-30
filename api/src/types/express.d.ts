// Augment Express.Request with Passport + express-session properties so
// TypeScript knows about req.user, req.isAuthenticated(), req.session, etc.
import { User } from '../users/user.entity.js';

declare global {
  namespace Express {
    // Passport uses Express.User for req.user — point it at our entity.
    interface User extends import('../users/user.entity').User {}
  }
}

declare module 'express' {
  interface Request {
    user?: User;
    isAuthenticated(): boolean;
    isUnauthenticated(): boolean;
    logIn(user: User, done: (err: unknown) => void): void;
    logIn(user: User, options: Record<string, unknown>, done: (err: unknown) => void): void;
    logout(done: (err: unknown) => void): void;
    session: Record<string, unknown> & {
      destroy(callback?: (err: unknown) => void): void;
    };
  }
}

export {};
