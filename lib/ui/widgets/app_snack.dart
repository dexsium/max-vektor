import 'package:flutter/material.dart';

/// Единый стиль всплывающих уведомлений в дизайне приложения:
/// скруглённая плавающая плашка с иконкой, вместо голого SnackBar.
class AppSnack {
  const AppSnack._();

  static void show(
    BuildContext context,
    String message, {
    IconData icon = Icons.info_outline,
    bool error = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bg = error ? scheme.errorContainer : scheme.surfaceContainerHighest;
    final fg = error ? scheme.onErrorContainer : scheme.onSurface;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: bg,
          elevation: 2,
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          content: Row(
            children: [
              Icon(icon, size: 20, color: error ? fg : scheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: TextStyle(color: fg)),
              ),
            ],
          ),
        ),
      );
  }

  /// «Раздел в разработке» — для ещё не реализованных пунктов настроек.
  static void soon(BuildContext context) =>
      show(context, 'Раздел в разработке', icon: Icons.construction_outlined);
}
