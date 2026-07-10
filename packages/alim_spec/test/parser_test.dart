import 'package:alim_spec/alim_spec.dart';
import 'package:test/test.dart';

void main() {
  group('AlimSpecParser', () {
    test('parsea el spec por defecto sin issues', () {
      final result = AlimSpecParser.parse(defaultSpecJson);
      expect(result.issues, isEmpty);
      final spec = result.spec!;
      expect(spec.meta.name, 'Lienzo');
      expect(spec.tokens.color.seed, 0xFF3D5A50);
      expect(spec.tokens.color.lightOverrides['surface'], 0xFFFAFAF8);
      expect(spec.components['chat_bubble']?['radius'], 16);
    });

    test('todos los presets de fábrica parsean limpios', () {
      for (final entry in presetSpecs.entries) {
        final result = AlimSpecParser.parse(entry.value);
        expect(result.issues, isEmpty,
            reason: 'preset ${entry.key}: ${result.issues}');
        expect(result.spec, isNotNull);
      }
    });

    test('JSON malformado es fatal (spec null, error)', () {
      final result = AlimSpecParser.parse('{no es json');
      expect(result.spec, isNull);
      expect(result.hasErrors, isTrue);
    });

    test('color inválido degrada a default con warning', () {
      final result = AlimSpecParser.parse('''
        {"alim": "0.1", "tokens": {"color": {"seed": "verde"}}}
      ''');
      expect(result.spec, isNotNull);
      expect(result.spec!.tokens.color.seed, 0xFF3D5A50);
      expect(
        result.issues.any((i) => i.path == 'tokens.color.seed'),
        isTrue,
      );
    });

    test('rol de color desconocido se ignora con warning', () {
      final result = AlimSpecParser.parse('''
        {"alim": "0.1", "tokens": {"color": {"light": {"neon": "#FF00FF"}}}}
      ''');
      expect(result.spec!.tokens.color.lightOverrides, isEmpty);
      expect(result.issues.single.path, 'tokens.color.light.neon');
    });

    test('número fuera de rango degrada a default con warning', () {
      final result = AlimSpecParser.parse('''
        {"alim": "0.1", "tokens": {"typography": {"scale": 9}}}
      ''');
      expect(result.spec!.tokens.typography.scale, 1.0);
      expect(result.issues, isNotEmpty);
    });

    test('versión distinta produce warning pero se interpreta', () {
      final result = AlimSpecParser.parse('{"alim": "9.9"}');
      expect(result.spec, isNotNull);
      expect(result.issues.any((i) => i.path == 'alim'), isTrue);
    });

    test('claves desconocidas en la raíz avisan sin romper', () {
      final result = AlimSpecParser.parse('{"alim": "0.1", "layout": {}}');
      expect(result.spec, isNotNull);
      expect(result.issues.any((i) => i.path == 'layout'), isTrue);
    });
  });

  group('parseHexColor', () {
    test('acepta #RRGGBB y #AARRGGBB', () {
      expect(parseHexColor('#3D5A50'), 0xFF3D5A50);
      expect(parseHexColor('#803D5A50'), 0x803D5A50);
    });

    test('rechaza formatos inválidos', () {
      expect(parseHexColor('3D5A50'), isNull);
      expect(parseHexColor('#XYZ'), isNull);
      expect(parseHexColor(42), isNull);
    });
  });
}
