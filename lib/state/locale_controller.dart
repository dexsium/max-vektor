import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../l10n/app_localizations.dart';

/// Выбранный язык интерфейса. `null` — следовать за системным языком
/// (поведение по умолчанию, как в официальном приложении). Явный выбор
/// переопределяет системный и хранится глобально (не по аккаунту), переживает
/// перезапуск.
class LocaleController extends Notifier<Locale?> {
  static const _key = 'mv_locale_override';
  static const _backend = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Locale? build() {
    _load();
    return null;
  }

  Future<void> _load() async {
    try {
      final code = await _backend.read(key: _key);
      if (code == null || code.isEmpty) return;
      final locale = Locale(code);
      if (_supported(locale)) state = locale;
    } catch (_) {
      // Нет доступа к хранилищу — остаётся системный язык.
    }
  }

  static bool _supported(Locale l) =>
      L.supportedLocales.any((s) => s.languageCode == l.languageCode);

  /// [locale] == null — вернуть выбор языка системе.
  Future<void> set(Locale? locale) async {
    state = locale;
    try {
      if (locale == null) {
        await _backend.delete(key: _key);
      } else {
        await _backend.write(key: _key, value: locale.languageCode);
      }
    } catch (_) {}
  }
}

final localeProvider =
    NotifierProvider<LocaleController, Locale?>(LocaleController.new);

/// Родные названия языков для меню выбора (по коду из [L.supportedLocales]).
const Map<String, String> kLanguageNames = {
  'ru': 'Русский',
  'en': 'English',
  'uk': 'Українська',
  'de': 'Deutsch',
  'es': 'Español',
  'fr': 'Français',
  'it': 'Italiano',
  'pt': 'Português',
  'tr': 'Türkçe',
};
