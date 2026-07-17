import 'package:alim_spec/alim_spec.dart';
import 'package:alim_theme_engine/alim_theme_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AlimSpec parse(String json) => AlimSpecParser.parse(json).spec!;

  const incomingKey = BubbleContextKey(
      isOutgoing: false, isRead: false, isGroup: false, isFailed: false);
  const outgoingKey = BubbleContextKey(
      isOutgoing: true, isRead: false, isGroup: false, isFailed: false);
  const outgoingReadKey = BubbleContextKey(
      isOutgoing: true, isRead: true, isGroup: false, isFailed: false);

  group('ThemeCompiler: tokens', () {
    test('el spec por defecto compila con la extensión de burbuja', () {
      final compiled = ThemeCompiler.compile(parse(defaultSpecJson));

      expect(compiled.light.colorScheme.surface, const Color(0xFFFAFAF8));
      final bubble = compiled.light.extension<AlimBubbleTheme>()!;
      final style = bubble.resolve(outgoingKey);
      expect(style.radius, 16);
      expect(style.tailRadius, 4);
      // "@primaryContainer" resuelve contra el esquema derivado de la semilla.
      expect(style.background, compiled.light.colorScheme.primaryContainer);
    });

    test('los overrides por rol se aplican solo al brillo indicado', () {
      final compiled = ThemeCompiler.compile(parse('''
        {"alim": "0.1", "tokens": {"color": {
          "seed": "#3D5A50",
          "dark": {"surface": "#101214"}
        }}}
      '''));

      expect(compiled.dark.colorScheme.surface, const Color(0xFF101214));
      expect(compiled.light.colorScheme.surface,
          isNot(const Color(0xFF101214)));
    });

    test('la escala tipográfica multiplica los tamaños', () {
      final scaled = ThemeCompiler.compile(parse('''
        {"alim": "0.1", "tokens": {
          "color": {"seed": "#3D5A50"},
          "typography": {"scale": 1.5}
        }}
      '''));

      final baseSize =
          Typography.material2021().englishLike.bodyLarge!.fontSize!;
      final scaledSize = scaled.light.textTheme.bodyLarge!.fontSize!;
      expect(scaledSize, closeTo(baseSize * 1.5, 0.01));
    });
  });

  group('ThemeCompiler: burbuja', () {
    test('colores hex literales', () {
      final compiled = ThemeCompiler.compile(parse('''
        {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
         "components": {"chat_bubble": {"outgoing": "#FF0000"}}}
      '''));

      final bubble = compiled.light.extension<AlimBubbleTheme>()!;
      expect(bubble.resolve(outgoingKey).background, const Color(0xFFFF0000));
    });

    test('valores inválidos degradan a defaults con issue', () {
      final issues = <SpecIssue>[];
      final compiled = ThemeCompiler.compile(
        parse('''
          {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
           "components": {"chat_bubble": {
             "incoming": "verde fosforito",
             "radius": 999,
             "maxWidthFraction": "ancho"
           }}}
        '''),
        issues: issues,
      );

      final style =
          compiled.light.extension<AlimBubbleTheme>()!.resolve(incomingKey);
      expect(style.background,
          compiled.light.colorScheme.surfaceContainerHighest);
      expect(style.radius, 16);
      expect(style.maxWidthFraction, 0.75);
      expect(issues.any((i) => i.path.contains('incoming')), isTrue);
    });

    test('expresiones de color evalúan por clave de contexto', () {
      final compiled = ThemeCompiler.compile(parse(r'''
        {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
         "components": {"chat_bubble": {
           "outgoing": "${message.isRead ? '#00FF00' : '#FF0000'}"
         }}}
      '''));

      final bubble = compiled.light.extension<AlimBubbleTheme>()!;
      expect(bubble.resolve(outgoingKey).background, const Color(0xFFFF0000));
      expect(
          bubble.resolve(outgoingReadKey).background, const Color(0xFF00FF00));
    });

    test('la resolución está memoizada (misma instancia por clave)', () {
      final compiled = ThemeCompiler.compile(parse(presetSpecs['Expresivo']!));
      final bubble = compiled.light.extension<AlimBubbleTheme>()!;

      expect(
        identical(bubble.resolve(outgoingKey), bubble.resolve(outgoingKey)),
        isTrue,
        reason: 'la segunda consulta debe ser un lookup, no una evaluación',
      );
    });

    test('una expresión inválida degrada con issue, sin romper', () {
      final issues = <SpecIssue>[];
      final compiled = ThemeCompiler.compile(
        parse(r'''
          {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
           "components": {"chat_bubble": {"outgoing": "${1 +}"}}}
        '''),
        issues: issues,
      );

      expect(
        compiled.light.extension<AlimBubbleTheme>()!.resolve(outgoingKey)
            .background,
        compiled.light.colorScheme.primaryContainer,
      );
      expect(issues, isNotEmpty);
    });
  });

  group('ThemeCompiler: layout de bloques', () {
    test('el layout del preset Expresivo compila', () {
      final compiled = ThemeCompiler.compile(parse(presetSpecs['Expresivo']!));
      final bubble = compiled.light.extension<AlimBubbleTheme>()!;
      expect(bubble.layout, isNotNull);
      expect(bubble.layout!.root, isA<ColumnNode>());
    });

    test('un bloque desconocido se descarta con issue', () {
      final issues = <SpecIssue>[];
      ThemeCompiler.compile(
        parse('''
          {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
           "components": {"chat_bubble": {"layout": {
             "type": "column",
             "children": [{"type": "hologram"}, {"type": "text"}]
           }}}}
        '''),
        issues: issues,
      );

      expect(issues.any((i) => i.message.contains('hologram')), isTrue);
    });

    test('sin layout la extensión lo deja en null (layout nativo)', () {
      final compiled = ThemeCompiler.compile(parse(defaultSpecJson));
      expect(compiled.light.extension<AlimBubbleTheme>()!.layout, isNull);
    });
  });

  test('todos los presets compilan limpios en ambos brillos', () {
    for (final entry in presetSpecs.entries) {
      final issues = <SpecIssue>[];
      final compiled =
          ThemeCompiler.compile(parse(entry.value), issues: issues);
      expect(issues, isEmpty, reason: 'preset ${entry.key}: $issues');
      expect(compiled.light.extension<AlimBubbleTheme>(), isNotNull);
      expect(compiled.dark.extension<AlimBubbleTheme>(), isNotNull);
    }
  });
}
