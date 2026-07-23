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

/// Capacidad opcional: motores donde el usuario puede borrar sus propios
/// mensajes para todos los participantes. La UI solo ofrece la acción sobre
/// mensajes salientes; el motor y el backend la vuelven a validar.
abstract interface class MessageDeleter {
  /// Borra [messageId] de [chatId] para todos. Lanza `EngineException` si el
  /// mensaje no es propio o ya no se puede borrar.
  Future<void> deleteMessage(String chatId, String messageId);
}

/// Capacidad opcional: motores donde el usuario puede editar el texto de sus
/// propios mensajes. La UI solo la ofrece sobre mensajes salientes de texto.
abstract interface class MessageEditor {
  /// Sustituye el texto de [messageId] en [chatId] por [newText]. Lanza
  /// `EngineException` si el mensaje no es propio o no es editable.
  Future<void> editMessage(String chatId, String messageId, String newText);
}
