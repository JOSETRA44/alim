// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $LocalConversationsTable extends LocalConversations
    with TableInfo<$LocalConversationsTable, LocalConversation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalConversationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastMessageIdMeta = const VerificationMeta(
    'lastMessageId',
  );
  @override
  late final GeneratedColumn<String> lastMessageId = GeneratedColumn<String>(
    'last_message_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastMessagePreviewMeta =
      const VerificationMeta('lastMessagePreview');
  @override
  late final GeneratedColumn<String> lastMessagePreview =
      GeneratedColumn<String>(
        'last_message_preview',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageSenderIdMeta =
      const VerificationMeta('lastMessageSenderId');
  @override
  late final GeneratedColumn<String> lastMessageSenderId =
      GeneratedColumn<String>(
        'last_message_sender_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _lastMessageSentAtMeta = const VerificationMeta(
    'lastMessageSentAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastMessageSentAt =
      GeneratedColumn<DateTime>(
        'last_message_sent_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _unreadCountMeta = const VerificationMeta(
    'unreadCount',
  );
  @override
  late final GeneratedColumn<int> unreadCount = GeneratedColumn<int>(
    'unread_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    kind,
    title,
    updatedAt,
    lastMessageId,
    lastMessagePreview,
    lastMessageSenderId,
    lastMessageSentAt,
    unreadCount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_conversations';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalConversation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_message_id')) {
      context.handle(
        _lastMessageIdMeta,
        lastMessageId.isAcceptableOrUnknown(
          data['last_message_id']!,
          _lastMessageIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_preview')) {
      context.handle(
        _lastMessagePreviewMeta,
        lastMessagePreview.isAcceptableOrUnknown(
          data['last_message_preview']!,
          _lastMessagePreviewMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sender_id')) {
      context.handle(
        _lastMessageSenderIdMeta,
        lastMessageSenderId.isAcceptableOrUnknown(
          data['last_message_sender_id']!,
          _lastMessageSenderIdMeta,
        ),
      );
    }
    if (data.containsKey('last_message_sent_at')) {
      context.handle(
        _lastMessageSentAtMeta,
        lastMessageSentAt.isAcceptableOrUnknown(
          data['last_message_sent_at']!,
          _lastMessageSentAtMeta,
        ),
      );
    }
    if (data.containsKey('unread_count')) {
      context.handle(
        _unreadCountMeta,
        unreadCount.isAcceptableOrUnknown(
          data['unread_count']!,
          _unreadCountMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalConversation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalConversation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastMessageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_id'],
      ),
      lastMessagePreview: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_preview'],
      ),
      lastMessageSenderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_message_sender_id'],
      ),
      lastMessageSentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_message_sent_at'],
      ),
      unreadCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unread_count'],
      )!,
    );
  }

  @override
  $LocalConversationsTable createAlias(String alias) {
    return $LocalConversationsTable(attachedDatabase, alias);
  }
}

class LocalConversation extends DataClass
    implements Insertable<LocalConversation> {
  final String id;
  final String kind;
  final String? title;
  final DateTime updatedAt;
  final String? lastMessageId;
  final String? lastMessagePreview;
  final String? lastMessageSenderId;
  final DateTime? lastMessageSentAt;
  final int unreadCount;
  const LocalConversation({
    required this.id,
    required this.kind,
    this.title,
    required this.updatedAt,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageSenderId,
    this.lastMessageSentAt,
    required this.unreadCount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastMessageId != null) {
      map['last_message_id'] = Variable<String>(lastMessageId);
    }
    if (!nullToAbsent || lastMessagePreview != null) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview);
    }
    if (!nullToAbsent || lastMessageSenderId != null) {
      map['last_message_sender_id'] = Variable<String>(lastMessageSenderId);
    }
    if (!nullToAbsent || lastMessageSentAt != null) {
      map['last_message_sent_at'] = Variable<DateTime>(lastMessageSentAt);
    }
    map['unread_count'] = Variable<int>(unreadCount);
    return map;
  }

  LocalConversationsCompanion toCompanion(bool nullToAbsent) {
    return LocalConversationsCompanion(
      id: Value(id),
      kind: Value(kind),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      updatedAt: Value(updatedAt),
      lastMessageId: lastMessageId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageId),
      lastMessagePreview: lastMessagePreview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessagePreview),
      lastMessageSenderId: lastMessageSenderId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSenderId),
      lastMessageSentAt: lastMessageSentAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastMessageSentAt),
      unreadCount: Value(unreadCount),
    );
  }

  factory LocalConversation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalConversation(
      id: serializer.fromJson<String>(json['id']),
      kind: serializer.fromJson<String>(json['kind']),
      title: serializer.fromJson<String?>(json['title']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastMessageId: serializer.fromJson<String?>(json['lastMessageId']),
      lastMessagePreview: serializer.fromJson<String?>(
        json['lastMessagePreview'],
      ),
      lastMessageSenderId: serializer.fromJson<String?>(
        json['lastMessageSenderId'],
      ),
      lastMessageSentAt: serializer.fromJson<DateTime?>(
        json['lastMessageSentAt'],
      ),
      unreadCount: serializer.fromJson<int>(json['unreadCount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'kind': serializer.toJson<String>(kind),
      'title': serializer.toJson<String?>(title),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastMessageId': serializer.toJson<String?>(lastMessageId),
      'lastMessagePreview': serializer.toJson<String?>(lastMessagePreview),
      'lastMessageSenderId': serializer.toJson<String?>(lastMessageSenderId),
      'lastMessageSentAt': serializer.toJson<DateTime?>(lastMessageSentAt),
      'unreadCount': serializer.toJson<int>(unreadCount),
    };
  }

  LocalConversation copyWith({
    String? id,
    String? kind,
    Value<String?> title = const Value.absent(),
    DateTime? updatedAt,
    Value<String?> lastMessageId = const Value.absent(),
    Value<String?> lastMessagePreview = const Value.absent(),
    Value<String?> lastMessageSenderId = const Value.absent(),
    Value<DateTime?> lastMessageSentAt = const Value.absent(),
    int? unreadCount,
  }) => LocalConversation(
    id: id ?? this.id,
    kind: kind ?? this.kind,
    title: title.present ? title.value : this.title,
    updatedAt: updatedAt ?? this.updatedAt,
    lastMessageId: lastMessageId.present
        ? lastMessageId.value
        : this.lastMessageId,
    lastMessagePreview: lastMessagePreview.present
        ? lastMessagePreview.value
        : this.lastMessagePreview,
    lastMessageSenderId: lastMessageSenderId.present
        ? lastMessageSenderId.value
        : this.lastMessageSenderId,
    lastMessageSentAt: lastMessageSentAt.present
        ? lastMessageSentAt.value
        : this.lastMessageSentAt,
    unreadCount: unreadCount ?? this.unreadCount,
  );
  LocalConversation copyWithCompanion(LocalConversationsCompanion data) {
    return LocalConversation(
      id: data.id.present ? data.id.value : this.id,
      kind: data.kind.present ? data.kind.value : this.kind,
      title: data.title.present ? data.title.value : this.title,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastMessageId: data.lastMessageId.present
          ? data.lastMessageId.value
          : this.lastMessageId,
      lastMessagePreview: data.lastMessagePreview.present
          ? data.lastMessagePreview.value
          : this.lastMessagePreview,
      lastMessageSenderId: data.lastMessageSenderId.present
          ? data.lastMessageSenderId.value
          : this.lastMessageSenderId,
      lastMessageSentAt: data.lastMessageSentAt.present
          ? data.lastMessageSentAt.value
          : this.lastMessageSentAt,
      unreadCount: data.unreadCount.present
          ? data.unreadCount.value
          : this.unreadCount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalConversation(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageSentAt: $lastMessageSentAt, ')
          ..write('unreadCount: $unreadCount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    title,
    updatedAt,
    lastMessageId,
    lastMessagePreview,
    lastMessageSenderId,
    lastMessageSentAt,
    unreadCount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalConversation &&
          other.id == this.id &&
          other.kind == this.kind &&
          other.title == this.title &&
          other.updatedAt == this.updatedAt &&
          other.lastMessageId == this.lastMessageId &&
          other.lastMessagePreview == this.lastMessagePreview &&
          other.lastMessageSenderId == this.lastMessageSenderId &&
          other.lastMessageSentAt == this.lastMessageSentAt &&
          other.unreadCount == this.unreadCount);
}

class LocalConversationsCompanion extends UpdateCompanion<LocalConversation> {
  final Value<String> id;
  final Value<String> kind;
  final Value<String?> title;
  final Value<DateTime> updatedAt;
  final Value<String?> lastMessageId;
  final Value<String?> lastMessagePreview;
  final Value<String?> lastMessageSenderId;
  final Value<DateTime?> lastMessageSentAt;
  final Value<int> unreadCount;
  final Value<int> rowid;
  const LocalConversationsCompanion({
    this.id = const Value.absent(),
    this.kind = const Value.absent(),
    this.title = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastMessageId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageSentAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalConversationsCompanion.insert({
    required String id,
    required String kind,
    this.title = const Value.absent(),
    required DateTime updatedAt,
    this.lastMessageId = const Value.absent(),
    this.lastMessagePreview = const Value.absent(),
    this.lastMessageSenderId = const Value.absent(),
    this.lastMessageSentAt = const Value.absent(),
    this.unreadCount = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       kind = Value(kind),
       updatedAt = Value(updatedAt);
  static Insertable<LocalConversation> custom({
    Expression<String>? id,
    Expression<String>? kind,
    Expression<String>? title,
    Expression<DateTime>? updatedAt,
    Expression<String>? lastMessageId,
    Expression<String>? lastMessagePreview,
    Expression<String>? lastMessageSenderId,
    Expression<DateTime>? lastMessageSentAt,
    Expression<int>? unreadCount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (kind != null) 'kind': kind,
      if (title != null) 'title': title,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastMessageId != null) 'last_message_id': lastMessageId,
      if (lastMessagePreview != null)
        'last_message_preview': lastMessagePreview,
      if (lastMessageSenderId != null)
        'last_message_sender_id': lastMessageSenderId,
      if (lastMessageSentAt != null) 'last_message_sent_at': lastMessageSentAt,
      if (unreadCount != null) 'unread_count': unreadCount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalConversationsCompanion copyWith({
    Value<String>? id,
    Value<String>? kind,
    Value<String?>? title,
    Value<DateTime>? updatedAt,
    Value<String?>? lastMessageId,
    Value<String?>? lastMessagePreview,
    Value<String?>? lastMessageSenderId,
    Value<DateTime?>? lastMessageSentAt,
    Value<int>? unreadCount,
    Value<int>? rowid,
  }) {
    return LocalConversationsCompanion(
      id: id ?? this.id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageId: lastMessageId ?? this.lastMessageId,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      lastMessageSentAt: lastMessageSentAt ?? this.lastMessageSentAt,
      unreadCount: unreadCount ?? this.unreadCount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastMessageId.present) {
      map['last_message_id'] = Variable<String>(lastMessageId.value);
    }
    if (lastMessagePreview.present) {
      map['last_message_preview'] = Variable<String>(lastMessagePreview.value);
    }
    if (lastMessageSenderId.present) {
      map['last_message_sender_id'] = Variable<String>(
        lastMessageSenderId.value,
      );
    }
    if (lastMessageSentAt.present) {
      map['last_message_sent_at'] = Variable<DateTime>(lastMessageSentAt.value);
    }
    if (unreadCount.present) {
      map['unread_count'] = Variable<int>(unreadCount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalConversationsCompanion(')
          ..write('id: $id, ')
          ..write('kind: $kind, ')
          ..write('title: $title, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastMessageId: $lastMessageId, ')
          ..write('lastMessagePreview: $lastMessagePreview, ')
          ..write('lastMessageSenderId: $lastMessageSenderId, ')
          ..write('lastMessageSentAt: $lastMessageSentAt, ')
          ..write('unreadCount: $unreadCount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMembersTable extends LocalMembers
    with TableInfo<$LocalMembersTable, LocalMember> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMembersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [conversationId, userId, displayName];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_members';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMember> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conversationId, userId};
  @override
  LocalMember map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMember(
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
    );
  }

  @override
  $LocalMembersTable createAlias(String alias) {
    return $LocalMembersTable(attachedDatabase, alias);
  }
}

class LocalMember extends DataClass implements Insertable<LocalMember> {
  final String conversationId;
  final String userId;
  final String displayName;
  const LocalMember({
    required this.conversationId,
    required this.userId,
    required this.displayName,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conversation_id'] = Variable<String>(conversationId);
    map['user_id'] = Variable<String>(userId);
    map['display_name'] = Variable<String>(displayName);
    return map;
  }

  LocalMembersCompanion toCompanion(bool nullToAbsent) {
    return LocalMembersCompanion(
      conversationId: Value(conversationId),
      userId: Value(userId),
      displayName: Value(displayName),
    );
  }

  factory LocalMember.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMember(
      conversationId: serializer.fromJson<String>(json['conversationId']),
      userId: serializer.fromJson<String>(json['userId']),
      displayName: serializer.fromJson<String>(json['displayName']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conversationId': serializer.toJson<String>(conversationId),
      'userId': serializer.toJson<String>(userId),
      'displayName': serializer.toJson<String>(displayName),
    };
  }

  LocalMember copyWith({
    String? conversationId,
    String? userId,
    String? displayName,
  }) => LocalMember(
    conversationId: conversationId ?? this.conversationId,
    userId: userId ?? this.userId,
    displayName: displayName ?? this.displayName,
  );
  LocalMember copyWithCompanion(LocalMembersCompanion data) {
    return LocalMember(
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      userId: data.userId.present ? data.userId.value : this.userId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMember(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(conversationId, userId, displayName);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMember &&
          other.conversationId == this.conversationId &&
          other.userId == this.userId &&
          other.displayName == this.displayName);
}

class LocalMembersCompanion extends UpdateCompanion<LocalMember> {
  final Value<String> conversationId;
  final Value<String> userId;
  final Value<String> displayName;
  final Value<int> rowid;
  const LocalMembersCompanion({
    this.conversationId = const Value.absent(),
    this.userId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMembersCompanion.insert({
    required String conversationId,
    required String userId,
    required String displayName,
    this.rowid = const Value.absent(),
  }) : conversationId = Value(conversationId),
       userId = Value(userId),
       displayName = Value(displayName);
  static Insertable<LocalMember> custom({
    Expression<String>? conversationId,
    Expression<String>? userId,
    Expression<String>? displayName,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conversationId != null) 'conversation_id': conversationId,
      if (userId != null) 'user_id': userId,
      if (displayName != null) 'display_name': displayName,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMembersCompanion copyWith({
    Value<String>? conversationId,
    Value<String>? userId,
    Value<String>? displayName,
    Value<int>? rowid,
  }) {
    return LocalMembersCompanion(
      conversationId: conversationId ?? this.conversationId,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMembersCompanion(')
          ..write('conversationId: $conversationId, ')
          ..write('userId: $userId, ')
          ..write('displayName: $displayName, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMessagesTable extends LocalMessages
    with TableInfo<$LocalMessagesTable, LocalMessage> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMessagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _conversationIdMeta = const VerificationMeta(
    'conversationId',
  );
  @override
  late final GeneratedColumn<String> conversationId = GeneratedColumn<String>(
    'conversation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _senderIdMeta = const VerificationMeta(
    'senderId',
  );
  @override
  late final GeneratedColumn<String> senderId = GeneratedColumn<String>(
    'sender_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    conversationId,
    senderId,
    content,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_messages';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMessage> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('conversation_id')) {
      context.handle(
        _conversationIdMeta,
        conversationId.isAcceptableOrUnknown(
          data['conversation_id']!,
          _conversationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_conversationIdMeta);
    }
    if (data.containsKey('sender_id')) {
      context.handle(
        _senderIdMeta,
        senderId.isAcceptableOrUnknown(data['sender_id']!, _senderIdMeta),
      );
    } else if (isInserting) {
      context.missing(_senderIdMeta);
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMessage map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMessage(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      conversationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conversation_id'],
      )!,
      senderId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sender_id'],
      )!,
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMessagesTable createAlias(String alias) {
    return $LocalMessagesTable(attachedDatabase, alias);
  }
}

class LocalMessage extends DataClass implements Insertable<LocalMessage> {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['conversation_id'] = Variable<String>(conversationId);
    map['sender_id'] = Variable<String>(senderId);
    map['content'] = Variable<String>(content);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMessagesCompanion toCompanion(bool nullToAbsent) {
    return LocalMessagesCompanion(
      id: Value(id),
      conversationId: Value(conversationId),
      senderId: Value(senderId),
      content: Value(content),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMessage.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMessage(
      id: serializer.fromJson<String>(json['id']),
      conversationId: serializer.fromJson<String>(json['conversationId']),
      senderId: serializer.fromJson<String>(json['senderId']),
      content: serializer.fromJson<String>(json['content']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'conversationId': serializer.toJson<String>(conversationId),
      'senderId': serializer.toJson<String>(senderId),
      'content': serializer.toJson<String>(content),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? content,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalMessage(
    id: id ?? this.id,
    conversationId: conversationId ?? this.conversationId,
    senderId: senderId ?? this.senderId,
    content: content ?? this.content,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMessage copyWithCompanion(LocalMessagesCompanion data) {
    return LocalMessage(
      id: data.id.present ? data.id.value : this.id,
      conversationId: data.conversationId.present
          ? data.conversationId.value
          : this.conversationId,
      senderId: data.senderId.present ? data.senderId.value : this.senderId,
      content: data.content.present ? data.content.value : this.content,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessage(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, conversationId, senderId, content, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMessage &&
          other.id == this.id &&
          other.conversationId == this.conversationId &&
          other.senderId == this.senderId &&
          other.content == this.content &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalMessagesCompanion extends UpdateCompanion<LocalMessage> {
  final Value<String> id;
  final Value<String> conversationId;
  final Value<String> senderId;
  final Value<String> content;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMessagesCompanion({
    this.id = const Value.absent(),
    this.conversationId = const Value.absent(),
    this.senderId = const Value.absent(),
    this.content = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMessagesCompanion.insert({
    required String id,
    required String conversationId,
    required String senderId,
    required String content,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       conversationId = Value(conversationId),
       senderId = Value(senderId),
       content = Value(content),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<LocalMessage> custom({
    Expression<String>? id,
    Expression<String>? conversationId,
    Expression<String>? senderId,
    Expression<String>? content,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (conversationId != null) 'conversation_id': conversationId,
      if (senderId != null) 'sender_id': senderId,
      if (content != null) 'content': content,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMessagesCompanion copyWith({
    Value<String>? id,
    Value<String>? conversationId,
    Value<String>? senderId,
    Value<String>? content,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMessagesCompanion(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (conversationId.present) {
      map['conversation_id'] = Variable<String>(conversationId.value);
    }
    if (senderId.present) {
      map['sender_id'] = Variable<String>(senderId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMessagesCompanion(')
          ..write('id: $id, ')
          ..write('conversationId: $conversationId, ')
          ..write('senderId: $senderId, ')
          ..write('content: $content, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalOutboxTable extends LocalOutbox
    with TableInfo<$LocalOutboxTable, LocalOutboxEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalOutboxTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _messageIdMeta = const VerificationMeta(
    'messageId',
  );
  @override
  late final GeneratedColumn<String> messageId = GeneratedColumn<String>(
    'message_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _attemptsMeta = const VerificationMeta(
    'attempts',
  );
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
    'attempts',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _nextAttemptAtMeta = const VerificationMeta(
    'nextAttemptAt',
  );
  @override
  late final GeneratedColumn<DateTime> nextAttemptAt =
      GeneratedColumn<DateTime>(
        'next_attempt_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _gaveUpMeta = const VerificationMeta('gaveUp');
  @override
  late final GeneratedColumn<bool> gaveUp = GeneratedColumn<bool>(
    'gave_up',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("gave_up" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    messageId,
    attempts,
    nextAttemptAt,
    lastError,
    gaveUp,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalOutboxEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('message_id')) {
      context.handle(
        _messageIdMeta,
        messageId.isAcceptableOrUnknown(data['message_id']!, _messageIdMeta),
      );
    } else if (isInserting) {
      context.missing(_messageIdMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(
        _attemptsMeta,
        attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta),
      );
    }
    if (data.containsKey('next_attempt_at')) {
      context.handle(
        _nextAttemptAtMeta,
        nextAttemptAt.isAcceptableOrUnknown(
          data['next_attempt_at']!,
          _nextAttemptAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_nextAttemptAtMeta);
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('gave_up')) {
      context.handle(
        _gaveUpMeta,
        gaveUp.isAcceptableOrUnknown(data['gave_up']!, _gaveUpMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {messageId};
  @override
  LocalOutboxEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalOutboxEntry(
      messageId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}message_id'],
      )!,
      attempts: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempts'],
      )!,
      nextAttemptAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}next_attempt_at'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      gaveUp: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}gave_up'],
      )!,
    );
  }

  @override
  $LocalOutboxTable createAlias(String alias) {
    return $LocalOutboxTable(attachedDatabase, alias);
  }
}

class LocalOutboxEntry extends DataClass
    implements Insertable<LocalOutboxEntry> {
  final String messageId;
  final int attempts;
  final DateTime nextAttemptAt;
  final String? lastError;
  final bool gaveUp;
  const LocalOutboxEntry({
    required this.messageId,
    required this.attempts,
    required this.nextAttemptAt,
    this.lastError,
    required this.gaveUp,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['message_id'] = Variable<String>(messageId);
    map['attempts'] = Variable<int>(attempts);
    map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['gave_up'] = Variable<bool>(gaveUp);
    return map;
  }

  LocalOutboxCompanion toCompanion(bool nullToAbsent) {
    return LocalOutboxCompanion(
      messageId: Value(messageId),
      attempts: Value(attempts),
      nextAttemptAt: Value(nextAttemptAt),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      gaveUp: Value(gaveUp),
    );
  }

  factory LocalOutboxEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalOutboxEntry(
      messageId: serializer.fromJson<String>(json['messageId']),
      attempts: serializer.fromJson<int>(json['attempts']),
      nextAttemptAt: serializer.fromJson<DateTime>(json['nextAttemptAt']),
      lastError: serializer.fromJson<String?>(json['lastError']),
      gaveUp: serializer.fromJson<bool>(json['gaveUp']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'messageId': serializer.toJson<String>(messageId),
      'attempts': serializer.toJson<int>(attempts),
      'nextAttemptAt': serializer.toJson<DateTime>(nextAttemptAt),
      'lastError': serializer.toJson<String?>(lastError),
      'gaveUp': serializer.toJson<bool>(gaveUp),
    };
  }

  LocalOutboxEntry copyWith({
    String? messageId,
    int? attempts,
    DateTime? nextAttemptAt,
    Value<String?> lastError = const Value.absent(),
    bool? gaveUp,
  }) => LocalOutboxEntry(
    messageId: messageId ?? this.messageId,
    attempts: attempts ?? this.attempts,
    nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
    lastError: lastError.present ? lastError.value : this.lastError,
    gaveUp: gaveUp ?? this.gaveUp,
  );
  LocalOutboxEntry copyWithCompanion(LocalOutboxCompanion data) {
    return LocalOutboxEntry(
      messageId: data.messageId.present ? data.messageId.value : this.messageId,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
      nextAttemptAt: data.nextAttemptAt.present
          ? data.nextAttemptAt.value
          : this.nextAttemptAt,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      gaveUp: data.gaveUp.present ? data.gaveUp.value : this.gaveUp,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxEntry(')
          ..write('messageId: $messageId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('gaveUp: $gaveUp')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(messageId, attempts, nextAttemptAt, lastError, gaveUp);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalOutboxEntry &&
          other.messageId == this.messageId &&
          other.attempts == this.attempts &&
          other.nextAttemptAt == this.nextAttemptAt &&
          other.lastError == this.lastError &&
          other.gaveUp == this.gaveUp);
}

class LocalOutboxCompanion extends UpdateCompanion<LocalOutboxEntry> {
  final Value<String> messageId;
  final Value<int> attempts;
  final Value<DateTime> nextAttemptAt;
  final Value<String?> lastError;
  final Value<bool> gaveUp;
  final Value<int> rowid;
  const LocalOutboxCompanion({
    this.messageId = const Value.absent(),
    this.attempts = const Value.absent(),
    this.nextAttemptAt = const Value.absent(),
    this.lastError = const Value.absent(),
    this.gaveUp = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalOutboxCompanion.insert({
    required String messageId,
    this.attempts = const Value.absent(),
    required DateTime nextAttemptAt,
    this.lastError = const Value.absent(),
    this.gaveUp = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : messageId = Value(messageId),
       nextAttemptAt = Value(nextAttemptAt);
  static Insertable<LocalOutboxEntry> custom({
    Expression<String>? messageId,
    Expression<int>? attempts,
    Expression<DateTime>? nextAttemptAt,
    Expression<String>? lastError,
    Expression<bool>? gaveUp,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (messageId != null) 'message_id': messageId,
      if (attempts != null) 'attempts': attempts,
      if (nextAttemptAt != null) 'next_attempt_at': nextAttemptAt,
      if (lastError != null) 'last_error': lastError,
      if (gaveUp != null) 'gave_up': gaveUp,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalOutboxCompanion copyWith({
    Value<String>? messageId,
    Value<int>? attempts,
    Value<DateTime>? nextAttemptAt,
    Value<String?>? lastError,
    Value<bool>? gaveUp,
    Value<int>? rowid,
  }) {
    return LocalOutboxCompanion(
      messageId: messageId ?? this.messageId,
      attempts: attempts ?? this.attempts,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      lastError: lastError ?? this.lastError,
      gaveUp: gaveUp ?? this.gaveUp,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (messageId.present) {
      map['message_id'] = Variable<String>(messageId.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    if (nextAttemptAt.present) {
      map['next_attempt_at'] = Variable<DateTime>(nextAttemptAt.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (gaveUp.present) {
      map['gave_up'] = Variable<bool>(gaveUp.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalOutboxCompanion(')
          ..write('messageId: $messageId, ')
          ..write('attempts: $attempts, ')
          ..write('nextAttemptAt: $nextAttemptAt, ')
          ..write('lastError: $lastError, ')
          ..write('gaveUp: $gaveUp, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalSyncStateTable extends LocalSyncState
    with TableInfo<$LocalSyncStateTable, LocalSyncEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalSyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<DateTime> value = GeneratedColumn<DateTime>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_sync_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalSyncEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalSyncEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalSyncEntry(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $LocalSyncStateTable createAlias(String alias) {
    return $LocalSyncStateTable(attachedDatabase, alias);
  }
}

class LocalSyncEntry extends DataClass implements Insertable<LocalSyncEntry> {
  final String key;
  final DateTime value;
  const LocalSyncEntry({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<DateTime>(value);
    return map;
  }

  LocalSyncStateCompanion toCompanion(bool nullToAbsent) {
    return LocalSyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory LocalSyncEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalSyncEntry(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<DateTime>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<DateTime>(value),
    };
  }

  LocalSyncEntry copyWith({String? key, DateTime? value}) =>
      LocalSyncEntry(key: key ?? this.key, value: value ?? this.value);
  LocalSyncEntry copyWithCompanion(LocalSyncStateCompanion data) {
    return LocalSyncEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncEntry(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalSyncEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class LocalSyncStateCompanion extends UpdateCompanion<LocalSyncEntry> {
  final Value<String> key;
  final Value<DateTime> value;
  final Value<int> rowid;
  const LocalSyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalSyncStateCompanion.insert({
    required String key,
    required DateTime value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalSyncEntry> custom({
    Expression<String>? key,
    Expression<DateTime>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalSyncStateCompanion copyWith({
    Value<String>? key,
    Value<DateTime>? value,
    Value<int>? rowid,
  }) {
    return LocalSyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<DateTime>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalSyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$LocalDatabase extends GeneratedDatabase {
  _$LocalDatabase(QueryExecutor e) : super(e);
  $LocalDatabaseManager get managers => $LocalDatabaseManager(this);
  late final $LocalConversationsTable localConversations =
      $LocalConversationsTable(this);
  late final $LocalMembersTable localMembers = $LocalMembersTable(this);
  late final $LocalMessagesTable localMessages = $LocalMessagesTable(this);
  late final $LocalOutboxTable localOutbox = $LocalOutboxTable(this);
  late final $LocalSyncStateTable localSyncState = $LocalSyncStateTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    localConversations,
    localMembers,
    localMessages,
    localOutbox,
    localSyncState,
  ];
}

typedef $$LocalConversationsTableCreateCompanionBuilder =
    LocalConversationsCompanion Function({
      required String id,
      required String kind,
      Value<String?> title,
      required DateTime updatedAt,
      Value<String?> lastMessageId,
      Value<String?> lastMessagePreview,
      Value<String?> lastMessageSenderId,
      Value<DateTime?> lastMessageSentAt,
      Value<int> unreadCount,
      Value<int> rowid,
    });
typedef $$LocalConversationsTableUpdateCompanionBuilder =
    LocalConversationsCompanion Function({
      Value<String> id,
      Value<String> kind,
      Value<String?> title,
      Value<DateTime> updatedAt,
      Value<String?> lastMessageId,
      Value<String?> lastMessagePreview,
      Value<String?> lastMessageSenderId,
      Value<DateTime?> lastMessageSentAt,
      Value<int> unreadCount,
      Value<int> rowid,
    });

class $$LocalConversationsTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastMessageSentAt => $composableBuilder(
    column: $table.lastMessageSentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalConversationsTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastMessageSentAt => $composableBuilder(
    column: $table.lastMessageSentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalConversationsTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalConversationsTable> {
  $$LocalConversationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get lastMessageId => $composableBuilder(
    column: $table.lastMessageId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessagePreview => $composableBuilder(
    column: $table.lastMessagePreview,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastMessageSenderId => $composableBuilder(
    column: $table.lastMessageSenderId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastMessageSentAt => $composableBuilder(
    column: $table.lastMessageSentAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unreadCount => $composableBuilder(
    column: $table.unreadCount,
    builder: (column) => column,
  );
}

class $$LocalConversationsTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalConversationsTable,
          LocalConversation,
          $$LocalConversationsTableFilterComposer,
          $$LocalConversationsTableOrderingComposer,
          $$LocalConversationsTableAnnotationComposer,
          $$LocalConversationsTableCreateCompanionBuilder,
          $$LocalConversationsTableUpdateCompanionBuilder,
          (
            LocalConversation,
            BaseReferences<
              _$LocalDatabase,
              $LocalConversationsTable,
              LocalConversation
            >,
          ),
          LocalConversation,
          PrefetchHooks Function()
        > {
  $$LocalConversationsTableTableManager(
    _$LocalDatabase db,
    $LocalConversationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalConversationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalConversationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalConversationsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<DateTime?> lastMessageSentAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConversationsCompanion(
                id: id,
                kind: kind,
                title: title,
                updatedAt: updatedAt,
                lastMessageId: lastMessageId,
                lastMessagePreview: lastMessagePreview,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageSentAt: lastMessageSentAt,
                unreadCount: unreadCount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String kind,
                Value<String?> title = const Value.absent(),
                required DateTime updatedAt,
                Value<String?> lastMessageId = const Value.absent(),
                Value<String?> lastMessagePreview = const Value.absent(),
                Value<String?> lastMessageSenderId = const Value.absent(),
                Value<DateTime?> lastMessageSentAt = const Value.absent(),
                Value<int> unreadCount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalConversationsCompanion.insert(
                id: id,
                kind: kind,
                title: title,
                updatedAt: updatedAt,
                lastMessageId: lastMessageId,
                lastMessagePreview: lastMessagePreview,
                lastMessageSenderId: lastMessageSenderId,
                lastMessageSentAt: lastMessageSentAt,
                unreadCount: unreadCount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalConversationsTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalConversationsTable,
      LocalConversation,
      $$LocalConversationsTableFilterComposer,
      $$LocalConversationsTableOrderingComposer,
      $$LocalConversationsTableAnnotationComposer,
      $$LocalConversationsTableCreateCompanionBuilder,
      $$LocalConversationsTableUpdateCompanionBuilder,
      (
        LocalConversation,
        BaseReferences<
          _$LocalDatabase,
          $LocalConversationsTable,
          LocalConversation
        >,
      ),
      LocalConversation,
      PrefetchHooks Function()
    >;
typedef $$LocalMembersTableCreateCompanionBuilder =
    LocalMembersCompanion Function({
      required String conversationId,
      required String userId,
      required String displayName,
      Value<int> rowid,
    });
typedef $$LocalMembersTableUpdateCompanionBuilder =
    LocalMembersCompanion Function({
      Value<String> conversationId,
      Value<String> userId,
      Value<String> displayName,
      Value<int> rowid,
    });

class $$LocalMembersTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalMembersTable> {
  $$LocalMembersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMembersTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalMembersTable> {
  $$LocalMembersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMembersTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalMembersTable> {
  $$LocalMembersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );
}

class $$LocalMembersTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalMembersTable,
          LocalMember,
          $$LocalMembersTableFilterComposer,
          $$LocalMembersTableOrderingComposer,
          $$LocalMembersTableAnnotationComposer,
          $$LocalMembersTableCreateCompanionBuilder,
          $$LocalMembersTableUpdateCompanionBuilder,
          (
            LocalMember,
            BaseReferences<_$LocalDatabase, $LocalMembersTable, LocalMember>,
          ),
          LocalMember,
          PrefetchHooks Function()
        > {
  $$LocalMembersTableTableManager(_$LocalDatabase db, $LocalMembersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMembersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMembersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMembersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> conversationId = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMembersCompanion(
                conversationId: conversationId,
                userId: userId,
                displayName: displayName,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String conversationId,
                required String userId,
                required String displayName,
                Value<int> rowid = const Value.absent(),
              }) => LocalMembersCompanion.insert(
                conversationId: conversationId,
                userId: userId,
                displayName: displayName,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMembersTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalMembersTable,
      LocalMember,
      $$LocalMembersTableFilterComposer,
      $$LocalMembersTableOrderingComposer,
      $$LocalMembersTableAnnotationComposer,
      $$LocalMembersTableCreateCompanionBuilder,
      $$LocalMembersTableUpdateCompanionBuilder,
      (
        LocalMember,
        BaseReferences<_$LocalDatabase, $LocalMembersTable, LocalMember>,
      ),
      LocalMember,
      PrefetchHooks Function()
    >;
typedef $$LocalMessagesTableCreateCompanionBuilder =
    LocalMessagesCompanion Function({
      required String id,
      required String conversationId,
      required String senderId,
      required String content,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMessagesTableUpdateCompanionBuilder =
    LocalMessagesCompanion Function({
      Value<String> id,
      Value<String> conversationId,
      Value<String> senderId,
      Value<String> content,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalMessagesTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMessagesTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get senderId => $composableBuilder(
    column: $table.senderId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMessagesTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalMessagesTable> {
  $$LocalMessagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get conversationId => $composableBuilder(
    column: $table.conversationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get senderId =>
      $composableBuilder(column: $table.senderId, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMessagesTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalMessagesTable,
          LocalMessage,
          $$LocalMessagesTableFilterComposer,
          $$LocalMessagesTableOrderingComposer,
          $$LocalMessagesTableAnnotationComposer,
          $$LocalMessagesTableCreateCompanionBuilder,
          $$LocalMessagesTableUpdateCompanionBuilder,
          (
            LocalMessage,
            BaseReferences<_$LocalDatabase, $LocalMessagesTable, LocalMessage>,
          ),
          LocalMessage,
          PrefetchHooks Function()
        > {
  $$LocalMessagesTableTableManager(
    _$LocalDatabase db,
    $LocalMessagesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMessagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalMessagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalMessagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> conversationId = const Value.absent(),
                Value<String> senderId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String conversationId,
                required String senderId,
                required String content,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LocalMessagesCompanion.insert(
                id: id,
                conversationId: conversationId,
                senderId: senderId,
                content: content,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMessagesTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalMessagesTable,
      LocalMessage,
      $$LocalMessagesTableFilterComposer,
      $$LocalMessagesTableOrderingComposer,
      $$LocalMessagesTableAnnotationComposer,
      $$LocalMessagesTableCreateCompanionBuilder,
      $$LocalMessagesTableUpdateCompanionBuilder,
      (
        LocalMessage,
        BaseReferences<_$LocalDatabase, $LocalMessagesTable, LocalMessage>,
      ),
      LocalMessage,
      PrefetchHooks Function()
    >;
typedef $$LocalOutboxTableCreateCompanionBuilder =
    LocalOutboxCompanion Function({
      required String messageId,
      Value<int> attempts,
      required DateTime nextAttemptAt,
      Value<String?> lastError,
      Value<bool> gaveUp,
      Value<int> rowid,
    });
typedef $$LocalOutboxTableUpdateCompanionBuilder =
    LocalOutboxCompanion Function({
      Value<String> messageId,
      Value<int> attempts,
      Value<DateTime> nextAttemptAt,
      Value<String?> lastError,
      Value<bool> gaveUp,
      Value<int> rowid,
    });

class $$LocalOutboxTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalOutboxTable> {
  $$LocalOutboxTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get gaveUp => $composableBuilder(
    column: $table.gaveUp,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalOutboxTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalOutboxTable> {
  $$LocalOutboxTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get messageId => $composableBuilder(
    column: $table.messageId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempts => $composableBuilder(
    column: $table.attempts,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get gaveUp => $composableBuilder(
    column: $table.gaveUp,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalOutboxTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalOutboxTable> {
  $$LocalOutboxTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get messageId =>
      $composableBuilder(column: $table.messageId, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);

  GeneratedColumn<DateTime> get nextAttemptAt => $composableBuilder(
    column: $table.nextAttemptAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);

  GeneratedColumn<bool> get gaveUp =>
      $composableBuilder(column: $table.gaveUp, builder: (column) => column);
}

class $$LocalOutboxTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalOutboxTable,
          LocalOutboxEntry,
          $$LocalOutboxTableFilterComposer,
          $$LocalOutboxTableOrderingComposer,
          $$LocalOutboxTableAnnotationComposer,
          $$LocalOutboxTableCreateCompanionBuilder,
          $$LocalOutboxTableUpdateCompanionBuilder,
          (
            LocalOutboxEntry,
            BaseReferences<
              _$LocalDatabase,
              $LocalOutboxTable,
              LocalOutboxEntry
            >,
          ),
          LocalOutboxEntry,
          PrefetchHooks Function()
        > {
  $$LocalOutboxTableTableManager(_$LocalDatabase db, $LocalOutboxTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalOutboxTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalOutboxTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalOutboxTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> messageId = const Value.absent(),
                Value<int> attempts = const Value.absent(),
                Value<DateTime> nextAttemptAt = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<bool> gaveUp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOutboxCompanion(
                messageId: messageId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                gaveUp: gaveUp,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String messageId,
                Value<int> attempts = const Value.absent(),
                required DateTime nextAttemptAt,
                Value<String?> lastError = const Value.absent(),
                Value<bool> gaveUp = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalOutboxCompanion.insert(
                messageId: messageId,
                attempts: attempts,
                nextAttemptAt: nextAttemptAt,
                lastError: lastError,
                gaveUp: gaveUp,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalOutboxTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalOutboxTable,
      LocalOutboxEntry,
      $$LocalOutboxTableFilterComposer,
      $$LocalOutboxTableOrderingComposer,
      $$LocalOutboxTableAnnotationComposer,
      $$LocalOutboxTableCreateCompanionBuilder,
      $$LocalOutboxTableUpdateCompanionBuilder,
      (
        LocalOutboxEntry,
        BaseReferences<_$LocalDatabase, $LocalOutboxTable, LocalOutboxEntry>,
      ),
      LocalOutboxEntry,
      PrefetchHooks Function()
    >;
typedef $$LocalSyncStateTableCreateCompanionBuilder =
    LocalSyncStateCompanion Function({
      required String key,
      required DateTime value,
      Value<int> rowid,
    });
typedef $$LocalSyncStateTableUpdateCompanionBuilder =
    LocalSyncStateCompanion Function({
      Value<String> key,
      Value<DateTime> value,
      Value<int> rowid,
    });

class $$LocalSyncStateTableFilterComposer
    extends Composer<_$LocalDatabase, $LocalSyncStateTable> {
  $$LocalSyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalSyncStateTableOrderingComposer
    extends Composer<_$LocalDatabase, $LocalSyncStateTable> {
  $$LocalSyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalSyncStateTableAnnotationComposer
    extends Composer<_$LocalDatabase, $LocalSyncStateTable> {
  $$LocalSyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<DateTime> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$LocalSyncStateTableTableManager
    extends
        RootTableManager<
          _$LocalDatabase,
          $LocalSyncStateTable,
          LocalSyncEntry,
          $$LocalSyncStateTableFilterComposer,
          $$LocalSyncStateTableOrderingComposer,
          $$LocalSyncStateTableAnnotationComposer,
          $$LocalSyncStateTableCreateCompanionBuilder,
          $$LocalSyncStateTableUpdateCompanionBuilder,
          (
            LocalSyncEntry,
            BaseReferences<
              _$LocalDatabase,
              $LocalSyncStateTable,
              LocalSyncEntry
            >,
          ),
          LocalSyncEntry,
          PrefetchHooks Function()
        > {
  $$LocalSyncStateTableTableManager(
    _$LocalDatabase db,
    $LocalSyncStateTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalSyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LocalSyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LocalSyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<DateTime> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) =>
                  LocalSyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required DateTime value,
                Value<int> rowid = const Value.absent(),
              }) => LocalSyncStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalSyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$LocalDatabase,
      $LocalSyncStateTable,
      LocalSyncEntry,
      $$LocalSyncStateTableFilterComposer,
      $$LocalSyncStateTableOrderingComposer,
      $$LocalSyncStateTableAnnotationComposer,
      $$LocalSyncStateTableCreateCompanionBuilder,
      $$LocalSyncStateTableUpdateCompanionBuilder,
      (
        LocalSyncEntry,
        BaseReferences<_$LocalDatabase, $LocalSyncStateTable, LocalSyncEntry>,
      ),
      LocalSyncEntry,
      PrefetchHooks Function()
    >;

class $LocalDatabaseManager {
  final _$LocalDatabase _db;
  $LocalDatabaseManager(this._db);
  $$LocalConversationsTableTableManager get localConversations =>
      $$LocalConversationsTableTableManager(_db, _db.localConversations);
  $$LocalMembersTableTableManager get localMembers =>
      $$LocalMembersTableTableManager(_db, _db.localMembers);
  $$LocalMessagesTableTableManager get localMessages =>
      $$LocalMessagesTableTableManager(_db, _db.localMessages);
  $$LocalOutboxTableTableManager get localOutbox =>
      $$LocalOutboxTableTableManager(_db, _db.localOutbox);
  $$LocalSyncStateTableTableManager get localSyncState =>
      $$LocalSyncStateTableTableManager(_db, _db.localSyncState);
}
