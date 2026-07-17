import 'dart:async';

import 'package:alim_core/alim_core.dart';
import 'package:alim_engine/alim_engine.dart';
import 'package:alim_keystore/alim_keystore.dart';
import 'package:uuid/uuid.dart';

import 'local/connection.dart';
import 'local/database.dart';
import 'remote/models.dart';
import 'remote/remote_transport.dart';
import 'remote/supabase_remote_transport.dart';
import 'sync/sync_engine.dart';

/// Motor "uchat native": local-first sobre Drift, con Supabase como capa de
/// sync en background ([SyncEngine]). Auth por código de un solo uso al
/// correo (Supabase email OTP) en vez de teléfono: reutiliza la misma
/// máquina de estados de [AuthState] que TDLib (waitingPhoneNumber ahora
/// contiene un email; nunca se llega a [AuthWaitingPassword]).
class SupabaseEngine
    implements
        MessagingEngine,
        ConversationStarter,
        ProfileEditor,
        MessageDeleter {
  /// [database] permite inyectar una BD en memoria en los tests; en
  /// producción se abre cifrada con la clave de [keyStore].
  SupabaseEngine({
    required RemoteTransport transport,
    LocalDatabase? database,
    SecretKeyStore? keyStore,
  })  : _transport = transport,
        _db = database ??
            LocalDatabase(
              openEncryptedConnection(keyStore ?? SecureKeyStore()),
            );

  /// Fábrica de producción: transporte real sobre `supabase_flutter`
  /// (requiere `Supabase.initialize` ya ejecutado) y BD local cifrada con
  /// la clave del almacén seguro del SO.
  factory SupabaseEngine.production() => SupabaseEngine(
        transport: SupabaseRemoteTransport(),
        keyStore: SecureKeyStore(),
      );

  static final _log = AlimLogger('SupabaseEngine');
  static const _uuid = Uuid();

  final RemoteTransport _transport;
  final LocalDatabase _db;

  late final StateStream<AuthState> _auth =
      StateStream<AuthState>(const AuthInitializing());
  late final StateStream<List<Chat>> _chats = StateStream<List<Chat>>(const []);
  final Map<String, StateStream<List<Message>>> _messageRelays = {};
  final Map<String, StreamSubscription<List<Message>>> _messageRelaySubs = {};

  StreamSubscription<String?>? _authSub;
  StreamSubscription<List<Chat>>? _chatsSub;
  SyncEngine? _sync;
  String _lastEmail = '';
  bool _started = false;
  bool _disposed = false;

  @override
  String get id => 'supabase';

  @override
  String get name => 'ALIM nativo (Supabase)';

  @override
  String get identifierLabel => 'Correo electrónico';

  @override
  String get identifierHint => 'tu@correo.com';

  @override
  Stream<AuthState> get authStates => _auth.stream;

  @override
  AuthState get currentAuthState => _auth.value;

  @override
  Stream<List<Chat>> get chats => _chats.stream;

  // --- Ciclo de vida -----------------------------------------------------

  @override
  Future<void> start() async {
    if (_started || _disposed) return;
    _started = true;

    _authSub = _transport.authChanges.listen((userId) {
      if (userId == null && _auth.value is! AuthClosed) {
        _stopSync();
        _auth.value = const AuthWaitingPhoneNumber();
      }
    });

    final userId = _transport.currentUserId;
    if (userId != null) {
      await _becomeReady(userId);
    } else {
      _auth.value = const AuthWaitingPhoneNumber();
    }
    _log.info('arrancado');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _chatsSub?.cancel();
    for (final sub in _messageRelaySubs.values) {
      await sub.cancel();
    }
    _stopSync();
    await _authSub?.cancel();
    await _transport.dispose();
    _auth.value = const AuthClosed();
    _auth.close();
    for (final relay in _messageRelays.values) {
      relay.close();
    }
    await _db.close();
    _log.info('cerrado');
  }

  @override
  Future<void> setBackgrounded(bool backgrounded) async {
    // Realtime de Supabase reconecta solo; nada que reducir explícitamente.
  }

  Future<void> _becomeReady(String userId) async {
    final profile = await _safeProfile(userId);
    await _chatsSub?.cancel();
    _chatsSub = _db.watchChats(userId).listen((value) => _chats.value = value);
    _stopSync();
    _sync = SyncEngine(db: _db, transport: _transport, currentUserId: userId)
      ..start();
    _auth.value = AuthReady(user: profile);
  }

  void _stopSync() {
    _sync?.dispose();
    _sync = null;
  }

  Future<AlimUser> _safeProfile(String userId) async {
    try {
      return await _transport.fetchOwnProfile();
    } catch (e) {
      _log.warning('fetchOwnProfile falló: $e');
      return AlimUser(id: userId, displayName: userId);
    }
  }

  // --- Autenticación -------------------------------------------------------

  @override
  Future<void> submitPhoneNumber(String phoneNumber) async {
    final email = phoneNumber.trim();
    if (!email.contains('@') || !email.contains('.')) {
      _auth.value = const AuthWaitingPhoneNumber(error: 'Correo inválido');
      return;
    }
    try {
      await _transport.requestEmailCode(email);
      _lastEmail = email;
      _auth.value = AuthWaitingCode(phoneNumber: email);
    } on EngineException catch (e) {
      _auth.value = AuthWaitingPhoneNumber(error: e.message);
    }
  }

  @override
  Future<void> submitCode(String code) async {
    try {
      await _transport.verifyEmailCode(_lastEmail, code.trim());
      final userId = _transport.currentUserId;
      if (userId == null) {
        throw const EngineException('No se pudo iniciar sesión');
      }
      await _becomeReady(userId);
    } on EngineException catch (e) {
      _auth.value = AuthWaitingCode(phoneNumber: _lastEmail, error: e.message);
    }
  }

  @override
  Future<void> submitPassword(String password) async {
    // Este motor usa código de un solo uso al correo: nunca se llega aquí.
    throw const EngineException(
        'Este motor no usa contraseña', code: 'UNSUPPORTED');
  }

  @override
  Future<void> logOut() async {
    await _chatsSub?.cancel();
    _stopSync();
    await _transport.signOut();
    // El historial de la cuenta anterior no sobrevive en el dispositivo.
    await _db.wipe();
    _auth.value = const AuthLoggedOut();
    _auth.value = const AuthWaitingPhoneNumber();
  }

  // --- Chats y mensajes ------------------------------------------------------

  @override
  Stream<List<Message>> watchMessages(String chatId) {
    final relay = _messageRelays.putIfAbsent(chatId, () {
      final stream = StateStream<List<Message>>(const []);
      final userId = _transport.currentUserId;
      if (userId != null) {
        _messageRelaySubs[chatId] = _db
            .watchMessages(chatId, userId)
            .listen((value) => stream.value = value);
      }
      return stream;
    });
    return relay.stream;
  }

  @override
  Future<void> loadMoreMessages(String chatId, {int limit = 30}) async {
    final userId = _transport.currentUserId;
    if (userId == null) return;
    try {
      final oldest = await _db.oldestMessageTime(chatId);
      final older = await _transport.fetchMessagesBefore(
        chatId,
        before: oldest,
        limit: limit,
      );
      for (final message in older) {
        await _db.applyIncomingMessage(message, currentUserId: userId);
      }
    } on EngineException catch (e) {
      _log.warning('loadMoreMessages($chatId) falló: $e');
    }
  }

  @override
  Future<void> sendText(String chatId, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final userId = _transport.currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    await _db.enqueueOutgoing(Message(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: userId,
      content: TextContent(trimmed),
      sentAt: DateTime.now(),
      isOutgoing: true,
      status: MessageStatus.sending,
    ));
  }

  @override
  Future<void> markChatRead(String chatId) => _db.markRead(chatId);

  @override
  Future<void> deleteMessage(String chatId, String messageId) async {
    final userId = _transport.currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    // Borrado optimista: desaparece de la UI al instante (la BD local es la
    // fuente de verdad). Si el borrado remoto falla, se restaura la copia.
    final backup = await _db.messageById(messageId);
    await _db.deleteMessageLocal(messageId);
    try {
      await _transport.deleteMessage(messageId);
    } on EngineException {
      if (backup != null) {
        await _db.applyIncomingMessage(
          RemoteMessage(
            id: backup.id,
            conversationId: backup.conversationId,
            senderId: backup.senderId,
            content: backup.content,
            createdAt: backup.createdAt,
            updatedAt: backup.updatedAt,
          ),
          currentUserId: userId,
        );
      }
      rethrow;
    }
  }

  // --- Capacidades opcionales --------------------------------------------

  @override
  Future<String> startDirectChat(String username) async {
    final userId = _transport.currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    final otherUserId = await _transport.findUserIdByUsername(username.trim());
    if (otherUserId == null) {
      throw EngineException(
          'No existe ningún usuario "$username"', code: 'USER_NOT_FOUND');
    }
    if (otherUserId == userId) {
      throw const EngineException('No puedes iniciar un chat contigo mismo');
    }
    final conversationId =
        await _transport.createDirectConversation(otherUserId);
    final remote = await _transport.fetchConversation(conversationId);
    if (remote != null) {
      await _db.upsertConversation(remote, currentUserId: userId);
    }
    return conversationId;
  }

  @override
  Future<void> setUsername(String username) =>
      _transport.setUsername(username.trim());
}
