import 'package:flutter/material.dart';

/// Avatar con iniciales y color estable derivado del id.
/// Sin imágenes remotas en el Hito 1; los motores reales añadirán avatarUrl.
class AlimAvatar extends StatelessWidget {
  const AlimAvatar({super.key, required this.id, required this.title, this.radius = 24});

  final String id;
  final String title;
  final double radius;

  static const _hues = [12.0, 48.0, 96.0, 156.0, 200.0, 260.0, 310.0];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hue = _hues[id.hashCode.abs() % _hues.length];
    final background = HSLColor.fromAHSL(
      1,
      hue,
      0.35,
      theme.brightness == Brightness.dark ? 0.35 : 0.75,
    ).toColor();

    final initials = title
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();

    return CircleAvatar(
      radius: radius,
      backgroundColor: background,
      child: Text(
        initials,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
