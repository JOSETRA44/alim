import 'dart:convert';

import 'issues.dart';
import 'spec.dart';

/// Resultado de parsear un spec. [spec] es null solo ante errores fatales
/// (JSON ilegible); cualquier otro problema degrada a defaults + issue.
class SpecParseResult {
  const SpecParseResult(this.spec, this.issues);

  final AlimSpec? spec;
  final List<SpecIssue> issues;

  bool get hasErrors =>
      issues.any((issue) => issue.severity == SpecSeverity.error);
}

/// Parser fail-safe del formato ALIM.
class AlimSpecParser {
  AlimSpecParser._(this._issues);

  final List<SpecIssue> _issues;

  static SpecParseResult parse(String source) {
    final issues = <SpecIssue>[];
    Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      return SpecParseResult(null, [
        SpecIssue(SpecSeverity.error, r'$', 'JSON inválido: ${e.message}'),
      ]);
    }
    if (decoded is! Map<String, Object?>) {
      return SpecParseResult(null, [
        const SpecIssue(
            SpecSeverity.error, r'$', 'El documento debe ser un objeto JSON'),
      ]);
    }
    final parser = AlimSpecParser._(issues);
    return SpecParseResult(parser._parseRoot(decoded), issues);
  }

  AlimSpec _parseRoot(Map<String, Object?> root) {
    const knownKeys = {'alim', 'meta', 'tokens', 'components'};
    for (final key in root.keys) {
      if (!knownKeys.contains(key)) {
        _warn(key, 'Clave desconocida, ignorada');
      }
    }

    final version = root['alim'];
    if (version is! String) {
      _warn('alim', 'Falta la versión del formato; se asume $alimSpecVersion');
    } else if (version != alimSpecVersion) {
      _warn('alim',
          'Versión "$version" distinta de $alimSpecVersion; se interpreta lo mejor posible');
    }

    return AlimSpec(
      version: version is String ? version : alimSpecVersion,
      meta: _parseMeta(_map(root, 'meta')),
      tokens: _parseTokens(_map(root, 'tokens')),
      components: _parseComponents(_map(root, 'components')),
    );
  }

  SpecMeta _parseMeta(Map<String, Object?> meta) => SpecMeta(
        name: _string(meta, 'meta', 'name') ?? 'Sin nombre',
        author: _string(meta, 'meta', 'author'),
      );

  AlimTokens _parseTokens(Map<String, Object?> tokens) {
    final color = _map(tokens, 'color');
    final typography = _map(tokens, 'typography');
    final shape = _map(tokens, 'shape');
    final radius = _map(shape, 'radius');
    final spacing = _map(tokens, 'spacing');

    return AlimTokens(
      color: ColorTokens(
        seed: _color(color['seed'], 'tokens.color.seed') ?? 0xFF3D5A50,
        lightOverrides: _palette(_map(color, 'light'), 'tokens.color.light'),
        darkOverrides: _palette(_map(color, 'dark'), 'tokens.color.dark'),
      ),
      typography: TypographyTokens(
        fontFamily: _string(typography, 'tokens.typography', 'fontFamily'),
        scale: _number(typography['scale'], 'tokens.typography.scale',
                min: 0.5, max: 2.0) ??
            1.0,
      ),
      shape: ShapeTokens(
        small: _number(radius['sm'], 'tokens.shape.radius.sm',
                min: 0, max: 48) ??
            8,
        medium: _number(radius['md'], 'tokens.shape.radius.md',
                min: 0, max: 48) ??
            12,
        large: _number(radius['lg'], 'tokens.shape.radius.lg',
                min: 0, max: 48) ??
            16,
      ),
      spacingUnit: _number(spacing['unit'], 'tokens.spacing.unit',
              min: 2, max: 24) ??
          8,
      density: _number(tokens['density'], 'tokens.density', min: -2, max: 0) ??
          0,
    );
  }

  Map<String, int> _palette(Map<String, Object?> raw, String path) {
    final palette = <String, int>{};
    for (final entry in raw.entries) {
      if (!supportedColorRoles.contains(entry.key)) {
        _warn('$path.${entry.key}', 'Rol de color desconocido, ignorado');
        continue;
      }
      final value = _color(entry.value, '$path.${entry.key}');
      if (value != null) palette[entry.key] = value;
    }
    return palette;
  }

  Map<String, Map<String, Object?>> _parseComponents(
      Map<String, Object?> raw) {
    final components = <String, Map<String, Object?>>{};
    for (final entry in raw.entries) {
      final value = entry.value;
      if (value is Map<String, Object?>) {
        components[entry.key] = value;
      } else {
        _warn('components.${entry.key}', 'Debe ser un objeto, ignorado');
      }
    }
    return components;
  }

  // --- Helpers de lectura tolerante ----------------------------------------

  Map<String, Object?> _map(Map<String, Object?> parent, String key) {
    final value = parent[key];
    if (value == null) return const {};
    if (value is Map<String, Object?>) return value;
    _warn(key, 'Debe ser un objeto; se ignora');
    return const {};
  }

  String? _string(Map<String, Object?> parent, String path, String key) {
    final value = parent[key];
    if (value == null) return null;
    if (value is String) return value;
    _warn('$path.$key', 'Debe ser texto; se ignora');
    return null;
  }

  double? _number(Object? value, String path,
      {required double min, required double max}) {
    if (value == null) return null;
    if (value is! num) {
      _warn(path, 'Debe ser un número; se usa el valor por defecto');
      return null;
    }
    final result = value.toDouble();
    if (result < min || result > max) {
      _warn(path, 'Fuera de rango [$min, $max]; se usa el valor por defecto');
      return null;
    }
    return result;
  }

  /// Colores en formato `#RRGGBB` o `#AARRGGBB`.
  int? _color(Object? value, String path) {
    if (value == null) return null;
    final parsed = parseHexColor(value);
    if (parsed == null) {
      _warn(path, 'Color inválido (usa #RRGGBB o #AARRGGBB)');
    }
    return parsed;
  }

  void _warn(String path, String message) =>
      _issues.add(SpecIssue(SpecSeverity.warning, path, message));
}

/// Convierte `#RRGGBB` / `#AARRGGBB` a int ARGB; null si es inválido.
int? parseHexColor(Object? value) {
  if (value is! String) return null;
  final hex = value.startsWith('#') ? value.substring(1) : null;
  if (hex == null || (hex.length != 6 && hex.length != 8)) return null;
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return hex.length == 6 ? 0xFF000000 | parsed : parsed;
}
