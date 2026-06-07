import { ConfigService } from '@nestjs/config';
import { ScoringService } from './scoring.service';

describe('ScoringService', () => {
  function createService() {
    const config = {
      get: jest.fn((key: string) => {
        if (key === 'USE_MOCK_OPENAI') return 'true';
        if (key === 'OPENAI_API_KEY') return 'test-key';
        return undefined;
      }),
    } as unknown as ConfigService;
    return new ScoringService(config);
  }

  it('scores an engaging question higher than a minimal reply', async () => {
    const service = createService();

    const engaging = await service.scoreMessage(
      'Es un té verde. ¿Qué estás tomando tú?',
      [],
      'easy',
    );
    const minimal = await service.scoreMessage('Vale.', [], 'easy');

    expect(engaging).toMatchObject({
      decision: 'continue',
      safety: 10,
    });
    expect(engaging.overall).toBeGreaterThan(minimal.overall);
    expect(engaging.initiative).toBeGreaterThan(minimal.initiative);
    expect(engaging.reason).not.toBe(minimal.reason);
    expect(minimal.decision).toBe('cool_down');
  });

  it('penalizes repeating the same intervention', async () => {
    const service = createService();
    const message = '¿Qué tipo de café te gusta más?';

    const first = await service.scoreMessage(message, [], 'easy');
    const repeated = await service.scoreMessage(
      message,
      ['Una respuesta anterior', message],
      'easy',
    );

    expect(repeated.overall).toBeLessThan(first.overall);
    expect(repeated.reason).toContain('Repites');
  });

  it('rejects threatening language', async () => {
    const service = createService();

    const result = await service.scoreMessage(
      'Te voy a matar si no me respondes.',
      [],
      'easy',
    );

    expect(result.decision).toBe('reject');
    expect(result.safety).toBe(0);
  });

  it('rejects the hostile dismissal found during emulator testing', async () => {
    const service = createService();

    const result = await service.scoreMessage(
      'Me apetece que te vayas.',
      [],
      'easy',
    );

    expect(result.decision).toBe('reject');
    expect(result.overall).toBeLessThan(5);
    expect(result.empathy).toBeLessThanOrEqual(1);
    expect(result.reason).toContain('expulsión directa');
  });

  it('does not mistake an insult for conversational interest', async () => {
    const service = createService();

    const result = await service.scoreMessage(
      'La silla está ocupada, imbécil.',
      [],
      'easy',
    );

    expect(result.decision).toBe('reject');
    expect(result.overall).toBeLessThan(5);
    expect(result.empathy).toBeLessThanOrEqual(1);
  });
});
