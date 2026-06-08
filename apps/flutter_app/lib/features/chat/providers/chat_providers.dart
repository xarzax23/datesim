import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../home/models/scenario.dart';
import '../../sessions/models/session.dart';
import '../../sessions/providers/sessions_providers.dart';
import '../data/chat_service.dart';
import '../models/scorecard.dart';

enum SessionEndReason { completed, rejected }

class ChatMessage {
  final String id;
  final String role;
  final String content;
  final bool isStreaming;

  ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.isStreaming = false,
  });

  ChatMessage copyWith({String? content, bool? isStreaming}) => ChatMessage(
    id: id,
    role: role,
    content: content ?? this.content,
    isStreaming: isStreaming ?? this.isStreaming,
  );
}

class ChatState {
  static const _noChange = Object();

  final List<ChatMessage> messages;
  final bool isSending;
  final bool isCompleting;
  final bool sessionEnded;
  final SessionEndReason? sessionEndReason;
  final double? finalScore;
  final String? errorMessage;
  final Scorecard? lastScorecard;
  final String? retryContent;
  final String? retryClientMessageId;
  final String? retryAssistantId;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.isCompleting = false,
    this.sessionEnded = false,
    this.sessionEndReason,
    this.finalScore,
    this.errorMessage,
    this.lastScorecard,
    this.retryContent,
    this.retryClientMessageId,
    this.retryAssistantId,
  });

  bool get canRetry =>
      retryContent != null &&
      retryClientMessageId != null &&
      retryAssistantId != null;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? isCompleting,
    bool? sessionEnded,
    SessionEndReason? sessionEndReason,
    double? finalScore,
    Object? errorMessage = _noChange,
    Scorecard? lastScorecard,
    bool clearLastScorecard = false,
    Object? retryContent = _noChange,
    Object? retryClientMessageId = _noChange,
    Object? retryAssistantId = _noChange,
  }) => ChatState(
    messages: messages ?? this.messages,
    isSending: isSending ?? this.isSending,
    isCompleting: isCompleting ?? this.isCompleting,
    sessionEnded: sessionEnded ?? this.sessionEnded,
    sessionEndReason: sessionEndReason ?? this.sessionEndReason,
    finalScore: finalScore ?? this.finalScore,
    errorMessage: errorMessage == _noChange
        ? this.errorMessage
        : errorMessage as String?,
    lastScorecard: clearLastScorecard
        ? null
        : lastScorecard ?? this.lastScorecard,
    retryContent: retryContent == _noChange
        ? this.retryContent
        : retryContent as String?,
    retryClientMessageId: retryClientMessageId == _noChange
        ? this.retryClientMessageId
        : retryClientMessageId as String?,
    retryAssistantId: retryAssistantId == _noChange
        ? this.retryAssistantId
        : retryAssistantId as String?,
  );
}

typedef ChatProviderArgs = ({String sessionId, Scenario scenario});

class ChatNotifier extends Notifier<ChatState> {
  late ChatService _service;
  String? _sessionId;
  Scenario? _scenario;
  String? _activeContent;
  String? _activeClientMessageId;
  String? _activeAssistantId;
  int _requestGeneration = 0;

  @override
  ChatState build() {
    _service = ref.watch(chatServiceProvider);
    ref.onDispose(_service.cancelActiveRequest);
    return const ChatState();
  }

  void configure(ChatProviderArgs args) {
    if (_sessionId != args.sessionId) {
      cancelResponse();
      state = const ChatState();
    }
    _sessionId = args.sessionId;
    _scenario = args.scenario;
  }

  Scenario? get scenario => _scenario;

  void clearLastScorecard() {
    state = state.copyWith(clearLastScorecard: true);
  }

  void addOpeningMessage(String content) {
    if (state.messages.isNotEmpty) return;
    state = state.copyWith(
      messages: [
        ChatMessage(id: 'opening', role: 'assistant', content: content),
      ],
    );
  }

  Future<void> sendMessage(String content) async {
    final currentSessionId = _sessionId;
    if (currentSessionId == null) {
      state = state.copyWith(
        errorMessage: 'La sesion no esta configurada correctamente.',
      );
      return;
    }

    if (state.isSending || state.isCompleting || state.sessionEnded) return;

    final timestamp = DateTime.now().microsecondsSinceEpoch;
    await _sendMessage(
      sessionId: currentSessionId,
      content: content,
      clientMessageId: '$currentSessionId-$timestamp',
      assistantId: '${timestamp}_a',
      appendUserMessage: true,
    );
  }

  Future<void> retryLastMessage() async {
    final currentSessionId = _sessionId;
    final content = state.retryContent;
    final clientMessageId = state.retryClientMessageId;
    final assistantId = state.retryAssistantId;
    if (currentSessionId == null ||
        content == null ||
        clientMessageId == null ||
        assistantId == null ||
        state.isSending ||
        state.isCompleting ||
        state.sessionEnded) {
      return;
    }

    await _sendMessage(
      sessionId: currentSessionId,
      content: content,
      clientMessageId: clientMessageId,
      assistantId: assistantId,
      appendUserMessage: false,
    );
  }

  void cancelResponse() {
    if (!state.isSending) return;

    final content = _activeContent;
    final clientMessageId = _activeClientMessageId;
    final assistantId = _activeAssistantId;
    _requestGeneration++;
    _service.cancelActiveRequest();

    if (content == null || clientMessageId == null || assistantId == null) {
      state = state.copyWith(isSending: false);
      return;
    }

    final updated = state.messages
        .map(
          (message) => message.id == assistantId
              ? message.copyWith(
                  content: message.content.isEmpty
                      ? 'Respuesta detenida.'
                      : message.content,
                  isStreaming: false,
                )
              : message,
        )
        .toList();
    state = state.copyWith(
      messages: updated,
      isSending: false,
      errorMessage: null,
      retryContent: content,
      retryClientMessageId: clientMessageId,
      retryAssistantId: assistantId,
    );
    _clearActiveRequest();
  }

