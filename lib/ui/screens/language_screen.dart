import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../l10n/app_localizations.dart';

/// Экран «Язык приложения». Язык следует за системным (как в официальном
/// приложении): показываем текущий язык устройства и предлагаем сменить его
/// в системных настройках. Кнопка открывает страницу приложения в «Настройках».
class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  /// Флаг и родное название языка по коду локали устройства.
  static ({String flag, String name}) _current() {
    final code = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return _langs[code] ?? (flag: '🌐', name: code.toUpperCase());
  }

  /// Родное название текущего языка — для подписи плитки в настройках.
  static String currentName() => _current().name;

  static const Map<String, ({String flag, String name})> _langs = {
    'ru': (flag: '🇷🇺', name: 'Русский'),
    'en': (flag: '🇬🇧', name: 'English'),
    'uk': (flag: '🇺🇦', name: 'Українська'),
    'be': (flag: '🇧🇾', name: 'Беларуская'),
    'kk': (flag: '🇰🇿', name: 'Қазақша'),
    'uz': (flag: '🇺🇿', name: 'Oʻzbekcha'),
    'ky': (flag: '🇰🇬', name: 'Кыргызча'),
    'tg': (flag: '🇹🇯', name: 'Тоҷикӣ'),
    'hy': (flag: '🇦🇲', name: 'Հայերեն'),
    'ka': (flag: '🇬🇪', name: 'ქართული'),
    'az': (flag: '🇦🇿', name: 'Azərbaycan'),
    'de': (flag: '🇩🇪', name: 'Deutsch'),
    'fr': (flag: '🇫🇷', name: 'Français'),
    'es': (flag: '🇪🇸', name: 'Español'),
    'it': (flag: '🇮🇹', name: 'Italiano'),
    'tr': (flag: '🇹🇷', name: 'Türkçe'),
    'zh': (flag: '🇨🇳', name: '中文'),
  };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = L.of(context);
    final cur = _current();
    return Scaffold(
      appBar: AppBar(title: Text(l.langTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(cur.flag, style: const TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                cur.name,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text(
                l.langHintSystem,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 20),
              Text(
                l.langHintDevice,
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () => openAppSettings(),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(l.langOpenSettings,
                  style:
                      const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}
