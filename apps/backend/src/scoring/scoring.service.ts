import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';
import type { ChatCompletionMessageParam } from 'openai/resources/chat/completions';

export interface ScorecardResult {
  fluency: number;
  empathy: number;
  initiative: number;
  clarity: number;
  safety: number;
  overall: number;
  decision: 'continue' | 'cool_down' | 'reject';
  reason: string;
}

@Injectable()
export class ScoringService {
  private openai: OpenAI;
  private readonly useMockOpenAI: boolean;
  private readonly openaiModel: string;

  constructor(private config: ConfigService) {
    this.useMockOpenAI = this.config.get<string>('USE_MOCK_OPENAI') === 'true';
    this.openaiModel = this.config.get<string>('OPENAI_MODEL') ?? 'gpt-5-nano';
    this.openai = new OpenAI({
      apiKey: this.config.get<string>('OPENAI_API_KEY'),
    });
  }

  async scoreMessage(
    userMessage: string,
    context: string[],
    difficulty: string,
  ): Promise<ScorecardResult> {
    if (this.useMockOpenAI) {
      return this.scoreLocally(userMessage, context, difficulty);
    }

    const contextMessages: ChatCompletionMessageParam[] = context.map(
      (msg, i) => ({
        role: i % 2 === 0 ? 'assistant' : 'user',
        content: msg,
      }),
    );
    const response = await this.openai.chat.completions.create({
      model: this.openaiModel,
      response_format: { type: 'json_object' },
      reasoning_effort: 'minimal',
      messages: [
        {
          role: 'system',
          content: `You are a dating conversation evaluator. Score the user's latest message on a scale 0-10 for each metric. Return JSON only.
Difficulty: ${difficulty}
Metrics: fluency, empathy, initiative, clarity, safety
Also determine: decision (continue/cool_down/reject) and reason.
Write the reason in Spanish.
Higher difficulty = stricter thresholds for "continue".
JSON schema: {"fluency":number,"empathy":number,"initiative":number,"clarity":number,"safety":number,"overall":number,"decision":"continue"|"cool_down"|"reject","reason":"string"}`,
        },
        ...contextMessages,
        { role: 'user', content: userMessage },
      ],
      max_completion_tokens: 300,
    });

    const raw = response.choices[0]?.message?.content ?? '{}';
    return JSON.parse(raw) as ScorecardResult;
  }

  private scoreLocally(
    userMessage: string,
    context: string[],
    difficulty: string,
  ): ScorecardResult {
    const normalized = this.normalize(userMessage);
    const words = normalized.match(/[a-z0-9]+/g) ?? [];
    const wordCount = words.length;
    const hasQuestion = /[¿?]/.test(userMessage);
    const hasOpenQuestion =
      hasQuestion &&
      /\b(que|como|cuando|donde|por que|cual|quien|cuentame)\b/.test(
        normalized,
      );
    const sharesSomething =
      /\b(yo|me|mi|creo|pienso|prefiero|gusta|tomo|soy|trabajo|estudio)\b/.test(
        normalized,
      );
    const isHostileDismissal =
      /\b(me apetece que te vayas|quiero que te vayas|vete|largate|fuera de aqui|quita de aqui|no te soporto|no quiero verte|desaparece|pierdete)\b/.test(
        normalized,
      );
    const isDismissive =
      isHostileDismissal ||
      /\b(no me importa|dejame en paz|me da igual|que pesado|que pesada|paso de ti|no quiero hablar contigo|no me interesa hablar contigo)\b/.test(
        normalized,
      );
    const hasInsult =
      /\b(idiota|imbecil|estupido|estupida|gilipollas|callate|payaso|payasa|inutil|asco|das asco)\b/.test(
        normalized,
      );
    const isThreatening =
      /\b(te voy a matar|voy a matarte|te hare dano|te obligare|sin tu permiso)\b/.test(
        normalized,
      );
    const negativeInteraction = isDismissive || hasInsult || isThreatening;
    const showsInterest =
      !negativeInteraction &&
      /\b(tu|contigo|tomas|piensas|gustas|te apetece|te interesa|que haces|como eres)\b/.test(
        normalized,
      );
    const usesWarmLanguage =
      !negativeInteraction &&
      /\b(gracias|entiendo|interesante|genial|claro|suena|perdona|siento|por favor|encanta)\b/.test(
        normalized,
      );
    const isRepeated = context.some(
      (message) => this.normalize(message) === normalized && normalized !== '',
    );

    let fluency =
      wordCount <= 1
        ? 2.5
        : wordCount <= 3
          ? 4
          : wordCount <= 6
            ? 6
            : wordCount <= 35
              ? 8
              : wordCount <= 60
                ? 7
                : 5.5;
    if (/[.!?¿¡]/.test(userMessage)) fluency += 0.5;
    if (isRepeated) fluency -= 2;

    let empathy = 4.5;
    if (showsInterest) empathy += 1.5;
    if (usesWarmLanguage) empathy += 2;
    if (hasQuestion) empathy += 0.5;
    if (isDismissive) empathy -= 3.5;
    if (hasInsult) empathy -= 4;
    if (isHostileDismissal) empathy = 0.5;
    if (isThreatening) empathy = 0;

    let initiative = 3.5;
    if (hasQuestion) initiative += 2;
    if (hasOpenQuestion) initiative += 1.5;
    if (sharesSomething) initiative += 1;
    if (wordCount >= 6) initiative += 0.5;
    if (isRepeated) initiative -= 2;
    if (isHostileDismissal || hasInsult) initiative = 1;

    let clarity =
      wordCount <= 1 ? 3.5 : wordCount <= 4 ? 5.5 : wordCount <= 40 ? 8 : 6.5;
    if (/[.!?¿¡]/.test(userMessage)) clarity += 0.5;
    if (userMessage.length > 12 && userMessage === userMessage.toUpperCase()) {
      clarity -= 1.5;
    }
    if (isRepeated) clarity -= 1;

    let safety = 10;
    if (isDismissive) safety = 7;
    if (hasInsult) safety = 4;
    if (isHostileDismissal) safety = 5;
    if (isThreatening) safety = 0;

    fluency = this.clampScore(fluency);
    empathy = this.clampScore(empathy);
    initiative = this.clampScore(initiative);
    clarity = this.clampScore(clarity);

    const overall = this.roundScore(
      fluency * 0.2 +
        empathy * 0.25 +
        initiative * 0.2 +
        clarity * 0.2 +
        safety * 0.15,
    );
    const continueThreshold =
      difficulty === 'hard' ? 7.5 : difficulty === 'medium' ? 6.8 : 6;
    const decision =
      isThreatening || hasInsult || isHostileDismissal
        ? 'reject'
        : overall >= continueThreshold
          ? 'continue'
          : 'cool_down';

    return {
      fluency,
      empathy,
      initiative,
      clarity,
      safety,
      overall,
      decision,
      reason: this.buildLocalReason({
        wordCount,
        hasQuestion,
        hasOpenQuestion,
        sharesSomething,
        showsInterest,
        usesWarmLanguage,
        isDismissive,
        isHostileDismissal,
        hasInsult,
        isThreatening,
        isRepeated,
      }),
    };
  }

