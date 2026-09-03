import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../state/providers.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/session_controller.dart';
import '../widgets/code_input.dart';
import '../widgets/vektor_mark.dart';

/// Экран входа и регистрации.
///
/// Шаги идут по состоянию сессии: номер → код → (имя, если аккаунта ещё
/// нет) → (пароль 2FA, если включён). Оформление собственное: знак «V» из
/// иконки приложения, без брендинга официального MAX.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _pwCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();

  bool _busy = false;
  bool _pwVisible = false;
  bool _tokenMode = false;

  /// Тикает раз в секунду, пока идёт отсчёт до повторного запроса кода.
  Timer? _resendTicker;

  @override
  void dispose() {
    _resendTicker?.cancel();
    _phoneCtrl.dispose();
    _codeCtrl.dispose();
    _pwCtrl.dispose();
    _tokenCtrl.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() op) async {
    setState(() => _busy = true);
    try {
      await op();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final ctrl = ref.read(sessionProvider.notifier);
    final step = _tokenMode ? _Step.token : _stepOf(session);

    // Есть куда вернуться, если этот экран открыт через «Добавить аккаунт»:
    // в списке уже есть другой (залогиненный) аккаунт.
    final canCancel = ref.watch(accountsProvider).length > 1;

    return Scaffold(
      // Тап по пустому месту убирает клавиатуру.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canCancel)
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    tooltip: 'Назад',
                    icon: const Icon(Icons.arrow_back),
                    onPressed: _busy ? null : () => ctrl.cancelAddAccount(),
                  ),
                ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(24, canCancel ? 8 : 32, 24, 32),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _header(step),
                          const SizedBox(height: 28),
                          if (session.error != null) ...[
                            _ErrorBanner(text: session.error!),
                            const SizedBox(height: 16),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Column(
                              key: ValueKey(step),
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: _body(step, session, ctrl),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _footer(step, ctrl),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _Step _stepOf(SessionState session) => switch (session.authFlow) {
        AuthState.awaitingSms => _Step.code,
        AuthState.awaitingName => _Step.name,
        AuthState.awaiting2fa => _Step.password,
        _ => _Step.phone,
      };

  // ─────────────────────────── шапка ───────────────────────────

  Widget _header(_Step step) {
    final theme = Theme.of(context);
    return Column(
      children: [
        const VektorMark(size: 76),
        const SizedBox(height: 18),
        Text(
          _title(step),
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _subtitle(step),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _title(_Step step) => switch (step) {
        _Step.phone => AppMeta.name,
        _Step.code => 'Введите код',
        _Step.name => 'Как вас зовут?',
        _Step.password => 'Пароль двухфакторной защиты',
        _Step.token => 'Вход по токену',
      };

  String _subtitle(_Step step) {
    final session = ref.read(sessionProvider);
    return switch (step) {
      _Step.phone => 'Введите номер телефона — пришлём код подтверждения.',
      // Канал доставки сервер не называет: при установленном официальном
      // приложении код обычно приходит push-ом в него, а не отдельной SMS.
      _Step.code => 'Отправили код на ${session.phone ?? 'ваш номер'}. '
          'Он приходит в SMS или в официальное приложение MAX.',
      _Step.name => 'Этого номера ещё нет в MAX. Укажите имя — '
          'и аккаунт будет создан.',
      _Step.password => 'На аккаунте включён пароль. Введите его, '
          'чтобы завершить вход.',
      _Step.token => 'Готовый auth-token из веб-версии web.max.ru: '
          'DevTools → Application → хранилище. Код подтверждения не нужен.',
    };
  }

  // ─────────────────────────── шаги ───────────────────────────

  List<Widget> _body(_Step step, SessionState session, SessionController c) {
    return switch (step) {
      _Step.phone => _phoneStep(c),
      _Step.code => _codeStep(session, c),
      _Step.name => _nameStep(c),
      _Step.password => _passwordStep(c),
      _Step.token => _tokenStep(c),
    };
  }

  List<Widget> _phoneStep(SessionController ctrl) {
    return [
      TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        autofillHints: const [AutofillHints.telephoneNumber],
        decoration: const InputDecoration(
          labelText: 'Номер телефона',
          hintText: '+79991234567',
          prefixIcon: Icon(Icons.phone_outlined),
        ),
        onSubmitted: _busy
            ? null
            : (_) => _run(() => ctrl.requestSms(_phoneCtrl.text.trim())),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Получить код',
        busy: _busy,
        onPressed: () => _run(() => ctrl.requestSms(_phoneCtrl.text.trim())),
      ),
    ];
  }

  List<Widget> _codeStep(SessionState session, SessionController ctrl) {
    _ensureResendTicker(session);
    final countdown = _resendCountdown(session);
    final length = session.codeLength ?? 6;
    final attempts = session.attemptsLeft;

    return [
      CodeInput(
        controller: _codeCtrl,
        length: length,
        enabled: !_busy,
        hasError: session.error != null,
        onCompleted: (code) => _run(() => ctrl.submitSmsCode(code)),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Подтвердить',
        busy: _busy,
        onPressed: () => _run(() => ctrl.submitSmsCode(_codeCtrl.text.trim())),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: (_busy || countdown > 0)
            ? null
            : () {
                _codeCtrl.clear();
                _run(() => ctrl.resendSms());
              },
        child: Text(
          countdown > 0
              ? 'Запросить код заново через $countdown с'
              : 'Запросить код заново',
        ),
      ),
      if (attempts != null)
        Text(
          'Осталось запросов кода: $attempts',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
    ];
  }

  List<Widget> _nameStep(SessionController ctrl) {
    return [
      TextField(
        controller: _firstNameCtrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.givenName],
        decoration: const InputDecoration(
          labelText: 'Имя',
          prefixIcon: Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _lastNameCtrl,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.familyName],
        decoration: const InputDecoration(
          labelText: 'Фамилия (необязательно)',
          prefixIcon: Icon(Icons.badge_outlined),
        ),
        onSubmitted: _busy ? null : (_) => _submitRegistration(ctrl),
      ),
      const SizedBox(height: 8),
      Text(
        // Сервер MAX проверяет имя: минимум два символа, без цифр, эмодзи
        // и знаков препинания, плюс фильтр запрещённых слов.
        'Не короче двух символов, только буквы — без цифр, эмодзи и '
        'знаков препинания.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Создать аккаунт',
        busy: _busy,
        onPressed: () => _submitRegistration(ctrl),
      ),
    ];
  }

  void _submitRegistration(SessionController ctrl) {
    final first = _firstNameCtrl.text.trim();
    // Отсекаем заведомо негодное здесь: серверный отказ стоит запроса и
    // приходит без объяснения, какое поле виновато.
    if (first.length < 2) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Имя должно быть не короче двух букв')),
      );
      return;
    }
    _run(() => ctrl.submitRegistration(
          firstName: first,
          lastName: _lastNameCtrl.text.trim(),
        ));
  }

  List<Widget> _passwordStep(SessionController ctrl) {
    return [
      TextField(
        controller: _pwCtrl,
        obscureText: !_pwVisible,
        // TextInputType.text, а НЕ visiblePassword: на Samsung Keyboard
        // visiblePassword показывает цифровой пад, и буквы в пароль 2FA
        // ввести нельзя. text даёт полную QWERTY; скрытие — через obscureText.
        keyboardType: TextInputType.text,
        enableSuggestions: false,
        autocorrect: false,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Пароль',
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: _pwVisible ? 'Скрыть' : 'Показать',
            icon: Icon(
              _pwVisible
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
            ),
            onPressed: () => setState(() => _pwVisible = !_pwVisible),
          ),
        ),
        onSubmitted:
            _busy ? null : (_) => _run(() => ctrl.submit2fa(_pwCtrl.text)),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Войти',
        busy: _busy,
        onPressed: () => _run(() => ctrl.submit2fa(_pwCtrl.text)),
      ),
    ];
  }

  List<Widget> _tokenStep(SessionController ctrl) {
    return [
      TextField(
        controller: _tokenCtrl,
        minLines: 3,
        maxLines: 6,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          labelText: 'auth-token',
          hintText: 'Вставьте токен сюда…',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: 'Войти по токену',
        busy: _busy,
        onPressed: () => _run(() => ctrl.loginWithToken(_tokenCtrl.text)),
      ),
    ];
  }

  // ─────────────────────────── подвал ───────────────────────────

  Widget _footer(_Step step, SessionController ctrl) {
    // На шаге имени назад нельзя: verify-код уже потрачен, возврат означал бы
    // новый запрос кода и лишний расход попыток.
    if (step == _Step.code || step == _Step.password) {
      return TextButton.icon(
        onPressed: _busy
            ? null
            : () {
                _codeCtrl.clear();
                _pwCtrl.clear();
                ctrl.backToPhone();
              },
        icon: const Icon(Icons.arrow_back, size: 18),
        label: const Text('Изменить номер'),
      );
    }
    if (step == _Step.name) {
      return Text(
        'Имя увидят собеседники в MAX. Его можно изменить позже '
        'в настройках профиля.',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return TextButton(
      onPressed: _busy ? null : () => setState(() => _tokenMode = !_tokenMode),
      child: Text(
        _tokenMode ? 'Войти по номеру телефона' : 'У меня есть auth-token',
      ),
    );
  }

  // ─────────────────────────── таймер повтора ───────────────────

  /// Сколько секунд осталось до повторного запроса кода. 0 — можно сейчас.
  int _resendCountdown(SessionState session) {
    final at = session.resendAvailableAt;
    if (at == null) return 0;
    final left = at.difference(DateTime.now()).inSeconds;
    return left > 0 ? left : 0;
  }

  /// Перерисовывать экран раз в секунду, пока идёт отсчёт.
  void _ensureResendTicker(SessionState session) {
    final running = _resendCountdown(session) > 0;
    if (running && _resendTicker == null) {
      _resendTicker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (_resendCountdown(ref.read(sessionProvider)) == 0) {
          _resendTicker?.cancel();
          _resendTicker = null;
        }
      });
    } else if (!running) {
      _resendTicker?.cancel();
      _resendTicker = null;
    }
  }
}

enum _Step { phone, code, name, password, token }

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            : Text(label),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: scheme.onErrorContainer),
            ),
          ),
        ],
      ),
    );
  }
}
