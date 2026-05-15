import 'package:flutter_test/flutter_test.dart';
import 'package:datesim/features/chat/models/scorecard.dart';
import 'package:datesim/features/chat/providers/chat_providers.dart';

void main() {
  test('ChatState.copyWith conserva flujo y actualiza scorecard', () {
    final initial = ChatState(
      messages: [
        ChatMessage(id: '1', role: 'assistant', content: 'Hola'),
      ],
      isSending: true,
      sessionEnded: false,
      errorMessage: null,
      lastScorecard: null,
    );

    final scorecard = Scorecard.fromJson({
      'fluency': 7,
      'empathy': 6,
      'initiative': 5,
      'clarity': 8,
      'safety': 9,
      'overall': 7,
      'decision': 'continue',
      'reason': 'Buen mensaje',
    });

    final updated = initial.copyWith(
      isSending: false,
      lastScorecard: scorecard,
    );

    expect(updated.messages.length, 1);
    expect(updated.isSending, isFalse);
    expect(updated.lastScorecard, isNotNull);

    final cleared = updated.copyWith(clearLastScorecard: true);
    expect(cleared.lastScorecard, isNull);
  });
}
