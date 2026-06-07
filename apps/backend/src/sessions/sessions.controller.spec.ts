import { BadRequestException } from '@nestjs/common';
import { Repository } from 'typeorm';
import type { AuthenticatedUser } from '../common/guards/firebase-auth.guard';
import { Message, Session } from '../entities';
import { SessionsController } from './sessions.controller';

describe('SessionsController', () => {
  const user: AuthenticatedUser = {
    id: '2a87b066-0e67-45d1-8609-e7931e0d96e2',
    firebaseUid: 'firebase-user-id',
  };

  function createController(options?: {
    session?: Partial<Session>;
    messages?: Partial<Message>[];
  }) {
    const session = {
      id: '1f6fb37c-d036-4bc7-86dd-e0b56af43065',
      userId: user.id,
      scenarioId: 'cafeteria',
      difficulty: 'easy',
      status: 'active',
      state: {},
      ...options?.session,
    } as Session;
    const saveSession = jest
      .fn()
      .mockImplementation((value: Session) => Promise.resolve(value));
    const sessionRepo = {
      findOne: jest.fn().mockResolvedValue(session),
      save: saveSession,
    } as unknown as Repository<Session>;
    const messageRepo = {
      find: jest.fn().mockResolvedValue(options?.messages ?? []),
    } as unknown as Repository<Message>;

    return {
      controller: new SessionsController(sessionRepo, messageRepo),
      session,
      saveSession,
    };
  }

  it('completes a session and stores the average score', async () => {
    const { controller, session, saveSession } = createController({
      messages: [
        { role: 'user', content: 'Hola' },
        { role: 'assistant', scorecard: { overall: 7.4 } },
        { role: 'user', content: '¿Qué tal?' },
        { role: 'assistant', scorecard: { overall: 8.2 } },
      ],
    });

    const result = await controller.complete(session.id, user);

    expect(result.status).toBe('completed');
    expect(result.overallScore).toBe(7.8);
    expect(saveSession).toHaveBeenCalledWith(session);
  });

  it('requires at least one user turn before completion', async () => {
    const { controller, session } = createController();

    await expect(controller.complete(session.id, user)).rejects.toBeInstanceOf(
      BadRequestException,
    );
  });
});
