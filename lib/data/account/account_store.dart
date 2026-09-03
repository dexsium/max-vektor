import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/constants.dart';
import 'account.dart';

/// Реестр аккаунтов: список и активный аккаунт.
///
/// Живёт в общем (не привязанном к аккаунту) Keychain-контейнере
/// Max Vektor. Сами токены здесь НЕ хранятся — они лежат в
/// per-account хранилище (`SecureStorage`), у каждого свой набор ключей.
class AccountStore {
  AccountStore([FlutterSecureStorage? backend])
      : _backend = backend ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _backend;

  static const String _accountsKey = 'mv_accounts_v1';
  static const String _activeKey = 'mv_active_account_v1';
  static const String _seqKey = 'mv_account_seq_v1';

  /// Больше аккаунтов одновременно держать смысла нет: каждый — это живое
  /// TLS-соединение к серверу MAX с одного устройства.
  static const int maxAccounts = 5;

  Future<List<MvAccount>> list() async =>
      MvAccount.decodeList(await _backend.read(key: _accountsKey));

  Future<void> _save(List<MvAccount> accounts) =>
      _backend.write(key: _accountsKey, value: MvAccount.encodeList(accounts));

  Future<String?> activeId() => _backend.read(key: _activeKey);

  Future<void> setActive(String id) =>
      _backend.write(key: _activeKey, value: id);

  /// Следующий свободный id вида `acc3`. Счётчик только растёт — id
  /// удалённого аккаунта не переиспользуется, иначе новый аккаунт
  /// унаследовал бы его `deviceId` и остатки данных.
  Future<String> _nextId() async {
    final raw = await _backend.read(key: _seqKey);
    final next = (int.tryParse(raw ?? '') ?? 0) + 1;
    await _backend.write(key: _seqKey, value: '$next');
    return 'acc$next';
  }

  /// Завести новый пустой аккаунт (вход в него ещё предстоит).
  Future<MvAccount> create() async {
    final accounts = await list();
    if (accounts.length >= maxAccounts) {
      throw StateError('Больше $maxAccounts аккаунтов добавить нельзя');
    }
    final account = MvAccount(id: await _nextId());
    await _save([...accounts, account]);
    return account;
  }

  Future<void> update(MvAccount account) async {
    final accounts = await list();
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx < 0) return;
    final copy = [...accounts]..[idx] = account;
    await _save(copy);
  }

  /// Полное удаление аккаунта: запись реестра, ключи Keychain, файл БД и
  /// каталог медиа. Возвращает id аккаунта, который стал активным, или null,
  /// если аккаунтов не осталось.
  Future<String?> remove(String id) async {
    final accounts = await list();
    final rest = accounts.where((a) => a.id != id).toList();
    await _save(rest);
    await purgeAccountData(id);

    final active = await activeId();
    if (active != id) return active;
    final next = rest.isEmpty ? null : rest.first.id;
    if (next == null) {
      await _backend.delete(key: _activeKey);
    } else {
      await setActive(next);
    }
    return next;
  }

  /// Стереть локальные данные аккаунта, не трогая реестр.
  Future<void> purgeAccountData(String accountId) async {
    for (final suffix in AppMeta.accountKeySuffixes) {
      await _backend.delete(key: AppMeta.accountKey(accountId, suffix));
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final db = File(p.join(docs.path, AppMeta.dbNameFor(accountId)));
      if (db.existsSync()) await db.delete();
      final media = Directory(p.join(docs.path, AppMeta.mediaDirFor(accountId)));
      if (media.existsSync()) await media.delete(recursive: true);
    } catch (_) {
      // Нет файловой системы (тест/desktop без path_provider) — реестр уже
      // почищен, этого достаточно.
    }
  }

  /// Разовый перенос данных из одноаккаунтной версии.
  ///
  /// Старая сборка держала токен в ключах без account-namespace и базу в
  /// `max_vektor.db`. Если реестр пуст, а старый токен есть — заводим из
  /// него первый аккаунт, чтобы человек не остался без сессии после
  /// обновления.
  Future<void> migrateLegacyIfNeeded(MvAccount account) async {
    for (final entry in AppMeta.legacyKeyMigration.entries) {
      final value = await _backend.read(key: entry.key);
      if (value == null) continue;
      final target = AppMeta.accountKey(account.id, entry.value);
      if (await _backend.read(key: target) == null) {
        await _backend.write(key: target, value: value);
      }
      await _backend.delete(key: entry.key);
    }
    try {
      final docs = await getApplicationDocumentsDirectory();
      final legacyDb = File(p.join(docs.path, AppMeta.legacyDbName));
      final target = File(p.join(docs.path, AppMeta.dbNameFor(account.id)));
      if (legacyDb.existsSync() && !target.existsSync()) {
        await legacyDb.rename(target.path);
      }
      final legacyMedia =
          Directory(p.join(docs.path, AppMeta.legacyMediaDirName));
      final targetMedia =
          Directory(p.join(docs.path, AppMeta.mediaDirFor(account.id)));
      if (legacyMedia.existsSync() && !targetMedia.existsSync()) {
        await legacyMedia.rename(targetMedia.path);
      }
    } catch (_) {
      // Файлов нет или ФС недоступна — не критично, аккаунт просто начнёт
      // с пустой локальной историей.
    }
  }

  /// Активный аккаунт для запуска приложения: берём сохранённый, а если
  /// аккаунтов ещё нет — заводим первый и подтягиваем в него legacy-данные.
  Future<({List<MvAccount> accounts, String activeId})> bootstrap() async {
    var accounts = await list();
    if (accounts.isEmpty) {
      final first = await create();
      await migrateLegacyIfNeeded(first);
      await setActive(first.id);
      accounts = [first];
      return (accounts: accounts, activeId: first.id);
    }
    final saved = await activeId();
    final exists = accounts.any((a) => a.id == saved);
    final active = exists ? saved! : accounts.first.id;
    if (!exists) await setActive(active);
    return (accounts: accounts, activeId: active);
  }
}
