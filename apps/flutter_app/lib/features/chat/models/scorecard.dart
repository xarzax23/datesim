enum ScorecardDecision { continueDecision, coolDown, reject }

class Scorecard {
  final double fluency;
  final double empathy;
  final double initiative;
  final double clarity;
  final double safety;
  final double overall;
  final ScorecardDecision decision;
  final String reason;

  const Scorecard({
    required this.fluency,
    required this.empathy,
    required this.initiative,
    required this.clarity,
    required this.safety,
    required this.overall,
    required this.decision,
    required this.reason,
  });

  factory Scorecard.fromJson(Map<String, dynamic> json) {
    return Scorecard(
      fluency: _parseScore(json['fluency'], 'fluency'),
      empathy: _parseScore(json['empathy'], 'empathy'),
      initiative: _parseScore(json['initiative'], 'initiative'),
      clarity: _parseScore(json['clarity'], 'clarity'),
      safety: _parseScore(json['safety'], 'safety'),
      overall: _parseScore(json['overall'], 'overall'),
      decision: _parseDecision(json['decision']),
      reason: _parseReason(json['reason']),
    );
  }

  static double _parseScore(dynamic value, String fieldName) {
    final parsed = switch (value) {
      int v => v.toDouble(),
      double v => v,
      String v => double.tryParse(v),
      _ => null,
    };

    if (parsed == null) {
      throw FormatException('Invalid score type for "$fieldName": $value');
    }

    if (parsed < 0 || parsed > 10) {
      throw FormatException(
        'Score "$fieldName" out of range [0,10]: $parsed',
      );
    }

    return parsed;
  }

  static ScorecardDecision _parseDecision(dynamic value) {
    return switch (value) {
      'continue' => ScorecardDecision.continueDecision,
      'cool_down' || 'coolDown' => ScorecardDecision.coolDown,
      'reject' => ScorecardDecision.reject,
      _ => throw FormatException('Invalid scorecard decision: $value'),
    };
  }

  static String _parseReason(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
    throw FormatException('Invalid scorecard reason: $value');
  }
}
