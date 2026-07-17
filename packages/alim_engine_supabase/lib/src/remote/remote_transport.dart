import 'package:alim_engine/alim_engine.dart';

import 'models.dart';

/// Transporte de red hacia Supabase, abstraído para poder testear
/// [SupabaseEngine] y [SyncEngine] sin red real (mismo patrón que `TdClient`
/// en alim_engine_tdlib: producción usa [SupabaseRemoteTransport], los
/// tests inyectan un fake).
abstract interface class RemoteTransport {
  /// Emite el id del usuario al autenticarse y `null` al cerrar sesión.
  Stream<String?> get authChanges;

  String? get currentUserId;

  Future<void> requestEmailCode(String email);

  Future<void> verifyEmailCode(String email, String code);

  Future<AlimUser> fetchOwnProfile();

  Future<void> signOut();

  Future<void> setUsername(String username);

  Future<String?> findUserIdByUsername(String username);

  Future<String> createDirectConversation(String otherUserId);

  Future<List<RemoteConversation>> fetchConversations();

  Future<RemoteConversation?> fetchConversation(String id);

  /// Paginación keyset: la ventana más reciente si [before] es null, o el
  /// tramo inmediatamente anterior a esa fecha.
  Future<List<RemoteMessage>> fetchMessagesBefore(
    String conversationId, {
    DateTime? before,
    required int limit,
  });

  /// Delta-pull: todo lo que cambió (insert o update) después de [since],
  /// en todas las conversaciones del usuario. RLS ya filtra por membresía.
  Future<List<RemoteMessage>> fetchMessagesSince(DateTime since);

  Future<void> insertMessage(RemoteMessage message);

  /// Borra el mensaje del backend. RLS solo lo permite al remitente.
  Future<void> deleteMessage(String messageId);

  Stream<RemoteEvent> get events;

  Future<void> dispose();
}
