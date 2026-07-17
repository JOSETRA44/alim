import 'dart:async';

import 'package:alim_engine/alim_engine.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'models.dart';
import 'remote_transport.dart';

/// Implementación real de [RemoteTransport] sobre `supabase_flutter`.
///
/// Requiere que `Supabase.initialize` ya se haya ejecutado (se hace una
/// vez en `main()`, antes de construir cualquier motor).
class SupabaseRemoteTransport implements RemoteTransport {
  SupabaseRemoteTransport([sb.SupabaseClient? client])
      : _client = client ?? sb.Supabase.instance.client;

  final sb.SupabaseClient _client;
  final _events = StreamController<RemoteEvent>.broadcast();
  sb.RealtimeChannel? _channel;

  @override
  Stream<String?> get authChanges =>
      _client.auth.onAuthStateChange.map((event) => event.session?.user.id);

  @override
  String? get currentUserId => _client.auth.currentUser?.id;

  @override
  Future<void> requestEmailCode(String email) async {
    try {
      await _client.auth.signInWithOtp(email: email);
    } on sb.AuthException catch (e) {
      throw EngineException(e.message, code: e.code, cause: e);
    }
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email,
        token: code,
        type: sb.OtpType.email,
      );
      if (response.user == null) {
        throw const EngineException('Código incorrecto', code: 'INVALID_CODE');
      }
      _subscribeRealtime();
    } on sb.AuthException catch (e) {
      throw EngineException(e.message, code: e.code, cause: e);
    }
  }

  @override
  Future<AlimUser> fetchOwnProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    _subscribeRealtime();
    final row =
        await _client.from('profiles').select().eq('id', userId).single();
    return AlimUser(
      id: userId,
      displayName: row['display_name'] as String,
      username: row['username'] as String?,
    );
  }

  @override
  Future<void> signOut() async {
    await _channel?.unsubscribe();
    _channel = null;
    await _client.auth.signOut();
  }

  @override
  Future<void> setUsername(String username) async {
    final userId = currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    try {
      await _client
          .from('profiles')
          .update({'username': username}).eq('id', userId);
    } on sb.PostgrestException catch (e) {
      throw EngineException(
        e.code == '23505' ? 'Ese nombre de usuario ya está en uso' : e.message,
        code: e.code,
        cause: e,
      );
    }
  }

  @override
  Future<String?> findUserIdByUsername(String username) async {
    final rows = await _client
        .from('profiles')
        .select('id')
        .eq('username', username)
        .limit(1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as String;
  }

  @override
  Future<String> createDirectConversation(String otherUserId) async {
    try {
      final id = await _client.rpc('create_conversation', params: {
        'p_kind': 'direct',
        'p_title': null,
        'p_member_ids': [otherUserId],
      });
      return id as String;
    } on sb.PostgrestException catch (e) {
      throw EngineException(e.message, code: e.code, cause: e);
    }
  }

  static const _conversationSelect =
      'id, kind, title, updated_at, conversation_members(user_id, profiles(display_name))';

  @override
  Future<List<RemoteConversation>> fetchConversations() async {
    final userId = currentUserId;
    if (userId == null) return const [];
    final memberships = await _client
        .from('conversation_members')
        .select('conversation_id')
        .eq('user_id', userId);
    final ids = [for (final m in memberships) m['conversation_id'] as String];
    if (ids.isEmpty) return const [];
    final rows = await _client
        .from('conversations')
        .select(_conversationSelect)
        .inFilter('id', ids)
        .order('updated_at', ascending: false);
    return [for (final row in rows) _conversationFrom(row)];
  }

  @override
  Future<RemoteConversation?> fetchConversation(String id) async {
    final rows = await _client
        .from('conversations')
        .select(_conversationSelect)
        .eq('id', id)
        .limit(1);
    // Lista vacía: ya no somos miembros (RLS) o no existe.
    if (rows.isEmpty) return null;
    return _conversationFrom(rows.first);
  }

  RemoteConversation _conversationFrom(Map<String, Object?> row) {
    final members = (row['conversation_members'] as List? ?? const [])
        .cast<Map<String, Object?>>();
    return RemoteConversation(
      id: row['id'] as String,
      kind: row['kind'] == 'group'
          ? RemoteConversationKind.group
          : RemoteConversationKind.direct,
      title: row['title'] as String?,
      updatedAt: DateTime.parse(row['updated_at'] as String),
      memberNames: {
        for (final member in members)
          member['user_id'] as String:
              (member['profiles'] as Map<String, Object?>?)?['display_name']
                      as String? ??
                  '',
      },
    );
  }

  @override
  Future<List<RemoteMessage>> fetchMessagesBefore(
    String conversationId, {
    DateTime? before,
    required int limit,
  }) async {
    var query = _client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId);
    if (before != null) {
      query = query.lt('created_at', before.toIso8601String());
    }
    final rows = await query.order('created_at', ascending: false).limit(limit);
    // La API devuelve más nuevo primero; el dominio espera ascendente.
    return [for (final row in rows.reversed) _messageFrom(row)];
  }

  @override
  Future<List<RemoteMessage>> fetchMessagesSince(DateTime since) async {
    if (currentUserId == null) return const [];
    final rows = await _client
        .from('messages')
        .select()
        .gt('updated_at', since.toIso8601String())
        .order('updated_at');
    return [for (final row in rows) _messageFrom(row)];
  }

  RemoteMessage _messageFrom(Map<String, Object?> row) => RemoteMessage(
        id: row['id'] as String,
        conversationId: row['conversation_id'] as String,
        senderId: row['sender_id'] as String,
        content: row['content'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );

  @override
  Future<void> insertMessage(RemoteMessage message) async {
    try {
      await _client.from('messages').insert({
        'id': message.id,
        'conversation_id': message.conversationId,
        'sender_id': message.senderId,
        'content': message.content,
      });
    } on sb.PostgrestException catch (e) {
      throw EngineException(e.message, code: e.code, cause: e);
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      await _client.from('messages').delete().eq('id', messageId);
    } on sb.PostgrestException catch (e) {
      throw EngineException(e.message, code: e.code, cause: e);
    }
  }

  @override
  Stream<RemoteEvent> get events => _events.stream;

  void _subscribeRealtime() {
    if (_channel != null) return;
    _channel = _client.channel('alim-sync')
      ..onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: 'messages',
        callback: (payload) {
          if (payload.eventType == sb.PostgresChangeEvent.delete) {
            // En un DELETE los datos viajan en oldRecord. `messages` tiene
            // REPLICA IDENTITY FULL (ver migración), así que trae también
            // conversation_id, no solo la PK.
            final old = payload.oldRecord;
            final id = old['id'] as String?;
            final conversationId = old['conversation_id'] as String?;
            if (id != null && conversationId != null) {
              _events.add(RemoteMessageDeleted(
                  id: id, conversationId: conversationId));
            }
            return;
          }
          final record = payload.newRecord;
          if (record.isEmpty) return;
          _events.add(RemoteMessageUpserted(_messageFrom(record)));
        },
      )
      ..onPostgresChanges(
        event: sb.PostgresChangeEvent.all,
        schema: 'public',
        table: 'conversations',
        callback: (payload) {
          final id = payload.newRecord['id'] as String?;
          if (id != null) _events.add(RemoteConversationChanged(id));
        },
      )
      ..onPostgresChanges(
        event: sb.PostgresChangeEvent.insert,
        schema: 'public',
        table: 'conversation_members',
        callback: (payload) {
          final id = payload.newRecord['conversation_id'] as String?;
          if (id != null) _events.add(RemoteConversationChanged(id));
        },
      )
      ..subscribe();
  }

  @override
  Future<void> dispose() async {
    await _channel?.unsubscribe();
    _channel = null;
    await _events.close();
  }
}
