import 'package:alim_core/alim_core.dart';

/// Objeto JSON de TDLib (request, respuesta o update).
typedef TdObject = Map<String, Object?>;

/// Error devuelto por TDLib a una petición concreta.
class TdRequestException extends EngineException {
  const TdRequestException(super.message, {this.tdCode, super.code});

  /// Código numérico de TDLib (400, 401, 429...).
  final int? tdCode;
}

/// Transporte abstracto hacia TDLib. La implementación real es FFI
/// ([TdFfiClient]); los tests inyectan un fake para ejercitar el motor
/// completo sin binarios nativos.
abstract interface class TdClient {
  /// Updates no solicitados (`update*`). Broadcast.
  Stream<TdObject> get updates;

  /// Arranca el transporte (crea el cliente nativo y el loop de recepción).
  Future<void> start();

  /// Envía [request] y espera su respuesta correlacionada por `@extra`.
  /// Lanza [TdRequestException] si TDLib responde `error`.
  Future<TdObject> send(TdObject request);

  /// Envía sin esperar respuesta (fire-and-forget).
  void post(TdObject request);

  /// Cierre ordenado del transporte. Idempotente.
  Future<void> close();
}
