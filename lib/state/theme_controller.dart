import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Выбранная тема оформления. Хранится глобально (не по аккаунту) в
/// защищённом хранилище, переживает перезапуск.
class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'mv_theme_mode';
  static const _backend = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  ThemeMode build() {
    _load();
    return ThemeMode.system;
  }

  Future<void> _load() async {
    try {
      final v = await _backend.read(key: _key);
      final mode = switch (v) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      if (mode != state) state = mode;
    } catch (_) {
      // Нет доступа к хранилищу — остаётся системная тема.
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    final v = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    try {
      await _backend.write(key: _key, value: v);
    } catch (_) {}
  }

  String get label => switch (state) {
        ThemeMode.light => 'Светлая',
        ThemeMode.dark => 'Тёмная',
        ThemeMode.system => 'Как в системе',
      };
}

final themeModeProvider =
    NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
