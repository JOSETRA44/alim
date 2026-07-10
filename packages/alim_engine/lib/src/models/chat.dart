import 'message.dart';

enum ChatKind { direct, group, channel }

/// Conversación tal como aparece en la lista de chats.
class Chat {
  const Chat({
    required this.id,
    required this.title,
    required this.kind,
    this.lastMessage,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isMuted = false,
  });

  final String id;
  final String title;
  final ChatKind kind;
  final Message? lastMessage;
  final int unreadCount;
  final bool isPinned;
  final bool isMuted;

  Chat copyWith({
    Message? lastMessage,
    int? unreadCount,
    bool? isPinned,
    bool? isMuted,
  }) =>
      Chat(
        id: id,
        title: title,
        kind: kind,
        lastMessage: lastMessage ?? this.lastMessage,
        unreadCount: unreadCount ?? this.unreadCount,
        isPinned: isPinned ?? this.isPinned,
        isMuted: isMuted ?? this.isMuted,
      );

  @override
  bool operator ==(Object other) =>
      other is Chat &&
      other.id == id &&
      other.unreadCount == unreadCount &&
      other.lastMessage == lastMessage;

  @override
  int get hashCode => Object.hash(id, unreadCount, lastMessage);
}
