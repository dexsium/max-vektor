/// Константы протокола MAX и приложения.
class MaxProto {
  static const String host = 'api.oneme.ru';
  static const int port = 443;
  static const int protoVersion = 10;
  /// Версия официального клиента MAX, которой представляется приложение.
  ///
  /// ЭТО ЗНАЧЕНИЕ ПРОТУХАЕТ. Сервер сверяет его при AUTH_REQUEST (op 17) и
  /// на устаревшем клиенте отвечает cmd=3 с текстом «Приложение устарело,
  /// пожалуйста, обновитесь» — INIT при этом проходит, так что проблема
  /// выглядит как поломка авторизации.
  ///
  /// 26.30.0 — версия из RuStore на 01.09.2026 (package ru.oneme.app),
  /// проверена вживую: с ней AUTH_REQUEST принимается.
  /// Как обновить, когда снова протухнет, — см. `tool_probe_auth.dart`
  /// и раздел README «Сервер отвечает „Приложение устарело“».
  static const String appVersion = '26.30.0';

  /// versionCode официального APK. Идёт в userAgent.buildNumber.
  ///
  /// ВНИМАНИЕ: 6689 — versionCode версии 26.15.0, для 26.30.0 он не
  /// подтверждён (в открытых источниках versionCode не публикуется).
  /// Сервер его не проверяет — AUTH_REQUEST с этой парой проходит, — но
  /// пара «26.30.0 + 6689» формально рассогласована. Если найдёте реальный
  /// versionCode для текущей [appVersion], поставьте его сюда.
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
  /// PING (heartbeat). Официальный клиент шлёт его каждые 15 сек
  /// (frk.java: heartbeat(15)); без него сервер рвёт сокет.
  static const int ping = 1;
  static const int init = 6;
  static const int profile = 16;
  static const int authRequest = 17;
  static const int authConfirm = 18;
  static const int login = 19;

  /// CONFIG (op 22): пользовательские настройки приватности —
  /// {settings: {user: {app.privacy.*: ALL|CONTACTS|NOBODY}}}.
  /// Источник: web.max.ru (send 22 {settings:{user}}) + APK (izi.java).
  static const int config = 22;

  /// Завершение регистрации нового аккаунта:
  /// `{token, tokenType: 'REGISTER', firstName, lastName?, photoId?}`.
  /// Источник: модуль авторизации веб-клиента web.max.ru.
  static const int register = 23;

  /// Авто-удаление профиля по неактивности:
  /// PROFILE_DELETE_TIME (op 200) — задать срок (app.privacy.inactive.ttl:
  /// 1M/3M/6M). Источник: APK (jl4.java, izi.java).
  static const int profileDeleteTime = 200;

  /// Создание сессии капчи перед запросом кода:
  /// `{source: 'auth', identifier: <phone>}` → `{link}`.
  /// Источник: модуль авторизации веб-клиента web.max.ru.
  static const int captchaSession = 224;

  /// Генерация QR для входа: `{type: 0}` →
  /// `{token/trackId, qrLink, expiresAt, pollingInterval}`.
  static const int qrStart = 112;

  /// Опрос статуса QR: `{trackId}` → `{status: {loginAvailable, expiresAt}}`.
  static const int qrPoll = 104;

  /// Подтверждение входа по QR со стороны СКАНЕРА (уже залогинен):
  /// клиент сканирует QR другого устройства и авторизует его вход.
  /// Опкод из официального APK (wkc.AUTH_QR_APPROVE). Единственный QR-опкод
  /// мобильного клиента — он только подтверждающий, QR сам не генерирует.
  static const int qrApprove = 290;
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
  static const String version = '0.11.0';

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
