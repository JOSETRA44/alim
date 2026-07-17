import 'package:alim_engine/alim_engine.dart';
import 'package:flutter/material.dart';

/// Estados vacío y de error, unificados para todas las pantallas.
///
/// Regla: al usuario NUNCA se le enseña una excepción cruda. Los errores de
/// dominio ([EngineException]) tienen un mensaje pensado para leerse; el
/// resto se degrada a un texto genérico y el detalle se queda en los logs.
class AlimPlaceholder extends StatelessWidget {
  const AlimPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  /// Construye el estado de error a partir de un error cualquiera.
  factory AlimPlaceholder.error(Object error, {VoidCallback? onRetry}) =>
      AlimPlaceholder(
        icon: Icons.cloud_off_outlined,
        title: 'Algo no ha ido bien',
        subtitle: error is EngineException
            ? error.message
            : 'No se pudo cargar el contenido. Inténtalo de nuevo.',
        action: onRetry == null
            ? null
            : _RetryAction(onRetry: onRetry),
      );

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryAction extends StatelessWidget {
  const _RetryAction({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => TextButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Reintentar'),
      );
}

/// Muestra un [EngineException] como snackbar; cualquier otro error se
/// reporta con un texto genérico (no se filtran detalles internos).
void showEngineError(BuildContext context, Object error) {
  final message = error is EngineException
      ? error.message
      : 'No se pudo completar la acción.';
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}
