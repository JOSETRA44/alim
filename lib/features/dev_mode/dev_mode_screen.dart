import 'package:alim_spec/alim_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_providers.dart';

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
            child: Wrap(
              spacing: 8,
              children: [
                for (final name in presetSpecs.keys)
                  ActionChip(
                    label: Text(name),
                    onPressed: () => _loadPreset(name),
                  ),
              ],
            ),
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
