import 'package:alim_engine/alim_engine.dart';
import 'package:drift/drift.dart';

import '../remote/models.dart';

part 'database.g.dart';

/// Conversación cacheada. `title` ya viene resuelto (para chats directos,
/// el nombre del otro miembro) para no depender de joins reactivos en cada
/// build: se calcula una vez al escribir, igual que el theme engine resuelve
/// estilos en la fase de compilación en vez de en cada frame.
@DataClassName('LocalConversation')
class LocalConversations extends Table {
  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get title => text().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get lastMessageId => text().nullable()();
  TextColumn get lastMessagePreview => text().nullable()();
  TextColumn get lastMessageSenderId => text().nullable()();
  DateTimeColumn get lastMessageSentAt => dateTime().nullable()();
  IntColumn get unreadCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalMember')
class LocalMembers extends Table {
  TextColumn get conversationId => text()();
  TextColumn get userId => text()();
  TextColumn get displayName => text()();

  @override
  Set<Column> get primaryKey => {conversationId, userId};
}

@DataClassName('LocalMessage')
class LocalMessages extends Table {
  TextColumn get id => text()();
  TextColumn get conversationId => text()();
  TextColumn get senderId => text()();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Presencia de una fila = mensaje saliente pendiente de confirmar contra
/// Supabase. Se borra al confirmarse; [gaveUp] la deja como recordatorio de
/// fallo definitivo (ver `OutboxRetryPolicy`).
@DataClassName('LocalOutboxEntry')
class LocalOutbox extends Table {
  TextColumn get messageId => text()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get lastError => text().nullable()();
  BoolColumn get gaveUp => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {messageId};
}

@DataClassName('LocalSyncEntry')
class LocalSyncState extends Table {
  TextColumn get key => text()();
  DateTimeColumn get value => dateTime()();

  @override
  Set<Column> get primaryKey => {key};
}

/// Base de datos local (SQLite vía Drift): Única Fuente de Verdad de la UI.
/// `SyncEngine` es el único escritor desde la red; la UI solo observa las
/// queries `watch*` de aquí, funcionando offline y sin latencia de render.
@DriftDatabase(tables: [
  LocalConversations,
  LocalMembers,
  LocalMessages,
  LocalOutbox,
  LocalSyncState,
])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  // --- Lecturas reactivas (consumidas por SupabaseEngine) -------------------

  Stream<List<Chat>> watchChats(String currentUserId) {
    final query = select(localConversations).join([
      leftOuterJoin(
        localOutbox,
        localOutbox.messageId.equalsExp(localConversations.lastMessageId),
      ),
      leftOuterJoin(
        localMembers,
        localMembers.conversationId.equalsExp(localConversations.id) &
            localMembers.userId.equalsExp(localConversations.lastMessageSenderId),
      ),
    ])
      ..orderBy([OrderingTerm.desc(localConversations.updatedAt)]);

    return query.watch().map((rows) => [
          for (final row in rows)
            _chatFrom(
              row.readTable(localConversations),
              row.readTableOrNull(localOutbox),
              row.readTableOrNull(localMembers),
              currentUserId,
            ),
        ]);
  }

  Chat _chatFrom(
    LocalConversation conv,
    LocalOutboxEntry? outbox,
    LocalMember? lastSender,
    String currentUserId,
  ) {
    Message? last;
    if (conv.lastMessageId != null) {
      final isOutgoing = conv.lastMessageSenderId == currentUserId;
      last = Message(
        id: conv.lastMessageId!,
        chatId: conv.id,
        senderId: conv.lastMessageSenderId ?? '',
        senderName: isOutgoing ? null : lastSender?.displayName,
        content: TextContent(conv.lastMessagePreview ?? ''),
        sentAt: conv.lastMessageSentAt ?? conv.updatedAt,
        isOutgoing: isOutgoing,
        status: _statusOf(isOutgoing: isOutgoing, outbox: outbox),
      );
    }
    return Chat(
      id: conv.id,
      title: conv.title ?? '',
      kind: conv.kind == 'group' ? ChatKind.group : ChatKind.direct,
      lastMessage: last,
      unreadCount: conv.unreadCount,
    );
  }

  Stream<List<Message>> watchMessages(
      String conversationId, String currentUserId) {
    final query = select(localMessages).join([
      leftOuterJoin(
        localOutbox,
        localOutbox.messageId.equalsExp(localMessages.id),
      ),
      leftOuterJoin(
        localMembers,
        localMembers.conversationId.equalsExp(localMessages.conversationId) &
            localMembers.userId.equalsExp(localMessages.senderId),
      ),
    ])
      ..where(localMessages.conversationId.equals(conversationId))
      ..orderBy([OrderingTerm.asc(localMessages.createdAt)]);

    return query.watch().map((rows) => [
          for (final row in rows)
            _messageFrom(
              row.readTable(localMessages),
              row.readTableOrNull(localOutbox),
              row.readTableOrNull(localMembers),
              currentUserId,
            ),
        ]);
  }

