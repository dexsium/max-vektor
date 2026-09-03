/// Константы протокола MAX и приложения.
class MaxProto {
  static const String host = 'api.oneme.ru';
  static const int port = 443;
  static const int protoVersion = 10;
  static const String appVersion = '26.15.0';

  /// versionCode официального APK (max_full.apk). Идёт в userAgent.buildNumber
  /// и должен быть согласован с [appVersion] (26.15.0 → 6689).
  static const int appBuild = 6689;
  static const String deviceType = 'ANDROID';
  static const String locale = 'ru';

  /// Полная локаль устройства для userAgent.deviceLocale (officical-формат).
  static const String deviceLocale = 'ru_RU';
}

/// Опкоды, известные на текущий момент.
/// Источник: реверс протокола в telega-to-max/max_client.py + декомпил APK
/// (см. docs/MEDIA_OPCODES.md).
class MaxOp {
  static const int init = 6;
  static const int profile = 16;
  static const int authRequest = 17;
  static const int authConfirm = 18;
  static const int login = 19;
  static const int contactInfo = 32;
  static const int contactByPhone = 46;
  static const int chatInfo = 48;
  static const int chatHistory = 49;
  static const int chatMedia = 51;
  static const int sendMessage = 64;
  static const int typing = 65;
  static const int editMessage = 67;
  static const int photoUpload = 80;
  static const int stickerUpload = 81;
  static const int videoUpload = 82;
  static const int videoPlay = 83;
  static const int fileUpload = 87;
  static const int fileDownload = 88;
  static const int sessionsInfo = 96;
  static const int sessionsClose = 97;
  static const int twoFa = 115;
  static const int notifAttach = 136;
  static const int transcribeMedia = 202;
  static const int notifTranscription = 293;
}

class AppMeta {
  static const String name = 'Max Vektor';

  /// Явная дисклеймер-строка для экрана «О приложении».
  static const String disclaimer = 'Unofficial MAX client';

  /// Версия приложения (держать синхронно с pubspec.yaml `version:`).
  static const String version = '0.1.17';

  /// Апстрим, из которого форкнут клиент.
  static const String upstreamUrl =
      'https://github.com/sansmaster1982/maxim-messenger';

  // ───────────────────── per-account namespace ─────────────────────
  //
  // Max Vektor держит несколько аккаунтов MAX сразу, поэтому ВСЁ, что
  // относится к конкретному аккаунту, живёт в собственном namespace:
  // ключи Keychain, файл SQLite, каталог медиа и deviceId. Общий префикс
  // `mv_` дополнительно отделяет приложение от чего угодно ещё в Keychain
  // (сам Keychain и так изолирован bundle id ru.vektor.max).

  /// Суффикс ключа: auth-token аккаунта.
  static const String tokenKeySuffix = 'token';

  /// Суффикс ключа: мой userId в MAX.
  static const String userIdKeySuffix = 'user_id';

  /// Суффикс ключа: тип токена ('web' или 'android').
  static const String tokenKindKeySuffix = 'token_kind';

  /// Суффикс ключа: стабильный deviceId аккаунта.
  ///
  /// deviceId генерируется ОДИН раз на аккаунт и переживает logout/login:
  /// регенерация на каждом запуске для антифрода MAX выглядит как поток
  /// новых устройств на одном номере. При этом у разных аккаунтов
  /// deviceId разные — иначе сервер видит один и тот же «телефон»,
  /// с которого одновременно живут несколько номеров.
  static const String deviceIdKeySuffix = 'device_id';

  static const List<String> accountKeySuffixes = [
    tokenKeySuffix,
    userIdKeySuffix,
    tokenKindKeySuffix,
    deviceIdKeySuffix,
  ];

  /// Полное имя ключа Keychain для аккаунта.
  static String accountKey(String accountId, String suffix) =>
      'mv_a_${accountId}_$suffix';

  /// Файл SQLite аккаунта.
  static String dbNameFor(String accountId) => 'max_vektor_$accountId.db';

  /// Каталог скачанных медиа аккаунта (внутри Documents).
  static String mediaDirFor(String accountId) => 'max_vektor_media/$accountId';

  // ───────────────────── миграция с одноаккаунтной версии ─────────────────

  static const String legacyDbName = 'max_vektor.db';
  static const String legacyMediaDirName = 'max_vektor_media';

  /// Старый ключ → суффикс нового per-account ключа.
  static const Map<String, String> legacyKeyMigration = {
    'mv_max_auth_token': tokenKeySuffix,
    'mv_my_max_user_id': userIdKeySuffix,
    'mv_max_token_kind': tokenKindKeySuffix,
    'mv_max_device_id': deviceIdKeySuffix,
  };
}
