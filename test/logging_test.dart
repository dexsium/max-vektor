import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/core/constants.dart';
import 'package:max_vektor/core/logging.dart';

void main() {
  group('mvRedact — секреты не должны попадать в лог целиком', () {
    test('токен не раскрывается, видна только длина и хвост', () {
      const token = 'abcdefghijklmnopqrstuvwxyz0123456789';
      final out = mvRedact(token);
      expect(out.contains(token), isFalse);
      expect(out, contains('len=${token.length}'));
      expect(out, contains('6789'));
    });

    test('короткий секрет не раскрывается вовсе', () {
      expect(mvRedact('1234'), '<len=4>');
    });

    test('null и пустая строка', () {
      expect(mvRedact(null), '<null>');
      expect(mvRedact(''), '<empty>');
    });
  });

  group('идентичность приложения', () {
    test('имя и дисклеймер Max Vektor', () {
      expect(AppMeta.name, 'Max Vektor');
      expect(AppMeta.disclaimer, 'Unofficial MAX client');
    });

    test('локальные хранилища отделены собственным namespace', () {
      expect(AppMeta.dbNameFor('acc1'), 'max_vektor_acc1.db');
      for (final suffix in AppMeta.accountKeySuffixes) {
        expect(
          AppMeta.accountKey('acc1', suffix).startsWith('mv_a_acc1_'),
          isTrue,
          reason: suffix,
        );
      }
    });
  });

  test('теги логов соответствуют формату [MaxVektor][TAG]', () {
    expect(MvTag.auth, '[AUTH]');
    expect(MvTag.socket, '[SOCKET]');
    expect(MvTag.init, '[INIT]');
    expect(MvTag.chat, '[CHAT]');
    expect(MvTag.message, '[MESSAGE]');
    expect(MvTag.error, '[ERROR]');
  });
}
