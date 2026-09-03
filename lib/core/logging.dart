import 'package:logger/logger.dart';

/// Release-сборка (`--release`). Намеренно НЕ используем `kDebugMode` из
/// `package:flutter/foundation.dart`: этот файл подключает и консольный
/// клиент `bin/max_vektor_cli.dart`, который компилируется чистым
/// `dart compile exe`, без Flutter.
const bool kMvReleaseBuild = bool.fromEnvironment('dart.vm.product');

/// Теги логов Max Vektor.
///
/// Формат строки в консоли: `[MaxVektor][AUTH] сообщение`.
/// Префикс `[MaxVektor]` добавляет [MaxVektorLogPrinter], доменный тег —
/// место вызова.
class MvTag {
  static const String auth = '[AUTH]';
  static const String socket = '[SOCKET]';
  static const String init = '[INIT]';
  static const String chat = '[CHAT]';
  static const String message = '[MESSAGE]';
  static const String error = '[ERROR]';
}

/// Принтер с единым префиксом приложения.
///
/// Никаких стектрейсов и рамок — одна строка на событие, чтобы лог
/// физического устройства читался в Xcode-консоли.
class MaxVektorLogPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final level = switch (event.level) {
      Level.trace => 'T',
      Level.debug => 'D',
      Level.info => 'I',
      Level.warning => 'W',
      Level.error => 'E',
      Level.fatal => 'F',
      _ => '?',
    };
    // Доменный тег ([AUTH], [SOCKET], ...) ставит место вызова — переносим
    // его из начала сообщения сразу за префиксом приложения, чтобы строка
    // читалась как [MaxVektor][AUTH][I] текст.
    final raw = event.message.toString();
    final match = RegExp(r'^(\[[A-Z]+\])\s*').firstMatch(raw);
    final domain = match?.group(1) ?? '';
    final body = match == null ? raw : raw.substring(match.end);
    final severe = event.level.index >= Level.error.index;
    final prefix =
        '[MaxVektor]${severe ? MvTag.error : ''}$domain[$level]';
    final lines = <String>['$prefix $body'];
    if (event.error != null) lines.add('$prefix cause: ${event.error}');
    return lines;
  }
}

/// В release оставляем только warning и выше: подробная трассировка
/// соединения и чатов нужна лишь в debug.
class _ReleaseFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level.index >= Level.warning.index;
}

/// Единая фабрика логгера приложения.
///
/// ВАЖНО: сюда нельзя отдавать auth-token, SMS-код, пароль 2FA и прочие
/// credentials. Для токенов есть [mvRedact].
Logger buildAppLogger() {
  return Logger(
    filter: kMvReleaseBuild ? _ReleaseFilter() : DevelopmentFilter(),
    printer: MaxVektorLogPrinter(),
  );
}

/// Безопасное представление секрета для лога: длина и хвост из 4 символов
/// (достаточно, чтобы отличить два токена, недостаточно, чтобы им
/// воспользоваться). `null` и пустая строка не раскрываются.
String mvRedact(String? secret) {
  if (secret == null) return '<null>';
  if (secret.isEmpty) return '<empty>';
  if (secret.length <= 4) return '<len=${secret.length}>';
  return '<len=${secret.length}, …${secret.substring(secret.length - 4)}>';
}
