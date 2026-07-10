import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme.dart';

class AlimApp extends ConsumerWidget {
  const AlimApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'ALIM',
      debugShowCheckedModeBanner: false,
      theme: alimTheme(Brightness.light),
      darkTheme: alimTheme(Brightness.dark),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
