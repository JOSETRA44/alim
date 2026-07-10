/// Versión del formato que entiende este parser.
const alimSpecVersion = '0.1';

/// Roles de color de Material 3 que un spec puede sobreescribir por nombre.
const supportedColorRoles = {
  'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
  'secondary', 'onSecondary', 'secondaryContainer', 'onSecondaryContainer',
  'tertiary', 'onTertiary', 'tertiaryContainer', 'onTertiaryContainer',
  'error', 'onError', 'errorContainer', 'onErrorContainer',
  'surface', 'onSurface', 'onSurfaceVariant',
  'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer',
  'surfaceContainerHigh', 'surfaceContainerHighest',
  'outline', 'outlineVariant',
  'inverseSurface', 'onInverseSurface', 'inversePrimary',
};

/// Documento ALIM parseado y validado. Inmutable: la fase de compilación
/// (alim_theme_engine) lo traduce una sola vez a objetos de Flutter.
class AlimSpec {
  const AlimSpec({
    required this.version,
    required this.meta,
    required this.tokens,
    this.components = const {},
  });

  final String version;
  final SpecMeta meta;
  final AlimTokens tokens;

  /// Overrides por componente registrado (`chat_bubble`, ...). Se mantienen
  /// como mapas crudos: el registro de componentes del theme engine decide
  /// qué claves entiende (render fail-safe para el resto).
  final Map<String, Map<String, Object?>> components;
}

class SpecMeta {
  const SpecMeta({required this.name, this.author});

  final String name;
  final String? author;
}

class AlimTokens {
  const AlimTokens({
    required this.color,
    this.typography = const TypographyTokens(),
    this.shape = const ShapeTokens(),
    this.spacingUnit = 8,
    this.density = 0,
  });

  final ColorTokens color;
  final TypographyTokens typography;
  final ShapeTokens shape;
  final double spacingUnit;

  /// Densidad visual (-2 compacto ... 0 estándar), mapea a VisualDensity.
  final double density;
}

/// Colores como int ARGB (este paquete no puede usar dart:ui).
class ColorTokens {
  const ColorTokens({
    required this.seed,
    this.lightOverrides = const {},
    this.darkOverrides = const {},
  });

  /// Semilla desde la que se deriva el ColorScheme completo.
  final int seed;

  /// Overrides puntuales por rol (ver [supportedColorRoles]).
  final Map<String, int> lightOverrides;
  final Map<String, int> darkOverrides;
}

class TypographyTokens {
  const TypographyTokens({this.fontFamily, this.scale = 1.0});

  /// Familia instalada en el sistema; null = fuente por defecto.
  final String? fontFamily;

  /// Factor multiplicador de todos los tamaños de texto.
  final double scale;
}

class ShapeTokens {
  const ShapeTokens({this.small = 8, this.medium = 12, this.large = 16});

  final double small;
  final double medium;
  final double large;
}
