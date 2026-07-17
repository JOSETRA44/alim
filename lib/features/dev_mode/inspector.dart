import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme_providers.dart';

/// Modo inspector del Dev Mode: activado, un toque largo sobre un componente
/// personalizable muestra su ruta en el spec ALIM y su fragmento JSON.
class InspectorNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool enabled) => state = enabled;
}

final inspectorEnabledProvider =
    NotifierProvider<InspectorNotifier, bool>(InspectorNotifier.new);

/// Envuelve un componente personalizable y lo hace inspeccionable.
class SpecInspectable extends ConsumerWidget {
  const SpecInspectable({
    super.key,
    required this.path,
    required this.child,
    this.details,
  });

  /// Ruta del componente dentro del spec, p. ej. `components.chat_bubble`.
  final String path;

  /// Valores resueltos que ayudan a entender el render actual.
  final String? details;

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(inspectorEnabledProvider);
    if (!enabled) return child;

    return GestureDetector(
      onLongPress: () => _showSheet(context, ref),
      child: child,
    );
  }

  void _showSheet(BuildContext context, WidgetRef ref) {
    final specJson = ref.read(themeProvider).specJson;
    String fragment;
    try {
      Object? node = jsonDecode(specJson);
      for (final part in path.split('.')) {
        node = (node as Map<String, Object?>)[part];
      }
      fragment = node == null
          ? '(sin overrides: se usan los valores por defecto)'
          : const JsonEncoder.withIndent('  ').convert(node);
    } catch (_) {
      fragment = '(no se pudo extraer el fragmento)';
    }

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Inspector ALIM', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(path,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontFamily: 'monospace',
                      color: theme.colorScheme.primary,
                    )),
                if (details != null) ...[
                  const SizedBox(height: 4),
                  Text(details!,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: SelectableText(
                      fragment,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
