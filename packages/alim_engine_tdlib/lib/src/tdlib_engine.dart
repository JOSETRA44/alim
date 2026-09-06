import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:alim_core/alim_core.dart';
import 'package:alim_engine/alim_engine.dart';
import 'package:alim_keystore/alim_keystore.dart';
import 'package:path_provider/path_provider.dart';

import 'client/td_client.dart';
import 'client/td_ffi_client.dart';
import 'config.dart';
import 'mapping.dart';

/// Motor de mensajería real sobre TDLib (Telegram).
class TdlibEngine implements MessagingEngine, MessageDeleter, MessageEditor {
  TdlibEngine({
    required TdClient client,
    required this.config,
    SecretKeyStore? keyStore,
  })  : _client = client,
        _keyStore = keyStore ?? InMemoryKeyStore();

  /// Fábrica de producción: transporte FFI real y clave custodiada por el
  /// almacén seguro del SO.
  factory TdlibEngine.production(TdlibConfig config) => TdlibEngine(
        client: TdFfiClient(),
        config: config,
        keyStore: SecureKeyStore(),
      );

  static final _log = AlimLogger('TdlibEngine');

  /// Identifica la clave de este motor dentro del almacén seguro.
  static const _keyPurpose = 'tdlib';

  /// Marca de que el binlog de este directorio ya nació cifrado. Su ausencia
  /// junto a un binlog existente significa "base heredada en claro".
  static const _encryptedMarker = '.alim_encrypted';

  final TdClient _client;
  final TdlibConfig config;
  final SecretKeyStore _keyStore;
  String _databaseEncryptionKey = '';

  late final StateStream<AuthState> _auth =
      StateStream<AuthState>(const AuthInitializing());
  late final StateStream<List<Chat>> _chats = StateStream<List<Chat>>(const []);

  final Map<int, _ChatEntry> _chatStore = {};
  final Map<int, _MessageWindow> _windows = {};
  final Map<int, String> _userNames = {};

  /// Cierres de chat pendientes; se cancelan en [dispose] para no dejar
  /// trabajo en vuelo contra un cliente ya cerrado.
  final Set<Timer> _releaseTimers = {};

  StreamSubscription<TdObject>? _updatesSub;
  late String _databaseDirectory;
  late String _filesDirectory;
  String _lastPhoneNumber = '';
  bool _started = false;
  bool _disposed = false;

  @override
  String get id => 'tdlib';

  @override
  String get name => 'Telegram (TDLib)';

  @override
  String get identifierLabel => 'Número de teléfono';

  @override
  String get identifierHint => '+34 600 000 000';

  @override
  Stream<AuthState> get authStates => _auth.stream;

  @override
  AuthState get currentAuthState => _auth.value;

  @override
  Stream<List<Chat>> get chats => _chats.stream;

  // --- Ciclo de vida --------------------------------------------------------

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;

