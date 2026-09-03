import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../../state/theme_controller.dart';
import 'accounts_screen.dart';
import 'devices_screen.dart';
import 'diagnostics_screen.dart';
import 'qr_login_scanner_screen.dart';
import '../widgets/app_snack.dart';

/// Экран настроек.
///
/// Разделы и их порядок повторяют официальное приложение MAX (шапка с
/// профилем, группы «Уведомления/Безопасность/Устройства/…», «Экономия/
/// Память», «Оформление/Язык», «MAX для бизнеса», «Помощь/О приложении»),
/// но оформление — собственное: сгруппированные карточки и знак «V».
/// Пункты, которые приложение уже поддерживает, открывают рабочие экраны;
/// остальные помечены как «в разработке», чтобы структура совпадала с
/// оригиналом без обмана.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final versionLabel =
        ref.watch(appVersionLabelProvider).valueOrNull ?? AppMeta.version;
    final mode = ref.watch(themeModeProvider);
    final themeLabel = mode == ThemeMode.light
        ? 'Светлая'
        : mode == ThemeMode.dark
            ? 'Тёмная'
            : 'Как в системе';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            _Header(
              onQr: () => _push(context, const QrLoginScannerScreen()),
              onAccounts: () => _push(context, const AccountsScreen()),
            ),

            _Group(children: [
              _Tile(
                icon: Icons.notifications_none,
                title: 'Уведомления и звук',
                onTap: () => _soon(context),
              ),
              _Tile(
                icon: Icons.lock_outline,
                title: 'Безопасность',
                subtitle: 'Двухфакторная защита, сессии',
                onTap: () => _push(context, const DevicesScreen()),
              ),
              _Tile(
                icon: Icons.devices_outlined,
                title: 'Устройства',
                onTap: () => _push(context, const DevicesScreen()),
              ),
              _Tile(
                icon: Icons.chat_bubble_outline,
                title: 'Сообщения',
                onTap: () => _soon(context),
              ),
              _Tile(
                icon: Icons.bookmark_border,
                title: 'Избранное',
                onTap: () => _soon(context),
              ),
              _Tile(
                icon: Icons.folder_outlined,
                title: 'Папки',
                onTap: () => _soon(context),
                last: true,
              ),
            ]),

            _Group(children: [
              _Tile(
                icon: Icons.battery_saver_outlined,
                title: 'Экономия батареи и сети',
                onTap: () => _soon(context),
              ),
              _Tile(
                icon: Icons.storage_outlined,
                title: 'Память',
                onTap: () => _soon(context),
                last: true,
              ),
            ]),

            _Group(children: [
              _Tile(
                icon: Icons.palette_outlined,
                title: 'Оформление',
                subtitle: themeLabel,
                onTap: () => _pickTheme(context, ref),
              ),
              _Tile(
                icon: Icons.language,
                title: 'Язык приложения',
                subtitle: 'Русский',
                onTap: () => _soon(context),
                last: true,
              ),
            ]),

            // Мультиаккаунт — наша особенность, которой нет в официальном
            // приложении, но она ключевая для Max Vektor.
            _Group(children: [
              _Tile(
                icon: Icons.switch_account_outlined,
                title: 'Аккаунты',
                subtitle: 'Переключить · добавить',
                onTap: () => _push(context, const AccountsScreen()),
              ),
              _Tile(
                icon: Icons.qr_code_scanner,
                title: 'Вход по QR-коду',
                subtitle: 'Подтвердить вход другого устройства',
                onTap: () => _push(context, const QrLoginScannerScreen()),
                last: true,
              ),
            ]),

            _Group(children: [
              _Tile(
                icon: Icons.help_outline,
                title: 'Помощь',
                onTap: () => _soon(context),
              ),
              _Tile(
                icon: Icons.bug_report_outlined,
                title: 'Диагностика',
                subtitle: 'Логи соединения — для разбора проблем',
                onTap: () => _push(context, const DiagnosticsScreen()),
              ),
              _Tile(
                icon: Icons.info_outline,
                title: 'О приложении',
                subtitle: '${AppMeta.name} $versionLabel · ${AppMeta.disclaimer}',
                onTap: () => _about(context, versionLabel),
                last: true,
              ),
            ]),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  icon: Icon(Icons.logout, color: scheme.error),
                  label: Text('Выйти из аккаунта',
                      style: TextStyle(color: scheme.error)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: scheme.error.withValues(alpha: 0.4)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => _confirmLogout(context, ref),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _soon(BuildContext context) => AppSnack.soon(context);

  Future<void> _pickTheme(BuildContext context, WidgetRef ref) async {
    final ctrl = ref.read(themeModeProvider.notifier);
    final current = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              (ThemeMode.system, 'Как в системе'),
              (ThemeMode.light, 'Светлая'),
              (ThemeMode.dark, 'Тёмная'),
            ])
              ListTile(
                title: Text(entry.$2),
                trailing: current == entry.$1
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () {
                  ctrl.set(entry.$1);
                  Navigator.of(ctx).pop();
                },
              ),
          ],
        ),
      ),
    );
  }

  void _about(BuildContext context, String versionLabel) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('О приложении'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppMeta.name} $versionLabel'),
            const SizedBox(height: 8),
            Text('${AppMeta.disclaimer}. Не связан с VK и разработчиками '
                'официального приложения MAX.'),
            const SizedBox(height: 8),
            Text('Протокол: app ${MaxProto.appVersion}, '
                'proto v${MaxProto.protoVersion}'),
            const SizedBox(height: 8),
            Text('Исходный код:\n${AppMeta.upstreamUrl}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Выйти?'),
        content: const Text(
          'Аккаунт исчезнет из переключателя. Его локальная история, '
          'скачанные файлы и сохранённый вход будут удалены с устройства. '
          'Другие аккаунты не затрагиваются.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(sessionProvider.notifier).logout();
  }
}

