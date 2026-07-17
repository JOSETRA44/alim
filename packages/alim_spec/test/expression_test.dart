import 'package:alim_spec/alim_spec.dart';
import 'package:test/test.dart';

void main() {
  Object? run(String source, [ExprContext context = const {}]) =>
      AlimExpression.compile(source).evaluate(context);

  group('AlimExpression: evaluación', () {
    test('literales y aritmética', () {
      expect(run('1 + 2 * 3'), 7);
      expect(run('(1 + 2) * 3'), 9);
      expect(run('10 / 4'), 2.5);
      expect(run('7 % 3'), 1);
      expect(run('-5 + 2'), -3);
      expect(run("'a' + 'b'"), 'ab');
    });

    test('comparaciones y lógica con cortocircuito', () {
      expect(run('1 < 2 && 2 <= 2'), true);
      expect(run('3 > 4 || 4 >= 4'), true);
      expect(run("!false && 'x' == 'x'"), true);
      expect(run("1 != 2"), true);
      // El cortocircuito evita evaluar el lado derecho inválido.
      expect(run('false && noExiste.nada'), false);
      expect(run('true || noExiste.nada'), true);
    });

    test('ternario', () {
      expect(run("true ? 'sí' : 'no'"), 'sí');
      expect(run('1 > 2 ? 10 : 20'), 20);
      expect(run("true ? false ? 1 : 2 : 3"), 2);
    });

    test('rutas del contexto', () {
      final context = {
        'message': {'isOutgoing': true, 'length': 42},
        'tokens': {
          'color': {'primary': '#3D5A50'},
        },
      };
      expect(run('message.isOutgoing', context), true);
      expect(
        run("message.isOutgoing ? tokens.color.primary : 'gris'", context),
        '#3D5A50',
      );
      expect(run('message.length > 40', context), true);
    });

    test('el caso de uso real del spec', () {
      final context = {
        'message': {'isOutgoing': false, 'isRead': true},
        'tokens': {
          'color': {'primary': '#111111', 'surface': '#EEEEEE'},
        },
      };
      expect(
        run('message.isOutgoing ? tokens.color.primary : tokens.color.surface',
            context),
        '#EEEEEE',
      );
    });
  });

  group('AlimExpression: errores y sandbox', () {
    test('sintaxis inválida no compila', () {
      expect(() => AlimExpression.compile('1 +'), throwsA(isA<ExpressionException>()));
      expect(() => AlimExpression.compile('(1'), throwsA(isA<ExpressionException>()));
      expect(() => AlimExpression.compile("'sin cerrar"),
          throwsA(isA<ExpressionException>()));
      expect(() => AlimExpression.compile('1 ; 2'),
          throwsA(isA<ExpressionException>()));
      expect(() => AlimExpression.compile('a b'),
          throwsA(isA<ExpressionException>()));
    });

    test('no existen llamadas ni acceso fuera del contexto (sandbox)', () {
      // Paréntesis tras identificador = token sobrante -> no compila.
      expect(() => AlimExpression.compile('print(1)'),
          throwsA(isA<ExpressionException>()));
      // Corchetes no forman parte de la gramática.
      expect(() => AlimExpression.compile("a['b']"),
          throwsA(isA<ExpressionException>()));
    });

    test('ruta inexistente falla en evaluación (el llamador degrada)', () {
      expect(() => run('nada.de.nada'), throwsA(isA<ExpressionException>()));
    });

    test('errores de tipo son explícitos', () {
      expect(() => run("1 + true"), throwsA(isA<ExpressionException>()));
      expect(() => run("'x' < 'y'"), throwsA(isA<ExpressionException>()));
      expect(() => run("5 ? 1 : 2"), throwsA(isA<ExpressionException>()));
    });

    test('división y módulo por cero', () {
      expect(() => run('1 / 0'), throwsA(isA<ExpressionException>()));
      expect(() => run('1 % 0'), throwsA(isA<ExpressionException>()));
    });

    test('entradas hostiles largas no rompen el parser', () {
      final deep = '${'(' * 200}1${')' * 200}';
      expect(run(deep), 1);
      final longChain = List.filled(500, '1').join('+');
      expect(run(longChain), 500);
    });
  });
}
