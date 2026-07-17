import 'dart:io';

import 'package:alim_spec/alim_spec.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di.dart';
import '../../app/theme_providers.dart';
import 'inspector.dart';
import 'skill_export.dart';

const _engineLabels = {
  'mock': 'Motor simulado',
  'tdlib': 'Telegram (TDLib)',
  'supabase': 'ALIM nativo (Supabase)',
};

/// Modo Desarrollador v0: editor JSON del spec ALIM con hot-apply,
/// presets de fábrica y panel de avisos. En el Hito 4 suma layout,
/// expresiones, inspector y exportador de Skill.
class DevModeScreen extends ConsumerStatefulWidget {
  const DevModeScreen({super.key});

  @override
  ConsumerState<DevModeScreen> createState() => _DevModeScreenState();
}

class _DevModeScreenState extends ConsumerState<DevModeScreen> {
  late final TextEditingController _controller;
  List<SpecIssue> _issues = const [];

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: ref.read(themeProvider).specJson);
    _issues = ref.read(themeProvider).issues;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply() {
    final issues = ref.read(themeProvider.notifier).apply(_controller.text);
    setState(() => _issues = issues);
    if (!mounted) return;
    final fatal = issues.any((i) => i.severity == SpecSeverity.error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(fatal
            ? 'JSON inválido: no se aplicó ningún cambio'
            : issues.isEmpty
                ? 'Tema aplicado'
                : 'Tema aplicado con ${issues.length} aviso(s)'),
      ),
    );
  }

  void _loadPreset(String name) {
    _controller.text = presetSpecs[name]!;
    _apply();
  }

  void _reset() {
    _controller.text = defaultSpecJson;
    _apply();
  }

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  static const _themeTypeGroup =
      XTypeGroup(label: 'Tema ALIM', extensions: ['alim', 'json']);

  Future<void> _import() async {
    final file = await openFile(acceptedTypeGroups: const [_themeTypeGroup]);
    if (file == null) return;
    _controller.text = await file.readAsString();
    if (!mounted) return;
    _apply();
  }

  Future<void> _export() async {
    final location = await getSaveLocation(
      suggestedName: 'tema.alim',
      acceptedTypeGroups: const [_themeTypeGroup],
    );
    if (location == null) return;
    await File(location.path).writeAsString(_controller.text);
    _notify('Tema exportado');
  }

  /// Genera el paquete Skill para el agente de código del usuario.
  Future<void> _exportSkill() async {
    final location = await getSaveLocation(
      suggestedName: 'alim-theme-SKILL.md',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Markdown', extensions: ['md']),
      ],
    );
    if (location == null) return;
    final markdown = buildSkillMarkdown(
      currentSpecJson: ref.read(themeProvider).specJson,
    );
    await File(location.path).writeAsString(markdown);
    _notify('Skill exportada: entrégasela a tu agente de código');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modo Desarrollador'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restablecer tema por defecto',
            onPressed: _reset,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _EngineSelector(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final name in presetSpecs.keys)
                  ActionChip(
                    label: Text(name),
                    onPressed: () => _loadPreset(name),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.file_open_outlined),
                  tooltip: 'Importar .alim',
                  onPressed: _import,
                ),
                IconButton(
                  icon: const Icon(Icons.save_alt_outlined),
                  tooltip: 'Exportar .alim',
                  onPressed: _export,
                ),
                IconButton(
                  icon: const Icon(Icons.smart_toy_outlined),
                  tooltip: 'Exportar Skill para tu agente de código',
                  onPressed: _exportSkill,
                ),
              ],
            ),
          ),
          SwitchListTile(
            title: const Text('Inspector'),
            subtitle: const Text(
                'Toque largo sobre una burbuja para ver su ruta en el spec'),
            value: ref.watch(inspectorEnabledProvider),
            onChanged: (value) =>
                ref.read(inspectorEnabledProvider.notifier).set(value),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.5,
                ),
                decoration: const InputDecoration(
                  hintText: 'Spec ALIM (JSON)',
                ),
              ),
            ),
          ),
          if (_issues.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 120),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final issue in _issues)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            issue.severity == SpecSeverity.error
                                ? Icons.error_outline
                                : Icons.warning_amber_outlined,
                            size: 16,
                            color: issue.severity == SpecSeverity.error
                                ? theme.colorScheme.error
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${issue.path}: ${issue.message}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              icon: const Icon(Icons.bolt_outlined),
              label: const Text('Aplicar en caliente'),
              onPressed: _apply,
            ),
          ),
        ],
      ),
    );
  }
}

/// Cambia el motor de mensajería en runtime (sin recompilar): Riverpod
/// reconstruye [engineProvider], que hace dispose() del motor anterior y
/// start() del nuevo. El de Supabase se oculta si `main()` no encontró
/// credenciales (`ALIM_SUPABASE_URL`/`ALIM_SUPABASE_ANON_KEY`).
class _EngineSelector extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedEngineIdProvider);
    final supabaseAvailable = ref.watch(supabaseAvailableProvider);
    final ids = [
      for (final id in availableEngineIds)
        if (id != 'supabase' || supabaseAvailable) id,
    ];

    return SegmentedButton<String>(
      segments: [
        for (final id in ids)
          ButtonSegment(value: id, label: Text(_engineLabels[id] ?? id)),
      ],
      selected: {selected},
      onSelectionChanged: (next) =>
          ref.read(selectedEngineIdProvider.notifier).set(next.first),
    );
  }
}
