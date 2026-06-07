import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import * as admin from 'firebase-admin';
import { Request } from 'express';
import { UsersService } from '../../auth/users.service';

export interface AuthenticatedUser {
  id: string;
  firebaseUid: string;
  email?: string;
  displayName?: string;
}

export type AuthenticatedRequest = Request & {
  firebaseUser?: AuthenticatedUser;
};

@Injectable()
export class FirebaseAuthGuard implements CanActivate {
  constructor(private readonly usersService: UsersService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthenticatedRequest>();
    const authHeader = request.headers.authorization;

    if (!authHeader?.startsWith('Bearer ')) {
      throw new UnauthorizedException('Missing bearer token');
    }

    const token = authHeader.split('Bearer ')[1];
    let decoded: admin.auth.DecodedIdToken;

    try {
      decoded = await admin.auth().verifyIdToken(token);
    } catch {
      throw new UnauthorizedException('Invalid token');
    }

    const displayName =
      typeof decoded.name === 'string' ? decoded.name : undefined;
    const user = await this.usersService.findOrCreate(
      decoded.uid,
      decoded.email,
      displayName,
    );

    request.firebaseUser = {
      id: user.id,
      firebaseUid: decoded.uid,
      email: user.email,
      displayName: user.displayName,
    };

    return true;
  }
}
