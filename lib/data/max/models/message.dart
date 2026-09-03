import 'package:equatable/equatable.dart';

import 'attach.dart';

enum MessageDirection { incoming, outgoing }

enum MessageStatus { pending, sent, delivered, read, failed, rejected }

class MaxMessage extends Equatable {
  final int? id;
  final int chatId;
  final int? senderId;
  final String text;
  final int timeMs;
  final MessageDirection direction;
  final MessageStatus status;

  /// Локальный id, который пригодится пока сервер не вернул свой.
  final String? localId;

  /// id сообщения, на которое отвечаем (если это reply).
  final int? replyToId;

  /// Короткий превью-текст того сообщения, чтобы рисовать в пузыре без
  /// дополнительного запроса в БД.
  final String? replyToPreview;

  /// id автора сообщения-цитаты — для показа его имени над цитатой (резолвится
  /// по контактам в UI). Из link.type=REPLY, sender вложенного message.
  final int? replyFromId;

  /// Вложения сообщения. Хранятся в отдельной таблице `attachments`,
  /// подгружаются репозиторием. В `toMap`/`fromDbRow` НЕ участвуют.
  final List<MaxAttach> attaches;

  /// Метка времени последней правки (opcode 67). null = сообщение не редактировалось.
  final int? editedAtMs;

  /// Имя источника пересланного сообщения (канал/чат). Не null для форварда из
  /// чата/канала — рисуется «Переслано: <имя>». Берётся из `link.chatName`
  /// серверного сообщения — см. APK pma.java.
  final String? forwardFromName;

  /// id автора пересланного сообщения (форвард от лички) — имя резолвится по
  /// контактам в UI, когда [forwardFromName] пуст.
  final int? forwardFromId;

  /// Это пересланное сообщение (из чата с именем или от пользователя).
  bool get isForward =>
      (forwardFromName?.isNotEmpty ?? false) || forwardFromId != null;

  const MaxMessage({
    required this.chatId,
    required this.text,
    required this.timeMs,
    required this.direction,
    this.id,
    this.senderId,
    this.status = MessageStatus.sent,
    this.localId,
    this.replyToId,
    this.replyToPreview,
    this.replyFromId,
    this.attaches = const [],
    this.editedAtMs,
    this.forwardFromName,
    this.forwardFromId,
  });

  MaxMessage copyWith({
    int? id,
    MessageStatus? status,
    String? text,
    int? timeMs,
    int? replyToId,
    String? replyToPreview,
    int? replyFromId,
    List<MaxAttach>? attaches,
    int? editedAtMs,
    String? forwardFromName,
    int? forwardFromId,
  }) {
    return MaxMessage(
      id: id ?? this.id,
      chatId: chatId,
      senderId: senderId,
      text: text ?? this.text,
      timeMs: timeMs ?? this.timeMs,
      direction: direction,
      status: status ?? this.status,
      localId: localId,
      replyToId: replyToId ?? this.replyToId,
      replyToPreview: replyToPreview ?? this.replyToPreview,
      replyFromId: replyFromId ?? this.replyFromId,
      attaches: attaches ?? this.attaches,
      editedAtMs: editedAtMs ?? this.editedAtMs,
      forwardFromName: forwardFromName ?? this.forwardFromName,
      forwardFromId: forwardFromId ?? this.forwardFromId,
    );
  }

  bool get hasAttaches => attaches.isNotEmpty;

  Map<String, Object?> toMap() => {
    'id': id,
    'local_id': localId,
    'chat_id': chatId,
    'sender_id': senderId,
    'text': text,
    'time_ms': timeMs,
    'direction': direction.name,
    'status': status.name,
    'reply_to_id': replyToId,
    'reply_to_preview': replyToPreview,
    'reply_from_id': replyFromId,
    'edited_at': editedAtMs,
    'forward_from': forwardFromName,
    'forward_from_id': forwardFromId,
  };

  factory MaxMessage.fromDbRow(Map<String, Object?> r) => MaxMessage(
    id: r['id'] as int?,
    localId: r['local_id'] as String?,
    chatId: r['chat_id'] as int,
    senderId: r['sender_id'] as int?,
    text: (r['text'] as String?) ?? '',
    timeMs: (r['time_ms'] as int?) ?? 0,
    direction: MessageDirection.values.firstWhere(
      (d) => d.name == (r['direction'] as String?),
      orElse: () => MessageDirection.incoming,
    ),
    status: MessageStatus.values.firstWhere(
      (s) => s.name == (r['status'] as String?),
      orElse: () => MessageStatus.sent,
    ),
    replyToId: r['reply_to_id'] as int?,
    replyToPreview: r['reply_to_preview'] as String?,
    replyFromId: (r['reply_from_id'] as num?)?.toInt(),
    editedAtMs: (r['edited_at'] as num?)?.toInt(),
    forwardFromName: r['forward_from'] as String?,
    forwardFromId: (r['forward_from_id'] as num?)?.toInt(),
  );

  @override
  List<Object?> get props => [
    id,
    localId,
    chatId,
    senderId,
    text,
    timeMs,
    direction,
    status,
    replyToId,
    replyToPreview,
    replyFromId,
    attaches,
    editedAtMs,
    forwardFromName,
    forwardFromId,
  ];
}
