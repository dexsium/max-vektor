import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/locale_controller.dart';
import '../widgets/language_picker.dart';

/// Экран «Язык приложения». Смена языка прямо в приложении (не через
/// системные настройки): выбор применяется сразу и сохраняется. «Системный»
/// — следовать за языком устройства.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  /// Родное название текущего языка — для подписи плитки в настройках.
  /// [override] == null — показываем, что выбран системный язык.
  static String currentName(Locale? override) {
    if (override == null) return _systemLabel;
    return kLanguageNames[override.languageCode] ??
        override.languageCode.toUpperCase();
  }

  static const _systemLabel = 'Системный';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final current = ref.watch(localeProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.langTitle)),
      body: LanguagePickerList(
        current: current,
        onSelect: (locale) => ref.read(localeProvider.notifier).set(locale),
      ),
    );
  }
}
