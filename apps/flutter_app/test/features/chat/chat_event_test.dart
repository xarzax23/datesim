import 'dart:convert';

import 'package:datesim/features/chat/models/chat_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatEvent.fromJson serializa data map a JSON valido', () {
    final event = ChatEvent.fromJson({
      'type': 'scorecard',
      'data': {'fluency': 7, 'decision': 'continue'},
    });

    final decoded = jsonDecode(event.rawData) as Map<String, dynamic>;
    expect(decoded['fluency'], 7);
    expect(decoded['decision'], 'continue');
  });

  test('ChatEvent.isRejected detecta done rejected', () {
    const event = ChatEvent(type: 'done', rawData: 'rejected');
    expect(event.isRejected, isTrue);
  });
}
