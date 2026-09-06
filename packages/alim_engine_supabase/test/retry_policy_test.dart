import 'dart:math';

import 'package:alim_engine_supabase/src/sync/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el techo crece exponencialmente hasta saturar', () {
    const policy = OutboxRetryPolicy(
      maxAttempts: 6,
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(minutes: 5),
    );

    expect(policy.ceilingFor(0), const Duration(seconds: 2));
    expect(policy.ceilingFor(1), const Duration(seconds: 4));
    expect(policy.ceilingFor(2), const Duration(seconds: 8));
    expect(policy.ceilingFor(10), const Duration(minutes: 5)); // saturado
  });

  test('delayFor nunca supera el techo ni es negativo', () {
    // Vale con cualquier estrategia de jitter razonable: es la invariante
    // que el andamiaje garantiza aunque cambie la fórmula.
    final policy = OutboxRetryPolicy(random: Random(42));
    for (var attempts = 0; attempts < 8; attempts++) {
      for (var i = 0; i < 50; i++) {
        final delay = policy.delayFor(attempts);
        expect(delay, greaterThanOrEqualTo(Duration.zero));
        expect(delay, lessThanOrEqualTo(policy.ceilingFor(attempts)));
      }
    }
  });

  test('equal jitter: el retraso cae en [techo/2, techo]', () {
    final policy = OutboxRetryPolicy(
      baseDelay: const Duration(seconds: 2),
      random: Random(7),
    );
    for (var attempts = 0; attempts < 6; attempts++) {
      final ceiling = policy.ceilingFor(attempts);
      final floor = Duration(microseconds: ceiling.inMicroseconds ~/ 2);
      for (var i = 0; i < 200; i++) {
        final delay = policy.delayFor(attempts);
        expect(delay, greaterThanOrEqualTo(floor));
        expect(delay, lessThanOrEqualTo(ceiling));
      }
    }
  });

  test('equal jitter: dos clientes que fallan a la vez NO se sincronizan', () {
    // La razón de ser del jitter: desincronizar. Con semillas distintas, dos
    // clientes calculan retrasos distintos para el mismo intento.
    final a = OutboxRetryPolicy(random: Random(1));
    final b = OutboxRetryPolicy(random: Random(2));
    final delaysA = [for (var i = 0; i < 20; i++) a.delayFor(3)];
    final delaysB = [for (var i = 0; i < 20; i++) b.delayFor(3)];
    expect(delaysA, isNot(equals(delaysB)),
        reason: 'sin jitter ambos darían la misma secuencia');
  });

  test('se da por vencido exactamente en maxAttempts', () {
    const policy = OutboxRetryPolicy(maxAttempts: 3);
    expect(policy.shouldGiveUp(2), isFalse);
    expect(policy.shouldGiveUp(3), isTrue);
    expect(policy.shouldGiveUp(4), isTrue);
  });
}
