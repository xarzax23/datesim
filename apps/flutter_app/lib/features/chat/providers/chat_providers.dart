import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/chat_service.dart';
import '../models/chat_event.dart';

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
  final List<ChatMessage> messages;
  final bool isSending;
  final bool sessionEnded;
  final String? errorMessage;

  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.sessionEnded = false,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    bool? sessionEnded,
    String? errorMessage,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        isSending: isSending ?? this.isSending,
        sessionEnded: sessionEnded ?? this.sessionEnded,
        errorMessage: errorMessage,
      );
}

class ChatNotifier extends FamilyNotifier<ChatState, String> {
  late ChatService _service;
  late String _sessionId;

  @override
  ChatState build(String sessionId) {
    _service = ref.watch(chatServiceProvider);
    _sessionId = sessionId;
    return const ChatState();
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
    );

    try {
      await for (final event in _service.sendMessage(_sessionId, content)) {
        switch (event.type) {
          case 'delta':
            _appendToken(assistantId, event.rawData);
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

final chatProvider =
    NotifierProvider.family<ChatNotifier, ChatState, String>(
  ChatNotifier.new,
);
