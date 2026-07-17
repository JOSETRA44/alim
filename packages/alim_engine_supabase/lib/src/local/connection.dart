import 'dart:io';

import 'package:alim_keystore/alim_keystore.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart';

/// Identifica la clave de este motor dentro del almacén seguro del SO.
const driftKeyPurpose = 'drift';

/// Abre la BD local cifrada con SQLCipher.
///
/// La clave (32 bytes aleatorios) la custodia [keyStore]; se resuelve de
/// forma perezosa al abrir la BD, no al construir el motor. Se pasa a
/// SQLCipher como *raw key* en hexadecimal (`PRAGMA key = "x'...'"`): la
/// clave ya es aleatoria, así que no hace falta derivarla con PBKDF2 — y de
/// paso se evita cualquier problema de escapado de comillas.
///
/// Igual que el motor TDLib, el directorio se resuelve explícitamente con
/// `path_provider` y se crea antes de abrir nada.
QueryExecutor openEncryptedConnection(SecretKeyStore keyStore) {
  return LazyDatabase(() async {
    final key = await keyStore.keyFor(driftKeyPurpose);
    final pragma = 'PRAGMA key = "x\'${_hex(key)}\'";';

    final support = await getApplicationSupportDirectory();
    final folder = Directory(p.join(support.path, 'supabase_engine'));
    await folder.create(recursive: true);
    final file = File(p.join(folder.path, 'alim.sqlite'));

    return NativeDatabase.createInBackground(
      file,
      // `setup` corre DENTRO del isolate de la BD, así que la sustitución de
      // la librería nativa debe repetirse allí: el override de `open` es
      // por isolate, no global al proceso.
      isolateSetup: _useSqlCipher,
      setup: (rawDb) {
        rawDb.execute(pragma);
        assert(_assertCipherActive(rawDb));
      },
    );
  });
}

/// En Android conviven la libsqlite3 del sistema (sin cifrado) y la que trae
/// este paquete: hay que apuntar explícitamente a la segunda o el `PRAGMA
/// key` se ignoraría en silencio, dejando la BD en claro. En escritorio, el
/// plugin ya sustituye la librería que carga package:sqlite3.
void _useSqlCipher() {
  if (Platform.isAndroid) {
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  }
}

/// Solo en debug: confirma que la librería cargada ES SQLCipher. Sin esto,
/// un fallo en la carga nativa degradaría a SQLite normal y la BD quedaría
/// SIN CIFRAR sin que nadie se enterase.
bool _assertCipherActive(Database db) {
  final result = db.select('PRAGMA cipher_version;');
  if (result.isEmpty || '${result.first.values.first}'.isEmpty) {
    throw StateError(
      'SQLCipher no está activo: la BD local se habría escrito sin cifrar.',
    );
  }
  return true;
}

String _hex(Uint8List bytes) =>
    [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')].join();
