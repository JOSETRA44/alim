import 'package:flutter/material.dart';

/// Placeholder del Modo Desarrollador. En el Hito 2 se convierte en el
/// editor de tokens ALIM con hot-apply; en el Hito 4 suma layout,
/// expresiones, inspector y exportador de Skill.
class DevModeScreen extends StatelessWidget {
  const DevModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Modo Desarrollador')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_outlined,
                  size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                'Aquí vivirá el editor ALIM: tokens, layout y expresiones '
                'aplicados en caliente sobre la interfaz.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
