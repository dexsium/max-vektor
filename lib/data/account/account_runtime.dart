import 'package:logger/logger.dart';

import '../../core/logging.dart';
import '../local/database.dart';
import '../local/secure_storage.dart';
import '../max/device_profile.dart';
import '../max/max_client.dart';
import '../repositories/auth_repository.dart';
import '../repositories/chats_repository.dart';
import '../repositories/contacts_repository.dart';
import '../repositories/media_repository.dart';
import '../repositories/messages_repository.dart';
import '../repositories/upload_repository.dart';

/// Живая сессия одного аккаунта: соединение, база и репозитории.
///
/// Ключевая идея мультиаккаунта: runtime НЕ уничтожается при переключении
/// на другой аккаунт. Соединение остаётся поднятым, поэтому возврат к
/// аккаунту не вызывает повторный LOGIN. Частые LOGIN с одного устройства —
/// главный поведенческий сигнал для антифрода MAX (см. `ReconnectPolicy`
/// и его throttle), и мультиаккаунт не должен его провоцировать.
///
/// Runtime закрывается только явно: при выходе из аккаунта или его удалении.
class AccountRuntime {
  AccountRuntime._(this.accountId, this._log)
      : storage = SecureStorage(accountId) {
    client = MaxClient(
      logger: _log,
      // deviceId стабилен внутри аккаунта и РАЗНЫЙ у разных аккаунтов:
      // ключ в Keychain содержит accountId (см. SecureStorage).
      deviceIdLoader: storage.readOrCreateDeviceId,
      userAgentLoader: DeviceProfile.userAgent,
    );
    auth = AuthRepository(
      client: client,
      storage: storage,
      logger: _log,
    );
  }

  final String accountId;
  final Logger _log;

  final SecureStorage storage;
  late final MaxClient client;
  late final AuthRepository auth;

  AppDatabase? _db;
  UploadRepository? _uploads;
  MessagesRepository? _messages;
  ChatsRepository? _chats;
  ContactsRepository? _contacts;
  MediaRepository? _media;

  Future<AppDatabase> database() async =>
      _db ??= await AppDatabase.forAccount(accountId);

  Future<UploadRepository> uploads() async {
    if (_uploads != null) return _uploads!;
    return _uploads = UploadRepository(
      client: client,
      db: await database(),
      logger: _log,
    );
  }

  Future<MessagesRepository> messages() async {
    if (_messages != null) return _messages!;
    final repo = MessagesRepository(
      client: client,
      db: await database(),
      storage: storage,
      uploader: await uploads(),
      logger: _log,
    );
    await repo.start();
    return _messages = repo;
  }

  Future<ChatsRepository> chats() async =>
      _chats ??= ChatsRepository(client: client, db: await database());

  Future<ContactsRepository> contacts() async =>
      _contacts ??= ContactsRepository(client: client, db: await database());

  Future<MediaRepository> media() async {
    if (_media != null) return _media!;
    return _media = MediaRepository(
      client: client,
      db: await database(),
      logger: _log,
    );
  }

  /// Полное закрытие: подписки, HTTP-клиент загрузок, сокет, база.
  Future<void> dispose() async {
    await _messages?.stop();
    _uploads?.close();
    await client.close();
    await AppDatabase.closeAccount(accountId);
    _db = null;
    _uploads = null;
    _messages = null;
    _chats = null;
    _contacts = null;
    _media = null;
  }
}

/// Пул живых сессий аккаунтов.
///
/// Живёт вне Riverpod намеренно: провайдеры пересоздаются при смене
/// активного аккаунта, а соединения — нет.
class AccountRuntimes {
  const AccountRuntimes._();

  static final Map<String, AccountRuntime> _runtimes = {};

  /// Сессия аккаунта, поднимается при первом обращении.
  static AccountRuntime of(String accountId, Logger log) {
    final existing = _runtimes[accountId];
    if (existing != null) return existing;
    log.i('${MvTag.auth} поднимаем сессию аккаунта $accountId');
    return _runtimes[accountId] = AccountRuntime._(accountId, log);
  }

  /// Открыт ли уже аккаунт (полезно, чтобы не будить соединение зря).
  static bool isOpen(String accountId) => _runtimes.containsKey(accountId);

  static Future<void> close(String accountId) async {
    final runtime = _runtimes.remove(accountId);
    if (runtime == null) return;
    await runtime.dispose();
  }

  static Future<void> closeAll() async {
    final ids = _runtimes.keys.toList();
    for (final id in ids) {
      await close(id);
    }
  }
}
