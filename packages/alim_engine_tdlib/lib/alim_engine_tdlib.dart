/// Adaptador TDLib de ALIM.
///
/// Arquitectura:
/// - [TdClient] es el transporte abstracto (peticiones + stream de eventos);
///   la lógica del motor no sabe de FFI y es testeable con un fake.
/// - [TdFfiClient] es el transporte real: interfaz JSON de TDLib vía
///   dart:ffi. `td_send` es thread-safe y se llama desde el isolate
///   principal; un isolate dedicado ejecuta el loop bloqueante `td_receive`.
/// - [TdlibEngine] implementa `MessagingEngine` (dominio) sobre el
///   transporte: máquina de estados de auth, stores de chats/mensajes.
library;

export 'src/client/td_client.dart';
export 'src/client/td_ffi_client.dart';
export 'src/config.dart';
export 'src/tdlib_engine.dart';
