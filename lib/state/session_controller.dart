import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account/account_runtime.dart';
import '../data/repositories/auth_repository.dart';
import 'providers.dart';

enum SessionStatus { loading, signedOut, signedIn }

class SessionState {
  final SessionStatus status;
  final AuthState authFlow;
  final String? phone;
  final String? error;

  /// Сколько цифр в коде подтверждения (сервер сообщает в ответе на op 17).
  final int? codeLength;

  /// Момент, начиная с которого можно запросить код заново.
  final DateTime? resendAvailableAt;

  /// Сколько запросов кода ещё разрешено.
  final int? attemptsLeft;

  const SessionState({
    required this.status,
    this.authFlow = AuthState.unauthenticated,
    this.phone,
    this.error,
    this.codeLength,
    this.resendAvailableAt,
    this.attemptsLeft,
  });

  SessionState copyWith({
    SessionStatus? status,
    AuthState? authFlow,
    String? phone,
    String? error,
    int? codeLength,
    DateTime? resendAvailableAt,
    int? attemptsLeft,
  }) {
    return SessionState(
      status: status ?? this.status,
      authFlow: authFlow ?? this.authFlow,
      phone: phone ?? this.phone,
      error: error,
      codeLength: codeLength ?? this.codeLength,
      resendAvailableAt: resendAvailableAt ?? this.resendAvailableAt,
      attemptsLeft: attemptsLeft ?? this.attemptsLeft,
    );
  }
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    // Смена активного аккаунта перестраивает контроллер: состояние входа
    // принадлежит конкретному аккаунту, а не приложению.
    ref.watch(activeAccountIdProvider);
    Future.microtask(_bootstrap);
    return const SessionState(status: SessionStatus.loading);
  }

  Future<void> _bootstrap() async {
    final repo = ref.read(authRepositoryProvider);
    // Мёртвый токен (FAIL_LOGIN_TOKEN) во время reconnect → разлогин.
    final accountId = ref.read(activeAccountIdProvider);
    repo.client.onAuthInvalid = () async {
      await repo.storage.wipe();
      // Колбэк переживает переключение аккаунтов: протухший токен соседа
      // не должен выкидывать на экран входа того, кто сейчас активен.
      if (ref.read(activeAccountIdProvider) != accountId) return;
      state = const SessionState(
        status: SessionStatus.signedOut,
        error: 'Сессия истекла, войдите снова',
      );
    };
    final ok = await repo.tryRestoreSession();
    if (ok) await _syncAccountCard();
    state = SessionState(
      status: ok ? SessionStatus.signedIn : SessionStatus.signedOut,
    );
  }

  /// Записать в карточку активного аккаунта то, чем его подписывает
  /// переключатель: userId, номер и имя из профиля.
  Future<void> _syncAccountCard({String? phone}) async {
    final runtime = ref.read(accountRuntimeProvider);
    final accounts = ref.read(accountsProvider.notifier);
    final current = ref.read(activeAccountProvider);
    await accounts.update(current.copyWith(
      userId: await runtime.storage.readMyUserId(),
      phone: phone ?? current.phone,
      displayName: runtime.auth.profileName ?? current.displayName,
    ));
  }

  Future<void> requestSms(String phone) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(error: null);
    try {
      final challenge = await repo.requestSms(phone);
      final resendMs = challenge.resendAfterMs;
      state = state.copyWith(
        phone: phone,
        authFlow: AuthState.awaitingSms,
        codeLength: challenge.codeLength,
        attemptsLeft: challenge.attemptsLeft,
        resendAvailableAt: resendMs == null
            ? null
            : DateTime.now().add(Duration(milliseconds: resendMs)),
      );
    } catch (e) {
      state = state.copyWith(error: _humanError(e));
    }
  }

  Future<void> submitSmsCode(String code) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(error: null);
    try {
      final next = await repo.submitSmsCode(code);
      if (next == AuthState.authenticated) {
        await _syncAccountCard(phone: state.phone);
        state = SessionState(status: SessionStatus.signedIn);
      } else {
        // awaiting2fa или awaitingName — экран входа покажет нужный шаг.
        state = state.copyWith(authFlow: next);
      }
    } catch (e) {
      // Если verify-token использован/истёк — сбросим состояние SMS,
      // UI покажет ошибку и предложит запросить новый код.
      repo.resetSmsState();
      state = state.copyWith(error: _humanError(e));
    }
  }

  /// Вернуться к вводу номера: пользователь ошибся или хочет другой номер.
  void backToPhone() {
    ref.read(authRepositoryProvider).resetSmsState();
    state = const SessionState(status: SessionStatus.signedOut);
  }

  /// Повторно отправить SMS-код на тот же номер. Используется после
  /// ошибки подтверждения (истёкший verify-token).
  Future<void> resendSms() async {
    final phone = state.phone;
    if (phone == null || phone.isEmpty) return;
    await requestSms(phone);
  }

  String _humanError(Object e) {
    final s = e.toString();
    // обрезаем тип исключения для красоты
    final idx = s.indexOf(': ');
    return idx >= 0 ? s.substring(idx + 2) : s;
  }

  Future<void> submit2fa(String password) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(error: null);
    try {
      await repo.submit2fa(password);
      await _syncAccountCard(phone: state.phone);
      state = const SessionState(status: SessionStatus.signedIn);
    } catch (e) {
      state = state.copyWith(error: _humanError(e));
    }
  }

  /// Завершить регистрацию нового аккаунта: сервер принял код, но номера
  /// в MAX ещё нет и он ждёт имя.
  Future<void> submitRegistration({
    required String firstName,
    String? lastName,
  }) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(error: null);
    try {
      await repo.submitRegistration(firstName: firstName, lastName: lastName);
      await _syncAccountCard(phone: state.phone);
      state = const SessionState(status: SessionStatus.signedIn);
    } catch (e) {
      state = state.copyWith(error: _humanError(e));
    }
  }

  /// Вход по готовому auth-token (вкладка «По токену» в LoginScreen).
  Future<void> loginWithToken(String token) async {
    final repo = ref.read(authRepositoryProvider);
    state = state.copyWith(error: null);
    final t = token.trim();
    if (t.isEmpty) {
      state = state.copyWith(error: 'Вставьте токен');
      return;
    }
    try {
      await repo.loginWithToken(t);
      await _syncAccountCard();
      state = const SessionState(status: SessionStatus.signedIn);
    } catch (e) {
      state = state.copyWith(error: _humanError(e));
    }
  }

  /// Выход из активного аккаунта: токен стирается, соединение рвётся,
  /// аккаунт исчезает из переключателя вместе со своими локальными данными.
  /// Управление уходит на аккаунт-сосед, если он есть.
  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    final accountId = ref.read(activeAccountIdProvider);
    await repo.logout();
    await ref.read(accountsProvider.notifier).signOutAndRemove(accountId);
    state = const SessionState(status: SessionStatus.signedOut);
  }

  /// Переключиться на другой аккаунт. Соединение соседа остаётся живым,
  /// поэтому повторного LOGIN не происходит (см. AccountRuntimes).
  Future<void> switchAccount(String accountId) async {
    if (ref.read(activeAccountIdProvider) == accountId) return;
    await ref.read(activeAccountIdProvider.notifier).switchTo(accountId);
  }

  /// Добавить ещё один аккаунт MAX и перейти к его входу.
  Future<void> addAccount() async {
    await ref.read(accountsProvider.notifier).addAndActivate();
  }

  /// Открыт ли уже сокет этого аккаунта — переключатель показывает это
  /// пользователю, чтобы было понятно, какие аккаунты сейчас онлайн.
  bool isAccountLive(String accountId) => AccountRuntimes.isOpen(accountId);
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
