import 'package:alim_spec/alim_spec.dart';
import 'package:flutter/material.dart';

import 'block_layout.dart';
import 'bubble_style.dart';

/// Tema compilado: dos [ThemeData] inmutables listos para MaterialApp.
/// Se construye UNA vez por apply; los builds de widgets solo leen.
class CompiledTheme {
  const CompiledTheme({
    required this.spec,
    required this.light,
    required this.dark,
  });

  final AlimSpec spec;
  final ThemeData light;
  final ThemeData dark;
}

/// Traductor spec ALIM → Flutter. Función pura: sin contexto ni estado.
class ThemeCompiler {
  const ThemeCompiler._();

  /// [issues] recoge problemas de compilación (expresiones inválidas,
  /// bloques desconocidos); el editor del Dev Mode los muestra junto a los
  /// del parser.
  static CompiledTheme compile(AlimSpec spec, {List<SpecIssue>? issues}) {
    final sink = issues ?? <SpecIssue>[];
    return CompiledTheme(
      spec: spec,
      light: _buildTheme(spec, Brightness.light, sink),
      dark: _buildTheme(spec, Brightness.dark, sink),
    );
  }

  static ThemeData _buildTheme(
      AlimSpec spec, Brightness brightness, List<SpecIssue> issues) {
    final tokens = spec.tokens;
    final scheme = _buildScheme(tokens.color, brightness);
    final shape = tokens.shape;

    var base = ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      fontFamily: tokens.typography.fontFamily,
      visualDensity:
          VisualDensity(horizontal: tokens.density, vertical: tokens.density),
    );
    if (tokens.typography.scale != 1.0) {
      // El textTheme de un ThemeData sin contexto no tiene geometría
      // resuelta (fontSize null): se fusiona la geometría M2021 primero para
      // que el factor quede fijado en el tema compilado (ThemeData.localize
      // da precedencia a nuestros valores).
      final effective =
          Typography.material2021().englishLike.merge(base.textTheme);
      base = base.copyWith(
        textTheme: _scaleTextTheme(effective, tokens.typography.scale),
      );
    }

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: false,
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(shape.medium),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(shape.medium),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shape.medium),
        ),
      ),
      extensions: [
        _buildBubbleTheme(spec, scheme, brightness, issues),
      ],
    );
  }

  /// Como TextTheme.apply, pero tolera estilos sin fontSize (los deja tal
  /// cual): el textTheme de un ThemeData construido sin contexto puede
  /// contener estilos aún sin geometría resuelta.
  static TextTheme _scaleTextTheme(TextTheme t, double factor) {
    TextStyle? scale(TextStyle? style) => style?.fontSize == null
        ? style
        : style!.apply(fontSizeFactor: factor);
    return TextTheme(
      displayLarge: scale(t.displayLarge),
      displayMedium: scale(t.displayMedium),
      displaySmall: scale(t.displaySmall),
      headlineLarge: scale(t.headlineLarge),
      headlineMedium: scale(t.headlineMedium),
      headlineSmall: scale(t.headlineSmall),
      titleLarge: scale(t.titleLarge),
      titleMedium: scale(t.titleMedium),
      titleSmall: scale(t.titleSmall),
      bodyLarge: scale(t.bodyLarge),
      bodyMedium: scale(t.bodyMedium),
      bodySmall: scale(t.bodySmall),
      labelLarge: scale(t.labelLarge),
      labelMedium: scale(t.labelMedium),
      labelSmall: scale(t.labelSmall),
    );
  }

  static ColorScheme _buildScheme(ColorTokens color, Brightness brightness) {
    var scheme = ColorScheme.fromSeed(
      seedColor: Color(color.seed),
      brightness: brightness,
    );
    final overrides = brightness == Brightness.light
        ? color.lightOverrides
        : color.darkOverrides;
    for (final entry in overrides.entries) {
      scheme = _applyRole(scheme, entry.key, Color(entry.value));
    }
    return scheme;
  }

  /// Aplica un override por nombre de rol. Los roles válidos ya fueron
  /// filtrados por el parser ([supportedColorRoles]).
  static ColorScheme _applyRole(ColorScheme s, String role, Color color) =>
      switch (role) {
        'primary' => s.copyWith(primary: color),
        'onPrimary' => s.copyWith(onPrimary: color),
        'primaryContainer' => s.copyWith(primaryContainer: color),
        'onPrimaryContainer' => s.copyWith(onPrimaryContainer: color),
        'secondary' => s.copyWith(secondary: color),
        'onSecondary' => s.copyWith(onSecondary: color),
        'secondaryContainer' => s.copyWith(secondaryContainer: color),
        'onSecondaryContainer' => s.copyWith(onSecondaryContainer: color),
        'tertiary' => s.copyWith(tertiary: color),
        'onTertiary' => s.copyWith(onTertiary: color),
        'tertiaryContainer' => s.copyWith(tertiaryContainer: color),
        'onTertiaryContainer' => s.copyWith(onTertiaryContainer: color),
        'error' => s.copyWith(error: color),
        'onError' => s.copyWith(onError: color),
        'errorContainer' => s.copyWith(errorContainer: color),
        'onErrorContainer' => s.copyWith(onErrorContainer: color),
        'surface' => s.copyWith(surface: color),
        'onSurface' => s.copyWith(onSurface: color),
        'onSurfaceVariant' => s.copyWith(onSurfaceVariant: color),
        'surfaceContainerLowest' => s.copyWith(surfaceContainerLowest: color),
        'surfaceContainerLow' => s.copyWith(surfaceContainerLow: color),
        'surfaceContainer' => s.copyWith(surfaceContainer: color),
        'surfaceContainerHigh' => s.copyWith(surfaceContainerHigh: color),
        'surfaceContainerHighest' =>
          s.copyWith(surfaceContainerHighest: color),
        'outline' => s.copyWith(outline: color),
        'outlineVariant' => s.copyWith(outlineVariant: color),
        'inverseSurface' => s.copyWith(inverseSurface: color),
        'onInverseSurface' => s.copyWith(onInverseSurface: color),
        'inversePrimary' => s.copyWith(inversePrimary: color),
        _ => s,
      };

  /// Construye la extensión de burbuja: expresiones compiladas UNA vez,
  /// resolver memoizado por clave finita, layout de bloques opcional.
  static AlimBubbleTheme _buildBubbleTheme(
    AlimSpec spec,
    ColorScheme scheme,
    Brightness brightness,
    List<SpecIssue> issues,
  ) {
    final raw = spec.components['chat_bubble'] ?? const {};
    // Solo se compilan issues una vez (los specs light/dark son idénticos).
    final sink = brightness == Brightness.light ? issues : <SpecIssue>[];

    final incoming =
        _colorSpec(raw['incoming'], 'components.chat_bubble.incoming', sink);
    final outgoing =
        _colorSpec(raw['outgoing'], 'components.chat_bubble.outgoing', sink);
    final radius = _resolveDouble(raw['radius'], min: 0, max: 48) ?? 16;
    final tailRadius = _resolveDouble(raw['tailRadius'], min: 0, max: 48) ?? 4;
    final maxWidthFraction =
        _resolveDouble(raw['maxWidthFraction'], min: 0.3, max: 1) ?? 0.75;

    final rawLayout = raw['layout'];
    final layout = rawLayout == null
        ? null
        : CompiledBlock.compile(rawLayout, sink,
            path: 'components.chat_bubble.layout');

    // Contexto de tokens visible para las expresiones de estilo.
    final tokensContext = <String, Object?>{
      'color': {
        'primary': _hexOf(scheme.primary),
        'primaryContainer': _hexOf(scheme.primaryContainer),
        'secondaryContainer': _hexOf(scheme.secondaryContainer),
        'tertiaryContainer': _hexOf(scheme.tertiaryContainer),
        'surface': _hexOf(scheme.surface),
        'surfaceContainerHighest': _hexOf(scheme.surfaceContainerHighest),
        'error': _hexOf(scheme.error),
        'errorContainer': _hexOf(scheme.errorContainer),
      },
    };

    final cache = <BubbleContextKey, AlimBubbleStyle>{};
    AlimBubbleStyle resolve(BubbleContextKey key) =>
        cache.putIfAbsent(key, () {
          final context = <String, Object?>{
            'message': {
              'isOutgoing': key.isOutgoing,
              'isRead': key.isRead,
              'isGroup': key.isGroup,
              'isFailed': key.isFailed,
            },
            'tokens': tokensContext,
          };
          final spec = key.isOutgoing ? outgoing : incoming;
          final background = spec.resolve(context, scheme) ??
              (key.isOutgoing
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest);
          return AlimBubbleStyle(
            background: background,
            radius: radius,
            tailRadius: tailRadius,
            maxWidthFraction: maxWidthFraction,
          );
        });

    return AlimBubbleTheme(resolve: resolve, layout: layout);
  }

  static String _hexOf(Color color) =>
      '#${color.toARGB32().toRadixString(16).padLeft(8, '0').toUpperCase()}';

  /// Valores de color en componentes: hex literal (`#RRGGBB`), referencia a
  /// rol (`@primaryContainer`) o expresión (`${...}`) que devuelve
  /// cualquiera de los dos.
  static _ColorSpec _colorSpec(
      Object? value, String path, List<SpecIssue> issues) {
    if (value is! String) return const _StaticColor(null);
    final trimmed = value.trim();
    if (trimmed.startsWith(r'${') && trimmed.endsWith('}')) {
      try {
        return _ExprColor(
            AlimExpression.compile(trimmed.substring(2, trimmed.length - 1)));
      } on ExpressionException catch (e) {
        issues.add(SpecIssue(SpecSeverity.warning, path, e.message));
        return const _StaticColor(null);
      }
    }
    final color = _literalColor(trimmed, null);
    if (color == null && !trimmed.startsWith('@')) {
      issues.add(SpecIssue(
          SpecSeverity.warning, path, 'Color inválido, se usa el default'));
    }
    return _StaticColor(trimmed);
  }

  /// Convierte un string ya evaluado (hex o `@role`) a Color.
  static Color? _literalColor(String value, ColorScheme? scheme) {
    if (value.startsWith('@')) {
      return scheme == null ? null : _roleValue(scheme, value.substring(1));
    }
    final argb = parseHexColor(value);
    return argb == null ? null : Color(argb);
  }

  static Color? _roleValue(ColorScheme s, String role) => switch (role) {
        'primary' => s.primary,
        'onPrimary' => s.onPrimary,
        'primaryContainer' => s.primaryContainer,
        'onPrimaryContainer' => s.onPrimaryContainer,
        'secondary' => s.secondary,
        'secondaryContainer' => s.secondaryContainer,
        'tertiary' => s.tertiary,
        'tertiaryContainer' => s.tertiaryContainer,
        'surface' => s.surface,
        'onSurface' => s.onSurface,
        'surfaceContainer' => s.surfaceContainer,
        'surfaceContainerHigh' => s.surfaceContainerHigh,
        'surfaceContainerHighest' => s.surfaceContainerHighest,
        'outline' => s.outline,
        'error' => s.error,
        'errorContainer' => s.errorContainer,
        _ => null,
      };

  static double? _resolveDouble(Object? value,
      {required double min, required double max}) {
    if (value is! num) return null;
    final result = value.toDouble();
    return result < min || result > max ? null : result;
  }
}

/// Valor de color de componente ya compilado: literal o expresión.
sealed class _ColorSpec {
  const _ColorSpec();

  Color? resolve(ExprContext context, ColorScheme scheme);
}

class _StaticColor extends _ColorSpec {
  const _StaticColor(this.value);

  final String? value;

  @override
  Color? resolve(ExprContext context, ColorScheme scheme) =>
      value == null ? null : ThemeCompiler._literalColor(value!, scheme);
}

class _ExprColor extends _ColorSpec {
  const _ExprColor(this.expression);

  final AlimExpression expression;

  @override
  Color? resolve(ExprContext context, ColorScheme scheme) {
    try {
      final result = expression.evaluate(context);
      return result is String
          ? ThemeCompiler._literalColor(result, scheme)
          : null;
    } on ExpressionException {
      // Fail-safe: una expresión rota degrada al color por defecto.
      return null;
    }
  }
}
