import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'logging.dart';

/// Отдельный логгер модуля — те же префикс/формат/таймстемп, что у всего
/// остального лога (см. [buildAppLogger]), чтобы банер запуска и переходы
/// жизненного цикла не выделялись из общей ленты диагностики.
final _log = buildAppLogger();

/// Персистентность буфера диагностики + криминалистика запуска.
///
/// Flutter-only (path_provider/device_info_plus/package_info_plus) — НЕ
/// подключается в core/logging.dart, который остаётся чистым Dart для
/// консольного клиента (bin/max_vektor_cli.dart). Подключается только из
/// main.dart Flutter-приложения.
///
/// Зачем это вообще нужно: раньше [MvLogBuffer] жил только в памяти. Самое
/// интересное для вопроса «почему выкинуло после закрытия приложения» —
/// именно та сессия, что НЕ доживает до открытия экрана диагностики (крэш,
/// принудительное закрытие пользователем, OS убила процесс в фоне под
/// нехваткой памяти — обычное дело для приложения без UIBackgroundModes).
/// Без сохранения на диск эти логи пропадали ровно тогда, когда были нужнее
/// всего.
class MvDiagnosticsSession {
  const MvDiagnosticsSession._();

  static const String _logFileName = 'diagnostics.log';
  static const String _markerFileName = 'session_marker.txt';

  /// Порог ротации файла лога — держим только последнюю треть, когда
  /// перевалили за это (дёшево: обрезка по строкам, не по байтам ровно).
  static const int _rotateAtBytes = 512 * 1024;

  static const Duration _flushInterval = Duration(seconds: 3);

  static File? _logFile;
  static File? _markerFile;
  static final List<String> _pending = [];
  static Timer? _flushTimer;

  /// Вызывать в самом начале main(), ДО runApp. Восстанавливает сохранённый
  /// с прошлого запуска хвост лога, разбирает маркер предыдущей сессии
  /// (криминалистика — см. [_readPreviousMarker]) и пишет банер с
  /// устройством/версией/причиной для НАЧАЛА текущей сессии.
  static Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logFile = File(p.join(dir.path, _logFileName));
      _markerFile = File(p.join(dir.path, _markerFileName));

