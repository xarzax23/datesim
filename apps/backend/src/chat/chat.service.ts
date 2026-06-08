import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import type { ChatCompletionMessageParam } from 'openai/resources/chat/completions';
import { Observable, Subject, of } from 'rxjs';
import { ScoringService, ScorecardResult } from '../scoring/scoring.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message, Session } from '../entities';
import { SCENARIOS } from '../scenarios/scenarios.data';

@Injectable()
export class ChatService {
  private openai: OpenAI;
  private readonly useMockOpenAI: boolean;
  private readonly openaiModel: string;
  private readonly activeRequests = new Set<string>();

  constructor(
    private config: ConfigService,
    private scoring: ScoringService,
    @InjectRepository(Session)
    private sessionRepo: Repository<Session>,
    @InjectRepository(Message)
    private messageRepo: Repository<Message>,
  ) {
    this.useMockOpenAI = this.config.get<string>('USE_MOCK_OPENAI') === 'true';
    this.openaiModel = this.config.get<string>('OPENAI_MODEL') ?? 'gpt-5-nano';
    this.openai = new OpenAI({
      apiKey: this.config.get<string>('OPENAI_API_KEY'),
    });
  }

  async processMessage(
    sessionId: string,
    userContent: string,
    userId: string,
    clientMessageId?: string,
  ): Promise<Observable<MessageEvent>> {
    const session = await this.sessionRepo.findOne({
      where: { id: sessionId, userId },
    });
    if (!session) {
      throw new NotFoundException('Session not found');
    }

    const requestKey = clientMessageId
      ? `${sessionId}:${clientMessageId}`
      : undefined;
    if (requestKey && this.activeRequests.has(requestKey)) {
      throw new ConflictException('Message is still processing');
    }
    if (requestKey) {
      this.activeRequests.add(requestKey);
    }

    try {
      const existingUserMessage = clientMessageId
        ? await this.messageRepo.findOne({
            where: { sessionId, clientMessageId, role: 'user' },
          })
        : null;

      if (existingUserMessage) {
        const existingAssistantMessage = await this.messageRepo.findOne({
          where: {
            sessionId,
            turnIndex: existingUserMessage.turnIndex + 1,
            role: 'assistant',
          },
        });
        if (existingAssistantMessage) {
          if (requestKey) this.activeRequests.delete(requestKey);
          return this.replayResponse(session, existingAssistantMessage);
        }
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
      const contextMessages = existingUserMessage
        ? recentMessages.filter(
            (message) => message.turnIndex < existingUserMessage.turnIndex,
          )
        : recentMessages;
      const turnIndex = existingUserMessage?.turnIndex ?? recentMessages.length;
      const contextStrings = contextMessages.map((message) => message.content);

      if (!existingUserMessage) {
        await this.messageRepo.save({
          sessionId,
          clientMessageId,
          turnIndex,
          role: 'user',
          content: userContent,
        });
      }

      const scorecard = await this.scoring.scoreMessage(
        userContent,
        contextStrings,
        session.difficulty,
      );
      const subject = new Subject<MessageEvent>();

      void this.streamResponse(
        session,
        userContent,
        contextStrings,
        scorecard,
        turnIndex,
        subject,
        requestKey,
      );

      return subject.asObservable();
    } catch (error) {
      if (requestKey) this.activeRequests.delete(requestKey);
      throw error;
    }
  }

  private async streamResponse(
    session: Session,
    userContent: string,
    context: string[],
    scorecard: ScorecardResult,
    turnIndex: number,
    subject: Subject<MessageEvent>,
    requestKey?: string,
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

        await this.sessionRepo.update(session.id, {
          status: 'rejected',
          overallScore: scorecard.overall,
        });

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
          model: this.openaiModel,
          stream: true,
          reasoning_effort: 'minimal',
          messages: [
            { role: 'system', content: systemPrompt },
            ...contextMessages,
            { role: 'user', content: userContent },
          ],
          max_completion_tokens: 250,
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
    } finally {
      if (requestKey) this.activeRequests.delete(requestKey);
    }
  }

  private replayResponse(
    session: Session,
    assistantMessage: Message,
  ): Observable<MessageEvent> {
    const events = [
      new MessageEvent('message', {
        data: JSON.stringify({
          type: 'delta',
          data: assistantMessage.content,
        }),
      }),
    ];
    if (session.difficulty === 'easy' && assistantMessage.scorecard) {
      events.push(
        new MessageEvent('message', {
          data: JSON.stringify({
            type: 'scorecard',
            data: JSON.stringify(assistantMessage.scorecard),
          }),
        }),
      );
    }
    events.push(
      new MessageEvent('message', {
        data: JSON.stringify({
          type: 'done',
          data: session.status === 'rejected' ? 'rejected' : 'ok',
        }),
      }),
    );
    return of(...events);
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
