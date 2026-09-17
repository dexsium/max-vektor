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
///
/// Сам буфер живёт только в памяти и остаётся ЧИСТЫМ Dart без Flutter-
/// плагинов — его подключает и консольный клиент (bin/max_vektor_cli.dart,
/// `dart compile exe`, плагины недоступны). Персистентность на диск (чтобы
/// диагностика переживала крэш/OS-килл/принудительное закрытие — самое
/// интересное для «почему выкинуло» обычно происходит именно в сессии,
/// которая не доживает до открытия экрана диагностики) подключается СВЕРХУ
/// через [onLine]/[onClear] — только Flutter-приложением, см.
/// core/diagnostics_session.dart.
class MvLogBuffer {
  const MvLogBuffer._();

  static const int _cap = 800;
  static final List<String> _lines = <String>[];

  /// Вызывается на каждую новую строку — точка подключения персистентности.
  static void Function(String line)? onLine;

  /// Вызывается при очистке буфера пользователем («Очистить» на экране
  /// диагностики) — точка подключения очистки персистентного файла.
  static void Function()? onClear;

  static void add(String line) {
    _lines.add(line);
    if (_lines.length > _cap) _lines.removeRange(0, _lines.length - _cap);
    onLine?.call(line);
  }

  /// Все накопленные строки одним текстом (для копирования/отправки).
  static String dump() => _lines.join('\n');

  static void clear() {
    _lines.clear();
    onClear?.call();
  }

  /// Заполнить буфер сохранённым с прошлого запуска хвостом ДО первого
  /// реального лога текущей сессии — так после крэша/перезапуска в
  /// диагностике видна история, а не только события с этого запуска.
  /// Не трогает [onLine]/[onClear].
  static void seed(Iterable<String> lines) {
    _lines
      ..clear()
      ..addAll(lines);
  }

  static int get length => _lines.length;
}

/// Принтер с единым префиксом приложения.
///
/// Никаких стектрейсов и рамок для ОБЫЧНЫХ событий — одна строка на
/// событие, чтобы лог физического устройства читался в Xcode-консоли.
/// Исключение — error/fatal (см. [severe] ниже): туда попадают только
/// настоящие крэши (FlutterError.onError/PlatformDispatcher.onError/
/// runZonedGuarded в main.dart), они редкие, и БЕЗ трассировки бесполезны —
/// «что-то упало» без указания где не помогает чинить. Каждая строка также
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
    if (severe && event.stackTrace != null) {
      lines.add('$ts $prefix stack: ${event.stackTrace}');
    }
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
