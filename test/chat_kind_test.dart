import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/data/max/models/chat.dart';

void main() {
  group('MaxChatKind.fromServer', () {
    test('DIALOG → dialog', () {
      expect(MaxChatKind.fromServer('DIALOG'), MaxChatKind.dialog);
    });

    test('CHAT и GROUP_CHAT → group', () {
      expect(MaxChatKind.fromServer('CHAT'), MaxChatKind.group);
      expect(MaxChatKind.fromServer('GROUP_CHAT'), MaxChatKind.group);
    });

    test('CHANNEL → channel', () {
      expect(MaxChatKind.fromServer('CHANNEL'), MaxChatKind.channel);
    });

    test('регистр не важен', () {
      expect(MaxChatKind.fromServer('channel'), MaxChatKind.channel);
    });

    test('незнакомое значение и null → unknown (ничего не выдумываем)', () {
      expect(MaxChatKind.fromServer('SOMETHING_NEW'), MaxChatKind.unknown);
      expect(MaxChatKind.fromServer(null), MaxChatKind.unknown);
    });
  });

  group('parseServerChat', () {
    test('канал: тип, название, аватар, превью последнего сообщения', () {
      final c = parseServerChat({
        'id': 42,
        'type': 'CHANNEL',
        'title': 'Новости',
        'baseIconUrl': 'https://cdn.example/icon',
        'participantsCount': 1500,
        'lastMessage': {'id': 7, 'text': 'Привет', 'time': 1700000000000},
      });
      expect(c, isNotNull);
      expect(c!.id, 42);
      expect(c.kind, MaxChatKind.channel);
      expect(c.isChannel, isTrue);
      expect(c.isMultiUser, isTrue);
      expect(c.title, 'Новости');
      expect(c.avatarUrl, 'https://cdn.example/icon');
      expect(c.membersCount, 1500);
      expect(c.lastMessagePreview, 'Привет');
      expect(c.lastMessageTimeMs, 1700000000000);
      expect(c.serverChatId, 42);
    });

    test('группа помечается isGroup для обратной совместимости', () {
      final c = parseServerChat({'id': 1, 'type': 'GROUP_CHAT'});
      expect(c!.kind, MaxChatKind.group);
      expect(c.isGroup, isTrue);
    });

    test('диалог не считается групповым', () {
      final c = parseServerChat({'id': 5, 'type': 'DIALOG'});
      expect(c!.isGroup, isFalse);
      expect(c.isMultiUser, isFalse);
      expect(c.isDialog, isTrue);
    });

    test('без типа работает прежняя эвристика по числу участников', () {
      expect(parseServerChat({'id': 1, 'membersCount': 8})!.isGroup, isTrue);
      expect(parseServerChat({'id': 2, 'membersCount': 2})!.isGroup, isFalse);
    });

    test('вложение без текста даёт превью «[Вложение]»', () {
      final c = parseServerChat({
        'id': 3,
        'lastMessage': {
          'id': 9,
          'time': 1,
          'attaches': [
            {'_type': 'PHOTO'}
          ],
        },
      });
      expect(c!.lastMessagePreview, '[Вложение]');
    });

    test('запись без числового id отбрасывается', () {
      expect(parseServerChat({'title': 'нет id'}), isNull);
      expect(parseServerChat({'id': 'abc'}), isNull);
    });

    test('roundtrip через БД сохраняет тип и число участников', () {
      final c = parseServerChat({
        'id': 11,
        'type': 'CHANNEL',
        'participantsCount': 3,
      })!;
      final back = MaxChat.fromDbRow(c.toMap());
      expect(back.kind, MaxChatKind.channel);
      expect(back.membersCount, 3);
    });
  });
}
