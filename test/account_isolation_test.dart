import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/core/constants.dart';

/// Изоляция мультиаккаунта построена на неймспейсинге: у каждого аккаунта
/// СВОЙ файл БД, СВОЙ каталог медиа и СВОИ ключи в Keychain. Эти тесты
/// фиксируют, что данные разных аккаунтов физически не могут пересечься —
/// регрессия (общий файл/ключ на все аккаунты) их уронит.
void main() {
  group('изоляция аккаунтов по неймспейсу', () {
    test('файл БД у каждого аккаунта свой', () {
      expect(AppMeta.dbNameFor('acc1'), isNot(AppMeta.dbNameFor('acc2')));
      expect(AppMeta.dbNameFor('acc1'), contains('acc1'));
      expect(AppMeta.dbNameFor('acc2'), contains('acc2'));
    });

    test('каталог медиа у каждого аккаунта свой', () {
      expect(AppMeta.mediaDirFor('acc1'), isNot(AppMeta.mediaDirFor('acc2')));
      expect(AppMeta.mediaDirFor('acc1'), contains('acc1'));
    });

    test('ключи Keychain содержат accountId — токены не смешиваются', () {
      final aToken = AppMeta.accountKey('acc1', AppMeta.tokenKeySuffix);
      final bToken = AppMeta.accountKey('acc2', AppMeta.tokenKeySuffix);
      final aDevice = AppMeta.accountKey('acc1', AppMeta.deviceIdKeySuffix);
      expect(aToken, isNot(bToken));
      expect(aToken, contains('acc1'));
      // Разные суффиксы одного аккаунта тоже различны (токен ≠ deviceId).
      expect(aToken, isNot(aDevice));
    });

    test('deviceId разный у разных аккаунтов (анти-фрод разводит устройства)',
        () {
      // Ключ deviceId содержит accountId → каждый аккаунт получит свой UUID.
      expect(
        AppMeta.accountKey('acc1', AppMeta.deviceIdKeySuffix),
        isNot(AppMeta.accountKey('acc2', AppMeta.deviceIdKeySuffix)),
      );
    });
  });
}
