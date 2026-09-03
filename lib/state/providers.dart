import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/constants.dart';
import '../core/logging.dart';
import '../data/account/account.dart';
import '../data/account/account_runtime.dart';
import '../data/account/account_store.dart';
import '../data/local/database.dart';
import '../data/local/secure_storage.dart';
import '../data/max/max_client.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/chats_repository.dart';
import '../data/repositories/contacts_repository.dart';
import '../data/repositories/media_repository.dart';
import '../data/repositories/messages_repository.dart';
import '../data/repositories/upload_repository.dart';

final loggerProvider = Provider<Logger>((ref) {
  return buildAppLogger();
});

final accountStoreProvider = Provider<AccountStore>((ref) => AccountStore());

/// Стартовое состояние аккаунтов, прочитанное в `main()` ДО `runApp`.
///
/// Переопределяется в `ProviderScope(overrides: ...)`. Благодаря этому
/// активный аккаунт известен синхронно и ни один провайдер не начинает
/// жизнь с `null`.
final accountsBootstrapProvider =
    Provider<({List<MvAccount> accounts, String activeId})>((ref) {
  throw UnimplementedError('accountsBootstrapProvider must be overridden');
});

/// Список аккаунтов приложения.
class AccountsController extends Notifier<List<MvAccount>> {
  @override
  List<MvAccount> build() => ref.watch(accountsBootstrapProvider).accounts;

  AccountStore get _store => ref.read(accountStoreProvider);

  Future<void> reload() async {
    state = await _store.list();
  }

  /// Обновить карточку аккаунта (номер, имя, userId) после входа.
  Future<void> update(MvAccount account) async {
    await _store.update(account);
    await reload();
  }

  /// Завести новый аккаунт и сразу сделать его активным — дальше UI покажет
  /// экран входа, потому что токена у него нет.
  Future<MvAccount> addAndActivate() async {
    final account = await _store.create();
    await reload();
    await ref.read(activeAccountIdProvider.notifier).switchTo(account.id);
    return account;
  }

  /// Выйти из аккаунта и удалить его локальные данные.
  ///
  /// Если это был последний аккаунт — на его месте заводится пустой, чтобы
  /// приложению всегда было куда показать экран входа.
  Future<void> signOutAndRemove(String accountId) async {
    await AccountRuntimes.close(accountId);
    final next = await _store.remove(accountId);
    if (next == null) {
      final fresh = await _store.create();
      await _store.setActive(fresh.id);
      await reload();
      ref.read(activeAccountIdProvider.notifier).setSilently(fresh.id);
      return;
    }
    await reload();
    ref.read(activeAccountIdProvider.notifier).setSilently(next);
  }
}

final accountsProvider = NotifierProvider<AccountsController, List<MvAccount>>(
  AccountsController.new,
);

/// Активный аккаунт. Смена этого значения перестраивает все зависимые
/// провайдеры — но НЕ рвёт соединения: они живут в [AccountRuntimes].
class ActiveAccountController extends Notifier<String> {
  @override
  String build() => ref.watch(accountsBootstrapProvider).activeId;

  Future<void> switchTo(String accountId) async {
    if (state == accountId) return;
    await ref.read(accountStoreProvider).setActive(accountId);
    state = accountId;
  }

  /// Установить активный аккаунт, когда запись в хранилище уже сделана
  /// (например после удаления аккаунта).
  void setSilently(String accountId) {
    if (state != accountId) state = accountId;
  }
}

final activeAccountIdProvider =
    NotifierProvider<ActiveAccountController, String>(
  ActiveAccountController.new,
);

/// Карточка активного аккаунта.
final activeAccountProvider = Provider<MvAccount>((ref) {
  final id = ref.watch(activeAccountIdProvider);
  final accounts = ref.watch(accountsProvider);
  return accounts.firstWhere(
    (a) => a.id == id,
    orElse: () => MvAccount(id: id),
  );
});

/// Живая сессия активного аккаунта.
final accountRuntimeProvider = Provider<AccountRuntime>((ref) {
  final id = ref.watch(activeAccountIdProvider);
  // Намеренно без ref.onDispose: закрытие сессии — дело выхода из аккаунта,
  // а не переключения на соседний.
  return AccountRuntimes.of(id, ref.watch(loggerProvider));
});

final secureStorageProvider = Provider<SecureStorage>(
  (ref) => ref.watch(accountRuntimeProvider).storage,
);

final maxClientProvider = Provider<MaxClient>(
  (ref) => ref.watch(accountRuntimeProvider).client,
);

final appDatabaseProvider = FutureProvider<AppDatabase>(
  (ref) => ref.watch(accountRuntimeProvider).database(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => ref.watch(accountRuntimeProvider).auth,
);

final uploadRepositoryProvider = FutureProvider<UploadRepository>(
  (ref) => ref.watch(accountRuntimeProvider).uploads(),
);

final messagesRepositoryProvider = FutureProvider<MessagesRepository>(
  (ref) => ref.watch(accountRuntimeProvider).messages(),
);

final chatsRepositoryProvider = FutureProvider<ChatsRepository>(
  (ref) => ref.watch(accountRuntimeProvider).chats(),
);

final contactsRepositoryProvider = FutureProvider<ContactsRepository>(
  (ref) => ref.watch(accountRuntimeProvider).contacts(),
);

final mediaRepositoryProvider = FutureProvider<MediaRepository>(
  (ref) => ref.watch(accountRuntimeProvider).media(),
);

/// Строка версии для экрана «О приложении»: «0.1.17 (сборка 7)».
///
/// Берётся из бандла, а не из константы: номер сборки подставляет CI
/// (`--build-number`), и захардкоженное значение врало бы. Если нативный
/// канал недоступен (тесты, desktop без плагина) — падаем на [AppMeta.version].
final appVersionLabelProvider = FutureProvider<String>((ref) async {
  try {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.isEmpty ? AppMeta.version : info.version;
    final build = info.buildNumber;
    return build.isEmpty ? version : '$version (сборка $build)';
  } catch (_) {
    return AppMeta.version;
  }
});