    await _resolveDirectories();
    await _resolveEncryptionKey();
    _updatesSub = _client.updates.listen(_onUpdate);
    await _client.start();
    _handleStaleClient();
    _log.info('arrancado (db: $_databaseDirectory, cifrado: activo)');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _releaseTimers) {
      timer.cancel();
    }
    _releaseTimers.clear();
    await _updatesSub?.cancel();
    await _client.close();
    _auth.value = const AuthClosed();
    _auth.close();
    _chats.close();
    for (final window in _windows.values) {
      window.stream.close();
    }
    _log.info('cerrado');
  }

  @override
  Future<void> setBackgrounded(bool backgrounded) async {
    if (_disposed) return;
    _client.post({
      '@type': 'setOption',
      'name': 'online',
      'value': {'@type': 'optionValueBoolean', 'value': !backgrounded},
    });
  }

  /// Mandato del plan: rutas explícitas, creadas y verificadas antes de
  /// inicializar TDLib. Nada de defaults del sandbox.
  Future<void> _resolveDirectories() async {
    var db = config.databaseDirectory;
    var files = config.filesDirectory;
    if (db == null || files == null) {
      final support = await getApplicationSupportDirectory();
      final sep = Platform.pathSeparator;
      db ??= '${support.path}${sep}tdlib${sep}db';
      files ??= '${support.path}${sep}tdlib${sep}files';
    }
    for (final path in [db, files]) {
      final dir = Directory(path);
      await dir.create(recursive: true);
      final probe = File('$path${Platform.pathSeparator}.alim_probe');
      await probe.writeAsString('ok');
      await probe.delete();
    }
    _databaseDirectory = db;
    _filesDirectory = files;
  }

  /// Recupera (o genera) la clave del binlog y la deja lista para
  /// `setTdlibParameters`. TDLib espera el campo `bytes` en base64.
  ///
  /// Migración: un binlog creado SIN clave no se puede abrir CON clave —
  /// TDLib devolvería "wrong database encryption key" y el motor quedaría
  /// muerto. Al no existir el marcador junto a una base preexistente se
  /// asume base heredada en claro y se descarta: es un borrado local, no
  /// una pérdida de datos (el historial vive en los servidores de Telegram
  /// y se vuelve a bajar tras iniciar sesión de nuevo).
  Future<void> _resolveEncryptionKey() async {
    final key = await _keyStore.keyFor(_keyPurpose);
    _databaseEncryptionKey = base64Encode(key);

    final dir = Directory(_databaseDirectory);
    final marker = File('$_databaseDirectory${Platform.pathSeparator}$_encryptedMarker');
    if (marker.existsSync()) return;

    final hasLegacyData = dir
        .listSync()
        .whereType<File>()
        .any((file) => !file.path.endsWith(_encryptedMarker));
    if (hasLegacyData) {
      _log.warning(
          'binlog heredado sin cifrar: se descarta y habrá que iniciar sesión de nuevo');
      for (final entry in dir.listSync()) {
        entry.deleteSync(recursive: true);
      }
    }
    marker.writeAsStringSync('v1');
  }

  /// Detección de hot-restart: si quedó un cliente nativo huérfano de una
  /// sesión Dart anterior en el MISMO proceso, se le envía `close`.
  /// El marcador vive junto a la BD; enviar a un id inexistente es inocuo.
  void _handleStaleClient() {
    final client = _client;
    if (client is! TdFfiClient) return;
    try {
      final marker = File(
          '$_databaseDirectory${Platform.pathSeparator}.alim_client_id');
      if (marker.existsSync()) {
        final stale = int.tryParse(marker.readAsStringSync().trim());
        if (stale != null && stale != client.clientId) {
          client.closeStaleClient(stale);
        }
      }
      marker.writeAsStringSync('${client.clientId}');
    } catch (e) {
      _log.warning('marcador de cliente: $e');
    }
  }

  // --- Autenticación --------------------------------------------------------

  @override
  Future<void> submitPhoneNumber(String phoneNumber) async {
    _lastPhoneNumber = phoneNumber.trim();
    try {
      await _client.send({
        '@type': 'setAuthenticationPhoneNumber',
        'phone_number': _lastPhoneNumber,
      });
    } on TdRequestException catch (e) {
      _auth.value = AuthWaitingPhoneNumber(error: e.message);
    }
  }

  @override
  Future<void> submitCode(String code) async {
    try {
      await _client.send({
        '@type': 'checkAuthenticationCode',
        'code': code.trim(),
      });
    } on TdRequestException catch (e) {
      _auth.value =
          AuthWaitingCode(phoneNumber: _lastPhoneNumber, error: e.message);
    }
  }

  @override
  Future<void> submitPassword(String password) async {
    try {
      await _client.send({
        '@type': 'checkAuthenticationPassword',
        'password': password,
      });
    } on TdRequestException catch (e) {
      _auth.value = AuthWaitingPassword(error: e.message);
    }
  }

  @override
  Future<void> logOut() async {
    _client.post({'@type': 'logOut'});
    // TDLib borra su binlog al cerrar sesión; se olvida además la clave para
    // que ningún resto en disco quede descifrable.
    await _keyStore.forget(_keyPurpose);
  }

  void _onAuthorizationState(TdObject state) {
    switch (state['@type']) {
      case 'authorizationStateWaitTdlibParameters':
        _client.post({
          '@type': 'setTdlibParameters',
          'use_test_dc': config.useTestDc,
          'database_directory': _databaseDirectory,
          'files_directory': _filesDirectory,
          'database_encryption_key': _databaseEncryptionKey,
          'use_file_database': true,
          'use_chat_info_database': true,
          'use_message_database': true,
          'use_secret_chats': false,
          'api_id': config.apiId,
          'api_hash': config.apiHash,
          'system_language_code': config.systemLanguageCode,
          'device_model': config.deviceModel,
          'system_version': '',
          'application_version': config.applicationVersion,
        });
      case 'authorizationStateWaitPhoneNumber':
        _auth.value = const AuthWaitingPhoneNumber();
      case 'authorizationStateWaitCode':
        final info = state['code_info'] as TdObject?;
        _auth.value = AuthWaitingCode(
          phoneNumber:
              info?['phone_number'] as String? ?? _lastPhoneNumber,
        );
      case 'authorizationStateWaitPassword':
        _auth.value = AuthWaitingPassword(
          hint: state['password_hint'] as String?,
        );
      case 'authorizationStateReady':
        _onReady();
      case 'authorizationStateLoggingOut':
        _auth.value = const AuthLoggedOut();
      case 'authorizationStateClosed':
        if (!_disposed) _auth.value = const AuthClosed();
      // waitEmailAddress / waitEmailCode / waitRegistration /
      // waitOtherDeviceConfirmation: fuera del alcance del Hito 3.
    }
  }

  Future<void> _onReady() async {
    try {
      final me = await _client.send({'@type': 'getMe'});
      final selfId = (me['id'] as num).toInt();
      _userNames[selfId] = displayNameOf(me);
      _auth.value = AuthReady(
        user: AlimUser(
          id: '$selfId',
          displayName: displayNameOf(me),
          username: usernameOf(me),
        ),
      );
      _loadChatList();
    } on EngineException catch (e) {
      _log.error('getMe falló', e);
    }
  }

  Future<void> _loadChatList() async {
    try {
      await _client.send({
        '@type': 'loadChats',
        'chat_list': {'@type': 'chatListMain'},
        'limit': 100,
      });
    } on TdRequestException catch (e) {
      // 404 = no quedan más chats por cargar; cualquier otra cosa se loguea.
      if (e.tdCode != 404) _log.error('loadChats falló', e);
    }
  }

  // --- Updates --------------------------------------------------------------

  void _onUpdate(TdObject update) {
    switch (update['@type']) {
      case 'updateAuthorizationState':
        final state = update['authorization_state'];
        if (state is TdObject) _onAuthorizationState(state);
      case 'updateUser':
        final user = update['user'];
        if (user is TdObject) {
          _userNames[(user['id'] as num).toInt()] = displayNameOf(user);
        }
      case 'updateNewChat':
        final chat = update['chat'];
        if (chat is TdObject) _upsertChat(chat);
      case 'updateChatTitle':
        _mutateChat(update, (entry) {
          entry.title = update['title'] as String? ?? entry.title;
        });
      case 'updateChatLastMessage':
        _mutateChat(update, (entry) {
          final message = update['last_message'];
          if (message is TdObject) {
            entry.lastMessage = messageFrom(message, senderNameOf: _senderName);
          }
          final positions = update['positions'];
          if (positions is List && positions.isNotEmpty) {
            final (order, pinned) = mainListPositionOf(positions);
            entry.order = order;
            entry.isPinned = pinned;
          }
        });
      case 'updateChatPosition':
        _mutateChat(update, (entry) {
          final (order, pinned) =
              mainListPositionOf([update['position']]);
          entry.order = order;
          entry.isPinned = pinned;
        });
      case 'updateChatReadInbox':
        _mutateChat(update, (entry) {
          entry.unreadCount =
              (update['unread_count'] as num?)?.toInt() ?? entry.unreadCount;
        });
      case 'updateNewMessage':
        final message = update['message'];
        if (message is TdObject) {
          final chatId = (message['chat_id'] as num).toInt();
          _windows[chatId]
              ?.append(messageFrom(message, senderNameOf: _senderName));
        }
      case 'updateMessageSendSucceeded':
        final message = update['message'];
        final oldId = update['old_message_id'];
        if (message is TdObject && oldId is num) {
          final chatId = (message['chat_id'] as num).toInt();
          _windows[chatId]?.replace(
            '${oldId.toInt()}',
            messageFrom(message, senderNameOf: _senderName),
          );
        }
      case 'updateMessageSendFailed':
        final message = update['message'];
        final oldId = update['old_message_id'];
        if (message is TdObject && oldId is num) {
          final chatId = (message['chat_id'] as num).toInt();
          _windows[chatId]?.replace(
            '${oldId.toInt()}',
            messageFrom(message, senderNameOf: _senderName)
                .copyWith(status: MessageStatus.failed),
          );
        }
      case 'updateMessageContent':
        // Edición del texto de un mensaje (propia o de otro participante).
        final chatId = (update['chat_id'] as num?)?.toInt();
        final messageId = update['message_id'];
        final newContent = update['new_content'];
        if (chatId != null && messageId is num && newContent is TdObject) {
          _windows[chatId]
              ?.editContent('${messageId.toInt()}', contentFrom(newContent));
        }
      case 'updateDeleteMessages':
        if (update['is_permanent'] == true) {
          final chatId = (update['chat_id'] as num?)?.toInt();
          final ids = update['message_ids'];
          if (chatId != null && ids is List) {
            _windows[chatId]?.removeAll({for (final id in ids) '$id'});
          }
        }
    }
  }

  String? _senderName(TdObject? senderId) => switch (senderId?['@type']) {
        'messageSenderUser' =>
          _userNames[(senderId?['user_id'] as num?)?.toInt()],
        'messageSenderChat' =>
          _chatStore[(senderId?['chat_id'] as num?)?.toInt()]?.title,
        _ => null,
      };

  void _upsertChat(TdObject chat) {
    final chatId = (chat['id'] as num).toInt();
    final (order, pinned) =
        mainListPositionOf(chat['positions'] as List<Object?>?);
    final lastMessage = chat['last_message'];
    _chatStore[chatId] = _ChatEntry(
      id: chatId,
      title: chat['title'] as String? ?? '',
      kind: chatKindFrom(chat['type'] as TdObject?),
      order: order,
      isPinned: pinned,
      unreadCount: (chat['unread_count'] as num?)?.toInt() ?? 0,
      isMuted: false,
      lastMessage: lastMessage is TdObject
          ? messageFrom(lastMessage, senderNameOf: _senderName)
          : null,
    );
    _emitChats();
  }

  void _mutateChat(TdObject update, void Function(_ChatEntry entry) mutate) {
    final chatId = (update['chat_id'] as num?)?.toInt();
    final entry = _chatStore[chatId];
    if (entry == null) return;
    mutate(entry);
    _emitChats();
  }

  void _emitChats() {
    final entries = _chatStore.values
        .where((entry) => entry.order > BigInt.zero)
        .toList()
      ..sort((a, b) {
        final byOrder = b.order.compareTo(a.order);
        return byOrder != 0 ? byOrder : a.id.compareTo(b.id);
      });
    _chats.value = [for (final entry in entries) entry.toChat()];
  }

  // --- Mensajes --------------------------------------------------------------

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    final id = int.parse(chatId);
    final window = _windows.putIfAbsent(
      id,
      () => _MessageWindow(onIdle: () => _scheduleChatRelease(id)),
    );
    if (!window.initialLoadStarted) {
      window.initialLoadStarted = true;
      _client.post({'@type': 'openChat', 'chat_id': id});
      unawaited(_loadHistory(id, fromMessageId: 0, limit: 30));
    }
    return window.stream.stream;
  }

  /// `openChat` y `closeChat` son un par obligatorio en TDLib: mientras un
  /// chat está abierto, TDLib lo mantiene sincronizado activamente. Sin este
  /// cierre, cada chat visitado quedaba abierto para siempre y el consumo de
  /// red y memoria crecía durante toda la sesión.
  ///
  /// Se espera un margen porque un rebuild de la UI cancela y vuelve a
  /// suscribirse enseguida; solo se cierra si nadie ha vuelto.
  void _scheduleChatRelease(int chatId) {
    if (_disposed) return;
    late final Timer timer;
    timer = Timer(const Duration(seconds: 3), () {
      _releaseTimers.remove(timer);
      final window = _windows[chatId];
      if (_disposed || window == null || window.stream.hasListeners) return;
      _client.post({'@type': 'closeChat', 'chat_id': chatId});
      _windows.remove(chatId);
      window.stream.close();
    });
    _releaseTimers.add(timer);
  }

  @override
  Future<void> loadMoreMessages(String chatId, {int limit = 30}) async {
    final id = int.parse(chatId);
    final window = _windows[id];
    if (window == null || window.items.isEmpty) return;
    await _loadHistory(id,
        fromMessageId: int.parse(window.items.first.id), limit: limit);
  }

  Future<void> _loadHistory(int chatId,
      {required int fromMessageId, required int limit}) async {
    try {
      final response = await _client.send({
        '@type': 'getChatHistory',
        'chat_id': chatId,
        'from_message_id': fromMessageId,
        'offset': 0,
        'limit': limit,
        'only_local': false,
      });
      final raw = response['messages'];
      if (raw is! List) return;
      // TDLib devuelve historial de más nuevo a más antiguo.
      final older = [
        for (final message in raw.whereType<TdObject>())
          messageFrom(message, senderNameOf: _senderName),
      ].reversed.toList();
      _windows[chatId]?.prependHistory(older);
    } on EngineException catch (e) {
      _log.error('getChatHistory($chatId) falló', e);
    }
  }

  @override
  Future<void> sendText(String chatId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    // La respuesta llega también como updateNewMessage (estado "sending");
    // updateMessageSendSucceeded lo sustituirá por el definitivo.
    await _client.send({
      '@type': 'sendMessage',
      'chat_id': int.parse(chatId),
      'input_message_content': {
        '@type': 'inputMessageText',
        'text': {'@type': 'formattedText', 'text': trimmed},
      },
    });
  }

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    try {
      await _client.send({
        '@type': 'deleteMessages',
        'chat_id': int.parse(chatId),
        'message_ids': [int.parse(messageId)],
        'revoke': true, // borrar para todos, no solo para mí
      });
      // TDLib confirma con updateDeleteMessages(is_permanent: true), que ya
      // quita el mensaje de la ventana observada.
    } on TdRequestException catch (e) {
      throw EngineException(e.message, code: '${e.tdCode}', cause: e);
    }
  }

  @override
  Future<void> editMessage(
      String chatId, String messageId, String newText) async {
    final trimmed = newText.trim();
    if (trimmed.isEmpty) return;
    try {
      await _client.send({
        '@type': 'editMessageText',
        'chat_id': int.parse(chatId),
        'message_id': int.parse(messageId),
        'input_message_content': {
          '@type': 'inputMessageText',
          'text': {'@type': 'formattedText', 'text': trimmed},
        },
      });
      // La confirmación llega como updateMessageContent / updateMessageEdited,
      // que la ventana observada ya refleja.
    } on TdRequestException catch (e) {
      throw EngineException(e.message, code: '${e.tdCode}', cause: e);
    }
  }

  @override
  Future<void> markChatRead(String chatId) async {
    final id = int.parse(chatId);
    final last = _chatStore[id]?.lastMessage;
    if (last == null) return;
    _client.post({
      '@type': 'viewMessages',
      'chat_id': id,
      'message_ids': [int.parse(last.id)],
      'force_read': true,
    });
  }
}

