import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
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

  // Регрессия: диагностика раньше жила только в памяти и пропадала при
  // крэше/OS-килле/принудительном закрытии — ровно тогда, когда была нужнее
  // всего (см. lib/core/diagnostics_session.dart). Персистентность
  // подключается СВЕРХУ через эти хуки, сам MvLogBuffer их только вызывает.
  group('MvLogBuffer — точки подключения персистентности', () {
    tearDown(() {
      // Статическое состояние переживает тесты внутри файла — обязательно
      // отключаем хуки и чистим буфер, иначе тесты потекут друг в друга.
      MvLogBuffer.onLine = null;
      MvLogBuffer.onClear = null;
      MvLogBuffer.clear();
    });

    test('add() вызывает onLine с этой же строкой', () {
      final seen = <String>[];
      MvLogBuffer.onLine = seen.add;
      MvLogBuffer.add('строка 1');
      MvLogBuffer.add('строка 2');
      expect(seen, ['строка 1', 'строка 2']);
      expect(MvLogBuffer.dump(), 'строка 1\nстрока 2');
    });

    test('clear() вызывает onClear и опустошает буфер', () {
      var cleared = false;
      MvLogBuffer.onClear = () => cleared = true;
      MvLogBuffer.add('что-то');
      MvLogBuffer.clear();
      expect(cleared, isTrue);
      expect(MvLogBuffer.length, 0);
    });

    test('seed() заполняет буфер сохранённым хвостом, НЕ дёргая onLine '
        '(это не новые строки, а восстановление старых)', () {
      final seen = <String>[];
      MvLogBuffer.onLine = seen.add;
      MvLogBuffer.seed(['прошлая сессия: строка A', 'прошлая сессия: строка B']);
      expect(MvLogBuffer.length, 2);
      expect(MvLogBuffer.dump(),
          'прошлая сессия: строка A\nпрошлая сессия: строка B');
      expect(seen, isEmpty);
    });

    test('seed() заменяет, а не добавляет к уже накопленному', () {
      MvLogBuffer.add('уже было');
      MvLogBuffer.seed(['восстановлено']);
      expect(MvLogBuffer.dump(), 'восстановлено');
    });
  });

  // Регрессия: без трассировки строка «что-то упало» бесполезна для
  // диагностики крэша — печать сработала бы, но чинить нечего (нет «где»).
  // При этом обычные info/debug-логи НЕ должны раздуваться трассировкой —
  // так они и задумывались («одна строка на событие»).
  group('MaxVektorLogPrinter — трассировка только для severe (error/fatal)', () {
    tearDown(() {
      MvLogBuffer.onLine = null;
      MvLogBuffer.clear();
    });

    test('error-событие со стектрейсом печатает строку stack:', () {
      final printer = MaxVektorLogPrinter();
      final lines = printer.log(LogEvent(
        Level.error,
        'что-то сломалось',
        error: 'boom',
        stackTrace: StackTrace.current,
      ));
      expect(lines.any((l) => l.contains('stack:')), isTrue);
      expect(lines.any((l) => l.contains('cause: boom')), isTrue);
    });

    test('info-событие со стектрейсом стек НЕ печатает (не крэш — обычное '
        'событие, лог не должен раздуваться)', () {
      final printer = MaxVektorLogPrinter();
      final lines = printer.log(LogEvent(
        Level.info,
        'обычное сообщение',
        stackTrace: StackTrace.current,
      ));
      expect(lines.any((l) => l.contains('stack:')), isFalse);
    });
  });
}
