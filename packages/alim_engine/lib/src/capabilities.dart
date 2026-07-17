/// Capacidad opcional: motores donde el usuario puede iniciar una
/// conversación directa buscando a otro usuario por su nombre de usuario.
/// No aplica a TDLib (los chats vienen determinados por la cuenta de
/// Telegram) ni al motor simulado.
abstract interface class ConversationStarter {
  /// Crea (o reutiliza) el chat directo con [username] y devuelve su id.
  /// Lanza `EngineException` si no existe ningún usuario con ese nombre.
  Future<String> startDirectChat(String username);
}

/// Capacidad opcional: motores con perfil de usuario editable (nombre de
/// usuario propio, buscable por otros).
abstract interface class ProfileEditor {
  /// Reclama [username] para la cuenta propia. Lanza `EngineException` si
  /// ya está en uso.
  Future<void> setUsername(String username);
}
