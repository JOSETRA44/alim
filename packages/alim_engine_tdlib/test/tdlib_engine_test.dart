import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alim_engine/alim_engine.dart';
import 'package:alim_engine_tdlib/alim_engine_tdlib.dart';
import 'package:flutter_test/flutter_test.dart';

/// Transporte fake: guarda las peticiones y permite inyectar updates,
/// ejercitando el motor completo sin binarios nativos.
class FakeTdClient implements TdClient {
  final _updates = StreamController<TdObject>.broadcast(sync: true);
  final List<TdObject> requests = [];
  final Map<String, TdObject Function(TdObject request)> handlers = {};
  bool closed = false;

  @override
  Stream<TdObject> get updates => _updates.stream;

  void emit(TdObject update) => _updates.add(update);

  void emitAuthState(TdObject state) => emit({
        '@type': 'updateAuthorizationState',
        'authorization_state': state,
      });

  @override
  Future<void> start() async {}

  @override
  Future<TdObject> send(TdObject request) async {
    requests.add(request);
    final handler = handlers[request['@type']];
    if (handler == null) return {'@type': 'ok'};
    final response = handler(request);
    if (response['@type'] == 'error') {
      throw TdRequestException(
        response['message'] as String? ?? 'error',
        tdCode: response['code'] as int?,
      );
    }
    return response;
  }

  @override
  void post(TdObject request) {
    requests.add(request);
  }

  @override
  Future<void> close() async {
    closed = true;
    await _updates.close();
  }

  TdObject? lastOfType(String type) {
    for (final request in requests.reversed) {
      if (request['@type'] == type) return request;
    }
    return null;
  }
}

