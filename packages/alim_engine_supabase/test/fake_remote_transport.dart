import 'dart:async';

import 'package:alim_engine/alim_engine.dart';
import 'package:alim_engine_supabase/alim_engine_supabase.dart';

/// Transporte fake: mantiene un backend en memoria y permite inyectar
/// eventos Realtime, ejercitando el motor completo sin red real (mismo
/// patrón que `FakeTdClient` en alim_engine_tdlib).
class FakeRemoteTransport implements RemoteTransport {
  final _authChanges = StreamController<String?>.broadcast();
  final _events = StreamController<RemoteEvent>.broadcast();

  final Map<String, AlimUser> profilesByEmail = {};
  final Map<String, String> usernames = {}; // username -> userId
  final Map<String, RemoteConversation> conversations = {};
  final List<RemoteMessage> messages = [];

  /// Códigos "enviados" por [requestEmailCode], para que el test los lea.
  final Map<String, String> pendingCodes = {};

  String? _currentUserId;
  bool failNextInsert = false;
  int conversationSeq = 0;

  @override
  Stream<String?> get authChanges => _authChanges.stream;

  @override
  String? get currentUserId => _currentUserId;

  void emit(RemoteEvent event) => _events.add(event);

  @override
  Future<void> requestEmailCode(String email) async {
    pendingCodes[email] = '11111';
  }

  @override
  Future<void> verifyEmailCode(String email, String code) async {
    if (pendingCodes[email] != code) {
      throw const EngineException('Código incorrecto', code: 'INVALID_CODE');
    }
    final user = profilesByEmail.putIfAbsent(
      email,
      () => AlimUser(id: 'u-${profilesByEmail.length}', displayName: email.split('@').first),
    );
    _currentUserId = user.id;
    _authChanges.add(user.id);
  }

  @override
  Future<AlimUser> fetchOwnProfile() async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    return profilesByEmail.values.firstWhere((u) => u.id == userId);
  }

  @override
  Future<void> signOut() async {
    _currentUserId = null;
    _authChanges.add(null);
  }

  @override
  Future<void> setUsername(String username) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw const EngineException('No autenticado', code: 'NOT_AUTHENTICATED');
    }
    if (usernames.containsKey(username)) {
      throw const EngineException('Ese nombre de usuario ya está en uso',
          code: '23505');
    }
    usernames[username] = userId;
  }

  @override
  Future<String?> findUserIdByUsername(String username) async =>
      usernames[username];

  String _displayNameOf(String userId) => profilesByEmail.values
      .firstWhere((u) => u.id == userId, orElse: () => AlimUser(id: userId, displayName: userId))
      .displayName;

  @override
  Future<String> createDirectConversation(String otherUserId) async {
    final userId = _currentUserId!;
    final id = 'c-${conversationSeq++}';
    conversations[id] = RemoteConversation(
      id: id,
      kind: RemoteConversationKind.direct,
      title: null,
      updatedAt: DateTime.now(),
      memberNames: {
        userId: _displayNameOf(userId),
        otherUserId: _displayNameOf(otherUserId),
      },
    );
    return id;
  }

  @override
  Future<List<RemoteConversation>> fetchConversations() async {
    final userId = _currentUserId;
    if (userId == null) return const [];
    return [
      for (final c in conversations.values)
        if (c.memberNames.containsKey(userId)) c,
    ];
  }

  @override
  Future<RemoteConversation?> fetchConversation(String id) async =>
      conversations[id];

  @override
  Future<List<RemoteMessage>> fetchMessagesBefore(
    String conversationId, {
    DateTime? before,
    required int limit,
  }) async {
    final all = messages
        .where((m) =>
            m.conversationId == conversationId &&
            (before == null || m.createdAt.isBefore(before)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all.take(limit).toList().reversed.toList();
  }

  @override
  Future<List<RemoteMessage>> fetchMessagesSince(DateTime since) async {
    final userId = _currentUserId;
    if (userId == null) return const [];
    final myConversations = {
      for (final c in conversations.values)
        if (c.memberNames.containsKey(userId)) c.id,
    };
    return messages
        .where((m) =>
            myConversations.contains(m.conversationId) &&
            m.updatedAt.isAfter(since))
        .toList();
  }

  @override
  Future<void> insertMessage(RemoteMessage message) async {
    if (failNextInsert) {
      failNextInsert = false;
      throw const EngineException('network down', code: 'NETWORK');
    }
    messages.add(message);
    final conv = conversations[message.conversationId];
    if (conv != null) {
      conversations[message.conversationId] = RemoteConversation(
        id: conv.id,
        kind: conv.kind,
        title: conv.title,
        updatedAt: message.updatedAt,
        memberNames: conv.memberNames,
      );
    }
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    messages.removeWhere((m) => m.id == messageId);
  }

  bool failNextEdit = false;

  @override
  Future<void> editMessage(String messageId, String content) async {
    if (failNextEdit) {
      failNextEdit = false;
      throw const EngineException('network down', code: 'NETWORK');
    }
    final i = messages.indexWhere((m) => m.id == messageId);
    if (i == -1) return;
    final old = messages[i];
    messages[i] = RemoteMessage(
      id: old.id,
      conversationId: old.conversationId,
      senderId: old.senderId,
      content: content,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Stream<RemoteEvent> get events => _events.stream;

  @override
  Future<void> dispose() async {
    await _authChanges.close();
    await _events.close();
  }
}
