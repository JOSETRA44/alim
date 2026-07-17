import 'package:alim_engine/alim_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';
import '../../common/states.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editUsername(BuildContext context, ProfileEditor editor) async {
    final controller = TextEditingController();
    final username = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nombre de usuario'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'p. ej. ada_lovelace'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (username == null || username.isEmpty || !context.mounted) return;
    try {
      await editor.setUsername(username);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ahora eres @$username')),
      );
    } catch (error) {
      if (!context.mounted) return;
      showEngineError(context, error);
    }
  }

  /// Cerrar sesión borra la sesión local del motor (y, en TDLib, el binlog):
  /// es destructivo e irreversible sin volver a autenticarse.
  Future<void> _confirmLogOut(
      BuildContext context, MessagingEngine engine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Cerrar sesión?'),
        content: Text(
          'Se cerrará tu sesión en ${engine.name} y se borrarán los datos '
          'de este dispositivo. Tendrás que volver a autenticarte.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await engine.logOut();
    } catch (error) {
      if (!context.mounted) return;
      showEngineError(context, error);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.memory_outlined),
            title: const Text('Motor de mensajería'),
            subtitle: Text(engine.name),
          ),
          if (engine case ProfileEditor editor) ...[
            const Divider(),
            ListTile(
              leading: const Icon(Icons.alternate_email),
              title: const Text('Nombre de usuario'),
              subtitle: const Text('Para que otros te encuentren e inicien chat'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _editUsername(context, editor),
            ),
          ],
          const Divider(),
          ListTile(
            leading: const Icon(Icons.code_outlined),
            title: const Text('Modo Desarrollador'),
            subtitle: const Text('Personaliza la interfaz en tiempo real'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/dev'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(Icons.logout,
                color: Theme.of(context).colorScheme.error),
            title: Text(
              'Cerrar sesión',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            onTap: () => _confirmLogOut(context, engine),
          ),
        ],
      ),
    );
  }
}
