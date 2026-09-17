import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/diagnostics_session.dart';
import 'core/logging.dart';
import 'data/account/account_store.dart';
import 'state/providers.dart';

/// Отдельный логгер только для крэш-хендлеров ниже — те же формат/таймстемп/
/// буфер, что у остального лога (см. [buildAppLogger]), чтобы строка о
/// крэше не выделялась из общей ленты диагностики.
final _crashLog = buildAppLogger();

Future<void> main() async {
  // ЛОВУШКА КРЭШЕЙ: без неё необработанная асинхронная ошибка тихо убивает
  // изолят в release — приложение «просто закрывается», и НИ ОДНОЙ строки
  // об этом не попадает ни в память, ни на диск. Это прямая причина жалобы
  // «закрылось — и разлогинило»: если дело было в крэше, раньше от него не
  // оставалось вообще никаких улик. runZonedGuarded ловит то, что вылетает
  // мимо try/catch (в т.ч. из fire-and-forget Future), FlutterError.onError —
  // ошибки построения виджетов, PlatformDispatcher.onError — то, что мимо
  // обоих (например, из callback'ов платформенных каналов).
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    final prevOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      _crashLog.f(
        'Flutter-ошибка: ${details.exceptionAsString()}',
        error: details.exception,
        stackTrace: details.stack,
      );
      unawaited(MvDiagnosticsSession.flush());
      prevOnError?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      _crashLog.f('необработанная ошибка платформы', error: error, stackTrace: stack);
      unawaited(MvDiagnosticsSession.flush());
      return true;
    };

    // Персистентность диагностики — ДО всего остального: если что-то ниже
    // упадёт при старте, крэш-хендлеры выше уже смогут сохранить это на
    // диск. Восстанавливает и хвост лога с прошлого запуска.
    await MvDiagnosticsSession.init();

    _initSqflitePlatform();
    await initializeDateFormatting('ru_RU', null);
    await initializeDateFormatting('ru', null);
    Intl.defaultLocale = 'ru_RU';

    // Реестр аккаунтов читаем ДО runApp: активный аккаунт должен быть известен
    // синхронно, иначе провайдеры сессии стартуют без namespace хранилищ.
    // Здесь же выполняется разовый перенос данных с одноаккаунтной версии.
    final bootstrap = await AccountStore().bootstrap();

    runApp(
      ProviderScope(
        overrides: [
          accountsBootstrapProvider.overrideWithValue(bootstrap),
        ],
        child: const MaxVektorApp(),
      ),
    );
  }, (error, stack) {
    _crashLog.f('необработанная ошибка зоны', error: error, stackTrace: stack);
    unawaited(MvDiagnosticsSession.flush());
  });
}

/// На Windows/Linux/macOS — sqflite через FFI. На Android/iOS — нативный.
void _initSqflitePlatform() {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
