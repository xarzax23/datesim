import { ConfigService } from '@nestjs/config';
import { Repository } from 'typeorm';
import { ScoringService } from '../scoring/scoring.service';
import { Message, Session } from '../entities';
import { ChatService } from './chat.service';

interface ReceivedEvent {
  type: string;
  data: string;
}

function parseEvent(data: unknown): ReceivedEvent {
  if (typeof data !== 'string') {
    throw new TypeError('Expected SSE event data to be a string');
  }

  const parsed: unknown = JSON.parse(data);
  if (
    typeof parsed !== 'object' ||
    parsed === null ||
    !('type' in parsed) ||
    !('data' in parsed) ||
    typeof parsed.type !== 'string' ||
    typeof parsed.data !== 'string'
  ) {
    throw new TypeError('Unexpected SSE event payload');
  }

  return { type: parsed.type, data: parsed.data };
}

describe('ChatService', () => {
  it('streams the complete local response before scorecard and done', async () => {
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'USE_MOCK_OPENAI') return 'true';
        if (key === 'OPENAI_API_KEY') return 'test-key';
        return undefined;
      }),
    } as unknown as ConfigService;
    const scorecard = {
      fluency: 8,
      empathy: 8,
      initiative: 8,
      clarity: 9,
      safety: 10,
      overall: 8.6,
      decision: 'continue' as const,
      reason: 'Buen inicio.',
    };
    const scoring = {
      scoreMessage: jest.fn().mockResolvedValue(scorecard),
    } as unknown as ScoringService;
    const sessionRepo = {
      findOne: jest.fn().mockResolvedValue({
        id: 'session-id',
        userId: 'user-id',
        scenarioId: 'cafeteria',
        difficulty: 'easy',
        status: 'active',
      }),
      update: jest.fn(),
    } as unknown as Repository<Session>;
    const messageRepo = {
      find: jest.fn().mockResolvedValue([]),
      save: jest.fn().mockResolvedValue({}),
    } as unknown as Repository<Message>;
    const service = new ChatService(config, scoring, sessionRepo, messageRepo);

    const stream = await service.processMessage(
      'session-id',
      'Es un té verde.',
      'user-id',
    );
    const events = await new Promise<ReceivedEvent[]>((resolve, reject) => {
      const received: ReceivedEvent[] = [];
      stream.subscribe({
        next: (event) => received.push(parseEvent(event.data)),
        error: reject,
        complete: () => resolve(received),
      });
    });

    const response = events
      .filter((event) => event.type === 'delta')
      .map((event) => event.data)
      .join('');

    expect(response).toBe(
      'Yo estoy tomando un café con leche. El té verde suena bien, ¿lo pides siempre o hoy te apetecía algo distinto?',
    );
    expect(events.at(-2)?.type).toBe('scorecard');
    expect(events.at(-1)).toEqual({ type: 'done', data: 'ok' });
  });

  it('does not accept messages after session completion', async () => {
    const config = {
      get: jest.fn((key: string) =>
        key === 'USE_MOCK_OPENAI' ? 'true' : 'test-key',
      ),
    } as unknown as ConfigService;
    const scoreMessage = jest.fn();
    const scoring = { scoreMessage } as unknown as ScoringService;
    const sessionRepo = {
      findOne: jest.fn().mockResolvedValue({
        id: 'session-id',
        userId: 'user-id',
        status: 'completed',
      }),
    } as unknown as Repository<Session>;
    const save = jest.fn();
    const messageRepo = {
      find: jest.fn(),
      save,
    } as unknown as Repository<Message>;
    const service = new ChatService(config, scoring, sessionRepo, messageRepo);

    await expect(
      service.processMessage('session-id', 'Otro mensaje', 'user-id'),
    ).rejects.toThrow('Session is no longer active');
  });

  it('persists the final score when a session is rejected', async () => {
    const config = {
      get: jest.fn((key: string) =>
        key === 'USE_MOCK_OPENAI' ? 'true' : 'test-key',
      ),
    } as unknown as ConfigService;
    const scorecard = {
      fluency: 2,
      empathy: 1,
      initiative: 1,
      clarity: 4,
      safety: 2,
      overall: 1.8,
      decision: 'reject' as const,
      reason: 'La conversación no puede continuar.',
    };
    const scoring = {
      scoreMessage: jest.fn().mockResolvedValue(scorecard),
    } as unknown as ScoringService;
    const update = jest.fn().mockResolvedValue({});
    const sessionRepo = {
      findOne: jest.fn().mockResolvedValue({
        id: 'session-id',
        userId: 'user-id',
        scenarioId: 'cafeteria',
        difficulty: 'easy',
        status: 'active',
      }),
      update,
    } as unknown as Repository<Session>;
    const messageRepo = {
      find: jest.fn().mockResolvedValue([]),
      save: jest.fn().mockResolvedValue({}),
    } as unknown as Repository<Message>;
    const service = new ChatService(config, scoring, sessionRepo, messageRepo);

    const stream = await service.processMessage(
      'session-id',
      'Déjame en paz.',
      'user-id',
    );
    await new Promise<void>((resolve, reject) => {
      stream.subscribe({ error: reject, complete: resolve });
    });

    expect(update).toHaveBeenCalledWith('session-id', {
      status: 'rejected',
      overallScore: 1.8,
    });
  });

  it('replays a persisted response for the same client message', async () => {
    const scorecard = {
      fluency: 8,
      empathy: 8,
      initiative: 8,
      clarity: 8,
      safety: 10,
      overall: 8.4,
      decision: 'continue',
      reason: 'Buen mensaje.',
    };
    const config = {
      get: jest.fn((key: string) =>
        key === 'USE_MOCK_OPENAI' ? 'true' : 'test-key',
      ),
    } as unknown as ConfigService;
    const replayScoreMessage = jest.fn();
    const scoring = {
      scoreMessage: replayScoreMessage,
    } as unknown as ScoringService;
    const sessionRepo = {
      findOne: jest.fn().mockResolvedValue({
        id: 'session-id',
        userId: 'user-id',
        difficulty: 'easy',
        status: 'active',
      }),
    } as unknown as Repository<Session>;
    const replaySave = jest.fn();
    const messageRepo = {
      findOne: jest
        .fn()
        .mockResolvedValueOnce({
          sessionId: 'session-id',
          clientMessageId: 'client-message-id',
          turnIndex: 1,
          role: 'user',
          content: 'Hola',
        })
        .mockResolvedValueOnce({
          sessionId: 'session-id',
          turnIndex: 2,
          role: 'assistant',
          content: 'Hola de nuevo',
          scorecard,
        }),
      find: jest.fn(),
      save: replaySave,
    } as unknown as Repository<Message>;
    const service = new ChatService(config, scoring, sessionRepo, messageRepo);

    const stream = await service.processMessage(
      'session-id',
      'Hola',
      'user-id',
      'client-message-id',
    );
    const events = await new Promise<ReceivedEvent[]>((resolve, reject) => {
      const received: ReceivedEvent[] = [];
      stream.subscribe({
        next: (event) => received.push(parseEvent(event.data)),
        error: reject,
        complete: () => resolve(received),
      });
    });

    expect(events[0]).toEqual({ type: 'delta', data: 'Hola de nuevo' });
    expect(events.at(-1)).toEqual({ type: 'done', data: 'ok' });
    expect(replayScoreMessage).not.toHaveBeenCalled();
    expect(replaySave).not.toHaveBeenCalled();
  });
});
