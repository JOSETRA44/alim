import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Estilo compilado de la burbuja de chat, disponible para los widgets como
/// `Theme.of(context).extension<AlimBubbleStyle>()`.
class AlimBubbleStyle extends ThemeExtension<AlimBubbleStyle> {
  const AlimBubbleStyle({
    required this.incoming,
    required this.outgoing,
    required this.radius,
    required this.tailRadius,
    required this.maxWidthFraction,
  });

  final Color incoming;
  final Color outgoing;
  final double radius;

  /// Radio de la esquina que "apunta" al emisor; igual a [radius] = sin cola.
  final double tailRadius;
  final double maxWidthFraction;

  @override
  AlimBubbleStyle copyWith({
    Color? incoming,
    Color? outgoing,
    double? radius,
    double? tailRadius,
    double? maxWidthFraction,
  }) =>
      AlimBubbleStyle(
        incoming: incoming ?? this.incoming,
        outgoing: outgoing ?? this.outgoing,
        radius: radius ?? this.radius,
        tailRadius: tailRadius ?? this.tailRadius,
        maxWidthFraction: maxWidthFraction ?? this.maxWidthFraction,
      );

  @override
  AlimBubbleStyle lerp(ThemeExtension<AlimBubbleStyle>? other, double t) {
    if (other is! AlimBubbleStyle) return this;
    return AlimBubbleStyle(
      incoming: Color.lerp(incoming, other.incoming, t)!,
      outgoing: Color.lerp(outgoing, other.outgoing, t)!,
      radius: lerpDouble(radius, other.radius, t)!,
      tailRadius: lerpDouble(tailRadius, other.tailRadius, t)!,
      maxWidthFraction:
          lerpDouble(maxWidthFraction, other.maxWidthFraction, t)!,
    );
  }
}
