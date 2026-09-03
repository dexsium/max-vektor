import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';

/// Secure storage ОДНОГО аккаунта.
///
/// Все ключи получают namespace аккаунта (`mv_a_<accountId>_...`), поэтому
/// токены, userId и deviceId разных аккаунтов физически не пересекаются,
/// а удаление аккаунта — это удаление его ключей, без риска задеть соседний.
class SecureStorage {
  SecureStorage(this.accountId, [FlutterSecureStorage? backend])
      : _backend = backend ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  /// Идентификатор аккаунта, чьи данные обслуживает это хранилище.
  final String accountId;

  final FlutterSecureStorage _backend;

  String _key(String suffix) => AppMeta.accountKey(accountId, suffix);

  Future<String?> readToken() =>
      _backend.read(key: _key(AppMeta.tokenKeySuffix));
  Future<void> writeToken(String token) =>
      _backend.write(key: _key(AppMeta.tokenKeySuffix), value: token);
  Future<void> deleteToken() =>
      _backend.delete(key: _key(AppMeta.tokenKeySuffix));

  Future<int?> readMyUserId() async {
    final v = await _backend.read(key: _key(AppMeta.userIdKeySuffix));
    if (v == null) return null;
    return int.tryParse(v);
  }

  Future<void> writeMyUserId(int id) =>
      _backend.write(key: _key(AppMeta.userIdKeySuffix), value: '$id');
  Future<void> deleteMyUserId() =>
      _backend.delete(key: _key(AppMeta.userIdKeySuffix));

  /// Тип устройства, под которым выдан токен: 'web' (веб-токен из
  /// web.max.ru) или 'android' (вход по SMS). Нужно чтобы при восстановлении
  /// сессии слать серверу тот же deviceType — иначе токен не примут.
  Future<String?> readTokenKind() =>
      _backend.read(key: _key(AppMeta.tokenKindKeySuffix));
  Future<void> writeTokenKind(String kind) =>
      _backend.write(key: _key(AppMeta.tokenKindKeySuffix), value: kind);

  /// Вернуть стабильный deviceId аккаунта, создав его при первом обращении.
  ///
  /// Формат — UUID v4 (как в рабочем python-клиенте telega-to-max, сервер
  /// такой принимает). Два свойства одновременно:
  ///
  /// * СТАБИЛЬНОСТЬ внутри аккаунта — не стирается при logout, живёт всю
  ///   установку. Новый deviceId на каждый запуск антифрод MAX читает как
  ///   поток новых устройств на одном номере;
  /// * РАЗЛИЧИЕ между аккаунтами — ключ содержит accountId, поэтому каждый
  ///   аккаунт получает свой UUID. Иначе сервер видел бы одно устройство,
  ///   на котором одновременно живут несколько номеров.
  Future<String> readOrCreateDeviceId() async {
    final key = _key(AppMeta.deviceIdKeySuffix);
    final existing = await _backend.read(key: key);
    if (existing != null && existing.isNotEmpty) return existing;
    final created = const Uuid().v4();
    await _backend.write(key: key, value: created);
    return created;
  }

  /// Сброс deviceId — только для явного «отвязать устройство». В обычный
  /// wipe() при logout НЕ входит.
  Future<void> deleteDeviceId() =>
      _backend.delete(key: _key(AppMeta.deviceIdKeySuffix));

  Future<void> wipe() async {
    await deleteToken();
    await deleteMyUserId();
    await _backend.delete(key: _key(AppMeta.tokenKindKeySuffix));
  }
}