      if (await _logFile!.exists()) {
        final prev = await _logFile!.readAsString();
        final lines = prev.split('\n').where((l) => l.isNotEmpty);
        MvLogBuffer.seed(lines);
      }
    } catch (_) {
      // Нет доступа к ФС (тест/desktop без path_provider) — диагностика
      // просто не переживёт перезапуск, само приложение не страдает.
      _logFile = null;
      _markerFile = null;
    }

    MvLogBuffer.onLine = (line) => _pending.add(line);
    MvLogBuffer.onClear = () {
      _pending.clear();
      final file = _logFile;
      if (file != null) unawaited(_clearFile(file));
    };
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(_flushInterval, (_) => unawaited(flush()));

    final previous = await _readPreviousMarker();
    await _writeMarker('launching');
    await _logStartupBanner(previous);
  }

  /// Разбор маркера, оставленного ПРЕДЫДУЩИМ запуском: последнее известное
  /// состояние жизненного цикла и когда оно было записано. Если маркер
  /// говорит `paused`/`inactive`/`hidden` и прошло много времени — сильный
  /// намёк, что ОС тихо убила свёрнутое приложение (никакого крэша, просто
  /// «закрыл — а там разлогинило», самая частая жалоба, для которой раньше
  /// не было вообще никаких улик). Если маркер остался `resumed` или
  /// `launching` — приложение убито/упало АКТИВНО на переднем плане, это
  /// уже больше похоже на крэш, чем на обычное сворачивание.
  static Future<String?> _readPreviousMarker() async {
    final file = _markerFile;
    if (file == null) return null;
    try {
      if (!await file.exists()) return null;
      return (await file.readAsString()).trim();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _logStartupBanner(String? previousMarker) async {
    final lines = <String>['════ ЗАПУСК ═══════════════════════════'];

    // Криминалистика предыдущего завершения.
    if (previousMarker == null || previousMarker.isEmpty) {
      lines.add('предыдущая сессия: нет данных (первый запуск или файл '
          'маркера недоступен)');
    } else {
      final parts = previousMarker.split('|');
      final state = parts.isNotEmpty ? parts[0] : previousMarker;
      final tsRaw = parts.length > 1 ? parts[1] : null;
      final ts = tsRaw == null ? null : DateTime.tryParse(tsRaw);
      final ago = ts == null ? null : DateTime.now().difference(ts);
      final agoStr = ago == null
          ? ''
          : ' (${_humanDuration(ago)} назад)';
      final verdict = switch (state) {
        'detached' => 'штатное завершение (detached получен)',
        'paused' || 'inactive' || 'hidden' =>
          'приложение было свёрнуто и НЕ вернулось на передний план — '
              'похоже, ОС завершила процесс в фоне (нет UIBackgroundModes, '
              'память/таймаут), а не крэш',
        'resumed' || 'launching' =>
          'приложение было на переднем плане и не записало штатное '
              'завершение — похоже на крэш или принудительное закрытие '
              'пользователем (не на «домой», а свайпом из шторки задач)',
        _ => 'неизвестное состояние ($state)',
      };
      lines.add('предыдущая сессия: последнее известное состояние '
          '"$state"$agoStr — $verdict');
    }

    // Устройство/ОС/версия приложения — чтобы лог был самодостаточным без
    // сопоставления с другими запусками.
    try {
      final pkg = await PackageInfo.fromPlatform();
      lines.add('приложение: ${pkg.version} (сборка ${pkg.buildNumber})');
    } catch (e) {
      lines.add('приложение: версия не определена ($e)');
    }
    try {
      if (Platform.isIOS) {
        final info = await DeviceInfoPlugin().iosInfo;
        lines.add('устройство: ${info.utsname.machine} · iOS '
            '${info.systemVersion} · '
            '${info.isPhysicalDevice ? 'физическое' : 'симулятор'}');
      } else if (Platform.isAndroid) {
        final info = await DeviceInfoPlugin().androidInfo;
        lines.add('устройство: ${info.manufacturer} ${info.model} · '
            'Android ${info.version.release} (SDK ${info.version.sdkInt})');
      }
    } catch (e) {
      lines.add('устройство: не определено ($e)');
    }
    lines.add('время запуска: ${DateTime.now().toIso8601String()}');
    lines.add('════════════════════════════════════════');

    for (final l in lines) {
      _log.i(l);
    }
  }

  static String _humanDuration(Duration d) {
    if (d.inDays > 0) return '${d.inDays} дн';
    if (d.inHours > 0) return '${d.inHours} ч';
    if (d.inMinutes > 0) return '${d.inMinutes} мин';
    return '${d.inSeconds} с';
  }

  /// Обновить маркер состояния (вызывается на каждый переход жизненного
  /// цикла — см. AppLifecycleGate). `detached` — единственное состояние,
  /// которое Flutter отдаёт как «приложение реально завершается штатно»;
  /// остальные («ушли в фон») тоже фиксируются, чтобы при СЛЕДУЮЩЕМ запуске
  /// можно было отличить «тихо убито ОС в фоне» от «упало на переднем плане».
  static Future<void> _writeMarker(String state) async {
    final file = _markerFile;
    if (file == null) return;
    try {
      await file.writeAsString('$state|${DateTime.now().toIso8601String()}');
    } catch (_) {}
  }

  /// Публичный вход для AppLifecycleGate — переход жизненного цикла плюс
  /// принудительный сброс накопленных строк лога на диск (не полагаемся на
  /// периодический таймер: он может не успеть тикнуть перед тем, как ОС
  /// убьёт процесс сразу после сворачивания).
  static Future<void> onLifecycleChange(String state) async {
    _log.i('${MvTag.auth} жизненный цикл приложения → $state');
    await _writeMarker(state);
    await flush();
  }

  static Future<void> flush() async {
    final file = _logFile;
    if (file == null || _pending.isEmpty) return;
    final chunk = _pending.join('\n');
    _pending.clear();
    try {
      final sink = file.openWrite(mode: FileMode.append);
      sink.write('$chunk\n');
      await sink.flush();
      await sink.close();
      if (await file.length() > _rotateAtBytes) await _rotate(file);
    } catch (_) {
      // Диск недоступен/переполнен — молча теряем этот кусок, логирование
      // не должно ронять приложение.
    }
  }

  static Future<void> _clearFile(File file) async {
    try {
      await file.writeAsString('');
    } catch (_) {}
  }

  static Future<void> _rotate(File file) async {
    try {
      final content = await file.readAsString();
      final lines = content.split('\n');
      final keepFrom = (lines.length * 2) ~/ 3;
      await file.writeAsString('${lines.sublist(keepFrom).join('\n')}\n');
    } catch (_) {}
  }
}
