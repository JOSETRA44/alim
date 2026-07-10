import 'package:alim_engine/alim_engine.dart';
import 'package:alim_engine_mock/alim_engine_mock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Motor activo. Único punto de la app que conoce implementaciones
/// concretas: cuando existan los motores TDLib y Supabase, el selector del
/// Dev Mode cambiará este provider sin tocar ninguna feature.
final engineProvider = Provider<MessagingEngine>((ref) {
  final engine = MockMessagingEngine(autoAuthenticate: false);
  ref.onDispose(engine.dispose);
  engine.start();
  return engine;
});

final authStateProvider = StreamProvider<AuthState>(
  (ref) => ref.watch(engineProvider).authStates,
);

final chatsProvider = StreamProvider<List<Chat>>(
  (ref) => ref.watch(engineProvider).chats,
);

final chatMessagesProvider = StreamProvider.family<List<Message>, String>(
  (ref, chatId) => ref.watch(engineProvider).watchMessages(chatId),
);
