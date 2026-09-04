// Диагностика входа по QR: op 112 (генерация) и op 104 (опрос статуса).
//
// Безопасно: номер телефона не нужен, SMS не шлётся, финальный вход
// происходит только после реального сканирования официальным приложением
// (мы его не триггерим). Цель — увидеть точные имена полей ответа сервера.
//
// Запуск: dart run tool_probe_qr.dart
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:max_vektor/data/max/max_client.dart';

Map<String, Object?> _iosUa(String _) => {
      'deviceType': 'IOS',
      'pushDeviceType': 'APNS',
      'appVersion': '26.30.0',
      'arch': 'arm64',
      'buildNumber': 6689,
      'osVersion': '18.6',
      'locale': 'ru',
      'deviceLocale': 'ru_RU',
      'deviceName': 'iPhone15,2',
      'screen': '1179x2556',
      'timezone': 'Europe/Moscow',
    };

Future<void> main() async {
  final client = MaxClient(
    logger: Logger(
      level: Level.all,
      filter: ProductionFilter(),
      printer: SimplePrinter(),
    ),
    userAgentLoader: (d, {seed}) async => _iosUa(d),
  );
  try {
    await client.connect(deviceType: 'WEB');
    stdout.writeln('INIT ok');
    final start = await client.qrStart();
    stdout.writeln('QR_START ключи: ${start.keys.toList()}');
    stdout.writeln('QR_START ответ: $start');
    final trackId = (start['trackId'] ?? start['token'])?.toString();
    if (trackId != null) {
      final poll = await client.qrPoll(trackId);
      stdout.writeln('QR_POLL ответ: $poll');
    } else {
      stdout.writeln('trackId/token не найден — опрос пропущен');
    }
  } catch (e) {
    stdout.writeln('ошибка: $e');
  } finally {
    await client.close();
  }
}
