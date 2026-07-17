import 'package:alim_engine/alim_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../common/avatar.dart';
import '../../common/formatting.dart';
import '../../common/states.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  Future<void> _startChat(BuildContext context, ConversationStarter starter) async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo chat'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
              hintText: 'Nombre de usuario', prefixText: '@'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Iniciar'),
          ),
        ],
      ),
    );
    if (username == null || username.isEmpty || !context.mounted) return;
    try {
      final chatId = await starter.startDirectChat(username);
      if (!context.mounted) return;
      context.go('/chat/$chatId');
    } catch (error) {
      if (!context.mounted) return;
      showEngineError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);
    final engine = ref.watch(engineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ALIM'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Ajustes',
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: switch (chats) {
        AsyncData(:final value) when value.isEmpty => AlimPlaceholder(
            icon: Icons.forum_outlined,
            title: 'Sin conversaciones todavía',
            subtitle: engine is ConversationStarter
                ? 'Pulsa + para buscar a alguien por su nombre de usuario.'
                : 'Tus chats aparecerán aquí en cuanto se sincronicen.',
          ),
        AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(indent: 88),
            itemBuilder: (context, index) => _ChatTile(chat: value[index]),
          ),
        AsyncError(:final error) => AlimPlaceholder.error(
            error,
            onRetry: () => ref.invalidate(chatsProvider),
          ),
        _ => const Center(child: CircularProgressIndicator()),
      },
      floatingActionButton: switch (engine) {
        ConversationStarter starter => FloatingActionButton(
            tooltip: 'Nuevo chat',
            onPressed: () => _startChat(context, starter),
            child: const Icon(Icons.add),
          ),
        _ => null,
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({required this.chat});

  final Chat chat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = chat.lastMessage;

    return ListTile(
      leading: AlimAvatar(id: chat.id, title: chat.title),
      title: Row(
        children: [
          Expanded(
            child: Text(
              chat.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall,
            ),
          ),
          if (chat.isPinned)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.push_pin_outlined,
                  size: 16, color: theme.colorScheme.onSurfaceVariant),
            ),
          if (last != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                formatMessageTime(last.sentAt),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
      subtitle: Row(
        children: [
          Expanded(
            child: Text(
              last == null
                  ? ''
                  : last.senderName == null || chat.kind == ChatKind.direct
                      ? last.content.preview
                      : '${last.senderName}: ${last.content.preview}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${chat.unreadCount}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: theme.colorScheme.onPrimary),
              ),
            ),
        ],
      ),
      onTap: () => context.go('/chat/${chat.id}'),
    );
  }
}
