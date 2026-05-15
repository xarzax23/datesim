import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../../home/models/scenario.dart';
import '../data/chat_service.dart';
import '../models/scorecard.dart';

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
  final bool sessionEnded;
  final String? errorMessage;
  final Scorecard? lastScorecard;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.sessionEnded = false,
    this.errorMessage,
    this.lastScorecard,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? sessionEnded,
    Object? errorMessage = _noChange,
    Scorecard? lastScorecard,
    bool clearLastScorecard = false,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        sessionEnded: sessionEnded ?? this.sessionEnded,
        errorMessage: errorMessage == _noChange
            ? this.errorMessage
            : errorMessage as String?,
        lastScorecard:
            clearLastScorecard ? null : lastScorecard ?? this.lastScorecard,
      );
}

typedef ChatProviderArgs = ({String sessionId, Scenario scenario});

class ChatNotifier extends Notifier<ChatState> {
  late ChatService _service;
  String? _sessionId;
  Scenario? _scenario;

  @override
  ChatState build() {
    _service = ref.watch(chatServiceProvider);
    return const ChatState();
  }

  void configure(ChatProviderArgs args) {
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

    if (state.isSending || state.sessionEnded) return;

    final userMsg = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_u',
      role: 'user',
      content: content,
    );
    final assistantId = '${DateTime.now().millisecondsSinceEpoch}_a';
    final assistantMsg = ChatMessage(
      id: assistantId,
      role: 'assistant',
      content: '',
      isStreaming: true,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg, assistantMsg],
      isSending: true,
      errorMessage: null,
      clearLastScorecard: true,
    );

    try {
      await for (final event in _service.sendMessage(currentSessionId, content)) {
        switch (event.type) {
          case 'delta':
            _appendToken(assistantId, event.rawData);
          case 'scorecard':
            _handleScorecard(event.rawData);
          case 'done':
            _finishStreaming(assistantId, rejected: event.isRejected);
          case 'error':
            _handleError(assistantId, event.rawData);
        }
      }
    } finally {
      if (state.isSending) {
        _finishStreaming(assistantId, rejected: false);
      }
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
    );
  }

  void _handleError(String msgId, String error) {
    final updated = state.messages
        .map((m) => m.id == msgId
            ? m.copyWith(
                content: 'No se pudo obtener respuesta.',
                isStreaming: false,
              )
            : m)
        .toList();
    state = state.copyWith(
      messages: updated,
      isSending: false,
      errorMessage: error,
    );
  }
}

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(auth: ref.watch(firebaseAuthProvider));
});

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(
  ChatNotifier.new,
);
