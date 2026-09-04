import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/app_snack.dart';
import 'blacklist_screen.dart';
import 'set_password_screen.dart';

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

  /// null — состояние ещё не загружено; true/false — установлен ли пароль
  /// входа (2FA). Подтягиваем через op 104 при открытии раздела.
  bool? _pwdEnabled;

  @override
  void initState() {
    super.initState();
    _loadPasswordState();
  }

  Future<void> _loadPasswordState() async {
    try {
      final d = await ref.read(maxClientProvider).get2faDetails();
      if (mounted) setState(() => _pwdEnabled = d.enabled);
    } catch (_) {
      // Оффлайн/сессия недоступна — оставляем неизвестным (бейдж-подсказку).
    }
  }

  Future<void> _openPassword() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const SetPasswordScreen()),
    );
    if (changed == true) _loadPasswordState();
  }

  Map<String, String> _accessLabels(L l) => {
        'ALL': l.accessAll,
        'CONTACTS': l.accessContacts,
        'NOBODY': l.accessNobody,
      };
  Map<String, String> _visibilityLabels(L l) => {
        'ALL': l.visibilityAll,
        'CONTACTS': l.visibilityContacts,
        'NOBODY': l.visibilityNobody,
      };

  Future<void> _set(String key, String value) async {
    final prev = _values[key];
    setState(() => _values[key] = value);
    try {
      await ref.read(maxClientProvider).setUserSettings({key: value});
    } catch (e) {
      if (mounted) {
        setState(() => _values[key] = prev ?? value);
        AppSnack.show(context, '$e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final access = _accessLabels(l);
    final visibility = _visibilityLabels(l);
    return Scaffold(
      appBar: AppBar(title: Text(l.secTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          _Group(children: [
            _NavTile(
              icon: Icons.vpn_key_outlined,
              title: l.secPassword,
              subtitle: _pwdEnabled == true ? l.pwdStateOn : l.secPasswordSub,
              // Бейдж-подсказка «!» только пока пароль не установлен.
              badge: _pwdEnabled != true,
              onTap: _openPassword,
            ),
          ]),
          _Group(children: [
            _NavTile(
              icon: Icons.shield_outlined,
              title: l.secFamily,
              subtitle: l.secFamilyOff,
              onTap: () => AppSnack.soon(context),
            ),
          ]),
          _Group(children: [
            SwitchListTile(
              secondary: Icon(Icons.lock_outline,
                  color: Theme.of(context).colorScheme.primary),
              title: Text(l.secSafeMode),
              value: _safeMode,
              onChanged: (v) {
                setState(() => _safeMode = v);
                _set('app.privacy.safe_mode', v ? 'ON' : 'OFF');
              },
            ),
            const _Divider(),
            _pickerTile(l.secCall, 'app.privacy.incoming.call', access),
            const _Divider(),
            _pickerTile(
                l.secFindByPhone, 'app.privacy.search_by_phone', access),
            const _Divider(),
            _pickerTile(l.secShowContent,
                'app.privacy.content.level.access', access),
            const _Divider(),
            _pickerTile(l.secInviteToChat, 'app.privacy.chats.invite', access),
          ]),
          _SectionLabel(l.secInfo),
          _Group(children: [
            _pickerTile(
                l.secSeeOnline, 'app.privacy.online.show', visibility),
            const _Divider(),
            _pickerTile(l.secSeeNumber, 'app.privacy.phone.number.privacy',
                visibility),
          ]),
          _Group(children: [
            _NavTile(
              icon: Icons.block,
              title: l.secBlacklist,
              subtitle: l.secBlacklistSub,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BlacklistScreen()),
              ),
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
