import 'dart:math';

/// Política de reintentos del outbox: cuánto esperar antes de reintentar un
/// mensaje que falló al enviarse, y cuándo darse por vencido.
///
/// Backoff exponencial con techo: intentos rápidos al principio (la mayoría
/// de fallos son cortes de red de segundos) sin machacar el backend si la
/// caída es larga. Tras [maxAttempts] fallidos el mensaje queda como
/// fallido definitivo — igual que TDLib, que tampoco reintenta solo: el
/// usuario debe reenviar a mano (`chat_screen.dart` ya pinta el icono de
/// error para `MessageStatus.failed`).
///
/// Sobre el jitter: el techo exponencial es determinista, así que sin
/// aleatoriedad todos los clientes que fallan a la vez (p. ej. una caída del
/// backend) reintentan sincronizados y machacan el servidor en oleadas justo
/// cuando intenta recuperarse. [delayFor] añade jitter sobre ese techo para
/// desincronizarlos. El [Random] se inyecta para poder testear con semilla.
class OutboxRetryPolicy {
  const OutboxRetryPolicy({
    this.maxAttempts = 6,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
    Random? random,
  }) : _random = random;

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;
  final Random? _random;

  bool shouldGiveUp(int attempts) => attempts >= maxAttempts;

  /// Techo determinista del backoff: duplica [baseDelay] por intento hasta
  /// saturar en [maxDelay]. Es la cota superior; [delayFor] aplica jitter por
  /// debajo de este valor.
  Duration ceilingFor(int attempts) {
    final scaled = baseDelay * (1 << attempts.clamp(0, 20));
    return scaled > maxDelay ? maxDelay : scaled;
  }

  /// Retraso real antes del siguiente intento: el techo de [ceilingFor] con
  /// jitter aplicado para desincronizar clientes.
  Duration delayFor(int attempts) {
    final ceiling = ceilingFor(attempts);
    final rng = _random ?? Random();
    return _applyJitter(ceiling, rng);
  }

  /// Equal jitter: conserva la mitad baja del techo como espera garantizada y
  /// reparte la otra mitad al azar → `ceiling/2 + random(0, ceiling/2)`.
  ///
  /// Elegido frente a full jitter (`random(0, ceiling)`) porque en ALIM los
  /// reintentos casi inmediatos que produce full jitter aportan poco (hay
  /// pocos clientes por conversación) y sí gastan batería y datos móviles
  /// despertando la radio; equal jitter mantiene el backoff creciendo de
  /// forma predecible y aun así desincroniza clientes lo bastante para no
  /// machacar el backend en oleadas tras una caída.
  ///
  /// Descartada la estrategia decorrelada: exige recordar el retraso previo y
  /// esta API es sin estado (el intento vive en la fila del outbox, no aquí).
  ///
  /// El resultado está acotado en `[ceiling/2, ceiling]`: nunca supera el
  /// techo (invariante que protege el test) ni es negativo.
  Duration _applyJitter(Duration ceiling, Random rng) {
    final half = ceiling.inMicroseconds ~/ 2;
    // half==0 solo si el techo es <2µs (imposible con baseDelay en segundos),
    // pero nextInt exige un máximo >0, así que lo cubrimos.
    if (half <= 0) return ceiling;
    final randomHalf = rng.nextInt(half + 1); // [0, half] inclusive
    return Duration(microseconds: half + randomHalf);
  }
}
