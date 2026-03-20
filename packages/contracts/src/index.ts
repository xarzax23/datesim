// ── Scenarios ──────────────────────────────────────────────

export type Difficulty = 'easy' | 'medium' | 'hard';

export interface Scenario {
  id: string;
  name: string;
  description: string;
  difficulty: Difficulty;
  systemPrompt: string;
  characterName: string;
  characterBio: string;
  openingMessage: string;
}

// ── Sessions ──────────────────────────────────────────────

export type SessionStatus = 'active' | 'completed' | 'rejected' | 'abandoned';

export interface CreateSessionRequest {
  scenarioId: string;
  difficulty: Difficulty;
}

export interface SessionResponse {
  id: string;
  scenarioId: string;
  difficulty: Difficulty;
  status: SessionStatus;
  overallScore: number | null;
  createdAt: string;
  updatedAt: string;
}

// ── Messages / Turn ───────────────────────────────────────

export type MessageRole = 'user' | 'assistant' | 'system';

export interface SendMessageRequest {
  content: string;
}

export interface Scorecard {
  fluency: number;     // 0-10
  empathy: number;     // 0-10
  initiative: number;  // 0-10
  clarity: number;     // 0-10
  safety: number;      // 0-10
  overall: number;     // 0-10 average
  decision: 'continue' | 'cool_down' | 'reject';
  feedback?: string;
}

/** SSE event types sent during a chat turn */
export type ChatEventType = 'token' | 'scorecard' | 'done' | 'error';

export interface ChatEventToken {
  type: 'token';
  data: string; // partial token
}

export interface ChatEventScorecard {
  type: 'scorecard';
  data: Scorecard;
}

export interface ChatEventDone {
  type: 'done';
  data: {
    messageId: string;
    fullContent: string;
    turnIndex: number;
  };
}

export interface ChatEventError {
  type: 'error';
  data: { message: string };
}

export type ChatEvent =
  | ChatEventToken
  | ChatEventScorecard
  | ChatEventDone
  | ChatEventError;

// ── User ──────────────────────────────────────────────────

export interface UserProfile {
  id: string;
  email?: string;
  displayName?: string;
  locale?: string;
  plan: 'free' | 'premium';
  createdAt: string;
}
