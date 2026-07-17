import 'dart:async';
import 'dart:math';

import 'package:alim_core/alim_core.dart';
import 'package:alim_engine/alim_engine.dart';

import 'seed_data.dart';

/// Implementación simulada de [MessagingEngine].
///
/// Flujo de auth simulado (para poder probar todas las pantallas):
/// - cualquier teléfono es aceptado;
/// - el código `11111` lleva a 2FA, cualquier otro de 5 dígitos autentica;
/// - la contraseña correcta de 2FA es `alim`.
class MockMessagingEngine implements MessagingEngine {
  MockMessagingEngine({
    this.autoAuthenticate = true,
    this.replyDelay = const Duration(seconds: 2),
  });

  /// Si es true, [start] deja el motor directamente en [AuthReady].
  final bool autoAuthenticate;

  /// Retraso de las respuestas automáticas (0 en tests).
  final Duration replyDelay;

  final _log = AlimLogger('MockEngine');
  final _random = Random(42);

  late final StateStream<AuthState> _auth =
      StateStream<AuthState>(const AuthInitializing());
  late final StateStream<List<Chat>> _chats = StateStream<List<Chat>>(const []);
  final Map<String, StateStream<List<Message>>> _messages = {};
  final Set<Timer> _pendingReplies = {};

  bool _started = false;
  bool _disposed = false;
  int _messageSeq = 0;

  @override
  String get id => 'mock';

  @override
  String get name => 'Motor simulado';

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

  // --- Ciclo de vida ---------------------------------------------------------

  @override
  Future<void> start() async {
    _ensureUsable();
    if (_started) return;
    _started = true;
    _seed();
    _auth.value = autoAuthenticate
        ? const AuthReady(user: MockSeed.self)
        : const AuthWaitingPhoneNumber();
    _log.info('arrancado (autoAuthenticate=$autoAuthenticate)');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    for (final timer in _pendingReplies) {
      timer.cancel();
    }
    _pendingReplies.clear();
    _auth.value = const AuthClosed();
    _auth.close();
    _chats.close();
    for (final stream in _messages.values) {
      stream.close();
    }
    _log.info('cerrado');
  }

  @override
  Future<void> setBackgrounded(bool backgrounded) async {
    // El motor simulado no tiene presencia ni red que reducir.
  }

  // --- Autenticación ---------------------------------------------------------

  @override
  Future<void> submitPhoneNumber(String phoneNumber) async {
    _ensureUsable();
    final normalized = phoneNumber.trim();
    if (normalized.length < 6) {
      _auth.value =
          const AuthWaitingPhoneNumber(error: 'Número de teléfono inválido');
      return;
    }
    _auth.value = AuthWaitingCode(phoneNumber: normalized);
  }

  @override
  Future<void> submitCode(String code) async {
    _ensureUsable();
    final current = _auth.value;
    if (current is! AuthWaitingCode) {
      throw const EngineException('No se esperaba un código ahora');
    }
    if (code.trim() == '11111') {
      _auth.value = const AuthWaitingPassword(hint: 'el nombre de la app');
      return;
    }
    if (code.trim().length != 5) {
      _auth.value = AuthWaitingCode(
        phoneNumber: current.phoneNumber,
        error: 'El código debe tener 5 dígitos',
      );
      return;
    }
    _auth.value = const AuthReady(user: MockSeed.self);
  }

  @override
  Future<void> submitPassword(String password) async {
    _ensureUsable();
    if (_auth.value is! AuthWaitingPassword) {
      throw const EngineException('No se esperaba una contraseña ahora');
    }
    if (password != 'alim') {
      _auth.value = const AuthWaitingPassword(
        hint: 'el nombre de la app',
        error: 'Contraseña incorrecta',
      );
      return;
    }
    _auth.value = const AuthReady(user: MockSeed.self);
  }

  @override
  Future<void> logOut() async {
    _ensureUsable();
    _auth.value = const AuthLoggedOut();
    _auth.value = const AuthWaitingPhoneNumber();
  }

  // --- Chats y mensajes ------------------------------------------------------

  @override
  Stream<List<Message>> watchMessages(String chatId) =>
      _messagesOf(chatId).stream;

  @override
  Future<void> loadMoreMessages(String chatId, {int limit = 30}) async {
    // El historial semilla ya está completo en memoria; nada que cargar.
  }

  @override
  Future<void> sendText(String chatId, String text) async {
    _ensureUsable();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final message = Message(
      id: 'm-${_messageSeq++}',
      chatId: chatId,
      senderId: MockSeed.self.id,
      senderName: MockSeed.self.displayName,
      content: TextContent(trimmed),
      sentAt: DateTime.now(),
      isOutgoing: true,
      status: MessageStatus.sent,
    );
    _append(chatId, message);
    _scheduleReply(chatId);
  }

  @override
  Future<void> markChatRead(String chatId) async {
    _ensureUsable();
    _chats.value = [
      for (final chat in _chats.value)
        if (chat.id == chatId) chat.copyWith(unreadCount: 0) else chat,
    ];
  }

  // --- Internos ---------------------------------------------------------------

  void _ensureUsable() {
    if (_disposed) {
      throw const EngineException('El motor ya fue cerrado', code: 'CLOSED');
    }
  }

  void _seed() {
    final history = MockSeed.messages(DateTime.now());
    for (final entry in history.entries) {
      _messagesOf(entry.key).value = entry.value;
    }
    _chats.value = MockSeed.chats(history);
  }

  StateStream<List<Message>> _messagesOf(String chatId) =>
      _messages.putIfAbsent(chatId, () => StateStream<List<Message>>(const []));

  void _append(String chatId, Message message) {
    final stream = _messagesOf(chatId);
    stream.value = [...stream.value, message];
    _chats.value = _sorted([
      for (final chat in _chats.value)
        if (chat.id == chatId)
          chat.copyWith(
            lastMessage: message,
            unreadCount:
                message.isOutgoing ? chat.unreadCount : chat.unreadCount + 1,
          )
        else
          chat,
    ]);
  }

  List<Chat> _sorted(List<Chat> chats) {
    final copy = [...chats];
    copy.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      final aTime = a.lastMessage?.sentAt ?? DateTime(2000);
      final bTime = b.lastMessage?.sentAt ?? DateTime(2000);
      return bTime.compareTo(aTime);
    });
    return copy;
  }

  void _scheduleReply(String chatId) {
    late final Timer timer;
    timer = Timer(replyDelay, () {
      _pendingReplies.remove(timer);
      if (_disposed) return;
      final sender = switch (chatId) {
        'c-ada' => MockSeed.ada,
        'c-linus' => MockSeed.linus,
        _ => MockSeed.grace,
      };
      _append(
        chatId,
        Message(
          id: 'm-${_messageSeq++}',
          chatId: chatId,
          senderId: sender.id,
          senderName: sender.displayName,
          content: TextContent(
            MockSeed.replies[_random.nextInt(MockSeed.replies.length)],
          ),
          sentAt: DateTime.now(),
          isOutgoing: false,
        ),
      );
    });
    _pendingReplies.add(timer);
  }
}
