import 'package:alim_engine/alim_engine.dart';

import 'client/td_client.dart';

/// Mapeo de objetos JSON de TDLib a entidades de dominio.
/// Notas de formato de la interfaz JSON:
/// - ids de chat/mensaje/usuario son int53 → llegan como números;
/// - `order` de las posiciones es int64 → llega como STRING.

ChatKind chatKindFrom(TdObject? type) => switch (type?['@type']) {
      'chatTypeBasicGroup' => ChatKind.group,
      'chatTypeSupergroup' =>
        (type?['is_channel'] == true) ? ChatKind.channel : ChatKind.group,
      _ => ChatKind.direct,
    };

MessageContent contentFrom(TdObject? content) => switch (content?['@type']) {
      'messageText' => TextContent(
          ((content?['text'] as TdObject?)?['text'] as String?) ?? '',
        ),
      null => const UnsupportedContent('mensaje'),
      final String other => UnsupportedContent(_describeContent(other)),
      _ => const UnsupportedContent('mensaje'),
    };

String _describeContent(String tdType) => switch (tdType) {
      'messagePhoto' => 'Foto',
      'messageVideo' => 'Vídeo',
      'messageVoiceNote' => 'Nota de voz',
      'messageAudio' => 'Audio',
      'messageDocument' => 'Documento',
      'messageSticker' => 'Sticker',
      'messageAnimation' => 'GIF',
      'messageLocation' => 'Ubicación',
      'messageContact' => 'Contacto',
      'messagePoll' => 'Encuesta',
      'messageCall' => 'Llamada',
      _ => 'No soportado aún',
    };

MessageStatus statusFrom(TdObject message) =>
    switch ((message['sending_state'] as TdObject?)?['@type']) {
      'messageSendingStatePending' => MessageStatus.sending,
      'messageSendingStateFailed' => MessageStatus.failed,
      _ => MessageStatus.sent,
    };

/// [senderNameOf] resuelve el nombre a mostrar (cache de usuarios/chats).
Message messageFrom(
  TdObject message, {
  required String? Function(TdObject? senderId) senderNameOf,
}) {
  final senderId = message['sender_id'] as TdObject?;
  return Message(
    id: '${message['id']}',
    chatId: '${message['chat_id']}',
    senderId: switch (senderId?['@type']) {
      'messageSenderUser' => '${senderId?['user_id']}',
      'messageSenderChat' => '${senderId?['chat_id']}',
      _ => '',
    },
    senderName: senderNameOf(senderId),
    content: contentFrom(message['content'] as TdObject?),
    sentAt: DateTime.fromMillisecondsSinceEpoch(
        ((message['date'] as num?)?.toInt() ?? 0) * 1000),
    isOutgoing: message['is_outgoing'] == true,
    status: statusFrom(message),
  );
}

/// Nombre visible de un usuario TDLib.
String displayNameOf(TdObject user) {
  final first = user['first_name'] as String? ?? '';
  final last = user['last_name'] as String? ?? '';
  final name = '$first $last'.trim();
  return name.isEmpty ? 'Usuario ${user['id']}' : name;
}

String? usernameOf(TdObject user) {
  final usernames = user['usernames'] as TdObject?;
  final active = usernames?['active_usernames'];
  if (active is List && active.isNotEmpty) return active.first as String?;
  return null;
}

/// Posición de un chat en la lista principal: (order, isPinned).
/// order == 0 significa "fuera de la lista".
(BigInt, bool) mainListPositionOf(List<Object?>? positions) {
  if (positions == null) return (BigInt.zero, false);
  for (final position in positions.whereType<TdObject>()) {
    if ((position['list'] as TdObject?)?['@type'] == 'chatListMain') {
      final rawOrder = position['order'];
      final order = switch (rawOrder) {
        String s => BigInt.tryParse(s) ?? BigInt.zero,
        num n => BigInt.from(n),
        _ => BigInt.zero,
      };
      return (order, position['is_pinned'] == true);
    }
  }
  return (BigInt.zero, false);
}
