import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../widgets/app_snack.dart';

/// Экран «Пароль для входа» — установка двухфакторной защиты (2FA).
///
/// Протокол сверен с APK MAX: детали текущего состояния — op 104
/// (AUTH_2FA_DETAILS, ответ `{enabled, hint, email}`), установка пароля —
/// op 111 (AUTH_SET_2FA, `{trackId:"", password, hint?, expectedCapabilities}`).
/// Ограничения длины (min/max/hint) в официальном клиенте приходят в CONFIG
/// `creation-2fa-config`; сервер применяет их как жёсткий предел, здесь
/// используем те же значения по умолчанию и заранее проверяем ввод.
class SetPasswordScreen extends ConsumerStatefulWidget {
  const SetPasswordScreen({super.key});

  // Значения creation-2fa-config официального сервера MAX.
  static const int passMinLen = 6;
  static const int passMaxLen = 64;
  static const int hintMaxLen = 30;

  @override
  ConsumerState<SetPasswordScreen> createState() => _SetPasswordScreenState();
}

class _SetPasswordScreenState extends ConsumerState<SetPasswordScreen> {
  final _passCtrl = TextEditingController();
  final _repeatCtrl = TextEditingController();
  final _hintCtrl = TextEditingController();

  bool _obscure = true;
  bool _loadingState = true;
  bool _saving = false;
  bool _enabled = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  @override
  void dispose() {
    _passCtrl.dispose();
    _repeatCtrl.dispose();
    _hintCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadState() async {
    try {
      final details = await ref.read(maxClientProvider).get2faDetails();
      if (!mounted) return;
      setState(() {
        _enabled = details.enabled;
        if (details.hint != null) _hintCtrl.text = details.hint!;
        _loadingState = false;
      });
    } catch (_) {
      // Оффлайн/старая сессия — не блокируем установку, просто не знаем
      // текущее состояние.
      if (mounted) setState(() => _loadingState = false);
    }
  }

  String? _validate(L l) {
    final pass = _passCtrl.text;
    if (pass.length < SetPasswordScreen.passMinLen) {
      return l.pwdTooShort(SetPasswordScreen.passMinLen);
    }
    if (pass.length > SetPasswordScreen.passMaxLen) {
      return l.pwdTooLong(SetPasswordScreen.passMaxLen);
    }
    if (_repeatCtrl.text != pass) return l.pwdMismatch;
    if (_hintCtrl.text.trim().length > SetPasswordScreen.hintMaxLen) {
      return l.pwdHintTooLong(SetPasswordScreen.hintMaxLen);
    }
    return null;
  }

  Future<void> _save() async {
    final l = L.of(context);
    final err = _validate(l);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _error = null;
      _saving = true;
    });
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    try {
      await ref.read(maxClientProvider).setLoginPassword(
            password: _passCtrl.text,
            hint: _hintCtrl.text,
          );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.pwdSaved)));
      nav.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnack.show(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(l.pwdTitle)),
      body: _loadingState
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                Row(
                  children: [
                    Icon(
                      _enabled ? Icons.lock : Icons.lock_open_outlined,
                      size: 18,
                      color: _enabled ? scheme.primary : scheme.outline,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _enabled ? l.pwdStateOn : l.pwdStateOff,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _enabled ? scheme.primary : scheme.outline,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l.pwdDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  autofocus: true,
                  maxLength: SetPasswordScreen.passMaxLen,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: l.pwdNew,
                    border: const OutlineInputBorder(),
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _repeatCtrl,
                  obscureText: _obscure,
                  maxLength: SetPasswordScreen.passMaxLen,
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                  onSubmitted: (_) => _save(),
                  decoration: InputDecoration(
                    labelText: l.pwdRepeat,
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _hintCtrl,
                  maxLength: SetPasswordScreen.hintMaxLen,
                  decoration: InputDecoration(
                    labelText: l.pwdHintLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l.pwdHintDesc,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: scheme.error),
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  height: 50,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.pwdSave),
                  ),
                ),
              ],
            ),
    );
  }
}
