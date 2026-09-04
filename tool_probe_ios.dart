// Диагностика: отправляет ли сервер код, если представиться как IOS.
//
// В официальном iOS-приложении MAX капчи нет и код приходит сразу, а на
// ANDROID-пути сервер отвечает «Captcha creation disabled» и код не шлёт.
//
// Запуск: dart run tool_probe_ios.dart <номер>
// Уходит РОВНО ОДИН запрос кода: попытки ограничены (requestCountLeft).
//
// userAgent собран здесь вручную (те же поля и порядок, что в
// DeviceProfile._iosUserAgent): DeviceProfile тянет dart:ui и
// device_info_plus, а этот скрипт запускается чистым `dart run`.
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:max_vektor/core/constants.dart';
import 'package:max_vektor/data/max/max_client.dart';

Map<String, Object?> _iosUserAgent(String _) => {
      'deviceType': 'IOS',
      'pushDeviceType': 'APNS',
      'appVersion': MaxProto.appVersion,
      'arch': 'arm64',
      'buildNumber': MaxProto.appBuild,
      'osVersion': '18.6',
      'locale': MaxProto.locale,
      'deviceLocale': MaxProto.deviceLocale,
      'deviceName': 'iPhone15,2',
      'screen': '1179x2556',
      'timezone': 'Europe/Moscow',
    };

Future<void> main(List<String> argv) async {
  if (argv.isEmpty) {
    stdout.writeln('нужен номер: dart run tool_probe_ios.dart +7...');
    return;
  }
  final phone = argv.first;
  final client = MaxClient(
    logger: Logger(
      level: Level.all,
      filter: ProductionFilter(),
      printer: SimplePrinter(),
    ),
    userAgentLoader: (deviceType, {seed}) async => _iosUserAgent(deviceType),
  );
  try {
    await client.connect(deviceType: 'IOS');
    stdout.writeln('INIT (IOS): принят');

    final link = await client.captchaSessionLink(phone);
    stdout.writeln(
        link == null ? 'капча: не требуется' : 'капча: требуется — $link');

    final c = await client.startAuthSms(phone);
    stdout.writeln('AUTH_REQUEST (IOS): код из ${c.codeLength} цифр, '
        'попыток осталось ${c.attemptsLeft}');
  } catch (e) {
    stdout.writeln('ошибка: $e');
  } finally {
    await client.close();
  }
}
