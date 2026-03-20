export interface Scenario {
  id: string;
  name: string;
  description: string;
  difficulty: 'easy' | 'medium' | 'hard';
  characterName: string;
  characterBio: string;
  openingMessage: string;
  systemPrompt: string;
}