/// Estado mutable interno de un chat (dominio + orden int64 de TDLib).
class _ChatEntry {
  _ChatEntry({
    required this.id,
    required this.title,
    required this.kind,
    required this.order,
    required this.isPinned,
    required this.unreadCount,
    required this.isMuted,
    required this.lastMessage,
  });

  final int id;
  String title;
  ChatKind kind;
  BigInt order;
  bool isPinned;
  int unreadCount;
  bool isMuted;
  Message? lastMessage;

  Chat toChat() => Chat(
        id: '$id',
        title: title,
        kind: kind,
        lastMessage: lastMessage,
        unreadCount: unreadCount,
        isPinned: isPinned,
        isMuted: isMuted,
      );
}

/// Ventana observada de mensajes de un chat (ascendente por antigüedad).
class _MessageWindow {
  _MessageWindow({void Function()? onIdle})
      : stream = StateStream<List<Message>>(const [], onIdle: onIdle);

  final StateStream<List<Message>> stream;
  List<Message> items = const [];
  bool initialLoadStarted = false;

  void _emit() => stream.value = items;

  void append(Message message) {
    items = [...items, message];
    _emit();
  }

  void prependHistory(List<Message> older) {
    final known = {for (final m in items) m.id};
    final fresh = [
      for (final message in older)
        if (!known.contains(message.id)) message,
    ];
    if (fresh.isEmpty) return;
    items = [...fresh, ...items];
    _emit();
  }

  void replace(String oldId, Message message) {
    items = [
      for (final item in items)
        if (item.id == oldId) message else item,
    ];
    _emit();
  }

  /// Sustituye el contenido de un mensaje ya presente y lo marca como
  /// editado, conservando el resto de sus campos.
  void editContent(String id, MessageContent content) {
    var changed = false;
    items = [
      for (final item in items)
        if (item.id == id)
          () {
            changed = true;
            return item.copyWith(content: content, isEdited: true);
          }()
        else
          item,
    ];
    if (changed) _emit();
  }

  void removeAll(Set<String> ids) {
    items = [
      for (final item in items)
        if (!ids.contains(item.id)) item,
    ];
    _emit();
  }
}