/// Шапка настроек: QR слева, карандаш справа, по центру крупный аватар,
/// имя и номер — как в официальном приложении MAX.
class _Header extends ConsumerWidget {
  const _Header({required this.onQr, required this.onAccounts});

  /// QR-иконка (слева) — вход по QR-коду.
  final VoidCallback onQr;

  /// Иконка-карандаш (справа). Редактирование профиля пока не поддержано,
  /// поэтому ведёт на переключатель аккаунтов.
  final VoidCallback onAccounts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    final scheme = Theme.of(context).colorScheme;
    final name = account.displayName?.isNotEmpty == true
        ? account.displayName!
        : 'Без имени';
    final phone = account.phone;
    final initial = name.isNotEmpty ? name.characters.first.toUpperCase() : '?';

    return Column(
      children: [
        // Верхний ряд: QR слева, карандаш справа.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'Вход по QR-коду',
                icon: const Icon(Icons.qr_code_2),
                onPressed: onQr,
              ),
              IconButton(
                tooltip: 'Аккаунты',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onAccounts,
              ),
            ],
          ),
        ),
        // Центрированный аватар с инициалом.
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF56CDFF), Color(0xFF2563EB)],
            ),
          ),
          child: Text(
            initial,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (phone != null && phone.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            phone,
            style: TextStyle(fontSize: 16, color: scheme.primary),
          ),
        ],
        const SizedBox(height: 12),
      ],
    );
  }
}

/// Группа-карточка со скруглёнными углами (как секции в MAX).
class _Group extends StatelessWidget {
  const _Group({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.last = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: scheme.primary),
          title: Text(title),
          subtitle: subtitle == null ? null : Text(subtitle!),
          trailing: Icon(Icons.chevron_right, color: scheme.outline),
          onTap: onTap,
        ),
        if (!last) const Divider(height: 1, indent: 56, endIndent: 12),
      ],
    );
  }
}
