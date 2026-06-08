// Scenarios

export type Difficulty = 'easy' | 'medium' | 'hard';

export interface PublicScenario {
  id: string;
  name: string;
  description: string;
  difficulty: Difficulty;
  characterName: string;
  characterBio: string;
  openingMessage: string;
}

export type Scenario = PublicScenario;

export interface ScenarioWithSystemPrompt extends PublicScenario {
  systemPrompt: string;
}

export type ScenariosResponse = PublicScenario[];
export type ScenarioResponse = PublicScenario;

// Sessions

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
  overallScore?: number | null;
  createdAt: string;
  updatedAt?: string;
}

export type SessionsResponse = SessionResponse[];
export type CompleteSessionResponse = SessionResponse;

// Messages / Turn

export type MessageRole = 'user' | 'assistant';

export interface SendMessageRequest {
  content: string;
  clientMessageId?: string;
}

export type ScorecardDecision = 'continue' | 'cool_down' | 'reject';

export interface Scorecard {
  fluency: number;
  empathy: number;
  initiative: number;
  clarity: number;
  safety: number;
  overall: number;
  decision: ScorecardDecision;
  reason: string;
}

export type ChatEventType = 'delta' | 'scorecard' | 'done' | 'error';
export type ChatDoneStatus = 'ok' | 'rejected';

export interface ChatEventDelta {
  type: 'delta';
  data: string;
}

export interface ChatEventScorecard {
  type: 'scorecard';
  data: string; // JSON-encoded Scorecard in the current SSE payload.
}

export interface ChatEventDone {
  type: 'done';
  data: ChatDoneStatus;
}

export interface ChatEventError {
  type: 'error';
  data: string;
}

export type ChatEvent =
  | ChatEventDelta
  | ChatEventScorecard
  | ChatEventDone
  | ChatEventError;

// User

export interface UserProfile {
  id: string;
  email?: string;
  displayName?: string;
  locale?: string;
  plan: 'free' | 'premium';
  createdAt: string;
}
