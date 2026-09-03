import 'package:equatable/equatable.dart';

/// Тип чата в терминах сервера MAX.
///
/// Значения взяты из декомпила официального клиента (см.
/// docs/MEDIA_OPCODES.md, поле `chatType` в CONTROL-attach):
/// `UNKNOWN | DIALOG | CHAT | CHANNEL | GROUP_CHAT`.
/// `CHAT` и `GROUP_CHAT` для UI — одно и то же (групповой чат).
enum MaxChatKind {
  /// 1:1 переписка.
  dialog,

  /// Групповой чат (CHAT / GROUP_CHAT).
  group,

  /// Канал (CHANNEL) — публичный или приватный, в котором мы состоим.
  channel,

  /// Сервер не прислал тип или прислал UNKNOWN.
  unknown;

  /// Разбор серверного значения. Неизвестные строки → [unknown]
  /// (не гадаем и не выдумываем новых типов протокола).
  static MaxChatKind fromServer(Object? raw) {
    final v = raw?.toString().toUpperCase();
    return switch (v) {
      'DIALOG' => MaxChatKind.dialog,
      'CHAT' || 'GROUP_CHAT' => MaxChatKind.group,
      'CHANNEL' => MaxChatKind.channel,
      _ => MaxChatKind.unknown,
    };
  }

  static MaxChatKind fromStorage(Object? raw) {
    final v = raw?.toString();
    for (final k in MaxChatKind.values) {
      if (k.name == v) return k;
    }
    return MaxChatKind.unknown;
  }

  /// Подпись типа для UI.
  String get label => switch (this) {
        MaxChatKind.dialog => 'Диалог',
        MaxChatKind.group => 'Группа',
        MaxChatKind.channel => 'Канал',
        MaxChatKind.unknown => 'Чат',
      };
}

class MaxChat extends Equatable {
  final int id;
  final String? title;
  final String? avatarUrl;
  final bool isGroup;

  /// Тип чата с сервера (DIALOG/CHAT/CHANNEL). Отдельно от [isGroup]:
  /// isGroup — старый булев флаг апстрима, kind — точный тип, по которому
  /// UI отличает канал от группы.
  final MaxChatKind kind;

  /// Число участников, если сервер его прислал.
  final int? membersCount;

  final int? lastMessageTimeMs;
  final String? lastMessagePreview;
  final int unreadCount;
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;

  /// != null ⇒ диалог 1:1 с этим userId; null ⇒ группа/канал/неизвестно.
  final int? peerUserId;

  /// != null ⇒ подтверждённый серверный chatId (маршрут отправки op 64).
  final int? serverChatId;

  const MaxChat({
    required this.id,
    this.title,
    this.avatarUrl,
    this.isGroup = false,
    this.kind = MaxChatKind.unknown,
    this.membersCount,
    this.lastMessageTimeMs,
    this.lastMessagePreview,
    this.unreadCount = 0,
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.peerUserId,
    this.serverChatId,
  });

  bool get isDialog => peerUserId != null || kind == MaxChatKind.dialog;

  bool get isChannel => kind == MaxChatKind.channel;

  /// Группа или канал — всё, что не 1:1.
  bool get isMultiUser =>
      kind == MaxChatKind.group || kind == MaxChatKind.channel || isGroup;

