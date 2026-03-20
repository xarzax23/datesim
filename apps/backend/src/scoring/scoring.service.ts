import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import OpenAI from 'openai';

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

  constructor(private config: ConfigService) {
    this.openai = new OpenAI({
      apiKey: this.config.get<string>('OPENAI_API_KEY'),
    });
  }

  async scoreMessage(
    userMessage: string,
    context: string[],
    difficulty: string,
  ): Promise<ScorecardResult> {
    const response = await this.openai.chat.completions.create({
      model: 'gpt-4o-mini',
      response_format: { type: 'json_object' },
      messages: [
        {
          role: 'system',
          content: `You are a dating conversation evaluator. Score the user's latest message on a scale 0-10 for each metric. Return JSON only.
Difficulty: ${difficulty}
Metrics: fluency, empathy, initiative, clarity, safety
Also determine: decision (continue/cool_down/reject) and reason.
Higher difficulty = stricter thresholds for "continue".
JSON schema: {"fluency":number,"empathy":number,"initiative":number,"clarity":number,"safety":number,"overall":number,"decision":"continue"|"cool_down"|"reject","reason":"string"}`,
        },
        ...context.map((msg, i) => ({
          role: (i % 2 === 0 ? 'assistant' : 'user') as 'assistant' | 'user',
          content: msg,
        })),
        { role: 'user', content: userMessage },
      ],
      temperature: 0.1,
      max_tokens: 300,
    });

    const raw = response.choices[0]?.message?.content ?? '{}';
    return JSON.parse(raw) as ScorecardResult;
  }
}
