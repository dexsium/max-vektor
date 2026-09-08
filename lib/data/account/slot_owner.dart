/// Правило владельца локального слота аккаунта — чистая функция без
/// зависимостей от сокета/Keychain/SQLite, поэтому её можно проверить
/// напрямую юнит-тестом (см. test/slot_owner_test.dart).
///
/// Один локальный слот (`accountId`, например `acc1`) может за свою жизнь
/// принять несколько РАЗНЫХ номеров MAX: пользователь выходит и входит другим
/// номером в тот же слот. Если не сверять владельца, локальная база остаётся
/// от прежнего номера, и новый вход видит чужие чаты — это и было причиной
/// «чаты не принадлежат этому аккаунту».
///
/// [storedOwner] — userId, которого слот считает своим по локальному
/// хранилищу (null — слот пуст: первый вход, после purge, после обновления
/// до версии с этим полем). Неизвестный владелец НАМЕРЕННО считается сменой:
/// данные неясного происхождения новому входу не показываем.
bool slotOwnerChanged({required int? storedOwner, required int userId}) =>
    storedOwner != userId;

/// Применяет правило [slotOwnerChanged] к реальному входу: если владелец
/// сменился — чистит локальные данные слота ДО того, как [userId] будет
/// зафиксирован новым владельцем (порядок важен — иначе окно между записью
/// owner и очисткой БД). Вызывается на КАЖДОМ успешном LOGIN.
///
/// Зависимости приняты функциями, а не конкретными типами (SecureStorage/
/// AppDatabase) — так тест проверяет только логику, без Keychain/SQLite/сети,
/// а production-код (account_runtime.dart) подключает те же функции реальными
/// методами storage/database.
Future<void> reconcileSlotOwner({
  required int? userId,
  required Future<int?> Function() readOwner,
  required Future<void> Function(int userId) writeOwner,
  required Future<void> Function(int userId) writeMyUserId,
  required Future<void> Function() clearSlotData,
  void Function(int? previousOwner, int newOwner)? onOwnerChanged,
}) async {
  if (userId == null) return;
  final owner = await readOwner();
  if (slotOwnerChanged(storedOwner: owner, userId: userId)) {
    onOwnerChanged?.call(owner, userId);
    await clearSlotData();
    await writeOwner(userId);
  }
  await writeMyUserId(userId);
}
