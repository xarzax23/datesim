enum SessionStatus { active, completed, rejected, abandoned }

class Session {
  final String id;
  final String scenarioId;
  final String difficulty;
  final SessionStatus status;
  final double? overallScore;
  final DateTime createdAt;

  const Session({
    required this.id,
    required this.scenarioId,
    required this.difficulty,
    required this.status,
    this.overallScore,
    required this.createdAt,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      scenarioId: json['scenarioId'] as String,
      difficulty: json['difficulty'] as String,
      status: _parseStatus(json['status'] as String),
      overallScore: (json['overallScore'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static SessionStatus _parseStatus(String value) => switch (value) {
        'active' => SessionStatus.active,
        'completed' => SessionStatus.completed,
        'rejected' => SessionStatus.rejected,
        'abandoned' => SessionStatus.abandoned,
        _ => SessionStatus.active,
      };
}
