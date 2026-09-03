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

  /// Собственная БД Max Vektor. Namespace отделён от апстрима, чтобы
  /// данные не пересекались ни с оригинальным форком, ни с официальным MAX.
  static const String dbName = 'max_vektor.db';

  /// Ключи secure storage с префиксом `mv_`: Keychain и так изолирован
  /// bundle id (ru.vektor.max), но собственный namespace исключает любое
  /// случайное пересечение при общем keychain access group.
  static const String secureTokenKey = 'mv_max_auth_token';
  static const String prefMyUserIdKey = 'mv_my_max_user_id';
  static const String tokenKindKey = 'mv_max_token_kind';

  /// Стабильный идентификатор устройства. Генерируется один раз и хранится
  /// в secure storage. Переживает logout/login (это физически то же
  /// устройство), переустановку — нет. Регенерация при каждом запуске
  /// выглядит для антифрода MAX как поток новых устройств на одном номере.
  static const String deviceIdKey = 'mv_max_device_id';
}
