import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import type { ChatCompletionMessageParam } from 'openai/resources/chat/completions';
import { Observable, Subject } from 'rxjs';
import { ScoringService, ScorecardResult } from '../scoring/scoring.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message, Session } from '../entities';
import { SCENARIOS } from '../scenarios/scenarios.data';

@Injectable()
export class ChatService {
  private openai: OpenAI;
  private readonly useMockOpenAI: boolean;

  constructor(
    private config: ConfigService,
    private scoring: ScoringService,
    @InjectRepository(Session)
    private sessionRepo: Repository<Session>,
    @InjectRepository(Message)
    private messageRepo: Repository<Message>,
  ) {
    this.useMockOpenAI = this.config.get<string>('USE_MOCK_OPENAI') === 'true';
    this.openai = new OpenAI({
      apiKey: this.config.get<string>('OPENAI_API_KEY'),
    });
  }

  async processMessage(
    sessionId: string,
    userContent: string,
    userId: string,
  ): Promise<Observable<MessageEvent>> {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, userId },
    });
    if (!session) {
      throw new NotFoundException('Session not found');
    }
    if (session.status !== 'active') {
      throw new BadRequestException('Session is no longer active');
    }

    // Get recent messages for context window (last 10 turns)
    const recentMessages = await this.messageRepo.find({
      where: { sessionId },
      order: { turnIndex: 'ASC' },
      take: 20,
    });

    const turnIndex = recentMessages.length;
    const contextStrings = recentMessages.map((m) => m.content);

    // 1. Persist user message
    await this.messageRepo.save({
      sessionId,
      turnIndex,
      role: 'user',
      content: userContent,
    });

    // 2. Score the message
    const scorecard = await this.scoring.scoreMessage(
      userContent,
      contextStrings,
      session.difficulty,
    );

    // 3. Generate character response with streaming
    const subject = new Subject<MessageEvent>();

    void this.streamResponse(
      session,
      userContent,
      contextStrings,
      scorecard,
      turnIndex,
      subject,
    );

    return subject.asObservable();
  }

  private async streamResponse(
    session: Session,
    userContent: string,
    context: string[],
    scorecard: ScorecardResult,
    turnIndex: number,
    subject: Subject<MessageEvent>,
  ): Promise<void> {
    try {
      // If rejected, send rejection and close
      if (scorecard.decision === 'reject') {
        const rejectionMsg =
          'Mira, creo que no estamos conectando. Ha sido un placer, pero prefiero dejarlo aquí. ¡Cuídate!';

        await this.messageRepo.save({
          sessionId: session.id,
          turnIndex: turnIndex + 1,
          role: 'assistant',
          content: rejectionMsg,
          scorecard: { ...scorecard },
        });

        await this.sessionRepo.update(session.id, { status: 'rejected' });

        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({ type: 'delta', data: rejectionMsg }),
          }),
        );
        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({
              type: 'scorecard',
              data: JSON.stringify(scorecard),
            }),
          }),
        );
        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({ type: 'done', data: 'rejected' }),
          }),
        );
        subject.complete();
        return;
      }

      // Build character prompt with steering from scoring
      const steeringNote =
        scorecard.decision === 'cool_down'
          ? 'The user is not performing well. Show less interest, be more distant.'
          : 'The conversation flows well. Be engaged and natural.';

      const scenario = SCENARIOS.find((s) => s.id === session.scenarioId);
      const systemPrompt = scenario
        ? `${scenario.systemPrompt}\n\nSteering: ${steeringNote}`
        : `You are a dating simulation character. Respond in Spanish, in character, as a person on a date. Stay natural and realistic.\nDifficulty: ${session.difficulty}\nSteering: ${steeringNote}\nKeep responses under 150 words. Be conversational, not formal.`;

      let fullResponse = '';

      if (this.useMockOpenAI) {
        fullResponse = this.buildMockResponse(
          session.scenarioId,
          userContent,
          scorecard,
        );
        await new Promise((resolve) => setTimeout(resolve, 0));
        for (const delta of fullResponse.match(/.{1,18}(?:\s|$)/g) ?? [
          fullResponse,
        ]) {
          subject.next(
            new MessageEvent('message', {
              data: JSON.stringify({ type: 'delta', data: delta }),
            }),
          );
          await new Promise((resolve) => setTimeout(resolve, 30));
        }
      } else {
        const contextMessages: ChatCompletionMessageParam[] = context.map(
          (msg, i) => ({
            role: i % 2 === 0 ? 'assistant' : 'user',
            content: msg,
          }),
        );
        const stream = await this.openai.chat.completions.create({
          model: 'gpt-4o-mini',
          stream: true,
          messages: [
            { role: 'system', content: systemPrompt },
            ...contextMessages,
            { role: 'user', content: userContent },
          ],
          temperature: 0.8,
          max_tokens: 400,
        });

        for await (const chunk of stream) {
          const delta = chunk.choices[0]?.delta?.content ?? '';
          if (delta) {
            fullResponse += delta;
            subject.next(
              new MessageEvent('message', {
                data: JSON.stringify({ type: 'delta', data: delta }),
              }),
            );
          }
        }
      }

      // Persist assistant message with scorecard
      await this.messageRepo.save({
        sessionId: session.id,
        turnIndex: turnIndex + 1,
        role: 'assistant',
        content: fullResponse,
        scorecard: { ...scorecard },
      });

      // Send scorecard (only on easy difficulty)
      if (session.difficulty === 'easy') {
        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({
              type: 'scorecard',
              data: JSON.stringify(scorecard),
            }),
          }),
        );
      }

      subject.next(
        new MessageEvent('message', {
          data: JSON.stringify({ type: 'done', data: 'ok' }),
        }),
      );
      subject.complete();
    } catch {
      subject.next(
        new MessageEvent('message', {
          data: JSON.stringify({ type: 'error', data: 'Internal error' }),
        }),
      );
      subject.complete();
    }
  }

  private buildMockResponse(
    scenarioId: string,
    userContent: string,
    scorecard: ScorecardResult,
  ): string {
    if (scorecard.decision === 'cool_down') {
      return 'Vale, te sigo. Aunque me cuesta un poco saber por dónde continuar, ¿quieres contarme algo más?';
    }

    if (scenarioId === 'cafeteria') {
      const normalized = userContent
        .toLowerCase()
        .normalize('NFD')
        .replace(/[\u0300-\u036f]/g, '');

      if (normalized.includes('te verde')) {
        return 'Yo estoy tomando un café con leche. El té verde suena bien, ¿lo pides siempre o hoy te apetecía algo distinto?';
      }
      if (userContent.includes('?')) {
        return 'Buena pregunta. Suelo venir aquí cuando quiero desconectar un rato, ¿tú vienes a menudo?';
      }
      return 'Eso suena interesante. Yo suelo venir aquí para desconectar, ¿qué te gusta de este sitio?';
    }

    return 'Qué interesante. Cuéntame un poco más, ¿qué te hizo elegir eso?';
  }
}
