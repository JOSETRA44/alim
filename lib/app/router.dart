import 'dart:async';

import 'package:alim_engine/alim_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/auth_flow_screen.dart';
import '../features/chat/chat_screen.dart';
import '../features/chats/chats_screen.dart';
import '../features/dev_mode/dev_mode_screen.dart';
import '../features/settings/settings_screen.dart';
import 'di.dart';

/// Adapta el stream de auth a un [Listenable] para el refresh del router.
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<AuthState> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final engine = ref.watch(engineProvider);
  final refresh = _AuthRefresh(engine.authStates);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    refreshListenable: refresh,
    initialLocation: '/',
    redirect: (context, state) {
      final authenticated = engine.currentAuthState is AuthReady;
      final inAuth = state.matchedLocation == '/auth';
      if (!authenticated && !inAuth) return '/auth';
      if (authenticated && inAuth) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthFlowScreen()),
      GoRoute(
        path: '/',
        builder: (context, state) => const ChatsScreen(),
        routes: [
          GoRoute(
            path: 'chat/:id',
            builder: (context, state) =>
                ChatScreen(chatId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'dev',
            builder: (context, state) => const DevModeScreen(),
          ),
        ],
      ),
    ],
  );
});
