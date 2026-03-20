import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import { Observable, Subject } from 'rxjs';
import { ScoringService, ScorecardResult } from '../scoring/scoring.service';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Message, Session } from '../entities';
import { SCENARIOS } from '../scenarios/scenarios.data';

interface ChatStreamEvent {
  type: 'delta' | 'scorecard' | 'done' | 'error';
  data: string;
}

@Injectable()
export class ChatService {
  private openai: OpenAI;

  constructor(
    private config: ConfigService,
    private scoring: ScoringService,
    @InjectRepository(Session)
    private sessionRepo: Repository<Session>,
    @InjectRepository(Message)
    private messageRepo: Repository<Message>,
  ) {
    this.openai = new OpenAI({
      apiKey: this.config.get<string>('OPENAI_API_KEY'),
    });
  }

  async processMessage(
    sessionId: string,
    userContent: string,
    userId: string,
  ): Promise<Observable<MessageEvent>> {
    const session = await this.sessionRepo.findOneOrFail({
      where: { id: sessionId, userId },
    });

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

    this.streamResponse(
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
          scorecard: scorecard as any,
        });

        await this.sessionRepo.update(session.id, { status: 'rejected' });

        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({ type: 'delta', data: rejectionMsg }),
          }),
        );
        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({ type: 'scorecard', data: JSON.stringify(scorecard) }),
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

      const stream = await this.openai.chat.completions.create({
        model: 'gpt-4o-mini',
        stream: true,
        messages: [
          { role: 'system', content: systemPrompt },
          ...context.map((msg, i) => ({
            role: (i % 2 === 0 ? 'assistant' : 'user') as 'assistant' | 'user',
            content: msg,
          })),
          { role: 'user', content: userContent },
        ],
        temperature: 0.8,
        max_tokens: 400,
      });

      let fullResponse = '';

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

      // Persist assistant message with scorecard
      await this.messageRepo.save({
        sessionId: session.id,
        turnIndex: turnIndex + 1,
        role: 'assistant',
        content: fullResponse,
        scorecard: scorecard as any,
      });

      // Send scorecard (only on easy difficulty)
      if (session.difficulty === 'easy') {
        subject.next(
          new MessageEvent('message', {
            data: JSON.stringify({ type: 'scorecard', data: JSON.stringify(scorecard) }),
          }),
        );
      }

      subject.next(
        new MessageEvent('message', {
          data: JSON.stringify({ type: 'done', data: 'ok' }),
        }),
      );
      subject.complete();
    } catch (error) {
      subject.next(
        new MessageEvent('message', {
          data: JSON.stringify({ type: 'error', data: 'Internal error' }),
        }),
      );
      subject.complete();
    }
  }
}
