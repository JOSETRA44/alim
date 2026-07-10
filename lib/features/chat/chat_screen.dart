import 'package:alim_engine/alim_engine.dart';
import 'package:alim_theme_engine/alim_theme_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../common/formatting.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(engineProvider).markChatRead(widget.chatId);
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    final chats = ref.watch(chatsProvider).value ?? const <Chat>[];
    final chat = chats.where((c) => c.id == widget.chatId).firstOrNull;

    return Scaffold(
      appBar: AppBar(title: Text(chat?.title ?? '')),
      body: Column(
        children: [
          Expanded(
            child: switch (messages) {
              AsyncData(:final value) => _MessageList(
                  messages: value,
                  isGroup: chat?.kind == ChatKind.group,
                ),
              AsyncError(:final error) => Center(child: Text('Error: $error')),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          _InputBar(chatId: widget.chatId),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.isGroup});

  final List<Message> messages;
  final bool isGroup;

  @override
  Widget build(BuildContext context) {
    // reverse + índice invertido: ancla el scroll abajo (último mensaje)
    // sin recalcular offsets al llegar mensajes nuevos.
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[messages.length - 1 - index];
        return _MessageBubble(
          key: ValueKey(message.id),
          message: message,
          showSender: isGroup && !message.isOutgoing,
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.showSender,
  });

  final Message message;
  final bool showSender;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final outgoing = message.isOutgoing;
    // Estilo compilado por el theme engine (spec ALIM). El fallback solo
    // aplica si un test monta la burbuja fuera del tema de la app.
    final bubble = theme.extension<AlimBubbleStyle>() ??
        AlimBubbleStyle(
          incoming: theme.colorScheme.surfaceContainerHighest,
          outgoing: theme.colorScheme.primaryContainer,
          radius: 16,
          tailRadius: 4,
          maxWidthFraction: 0.75,
        );

    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: BoxConstraints(
          maxWidth:
              MediaQuery.sizeOf(context).width * bubble.maxWidthFraction,
        ),
        decoration: BoxDecoration(
          color: outgoing ? bubble.outgoing : bubble.incoming,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(bubble.radius),
            topRight: Radius.circular(bubble.radius),
            bottomLeft:
                Radius.circular(outgoing ? bubble.radius : bubble.tailRadius),
            bottomRight:
                Radius.circular(outgoing ? bubble.tailRadius : bubble.radius),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showSender && message.senderName != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.senderName!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              switch (message.content) {
                TextContent(:final text) => text,
                UnsupportedContent(:final description) => '[$description]',
              },
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 2),
            Text(
              formatMessageTime(message.sentAt),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends ConsumerStatefulWidget {
  const _InputBar({required this.chatId});

  final String chatId;

  @override
  ConsumerState<_InputBar> createState() => _InputBarState();
}

class _InputBarState extends ConsumerState<_InputBar> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    ref.read(engineProvider).sendText(widget.chatId, text);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                textInputAction: TextInputAction.send,
                decoration: const InputDecoration(hintText: 'Mensaje'),
                onSubmitted: (_) => _send(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              icon: const Icon(Icons.arrow_upward),
              tooltip: 'Enviar',
              color: theme.colorScheme.onPrimary,
              onPressed: _send,
            ),
          ],
        ),
      ),
    );
  }
}
