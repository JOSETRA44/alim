import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'di.dart';
import 'router.dart';
import 'theme_providers.dart';

class AlimApp extends ConsumerStatefulWidget {
  const AlimApp({super.key});

  @override
  ConsumerState<AlimApp> createState() => _AlimAppState();
}

class _AlimAppState extends ConsumerState<AlimApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Mandato del plan: el ciclo de vida nativo gobierna los recursos del
    // motor (cero isolates zombie, presencia reducida en segundo plano).
    _lifecycle = AppLifecycleListener(
      onDetach: () => ref.read(engineProvider).dispose(),
      onPause: () => ref.read(engineProvider).setBackgrounded(true),
      onResume: () => ref.read(engineProvider).setBackgrounded(false),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
