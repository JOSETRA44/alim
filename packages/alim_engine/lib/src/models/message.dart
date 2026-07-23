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

  @override
  bool operator ==(Object other) =>
      other is TextContent && other.text == text;

  @override
  int get hashCode => text.hashCode;
}

/// Contenido aún no soportado por la UI (stickers, polls, etc.).
/// Render fail-safe: se muestra [description] en lugar de romper.
class UnsupportedContent extends MessageContent {
  const UnsupportedContent(this.description);

  final String description;

  @override
  String get preview => description;

  @override
  bool operator ==(Object other) =>
      other is UnsupportedContent && other.description == description;

  @override
  int get hashCode => description.hashCode;
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
    this.isEdited = false,
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

  /// El mensaje fue editado tras enviarse (la UI muestra "editado").
  final bool isEdited;

  Message copyWith({
    MessageStatus? status,
    MessageContent? content,
    bool? isEdited,
  }) =>
      Message(
        id: id,
        chatId: chatId,
        senderId: senderId,
        senderName: senderName,
        content: content ?? this.content,
        sentAt: sentAt,
        isOutgoing: isOutgoing,
        status: status ?? this.status,
        isEdited: isEdited ?? this.isEdited,
      );

  @override
  bool operator ==(Object other) =>
      other is Message &&
      other.id == id &&
      other.status == status &&
      other.content == content &&
      other.isEdited == isEdited;

  @override
  int get hashCode => Object.hash(id, status, content, isEdited);
}
