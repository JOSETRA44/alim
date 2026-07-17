import 'dart:io';

import 'package:alim_engine_supabase/alim_engine_supabase.dart';
import 'package:alim_keystore/alim_keystore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Verificación de que el cifrado en reposo es REAL, no solo configurado.
///
/// Tiene que correr como test de integración (sobre la app compilada) y no
/// como test unitario: la librería nativa de SQLCipher solo se carga desde
/// el binario con los plugins enlazados. Un `flutter test` normal abriría la
/// SQLite del sistema y pasaría en verde con la BD sin cifrar.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late File dbFile;

  setUp(() async {
    final support = await getApplicationSupportDirectory();
    dbFile = File(p.join(support.path, 'supabase_engine', 'alim.sqlite'));
    if (dbFile.existsSync()) dbFile.deleteSync();
  });

  testWidgets('la BD local queda cifrada en disco', (tester) async {
    const secreto = 'CANARIO-EN-CLARO-SI-ESTO-FALLA';

    final db = LocalDatabase(openEncryptedConnection(InMemoryKeyStore()));
    await db.applyIncomingMessage(
      RemoteMessage(
        id: 'm-1',
        conversationId: 'c-1',
        senderId: 'u-1',
        content: secreto,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      currentUserId: 'u-yo',
    );
    // Se cierra para que todo esté volcado a disco antes de inspeccionarlo.
    await db.close();

    expect(dbFile.existsSync(), isTrue, reason: 'la BD debería existir');
    final bytes = await dbFile.readAsBytes();

    // 1. Una SQLite sin cifrar empieza por la cabecera "SQLite format 3".
    final header = String.fromCharCodes(bytes.take(15));
    expect(header, isNot('SQLite format 3'),
        reason: 'la cabecera en claro significa que NO se cifró nada');

    // 2. El texto del mensaje no puede aparecer literalmente en el fichero.
    final asLatin1 = String.fromCharCodes(bytes);
    expect(asLatin1.contains(secreto), isFalse,
        reason: 'el contenido del mensaje está en claro en disco');
  });

  testWidgets('la BD cifrada se puede reabrir con la misma clave',
      (tester) async {
    final keyStore = InMemoryKeyStore();

    final first = LocalDatabase(openEncryptedConnection(keyStore));
    await first.applyIncomingMessage(
      RemoteMessage(
        id: 'm-1',
        conversationId: 'c-1',
        senderId: 'u-1',
        content: 'persiste',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      currentUserId: 'u-yo',
    );
    await first.close();

    final reopened = LocalDatabase(openEncryptedConnection(keyStore));
    final message = await reopened.messageById('m-1');
    await reopened.close();

    expect(message?.content, 'persiste');
  });
}
