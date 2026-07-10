import 'models/auth_state.dart';
import 'models/chat.dart';
import 'models/message.dart';

/// Contrato único que la UI conoce. Implementaciones: TDLib, Supabase
/// local-first, Mock. Cambiar de motor no toca ninguna feature.
///
/// Convenciones reactivas:
/// - Todos los streams entregan el estado vigente al suscribirse
///   (semántica de `StateStream` en alim_core).
/// - [watchMessages] emite la ventana cargada del chat ordenada de más
///   antiguo a más reciente; [loadMoreMessages] antepone historial y la
///   misma suscripción recibe la ventana ampliada.
/// - Los comandos fallan con `EngineException` (alim_core).
abstract interface class MessagingEngine {
  /// Identificador estable (`mock`, `tdlib`, `supabase`) usado por el
  /// selector de motor del Dev Mode y por la persistencia de ajustes.
  String get id;

  /// Nombre legible para la UI.
  String get name;

  // --- Ciclo de vida -------------------------------------------------------

  /// Arranca el motor. Idempotente: llamadas repetidas no crean recursos
  /// duplicados. Tras esto [authStates] comienza a emitir.
  Future<void> start();

  /// Cierre ordenado: libera clientes nativos, isolates y streams.
  /// Tras esto el motor queda en [AuthClosed] y no acepta comandos.
  Future<void> dispose();

  // --- Autenticación -------------------------------------------------------

  Stream<AuthState> get authStates;

  /// Estado vigente sin necesidad de suscripción (para redirects de router).
  AuthState get currentAuthState;

  Future<void> submitPhoneNumber(String phoneNumber);

  Future<void> submitCode(String code);

  Future<void> submitPassword(String password);

  Future<void> logOut();

  // --- Chats y mensajes ----------------------------------------------------

  /// Lista de chats ordenada (pinned primero, luego por actividad).
  Stream<List<Chat>> get chats;

  Stream<List<Message>> watchMessages(String chatId);

  /// Carga historial más antiguo dentro de la ventana observada.
  Future<void> loadMoreMessages(String chatId, {int limit = 30});

  Future<void> sendText(String chatId, String text);

  Future<void> markChatRead(String chatId);
}
