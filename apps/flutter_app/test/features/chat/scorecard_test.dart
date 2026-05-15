import 'package:flutter_test/flutter_test.dart';
import 'package:datesim/features/chat/models/scorecard.dart';

void main() {
  group('Scorecard.fromJson', () {
    test('parsea payload valido correctamente', () {
      final scorecard = Scorecard.fromJson({
        'fluency': 7,
        'empathy': 6.5,
        'initiative': '8',
        'clarity': 5,
        'safety': 9,
        'overall': 7.1,
        'decision': 'cool_down',
        'reason': 'Buena intencion, pero falta naturalidad.',
      });

      expect(scorecard.fluency, 7);
      expect(scorecard.empathy, 6.5);
      expect(scorecard.initiative, 8);
      expect(scorecard.decision, ScorecardDecision.coolDown);
      expect(scorecard.reason, isNotEmpty);
    });

    test('lanza error cuando una metrica esta fuera de rango', () {
      expect(
        () => Scorecard.fromJson({
          'fluency': 11,
          'empathy': 6,
          'initiative': 5,
          'clarity': 5,
          'safety': 7,
          'overall': 6,
          'decision': 'continue',
          'reason': 'ok',
        }),
        throwsFormatException,
      );
    });

    test('lanza error con decision invalida', () {
      expect(
        () => Scorecard.fromJson({
          'fluency': 4,
          'empathy': 4,
          'initiative': 4,
          'clarity': 4,
          'safety': 4,
          'overall': 4,
          'decision': 'unknown',
          'reason': 'ok',
        }),
        throwsFormatException,
      );
    });
  });
}
