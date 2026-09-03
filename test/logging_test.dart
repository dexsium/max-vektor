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
      expect(AppMeta.dbName, 'max_vektor.db');
      for (final key in [
        AppMeta.secureTokenKey,
        AppMeta.prefMyUserIdKey,
        AppMeta.tokenKindKey,
        AppMeta.deviceIdKey,
      ]) {
        expect(key.startsWith('mv_'), isTrue, reason: key);
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
