// Диагностика: требует ли сервер MAX капчу перед запросом кода (op 224).
//
// Номер — заведомо несуществующий: проверяем реакцию сервера, а не входим.
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:max_vektor/data/max/max_client.dart';

Future<void> main(List<String> argv) async {
  final phone = argv.isEmpty ? '+70001234567' : argv.first;
  final client = MaxClient(
    logger: Logger(
      level: Level.all,
      filter: ProductionFilter(),
      printer: SimplePrinter(),
    ),
  );
  try {
    await client.connect();
    final link = await client.captchaSessionLink(phone);
    stdout.writeln(link == null
        ? 'КАПЧА НЕ ТРЕБУЕТСЯ: сервер не вернул ссылку'
        : 'КАПЧА ТРЕБУЕТСЯ: $link');
  } finally {
    await client.close();
  }
}
