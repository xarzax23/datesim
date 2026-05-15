import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_providers.dart';
import '../../home/models/scenario.dart';
import '../widgets/scorecard_display.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String sessionId;
  final Scenario scenario;

  const ChatScreen({
    super.key,
    required this.sessionId,
    required this.scenario,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    final opening = widget.scenario.openingMessage;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(chatProvider.notifier);
      notifier.configure(
        (sessionId: widget.sessionId, scenario: widget.scenario),
      );
      notifier.addOpeningMessage(opening);
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).sendMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatState = ref.watch(chatProvider);
    final showScorecard =
        chatState.lastScorecard != null &&
        widget.scenario.difficulty == Difficulty.easy;

    ref.listen(chatProvider, (_, __) => _scrollToBottom());

    ref.listen<String?>(
      chatProvider.select((s) => s.errorMessage),
      (_, error) {
        if (error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error),
              backgroundColor: theme.colorScheme.error,
            ),
          );
        }
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scenario.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // TODO: mostrar scorecard / info de sesión
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.sessionEnded)
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: theme.colorScheme.errorContainer,
              child: Text(
                'La sesión ha terminado. ¡Inténtalo de nuevo!',
                style:
                    TextStyle(color: theme.colorScheme.onErrorContainer),
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: chatState.messages.length + (showScorecard ? 1 : 0),
              itemBuilder: (context, index) {
                if (showScorecard && index == chatState.messages.length) {
                  return AnimatedOpacity(
                    opacity: showScorecard ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                    child: ScorecardDisplay(
                      scorecard: chatState.lastScorecard!,
                      onDismiss: () {
                        ref.read(chatProvider.notifier).clearLastScorecard();
                      },
                    ),
                  );
                }

                final msg = chatState.messages[index];
                if (msg.isStreaming && msg.content.isEmpty) {
                  return const _TypingIndicator();
                }
                return _MessageBubble(
                  role: msg.role,
                  content: msg.content,
                  isStreaming: msg.isStreaming,
                );
              },
            ),
          ),
          _ChatInput(
            controller: _controller,
            onSend: _sendMessage,
            enabled: !chatState.isSending && !chatState.sessionEnded,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String role;
  final String content;
  final bool isStreaming;

  const _MessageBubble({
    required this.role,
    required this.content,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = role == 'user';
    final theme = Theme.of(context);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                content,
                style: TextStyle(
                  color: isUser
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isStreaming)
              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: isUser
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _Dot(delay: i * 200),
            ),
          ),
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Opacity(
        opacity: 0.3 + _controller.value * 0.7,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool enabled;

  const _ChatInput({
    required this.controller,
    required this.onSend,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? (_) => onSend() : null,
              enabled: enabled,
              decoration: const InputDecoration(
                hintText: 'Escribe tu mensaje...',
                border: InputBorder.none,
                filled: false,
              ),
              maxLines: 4,
              minLines: 1,
            ),
          ),
          IconButton.filled(
            onPressed: enabled ? onSend : null,
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
}