  private buildLocalReason(signals: {
    wordCount: number;
    hasQuestion: boolean;
    hasOpenQuestion: boolean;
    sharesSomething: boolean;
    showsInterest: boolean;
    usesWarmLanguage: boolean;
    isDismissive: boolean;
    isHostileDismissal: boolean;
    hasInsult: boolean;
    isThreatening: boolean;
    isRepeated: boolean;
  }): string {
    if (signals.isThreatening) {
      return 'El mensaje contiene lenguaje amenazante o coercitivo y termina la conversación.';
    }
    if (signals.hasInsult) {
      return 'El insulto reduce mucho la empatía y la seguridad. Reformula el mensaje con respeto.';
    }
    if (signals.isHostileDismissal) {
      return 'La expulsión directa resulta hostil y termina la conversación. Si quieres marcharte, exprésalo como un límite respetuoso.';
    }
    if (signals.isDismissive) {
      return 'El tono resulta distante y corta la conversación. Expresa el límite sin despreciar a la otra persona.';
    }
    if (signals.isRepeated) {
      return 'Repites una intervención anterior, por lo que baja la fluidez y no haces avanzar la conversación.';
    }
    if (signals.wordCount <= 3) {
      return 'La respuesta es demasiado breve. Añade una idea propia o una pregunta para mantener la conversación.';
    }
    if (signals.hasOpenQuestion && signals.showsInterest) {
      return 'La pregunta abierta muestra interés por la otra persona y ayuda a que la conversación avance.';
    }
    if (signals.hasQuestion && signals.sharesSomething) {
      return 'Compartes algo sobre ti y devuelves una pregunta, logrando un intercambio equilibrado.';
    }
    if (signals.usesWarmLanguage || signals.showsInterest) {
      return 'El tono muestra interés y cercanía. Una pregunta abierta aportaría todavía más iniciativa.';
    }
    if (!signals.hasQuestion) {
      return 'El mensaje se entiende, pero le falta una pregunta o una nueva idea que impulse la conversación.';
    }
    return 'El mensaje mantiene la conversación, aunque puede ser más concreto y personal.';
  }

  private normalize(value: string): string {
    return value
      .toLowerCase()
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .replace(/[^a-z0-9¿?¡!]+/g, ' ')
      .trim();
  }

  private clampScore(value: number): number {
    return this.roundScore(Math.min(10, Math.max(0, value)));
  }

  private roundScore(value: number): number {
    return Math.round(value * 10) / 10;
  }
}
