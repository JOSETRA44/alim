import 'dart:io';

import 'package:alim_core/alim_core.dart';
import 'package:alim_spec/alim_spec.dart';
import 'package:alim_theme_engine/alim_theme_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

/// Estado del tema activo: el JSON fuente, su compilación y los avisos
/// del último parseo (mostrados en el editor del Dev Mode).
class ThemeState {
  const ThemeState({
    required this.specJson,
    required this.compiled,
    this.issues = const [],
  });

  final String specJson;
  final CompiledTheme compiled;
  final List<SpecIssue> issues;
}

/// Orquestador del hot-apply. La compilación ocurre aquí, UNA vez por
/// apply; los widgets solo leen el resultado vía Theme.of.
class ThemeNotifier extends Notifier<ThemeState> {
  static final _log = AlimLogger('ThemeNotifier');
  static const _fileName = 'alim_theme.json';

  @override
  ThemeState build() {
    // El default de fábrica siempre compila; el tema persistido (si existe)
    // llega de forma asíncrona justo después.
    Future.microtask(_loadPersisted);
    return _compileState(defaultSpecJson)!;
  }

  /// Aplica [specJson] en caliente. Devuelve los issues de parseo Y de
  /// compilación (expresiones/bloques inválidos); si el JSON es fatal
  /// (ilegible) no se aplica nada.
  List<SpecIssue> apply(String specJson) {
    final next = _compileState(specJson);
    if (next == null) return AlimSpecParser.parse(specJson).issues;
    state = next;
    _persist(specJson);
    return next.issues;
  }

  void reset() => apply(defaultSpecJson);

  ThemeState? _compileState(String specJson) {
    final result = AlimSpecParser.parse(specJson);
    final spec = result.spec;
    if (spec == null) return null;
    final compileIssues = <SpecIssue>[];
    final compiled = ThemeCompiler.compile(spec, issues: compileIssues);
    return ThemeState(
      specJson: specJson,
      compiled: compiled,
      issues: [...result.issues, ...compileIssues],
    );
  }

  // La persistencia es best-effort: sin plugin (tests) o sin disco, la app
  // sigue funcionando con el tema en memoria.
  Future<File?> _themeFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}${Platform.pathSeparator}$_fileName');
  }

  Future<void> _loadPersisted() async {
    try {
      final file = await _themeFile();
      if (file == null || !await file.exists()) return;
      final compiled = _compileState(await file.readAsString());
      if (compiled != null) state = compiled;
    } catch (e) {
      _log.warning('no se pudo cargar el tema persistido: $e');
    }
  }

  Future<void> _persist(String specJson) async {
    try {
      final file = await _themeFile();
      await file?.writeAsString(specJson);
    } catch (e) {
      _log.warning('no se pudo persistir el tema: $e');
    }
  }
}

final themeProvider =
    NotifierProvider<ThemeNotifier, ThemeState>(ThemeNotifier.new);
