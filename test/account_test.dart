import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/core/constants.dart';
import 'package:max_vektor/data/account/account.dart';

void main() {
  group('namespace аккаунта', () {
    test('ключи Keychain у разных аккаунтов не пересекаются', () {
      for (final suffix in AppMeta.accountKeySuffixes) {
        expect(
          AppMeta.accountKey('acc1', suffix),
          isNot(AppMeta.accountKey('acc2', suffix)),
          reason: suffix,
        );
      }
    });

    test('deviceId лежит под собственным ключом каждого аккаунта', () {
      // Именно это разводит аккаунты как разные устройства для сервера MAX.
      expect(
        AppMeta.accountKey('acc1', AppMeta.deviceIdKeySuffix),
        'mv_a_acc1_device_id',
      );
      expect(
        AppMeta.accountKey('acc2', AppMeta.deviceIdKeySuffix),
        'mv_a_acc2_device_id',
      );
    });

    test('база и каталог медиа у каждого аккаунта свои', () {
      expect(AppMeta.dbNameFor('acc1'), isNot(AppMeta.dbNameFor('acc2')));
      expect(AppMeta.mediaDirFor('acc1'), isNot(AppMeta.mediaDirFor('acc2')));
      expect(AppMeta.mediaDirFor('acc2'), 'max_vektor_media/acc2');
    });

    test('legacy-ключи одноаккаунтной версии ведут на валидные суффиксы', () {
      for (final suffix in AppMeta.legacyKeyMigration.values) {
        expect(AppMeta.accountKeySuffixes, contains(suffix));
      }
      expect(
        AppMeta.legacyKeyMigration['mv_max_auth_token'],
        AppMeta.tokenKeySuffix,
      );
    });
  });

  group('MvAccount', () {
    test('подпись: имя важнее номера, номер уходит во вторую строку', () {
      const a = MvAccount(
        id: 'acc1',
        userId: 7,
        phone: '+79990000000',
        displayName: 'Иван',
      );
      expect(a.label, 'Иван');
      expect(a.subtitle, '+79990000000');
      expect(a.isSignedIn, isTrue);
    });

    test('без имени подписью становится номер', () {
      const a = MvAccount(id: 'acc1', phone: '+79990000000');
      expect(a.label, '+79990000000');
      expect(a.subtitle, isNull);
    });

    test('пустой аккаунт — вход ещё не выполнен', () {
      const a = MvAccount(id: 'acc9');
      expect(a.isSignedIn, isFalse);
      expect(a.label, 'Вход не выполнен');
    });

    test('roundtrip через JSON сохраняет поля', () {
      const a = MvAccount(
        id: 'acc3',
        userId: 42,
        phone: '+70000000000',
        displayName: 'Тест',
      );
      final back = MvAccount.decodeList(MvAccount.encodeList([a])).single;
      expect(back.id, a.id);
      expect(back.userId, a.userId);
      expect(back.phone, a.phone);
      expect(back.displayName, a.displayName);
    });

    test('повреждённый реестр не роняет запуск', () {
      expect(MvAccount.decodeList('не json'), isEmpty);
      expect(MvAccount.decodeList(null), isEmpty);
      expect(MvAccount.decodeList('{"id":"acc1"}'), isEmpty);
    });

    test('записи без id отбрасываются', () {
      expect(MvAccount.decodeList('[{"userId":1}]'), isEmpty);
      expect(MvAccount.decodeList('[{"id":""}]'), isEmpty);
    });

    test('copyWith не теряет id', () {
      const a = MvAccount(id: 'acc5');
      expect(a.copyWith(userId: 1).id, 'acc5');
    });
  });
}