  Future<void> _sendMessage({
    required String sessionId,
    required String content,
    required String clientMessageId,
    required String assistantId,
    required bool appendUserMessage,
  }) async {
    final requestGeneration = ++_requestGeneration;
    _activeContent = content;
    _activeClientMessageId = clientMessageId;
    _activeAssistantId = assistantId;

    final userMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_u',
      role: 'user',
      content: content,
    );
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: 'assistant',
      content: '',
      isStreaming: true,
    );

    state = state.copyWith(
      messages: appendUserMessage
          ? [...state.messages, userMsg, assistantMsg]
          : state.messages
                .map(
                  (message) =>
                      message.id == assistantId ? assistantMsg : message,
                )
                .toList(),
      isSending: true,
      errorMessage: null,
      clearLastScorecard: true,
      retryContent: null,
      retryClientMessageId: null,
      retryAssistantId: null,
    );

    var receivedTerminalEvent = false;
    try {
      await for (final event in _service.sendMessage(
        sessionId,
        content,
        clientMessageId: clientMessageId,
      )) {
        if (requestGeneration != _requestGeneration) return;
        switch (event.type) {
          case 'delta':
            _appendToken(assistantId, event.rawData);
          case 'scorecard':
            _handleScorecard(event.rawData);
          case 'done':
            receivedTerminalEvent = true;
            _finishStreaming(assistantId, rejected: event.isRejected);
          case 'error':
            receivedTerminalEvent = true;
            _handleError(
              assistantId,
              event.rawData,
              content: content,
              clientMessageId: clientMessageId,
            );
        }
      }
      if (requestGeneration == _requestGeneration &&
          !receivedTerminalEvent &&
          state.isSending) {
        _handleError(
          assistantId,
          'La respuesta se interrumpió antes de terminar.',
          content: content,
          clientMessageId: clientMessageId,
        );
      }
    } catch (_) {
      if (requestGeneration == _requestGeneration) {
        _handleError(
          assistantId,
          'No se pudo conectar al servidor.',
          content: content,
          clientMessageId: clientMessageId,
        );
      }
    } finally {
      if (requestGeneration == _requestGeneration) {
        _clearActiveRequest();
      }
    }
  }

  Future<void> completeSession() async {
    final currentSessionId = _sessionId;
    if (currentSessionId == null) {
      state = state.copyWith(
        errorMessage: 'La sesión no está configurada correctamente.',
      );
      return;
    }
    if (state.isSending || state.isCompleting || state.sessionEnded) return;

    final hasUserTurn = state.messages.any((message) => message.role == 'user');
    if (!hasUserTurn) {
      state = state.copyWith(
        errorMessage: 'Envía al menos un mensaje antes de finalizar.',
      );
      return;
    }

    state = state.copyWith(isCompleting: true, errorMessage: null);
    try {
      final session = await ref
          .read(sessionsServiceProvider)
          .completeSession(currentSessionId);
      if (session.status != SessionStatus.completed) {
        throw StateError('La sesión no se completó correctamente.');
      }
      state = state.copyWith(
        isCompleting: false,
        sessionEnded: true,
        sessionEndReason: SessionEndReason.completed,
        finalScore: session.overallScore,
      );
      ref.invalidate(sessionsProvider);
    } catch (error) {
      state = state.copyWith(
        isCompleting: false,
        errorMessage: error.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void _handleScorecard(String rawData) {
    try {
      // Scorecard events arrive as JSON payloads inside SSE `data`.
      final decoded = jsonDecode(rawData);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Scorecard payload is not a JSON object.');
      }
      final scorecard = Scorecard.fromJson(decoded);
      state = state.copyWith(lastScorecard: scorecard);
    } catch (_) {
      // Keep chat streaming alive even if scorecard payload is malformed.
      state = state.copyWith(
        errorMessage: 'No se pudo procesar el scorecard recibido.',
      );
    }
  }

  void _appendToken(String msgId, String token) {
    final updated = state.messages
        .map((m) => m.id == msgId ? m.copyWith(content: m.content + token) : m)
        .toList();
    state = state.copyWith(messages: updated);
  }

  void _finishStreaming(String msgId, {required bool rejected}) {
    final updated = state.messages
        .map((m) => m.id == msgId ? m.copyWith(isStreaming: false) : m)
        .toList();
    state = state.copyWith(
      messages: updated,
      isSending: false,
      sessionEnded: rejected ? true : state.sessionEnded,
      sessionEndReason: rejected
          ? SessionEndReason.rejected
          : state.sessionEndReason,
      finalScore: rejected ? state.lastScorecard?.overall : state.finalScore,
      retryContent: null,
      retryClientMessageId: null,
      retryAssistantId: null,
    );
  }

  void _handleError(
    String msgId,
    String error, {
    required String content,
    required String clientMessageId,
  }) {
    final updated = state.messages
        .map(
          (m) => m.id == msgId
              ? m.copyWith(
                  content: 'No se pudo obtener respuesta.',
                  isStreaming: false,
                )
              : m,
        )
        .toList();
    state = state.copyWith(
      messages: updated,
      isSending: false,
      errorMessage: error,
      retryContent: content,
      retryClientMessageId: clientMessageId,
      retryAssistantId: msgId,
    );
  }

  void _clearActiveRequest() {
    _activeContent = null;
    _activeClientMessageId = null;
    _activeAssistantId = null;
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(auth: ref.watch(firebaseAuthProvider));
});

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
