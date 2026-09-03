import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/session_controller.dart';
import 'devices_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('О приложении'),
            subtitle: Text(
              '${AppMeta.name} ${AppMeta.version}\n'
              '${AppMeta.disclaimer} — неофициальный клиент MAX.\n'
              'Не связан с VK и разработчиками официального приложения MAX.',
            ),
            isThreeLine: true,
            leading: Icon(Icons.info_outline),
          ),
          const ListTile(
            title: Text('Исходный код (upstream)'),
            subtitle: Text(AppMeta.upstreamUrl),
            leading: Icon(Icons.code),
          ),
          ListTile(
            title: const Text('Версия протокола MAX'),
            subtitle: Text('app ${MaxProto.appVersion}, '
                'proto v${MaxProto.protoVersion}'),
            leading: const Icon(Icons.cloud_outlined),
          ),
          const Divider(),
          ListTile(
            title: const Text('Устройства и сессии'),
            subtitle: const Text('Активные входы · завершить чужие'),
            leading: const Icon(Icons.devices_outlined),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const DevicesScreen()),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Выйти из аккаунта'),
            leading: const Icon(Icons.logout),
            iconColor: Theme.of(context).colorScheme.error,
            textColor: Theme.of(context).colorScheme.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Выйти?'),
                  content: const Text(
                    'Локальная история чатов и контактов останется, '
                    'но потребуется повторный логин.',
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
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
