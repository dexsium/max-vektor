import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'data/account/account_store.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
}

/// На Windows/Linux/macOS — sqflite через FFI. На Android/iOS — нативный.
void _initSqflitePlatform() {
  if (kIsWeb) return;
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}