  MaxChat copyWith({
    int? id,
    String? title,
    String? avatarUrl,
    bool? isGroup,
    MaxChatKind? kind,
    int? membersCount,
    int? lastMessageTimeMs,
    String? lastMessagePreview,
    int? unreadCount,
    bool? isPinned,
    bool? isArchived,
    bool? isMuted,
    int? peerUserId,
    int? serverChatId,
  }) {
    return MaxChat(
      id: id ?? this.id,
      title: title ?? this.title,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isGroup: isGroup ?? this.isGroup,
      kind: kind ?? this.kind,
      membersCount: membersCount ?? this.membersCount,
      lastMessageTimeMs: lastMessageTimeMs ?? this.lastMessageTimeMs,
      lastMessagePreview: lastMessagePreview ?? this.lastMessagePreview,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isMuted: isMuted ?? this.isMuted,
      peerUserId: peerUserId ?? this.peerUserId,
      serverChatId: serverChatId ?? this.serverChatId,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'avatar_url': avatarUrl,
    'is_group': isGroup ? 1 : 0,
    'chat_kind': kind.name,
    'members_count': membersCount,
    'last_message_time_ms': lastMessageTimeMs,
    'last_message_preview': lastMessagePreview,
    'unread_count': unreadCount,
    'is_pinned': isPinned ? 1 : 0,
    'is_archived': isArchived ? 1 : 0,
    'is_muted': isMuted ? 1 : 0,
    'peer_user_id': peerUserId,
    'server_chat_id': serverChatId,
  };

  factory MaxChat.fromDbRow(Map<String, Object?> r) => MaxChat(
    id: r['id'] as int,
    title: r['title'] as String?,
    avatarUrl: r['avatar_url'] as String?,
    isGroup: (r['is_group'] as int? ?? 0) == 1,
    kind: MaxChatKind.fromStorage(r['chat_kind']),
    membersCount: (r['members_count'] as num?)?.toInt(),
    lastMessageTimeMs: r['last_message_time_ms'] as int?,
    lastMessagePreview: r['last_message_preview'] as String?,
    unreadCount: r['unread_count'] as int? ?? 0,
    isPinned: (r['is_pinned'] as int? ?? 0) == 1,
    isArchived: (r['is_archived'] as int? ?? 0) == 1,
    isMuted: (r['is_muted'] as int? ?? 0) == 1,
    peerUserId: (r['peer_user_id'] as num?)?.toInt(),
    serverChatId: (r['server_chat_id'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [
    id,
    title,
    avatarUrl,
    isGroup,
    kind,
    membersCount,
    lastMessageTimeMs,
    lastMessagePreview,
    unreadCount,
    isPinned,
    isArchived,
    isMuted,
    peerUserId,
    serverChatId,
  ];
}

/// Разбор записи чата, как её отдаёт сервер MAX.
///
/// Используется и для ответа CHAT_INFO (op 48), и для массива `chats`
/// в ответе LOGIN (op 19) — структура записи там одна и та же.
///
/// Ключи читаются «по кандидатам»: если сервер не прислал поле, остаётся
/// null, ничего не додумывается. Новых полей протокола здесь не вводится —
/// только те, что уже встречаются в ответах (`id`, `type`/`chatType`,
/// `title`/`name`, `lastMessage`, иконка) и в декомпиле официального клиента.
MaxChat? parseServerChat(Map<Object?, Object?> raw) {
  final m = raw.map((k, v) => MapEntry(k.toString(), v));
  final id = m['id'];
  if (id is! num) return null;

  final kind = MaxChatKind.fromServer(m['type'] ?? m['chatType']);
  final membersCount =
      (m['participantsCount'] ?? m['membersCount']) is num
          ? ((m['participantsCount'] ?? m['membersCount']) as num).toInt()
          : null;

  // Старый булев флаг апстрима сохраняем: группа/канал ⇒ true, а если типа
  // нет — прежняя эвристика «участников больше двух».
  final isGroup = kind == MaxChatKind.group ||
      kind == MaxChatKind.channel ||
      (kind == MaxChatKind.unknown &&
          membersCount != null &&
          membersCount > 2);

  String? firstString(List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.isNotEmpty) return v;
    }
    return null;
  }

  final lm = m['lastMessage'];
  int? lastTime;
  String? lastPreview;
  if (lm is Map) {
    final lmm = lm.map((k, v) => MapEntry(k.toString(), v));
    lastTime = (lmm['time'] as num?)?.toInt();
    final text = lmm['text']?.toString() ?? '';
    final att = (lmm['attaches'] ?? lmm['attachments']) as List?;
    lastPreview = text.isNotEmpty
        ? text
        : (att != null && att.isNotEmpty ? '[Вложение]' : null);
  }

  return MaxChat(
    id: id.toInt(),
    // Имена полей сверены с парсером чата официального APK (lv2.java):
    // title/name/subject — заголовок, baseIconUrl/icon/photoUrl — аватар.
    title: firstString(['title', 'name', 'subject']),
    avatarUrl: firstString([
      'baseIconUrl',
      'baseRawIconUrl',
      'icon',
      'iconUrl',
      'photoUrl',
      'avatar',
      'photo',
    ]),
    isGroup: isGroup,
    kind: kind,
    membersCount: membersCount,
    lastMessageTimeMs: lastTime,
    lastMessagePreview: lastPreview,
    // Запись пришла из серверного списка — её id уже серверный, маршрут
    // отправки = chatId (а не userId).
    serverChatId: id.toInt(),
  );
}
