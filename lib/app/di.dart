import 'package:alim_engine/alim_engine.dart';
import 'package:alim_engine_mock/alim_engine_mock.dart';
import 'package:alim_engine_supabase/alim_engine_supabase.dart';
import 'package:alim_engine_tdlib/alim_engine_tdlib.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Motor por defecto al arrancar (dart-define); el selector del Dev Mode
/// permite cambiarlo en runtime sin recompilar:
///
///   flutter run -d windows --dart-define-from-file=env.local.json
const _defaultEngineId =
    String.fromEnvironment('ALIM_ENGINE', defaultValue: 'mock');
const _telegramApiId = int.fromEnvironment('ALIM_TELEGRAM_API_ID');
const _telegramApiHash = String.fromEnvironment('ALIM_TELEGRAM_API_HASH');
const _supabaseUrl = String.fromEnvironment('ALIM_SUPABASE_URL');

/// true si `main()` llamó a `Supabase.initialize` (hay credenciales).
final supabaseAvailableProvider = Provider<bool>((ref) => _supabaseUrl.isNotEmpty);

/// Todos los motores que la UI puede ofrecer en el selector, con su id
/// estable y nombre legible. El de Supabase se filtra si no hay
/// credenciales ([supabaseAvailableProvider]).
const availableEngineIds = ['mock', 'tdlib', 'supabase'];

class SelectedEngineId extends Notifier<String> {
  @override
  String build() => _defaultEngineId;

  void set(String id) => state = id;
}

final selectedEngineIdProvider =
    NotifierProvider<SelectedEngineId, String>(SelectedEngineId.new);

/// Motor activo. Único punto de la app que conoce implementaciones
/// concretas: cambiar de motor no toca ninguna feature. Al cambiar
/// [selectedEngineIdProvider], Riverpod reconstruye este provider —
/// dispose() del motor anterior y start() del nuevo son automáticos.
final engineProvider = Provider<MessagingEngine>((ref) {
  final id = ref.watch(selectedEngineIdProvider);
  final engine = switch (id) {
    'tdlib' => TdlibEngine.production(
        const TdlibConfig(apiId: _telegramApiId, apiHash: _telegramApiHash),
      ),
    'supabase' => SupabaseEngine.production(),
    _ => MockMessagingEngine(autoAuthenticate: false),
  };
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
