import 'dart:convert';

import 'package:datesim/features/chat/models/chat_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ChatEvent.fromJson conserva delta como texto plano', () {
    final event = ChatEvent.fromJson({'type': 'delta', 'data': 'Hola'});

    expect(event.type, 'delta');
    expect(event.rawData, 'Hola');
  });

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

  test('ChatEvent.isRejected no marca done ok como rechazado', () {
    const event = ChatEvent(type: 'done', rawData: 'ok');
    expect(event.isRejected, isFalse);
  });

  test('ChatEvent.fromJson normaliza error string', () {
    final event = ChatEvent.fromJson({
      'type': 'error',
      'data': 'Internal error',
    });

    expect(event.type, 'error');
    expect(event.rawData, 'Internal error');
  });
}
