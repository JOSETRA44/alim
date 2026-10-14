import 'package:alim_engine_supabase/alim_engine_supabase.dart';
import 'package:alim_engine_supabase/src/sync/sync_engine.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_remote_transport.dart';

void main() {
  late FakeRemoteTransport transport;
  late LocalDatabase db;

  setUp(() async {
    transport = FakeRemoteTransport();
    db = LocalDatabase(NativeDatabase.memory());
    await transport.requestEmailCode('ada@alim.dev');
    await transport.verifyEmailCode('ada@alim.dev', '11111');
  });

  tearDown(() async {
    await db.close();
  });

  // Espera a que el delta-pull de una sesión de sync termine de aplicar.
  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 50));

  Future<void> runSyncSession(String userId) async {
    final sync =
        SyncEngine(db: db, transport: transport, currentUserId: userId);
    await sync.start();
    await settle();
    sync.dispose();
  }

  test(
      'regresión: el cursor avanza en tiempo-servidor y no pierde mensajes '
      'aunque el reloj del cliente adelante', () async {
    final userId = transport.currentUserId!;
    final chatId = await transport.createDirectConversation('u-peer');
    await db.upsertConversation(transport.conversations[chatId]!,
        currentUserId: userId);

    // El reloj del SERVIDOR va por detrás del cliente (deriva típica): todos
    // los updated_at sembrados están claramente en el pasado respecto a
    // DateTime.now() del cliente. Segundos enteros para no chocar con el
    // truncado a segundos de Drift.
    final serverNow = DateTime(2026, 1, 1, 12, 0, 0);

    // Mensaje 1: presente en la primera sesión de sync.
    transport.messages.add(RemoteMessage(
      id: 'm1',
      conversationId: chatId,
      senderId: 'u-peer',
      content: 'primero',
      createdAt: serverNow,
      updatedAt: serverNow,
    ));

    await runSyncSession(userId); // primer arranque de la app

    // Con el bug, el cursor quedaría en DateTime.now() del cliente (muy por
    // delante del servidor). El mensaje 2, sellado por el servidor ANTES de
    // ese now pero DESPUÉS del mensaje 1, caería bajo el cursor y se perdería.
    final serverLater = serverNow.add(const Duration(seconds: 30));
    transport.messages.add(RemoteMessage(
      id: 'm2',
      conversationId: chatId,
      senderId: 'u-peer',
      content: 'segundo',
      createdAt: serverLater,
      updatedAt: serverLater,
    ));

    await runSyncSession(userId); // segundo arranque

    expect(await db.messageById('m1'), isNotNull);
    expect(await db.messageById('m2'), isNotNull,
        reason: 'el mensaje 2 no debe perderse por deriva de reloj');
  });

  test('el cursor no retrocede si un pull no trae nada nuevo', () async {
    final userId = transport.currentUserId!;
    final chatId = await transport.createDirectConversation('u-peer');
    await db.upsertConversation(transport.conversations[chatId]!,
        currentUserId: userId);

    final t = DateTime(2026, 1, 1, 11, 55, 0);
    transport.messages.add(RemoteMessage(
      id: 'm1',
      conversationId: chatId,
      senderId: 'u-peer',
      content: 'uno',
      createdAt: t,
      updatedAt: t,
    ));

    await runSyncSession(userId);
    expect(await db.syncCursor('messages'), t);

    // Segundo pull sin mensajes nuevos: el cursor se queda donde estaba.
    await runSyncSession(userId);
    expect(await db.syncCursor('messages'), t);
  });
}
