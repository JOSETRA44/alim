/// Motor "uchat native" de ALIM: Drift (SQLite) como Única Fuente de
/// Verdad, Supabase restringido a una capa de sync en background
/// (outbox/Realtime/delta-pull). Mismo contrato `MessagingEngine` que
/// TDLib y el motor simulado.
library;

export 'src/local/connection.dart' show openEncryptedConnection, driftKeyPurpose;
export 'src/local/database.dart' show LocalDatabase;
export 'src/remote/models.dart';
export 'src/remote/remote_transport.dart';
export 'src/remote/supabase_remote_transport.dart';
export 'src/supabase_engine.dart';
