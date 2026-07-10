import 'package:alim_core/alim_core.dart';
import 'package:test/test.dart';

void main() {
  group('StateStream', () {
    test('un suscriptor tardío recibe el valor vigente primero', () async {
      final stream = StateStream<int>(1);
      stream.value = 2;

      expect(await stream.stream.first, 2);
      stream.close();
    });

    test('emite actualizaciones a todos los suscriptores', () async {
      final stream = StateStream<int>(0);
      final seen = <int>[];
      final sub = stream.stream.listen(seen.add);

      stream.value = 1;
      stream.value = 2;
      await Future<void>.delayed(Duration.zero);

      expect(seen, [0, 1, 2]);
      await sub.cancel();
      stream.close();
    });

    test('close cierra los streams y silencia escrituras posteriores',
        () async {
      final stream = StateStream<int>(0);
      final done = stream.stream.toList();
      stream.close();
      stream.value = 99;

      expect(await done, [0]);
      expect(stream.value, 0);
    });
  });

  group('Result', () {
    test('guard captura excepciones como Err', () async {
      final result = await Result.guard<int>(() async => throw StateError('x'));
      expect(result.isOk, isFalse);
      expect(result.fold((_) => 'ok', (e) => 'err'), 'err');
    });
  });
}
