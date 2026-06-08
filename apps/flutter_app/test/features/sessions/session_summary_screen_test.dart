import 'package:datesim/features/sessions/models/session.dart';
import 'package:datesim/features/sessions/presentation/session_summary_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('muestra el resultado completado con puntuación y feedback', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SessionSummaryScreen(
          args: SessionSummaryArgs(
            scenarioName: 'Encuentro en la cafetería',
            status: SessionStatus.completed,
            overallScore: 7.8,
            feedback: 'Buen equilibrio entre interés e iniciativa.',
          ),
        ),
      ),
    );

    expect(find.text('Práctica completada'), findsOneWidget);
    expect(find.text('7.8'), findsOneWidget);
    expect(
      find.text('Buen equilibrio entre interés e iniciativa.'),
      findsOneWidget,
    );
    expect(find.text('Practicar de nuevo'), findsOneWidget);
  });

  testWidgets('presenta el rechazo con un mensaje respetuoso', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: SessionSummaryScreen(
          args: SessionSummaryArgs(
            scenarioName: 'Noche de fiesta',
            status: SessionStatus.rejected,
            overallScore: 2.1,
          ),
        ),
      ),
    );

    expect(find.text('La conversación terminó'), findsOneWidget);
    expect(
      find.text('Revisa el feedback y vuelve a intentarlo cuando quieras.'),
      findsOneWidget,
    );
  });
}
