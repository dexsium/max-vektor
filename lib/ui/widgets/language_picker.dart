import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../state/locale_controller.dart';

/// Флаги поддерживаемых языков (для списка выбора). Коды совпадают с
/// [L.supportedLocales].
const Map<String, String> _flags = {
  'ru': '🇷🇺',
  'en': '🇬🇧',
  'uk': '🇺🇦',
  'de': '🇩🇪',
  'es': '🇪🇸',
  'fr': '🇫🇷',
  'it': '🇮🇹',
  'pt': '🇵🇹',
  'tr': '🇹🇷',
};

/// Список выбора языка интерфейса: «Системный» + все поддерживаемые.
/// [current] == null — сейчас выбран системный язык. [onSelect] получает
/// выбранный язык или null (вернуть выбор системе).
class LanguagePickerList extends StatelessWidget {
  const LanguagePickerList({
    super.key,
    required this.current,
    required this.onSelect,
    this.shrinkWrap = false,
  });

  final Locale? current;
  final void Function(Locale? locale) onSelect;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    final codes = L.supportedLocales.map((e) => e.languageCode).toList();

    Widget tile({
      required String leading,
      required String title,
      required bool selected,
      required VoidCallback onTap,
    }) {
      return ListTile(
        leading: Text(leading, style: const TextStyle(fontSize: 26)),
        title: Text(title),
        trailing: selected
            ? Icon(Icons.check_circle, color: scheme.primary)
            : null,
        onTap: onTap,
      );
    }

    return ListView(
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        tile(
          leading: '🌐',
          title: l.langSystem,
          selected: current == null,
          onTap: () => onSelect(null),
        ),
        const Divider(height: 1),
        for (final code in codes)
          tile(
            leading: _flags[code] ?? '🌐',
            title: kLanguageNames[code] ?? code.toUpperCase(),
            selected: current?.languageCode == code,
            onTap: () => onSelect(Locale(code)),
          ),
      ],
    );
  }
}

/// Модальный лист выбора языка (для экрана входа). Применяет выбор к
/// [localeProvider] и закрывает лист.
Future<void> showLanguagePicker(
  BuildContext context, {
  required Locale? current,
  required void Function(Locale? locale) onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Row(
                children: [
                  Text(
                    L.of(ctx).langTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            Flexible(
              child: LanguagePickerList(
                current: current,
                onSelect: (locale) {
                  onSelect(locale);
                  Navigator.of(ctx).pop();
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
