import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../core/countries.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/locale_controller.dart';
import '../../data/repositories/auth_repository.dart';
import '../../state/session_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/code_input.dart';
import '../widgets/language_picker.dart';
import '../widgets/vektor_mark.dart';
import 'diagnostics_screen.dart';

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

  /// Выбранная страна для кода телефона. По умолчанию — регион устройства
  /// (как в официальном приложении, o2j.z), обычно Россия (+7).
  late Country _country = defaultCountry();

  /// Тикает раз в секунду, пока идёт отсчёт до повторного запроса кода.
  Timer? _resendTicker;

  /// Полный номер в E.164: «+<код страны><цифры без кода>».
  String _fullPhone() {
    final digits = _phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return '+${_country.dialCode}$digits';
  }

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

    // Экран входа всегда тёмный (брендированный), независимо от темы системы —
    // поэтому оборачиваем в тёмную тему, чтобы поля/пилюли были тёмными.
    return Theme(
      data: AppTheme.dark(),
      child: Scaffold(
      backgroundColor: const Color(0xFF080B12),
      // Тап по пустому месту убирает клавиатуру.
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            const Positioned.fill(child: _LoginBackground()),
            SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Верхний ряд: слева глобус → смена языка прямо в приложении
              // (и «назад», если это добавление аккаунта); справа шестерёнка →
              // «Диагностика» (лог нужен и на экране входа: после вылета
              // настройки недоступны, а причину видно в логе).
              Row(
                children: [
                  if (canCancel)
                    IconButton(
                      tooltip: L.of(context).loginBack,
                      icon: const Icon(Icons.arrow_back, color: Colors.white70),
                      onPressed: _busy ? null : () => ctrl.cancelAddAccount(),
                    ),
                  IconButton(
                    tooltip: L.of(context).langTitle,
                    icon: const Icon(Icons.language, color: Colors.white70),
                    onPressed: _busy ? null : _pickLanguage,
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: L.of(context).settingsDiagnostics,
                    icon: const Icon(Icons.settings_outlined,
                        color: Colors.white70),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DiagnosticsScreen(),
                      ),
                    ),
                  ),
                ],
              ),
              // Контент поднят к верху, а поле ввода тяготеет к центру экрана:
              // Spacer'ы распределяют свободное место, а при появлении
              // клавиатуры IntrinsicHeight+прокрутка не дают контенту обрезаться.
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 420),
                              child: IntrinsicHeight(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    SizedBox(height: canCancel ? 8 : 16),
                                    _header(step),
                                    if (session.error != null) ...[
                                      const SizedBox(height: 20),
                                      _ErrorBanner(text: session.error!),
                                    ],
                                    const Spacer(flex: 2),
                                    AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      child: Column(
                                        key: ValueKey(step),
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: _body(step, session, ctrl),
                                      ),
                                    ),
                                    const Spacer(flex: 3),
                                    _footer(step, ctrl),
                                    const SizedBox(height: 12),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
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
    final isPhone = step == _Step.phone;
    final logoSize = isPhone ? 150.0 : 96.0;
    return Column(
      children: [
        // У PNG-логотипа собственное свечение — показываем как есть.
        VektorMark(size: logoSize),
        SizedBox(height: isPhone ? 4 : 12),
        if (isPhone)
          const _VektorWordmark()
        else
          Text(
            _title(step),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        const SizedBox(height: 10),
        Text(
          _subtitle(step),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 15, color: Colors.white70),
        ),
      ],
    );
  }

  String _title(_Step step) {
    final l = L.of(context);
    return switch (step) {
      _Step.phone => AppMeta.name,
      _Step.code => l.loginCodeTitle,
      _Step.name => l.loginNameTitle,
      _Step.password => l.login2faTitle,
      _Step.token => l.loginTokenTitle,
    };
  }

  String _subtitle(_Step step) {
    final l = L.of(context);
    final session = ref.read(sessionProvider);
    return switch (step) {
      _Step.phone => l.loginPhonePrompt,
      // Канал доставки сервер не называет: при установленном официальном
      // приложении код обычно приходит push-ом в него, а не отдельной SMS.
      _Step.code => l.loginCodePrompt(session.phone ?? ''),
      _Step.name => l.loginNamePrompt,
      _Step.password => l.login2faPrompt,
      _Step.token => 'auth-token · web.max.ru → DevTools → Application',
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
    final scheme = Theme.of(context).colorScheme;
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Селектор кода страны — тап открывает список.
          InkWell(
            onTap: _busy ? null : _pickCountry,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_country.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 6),
                  Text('+${_country.dialCode}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  Icon(Icons.arrow_drop_down, color: scheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: InputDecoration(
                labelText: L.of(context).loginPhoneField,
                hintText: '999 123-45-67',
              ),
              onSubmitted: _busy
                  ? null
                  : (_) => _run(() => ctrl.requestSms(_fullPhone())),
            ),
          ),
        ],
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: L.of(context).loginGetCode,
        busy: _busy,
        onPressed: () => _run(() => ctrl.requestSms(_fullPhone())),
      ),
    ];
  }

  /// Смена языка интерфейса прямо в приложении (глобус вверху слева).
  Future<void> _pickLanguage() async {
    await showLanguagePicker(
      context,
      current: ref.read(localeProvider),
      onSelect: (locale) => ref.read(localeProvider.notifier).set(locale),
    );
  }

  /// Список стран с поиском. Выбор подставляет код в селектор.
  Future<void> _pickCountry() async {
    final chosen = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _CountryPicker(selected: _country),
    );
    if (chosen != null && mounted) setState(() => _country = chosen);
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
        label: L.of(context).loginConfirm,
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
              ? L.of(context).loginResendIn('$countdown')
              : L.of(context).loginResend,
        ),
      ),
      if (attempts != null)
        Text(
          L.of(context).loginAttemptsLeft(attempts),
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
        decoration: InputDecoration(
          labelText: L.of(context).loginFirstName,
          prefixIcon: const Icon(Icons.person_outline),
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _lastNameCtrl,
        textCapitalization: TextCapitalization.words,
        autofillHints: const [AutofillHints.familyName],
        decoration: InputDecoration(
          labelText: L.of(context).loginLastNameOptional,
          prefixIcon: const Icon(Icons.badge_outlined),
        ),
        onSubmitted: _busy ? null : (_) => _submitRegistration(ctrl),
      ),
      const SizedBox(height: 8),
      Text(
        // Сервер MAX проверяет имя: минимум два символа, без цифр, эмодзи
        // и знаков препинания, плюс фильтр запрещённых слов.
        L.of(context).loginNameHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: L.of(context).loginCreateAccount,
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
        SnackBar(content: Text(L.of(context).loginNameTooShort)),
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
          labelText: L.of(context).loginPassword,
          prefixIcon: const Icon(Icons.lock_outline),
          suffixIcon: IconButton(
            tooltip: _pwVisible ? L.of(context).loginHide : L.of(context).loginShow,
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
        label: L.of(context).loginSignIn,
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
        decoration: InputDecoration(
          labelText: 'auth-token',
          hintText: L.of(context).loginTokenHint,
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 20),
      _PrimaryButton(
        label: L.of(context).loginTokenButton,
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
        label: Text(L.of(context).loginChangeNumber),
      );
    }
    if (step == _Step.name) {
      return Text(
        L.of(context).loginNameVisibleHint,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return TextButton(
      onPressed: _busy ? null : () => setState(() => _tokenMode = !_tokenMode),
      child: Text(
        _tokenMode
            ? L.of(context).loginByPhone
            : L.of(context).loginHaveToken,
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

/// Список стран с поиском по названию или коду. Возвращает выбранную страну.
class _CountryPicker extends StatefulWidget {
  const _CountryPicker({required this.selected});
  final Country selected;

  @override
  State<_CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<_CountryPicker> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final q = _query.trim().toLowerCase();
    final items = q.isEmpty
        ? kCountries
        : kCountries
            .where((c) =>
                c.name.toLowerCase().contains(q) ||
                c.dialCode.contains(q) ||
                c.iso.toLowerCase().contains(q))
            .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            children: [
              // Крестик закрытия окна выбора страны (справа сверху).
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, top: 4),
                  child: IconButton(
                    tooltip: L.of(context).commonClose,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: L.of(context).loginSearchCountry,
                    prefixIcon: const Icon(Icons.search),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final c = items[i];
                    final isSel = c.iso == widget.selected.iso;
                    return ListTile(
                      leading:
                          Text(c.flag, style: const TextStyle(fontSize: 24)),
                      title: Text(c.name),
                      trailing: Text('+${c.dialCode}',
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600)),
                      selected: isSel,
                      onTap: () => Navigator.of(context).pop(c),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: busy
            ? null
            : [
                BoxShadow(
                  color: const Color(0xFF2E7DF0).withValues(alpha: 0.55),
                  blurRadius: 28,
                  spreadRadius: -2,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: FilledButton(
        onPressed: busy ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF2E7DF0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.4, color: Colors.white),
              )
            : Text(label),
      ),
    );
  }
}

/// Надпись «Vektor» с сине-белым градиентом (как на брендированном входе).
class _VektorWordmark extends StatelessWidget {
  const _VektorWordmark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [Color(0xFF8FC0FF), Color(0xFFFFFFFF), Color(0xFF3E86F5)],
        stops: [0.0, 0.45, 1.0],
      ).createShader(rect),
      child: const Text(
        'Vektor',
        style: TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Тёмный фон экрана входа с синим свечением снизу (как «горизонт планеты»).
class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF080B12), Color(0xFF0A1020), Color(0xFF070A11)],
          stops: [0.0, 0.55, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Нижнее-левое свечение — дуга «горизонта».
          Positioned(
            left: -160,
            bottom: -220,
            child: Container(
              width: 520,
              height: 520,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2E7DF0).withValues(alpha: 0.30),
                    const Color(0xFF2E7DF0).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
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
