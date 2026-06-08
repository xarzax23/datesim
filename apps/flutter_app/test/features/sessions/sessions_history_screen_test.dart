import 'package:datesim/features/home/models/scenario.dart';
import 'package:datesim/features/home/providers/scenarios_providers.dart';
import 'package:datesim/features/sessions/models/session.dart';
import 'package:datesim/features/sessions/presentation/sessions_history_screen.dart';
import 'package:datesim/features/sessions/providers/sessions_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra progreso e historial con datos reales de sesión', (
    tester,
  ) async {
    final sessions = [
      Session(
        id: 'completed',
        scenarioId: 'cafeteria',
        difficulty: 'easy',
        status: SessionStatus.completed,
        overallScore: 8,
        createdAt: DateTime(2026, 6, 8),
      ),
      Session(
        id: 'rejected',
        scenarioId: 'fiesta',
        difficulty: 'hard',
        status: SessionStatus.rejected,
        overallScore: 4,
        createdAt: DateTime(2026, 6, 7),
      ),
    ];
    const scenarios = [
      Scenario(
        id: 'cafeteria',
        name: 'Encuentro en la cafetería',
        description: 'Descripción',
        difficulty: Difficulty.easy,
        characterName: 'Lucía',
        characterBio: 'Bio',
        openingMessage: 'Hola',
      ),
      Scenario(
        id: 'fiesta',
        name: 'Noche de fiesta',
        description: 'Descripción',
        difficulty: Difficulty.hard,
        characterName: 'Daniela',
        characterBio: 'Bio',
        openingMessage: 'Hola',
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionsProvider.overrideWith((ref) async => sessions),
          scenariosProvider.overrideWith((ref) async => scenarios),
        ],
        child: const MaterialApp(home: SessionsHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Prácticas recientes'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('6.0'), findsOneWidget);
    expect(find.text('Encuentro en la cafetería'), findsOneWidget);
    expect(find.text('Noche de fiesta'), findsOneWidget);
  });

  testWidgets('muestra un estado vacío accionable', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionsProvider.overrideWith((ref) async => const <Session>[]),
          scenariosProvider.overrideWith((ref) async => const <Scenario>[]),
        ],
        child: const MaterialApp(home: SessionsHistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Aún no tienes prácticas guardadas.'), findsOneWidget);
    expect(find.text('Empezar una práctica'), findsOneWidget);
  });
}
