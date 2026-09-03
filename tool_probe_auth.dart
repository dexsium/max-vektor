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

Future<void> main() async {
  final client = MaxClient(logger: Logger(printer: SimplePrinter()));
  _say('proto v${MaxProto.protoVersion}, app ${MaxProto.appVersion}, '
      'build ${MaxProto.appBuild}');
  try {
    await client.connect();
    _say('INIT: ok — handshake сервер принял');
    try {
      await client.startAuthSms(_invalidPhone);
      _say('AUTH_REQUEST: неожиданно принят (номер должен быть невалиден)');
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
