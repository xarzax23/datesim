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
      findOneOrFail: jest.fn().mockResolvedValue({
        id: 'session-id',
        userId: 'user-id',
        scenarioId: 'cafeteria',
        difficulty: 'easy',
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
});
