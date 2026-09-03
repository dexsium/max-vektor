import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';
import '../widgets/accounts_section.dart';
import '../widgets/vektor_mark.dart';
import 'devices_screen.dart';

/// Экран настроек.
///
/// Структура повторяет разделы официального приложения MAX (профиль,
/// аккаунты, устройства и сессии, приложение, выход), но оформление —
/// собственное: сгруппированные карточки в стиле iOS и знак «V», как на
/// экране входа. Показываются только те разделы, что приложение реально
/// поддерживает.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final versionLabel =
        ref.watch(appVersionLabelProvider).valueOrNull ?? AppMeta.version;

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          const _ProfileHeader(),
          const SizedBox(height: 8),

          // Аккаунты: список + «Добавить аккаунт» (тап переключает).
          const _Group(
            title: 'Аккаунты',
            child: AccountsSection(showHeader: false),
          ),

          _Group(
            title: 'Приложение',
            child: Column(
              children: [
                _Tile(
                  icon: Icons.devices_outlined,
                  title: 'Устройства и сессии',
                  subtitle: 'Активные входы · завершить чужие',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const DevicesScreen()),
                  ),
                ),
                const _TileDivider(),
                _Tile(
                  icon: Icons.cloud_outlined,
                  title: 'Версия протокола MAX',
                  subtitle: 'app ${MaxProto.appVersion}, '
                      'proto v${MaxProto.protoVersion}',
                ),
              ],
            ),
          ),

          _Group(
            title: 'О приложении',
            child: Column(
              children: [
                _Tile(
                  icon: Icons.info_outline,
                  title: '${AppMeta.name} $versionLabel',
                  subtitle:
                      '${AppMeta.disclaimer}. Не связан с VK и разработчиками '
                      'официального приложения MAX.',
                ),
                const _TileDivider(),
                _Tile(
                  icon: Icons.code,
                  title: 'Исходный код',
                  subtitle: AppMeta.upstreamUrl,
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                icon: Icon(Icons.logout, color: scheme.error),
                label: Text(
                  'Выйти из аккаунта',
                  style: TextStyle(color: scheme.error),
                ),
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

/// Шапка с аватаром-знаком и данными активного аккаунта.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(activeAccountProvider);
    final scheme = Theme.of(context).colorScheme;
    final name = account.displayName?.isNotEmpty == true
        ? account.displayName!
        : (account.phone ?? 'Аккаунт MAX');
    final subtitle =
        account.displayName?.isNotEmpty == true ? account.phone : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          const VektorMark(size: 56),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Сгруппированная секция-карточка с заголовком.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    letterSpacing: 0.6,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ],
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
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: onTap == null
          ? null
          : Icon(Icons.chevron_right, color: scheme.outline),
      onTap: onTap,
    );
  }
}

class _TileDivider extends StatelessWidget {
  const _TileDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56, endIndent: 12);
  }
}
