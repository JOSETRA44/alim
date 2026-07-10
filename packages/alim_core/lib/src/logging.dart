/// Nivel de severidad de un evento de log.
enum LogLevel { debug, info, warning, error }

/// Destino de los logs; inyectable para tests y para la consola del Dev Mode.
typedef LogSink = void Function(LogLevel level, String scope, String message);

/// Logger mínimo con ámbito. Evita dependencias externas: la consola del
/// Modo Desarrollador se conectará aquí mediante [LogSink].
class AlimLogger {
  AlimLogger(this.scope, {LogSink? sink}) : _sink = sink ?? _printSink;

  final String scope;
  final LogSink _sink;

  static void _printSink(LogLevel level, String scope, String message) {
    // ignore: avoid_print
    print('[${level.name}] $scope: $message');
  }

  void debug(String message) => _sink(LogLevel.debug, scope, message);
  void info(String message) => _sink(LogLevel.info, scope, message);
  void warning(String message) => _sink(LogLevel.warning, scope, message);
  void error(String message, [Object? cause]) => _sink(
        LogLevel.error,
        scope,
        cause == null ? message : '$message ($cause)',
      );
}
