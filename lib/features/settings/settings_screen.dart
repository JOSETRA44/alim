import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/di.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
            onTap: () => engine.logOut(),
          ),
        ],
      ),
    );
  }
}
