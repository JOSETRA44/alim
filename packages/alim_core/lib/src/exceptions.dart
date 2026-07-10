/// Error de dominio lanzado por cualquier implementación de motor.
///
/// Las capas de presentación solo dependen de este tipo; los detalles del
/// transporte (TDLib, Supabase, red) quedan en [cause].
class EngineException implements Exception {
  const EngineException(this.message, {this.code, this.cause});

  /// Mensaje legible para logs y, cuando aplica, para la UI.
  final String message;

  /// Código estable opcional (p. ej. `PHONE_NUMBER_INVALID`).
  final String? code;

  /// Error original de la capa de infraestructura.
  final Object? cause;

  @override
  String toString() =>
      'EngineException(${code == null ? '' : '$code: '}$message)';
}
