import 'package:alim_engine_supabase/src/sync/retry_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el retraso crece exponencialmente hasta el techo', () {
    const policy = OutboxRetryPolicy(
      maxAttempts: 6,
      baseDelay: Duration(seconds: 2),
      maxDelay: Duration(minutes: 5),
    );

    expect(policy.delayFor(0), const Duration(seconds: 2));
    expect(policy.delayFor(1), const Duration(seconds: 4));
    expect(policy.delayFor(2), const Duration(seconds: 8));
    expect(policy.delayFor(10), const Duration(minutes: 5)); // saturado
  });

  test('se da por vencido exactamente en maxAttempts', () {
    const policy = OutboxRetryPolicy(maxAttempts: 3);
    expect(policy.shouldGiveUp(2), isFalse);
    expect(policy.shouldGiveUp(3), isTrue);
    expect(policy.shouldGiveUp(4), isTrue);
  });
}
