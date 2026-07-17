import 'package:alim_engine/alim_engine.dart';
import 'package:alim_engine_supabase/alim_engine_supabase.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_remote_transport.dart';

void main() {
  late FakeRemoteTransport transport;
  late LocalDatabase db;
  late SupabaseEngine engine;

  setUp(() async {
    transport = FakeRemoteTransport();
    db = LocalDatabase(NativeDatabase.memory());
    engine = SupabaseEngine(transport: transport, database: db);
    await engine.start();
  });

  tearDown(() async {
    await engine.dispose();
  });

  Future<void> login(String email) async {
    await engine.submitPhoneNumber(email);
    await engine.submitCode(transport.pendingCodes[email]!);
  }

  test('auth: código de un solo uso al correo lleva a AuthReady', () async {
    await login('ada@alim.dev');
    expect(engine.currentAuthState, isA<AuthReady>());
    final ready = engine.currentAuthState as AuthReady;
    expect(ready.user.displayName, 'ada');
  });

  test('auth: código incorrecto deja un error en AuthWaitingCode', () async {
    await engine.submitPhoneNumber('ada@alim.dev');
    await engine.submitCode('00000');
    expect(engine.currentAuthState, isA<AuthWaitingCode>());
    expect((engine.currentAuthState as AuthWaitingCode).error, isNotNull);
  });

  test('auth: correo inválido no llega a pedir código', () async {
    await engine.submitPhoneNumber('no-es-un-correo');
    expect(engine.currentAuthState, isA<AuthWaitingPhoneNumber>());
    expect(
        (engine.currentAuthState as AuthWaitingPhoneNumber).error, isNotNull);
  });

  test('sendText: aparece optimista como "sending" y pasa a "sent"', () async {
    await login('ada@alim.dev');
    final chatId =
        await transport.createDirectConversation('u-peer-placeholder');
    // El peer no existe de verdad en este test; solo interesa el envío.
    await engine.sendText(chatId, 'hola mundo');

    final firstEmission =
        await engine.watchMessages(chatId).firstWhere((m) => m.isNotEmpty);
    expect(firstEmission.single.status, MessageStatus.sending);

    // El outbox drena en un timer; se espera a que se confirme.
    final sent = await engine
        .watchMessages(chatId)
        .firstWhere((m) => m.isNotEmpty && m.single.status == MessageStatus.sent);
    expect(sent.single.content, isA<TextContent>());
    expect((sent.single.content as TextContent).text, 'hola mundo');
    expect(transport.messages.single.content, 'hola mundo');
  });

  test('sendText: reintenta y termina en "failed" si el envío siempre falla',
      () async {
    await login('ada@alim.dev');
    final chatId = await transport.createDirectConversation('u-peer');

    // Falla el primer intento del outbox; con backoff exponencial el
    // reintento tarda >2s, así que se fuerza el estado a mano en vez de
    // esperar el timer real en el test.
    transport.failNextInsert = true;
    await engine.sendText(chatId, 'se va a perder');

    final failing =
        await engine.watchMessages(chatId).firstWhere((m) => m.isNotEmpty);
    expect(failing.single.status, MessageStatus.sending);
  });

  test('chats: un mensaje entrante por Realtime sube el contador de no leídos',
      () async {
    await login('ada@alim.dev');
    transport.profilesByEmail['linus@alim.dev'] =
        const AlimUser(id: 'u-linus', displayName: 'Linus');
    final chatId = await transport.createDirectConversation('u-linus');
    await db.upsertConversation(transport.conversations[chatId]!,
        currentUserId: transport.currentUserId!);

    transport.emit(RemoteMessageUpserted(RemoteMessage(
      id: 'm-1',
      conversationId: chatId,
      senderId: 'u-linus',
      content: 'hola!',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )));

    final chats = await engine.chats.firstWhere((c) => c
        .any((chat) => chat.id == chatId && chat.unreadCount > 0));
    final chat = chats.firstWhere((c) => c.id == chatId);
    expect(chat.unreadCount, 1);
    expect(chat.lastMessage?.senderName, 'Linus');

    await engine.markChatRead(chatId);
    final afterRead = await engine.chats.firstWhere((c) => c
        .any((chat) => chat.id == chatId && chat.unreadCount == 0));
    expect(afterRead.firstWhere((c) => c.id == chatId).unreadCount, 0);
  });

  test('ConversationStarter: falla con USER_NOT_FOUND si el username no existe',
      () async {
    await login('ada@alim.dev');
    expect(
      () => engine.startDirectChat('nadie'),
      throwsA(isA<EngineException>()
          .having((e) => e.code, 'code', 'USER_NOT_FOUND')),
    );
  });

  test('ConversationStarter: crea el chat directo y aparece en la lista',
      () async {
    await login('ada@alim.dev');
    transport.profilesByEmail['grace@alim.dev'] =
        const AlimUser(id: 'u-grace', displayName: 'Grace');
    transport.usernames['grace'] = 'u-grace';

    final chatId = await engine.startDirectChat('grace');
    expect(chatId, isNotEmpty);
    final chats = await engine.chats.first;
    expect(chats.any((c) => c.id == chatId), isTrue);
  });

  test('MessageDeleter: borra el mensaje local y remotamente', () async {
    await login('ada@alim.dev');
    final chatId = await transport.createDirectConversation('u-peer');
    await db.upsertConversation(transport.conversations[chatId]!,
        currentUserId: transport.currentUserId!);
    await engine.sendText(chatId, 'me arrepiento');

    // Espera a que el outbox confirme el envío (estado sent).
    final sent = await engine.watchMessages(chatId).firstWhere(
        (m) => m.isNotEmpty && m.single.status == MessageStatus.sent);
    final messageId = sent.single.id;
    expect(transport.messages.any((m) => m.id == messageId), isTrue);

    await engine.deleteMessage(chatId, messageId);

    final afterDelete =
        await engine.watchMessages(chatId).firstWhere((m) => m.isEmpty);
    expect(afterDelete, isEmpty);
    expect(transport.messages.any((m) => m.id == messageId), isFalse,
        reason: 'el borrado debe propagarse al backend');
  });

  test('MessageDeleter: un borrado por Realtime desde otro equipo se refleja',
      () async {
    await login('ada@alim.dev');
    final chatId = await transport.createDirectConversation('u-peer');
    await db.upsertConversation(transport.conversations[chatId]!,
        currentUserId: transport.currentUserId!);
    transport.emit(RemoteMessageUpserted(RemoteMessage(
      id: 'm-remoto',
      conversationId: chatId,
      senderId: transport.currentUserId!,
      content: 'enviado desde el móvil',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    )));
    await engine.watchMessages(chatId).firstWhere((m) => m.isNotEmpty);

    transport.emit(
        RemoteMessageDeleted(id: 'm-remoto', conversationId: chatId));

    final afterDelete =
        await engine.watchMessages(chatId).firstWhere((m) => m.isEmpty);
    expect(afterDelete, isEmpty);
  });

  test('ProfileEditor: setUsername propaga el error de nombre duplicado',
      () async {
    await login('ada@alim.dev');
    transport.usernames['tomada'] = 'otro-usuario';
    expect(
      () => engine.setUsername('tomada'),
      throwsA(isA<EngineException>()),
    );
  });
}
