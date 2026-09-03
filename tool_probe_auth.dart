// Диагностика авторизации MAX без сборки приложения.
//
// Зачем: сервер MAX сверяет версию клиента на AUTH_REQUEST (op 17). Когда
// MaxProto.appVersion протухает, вход перестаёт работать с ответом
// «Приложение устарело, пожалуйста, обновитесь», причём INIT (op 6)
// продолжает проходить — и поломка выглядит как что угодно, только не как
// версия. Этот скрипт показывает реальный ответ сервера за пару секунд,
// без пересборки под iOS.
//
// Запуск:  dart run tool_probe_auth.dart
//
// Номер намеренно ЗАВЕДОМО НЕВАЛИДНЫЙ: цель — увидеть ответ сервера, а не
// войти. Не подставляйте сюда реальный номер: на валидный номер сервер
// отправит настоящую SMS, а частые запросы кода — бан-сигнал.
import 'dart:io';

import 'package:logger/logger.dart';
import 'package:max_vektor/core/constants.dart';
import 'package:max_vektor/data/max/max_client.dart';

const String _invalidPhone = '+7000';

Future<void> main(List<String> argv) async {
  // Номер можно передать аргументом — ТОЛЬКО несуществующий, для разбора
  // ответа сервера. На реальный номер уйдёт настоящая SMS.
  final phone = argv.isEmpty ? _invalidPhone : argv.first;
  // ProductionFilter + level=all: DevelopmentFilter в `dart run` глушит
  // вывод, а нам нужен весь обмен, включая RESP с полями ответа.
  final client = MaxClient(
    logger: Logger(
      level: Level.all,
      filter: ProductionFilter(),
      printer: SimplePrinter(),
    ),
  );
  _say('proto v${MaxProto.protoVersion}, app ${MaxProto.appVersion}, '
      'build ${MaxProto.appBuild}');
  try {
    await client.connect();
    _say('INIT: ok — handshake сервер принял');
    try {
      final c = await client.startAuthSms(phone);
      _say('AUTH_REQUEST: принят. Код из ${c.codeLength} цифр, '
          'повтор через ${c.resendAfterMs}мс, '
          'попыток осталось ${c.attemptsLeft}.');
      _say('Структуру ответа смотрите в строке RESP op=17 выше: '
          'там видно, что сервер сообщает о доставке кода.');
      return;
    } catch (e) {
      _say('AUTH_REQUEST: $e');
      _say('');
      _say('Как читать ответ:');
      _say('  «Приложение устарело…» → протухла MaxProto.appVersion,');
      _say('     поставьте актуальную версию ru.oneme.app и повторите;');
      _say('  «Проверьте номер…»     → версия в порядке, сервер дошёл до');
      _say('     валидации номера — авторизация работает.');
    }
  } finally {
    await client.close();
  }
}

void _say(String line) => stdout.writeln(line);
