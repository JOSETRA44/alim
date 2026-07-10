enum SpecSeverity { warning, error }

/// Problema detectado al parsear/validar un spec ALIM.
///
/// Filosofía fail-safe: un warning nunca impide aplicar el tema (se usa el
/// valor por defecto y se informa); solo un JSON imposible de leer es fatal.
class SpecIssue {
  const SpecIssue(this.severity, this.path, this.message);

  final SpecSeverity severity;

  /// Ruta dentro del documento, p. ej. `tokens.color.light.primary`.
  final String path;
  final String message;

  @override
  String toString() => '[${severity.name}] $path: $message';
}
