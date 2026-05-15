import 'package:datesim/features/chat/data/chat_service.dart';
import 'package:datesim/features/chat/models/chat_event.dart';
import 'package:datesim/features/chat/providers/chat_providers.dart';
import 'package:datesim/features/home/models/scenario.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HappyPathChatService extends ChatService {
  _HappyPathChatService() : super(auth: _FakeFirebaseAuth());

  @override
  Stream<ChatEvent> sendMessage(String sessionId, String content) async* {
    yield const ChatEvent(type: 'delta', rawData: 'Hola');
    yield const ChatEvent(
      type: 'scorecard',
      rawData:
          '{"fluency":7,"empathy":6,"initiative":8,"clarity":7,"safety":9,"overall":7.4,"decision":"continue","reason":"Buen avance"}',
    );
    yield const ChatEvent(type: 'done', rawData: 'ok');
  }
}

class _MalformedScorecardService extends ChatService {
  _MalformedScorecardService() : super(auth: _FakeFirebaseAuth());

  @override
  Stream<ChatEvent> sendMessage(String sessionId, String content) async* {
    yield const ChatEvent(type: 'delta', rawData: 'Hola');
    yield const ChatEvent(type: 'scorecard', rawData: '{bad json');
    yield const ChatEvent(type: 'done', rawData: 'ok');
  }
}

class _RejectedDoneService extends ChatService {
  _RejectedDoneService() : super(auth: _FakeFirebaseAuth());

  @override
  Stream<ChatEvent> sendMessage(String sessionId, String content) async* {
    yield const ChatEvent(type: 'delta', rawData: 'No funciona');
    yield const ChatEvent(type: 'done', rawData: 'rejected');
  }
}

void main() {
  final scenario = Scenario(
    id: 's1',
    name: 'Cafe',
    description: 'Escenario prueba',
    difficulty: Difficulty.easy,
    characterName: 'Lucia',
    characterBio: 'Bio',
    openingMessage: 'Hola inicial',
  );

  test('ChatNotifier procesa delta -> scorecard -> done sin romper flujo',
      () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_HappyPathChatService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-1', scenario: scenario));
    notifier.addOpeningMessage('Hola inicial');

    await notifier.sendMessage('Que tal?');

    final state = container.read(chatProvider);
    expect(state.messages.where((m) => m.role == 'user').length, 1);
    expect(state.messages.where((m) => m.role == 'assistant').length, greaterThan(0));
    expect(state.lastScorecard, isNotNull);
    expect(state.isSending, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('ChatNotifier maneja scorecard malformado sin crash', () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_MalformedScorecardService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-2', scenario: scenario));

    await notifier.sendMessage('Mensaje');

    final state = container.read(chatProvider);
    expect(state.isSending, isFalse);
    expect(state.lastScorecard, isNull);
    expect(state.errorMessage, isNotNull);
  });

  test('ChatNotifier marca sessionEnded cuando done llega como rejected',
      () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_RejectedDoneService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-3', scenario: scenario));

    await notifier.sendMessage('Mensaje');

    final state = container.read(chatProvider);
    expect(state.sessionEnded, isTrue);
  });

  test('sendMessage sin configure no crashea y setea error', () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_HappyPathChatService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    await notifier.sendMessage('Mensaje');

    final state = container.read(chatProvider);
    expect(state.errorMessage, isNotNull);
  });

  test('addOpeningMessage solo agrega una vez y clearLastScorecard funciona',
      () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_HappyPathChatService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-4', scenario: scenario));
    notifier.addOpeningMessage('Hola inicial');
    notifier.addOpeningMessage('No debe repetirse');

    final state = container.read(chatProvider);
    expect(state.messages.length, 1);

    await notifier.sendMessage('Mensaje para generar scorecard');
    expect(container.read(chatProvider).lastScorecard, isNotNull);

    notifier.clearLastScorecard();
    expect(container.read(chatProvider).lastScorecard, isNull);
  });
}
