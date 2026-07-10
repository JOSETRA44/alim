import 'package:alim_engine/alim_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../common/avatar.dart';
import '../../common/formatting.dart';

class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatsProvider);

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
        AsyncData(:final value) when value.isEmpty =>
          const _EmptyState(),
        AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(indent: 88),
            itemBuilder: (context, index) => _ChatTile(chat: value[index]),
          ),
        AsyncError(:final error) =>
          Center(child: Text('Error: $error')),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'Sin conversaciones todavía',
        style: theme.textTheme.bodyLarge
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
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