  Message _messageFrom(
    LocalMessage msg,
    LocalOutboxEntry? outbox,
    LocalMember? sender,
    String currentUserId,
  ) {
    final isOutgoing = msg.senderId == currentUserId;
    return Message(
      id: msg.id,
      chatId: msg.conversationId,
      senderId: msg.senderId,
      senderName: isOutgoing ? null : sender?.displayName,
      content: TextContent(msg.content),
      sentAt: msg.createdAt,
      isOutgoing: isOutgoing,
      status: _statusOf(isOutgoing: isOutgoing, outbox: outbox),
    );
  }

  MessageStatus _statusOf({required bool isOutgoing, LocalOutboxEntry? outbox}) {
    if (!isOutgoing) return MessageStatus.delivered;
    if (outbox == null) return MessageStatus.sent;
    return outbox.gaveUp ? MessageStatus.failed : MessageStatus.sending;
  }

  Future<DateTime?> oldestMessageTime(String conversationId) async {
    final row = await (select(localMessages)
          ..where((t) => t.conversationId.equals(conversationId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
          ..limit(1))
        .getSingleOrNull();
    return row?.createdAt;
  }

  Future<LocalMessage?> messageById(String id) =>
      (select(localMessages)..where((t) => t.id.equals(id))).getSingleOrNull();

  // --- Escrituras desde el motor de sincronización ---------------------------

  Future<void> upsertConversation(
    RemoteConversation remote, {
    required String currentUserId,
  }) async {
    final existing = await (select(localConversations)
          ..where((t) => t.id.equals(remote.id)))
        .getSingleOrNull();

    final displayTitle = remote.kind == RemoteConversationKind.group
        ? remote.title
        : remote.memberNames.entries
            .firstWhere(
              (entry) => entry.key != currentUserId,
              orElse: () => MapEntry(currentUserId, remote.title ?? ''),
            )
            .value;

    await into(localConversations).insertOnConflictUpdate(
      LocalConversationsCompanion.insert(
        id: remote.id,
        kind: remote.kind == RemoteConversationKind.group ? 'group' : 'direct',
        title: Value(displayTitle),
        updatedAt: remote.updatedAt,
        lastMessageId: Value(existing?.lastMessageId),
        lastMessagePreview: Value(existing?.lastMessagePreview),
        lastMessageSenderId: Value(existing?.lastMessageSenderId),
        lastMessageSentAt: Value(existing?.lastMessageSentAt),
        unreadCount: Value(existing?.unreadCount ?? 0),
      ),
    );

    await (delete(localMembers)
          ..where((t) => t.conversationId.equals(remote.id)))
        .go();
    if (remote.memberNames.isNotEmpty) {
      await batch((b) => b.insertAll(localMembers, [
            for (final entry in remote.memberNames.entries)
              LocalMembersCompanion.insert(
                conversationId: remote.id,
                userId: entry.key,
                displayName: entry.value,
              ),
          ]));
    }
  }

  /// Aplica un mensaje remoto (delta-pull, Realtime o paginación de
  /// historial) idempotentemente: insertarlo dos veces con el mismo [id] es
  /// un no-op salvo por los campos que cambien.
  Future<void> applyIncomingMessage(
    RemoteMessage message, {
    required String currentUserId,
  }) async {
    final existing =
        await (select(localMessages)..where((t) => t.id.equals(message.id)))
            .getSingleOrNull();
    final isNew = existing == null;

    await into(localMessages).insertOnConflictUpdate(
      LocalMessagesCompanion.insert(
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        content: message.content,
        createdAt: message.createdAt,
        updatedAt: message.updatedAt,
      ),
    );

    final conv = await (select(localConversations)
          ..where((t) => t.id.equals(message.conversationId)))
        .getSingleOrNull();
    if (conv == null) return; // conversación aún no sincronizada.

    final isLatest = conv.lastMessageSentAt == null ||
        !message.createdAt.isBefore(conv.lastMessageSentAt!);

    await (update(localConversations)
          ..where((t) => t.id.equals(message.conversationId)))
        .write(LocalConversationsCompanion(
      updatedAt: Value(
          message.updatedAt.isAfter(conv.updatedAt) ? message.updatedAt : conv.updatedAt),
      lastMessageId: isLatest ? Value(message.id) : const Value.absent(),
      lastMessagePreview:
          isLatest ? Value(message.content) : const Value.absent(),
      lastMessageSenderId:
          isLatest ? Value(message.senderId) : const Value.absent(),
      lastMessageSentAt:
          isLatest ? Value(message.createdAt) : const Value.absent(),
      unreadCount: (isNew && message.senderId != currentUserId)
          ? Value(conv.unreadCount + 1)
          : const Value.absent(),
    ));
  }

  /// Borra un mensaje localmente y recalcula el "último mensaje" de la
  /// conversación si el borrado era el más reciente (para que la lista de
  /// chats no siga mostrando un mensaje que ya no existe).
  Future<void> deleteMessageLocal(String messageId) => transaction(() async {
        final msg = await messageById(messageId);
        if (msg == null) return;
        await (delete(localOutbox)..where((t) => t.messageId.equals(messageId)))
            .go();
        await (delete(localMessages)..where((t) => t.id.equals(messageId)))
            .go();

        final conv = await (select(localConversations)
              ..where((t) => t.id.equals(msg.conversationId)))
            .getSingleOrNull();
        if (conv == null || conv.lastMessageId != messageId) return;

        final newest = await (select(localMessages)
              ..where((t) => t.conversationId.equals(msg.conversationId))
              ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
              ..limit(1))
            .getSingleOrNull();
        await (update(localConversations)
              ..where((t) => t.id.equals(msg.conversationId)))
            .write(LocalConversationsCompanion(
          lastMessageId: Value(newest?.id),
          lastMessagePreview: Value(newest?.content),
          lastMessageSenderId: Value(newest?.senderId),
          lastMessageSentAt: Value(newest?.createdAt),
        ));
      });

  Future<void> enqueueOutgoing(Message message) async {
    final text = (message.content as TextContent).text;
    await into(localMessages).insertOnConflictUpdate(
      LocalMessagesCompanion.insert(
        id: message.id,
        conversationId: message.chatId,
        senderId: message.senderId,
        content: text,
        createdAt: message.sentAt,
        updatedAt: message.sentAt,
      ),
    );
    await into(localOutbox).insertOnConflictUpdate(
      LocalOutboxCompanion.insert(
        messageId: message.id,
        nextAttemptAt: DateTime.now(),
      ),
    );
    final conv = await (select(localConversations)
          ..where((t) => t.id.equals(message.chatId)))
        .getSingleOrNull();
    if (conv != null) {
      await (update(localConversations)
            ..where((t) => t.id.equals(message.chatId)))
          .write(LocalConversationsCompanion(
        updatedAt: Value(message.sentAt),
        lastMessageId: Value(message.id),
        lastMessagePreview: Value(text),
        lastMessageSenderId: Value(message.senderId),
        lastMessageSentAt: Value(message.sentAt),
      ));
    }
  }

  Future<List<LocalOutboxEntry>> duePendingOutbox() => (select(localOutbox)
        ..where((t) =>
            t.gaveUp.equals(false) &
            t.nextAttemptAt.isSmallerOrEqualValue(DateTime.now())))
      .get();

  Future<void> markOutboxSent(String messageId) =>
      (delete(localOutbox)..where((t) => t.messageId.equals(messageId))).go();

  Future<void> markOutboxRetry(
    String messageId, {
    required int attempts,
    required DateTime nextAttemptAt,
    required String error,
    required bool gaveUp,
  }) =>
      (update(localOutbox)..where((t) => t.messageId.equals(messageId)))
          .write(LocalOutboxCompanion(
        attempts: Value(attempts),
        nextAttemptAt: Value(nextAttemptAt),
        lastError: Value(error),
        gaveUp: Value(gaveUp),
      ));

  Future<void> markRead(String conversationId) =>
      (update(localConversations)..where((t) => t.id.equals(conversationId)))
          .write(const LocalConversationsCompanion(unreadCount: Value(0)));

  Future<DateTime?> syncCursor(String key) async {
    final row =
        await (select(localSyncState)..where((t) => t.key.equals(key)))
            .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSyncCursor(String key, DateTime value) =>
      into(localSyncState).insertOnConflictUpdate(
        LocalSyncStateCompanion.insert(key: key, value: value),
      );

  /// Borra TODO el contenido local. Se llama al cerrar sesión: los datos de
  /// la cuenta anterior no pueden sobrevivir en el dispositivo.
  ///
  /// Se vacían las tablas en vez de borrar el fichero (y su clave): la clave
  /// sigue custodiada por el SO y el mismo fichero cifrado se reutiliza
  /// para la siguiente sesión. Descartar la clave dejaría en disco un
  /// fichero que ya nadie podría reabrir.
  Future<void> wipe() => transaction(() async {
        await delete(localOutbox).go();
        await delete(localMessages).go();
        await delete(localMembers).go();
        await delete(localConversations).go();
        await delete(localSyncState).go();
      });
}
