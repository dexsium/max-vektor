import 'dart:async';
import 'dart:io' show Platform;

import 'package:logger/logger.dart';

import '../../core/errors.dart';
import '../../core/logging.dart';
import '../local/secure_storage.dart';
import '../max/contact_name.dart';
import '../max/max_client.dart';

/// [awaitingName] — код принят, но номер ещё не зарегистрирован в MAX:
/// сервер ждёт имя (op 23), после чего аккаунт создаётся.
enum AuthState {
  unauthenticated,
  awaitingSms,
  awaiting2fa,
  awaitingName,
  authenticated,
}

class AuthRepository {
  AuthRepository({
    required this.client,
    required this.storage,
    Logger? logger,
  }) : _log = logger ?? Logger();

  final MaxClient client;
  final SecureStorage storage;
  final Logger _log;

  /// Каким устройством представляться при входе по номеру.
  ///
  /// ВАЖНО: на ANDROID сервер код не отправляет. Он отвечает на запрос
  /// успехом (cmd=1, token, codeLength), но SMS/push не приходит, а
  /// создание капчи для этого пути выключено
  /// (`captcha.create-session-failed / Captcha creation disabled`) —
  /// то есть пройти проверку и «доказать», что клиент настоящий, нечем.
  /// На IOS капчи нет и код приходит сразу; проверено вживую.
  /// WEB тоже рабочий, но требует прохождения капчи в браузере.
  static String get _authDeviceType => Platform.isIOS ? 'IOS' : 'ANDROID';

  /// Значение для secure storage, по которому при восстановлении сессии
  /// поднимается соединение того же типа: токен, выданный IOS-сессии,
  /// сервер не примет от ANDROID.
  static String get _authTokenKind => Platform.isIOS ? 'ios' : 'android';

  String? _verifyToken;
  String? _trackId;

  /// Токен регистрации (`tokenAttrs.REGISTER.token`) — живёт между вводом
  /// кода и вводом имени.
  ///
  /// Публичный: контроллер сессии кладёт его в своё состояние и передаёт
  /// обратно при отправке имени. Если держать токен только здесь, он
  /// теряется при любом пересоздании репозитория — и вторая попытка ввода
  /// имени падает с «Регистрация не начата» вместо настоящей ошибки.
  String? registerToken;

  /// Имя из профиля MAX, если его удалось загрузить при последнем входе.
  /// Нужно переключателю аккаунтов, чтобы подписать карточку без лишнего
  /// сетевого запроса.
  String? profileName;

  /// Соединение уже поднято и залогинено.
  ///
  /// Мультиаккаунт держит сессии живыми, и при возврате к аккаунту LOGIN
  /// повторять НЕ надо: частые LOGIN с одного устройства — ровно тот
  /// поведенческий сигнал, от которого защищается ReconnectPolicy
  /// (см. authThrottle в reconnect_policy.dart).
  bool get isSessionLive => client.isConnected && client.token != null;

  /// Попытаться восстановить сессию из secure storage. true - вошли.
  /// deviceType берём из сохранённого kind — веб-токен требует WEB.
  Future<bool> tryRestoreSession() async {
    if (isSessionLive) {
      _log.i('${MvTag.auth} сессия уже живая — LOGIN не повторяем');
      return true;
    }
    final saved = await storage.readToken();
    if (saved == null) {
      _log.i('${MvTag.auth} сохранённой сессии нет — нужен вход');
      return false;
    }
    final kind = await storage.readTokenKind() ?? 'android';
    final deviceType = switch (kind) {
      'web' => 'WEB',
      'ios' => 'IOS',
      _ => 'ANDROID',
    };
    try {
      if (!client.isConnected) await client.connect(deviceType: deviceType);
      await client.login(saved);
      // Сервер ротирует токен в ответе LOGIN — перезаписываем сохранённый,
      // иначе следующий реконнект пойдёт протухшим токеном → FAIL_LOGIN_TOKEN.
      await _persistRotatedToken();
      _log.i('${MvTag.auth} сессия восстановлена (deviceType=$deviceType)');
      await _captureProfile();
      return true;
    } on MaxTokenRejected catch (e) {
      // Токен реально мёртв — только тогда стираем и просим войти заново.
      _log.w('${MvTag.auth} токен отвергнут сервером, нужен вход: $e');
      await storage.deleteToken();
      return false;
    } catch (e) {
      // Транзиентный сбой (нет сети, proto.payload, таймаут) — токен НЕ
      // трогаем: следующий запуск/reconnect попробует снова. Показываем
      // экран входа, но сохранённый вход остаётся.
      _log.w('${MvTag.auth} восстановление отложено (транзиентно): $e');
      return false;
    }
  }

