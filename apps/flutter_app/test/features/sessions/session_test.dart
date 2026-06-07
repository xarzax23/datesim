import 'package:datesim/features/sessions/models/session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Session.fromJson', () {
    test('parsea sesion activa con score nulo', () {
      final session = Session.fromJson({
        'id': 'session-1',
        'scenarioId': 'cafeteria',
        'difficulty': 'easy',
        'status': 'active',
        'overallScore': null,
        'createdAt': '2026-05-26T18:00:00.000Z',
      });

      expect(session.id, 'session-1');
      expect(session.scenarioId, 'cafeteria');
      expect(session.difficulty, 'easy');
      expect(session.status, SessionStatus.active);
      expect(session.overallScore, isNull);
      expect(
        session.createdAt.toUtc().toIso8601String(),
        '2026-05-26T18:00:00.000Z',
      );
    });

    test('parsea estados completado, rechazado y abandonado', () {
      Session build(String status) => Session.fromJson({
        'id': 'session-$status',
        'scenarioId': 'cafeteria',
        'difficulty': 'easy',
        'status': status,
        'overallScore': 7.5,
        'createdAt': '2026-05-26T18:00:00.000Z',
      });

      expect(build('completed').status, SessionStatus.completed);
      expect(build('rejected').status, SessionStatus.rejected);
      expect(build('abandoned').status, SessionStatus.abandoned);
      expect(build('completed').overallScore, 7.5);
    });

    test('estado desconocido cae a active para no romper UI', () {
      final session = Session.fromJson({
        'id': 'session-unknown',
        'scenarioId': 'cafeteria',
        'difficulty': 'easy',
        'status': 'paused',
        'overallScore': null,
        'createdAt': '2026-05-26T18:00:00.000Z',
      });

      expect(session.status, SessionStatus.active);
    });
  });
}
