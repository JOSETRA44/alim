import 'package:alim_engine/alim_engine.dart';
import 'package:alim_theme_engine/alim_theme_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../common/formatting.dart';
import '../../common/states.dart';
import '../dev_mode/inspector.dart';
// inspectorEnabledProvider vive en inspector.dart.

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
              AsyncData(:final value) when value.isEmpty => const AlimPlaceholder(
                  icon: Icons.waving_hand_outlined,
                  title: 'Aún no hay mensajes',
                  subtitle: 'Escribe abajo para empezar la conversación.',
                ),
              AsyncData(:final value) => _MessageList(
                  chatId: widget.chatId,
                  messages: value,
                  isGroup: chat?.kind == ChatKind.group,
                ),
              AsyncError(:final error) => AlimPlaceholder.error(
                  error,
                  onRetry: () =>
                      ref.invalidate(chatMessagesProvider(widget.chatId)),
                ),
              _ => const Center(child: CircularProgressIndicator()),
            },
          ),
          _InputBar(chatId: widget.chatId),
        ],
      ),
    );
  }
}

class _MessageList extends ConsumerStatefulWidget {
  const _MessageList({
    required this.chatId,
    required this.messages,
    required this.isGroup,
  });

  final String chatId;
  final List<Message> messages;
  final bool isGroup;

  @override
  ConsumerState<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<_MessageList> {
  bool _loadingMore = false;

  Future<void> _maybeLoadMore(ScrollNotification notification) async {
    // Con reverse:true, maxScrollExtent es el extremo del historial antiguo.
    if (_loadingMore ||
        notification.metrics.pixels <
            notification.metrics.maxScrollExtent - 200) {
      return;
    }
    _loadingMore = true;
    try {
      await ref.read(engineProvider).loadMoreMessages(widget.chatId);
    } finally {
      _loadingMore = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = widget.messages;
    // reverse + índice invertido: ancla el scroll abajo (último mensaje)
    // sin recalcular offsets al llegar mensajes nuevos.
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _maybeLoadMore(notification);
        return false;
      },
      child: ListView.builder(
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[messages.length - 1 - index];
          return _MessageBubble(
            key: ValueKey(message.id),
            message: message,
            isGroup: widget.isGroup,
          );
        },
      ),
    );
  }
}

class _MessageBubble extends ConsumerWidget {
  const _MessageBubble({
    super.key,
    required this.message,
    required this.isGroup,
  });

  final Message message;
  final bool isGroup;

  /// Menú contextual de un mensaje propio (hoy solo "Borrar"). Se ofrece con
  /// long-press cuando el inspector está apagado, para no pisar su gesto.
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.delete_outline,
                  color: Theme.of(context).colorScheme.error),
              title: Text('Borrar para todos',
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (action != 'delete' || !context.mounted) return;
    if (ref.read(engineProvider) case final MessageDeleter deleter) {
      try {
        await deleter.deleteMessage(message.chatId, message.id);
      } catch (error) {
        if (!context.mounted) return;
        showEngineError(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final outgoing = message.isOutgoing;
    final bubbleTheme = theme.extension<AlimBubbleTheme>();

    // Lookup memoizado: la clave es finita, la evaluación de expresiones
    // ocurrió como mucho una vez por combinación tras aplicar el tema.
    final style = bubbleTheme?.resolve(BubbleContextKey(
          isOutgoing: outgoing,
          isRead: message.status == MessageStatus.read,
          isGroup: isGroup,
          isFailed: message.status == MessageStatus.failed,
        )) ??
        AlimBubbleStyle(
          background: outgoing
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          radius: 16,
          tailRadius: 4,
          maxWidthFraction: 0.75,
        );

    final statusIcon = Icon(
      switch (message.status) {
        MessageStatus.sending => Icons.schedule,
        MessageStatus.failed => Icons.error_outline,
        MessageStatus.read => Icons.done_all,
        _ => Icons.done,
      },
      size: 12,
      color: message.status == MessageStatus.failed
          ? theme.colorScheme.error
          : theme.colorScheme.onSurfaceVariant,
    );

    final data = BubbleMessageData(
      text: switch (message.content) {
        TextContent(:final text) => text,
        UnsupportedContent(:final description) => '[$description]',
      },
      timeLabel: formatMessageTime(message.sentAt),
      senderName: message.senderName,
      isOutgoing: outgoing,
      isRead: message.status == MessageStatus.read,
      isGroup: isGroup,
      isFailed: message.status == MessageStatus.failed,
      isSending: message.status == MessageStatus.sending,
    );

    final content = bubbleTheme?.layout != null
        ? bubbleTheme!.layout!.build(context, data, statusIcon: statusIcon)
        : _defaultLayout(theme, data, statusIcon);

    final bubble = Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * style.maxWidthFraction,
        ),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(style.radius),
            topRight: Radius.circular(style.radius),
            bottomLeft:
                Radius.circular(outgoing ? style.radius : style.tailRadius),
            bottomRight:
                Radius.circular(outgoing ? style.tailRadius : style.radius),
          ),
        ),
        child: content,
      ),
    );

    // El inspector (si está activo) se queda el long-press. Cuando está
    // apagado y el mensaje es propio y borrable, ese mismo gesto abre el
    // menú de acciones — así no compiten dos GestureDetector por el gesto.
    final inspectorOn = ref.watch(inspectorEnabledProvider);
    final canDelete = outgoing &&
        ref.watch(engineProvider) is MessageDeleter &&
        message.status != MessageStatus.sending;

    Widget interactive = SpecInspectable(
      path: 'components.chat_bubble',
      details: 'fondo ${style.background}, radius ${style.radius}',
      child: bubble,
    );
    if (!inspectorOn && canDelete) {
      interactive = GestureDetector(
        onLongPress: () => _showActions(context, ref),
        child: interactive,
      );
    }

    return RepaintBoundary(child: interactive);
  }

  Widget _defaultLayout(
      ThemeData theme, BubbleMessageData data, Widget statusIcon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (data.isGroup && !data.isOutgoing && data.senderName != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              data.senderName!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Text(data.text, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 2),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              data.timeLabel,
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (data.isOutgoing) ...[
              const SizedBox(width: 4),
              statusIcon,
            ],
          ],
        ),
      ],
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

  /// El envío puede fallar de forma síncrona (motor cerrado, sin sesión).
  /// Antes el Future quedaba sin await y el error se perdía como
  /// "unhandled async error": el usuario veía cómo su mensaje desaparecía
  /// del campo sin explicación.
  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    try {
      await ref.read(engineProvider).sendText(widget.chatId, text);
    } catch (error) {
      if (!mounted) return;
      _controller.text = text; // se devuelve el texto para no perderlo
      showEngineError(context, error);
    }
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