  /// Вход по готовому auth-token (например из web.max.ru). Веб-токены
  /// сервер принимает только при deviceType=WEB — иначе FAIL_WRONG_PASSWORD.
  Future<void> loginWithToken(String token) async {
    if (client.isConnected) {
      await client.close();
    }
    await client.connect(deviceType: 'WEB');
    await client.login(token);
    // Сохраняем токен из ответа LOGIN (ротированный), а не исходный.
    await storage.writeToken(client.token ?? token);
    await storage.writeTokenKind('web');
    await _captureProfile(
      onError: 'профиль не загрузился после входа по токену',
    );
  }

  /// Условия последнего запроса кода: длина, пауза до повтора, остаток
  /// попыток. UI показывает их пользователю.
  MaxSmsChallenge? lastChallenge;

  Future<MaxSmsChallenge> requestSms(String phone) async {
    _log.i('${MvTag.auth} запрос SMS-кода для номера ***${_tail(phone)}');
    // Если до этого было WEB-соединение (вход по токену), закрываем его и
    // поднимаем чистое соединение нужного типа: иначе _deviceType остался
    // бы WEB и сервер обработал бы запрос иначе.
    if (client.isConnected) {
      await client.close();
    }
    final challenge = await _withFreshConnection(
      () => client.startAuthSms(phone),
      deviceType: _authDeviceType,
    );
    _verifyToken = challenge.token;
    lastChallenge = challenge;
    return challenge;
  }

