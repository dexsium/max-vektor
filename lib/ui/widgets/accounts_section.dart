import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/account/account.dart';
import '../../data/account/account_store.dart';
import '../../state/providers.dart';
import '../../state/session_controller.dart';

/// Список аккаунтов MAX и кнопка «Добавить аккаунт».
///
/// Аккаунты полностью изолированы: свой токен, своя база, свой каталог
/// медиа и свой `deviceId`. Соединения соседних аккаунтов остаются живыми,
/// поэтому тап по аккаунту переключает мгновенно и не выполняет повторный
/// вход (частые LOGIN с одного устройства — сигнал для антифрода MAX).
class AccountsSection extends ConsumerWidget {
  const AccountsSection({
    super.key,
    this.onSwitched,
    this.showHeader = true,
    this.showFooter = true,
  });

  /// Вызывается после переключения — экрану аккаунтов нужно закрыться,
  /// настройкам достаточно перерисоваться.
  final VoidCallback? onSwitched;

  /// Показывать собственный заголовок «Аккаунты». В настройках секция уже
  /// обёрнута в группу с заголовком, поэтому там его отключаем.
  final bool showHeader;

  /// Показывать пояснительный текст под списком. В настройках-карточке (как в
  /// официальном приложении) его прячем, чтобы блок был компактным.
  final bool showFooter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final activeId = ref.watch(activeAccountIdProvider);
    final session = ref.read(sessionProvider.notifier);
    final limitReached = accounts.length >= AccountStore.maxAccounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showHeader)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              'Аккаунты',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        for (final account in accounts)
          _AccountTile(
            account: account,
            isActive: account.id == activeId,
            isLive: session.isAccountLive(account.id),
            onTap: () async {
              await session.switchAccount(account.id);
              onSwitched?.call();
            },
            onSignOut: () => _confirmSignOut(context, ref, account),
          ),
        ListTile(
          leading: const Icon(Icons.person_add_alt),
          title: Text(L.of(context).accAddAccount),
          subtitle: Text(
            limitReached
                ? 'Достигнут предел: ${AccountStore.maxAccounts} аккаунтов'
                : 'Войти ещё под одним номером MAX',
          ),
          enabled: !limitReached,
          onTap: limitReached
              ? null
              : () async {
                  await session.addAccount();
                  onSwitched?.call();
                },
        ),
        if (showFooter)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Text(
              'У каждого аккаунта своя переписка, свой вход и свой '
              'идентификатор устройства — данные не смешиваются. '
              'Переключение не выполняет повторный вход: соединение остаётся '
              'поднятым, пока вы не выйдете из аккаунта.',
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmSignOut(
    BuildContext context,
    WidgetRef ref,
    MvAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.of(context).accLogoutTitle(account.label)),
        content: const Text(
          'Аккаунт исчезнет из списка. Локальная история переписки, '
          'скачанные файлы и сохранённый вход этого аккаунта будут удалены '
          'с устройства. Другие аккаунты не затрагиваются.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L.of(context).commonLogout),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(accountsProvider.notifier).signOutAndRemove(account.id);
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.account,
    required this.isActive,
    required this.isLive,
    required this.onTap,
    required this.onSignOut,
  });

  final MvAccount account;
  final bool isActive;
  final bool isLive;
  final VoidCallback onTap;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial =
        account.label.isNotEmpty ? account.label[0].toUpperCase() : '?';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor:
            isActive ? scheme.primary : scheme.surfaceContainerHighest,
        foregroundColor: isActive ? Colors.white : scheme.onSurfaceVariant,
        child: account.isSignedIn
            ? Text(initial)
            : const Icon(Icons.login, size: 20),
      ),
      title: Text(account.label),
      subtitle: Text(
        [
          if (account.subtitle != null) account.subtitle!,
          if (isActive)
            'активный'
          else if (isLive)
            'на связи'
          else
            'соединение не поднято',
        ].join(' · '),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Icon(Icons.check_circle, color: scheme.primary, size: 22),
          IconButton(
            tooltip: L.of(context).settingsLogout,
            icon: const Icon(Icons.logout),
            color: scheme.error,
            onPressed: onSignOut,
          ),
        ],
      ),
      selected: isActive,
      onTap: isActive ? null : onTap,
    );
  }
}
