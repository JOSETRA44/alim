/// Dominio puro de ALIM: entidades y el contrato [MessagingEngine].
///
/// Regla arquitectónica: la UI y la gestión de estado dependen SOLO de este
/// paquete. Ninguna implementación (TDLib, Supabase, Mock) se filtra aquí.
library;

export 'package:alim_core/alim_core.dart' show EngineException;

export 'src/capabilities.dart';
export 'src/messaging_engine.dart';
export 'src/models/auth_state.dart';
export 'src/models/chat.dart';
export 'src/models/message.dart';
export 'src/models/user.dart';
