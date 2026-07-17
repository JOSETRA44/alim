enum RemoteConversationKind { direct, group }

/// Conversación tal como vive en Postgres (sin el último mensaje: eso lo
/// resuelve el estado local a partir de los mensajes ya sincronizados).
class RemoteConversation {
  const RemoteConversation({
    required this.id,
    required this.kind,
    required this.title,
    required this.updatedAt,
    required this.memberNames,
  });

  final String id;
  final RemoteConversationKind kind;
  final String? title;
  final DateTime updatedAt;

  /// userId -> displayName de todos los miembros (incluye al propio usuario).
  final Map<String, String> memberNames;
}

class RemoteMessage {
  const RemoteMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
}

/// Evento de Realtime. El nombre del remitente y el resto de metadatos de
/// una conversación NO viajan en el payload de Postgres Changes: se
/// resuelven contra la caché local ([RemoteMessageUpserted]) o con un
/// refetch puntual ([RemoteConversationChanged]).
sealed class RemoteEvent {
  const RemoteEvent();
}

class RemoteMessageUpserted extends RemoteEvent {
  const RemoteMessageUpserted(this.message);

  final RemoteMessage message;
}

class RemoteConversationChanged extends RemoteEvent {
  const RemoteConversationChanged(this.conversationId);

  final String conversationId;
}

class RemoteMessageDeleted extends RemoteEvent {
  const RemoteMessageDeleted({required this.id, required this.conversationId});

  final String id;
  final String conversationId;
}
