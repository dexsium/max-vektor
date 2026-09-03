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

  /// Вложения сообщения. Хранятся в отдельной таблице `attachments`,
  /// подгружаются репозиторием. В `toMap`/`fromDbRow` НЕ участвуют.
  final List<MaxAttach> attaches;

  /// Метка времени последней правки (opcode 67). null = сообщение не редактировалось.
  final int? editedAtMs;

  /// Имя источника пересланного сообщения (канал/чат/автор). Не null, если это
  /// форвард — тогда в пузыре рисуется «Переслано: <имя>». Берётся из объекта
  /// `link` (type=FORWARD, поле chatName) серверного сообщения — см. APK pma.java.
  final String? forwardFromName;

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
    this.attaches = const [],
    this.editedAtMs,
    this.forwardFromName,
  });

  MaxMessage copyWith({
    int? id,
    MessageStatus? status,
    String? text,
    int? timeMs,
    int? replyToId,
    String? replyToPreview,
    List<MaxAttach>? attaches,
    int? editedAtMs,
    String? forwardFromName,
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
      attaches: attaches ?? this.attaches,
      editedAtMs: editedAtMs ?? this.editedAtMs,
      forwardFromName: forwardFromName ?? this.forwardFromName,
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
    'edited_at': editedAtMs,
    'forward_from': forwardFromName,
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
    editedAtMs: (r['edited_at'] as num?)?.toInt(),
    forwardFromName: r['forward_from'] as String?,
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
    attaches,
    editedAtMs,
    forwardFromName,
  ];
}
