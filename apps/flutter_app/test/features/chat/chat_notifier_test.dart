import 'dart:async';

import 'package:datesim/features/chat/data/chat_service.dart';
import 'package:datesim/features/chat/models/chat_event.dart';
import 'package:datesim/features/chat/providers/chat_providers.dart';
import 'package:datesim/features/home/models/scenario.dart';
import 'package:datesim/features/sessions/data/sessions_service.dart';
import 'package:datesim/features/sessions/models/session.dart';
import 'package:datesim/features/sessions/providers/sessions_providers.dart';
import 'package:dio/dio.dart';
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
  Stream<ChatEvent> sendMessage(
    String sessionId,
    String content, {
    required String clientMessageId,
  }) async* {
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
  Stream<ChatEvent> sendMessage(
    String sessionId,
    String content, {
    required String clientMessageId,
  }) async* {
    yield const ChatEvent(type: 'delta', rawData: 'Hola');
    yield const ChatEvent(type: 'scorecard', rawData: '{bad json');
    yield const ChatEvent(type: 'done', rawData: 'ok');
  }
}

class _RejectedDoneService extends ChatService {
  _RejectedDoneService() : super(auth: _FakeFirebaseAuth());

  @override
  Stream<ChatEvent> sendMessage(
    String sessionId,
    String content, {
    required String clientMessageId,
  }) async* {
    yield const ChatEvent(type: 'delta', rawData: 'No funciona');
    yield const ChatEvent(
      type: 'scorecard',
      rawData:
          '{"fluency":2,"empathy":1,"initiative":1,"clarity":4,"safety":2,"overall":1.8,"decision":"reject","reason":"La conversación no puede continuar."}',
    );
    yield const ChatEvent(type: 'done', rawData: 'rejected');
  }
}

class _RetryChatService extends ChatService {
  _RetryChatService() : super(auth: _FakeFirebaseAuth());

  int attempts = 0;
  final List<String> clientMessageIds = [];

  @override
  Stream<ChatEvent> sendMessage(
    String sessionId,
    String content, {
    required String clientMessageId,
  }) async* {
    attempts++;
    clientMessageIds.add(clientMessageId);
    if (attempts == 1) {
      yield const ChatEvent(type: 'error', rawData: 'Conexion interrumpida');
      return;
    }
    yield const ChatEvent(type: 'delta', rawData: 'Respuesta recuperada');
    yield const ChatEvent(type: 'done', rawData: 'ok');
  }
}

class _ControlledChatService extends ChatService {
  _ControlledChatService() : super(auth: _FakeFirebaseAuth());

  final controller = StreamController<ChatEvent>();
  bool cancelCalled = false;

  @override
  Stream<ChatEvent> sendMessage(
    String sessionId,
    String content, {
    required String clientMessageId,
  }) async* {
    yield* controller.stream;
  }

  @override
  void cancelActiveRequest() {
    cancelCalled = true;
    unawaited(controller.close());
  }
}

class _CompletedSessionsService extends SessionsService {
  _CompletedSessionsService() : super(dio: Dio(), auth: _FakeFirebaseAuth());

  @override
  Future<Session> completeSession(String sessionId) async {
    return Session(
      id: sessionId,
      scenarioId: 'cafeteria',
      difficulty: 'easy',
      status: SessionStatus.completed,
      overallScore: 7.4,
      createdAt: DateTime.utc(2026, 6, 7),
    );
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

  test(
    'ChatNotifier procesa delta -> scorecard -> done sin romper flujo',
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
      expect(
        state.messages.where((m) => m.role == 'assistant').length,
        greaterThan(0),
      );
      expect(state.lastScorecard, isNotNull);
      expect(state.isSending, isFalse);
      expect(state.errorMessage, isNull);
    },
  );

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

  test(
    'ChatNotifier marca sessionEnded cuando done llega como rejected',
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
      expect(state.sessionEndReason, SessionEndReason.rejected);
      expect(state.finalScore, 1.8);
    },
  );

  test('completeSession marca la práctica como completada', () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_HappyPathChatService()),
        sessionsServiceProvider.overrideWithValue(_CompletedSessionsService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-completed', scenario: scenario));
    notifier.addOpeningMessage('Hola inicial');
    await notifier.sendMessage('Me alegra conocerte. ¿Vienes mucho por aquí?');
    await notifier.completeSession();

    final state = container.read(chatProvider);
    expect(state.sessionEnded, isTrue);
    expect(state.sessionEndReason, SessionEndReason.completed);
    expect(state.finalScore, 7.4);
    expect(state.isCompleting, isFalse);
  });

  test('configure limpia el estado al abrir una sesión diferente', () async {
    final container = ProviderContainer(
      overrides: [
        chatServiceProvider.overrideWithValue(_RejectedDoneService()),
      ],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-rejected', scenario: scenario));
    await notifier.sendMessage('Mensaje');
    expect(container.read(chatProvider).sessionEnded, isTrue);

    notifier.configure((sessionId: 'session-new', scenario: scenario));

    final state = container.read(chatProvider);
    expect(state.messages, isEmpty);
    expect(state.sessionEnded, isFalse);
    expect(state.sessionEndReason, isNull);
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

  test(
    'addOpeningMessage solo agrega una vez y clearLastScorecard funciona',
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
    },
  );

  test('cancelar una respuesta conserva el turno para reintentar', () async {
    final service = _ControlledChatService();
    final container = ProviderContainer(
      overrides: [chatServiceProvider.overrideWithValue(service)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(chatProvider.notifier);
    notifier.configure((sessionId: 'session-cancel', scenario: scenario));

    final sendFuture = notifier.sendMessage('Mensaje pendiente');
    await Future<void>.delayed(Duration.zero);
    expect(container.read(chatProvider).isSending, isTrue);

    notifier.cancelResponse();
    await sendFuture;

    final state = container.read(chatProvider);
    expect(service.cancelCalled, isTrue);
    expect(state.isSending, isFalse);
    expect(state.canRetry, isTrue);
    expect(
      state.messages.where((message) => message.role == 'user'),
      hasLength(1),
    );
    expect(state.messages.last.content, 'Respuesta detenida.');
  });

  test(
    'reintentar reutiliza el identificador y no duplica al usuario',
    () async {
      final service = _RetryChatService();
      final container = ProviderContainer(
        overrides: [chatServiceProvider.overrideWithValue(service)],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatProvider.notifier);
      notifier.configure((sessionId: 'session-retry', scenario: scenario));

      await notifier.sendMessage('Mensaje recuperable');
      expect(container.read(chatProvider).canRetry, isTrue);

      await notifier.retryLastMessage();

      final state = container.read(chatProvider);
      expect(service.attempts, 2);
      expect(service.clientMessageIds.toSet(), hasLength(1));
      expect(
        state.messages.where((message) => message.role == 'user'),
        hasLength(1),
      );
      expect(state.messages.last.content, 'Respuesta recuperada');
      expect(state.canRetry, isFalse);
    },
  );
}
