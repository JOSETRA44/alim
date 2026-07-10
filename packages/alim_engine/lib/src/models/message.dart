/// Estado de entrega de un mensaje saliente.
enum MessageStatus { sending, sent, delivered, read, failed }

/// Contenido de un mensaje. Sellado para que la UI haga switch exhaustivo;
/// los tipos de media se añadirán como nuevas variantes sin romper llamadas.
sealed class MessageContent {
  const MessageContent();

  /// Texto de vista previa para listas de chats y notificaciones.
  String get preview;
}

class TextContent extends MessageContent {
  const TextContent(this.text);

  final String text;

  @override
  String get preview => text;
}

/// Contenido aún no soportado por la UI (stickers, polls, etc.).
/// Render fail-safe: se muestra [description] en lugar de romper.
class UnsupportedContent extends MessageContent {
  const UnsupportedContent(this.description);

  final String description;

  @override
  String get preview => description;
}

class Message {
  const Message({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    required this.isOutgoing,
    this.senderName,
    this.status = MessageStatus.sent,
  });

  final String id;
  final String chatId;
  final String senderId;

  /// Nombre a mostrar en grupos; null en chats directos.
  final String? senderName;
  final MessageContent content;
  final DateTime sentAt;
  final bool isOutgoing;
  final MessageStatus status;

  Message copyWith({MessageStatus? status}) => Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content,
        sentAt: sentAt,
        isOutgoing: isOutgoing,
        status: status ?? this.status,
      );

  @override
  bool operator ==(Object other) =>
      other is Message && other.id == id && other.status == status;

  @override
  int get hashCode => Object.hash(id, status);
}
