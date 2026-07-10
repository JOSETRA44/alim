import 'package:alim_engine/alim_engine.dart';

/// Personas y conversaciones semilla del motor mock. Determinista para que
/// los tests y las previews del Dev Mode sean reproducibles.
class MockSeed {
  static const self = AlimUser(id: 'me', displayName: 'Tú', username: 'yo');

  static const ada = AlimUser(
    id: 'u-ada',
    displayName: 'Ada Lovelace',
    username: 'ada',
  );
  static const linus = AlimUser(
    id: 'u-linus',
    displayName: 'Linus',
    username: 'linus',
  );
  static const grace = AlimUser(
    id: 'u-grace',
    displayName: 'Grace Hopper',
    username: 'grace',
  );

  static const replies = [
    'Interesante, cuéntame más.',
    '¿Probaste cambiar el tema desde el Modo Desarrollador?',
    'Eso suena a que necesita más café ☕',
    'De acuerdo. ¿Seguimos mañana?',
    'jajaja',
    'Mira el spec ALIM, ahí está la respuesta.',
  ];

  /// Historial inicial por chat, ordenado de más antiguo a más reciente.
  static Map<String, List<Message>> messages(DateTime now) {
    Message m(
      String chatId,
      int index,
      AlimUser sender,
      String text, {
      int minutesAgo = 0,
    }) =>
        Message(
          id: '$chatId-seed-$index',
          chatId: chatId,
          senderId: sender.id,
          senderName: sender.displayName,
          content: TextContent(text),
          sentAt: now.subtract(Duration(minutes: minutesAgo)),
          isOutgoing: sender.id == self.id,
          status: sender.id == self.id ? MessageStatus.read : MessageStatus.sent,
        );

    return {
      'c-ada': [
        m('c-ada', 0, ada, 'Vi el prototipo de ALIM, me encanta lo minimalista.',
            minutesAgo: 95),
        m('c-ada', 1, self, 'Gracias — todo el estilo sale de tokens JSON.',
            minutesAgo: 90),
        m('c-ada', 2, ada, '¿O sea que puedo rediseñar mi burbuja en runtime?',
            minutesAgo: 12),
      ],
      'c-linus': [
        m('c-linus', 0, linus, 'Talk is cheap. Show me the code.',
            minutesAgo: 300),
        m('c-linus', 1, self, 'Está en packages/, arquitectura limpia 😎',
            minutesAgo: 280),
      ],
      'c-equipo': [
        m('c-equipo', 0, grace, 'Recuerden: un barco en puerto está a salvo…',
            minutesAgo: 1500),
        m('c-equipo', 1, ada, '…pero no es para eso que se construyen los barcos.',
            minutesAgo: 1490),
        m('c-equipo', 2, self, 'Zarpamos con el Hito 1 🚀', minutesAgo: 60),
        m('c-equipo', 3, grace, '¿Ya se puede probar el modo desarrollador?',
            minutesAgo: 5),
      ],
    };
  }

  static List<Chat> chats(Map<String, List<Message>> history) => [
        Chat(
          id: 'c-equipo',
          title: 'Equipo ALIM',
          kind: ChatKind.group,
          lastMessage: history['c-equipo']!.last,
          unreadCount: 2,
          isPinned: true,
        ),
        Chat(
          id: 'c-ada',
          title: 'Ada Lovelace',
          kind: ChatKind.direct,
          lastMessage: history['c-ada']!.last,
          unreadCount: 1,
        ),
        Chat(
          id: 'c-linus',
          title: 'Linus',
          kind: ChatKind.direct,
          lastMessage: history['c-linus']!.last,
        ),
      ];
}
