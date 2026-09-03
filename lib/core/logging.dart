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

/// Кольцевой буфер последних строк лога — для экрана диагностики в
/// приложении (release-сборку не подключить к Xcode-консоли, поэтому логи
/// показываем прямо в UI и даём скопировать). Токены/коды сюда не попадают:
/// они уже замаскированы [mvRedact] на месте вызова.
class MvLogBuffer {
  const MvLogBuffer._();

  static const int _cap = 800;
  static final List<String> _lines = <String>[];

  static void add(String line) {
    _lines.add(line);
    if (_lines.length > _cap) _lines.removeRange(0, _lines.length - _cap);
  }

  /// Все накопленные строки одним текстом (для копирования/отправки).
  static String dump() => _lines.join('\n');

  static void clear() => _lines.clear();

  static int get length => _lines.length;
}

/// Принтер с единым префиксом приложения.
///
/// Никаких стектрейсов и рамок — одна строка на событие, чтобы лог
/// физического устройства читался в Xcode-консоли. Каждая строка также
/// уходит в [MvLogBuffer] для экрана диагностики.
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
    final ts = DateTime.now().toIso8601String().substring(11, 19);
    final lines = <String>['$ts $prefix $body'];
    if (event.error != null) lines.add('$ts $prefix cause: ${event.error}');
    for (final l in lines) {
      MvLogBuffer.add(l);
    }
    return lines;
  }
}

/// В release пропускаем info и выше (не trace/debug): нужно для экрана
/// диагностики — трассировка соединения и чатов идёт на уровне info.
class _ReleaseFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) => event.level.index >= Level.info.index;
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
