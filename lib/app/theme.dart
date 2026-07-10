import 'package:flutter/material.dart';

/// Tema por defecto de ALIM: puramente funcional, plano y minimalista.
///
/// Transitorio a propósito: en el Hito 2 este archivo pasa a generarse desde
/// los design tokens del spec ALIM (alim_theme_engine). Ningún widget debe
/// hardcodear colores ni tamaños — siempre `Theme.of(context)`.
ThemeData alimTheme(Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: const Color(0xFF3D5A50),
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);

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
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        elevation: 0,
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      elevation: 0,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
