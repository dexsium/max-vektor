import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class IncomingMessage extends Equatable {
  final int chatId;
  final int? messageId;
  final int? sender;
  final String text;
  final int? timeMs;
  final Uint8List raw;

  /// Клиентский id (cid), если сервер вернул его в эхо нашего исходящего —
  /// по нему дедупим собственное сообщение, чтобы не было дубля.
  final int? cid;

  /// Сырой список attach'ей из push-payload. Каждый элемент — map с полем
  /// `_type` и набором полей зависящих от типа. Парсится в `MaxAttach.fromServer`.
  final List<Map<String, dynamic>> attaches;

  /// Имя источника пересланного сообщения (link.type=FORWARD, chatName).
  /// null = не форвард или форвард от лички (тогда см. [forwardFromId]).
  final String? forwardFromName;

  /// id автора пересланного сообщения (sender вложенного message) — для
  /// форварда от лички, имя резолвится по контактам в UI.
  final int? forwardFromId;

  /// Данные цитаты (link.type=REPLY): id, превью-текст, id автора.
  final int? replyToId;
  final String? replyToPreview;
  final int? replyFromId;

  const IncomingMessage({
    required this.chatId,
    required this.text,
    required this.raw,
    this.messageId,
    this.sender,
    this.timeMs,
    this.attaches = const [],
    this.cid,
    this.forwardFromName,
    this.forwardFromId,
    this.replyToId,
    this.replyToPreview,
    this.replyFromId,
  });

  @override
  List<Object?> get props => [
        chatId,
        messageId,
        sender,
        text,
        timeMs,
        attaches,
        cid,
        forwardFromName,
        forwardFromId,
        replyToId,
        replyToPreview,
        replyFromId,
      ];
}
