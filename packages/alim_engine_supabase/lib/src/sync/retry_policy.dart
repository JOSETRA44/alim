/// Política de reintentos del outbox: cuánto esperar antes de reintentar un
/// mensaje que falló al enviarse, y cuándo darse por vencido.
///
/// Backoff exponencial con techo: intentos rápidos al principio (la mayoría
/// de fallos son cortes de red de segundos) sin machacar el backend si la
/// caída es larga. Tras [maxAttempts] fallidos el mensaje queda como
/// fallido definitivo — igual que TDLib, que tampoco reintenta solo: el
/// usuario debe reenviar a mano (`chat_screen.dart` ya pinta el icono de
/// error para `MessageStatus.failed`).
class OutboxRetryPolicy {
  const OutboxRetryPolicy({
    this.maxAttempts = 6,
    this.baseDelay = const Duration(seconds: 2),
    this.maxDelay = const Duration(minutes: 5),
  });

  final int maxAttempts;
  final Duration baseDelay;
  final Duration maxDelay;

  bool shouldGiveUp(int attempts) => attempts >= maxAttempts;

  Duration delayFor(int attempts) {
    final scaled = baseDelay * (1 << attempts.clamp(0, 20));
    return scaled > maxDelay ? maxDelay : scaled;
  }
}
