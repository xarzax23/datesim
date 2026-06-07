import 'dart:async';

import 'package:datesim/features/chat/data/chat_service.dart';
import 'package:datesim/features/chat/models/chat_event.dart';
import 'package:datesim/features/chat/presentation/chat_screen.dart';
import 'package:datesim/features/chat/providers/chat_providers.dart';
import 'package:datesim/features/home/models/scenario.dart';
import 'package:datesim/features/sessions/data/sessions_service.dart';
import 'package:datesim/features/sessions/models/session.dart';
import 'package:datesim/features/sessions/providers/sessions_providers.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeChatService extends ChatService {
  _FakeChatService() : super(auth: _FakeFirebaseAuth());

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

class _RejectedChatService extends ChatService {
  _RejectedChatService() : super(auth: _FakeFirebaseAuth());

  @override
  Stream<ChatEvent> sendMessage(String sessionId, String content) async* {
    yield const ChatEvent(type: 'delta', rawData: 'Respuesta corta');
    yield const ChatEvent(type: 'done', rawData: 'rejected');
  }
}

class _ErrorChatService extends ChatService {
  _ErrorChatService() : super(auth: _FakeFirebaseAuth());

  @override
  Stream<ChatEvent> sendMessage(String sessionId, String content) async* {
    yield const ChatEvent(type: 'error', rawData: 'Error de prueba');
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
  testWidgets(
    'flujo SSE delta -> scorecard -> done renderiza scorecard en easy',
    (tester) async {
      final scenario = Scenario(
        id: 's1',
        name: 'Cafe',
        description: 'Escenario prueba',
        difficulty: Difficulty.easy,
        characterName: 'Lucia',
        characterBio: 'Bio',
        openingMessage: 'Hola, encantada.',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            chatServiceProvider.overrideWithValue(_FakeChatService()),
          ],
          child: MaterialApp(
            home: ChatScreen(sessionId: 'session-1', scenario: scenario),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Hola que tal?');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Buen avance'), findsOneWidget);
      expect(find.text('Continuar'), findsOneWidget);
      expect(find.text('Evaluacion del mensaje'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Evaluacion del mensaje'), findsNothing);
    },
  );

  testWidgets('scorecard no se muestra en dificultad medium', (tester) async {
    final scenario = Scenario(
      id: 's2',
      name: 'Cena',
      description: 'Escenario prueba',
      difficulty: Difficulty.medium,
      characterName: 'Valeria',
      characterBio: 'Bio',
      openingMessage: 'Hola, me alegra verte.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatServiceProvider.overrideWithValue(_FakeChatService())],
        child: MaterialApp(
          home: ChatScreen(sessionId: 'session-2', scenario: scenario),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mensaje');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Evaluacion del mensaje'), findsNothing);
  });

  testWidgets('muestra banner cuando la sesion termina por rechazo', (
    tester,
  ) async {
    final scenario = Scenario(
      id: 's3',
      name: 'Fiesta',
      description: 'Escenario prueba',
      difficulty: Difficulty.hard,
      characterName: 'Daniela',
      characterBio: 'Bio',
      openingMessage: 'Hola, que tal?',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatServiceProvider.overrideWithValue(_RejectedChatService()),
        ],
        child: MaterialApp(
          home: ChatScreen(sessionId: 'session-3', scenario: scenario),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mensaje');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.textContaining('ha terminado'), findsOneWidget);
  });

  testWidgets('permite finalizar y muestra el estado completado', (
    tester,
  ) async {
    final scenario = Scenario(
      id: 's5',
      name: 'Cafe',
      description: 'Escenario prueba',
      difficulty: Difficulty.easy,
      characterName: 'Lucia',
      characterBio: 'Bio',
      openingMessage: 'Hola, encantada.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          chatServiceProvider.overrideWithValue(_FakeChatService()),
          sessionsServiceProvider.overrideWithValue(
            _CompletedSessionsService(),
          ),
        ],
        child: MaterialApp(
          home: ChatScreen(sessionId: 'session-5', scenario: scenario),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Encantado de conocerte.');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.stop_circle_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Finalizar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Práctica completada. Tu resultado se ha guardado.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });

  testWidgets('muestra snackbar cuando llega evento de error', (tester) async {
    final scenario = Scenario(
      id: 's4',
      name: 'Cafe',
      description: 'Escenario prueba',
      difficulty: Difficulty.easy,
      characterName: 'Lucia',
      characterBio: 'Bio',
      openingMessage: 'Hola, encantada.',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [chatServiceProvider.overrideWithValue(_ErrorChatService())],
        child: MaterialApp(
          home: ChatScreen(sessionId: 'session-4', scenario: scenario),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Mensaje');
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();

    expect(find.text('Error de prueba'), findsOneWidget);
  });
}
