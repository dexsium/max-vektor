import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/providers.dart';
import '../widgets/app_snack.dart';

/// Раздел «Безопасность» — приватность как в официальном приложении MAX.
///
/// Значения приватности (ALL/CONTACTS/NOBODY) и ключи `app.privacy.*`
/// сверены с APK (izi.java, bnh.k). Отправка — CONFIG (op 22):
/// `{settings:{user:{ключ:значение}}}`. Текущие значения по умолчанию
/// показываем «могут контакты»; сервер их подтвердит/поправит (ответ op 22
/// пишется в диагностику — точная схема без живого аккаунта не проверена).
class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  // Локальное состояние выбора (значения app.privacy.*).
  final Map<String, String> _values = {
    'app.privacy.incoming.call': 'CONTACTS',
    'app.privacy.search_by_phone': 'CONTACTS',
    'app.privacy.content.level.access': 'ALL',
    'app.privacy.chats.invite': 'CONTACTS',
    'app.privacy.online.show': 'NOBODY',
    'app.privacy.phone.number.privacy': 'NOBODY',
  };
  bool _safeMode = false;

  static const _access = {
    'ALL': 'все',
    'CONTACTS': 'могут контакты',
    'NOBODY': 'никто',
  };
  static const _visibility = {
    'ALL': 'все',
    'CONTACTS': 'контакты',
    'NOBODY': 'никто',
  };

  Future<void> _set(String key, String value) async {
    final prev = _values[key];
    setState(() => _values[key] = value);
    try {
      await ref.read(maxClientProvider).setUserSettings({key: value});
    } catch (e) {
      if (mounted) {
        setState(() => _values[key] = prev ?? value);
        AppSnack.show(context, 'Не удалось сохранить: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Безопасность')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _Group(children: [
            _NavTile(
              icon: Icons.vpn_key_outlined,
              title: 'Пароль для входа',
              subtitle: 'Двухфакторная защита',
              badge: true,
              onTap: () => AppSnack.show(
                context,
                'Пароль 2FA задаётся при входе. Управление паролем — в разработке.',
              ),
            ),
          ]),
          _Group(children: [
            _NavTile(
              icon: Icons.shield_outlined,
              title: 'Семейная защита',
              subtitle: 'Отключена',
              onTap: () => AppSnack.soon(context),
            ),
          ]),
          _Group(children: [
            SwitchListTile(
              secondary: Icon(Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary),
              title: const Text('Безопасный режим'),
              value: _safeMode,
              onChanged: (v) {
                setState(() => _safeMode = v);
                _set('app.privacy.safe_mode', v ? 'ON' : 'OFF');
              },
            ),
            const _Divider(),
            _pickerTile('Позвонить', 'app.privacy.incoming.call', _access),
            const _Divider(),
            _pickerTile(
                'Найти меня по номеру', 'app.privacy.search_by_phone', _access),
            const _Divider(),
            _pickerTile('Показывать контент', 'app.privacy.content.level.access',
                _access),
            const _Divider(),
            _pickerTile('Пригласить в чат', 'app.privacy.chats.invite', _access),
          ]),
          const _SectionLabel('Информация'),
          _Group(children: [
            _pickerTile(
                'Видеть статус «в сети»', 'app.privacy.online.show', _visibility),
            const _Divider(),
            _pickerTile('Видеть мой номер', 'app.privacy.phone.number.privacy',
                _visibility),
          ]),
          _Group(children: [
            _NavTile(
              icon: Icons.block,
              title: 'Чёрный список',
              subtitle: 'Кто не может писать, звонить и добавлять в чаты',
              onTap: () => AppSnack.soon(context),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _pickerTile(String title, String key, Map<String, String> labels) {
    final value = _values[key] ?? 'CONTACTS';
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(labels[value] ?? value,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline),
        ],
      ),
      onTap: () => _pick(title, key, labels),
    );
  }

  Future<void> _pick(
      String title, String key, Map<String, String> labels) async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            for (final e in labels.entries)
              ListTile(
                title: Text(e.value),
                trailing: _values[key] == e.key
                    ? Icon(Icons.check,
                        color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(e.key),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != _values[key]) _set(key, chosen);
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
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

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 12);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 16, 6),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.6)),
      );
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.primary),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge)
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: scheme.error, shape: BoxShape.circle),
              child: const Text('!',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
          const SizedBox(width: 6),
          Icon(Icons.chevron_right, color: scheme.outline),
        ],
      ),
      onTap: onTap,
    );
  }
}