void main() {
  late FakeTdClient client;
  late TdlibEngine engine;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('alim_tdlib_test');
    client = FakeTdClient();
    engine = TdlibEngine(
      client: client,
      config: TdlibConfig(
        apiId: 1,
        apiHash: 'hash',
        databaseDirectory: '${tempDir.path}${Platform.pathSeparator}db',
        filesDirectory: '${tempDir.path}${Platform.pathSeparator}files',
      ),
    );
    await engine.start();
  });

  tearDown(() async {
    await engine.dispose();
    await tempDir.delete(recursive: true);
  });

  TdObject userJuan() => {
        '@type': 'user',
        'id': 7,
        'first_name': 'Juan',
        'last_name': 'Pérez',
      };

  TdObject textMessage({
    required int id,
    required int chatId,
    required String text,
    bool outgoing = false,
    TdObject? sendingState,
  }) =>
      {
        '@type': 'message',
        'id': id,
        'chat_id': chatId,
        'sender_id': {'@type': 'messageSenderUser', 'user_id': 7},
        'is_outgoing': outgoing,
        'date': 1700000000,
        if (sendingState != null) 'sending_state': sendingState,
        'content': {
          '@type': 'messageText',
          'text': {'@type': 'formattedText', 'text': text},
        },
      };

  group('migración a binlog cifrado', () {
    /// Arranca un motor nuevo sobre [dbDir] sin usar el `engine` del setUp.
    Future<TdlibEngine> startOn(String dbDir) async {
      final fresh = TdlibEngine(
        client: FakeTdClient(),
        config: TdlibConfig(
          apiId: 1,
          apiHash: 'hash',
          databaseDirectory: dbDir,
          filesDirectory: '${tempDir.path}${Platform.pathSeparator}files2',
        ),
      );
      await fresh.start();
      return fresh;
    }

    test('un binlog heredado SIN cifrar se descarta al activar el cifrado',
        () async {
      final dbDir = Directory('${tempDir.path}${Platform.pathSeparator}legacy')
        ..createSync(recursive: true);
      // Base preexistente de la época sin cifrado: no hay marcador.
      final legacy = File('${dbDir.path}${Platform.pathSeparator}td.binlog')
        ..writeAsStringSync('datos en claro');

      final fresh = await startOn(dbDir.path);
      addTearDown(fresh.dispose);

      expect(legacy.existsSync(), isFalse,
          reason: 'TDLib no puede abrir con clave una base creada sin ella');
      expect(
          File('${dbDir.path}${Platform.pathSeparator}.alim_encrypted')
              .existsSync(),
          isTrue);
    });

    test('un binlog ya cifrado se conserva entre arranques', () async {
      final dbDir = Directory('${tempDir.path}${Platform.pathSeparator}enc')
        ..createSync(recursive: true);

      final first = await startOn(dbDir.path);
      await first.dispose();

      // Segundo arranque: ya existe el marcador, así que nada se borra.
      final binlog = File('${dbDir.path}${Platform.pathSeparator}td.binlog')
        ..writeAsStringSync('datos ya cifrados');

      final second = await startOn(dbDir.path);
      addTearDown(second.dispose);

      expect(binlog.existsSync(), isTrue,
          reason: 'un arranque normal no puede borrar la sesión del usuario');
    });
  });

  group('inicialización y auth', () {
    test('waitTdlibParameters envía setTdlibParameters con rutas explícitas',
        () {
      client.emitAuthState({'@type': 'authorizationStateWaitTdlibParameters'});

      final params = client.lastOfType('setTdlibParameters')!;
      expect(params['api_id'], 1);
      expect(params['database_directory'], contains('db'));
      expect(params['files_directory'], contains('files'));
      // Las rutas se verificaron creándolas de verdad.
      expect(Directory(params['database_directory'] as String).existsSync(),
          isTrue);
    });

    test('el binlog se cifra: la clave viaja en setTdlibParameters', () {
      client.emitAuthState({'@type': 'authorizationStateWaitTdlibParameters'});

      final params = client.lastOfType('setTdlibParameters')!;
      final key = params['database_encryption_key'] as String;
      expect(key, isNotEmpty,
          reason: 'una clave vacía deja el historial en claro en disco');
      // TDLib espera los `bytes` en base64; el InMemoryKeyStore da 32 bytes.
      expect(base64Decode(key).length, 32);
    });

    test('flujo completo: phone -> code -> password -> ready', () async {
      client.emitAuthState({'@type': 'authorizationStateWaitPhoneNumber'});
      expect(engine.currentAuthState, isA<AuthWaitingPhoneNumber>());

      await engine.submitPhoneNumber('+34600123123');
      expect(client.lastOfType('setAuthenticationPhoneNumber')?['phone_number'],
          '+34600123123');

      client.emitAuthState({
        '@type': 'authorizationStateWaitCode',
        'code_info': {'phone_number': '+34600123123'},
      });
      final waiting = engine.currentAuthState;
      expect((waiting as AuthWaitingCode).phoneNumber, '+34600123123');

      client.emitAuthState({
        '@type': 'authorizationStateWaitPassword',
        'password_hint': 'pista',
      });
      expect((engine.currentAuthState as AuthWaitingPassword).hint, 'pista');

      client.handlers['getMe'] = (_) => userJuan();
      client.emitAuthState({'@type': 'authorizationStateReady'});
      await Future<void>.delayed(Duration.zero);

      final ready = engine.currentAuthState;
      expect(ready, isA<AuthReady>());
      expect((ready as AuthReady).user.displayName, 'Juan Pérez');
      // Al autenticar se pide la lista de chats.
      expect(client.lastOfType('loadChats'), isNotNull);
    });

    test('un error de TDLib se refleja en el estado con mensaje', () async {
      client.emitAuthState({'@type': 'authorizationStateWaitPhoneNumber'});
      client.handlers['setAuthenticationPhoneNumber'] = (_) =>
          {'@type': 'error', 'code': 400, 'message': 'PHONE_NUMBER_INVALID'};

      await engine.submitPhoneNumber('abc');
      final state = engine.currentAuthState;
      expect((state as AuthWaitingPhoneNumber).error, 'PHONE_NUMBER_INVALID');
    });
  });

  group('chats', () {
    TdObject chatJson({
      required int id,
      required String title,
      String order = '100',
      bool pinned = false,
      int unread = 0,
    }) =>
        {
          '@type': 'chat',
          'id': id,
          'title': title,
          'type': {'@type': 'chatTypePrivate'},
          'unread_count': unread,
          'positions': [
            {
              '@type': 'chatPosition',
              'list': {'@type': 'chatListMain'},
              'order': order,
              'is_pinned': pinned,
            }
          ],
        };

    test('updateNewChat construye la lista ordenada por order desc', () async {
      client.emit({'@type': 'updateNewChat', 'chat': chatJson(id: 1, title: 'A', order: '50')});
      client.emit({'@type': 'updateNewChat', 'chat': chatJson(id: 2, title: 'B', order: '99')});

      final chats = await engine.chats.first;
      expect(chats.map((c) => c.title), ['B', 'A']);
    });

    test('order 0 saca el chat de la lista', () async {
      client.emit({'@type': 'updateNewChat', 'chat': chatJson(id: 1, title: 'A')});
      client.emit({
        '@type': 'updateChatPosition',
        'chat_id': 1,
        'position': {
          '@type': 'chatPosition',
          'list': {'@type': 'chatListMain'},
          'order': '0',
          'is_pinned': false,
        },
      });

      expect(await engine.chats.first, isEmpty);
    });

    test('updateChatReadInbox actualiza el contador', () async {
      client.emit({'@type': 'updateNewChat', 'chat': chatJson(id: 1, title: 'A', unread: 5)});
      client.emit({
        '@type': 'updateChatReadInbox',
        'chat_id': 1,
        'last_read_inbox_message_id': 10,
        'unread_count': 0,
      });

      final chats = await engine.chats.first;
      expect(chats.single.unreadCount, 0);
    });
  });

  group('mensajes', () {
    test('watchMessages abre el chat, carga historial y recibe updates',
        () async {
      client.emit({'@type': 'updateUser', 'user': userJuan()});
      client.handlers['getChatHistory'] = (_) => {
            '@type': 'messages',
            'messages': [
              textMessage(id: 2, chatId: 9, text: 'segundo'),
              textMessage(id: 1, chatId: 9, text: 'primero'),
            ],
          };

      final stream = engine.watchMessages('9');
      await Future<void>.delayed(Duration.zero);
      expect(client.lastOfType('openChat')?['chat_id'], 9);

      var messages = await stream.first;
      expect(messages.map((m) => m.content.preview), ['primero', 'segundo']);
      expect(messages.first.senderName, 'Juan Pérez');

      client.emit({
        '@type': 'updateNewMessage',
        'message': textMessage(id: 3, chatId: 9, text: 'nuevo'),
      });
      messages = await stream.first;
      expect(messages.last.content.preview, 'nuevo');
    });

    test('updateMessageSendSucceeded sustituye el mensaje temporal', () async {
      client.handlers['getChatHistory'] = (_) =>
          {'@type': 'messages', 'messages': <Object?>[]};
      final stream = engine.watchMessages('9');
      await Future<void>.delayed(Duration.zero);

      client.emit({
        '@type': 'updateNewMessage',
        'message': textMessage(
          id: 100,
          chatId: 9,
          text: 'hola',
          outgoing: true,
          sendingState: {'@type': 'messageSendingStatePending'},
        ),
      });
      var messages = await stream.first;
      expect(messages.single.status, MessageStatus.sending);

      client.emit({
        '@type': 'updateMessageSendSucceeded',
        'old_message_id': 100,
        'message': textMessage(id: 555, chatId: 9, text: 'hola', outgoing: true),
      });
      messages = await stream.first;
      expect(messages.single.id, '555');
      expect(messages.single.status, MessageStatus.sent);
    });

    test('sendText construye inputMessageText', () async {
      await engine.sendText('9', ' hola mundo ');
      final request = client.lastOfType('sendMessage')!;
      expect(request['chat_id'], 9);
      final content = request['input_message_content'] as TdObject;
      expect((content['text'] as TdObject)['text'], 'hola mundo');
    });

    test('deleteMessage borra para todos (revoke: true)', () async {
      await engine.deleteMessage('9', '42');
      final request = client.lastOfType('deleteMessages')!;
      expect(request['chat_id'], 9);
      expect(request['message_ids'], [42]);
      expect(request['revoke'], isTrue);
    });

    test('regresión: al dejar de observar el chat se envía closeChat',
        () async {
      // openChat/closeChat son un par en TDLib: sin el cierre, cada chat
      // visitado quedaba abierto para siempre consumiendo red y memoria.
      final sub = engine.watchMessages('9').listen((_) {});
      expect(client.lastOfType('openChat')!['chat_id'], 9);
      expect(client.lastOfType('closeChat'), isNull);

      await sub.cancel();
      // El cierre espera un margen por si la UI se resuscribe (rebuild).
      await Future<void>.delayed(const Duration(milliseconds: 3100));

      expect(client.lastOfType('closeChat')?['chat_id'], 9,
          reason: 'sin oyentes, el chat debe cerrarse');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('regresión: una resuscripción rápida NO cierra el chat', () async {
      final first = engine.watchMessages('9').listen((_) {});
      await first.cancel();
      // Rebuild inmediato de la UI: vuelve a suscribirse enseguida.
      final second = engine.watchMessages('9').listen((_) {});
      addTearDown(second.cancel);

      await Future<void>.delayed(const Duration(milliseconds: 3100));

      expect(client.lastOfType('closeChat'), isNull,
          reason: 'hay un oyente activo: cerrar cortaría la sincronización');
    }, timeout: const Timeout(Duration(seconds: 15)));

    test('editMessage envía editMessageText con el texto recortado', () async {
      await engine.editMessage('9', '42', '  texto nuevo  ');
      final request = client.lastOfType('editMessageText')!;
      expect(request['chat_id'], 9);
      expect(request['message_id'], 42);
      final content = request['input_message_content'] as TdObject;
      expect((content['text'] as TdObject)['text'], 'texto nuevo');
    });

    test('updateMessageContent marca el mensaje como editado en la ventana',
        () async {
      // Abre la ventana y recibe un mensaje.
      final sub = engine.watchMessages('9').listen((_) {});
      addTearDown(sub.cancel);
      client.emit({
        '@type': 'updateNewMessage',
        'message': textMessage(id: 5, chatId: 9, text: 'antes'),
      });
      // Edición entrante de ese mensaje.
      client.emit({
        '@type': 'updateMessageContent',
        'chat_id': 9,
        'message_id': 5,
        'new_content': {
          '@type': 'messageText',
          'text': {'@type': 'formattedText', 'text': 'después'},
        },
      });

      final messages = await engine.watchMessages('9').first;
      final edited = messages.firstWhere((m) => m.id == '5');
      expect((edited.content as TextContent).text, 'después');
      expect(edited.isEdited, isTrue);
    });
  });
}
