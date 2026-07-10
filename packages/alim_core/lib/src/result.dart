/// Resultado funcional ligero para cruzar límites de capa sin excepciones.
sealed class Result<T> {
  const Result();

  const factory Result.ok(T value) = Ok<T>;
  const factory Result.err(Object error, [StackTrace? stackTrace]) = Err<T>;

  /// Ejecuta [body] capturando cualquier excepción como [Err].
  static Future<Result<T>> guard<T>(Future<T> Function() body) async {
    try {
      return Result.ok(await body());
    } catch (error, stackTrace) {
      return Result.err(error, stackTrace);
    }
  }

  bool get isOk => this is Ok<T>;

  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Err<T>() => null,
      };

  R fold<R>(R Function(T value) onOk, R Function(Object error) onErr) =>
      switch (this) {
        Ok<T>(:final value) => onOk(value),
        Err<T>(:final error) => onErr(error),
      };
}

final class Ok<T> extends Result<T> {
  const Ok(this.value);

  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.error, [this.stackTrace]);

  final Object error;
  final StackTrace? stackTrace;
}
