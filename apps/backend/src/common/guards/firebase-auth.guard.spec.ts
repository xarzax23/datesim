import { ExecutionContext, UnauthorizedException } from '@nestjs/common';
import * as admin from 'firebase-admin';
import { UsersService } from '../../auth/users.service';
import { AuthenticatedUser, FirebaseAuthGuard } from './firebase-auth.guard';

describe('FirebaseAuthGuard', () => {
  const verifyIdToken = jest.fn();
  const findOrCreate = jest.fn();
  const usersService = { findOrCreate } as unknown as UsersService;

  beforeEach(() => {
    jest.clearAllMocks();
    jest
      .spyOn(admin, 'auth')
      .mockReturnValue({ verifyIdToken } as unknown as admin.auth.Auth);
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  function createContext(authorization?: string) {
    const request: {
      headers: { authorization?: string };
      firebaseUser?: AuthenticatedUser;
    } = { headers: { authorization } };
    const context = {
      switchToHttp: () => ({
        getRequest: () => request,
      }),
    } as ExecutionContext;

    return { context, request };
  }

  it('attaches the internal database user after verifying the token', async () => {
    verifyIdToken.mockResolvedValue({
      uid: 'firebase-user-id',
      email: 'test@example.com',
      name: 'Test User',
    });
    findOrCreate.mockResolvedValue({
      id: '2a87b066-0e67-45d1-8609-e7931e0d96e2',
      email: 'test@example.com',
      displayName: 'Test User',
    });
    const { context, request } = createContext('Bearer valid-token');
    const guard = new FirebaseAuthGuard(usersService);

    await expect(guard.canActivate(context)).resolves.toBe(true);
    expect(findOrCreate).toHaveBeenCalledWith(
      'firebase-user-id',
      'test@example.com',
      'Test User',
    );
    expect(request.firebaseUser).toEqual({
      id: '2a87b066-0e67-45d1-8609-e7931e0d96e2',
      firebaseUid: 'firebase-user-id',
      email: 'test@example.com',
      displayName: 'Test User',
    });
  });

  it('rejects a request without a bearer token', async () => {
    const { context } = createContext();
    const guard = new FirebaseAuthGuard(usersService);

    await expect(guard.canActivate(context)).rejects.toBeInstanceOf(
      UnauthorizedException,
    );
    expect(findOrCreate).not.toHaveBeenCalled();
  });
});
