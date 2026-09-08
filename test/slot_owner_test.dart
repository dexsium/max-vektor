import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/data/account/slot_owner.dart';

/// Регрессионный тест бага «в аккаунте видны чужие чаты»: локальный слот
/// (например acc1) может за свою жизнь принять несколько РАЗНЫХ номеров MAX
/// (вышли — вошли другим номером в тот же слот). Без сверки владельца
/// локальная БД оставалась от прежнего номера, и клиент запрашивал/показывал
/// чужие чаты (видно в диагностике: op 48 по чату старого владельца →
/// chats: []). Правило — [slotOwnerChanged]/[reconcileSlotOwner]
/// (см. lib/data/account/slot_owner.dart), подключено в account_runtime.dart
/// как onLoginUser MaxClient — вызывается на КАЖДОМ успешном LOGIN.
void main() {
  group('slotOwnerChanged', () {
    test('первый вход в пустой слот (owner=null) — смена', () {
      expect(slotOwnerChanged(storedOwner: null, userId: 100), isTrue);
    });

    test('тот же владелец — не смена', () {
      expect(slotOwnerChanged(storedOwner: 100, userId: 100), isFalse);
    });

    test('другой номер в тот же слот — смена', () {
      expect(slotOwnerChanged(storedOwner: 100, userId: 200), isTrue);
    });
  });

  group('reconcileSlotOwner', () {
    test('null userId (профиль не пришёл в LOGIN) — ничего не трогает',
        () async {
      var readCalled = false;
      var cleared = false;
      await reconcileSlotOwner(
        userId: null,
        readOwner: () async {
          readCalled = true;
          return null;
        },
        writeOwner: (_) async => fail('writeOwner не должен вызываться'),
        writeMyUserId: (_) async => fail('writeMyUserId не должен вызываться'),
        clearSlotData: () async => cleared = true,
      );
      expect(readCalled, isFalse);
      expect(cleared, isFalse);
    });

    test('первый вход в слот — чистит (no-op на пустой БД) и фиксирует '
        'владельца', () async {
      var cleared = false;
      int? writtenOwner;
      int? writtenMyId;
      await reconcileSlotOwner(
        userId: 427832073,
        readOwner: () async => null,
        writeOwner: (id) async => writtenOwner = id,
        writeMyUserId: (id) async => writtenMyId = id,
        clearSlotData: () async => cleared = true,
      );
      expect(cleared, isTrue);
      expect(writtenOwner, 427832073);
      expect(writtenMyId, 427832073);
    });

    test('переподключение ТЕМ ЖЕ номером — БД НЕ чистится (чаты не '
        'теряются на обычном reconnect)', () async {
      var cleared = false;
      int? writtenMyId;
      await reconcileSlotOwner(
        userId: 427832073,
        readOwner: () async => 427832073,
        writeOwner: (_) async => fail('владелец не менялся — writeOwner не '
            'должен вызываться'),
        writeMyUserId: (id) async => writtenMyId = id,
        clearSlotData: () async => cleared = true,
      );
      expect(cleared, isFalse);
      expect(writtenMyId, 427832073);
    });

    test('ДРУГОЙ номер вошёл в тот же слот — БД чистится ДО записи нового '
        'владельца (иначе окно для гонки с чтением чатов)', () async {
      final calls = <String>[];
      await reconcileSlotOwner(
        userId: 200,
        readOwner: () async => 100,
        writeOwner: (id) async => calls.add('writeOwner($id)'),
        writeMyUserId: (id) async => calls.add('writeMyUserId($id)'),
        clearSlotData: () async => calls.add('clear'),
      );
      expect(calls, ['clear', 'writeOwner(200)', 'writeMyUserId(200)']);
    });

    test('колбэк onOwnerChanged получает старого и нового владельца',
        () async {
      int? seenPrev;
      int? seenNext;
      var calledWith = false;
      await reconcileSlotOwner(
        userId: 200,
        readOwner: () async => 100,
        writeOwner: (_) async {},
        writeMyUserId: (_) async {},
        clearSlotData: () async {},
        onOwnerChanged: (previous, next) {
          calledWith = true;
          seenPrev = previous;
          seenNext = next;
        },
      );
      expect(calledWith, isTrue);
      expect(seenPrev, 100);
      expect(seenNext, 200);
    });

    test('onOwnerChanged НЕ вызывается, если владелец не менялся', () async {
      var called = false;
      await reconcileSlotOwner(
        userId: 100,
        readOwner: () async => 100,
        writeOwner: (_) async {},
        writeMyUserId: (_) async {},
        clearSlotData: () async {},
        onOwnerChanged: (_, __) => called = true,
      );
      expect(called, isFalse);
    });
  });
}
