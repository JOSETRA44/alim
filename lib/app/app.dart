import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme_providers.dart';

class AlimApp extends ConsumerWidget {
  const AlimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider).compiled;
    return MaterialApp.router(
      title: 'ALIM',
      debugShowCheckedModeBanner: false,
      theme: theme.light,
      darkTheme: theme.dark,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
