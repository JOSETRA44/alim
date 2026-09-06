import 'dart:async';

import 'package:alim_core/alim_core.dart';

import '../local/database.dart';
import '../remote/models.dart';
import '../remote/remote_transport.dart';
import 'retry_policy.dart';

/// Sincroniza en background la BD local (SSOT) con Supabase: drena el
/// outbox de mensajes salientes, aplica eventos Realtime entrantes y hace
/// un delta-pull al arrancar. La UI nunca toca esto directamente: solo
/// observa las queries reactivas de [LocalDatabase].
class SyncEngine {
  SyncEngine({
    required LocalDatabase db,
    required RemoteTransport transport,
    required String currentUserId,
    this.retryPolicy = const OutboxRetryPolicy(),
  })  : _db = db,
        _transport = transport,
        _currentUserId = currentUserId;

  static final _log = AlimLogger('SyncEngine');

  final LocalDatabase _db;
  final RemoteTransport _transport;
  final String _currentUserId;
  final OutboxRetryPolicy retryPolicy;

  StreamSubscription<RemoteEvent>? _eventsSub;
  Timer? _outboxTimer;
  bool _disposed = false;

  Future<void> start() async {
    _eventsSub = _transport.events.listen(_onRemoteEvent);
    unawaited(_deltaPull());
    _scheduleOutboxDrain(Duration.zero);
  }

  void dispose() {
    _disposed = true;
    _outboxTimer?.cancel();
    _eventsSub?.cancel();
  }

  void _onRemoteEvent(RemoteEvent event) {
    switch (event) {
      case RemoteMessageUpserted(:final message):
        unawaited(
          _db.applyIncomingMessage(message, currentUserId: _currentUserId),
        );
      case RemoteMessageDeleted(:final id):
        // Borrado hecho desde otro dispositivo: se refleja localmente.
        unawaited(_db.deleteMessageLocal(id));
      case RemoteConversationChanged(:final conversationId):
        unawaited(_refreshConversation(conversationId));
    }
  }

  Future<void> _refreshConversation(String conversationId) async {
    try {
      final remote = await _transport.fetchConversation(conversationId);
      if (remote != null) {
        await _db.upsertConversation(remote, currentUserId: _currentUserId);
      }
    } catch (e) {
      _log.warning('refresh de conversación $conversationId falló: $e');
    }
  }

  Future<void> _deltaPull() async {
    try {
      final conversations = await _transport.fetchConversations();
      for (final conv in conversations) {
        await _db.upsertConversation(conv, currentUserId: _currentUserId);
      }

      final cursor = await _db.syncCursor('messages') ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final since = DateTime.now();
      final messages = await _transport.fetchMessagesSince(cursor);
      for (final message in messages) {
        await _db.applyIncomingMessage(message, currentUserId: _currentUserId);
      }
      await _db.setSyncCursor('messages', since);
    } catch (e) {
      _log.warning('delta-pull falló: $e');
    }
  }

  /// Despierta el drenado del outbox. Lo llama el motor al encolar un mensaje
  /// nuevo, para no depender de que un sondeo lo descubra.
  void notifyOutboxChanged() => _scheduleOutboxDrain(Duration.zero);

  void _scheduleOutboxDrain(Duration delay) {
    if (_disposed) return;
    _outboxTimer?.cancel();
    _outboxTimer = Timer(delay, _drainOutbox);
  }

  /// Drena lo que esté vencido y luego duerme EXACTAMENTE hasta el próximo
  /// reintento pendiente. Si no queda nada en el outbox no se reprograma
  /// nada: antes se re-agendaba cada 3 s indefinidamente, lo que suponía una
  /// consulta a SQLite cada 3 s de por vida (batería en móvil) aunque no
  /// hubiera un solo mensaje que enviar.
  Future<void> _drainOutbox() async {
    if (_disposed) return;
    final due = await _db.duePendingOutbox();
    for (final entry in due) {
      if (_disposed) return;
      await _sendOne(entry);
    }
    if (_disposed) return;

    final next = await _db.nextPendingAttemptAt();
    if (next == null || _disposed) return; // outbox vacío: a dormir.
    final delay = next.difference(DateTime.now());
    _scheduleOutboxDrain(delay.isNegative ? Duration.zero : delay);
  }

  Future<void> _sendOne(LocalOutboxEntry entry) async {
    final message = await _db.messageById(entry.messageId);
    if (message == null) {
      // Huérfano (borrado localmente entre encolar y drenar): limpio.
      await _db.markOutboxSent(entry.messageId);
      return;
    }
    try {
      await _transport.insertMessage(RemoteMessage(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        content: message.content,
        createdAt: message.createdAt,
        updatedAt: message.updatedAt,
      ));
      await _db.markOutboxSent(entry.messageId);
    } catch (e) {
      final attempts = entry.attempts + 1;
      final giveUp = retryPolicy.shouldGiveUp(attempts);
      await _db.markOutboxRetry(
        entry.messageId,
        attempts: attempts,
        nextAttemptAt: DateTime.now().add(retryPolicy.delayFor(attempts)),
        error: '$e',
        gaveUp: giveUp,
      );
      _log.warning('envío de ${entry.messageId} falló (intento $attempts): $e');
    }
  }
}
