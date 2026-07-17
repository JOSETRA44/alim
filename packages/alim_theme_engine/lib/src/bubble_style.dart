import 'package:flutter/material.dart';

import 'block_layout.dart';

/// Estilo resuelto de una burbuja concreta: datos inmutables listos para
/// pintar, sin ninguna evaluación pendiente.
class AlimBubbleStyle {
  const AlimBubbleStyle({
    required this.background,
    required this.radius,
    required this.tailRadius,
    required this.maxWidthFraction,
  });

  final Color background;
  final double radius;

  /// Radio de la esquina que "apunta" al emisor; igual a [radius] = sin cola.
  final double tailRadius;
  final double maxWidthFraction;
}

/// Clave de contexto FINITA para memoizar estilos por mensaje.
///
/// Las expresiones de estilo solo ven estos campos (dominio pequeño y
/// acotado); así cada combinación se evalúa UNA vez por tema aplicado y el
/// scroll nunca re-evalúa nada (mandato anti-jank). El texto del mensaje u
/// otros campos abiertos NO participan en estilos de color.
@immutable
class BubbleContextKey {
  const BubbleContextKey({
    required this.isOutgoing,
    required this.isRead,
    required this.isGroup,
    required this.isFailed,
  });

  final bool isOutgoing;
  final bool isRead;
  final bool isGroup;
  final bool isFailed;

  @override
  bool operator ==(Object other) =>
      other is BubbleContextKey &&
      other.isOutgoing == isOutgoing &&
      other.isRead == isRead &&
      other.isGroup == isGroup &&
      other.isFailed == isFailed;

  @override
  int get hashCode => Object.hash(isOutgoing, isRead, isGroup, isFailed);
}

/// Extensión de tema con el estilo de burbuja compilado.
///
/// [resolve] es un closure memoizado construido por el compilador: la
/// primera consulta de una clave evalúa las expresiones compiladas; las
/// siguientes son un lookup en un HashMap.
class AlimBubbleTheme extends ThemeExtension<AlimBubbleTheme> {
  const AlimBubbleTheme({required this.resolve, this.layout});

  final AlimBubbleStyle Function(BubbleContextKey key) resolve;

  /// Layout de bloques del interior de la burbuja (null = layout nativo).
  final CompiledBlock? layout;

  @override
  AlimBubbleTheme copyWith({
    AlimBubbleStyle Function(BubbleContextKey key)? resolve,
    CompiledBlock? layout,
  }) =>
      AlimBubbleTheme(
        resolve: resolve ?? this.resolve,
        layout: layout ?? this.layout,
      );

  @override
  AlimBubbleTheme lerp(ThemeExtension<AlimBubbleTheme>? other, double t) =>
      // Los resolvers no se interpolan; el cambio de tema es un corte.
      t < 0.5 ? this : (other is AlimBubbleTheme ? other : this);
}
