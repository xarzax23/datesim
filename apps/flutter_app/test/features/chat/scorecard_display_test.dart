import 'package:datesim/features/chat/models/scorecard.dart';
import 'package:datesim/features/chat/widgets/scorecard_display.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Scorecard buildScorecard({required String decision}) {
    return Scorecard.fromJson({
      'fluency': 2,
      'empathy': 5,
      'initiative': 8,
      'clarity': 7,
      'safety': 9,
      'overall': 6.2,
      'decision': decision,
      'reason': 'Respuesta util para mejorar.',
    });
  }

  testWidgets('muestra metricas, badge y reason', (tester) async {
    final scorecard = buildScorecard(decision: 'cool_down');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScorecardDisplay(scorecard: scorecard),
        ),
      ),
    );

    expect(find.text('Evaluacion del mensaje'), findsOneWidget);
    expect(find.text('Fluidez'), findsOneWidget);
    expect(find.text('Empatia'), findsOneWidget);
    expect(find.text('Iniciativa'), findsOneWidget);
    expect(find.text('Claridad'), findsOneWidget);
    expect(find.text('Seguridad'), findsOneWidget);
    expect(find.text('Enfriar'), findsOneWidget);
    expect(find.text('Respuesta util para mejorar.'), findsOneWidget);
  });

  testWidgets('usa datos dinamicos sin hardcode', (tester) async {
    final scorecard = buildScorecard(decision: 'reject');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScorecardDisplay(scorecard: scorecard),
        ),
      ),
    );

    expect(find.text('Total: 6.2/10'), findsOneWidget);
    expect(find.text('Rechazo'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNWidgets(5));
  });
}
