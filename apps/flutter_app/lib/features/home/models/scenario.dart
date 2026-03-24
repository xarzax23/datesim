enum Difficulty { easy, medium, hard }

extension DifficultyLabel on Difficulty {
  String get label => switch (this) {
        Difficulty.easy => 'Fácil',
        Difficulty.medium => 'Media',
        Difficulty.hard => 'Difícil',
      };
}

class Scenario {
  final String id;
  final String name;
  final String description;
  final Difficulty difficulty;
  final String characterName;
  final String characterBio;
  final String openingMessage;

  const Scenario({
    required this.id,
    required this.name,
    required this.description,
    required this.difficulty,
    required this.characterName,
    required this.characterBio,
    required this.openingMessage,
  });

  factory Scenario.fromJson(Map<String, dynamic> json) {
    return Scenario(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      difficulty: _parseDifficulty(json['difficulty'] as String),
      characterName: json['characterName'] as String,
      characterBio: json['characterBio'] as String,
      openingMessage: json['openingMessage'] as String,
    );
  }

  static Difficulty _parseDifficulty(String value) => switch (value) {
        'easy' => Difficulty.easy,
        'medium' => Difficulty.medium,
        'hard' => Difficulty.hard,
        _ => Difficulty.easy,
      };
}
