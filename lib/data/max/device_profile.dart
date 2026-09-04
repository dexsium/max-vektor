import 'dart:ui' as ui;

import 'package:device_info_plus/device_info_plus.dart';

import '../../core/constants.dart';

/// Сборка поля `userAgent` для SESSION_INIT (opcode 6).
///
/// Зачем: урезанный userAgent (`deviceType/locale/appVersion`) сам по себе
/// отличает клиент от официального. Реверс протокола (gist koval01,
/// openmax-server) показывает полный набор из 11 полей в строгом порядке:
/// `pushDeviceType` обязан идти ВТОРЫМ, `deviceType` — в верхнем регистре.
/// Сервер MAX не проверяет TLS/JA3, поэтому самосогласованный правдоподобный
/// userAgent безопасен и убирает дешёвый сигнал «не родной клиент».
///
/// Обогащаем только ANDROID-путь (там, где идут SMS-входы и баны). WEB и
/// прочее оставляем минимальными — этот путь (вход по веб-токену) уже
/// работает, а официальный WEB-userAgent не реверснут, ломать его смысла нет.
///
/// Порядок ключей сохраняется: литералы Map в Dart — LinkedHashMap, msgpack
/// сериализует в порядке вставки.
class DeviceProfile {
  const DeviceProfile._();

  static Future<Map<String, Object?>> userAgent(String deviceType,
      {String? seed}) async {
    if (deviceType == 'IOS') {
      return _iosUserAgent(seed);
    }
    if (deviceType != 'ANDROID') {
      return minimal(deviceType);
    }

    var arch = 'arm64-v8a';
    var osVersion = '34';
    var deviceName = 'Android';
    var realAndroid = false;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.supportedAbis.isNotEmpty) {
        arch = info.supportedAbis.first;
      }
      osVersion = '${info.version.sdkInt}';
      final man = info.manufacturer.trim();
      final model = info.model.trim();
      final name = man.isEmpty ? model : '$man $model';
      if (name.trim().isNotEmpty) deviceName = name.trim();
      realAndroid = true;
    } catch (_) {
      // Нет нативного канала (iOS/desktop/CLI/тест) — остаются дефолты.
    }

    // Экран берём с устройства ТОЛЬКО на настоящем Android.
    //
    // Иначе получался несуществующий отпечаток: шаблонные Android-поля
    // (deviceName «Android», sdk 34, arm64-v8a) вперемешку с реальным
    // разрешением iPhone. Для антифрода такая нестыковка заметнее, чем
    // ровный типовой профиль, а SMS-вход всегда идёт как ANDROID.
    var screen = '1080x2340';
    if (realAndroid) {
      try {
        final view = ui.PlatformDispatcher.instance.implicitView;
        final size = view?.physicalSize;
        if (size != null && size.width > 0 && size.height > 0) {
          screen = '${size.width.round()}x${size.height.round()}';
        }
      } catch (_) {}
    }

    // Порядок строго как у официального клиента (pushDeviceType — 2-й).
    return {
      'deviceType': 'ANDROID',
      'pushDeviceType': 'GCM',
      'appVersion': MaxProto.appVersion,
      'arch': arch,
      'buildNumber': MaxProto.appBuild,
      'osVersion': osVersion,
      'locale': MaxProto.locale,
      'deviceLocale': MaxProto.deviceLocale,
      'deviceName': deviceName,
      'screen': screen,
      'timezone': _ianaTimezone(),
    };
  }

  /// Согласованные iPhone-профили: (модель utsname.machine, разрешение экрана
  /// в пикселях). Пары модель↔экран реальные, чтобы отпечаток был внутренне
  /// непротиворечивым (несостыковка модель/экран для антифрода заметнее).
  static const _iphones = <(String, String)>[
    ('iPhone13,1', '1080x2340'), // 12 mini
    ('iPhone13,2', '1170x2532'), // 12 / 12 Pro
    ('iPhone13,4', '1284x2778'), // 12 Pro Max
    ('iPhone14,2', '1170x2532'), // 13 Pro
    ('iPhone14,3', '1284x2778'), // 13 Pro Max
    ('iPhone14,5', '1170x2532'), // 13
    ('iPhone14,7', '1170x2532'), // 14
    ('iPhone14,8', '1284x2778'), // 14 Plus
    ('iPhone15,2', '1179x2556'), // 14 Pro
    ('iPhone15,3', '1290x2796'), // 14 Pro Max
    ('iPhone15,4', '1179x2556'), // 15
    ('iPhone15,5', '1290x2796'), // 15 Plus
    ('iPhone16,1', '1179x2556'), // 15 Pro
    ('iPhone16,2', '1290x2796'), // 15 Pro Max
  ];

  static const _iosVersions = <String>[
    '17.4.1', '17.5.1', '17.6.1', '18.0.1', '18.1.1',
  ];

  /// userAgent для deviceType=IOS. Чтобы наш клиент выглядел для сервера как
  /// ОТДЕЛЬНЫЙ iPhone (а не то же устройство, что официальное приложение —
  /// иначе сервер по совпадающему отпечатку передаёт сессию нам и выкидывает
  /// официалку), поля устройства СИНТЕТИЧЕСКИЕ, а НЕ реальные: модель, экран и
  /// версия iOS берутся детерминированно из [seed] (стабильного deviceId
  /// аккаунта). Так профиль постоянен для аккаунта и отличается от настоящего
  /// телефона. deviceType/pushDeviceType остаются iOS/APNS.
  static Future<Map<String, Object?>> _iosUserAgent(String? seed) async {
    final h = _stableHash(seed ?? 'max-vektor');
    final model = _iphones[h % _iphones.length];
    final osVersion = _iosVersions[(h ~/ 7) % _iosVersions.length];

    return {
      'deviceType': 'IOS',
      'pushDeviceType': 'APNS',
      'appVersion': MaxProto.appVersion,
      'arch': 'arm64',
      'buildNumber': MaxProto.appBuild,
      'osVersion': osVersion,
      'locale': MaxProto.locale,
      'deviceLocale': MaxProto.deviceLocale,
      'deviceName': model.$1,
      'screen': model.$2,
      'timezone': _ianaTimezone(),
    };
  }

  /// Стабильный (между запусками) хеш строки — FNV-1a 32-bit. String.hashCode
  /// в Dart не гарантирован между запусками, поэтому свой.
  static int _stableHash(String s) {
    var hash = 0x811c9dc5;
    for (final c in s.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// Проверенный рабочим python-клиентом минимум — для WEB и fallback.
  static Map<String, Object?> minimal(String deviceType) => {
    'deviceType': deviceType,
    'locale': MaxProto.locale,
    'appVersion': MaxProto.appVersion,
  };

  /// Best-effort IANA-таймзона по смещению. Сервер таймзону жёстко не
  /// валидирует (у реальных клиентов она разная); важна правдоподобность.
  static String _ianaTimezone() {
    final off = DateTime.now().timeZoneOffset.inHours;
    switch (off) {
      case 2:
        return 'Europe/Kaliningrad';
      case 3:
        return 'Europe/Moscow';
      case 4:
        return 'Asia/Tbilisi';
      case 5:
        return 'Asia/Yekaterinburg';
      case 6:
        return 'Asia/Omsk';
      case 7:
        return 'Asia/Krasnoyarsk';
      case 8:
        return 'Asia/Irkutsk';
      case 9:
        return 'Asia/Yakutsk';
      case 10:
        return 'Asia/Vladivostok';
      case 11:
        return 'Asia/Magadan';
      case 12:
        return 'Asia/Kamchatka';
      default:
        return 'Europe/Moscow';
    }
  }
}