  /// Гарантирует живое TLS-соединение и выполняет [op]. Если соединение упало
  /// в течение нескольких миллисекунд после connect (race condition при
  /// устаревшем APP_VERSION или сервер DROP'ит INIT) — делает один retry с
  /// небольшой паузой.
  Future<T> _withFreshConnection<T>(
    Future<T> Function() op, {
    String deviceType = 'ANDROID',
  }) async {
    Object? lastErr;
    for (var attempt = 0; attempt < 2; attempt++) {
      if (!client.isConnected) {
        try {
          await client.connect(deviceType: deviceType);
        } catch (e) {
          lastErr = e;
          if (attempt == 0) {
            await Future<void>.delayed(const Duration(milliseconds: 500));
            continue;
          }
          rethrow;
        }
      }
      try {
        return await op();
      } on MaxNotConnected catch (e) {
        lastErr = e;
        // соединение упало между connect() и операцией — попробуем ещё раз
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }
    throw lastErr ?? const MaxNotConnected('connection failed');
  }

  /// Возвращает [AuthState.authenticated] если код принят и токен сохранён,
  /// или [AuthState.awaiting2fa] если включён пароль.
  ///
  /// Verify-токен одноразовый — если запрос отправлен и сервер его
  /// потребил, повтор приведёт к `cmd=3 INVALID_TOKEN`. Поэтому если
  /// соединение мёртво, поднимаем его ОДИН РАЗ (без сетевого запроса),
  /// потом дёргаем confirmSms ровно один раз. Любая ошибка возвращается
  /// наружу — UI попросит запросить новый SMS.
  Future<AuthState> submitSmsCode(String code) async {
    final vt = _verifyToken;
    if (vt == null) throw StateError('SMS не запрошен');
    if (!client.isConnected) {
      try {
        await client.connect(deviceType: _authDeviceType);
      } catch (e) {
        // Если коннект упал ДО отправки confirmSms — verify-token не использован,
        // можно попробовать ещё раз через 500мс.
        await Future<void>.delayed(const Duration(milliseconds: 500));
        await client.connect(deviceType: _authDeviceType);
      }
    }
    _log.i('${MvTag.auth} отправка SMS-кода на проверку');
    final r = await client.confirmSms(vt, code);
    if (r.authToken != null) {
      _log.i('${MvTag.auth} код принят, сессия выдана');
      await _completeLogin(r.authToken!);
      return AuthState.authenticated;
    }
    if (r.registerToken != null) {
      registerToken = r.registerToken;
      return AuthState.awaitingName;
    }
    _log.i('${MvTag.auth} требуется 2FA-пароль');
    _trackId = r.trackId;
    return AuthState.awaiting2fa;
  }

  /// Завершить регистрацию нового аккаунта именем (op 23).
  Future<void> submitRegistration({
    required String firstName,
    String? lastName,
    String? token,
  }) async {
    final regToken = token ?? registerToken;
    if (regToken == null) {
      throw const MaxLoginFailed(
        'Сессия регистрации потеряна. Запросите код заново.',
      );
    }
    final authToken = await _withFreshConnection(
      () => client.completeRegistration(
        token: regToken,
        firstName: firstName,
        lastName: lastName,
      ),
    );
    // Сбрасываем только после успеха: при отказе сервера (например, имя не
    // прошло проверку) токен ещё нужен для повторной попытки.
    registerToken = null;
    await _completeLogin(authToken);
  }

  /// После ошибки `cmd=3` (verify-token истёк/использован) UI должен
  /// сбросить ввод и попросить пользователя нажать «Получить SMS заново».
  void resetSmsState() {
    _verifyToken = null;
  }

  Future<void> submit2fa(String password) async {
    final t = _trackId;
    if (t == null) throw StateError('2FA-челлендж отсутствует');
    _log.i('${MvTag.auth} отправка 2FA-пароля');
    final token = await _withFreshConnection(
      () => client.confirm2fa(t, password),
    );
    await _completeLogin(token);
  }

  Future<void> logout() async {
    _log.i('${MvTag.auth} logout: чистим токен и рвём соединение');
    await storage.wipe();
    await client.close();
  }

  /// Последние 4 цифры номера для лога. Полный номер в лог не пишем.
  static String _tail(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length <= 4 ? '' : digits.substring(digits.length - 4);
  }

  /// Завершение ИНТЕРАКТИВНОГО входа (код, 2FA, регистрация).
  ///
  /// Код/2FA (op 18/115) выдают токен, но сессия ещё НЕ «ONLINE»: пока не
  /// послан LOGIN (op 19), сервер отвечает «Must be ONLINE session» на op 48
  /// (названия чатов), op 83 (видео) и рвёт сокет через пару секунд. Поэтому
  /// после токена ОБЯЗАТЕЛЬНО шлём LOGIN (теперь с userAgent — раньше он
  /// падал с `userAgent required`), и только тогда сессия рабочая.
  Future<void> _completeLogin(String token) async {
    _log.i('${MvTag.auth} вход завершён, токен ${mvRedact(token)} сохранён');
    await storage.writeToken(token);
    await storage.writeTokenKind(_authTokenKind);
    await client.login(token);
    // LOGIN мог вернуть новый (ротированный) токен — сохраняем его.
    await _persistRotatedToken();
    await _captureProfile();
  }

  /// Если сервер вернул в ответе LOGIN новый токен (client.token отличается от
  /// сохранённого), перезаписываем сохранённый — иначе следующий реконнект
  /// пойдёт протухшим токеном и получит FAIL_LOGIN_TOKEN («сессия истекла»).
  Future<void> _persistRotatedToken() async {
    final t = client.token;
    if (t == null || t.isEmpty) return;
    final saved = await storage.readToken();
    if (t != saved) {
      await storage.writeToken(t);
      _log.i('${MvTag.auth} сохранён ротированный токен ${mvRedact(t)}');
    }
  }

  /// Загрузить свой профиль и запомнить userId (в secure storage) и имя
  /// (в памяти, для переключателя аккаунтов). Ошибку не пробрасываем:
  /// вход уже состоялся, профиль — украшение.
  Future<void> _captureProfile({String onError = 'профиль не загрузился'}) async {
    try {
      final me = await client.currentProfile();
      final id = me['id'];
      // Смена владельца слота (и очистка БД) обрабатывается в MaxClient.
      // onLoginUser ДО записи чатов — здесь только фиксируем userId и имя.
      if (id is int) await storage.writeMyUserId(id);
      final name = displayContactName(
        me.map((k, v) => MapEntry(k.toString(), v)),
      );
      if (name != null && name.isNotEmpty) profileName = name;
    } catch (e) {
      _log.w('${MvTag.auth} $onError: $e');
    }
  }
}
