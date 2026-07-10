import 'package:alim_spec/alim_spec.dart';
import 'package:alim_theme_engine/alim_theme_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AlimSpec parse(String json) => AlimSpecParser.parse(json).spec!;

  group('ThemeCompiler', () {
    test('el spec por defecto compila con la extensión de burbuja', () {
      final compiled = ThemeCompiler.compile(parse(defaultSpecJson));

      expect(compiled.light.colorScheme.surface, const Color(0xFFFAFAF8));
      final bubble = compiled.light.extension<AlimBubbleStyle>();
      expect(bubble, isNotNull);
      expect(bubble!.radius, 16);
      expect(bubble.tailRadius, 4);
      // "@primaryContainer" resuelve contra el esquema derivado de la semilla.
      expect(bubble.outgoing, compiled.light.colorScheme.primaryContainer);
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

    test('colores hex literales en componentes', () {
      final compiled = ThemeCompiler.compile(parse('''
        {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
         "components": {"chat_bubble": {"outgoing": "#FF0000"}}}
      '''));

      expect(compiled.light.extension<AlimBubbleStyle>()!.outgoing,
          const Color(0xFFFF0000));
    });

    test('valores inválidos de componente degradan a defaults', () {
      final compiled = ThemeCompiler.compile(parse('''
        {"alim": "0.1", "tokens": {"color": {"seed": "#3D5A50"}},
         "components": {"chat_bubble": {
           "incoming": "@rolInexistente",
           "radius": 999,
           "maxWidthFraction": "ancho"
         }}}
      '''));

      final bubble = compiled.light.extension<AlimBubbleStyle>()!;
      expect(bubble.incoming, compiled.light.colorScheme.surfaceContainerHighest);
      expect(bubble.radius, 16);
      expect(bubble.maxWidthFraction, 0.75);
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

    test('todos los presets compilan en ambos brillos', () {
      for (final entry in presetSpecs.entries) {
        final compiled = ThemeCompiler.compile(parse(entry.value));
        expect(compiled.light.extension<AlimBubbleStyle>(), isNotNull,
            reason: 'preset ${entry.key}');
        expect(compiled.dark.extension<AlimBubbleStyle>(), isNotNull,
            reason: 'preset ${entry.key}');
      }
    });
  });
}
