import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:logger/logger.dart';
import 'package:uuid/uuid.dart';

import '../../core/constants.dart';
import '../../core/errors.dart';
import '../../core/logging.dart';
import 'contact_name.dart';
import 'lz4_block.dart';
import 'max_codec.dart';
import 'models/incoming_message.dart';
import 'raw_parsers.dart';
import 'reconnect_policy.dart';

/// Колбэк для отладки push-фреймов (как `on_push_debug` в Python-версии).
typedef PushDebug = void Function(MaxFrame frame);

/// Состояние транспортного соединения. На него подписывается UI и репозитории.
enum MaxConnectionState { disconnected, connecting, connected, reconnecting }

/// Один MaxClient = одно TLS-соединение к api.oneme.ru:443 + один читающий
/// сабскрипшен. Запросы идут через [_request], ответы матчатся по seq.
/// Сервер-пуш сваливается в [incomingStream].
/// Значения поля `type` в запросе кода (op 17).
///
/// Официальный веб-клиент выбирает их так:
/// `m.name === 'captcha' ? 'START_AUTH' : 'RESEND'` — то есть обычный
/// запрос кода уходит как [resend], а [startAuth] используется, когда
/// пользователь уже прошёл капчу. Апстрим-форк всегда слал [startAuth],
/// и сервер отвечал успехом, не отправляя код.
class MaxAuthRequestType {
  const MaxAuthRequestType._();

  static const String resend = 'RESEND';
  static const String startAuth = 'START_AUTH';
}

/// Условия ввода кода подтверждения, присланные сервером вместе с
/// verify-токеном (ответ на op 17).
typedef MaxSmsChallenge = ({
  String token,
  int? codeLength,
  int? resendAfterMs,
  int? attemptsLeft,
});

class MaxClient {
  MaxClient({
    this.onPushDebug,
    Logger? logger,
    this.deviceIdLoader,
    this.userAgentLoader,
  }) : _log = logger ?? Logger(printer: PrettyPrinter(methodCount: 0)) {
    _reconnect = _ReconnectManager(this, _log);
  }

  final PushDebug? onPushDebug;
  final Logger _log;
  late final _ReconnectManager _reconnect;

  /// Источник стабильного deviceId. Вызывается один раз перед первым INIT,
  /// результат кешируется на всё время жизни клиента. Если null (например в
  /// CLI), генерируется разовый UUID — как в python-клиенте.
  final Future<String> Function()? deviceIdLoader;

  /// Источник поля `userAgent` для INIT по текущему deviceType. Если null или
  /// бросает — используется минимальный проверенный набор. См. DeviceProfile.
  final Future<Map<String, Object?>> Function(String deviceType)?
      userAgentLoader;

  /// Вызывается когда сервер отверг сохранённый токен (FAIL_LOGIN_TOKEN) —
  /// UI должен разлогинить и показать экран входа, а не висеть в reconnect.
  void Function()? _authInvalid;
  set onAuthInvalid(void Function()? cb) => _authInvalid = cb;

  String? _token;

  /// Часы с последнего успешного LOGIN — для anti-storm throttle
  /// (см. [ReconnectPolicy.authThrottle]). Не сбрасывается при дисконнекте:
  /// считаем именно время с последней АВТОРИЗАЦИИ, а не с разрыва.
  final Stopwatch _sinceLogin = Stopwatch();
  Duration get sinceLastLogin =>
      _sinceLogin.isRunning ? _sinceLogin.elapsed : const Duration(days: 3650);

  /// Keepalive: пока соединение живо, раз в [_pingInterval] шлём лёгкий
  /// read-only запрос, чтобы сервер не рвал сокет по простою и не провоцировал
  /// реконнект-шторм с переавторизацией (главный бан-фактор).
  Timer? _keepalive;
  // Официальный клиент шлёт PING каждые 15 сек (frk.java: heartbeat(15)).
  static const Duration _pingInterval = Duration(seconds: 15);

  String get deviceId => _deviceId ?? '(unresolved)';

  /// Кеш разрешённого deviceId. null до первого [_resolveDeviceId].
  String? _deviceId;

  /// Разрешить deviceId один раз: сперва из loader (persisted), при его
  /// отсутствии — разовый UUID. Повторные вызовы возвращают тот же id, чтобы
  /// reconnect не менял идентичность устройства внутри одной сессии.
  Future<String> _resolveDeviceId() async {
    final cached = _deviceId;
    if (cached != null) return cached;
    String? loaded;
    if (deviceIdLoader != null) {
      try {
        loaded = await deviceIdLoader!();
      } catch (e) {
        _log.w('${MvTag.init} deviceIdLoader failed, fallback to ephemeral: $e');
      }
    }
    final resolved = (loaded != null && loaded.isNotEmpty)
        ? loaded
        : const Uuid().v4();
    _deviceId = resolved;
    return resolved;
  }

  SecureSocket? _socket;
  StreamSubscription<Uint8List>? _sub;
  int _seq = 0;
  bool _closed = false;
  final _pending = <int, Completer<MaxFrame>>{};
  final _pushCtrl = StreamController<IncomingMessage>.broadcast();
  final _stateCtrl = StreamController<MaxConnectionState>.broadcast();
  MaxConnectionState _state = MaxConnectionState.disconnected;
  final _bufferBuilder = BytesBuilder(copy: false);

  Stream<IncomingMessage> get incomingStream => _pushCtrl.stream;
  Stream<MaxConnectionState> get connectionState => _stateCtrl.stream;
  MaxConnectionState get currentState => _state;
  String? get token => _token;
  bool get isConnected => _socket != null && !_closed;

  void _emitState(MaxConnectionState s) {
    if (_state == s) return;
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }

  /// Тип устройства для INIT: 'ANDROID' (SMS-флоу) или 'WEB' (вход по
  /// веб-токену из web.max.ru). Веб-токены сервер принимает только при WEB.
  String _deviceType = MaxProto.deviceType;

  /// [deviceType] null => сохранить текущий (важно для reconnect: иначе
  /// переподключение сбрасывало бы WEB-сессию на ANDROID и сервер отвергал
  /// бы веб-токен с login.cred).
  Future<void> connect({String? deviceType}) async {
    if (deviceType != null) _deviceType = deviceType;
    _log.i(
      '${MvTag.socket} connect → ${MaxProto.host}:${MaxProto.port} '
      '(deviceType=$_deviceType)',
    );
    _emitState(MaxConnectionState.connecting);
    try {
      final s = await _openSecureSocket();
      s.setOption(SocketOption.tcpNoDelay, true);
      _socket = s;
      _closed = false;
      _sub = s.listen(
        _onData,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );
      await _initSession();
      _emitState(MaxConnectionState.connected);
    } catch (e) {
      // INIT упал или сокет порвался — приведём состояние к чистому
      // disconnected, чтобы следующий connect() имел шанс начать заново.
      await _sub?.cancel();
      _sub = null;
      try {
        await _socket?.close();
      } catch (_) {}
      _socket = null;
      _emitState(MaxConnectionState.disconnected);
      rethrow;
    }
  }

  /// IP, добытый через DoH — кэш на сессию, чтобы не дёргать DoH на каждом
  /// reconnect, пока системный DNS «молчит».
  String? _dohIp;

  /// Открывает TLS-сокет к api.oneme.ru. Сначала обычным путём (системный DNS).
  /// Если системный DNS не резолвит хост (errno 7 — бывает на Wi-Fi с
  /// фильтрующим/недоступным DNS), резолвим адрес через DoH (Cloudflare, по IP,
  /// мимо системного DNS) и коннектимся по IP с SNI и проверкой сертификата на
  /// api.oneme.ru. Так клиент поднимается и на мобильной, и на Wi-Fi, чей DNS
  /// не отдаёт адрес MAX.
  Future<SecureSocket> _openSecureSocket() async {
    try {
      return await SecureSocket.connect(
        MaxProto.host,
        MaxProto.port,
        timeout: const Duration(seconds: 15),
      );
    } on SocketException catch (e) {
      final isDnsFail = e.osError?.errorCode == 7 ||
          e.message.contains('Failed host lookup') ||
          e.message.contains('No address associated');
      if (!isDnsFail) rethrow;
      final ip = _dohIp ?? await _resolveViaDoh(MaxProto.host);
      if (ip == null) {
        _log.w('${MvTag.socket} DoH-фолбэк не дал IP для ${MaxProto.host}');
        rethrow;
      }
      _dohIp = ip;
      try {
        final raw = await Socket.connect(
          ip,
          MaxProto.port,
          timeout: const Duration(seconds: 15),
        );
        raw.setOption(SocketOption.tcpNoDelay, true);
        // host: задаёт SNI и имя для проверки сертификата — коннект по IP,
        // но TLS валидируется против api.oneme.ru.
        final secure = await SecureSocket.secure(raw, host: MaxProto.host);
        _log.i('${MvTag.socket} подключение через DoH-IP $ip (системный DNS молчит)');
        return secure;
      } catch (_) {
        _dohIp = null; // IP протух/неверный — сбросим кэш
        rethrow;
      }
    }
  }

  /// Резолв A-записи через DNS-over-HTTPS (Cloudflare). Запрос идёт на IP
  /// 1.1.1.1/1.0.0.1, поэтому не зависит от системного DNS.
  Future<String?> _resolveViaDoh(String host) async {
    final http = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      for (final resolver in const ['1.1.1.1', '1.0.0.1']) {
        try {
          final uri =
              Uri.parse('https://$resolver/dns-query?name=$host&type=A');
          final req = await http.getUrl(uri);
          req.headers.set('accept', 'application/dns-json');
          final resp = await req.close().timeout(const Duration(seconds: 8));
          if (resp.statusCode != 200) continue;
          final body = await resp.transform(utf8.decoder).join();
          final data = jsonDecode(body);
          if (data is Map && data['Answer'] is List) {
            for (final a in (data['Answer'] as List)) {
              // type 1 = A-запись (IPv4)
              if (a is Map && a['type'] == 1) {
                final ip = a['data']?.toString();
                if (ip != null && ip.isNotEmpty) return ip;
              }
            }
          }
        } catch (e) {
          _log.d('${MvTag.socket} DoH $resolver: $e');
        }
      }
    } finally {
      http.close(force: true);
    }
    return null;
  }

  /// Переподключение по сохранённому токену. Не выставляет [_closed].
  /// Если [_token] не задан — это голый [connect].
  Future<void> reconnect() async {
    await _disconnect();
    await connect();
    final t = _token;
    if (t != null && t.isNotEmpty) {
      await login(t);
    }
  }

  /// Закрытие сокета без флага «навсегда» — для авто-переподключения.
  Future<void> _disconnect() async {
    _stopKeepalive();
    await _sub?.cancel();
    _sub = null;
    try {
      await _socket?.close();
    } catch (_) {}
    _socket = null;
    _failAllPending(const MaxNotConnected('disconnected'));
  }

  /// Явное закрытие пользователем. Блокирует все будущие reconnect-попытки.
  Future<void> close() async {
    _closed = true;
    _reconnect.cancel();
    await _disconnect();
    _emitState(MaxConnectionState.disconnected);
  }

  Future<void> _initSession() async {
    final deviceId = await _resolveDeviceId();
    final userAgent = await _resolveUserAgent();
    _log.i(
      '${MvTag.init} INIT deviceType=$_deviceType '
      'appVersion=${MaxProto.appVersion} proto=v${MaxProto.protoVersion} '
      'deviceId=${mvRedact(deviceId)}',
    );
    final f = await _request(MaxOp.init, {
      'userAgent': userAgent,
      'deviceId': deviceId,
    });
    if (f.cmd != 1) {
      final r = _rejection(f);
      _log.w(
        '${MvTag.init} INIT отвергнут сервером: cmd=${f.cmd} '
        'error=${r.code ?? '-'} message=${r.message ?? '-'}',
      );
      throw MaxError(
        r.localized ??
            r.code ??
            'INIT отклонён сервером (cmd=${f.cmd}). Вероятно, устарела '
                'версия клиента: app ${MaxProto.appVersion}, '
                'proto v${MaxProto.protoVersion}.',
      );
    }
    _log.i('${MvTag.init} INIT принят');
  }

  /// Минимальный userAgent — проверен рабочим python-клиентом, используется
  /// как fallback и для WEB.
  Map<String, Object?> _minimalUserAgent() => {
    'deviceType': _deviceType,
    'locale': MaxProto.locale,
    'appVersion': MaxProto.appVersion,
  };

  Future<Map<String, Object?>> _resolveUserAgent() async {
    final loader = userAgentLoader;
    if (loader == null) return _minimalUserAgent();
    try {
      final ua = await loader(_deviceType);
      if (ua.isEmpty) return _minimalUserAgent();
      return ua;
    } catch (e) {
      _log.w('${MvTag.init} userAgentLoader failed, fallback to minimal: $e');
      return _minimalUserAgent();
    }
  }

  // ─────────────────────────── auth ───────────────────────────

  /// Причина отказа из ответа сервера.
  ///
  /// На cmd != 1 сервер кладёт в payload structured error:
  /// `{error, message, localizedMessage, title}`. Раньше эта информация
  /// терялась, и пользователь видел бесполезное «cmd=3».
  ({String? localized, String? code, String? message}) _rejection(MaxFrame f) {
    final d = f.decoded;
    if (d is! Map) return (localized: null, code: null, message: null);
    final m = d.map((k, v) => MapEntry(k.toString(), v));
    String? pick(String key) {
      final v = m[key]?.toString();
      return (v == null || v.isEmpty) ? null : v;
    }

    return (
      localized: pick('localizedMessage'),
      code: pick('error'),
      message: pick('message'),
    );
  }

  /// Отказы, где серверного текста мало и нужно объяснить, что делать.
  static String? _actionableHint(String? code) {
    if (code == null) return null;
    // Аккаунт есть, но у него не задан пароль двухфакторной защиты, и MAX
    // не пускает вход с нового устройства, пока его не поставят. В
    // официальном веб-клиенте это отдельный экран `session-no-2fa`.
    if (code.contains('no2fa')) {
      return 'MAX не разрешает вход с нового устройства, пока на аккаунте '
          'не задан пароль двухфакторной защиты.\n\n'
          'Откройте официальное приложение MAX на телефоне, где вы уже '
          'вошли: Настройки → Конфиденциальность и безопасность → '
          'задайте пароль (двухфакторная защита). Затем вернитесь сюда и '
          'войдите заново — после кода приложение спросит этот пароль.';
    }
    return null;
  }

  /// Единый выход по отказу: пишет причину в лог (уровень warning, поэтому
  /// видно и в release) и бросает понятное пользователю сообщение.
  Never _failWith(MaxFrame f, String op) {
    final r = _rejection(f);
    _log.w(
      '${MvTag.auth} $op отклонён сервером: cmd=${f.cmd} '
      'error=${r.code ?? '-'} message=${r.message ?? '-'}',
    );
    final hint = _actionableHint(r.code);
    if (hint != null) throw MaxLoginFailed(hint);
    // Код сервера дописываем ВСЕГДА: localizedMessage часто сводится к
    // «Ошибка валидации» и не даёт понять, что именно не так. Код (напр.
    // validate.first_name.invalid_chars) — единственная надёжная зацепка.
    final tail = r.code != null ? '\n[$op: ${r.code}]' : '\n[$op cmd=${f.cmd}]';
    if (r.localized != null) throw MaxLoginFailed('${r.localized!}$tail');
    if (r.message != null) throw MaxLoginFailed('${r.message!}$tail');
    throw MaxLoginFailed(
      '$op отклонён сервером (cmd=${f.cmd}) без объяснения причины. '
      'Обычно так отвечают на устаревшую версию клиента '
      '(app ${MaxProto.appVersion}, proto v${MaxProto.protoVersion}) '
      'или на слишком частые попытки входа с одного номера.$tail',
    );
  }

  /// Ответ сервера на запрос кода подтверждения.
  ///
  /// Кроме verify-токена сервер сообщает условия ввода: длину кода,
  /// через сколько можно запросить код заново и сколько попыток осталось.
  /// Раньше всё это отбрасывалось, и пользователю нечего было показать.
  /// Спросить сервер, нужна ли капча перед запросом кода (op 224).
  ///
  /// Возвращает ссылку на страницу капчи, если сервер её требует, иначе
  /// null. Решает капчу ТОЛЬКО человек — приложение её не проходит.
  Future<String?> captchaSessionLink(String phone) async {
    final f = await _request(MaxOp.captchaSession, {
      'source': 'auth',
      'identifier': phone,
    });
    _log.i('${MvTag.auth} captcha session: cmd=${f.cmd} '
        'decoded=${_redact(f.decoded)}');
    if (f.cmd != 1) return null;
    final d = f.decoded;
    if (d is! Map) return null;
    final link = d['link'];
    return (link is String && link.isNotEmpty) ? link : null;
  }

  /// Начать вход по QR (op 112). Возвращает сырой ответ сервера, чтобы
  /// вызывающий сам вытащил qrLink/token — точные имена полей проверяются
  /// живым probe (см. tool_probe_qr.dart).
  Future<Map<String, dynamic>> qrStart() async {
    final f = await _request(MaxOp.qrStart, {'type': 0});
    if (f.cmd != 1) _failWith(f, 'QR_START');
    final d = f.decoded;
    _log.i('${MvTag.auth} QR_START ok: ${_redact(d)}');
    return d is Map ? d.map((k, v) => MapEntry(k.toString(), v)) : {};
  }

  /// Опрос статуса QR (op 104). Возвращает сырой ответ сервера.
  Future<Map<String, dynamic>> qrPoll(String trackId) async {
    final f = await _request(MaxOp.qrPoll, {'trackId': trackId});
    if (f.cmd != 1) _failWith(f, 'QR_POLL');
    final d = f.decoded;
    return d is Map ? d.map((k, v) => MapEntry(k.toString(), v)) : {};
  }

  /// Подтвердить вход по QR (op 290). Вызывается на УЖЕ ЗАЛОГИНЕННОМ
  /// клиенте: [scanned] — содержимое отсканированного QR (токен/ссылка,
  /// показанные на web.max.ru или другом устройстве). Сервер авторизует тот
  /// вход и отвечает статусом/профилем.
  ///
  /// ВНИМАНИЕ: точное имя поля payload из обфусцированного APK не
  /// подтверждено; семейство auth стабильно использует `token`. Полный ответ
  /// сервера пишется в лог — по первому живому сканированию поле уточняется.
  Future<Map<String, dynamic>> approveQrLogin(String scanned) async {
    final value = scanned.trim();
    _log.i('${MvTag.auth} QR approve: отправляю (${mvRedact(value)})');
    final f = await _request(MaxOp.qrApprove, {'token': value});
    _log.i('${MvTag.auth} QR approve ответ: cmd=${f.cmd} '
        'decoded=${_redact(f.decoded)}');
    if (f.cmd != 1) _failWith(f, 'QR_APPROVE');
    final d = f.decoded;
    return d is Map ? d.map((k, v) => MapEntry(k.toString(), v)) : {};
  }

  Future<MaxSmsChallenge> startAuthSms(
    String phone, {
    String type = MaxAuthRequestType.resend,
    String captchaToken = '',
  }) async {
    final f = await _request(MaxOp.authRequest, {
      'phone': phone,
      'type': type,
      'language': MaxProto.locale,
      // Официальный веб-клиент передаёт captchaToken всегда: пустую строку,
      // когда сервер капчу не требует (сейчас он отвечает
      // `captcha.create-session-failed / Captcha creation disabled`).
      'captchaToken': captchaToken,
    });
    if (f.cmd != 1) _failWith(f, 'AUTH_REQUEST');
    final t = RawParsers.findLongToken(f.body);
    if (t == null) throw const MaxLoginFailed('verify token not extracted');

    int? intField(String key) {
      final d = f.decoded;
      if (d is! Map) return null;
      final v = d[key];
      return v is num ? v.toInt() : null;
    }

    final challenge = (
      token: t,
      codeLength: intField('codeLength'),
      // Официальный веб-клиент отсчитывает повтор именно по
      // altActionDuration (`resendAt: Date.now() + t.altActionDuration`),
      // requestMaxDuration оставляем запасным вариантом.
      resendAfterMs:
          intField('altActionDuration') ?? intField('requestMaxDuration'),
      attemptsLeft: intField('requestCountLeft'),
    );
    _log.i(
      '${MvTag.auth} код запрошен: длина=${challenge.codeLength ?? '?'} '
      'повтор через=${challenge.resendAfterMs ?? '?'}мс '
      'попыток осталось=${challenge.attemptsLeft ?? '?'}',
    );
    return challenge;
  }

  /// Возвращает результат проверки кода: вход, 2FA или регистрация.
  ///
  /// Три исхода (порядок разбора — как в официальном веб-клиенте):
  /// * `authToken` — аккаунт существует, вход выполнен;
  /// * `trackId` — включён пароль 2FA;
  /// * `registerToken` — аккаунта НЕТ, сервер прислал
  ///   `tokenAttrs.REGISTER.token`, дальше нужен op 23 с именем.
  Future<({String? authToken, String? trackId, String? registerToken})>
      confirmSms(
    String verifyToken,
    String code,
  ) async {
    final f = await _request(MaxOp.authConfirm, {
      'token': verifyToken,
      'verifyCode': code,
      'authTokenType': 'CHECK_CODE',
    });
    if (f.cmd != 1) {
      final r = _rejection(f);
      final hint = _actionableHint(r.code);
      if (hint != null) throw MaxLoginFailed(hint);
      if (r.localized == null && r.code == null && f.cmd == 3) {
        _log.w('${MvTag.auth} AUTH_CONFIRM отклонён: cmd=3 без деталей');
        throw const MaxLoginFailed(
          'SMS-код неверный или истёк. Запросите новый код.',
        );
      }
      _failWith(f, 'AUTH_CONFIRM');
    }

    // Номер ещё не зарегистрирован: сервер отдаёт токен регистрации в
    // tokenAttrs.REGISTER.token, профиля при этом нет.
    final registerToken = _registerToken(f.decoded);
    if (registerToken != null) {
      _log.i('${MvTag.auth} номер не зарегистрирован — требуется имя');
      return (authToken: null, trackId: null, registerToken: registerToken);
    }

    // Постоянный токен входа лежит в tokenAttrs.LOGIN.token (так его берёт
    // транспорт официального клиента, case 18/115). findLongToken по сырым
    // байтам иногда цеплял НЕ тот длинный токен — отсюда и «proto.payload»
    // на LOGIN, и плавающие сбои. Сырой парсер оставлен запасным.
    final authToken =
        _loginToken(f.decoded) ?? RawParsers.findLongToken(f.body);
    if (authToken != null) {
      return (authToken: authToken, trackId: null, registerToken: null);
    }

    final trackId = _challengeTrackId(f.decoded);
    if (trackId != null || _contains(f.body, 'passwordChallenge')) {
      final tid = trackId ?? RawParsers.findUuid(f.body);
      if (tid == null) {
        throw const MaxLoginFailed('2FA required but trackId not found');
      }
      return (authToken: null, trackId: tid, registerToken: null);
    }
    throw const MaxLoginFailed('no auth token and no 2FA challenge');
  }

  /// Постоянный токен входа из ответа авторизации: `tokenAttrs.LOGIN.token`.
  /// Он же — токен для повторного входа (op 19) при перезапуске.
  static String? _loginToken(Object? decoded) {
    if (decoded is! Map) return null;
    final attrs = decoded['tokenAttrs'];
    if (attrs is! Map) return null;
    final login = attrs['LOGIN'];
    if (login is! Map) return null;
    final token = login['token'];
    return (token is String && token.isNotEmpty) ? token : null;
  }

  /// trackId 2FA-челленджа из `passwordChallenge.trackId`.
  static String? _challengeTrackId(Object? decoded) {
    if (decoded is! Map) return null;
    final ch = decoded['passwordChallenge'];
    if (ch is! Map) return null;
    final tid = ch['trackId'];
    return (tid is String && tid.isNotEmpty) ? tid : null;
  }

  /// Понятное объяснение отказа регистрации по коду ошибки сервера.
  ///
  /// Набор кодов — из обработчика ошибок официального веб-клиента:
  /// `validate.FIELD.{empty,min_length,invalid_chars,
  /// invalid_complex_chars,censor_restricted}`. Сервер присылает и свой
  /// localizedMessage, но он часто сводится к «ошибка валидации» и не
  /// говорит, какое поле виновато.
  static String? _registerValidationHint(String? code) {
    if (code == null || !code.startsWith('validate.')) return null;
    final isLast = code.contains('last_name');
    final field = isLast ? 'Фамилия' : 'Имя';
    if (code.endsWith('.empty')) {
      return '$field не может быть пустым.';
    }
    if (code.endsWith('.min_length')) {
      return '$field слишком короткое — нужно минимум два символа.';
    }
    if (code.endsWith('.invalid_chars') ||
        code.endsWith('.invalid_complex_chars')) {
      return '$field содержит недопустимые символы. Оставьте только буквы, '
          'без цифр, эмодзи и знаков препинания.';
    }
    if (code.endsWith('.censor_restricted')) {
      return '$field отклонено фильтром сервера MAX. Попробуйте другое.';
    }
    return '$field не прошло проверку сервера ($code).';
  }

  /// `tokenAttrs.REGISTER.token` из ответа на op 18, если он там есть.
  static String? _registerToken(Object? decoded) {
    if (decoded is! Map) return null;
    final attrs = decoded['tokenAttrs'];
    if (attrs is! Map) return null;
    final reg = attrs['REGISTER'];
    if (reg is! Map) return null;
    final token = reg['token'];
    return (token is String && token.isNotEmpty) ? token : null;
  }

  /// Завершение регистрации нового аккаунта (op 23).
  ///
  /// Вызывается с токеном из [confirmSms]. Сервер валидирует имя и в ответ
  /// присылает профиль вместе с auth-токеном.
  ///
  /// Структура запроса взята из модуля авторизации официального веб-клиента:
  /// `{token, tokenType: 'REGISTER', firstName, lastName?, photoId?}`.
  /// Аватар (`photoId`) не отправляем — его можно поставить после входа.
  Future<String> completeRegistration({
    required String token,
    required String firstName,
    String? lastName,
  }) async {
    final trimmedLast = lastName?.trim();
    _log.i('${MvTag.auth} регистрация: отправляем имя');
    // Набор и порядок ключей — как в официальном клиенте:
    // {token, tokenType, firstName, lastName, photoId}. Ключи lastName и
    // photoId присутствуют ВСЕГДА, даже пустыми: раньше мы их опускали, и
    // сервер отвечал отказом валидации на имя, которое официальное
    // приложение принимает.
    final f = await _request(MaxOp.register, {
      'token': token,
      'tokenType': 'REGISTER',
      'firstName': firstName.trim(),
      'lastName': (trimmedLast == null || trimmedLast.isEmpty)
          ? null
          : trimmedLast,
      'photoId': null,
    });
    if (f.cmd != 1) {
      final r = _rejection(f);
      _log.w(
        '${MvTag.auth} регистрация отклонена: cmd=${f.cmd} '
        'error=${r.code ?? '-'} message=${r.message ?? '-'}',
      );
      final hint = _registerValidationHint(r.code);
      // Код показываем всегда: серверный localizedMessage сводится к
      // «ошибка валидации» и не даёт понять, что именно исправлять.
      if (hint != null) throw MaxLoginFailed('$hint\n[${r.code}]');
      _failWith(f, 'REGISTER');
    }
    // Ответ op 23 кладёт токен в payload.token (транспорт офиц. клиента,
    // case 23), но на всякий случай пробуем и tokenAttrs.LOGIN, и сырой парсер.
    final dec = f.decoded;
    final authToken = (dec is Map && dec['token'] is String
            ? dec['token'] as String
            : null) ??
        _loginToken(dec) ??
        RawParsers.findLongToken(f.body);
    if (authToken == null || authToken.isEmpty) {
      throw const MaxLoginFailed(
        'Регистрация прошла, но сервер не вернул токен сессии',
      );
    }
    _log.i('${MvTag.auth} регистрация завершена');
    return authToken;
  }

  Future<String> confirm2fa(String trackId, String password) async {
    final f = await _request(MaxOp.twoFa, {
      'trackId': trackId,
      'password': password,
    });
    if (f.cmd != 1) _failWith(f, '2FA');
    // Токен входа — tokenAttrs.LOGIN.token (case 115 транспорта). Сырой
    // парсер оставлен запасным.
    final t = _loginToken(f.decoded) ?? RawParsers.findLongToken(f.body);
    if (t == null) throw const MaxLoginFailed('auth token missing after 2FA');
    return t;
  }

  /// Пометить сессию вошедшей БЕЗ отправки LOGIN (op 19).
  ///
  /// Интерактивная авторизация (код op 18, 2FA op 115, регистрация op 23)
  /// САМА переводит сессию в ONLINE на сервере и возвращает постоянный токен.
  /// Отправлять op 19 на этом же сокете нельзя — сервер отвечает
  /// `proto.payload` (второй LOGIN на уже авторизованной сессии). op 19 с
  /// сохранённым токеном нужен только на СВЕЖЕМ соединении: переподключение и
  /// восстановление после перезапуска (см. [login]).
  void markLoggedIn(String token) {
    _token = token;
    _sinceLogin
      ..reset()
      ..start();
    _startKeepalive();
    _reconnect.rearm();
    _log.i('${MvTag.auth} сессия ONLINE (LOGIN не отправляем — уже авторизованы)');
  }


  /// Логин по сохранённому токену. Возвращает raw payload, оттуда вызывающий
  /// код может вытащить контакты/чаты при синхронизации.
  final _syncedChats = StreamController<List<dynamic>>.broadcast();

  /// Чаты из ответа LOGIN (op 19) вместе с их lastMessage. Нужны, чтобы
  /// восстановить входящие сообщения/медиа, если живой push (op 128) был
  /// пропущен на обрыве: на каждом reconnect LOGIN отдаёт свежий lastMessage.
  Stream<List<dynamic>> get syncedChatsStream => _syncedChats.stream;

  List<dynamic>? _lastSyncedChats;

  /// Последний снапшот списка чатов из ответа LOGIN (op 19). Нужен тем,
  /// кто подписался на [syncedChatsStream] уже после входа.
  List<dynamic>? get lastSyncedChats => _lastSyncedChats;

  Future<Uint8List> login(String token) async {
    // Структура payload: token + userAgent + interactive + presenceSync=-1 +
    // вложенный exp{}. userAgent ОБЯЗАТЕЛЕН — без него сервер отвечает
    // `proto.payload: userAgent required` (видно в диагностике), из-за чего
    // сессия не становилась ONLINE: op 48/83 падали «Must be ONLINE», сокет
    // рвался (мигание), а восстановление после перезапуска выкидывало на
    // экран входа. Тот же userAgent, что в INIT (op 6).
    final userAgent = await _resolveUserAgent();
    final f = await _request(MaxOp.login, {
      'token': token,
      'userAgent': userAgent,
      'interactive': false,
      'presenceSync': -1,
      'exp': <String, Object?>{},
    });
    if (f.cmd != 1) {
      final r = _rejection(f);
      _log.w(
        '${MvTag.auth} LOGIN отклонён: cmd=${f.cmd} error=${r.code ?? '-'} '
        'message=${r.message ?? '-'}',
      );
      final code = r.code ?? '';
      // Сессия УЖЕ онлайн: интерактивный вход (op 18/115) сам её поднял, и
      // повторный LOGIN на той же сессии сервер отвечает proto.state. Это не
      // ошибка — токен валиден, соединение живо. Проваливаемся в успешную
      // ветку ниже, чтобы включить keepalive и снять отмену reconnect.
      final alreadyOnline = code == 'proto.state' || code.contains('ONLINE');
      if (!alreadyOnline) {
        // Токен мёртв ТОЛЬКО при явных «token»-кодах — тогда разлогин.
        // Всё остальное (временные сбои) транзиентно: бросаем обычную ошибку,
        // чтобы reconnect повторил, а не выкидывал из аккаунта.
        final tokenDead = code.contains('login.token') ||
            code.contains('login.cred') ||
            code.contains('FAIL_LOGIN_TOKEN') ||
            code == 'token.invalid' ||
            code == 'auth.token.invalid';
        if (tokenDead) {
          throw MaxTokenRejected(r.localized ?? 'Сессия истекла: $code');
        }
        throw MaxError('LOGIN cmd=${f.cmd} ${r.code ?? ''}'.trim());
      }
      _log.i('${MvTag.auth} LOGIN: сессия уже онлайн — принимаю как успех');
    }
    _token = token;
    _sinceLogin
      ..reset()
      ..start();
    _startKeepalive();
    // Снимаем «навсегда»-отмену reconnect, которую мог поставить мёртвый токен
    // (MaxLoginFailed) ранее: после успешного LOGIN авто-реконнект снова нужен.
    _reconnect.rearm();
    final dec = f.decoded;
    if (dec is Map) {
      final chats = dec['chats'];
      if (chats is List && chats.isNotEmpty) {
        // Кэшируем снапшот: подписчик (список чатов) может быть построен
        // ПОСЛЕ логина и иначе пропустил бы единственную выдачу.
        _lastSyncedChats = chats;
        _log.i('${MvTag.chat} синк чатов из LOGIN: ${chats.length}');
        if (_syncedChats.hasListener) _syncedChats.add(chats);
      }
    }
    return f.body;
  }

  // ───────────────────────── keepalive ────────────────────────

  void _startKeepalive() {
    _keepalive?.cancel();
    // Первый PING сразу: сервер ждёт heartbeat вскоре после входа и рвёт
    // сокет, не дождавшись, — отсюда было «мигание» связи после входа.
    unawaited(_ping());
    _keepalive = Timer.periodic(_pingInterval, (_) => unawaited(_ping()));
  }

  void _stopKeepalive() {
    _keepalive?.cancel();
    _keepalive = null;
  }

  /// Heartbeat официальным опкодом PING (op 1). Именно его ждёт сервер,
  /// чтобы не рвать сокет (frk.java: heartbeat(15)). Тело пустое.
  Future<void> _ping() async {
    if (_socket == null || _closed) return;
    try {
      await _request(
        MaxOp.ping,
        const <String, Object?>{},
        timeout: const Duration(seconds: 10),
      );
    } catch (e) {
      // Реальный дроп/таймаут обработают onError/onDone → reconnect.
      _log.d('${MvTag.socket} PING failed: $e');
    }
  }

  // ───────────────────────── messaging ────────────────────────

  /// Отправка сообщения (op 64). Сервер принимает ЛИБО [chatId] (существующий
  /// чат/группа/канал), ЛИБО [peerUserId] (новый диалог 1:1) — ровно один.
  /// [cid] — клиентский id ВНУТРИ message (findings: lzc.java); по нему дедупим
  /// эхо-push. Раньше форк клал peer userId в chatId → user.not.found.
  Future<Map<String, dynamic>> sendMessage({
    int? chatId,
    int? peerUserId,
    required String text,
    List<Map<String, Object?>>? attaches,
    int? replyToId,
    int? cid,
  }) async {
    assert(
      (chatId != null && chatId != 0) ||
          (peerUserId != null && peerUserId != 0),
      'sendMessage requires chatId or peerUserId',
    );
    final hasAttaches = attaches != null && attaches.isNotEmpty;
    final message = <String, Object?>{
      'cid': cid ?? DateTime.now().microsecondsSinceEpoch,
      'text': text,
    };
    // detectShare (превью ссылок) — только для чисто текстовых. Для media с
    // attaches поле не подтверждено findings — сохраняем доказанный payload.
    if (hasAttaches) {
      message['attaches'] = attaches;
    } else {
      message['detectShare'] = false;
    }
    if (replyToId != null) {
      // ключ reply не подтверждён в декомпиле — сервер либо примет, либо нет.
      message['replyTo'] = replyToId;
    }
    final payload = <String, Object?>{
      'message': message,
      'notify': true,
    };
    if (chatId != null && chatId != 0) {
      payload['chatId'] = chatId;
    } else {
      payload['userId'] = peerUserId;
    }
    final f = await _request(MaxOp.sendMessage, payload);
    if (f.cmd != 1) {
      if (f.cmd == 3) {
        String? reason;
        final d = f.decoded;
        if (d is Map) {
          final m = d.map((k, v) => MapEntry(k.toString(), v));
          reason = m['error']?.toString() ?? m['message']?.toString();
        }
        throw MaxRejected('send_message rejected', f.cmd, reason: reason);
      }
      throw MaxError('send_message cmd=${f.cmd}');
    }
    return _asMap(f.decoded);
  }

  Future<void> typing(int chatId, {bool isTyping = true}) async {
    await _request(MaxOp.typing, {
      'chatId': chatId,
      'typing': isTyping,
    });
  }

  /// Редактирование уже отправленного сообщения (opcode 67).
  Future<Map<String, dynamic>> editMessage(
    int chatId,
    int messageId,
    String text, {
    List<Map<String, Object?>>? attaches,
  }) async {
    final payload = <String, Object?>{
      'chatId': chatId,
      'messageId': messageId,
      'text': text,
    };
    if (attaches != null) payload['attachments'] = attaches;
    final f = await _request(MaxOp.editMessage, payload);
    if (f.cmd != 1) throw MaxError('editMessage cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  // ───────────────────────── media ────────────────────────────

  /// Запрос upload-URL для фото. Возвращает декодированный ответ — клиент
  /// должен взять оттуда `url` (HTTP POST endpoint) и `photoToken`.
  /// Поле profile=true используется для аватарок.
  /// Обновление профиля (op 16). Поля сверены с APK (o8b.java): firstName,
  /// lastName, description, link, photoToken (+avatarType при смене аватара).
  /// Пустая строка в description/link удаляет значение. Возвращает
  /// обновлённый профиль.
  Future<Map<String, dynamic>> updateProfile({
    String? firstName,
    String? lastName,
    String? description,
    String? link,
    String? photoToken,
  }) async {
    final payload = <String, Object?>{};
    if (firstName != null) payload['firstName'] = firstName;
    if (lastName != null) payload['lastName'] = lastName;
    if (description != null) payload['description'] = description;
    if (link != null) payload['link'] = link;
    if (photoToken != null) {
      payload['photoToken'] = photoToken;
      payload['avatarType'] = 'USER_AVATAR';
    }
    final f = await _request(MaxOp.profile, payload);
    if (f.cmd != 1) _failWith(f, 'PROFILE_UPDATE');
    return _asMap(f.decoded);
  }

  /// Задать срок авто-удаления профиля по неактивности (op 200).
  /// [ttl] ∈ {'1M','3M','6M'} — как в официальном клиенте
  /// (ключ app.privacy.inactive.ttl). Ответ пишется в лог диагностики —
  /// точная схема op 200 не проверена вживую, при расхождении поправим.
  Future<Map<String, dynamic>> setInactiveDeleteTtl(String ttl) async {
    final f = await _request(MaxOp.profileDeleteTime, {
      'settings': {'app.privacy.inactive.ttl': ttl},
    });
    _log.i('${MvTag.auth} inactive.ttl=$ttl → cmd=${f.cmd} '
        'decoded=${_redact(f.decoded)}');
    if (f.cmd != 1) _failWith(f, 'PROFILE_DELETE_TIME');
    return _asMap(f.decoded);
  }

  /// Записать пользовательские настройки приватности (op 22 CONFIG).
  /// [settings] — карта ключ→значение (app.privacy.*: ALL|CONTACTS|NOBODY).
  /// Возвращает обновлённый config сервера.
  Future<Map<String, dynamic>> setUserSettings(
      Map<String, Object?> settings) async {
    final f = await _request(MaxOp.config, {
      'settings': {'user': settings},
    });
    _log.i('${MvTag.auth} CONFIG set → cmd=${f.cmd} '
        'decoded=${_redact(f.decoded)}');
    if (f.cmd != 1) _failWith(f, 'CONFIG');
    return _asMap(f.decoded);
  }

  Future<Map<String, dynamic>> requestPhotoUpload({
    int count = 1,
    bool profile = false,
  }) async {
    final f = await _request(MaxOp.photoUpload, {
      'count': count,
      'profile': profile,
    });
    if (f.cmd != 1) throw MaxError('photoUpload cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Запрос параметров видео-аплоада.
  /// `uploaderType` ∈ {VIDEO, VIDEO_MSG, AUDIO} согласно декомпилу.
  Future<Map<String, dynamic>> requestVideoUpload({
    String type = 'VIDEO',
    int count = 1,
    String uploaderType = 'VIDEO',
  }) async {
    final f = await _request(MaxOp.videoUpload, {
      'type': type,
      'count': count,
      'uploaderType': uploaderType,
    });
    if (f.cmd != 1) throw MaxError('videoUpload cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Универсальный аплоад файла (87). Поля payload не подтверждены в
  /// декомпиле полностью — отправляем минимум.
  Future<Map<String, dynamic>> requestFileUpload({int count = 1}) async {
    final f = await _request(MaxOp.fileUpload, {'count': count});
    if (f.cmd != 1) throw MaxError('fileUpload cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Список активных сессий/устройств аккаунта (op 96 SESSIONS_INFO).
  /// Формат ответа уточняется по живому логу (парсер в декомпиле generic).
  Future<Map<String, dynamic>> sessionsInfo() async {
    final f = await _request(MaxOp.sessionsInfo, const <String, Object?>{});
    if (f.cmd != 1) throw MaxError('sessionsInfo cmd=${f.cmd}');
    final m = _asMap(f.decoded);
    _log.i('${MvTag.socket} sessionsInfo ключи=${m.keys.toList()}');
    return m;
  }

  /// Завершить сессии (op 97 SESSIONS_CLOSE). [sessionId] — закрыть одну
  /// конкретную; [exceptCurrent]=true — закрыть все, кроме текущей.
  Future<Map<String, dynamic>> closeSessions({
    int? sessionId,
    bool exceptCurrent = false,
  }) async {
    final payload = <String, Object?>{};
    if (sessionId != null) payload['sessionId'] = sessionId;
    if (exceptCurrent) payload['exceptCurrent'] = true;
    final f = await _request(MaxOp.sessionsClose, payload);
    if (f.cmd != 1) throw MaxError('sessionsClose cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Получить URL воспроизведения видео (opcode 83).
  Future<Map<String, dynamic>> requestVideoPlay({
    required int videoId,
    int? chatId,
    int? messageId,
    String? token,
  }) async {
    final payload = <String, Object?>{'videoId': videoId};
    if (chatId != null) payload['chatId'] = chatId;
    if (messageId != null) payload['messageId'] = messageId;
    if (token != null) payload['token'] = token;
    final f = await _request(MaxOp.videoPlay, payload);
    if (f.cmd != 1) throw MaxError('videoPlay cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Получить download URL для файла (opcode 88).
  Future<Map<String, dynamic>> requestFileDownload({
    required int fileId,
    required int chatId,
    required int messageId,
  }) async {
    final f = await _request(MaxOp.fileDownload, {
      'fileId': fileId,
      'chatId': chatId,
      'messageId': messageId,
    });
    if (f.cmd != 1) throw MaxError('fileDownload cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Список медиа конкретного чата (opcode 51). Используется для галереи.
  Future<Map<String, dynamic>> chatMedia({
    required int chatId,
    int? messageId,
    List<String> attachTypes = const ['PHOTO', 'VIDEO'],
    int forward = 50,
    int backward = 0,
  }) async {
    final payload = <String, Object?>{
      'chatId': chatId,
      'attachTypes': attachTypes,
      'forward': forward,
      'backward': backward,
    };
    if (messageId != null) payload['messageId'] = messageId;
    final f = await _request(MaxOp.chatMedia, payload);
    if (f.cmd != 1) throw MaxError('chatMedia cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  /// Запрос транскрипции голосового/видео-сообщения (opcode 202).
  Future<Map<String, dynamic>> transcribeMedia({
    required int mediaId,
    required int chatId,
    required int messageId,
  }) async {
    final f = await _request(MaxOp.transcribeMedia, {
      'mediaId': mediaId,
      'chatId': chatId,
      'messageId': messageId,
    });
    if (f.cmd != 1) throw MaxError('transcribeMedia cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  Future<Map<String, dynamic>> findContactByPhone(String phone) async {
    final f = await _request(MaxOp.contactByPhone, {'phone': phone});
    if (f.cmd != 1) throw MaxError('contactByPhone cmd=${f.cmd}');
    return _parseContact(f);
  }

  Future<Map<String, dynamic>> contactInfo(List<int> ids) async {
    final f = await _request(MaxOp.contactInfo, {'contactIds': ids});
    if (f.cmd != 1) throw MaxError('contactInfo cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  Future<Map<String, dynamic>> chatInfo(List<int> ids) async {
    final f = await _request(MaxOp.chatInfo, {'chatIds': ids});
    if (f.cmd != 1) throw MaxError('chatInfo cmd=${f.cmd}');
    return _asMap(f.decoded);
  }

  Future<List<Map<String, dynamic>>> chatHistory(
    int chatId, {
    int fromId = 0,
    int count = 50,
  }) async {
    final f = await _request(MaxOp.chatHistory, {
      'chatId': chatId,
      'from': fromId,
      'forward': count,
    });
    if (f.cmd != 1) throw MaxError('chatHistory cmd=${f.cmd}');
    final m = _asMap(f.decoded);
    final msgs = m['messages'];
    if (msgs is List) {
      return msgs.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    }
    return _parseMessagesRaw(f.body);
  }

  Future<Map<String, dynamic>> currentProfile() async {
    final f = await _request(MaxOp.profile, {});
    if (f.cmd != 1) throw MaxError('profile cmd=${f.cmd}');
    final m = _asMap(f.decoded);
    if (m.isNotEmpty) return m;
    return {
      'id': RawParsers.readIntAfterKey(
        f.body,
        Uint8List.fromList([0xA2, ...'id'.codeUnits]),
      ),
      'name': RawParsers.readStrAfterKey(
        f.body,
        Uint8List.fromList([0xA4, ...'name'.codeUnits]),
      ),
    };
  }

  // ───────────────────────── internals ────────────────────────

  /// Очередь записи в сокет: последовательный await-цепочкой, чтобы add()+
  /// flush() разных запросов не пересекались.
  Future<void> _writeChain = Future<void>.value();

  Future<void> _enqueueWrite(Future<void> Function() write) {
    final next = _writeChain.then((_) => write());
    // Проглатываем ошибку в хвосте цепочки, чтобы один сбой записи не рушил
    // все последующие; сама ошибка вернётся вызывающему через await next.
    _writeChain = next.catchError((_) {});
    return next;
  }

  Future<MaxFrame> _request(
    int opcode,
    Map<String, Object?> payload, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final s = _socket;
    if (s == null || _closed) throw const MaxNotConnected('socket is null');

    final seq = _seq;
    _seq = (_seq + 1) & 0xFFFF;
    final completer = Completer<MaxFrame>();
    _pending[seq] = completer;

    final frame = MaxCodec.frame(seq: seq, opcode: opcode, payload: payload);
    // Маскируем чувствительные поля в логе.
    _log.i(
      '${MvTag.socket} REQ op=$opcode seq=$seq payload=${_redact(payload)}',
    );
    // Запись в сокет СЕРИАЛИЗУЕМ: одновременные _request (ping/профиль/чаты
    // после входа) вызывали add()+flush() параллельно → «Bad state:
    // StreamSink is bound to a stream». Цепочка гарантирует по одной записи.
    await _enqueueWrite(() async {
      s.add(frame);
      await s.flush();
    });
    final f = await completer.future.timeout(
      timeout,
      onTimeout: () {
        _pending.remove(seq);
        throw const MaxTimeout('request timeout');
      },
    );
    _log.i(
      '${MvTag.socket} RESP op=$opcode seq=$seq cmd=${f.cmd} len=${f.body.length} '
      'decoded=${_redact(f.decoded)}',
    );
    return f;
  }

  static String _redact(Object? v) {
    if (v is Map) {
      return v.map((k, v2) {
        final ks = k.toString();
        if (ks == 'token' ||
            ks == 'password' ||
            ks == 'trackId' ||
            ks == 'photoToken' ||
            ks == 'url' ||
            ks == 'baseUrl' ||
            ks == 'photoUrl' ||
            ks == 'previewData' ||
            ks == 'thumbhashData') {
          return MapEntry(ks, '<redacted>');
        }
        return MapEntry(ks, _redact(v2));
      }).toString();
    }
    if (v is List) return '[${v.map(_redact).join(', ')}]';
    final s = v?.toString() ?? 'null';
    return s.length > 200 ? '${s.substring(0, 200)}...(${s.length})' : s;
  }

  /// Распаковка тела кадра по флагу cof. LZ4 — чистый Dart. zstd (cof=0xFF)
  /// без нативной библиотеки не распакуем — логируем и отдаём сырое
  /// (такие кадры редки; основной трафик — LZ4 cof>0).
  Uint8List _decompressBody(int cof, int payloadLen, Uint8List body) {
    if (cof == 0 || body.isEmpty) return body;
    if (cof == 0xFF) {
      _log.w('${MvTag.socket} zstd-кадр (cof=0xFF) не распакован — нет нативного zstd');
      return body;
    }
    try {
      return Lz4Block.decompress(body, payloadLen * cof);
    } catch (e) {
      _log.w('${MvTag.socket} LZ4 decompress failed (cof=$cof len=$payloadLen): $e');
      return body;
    }
  }

  void _onData(Uint8List chunk) {
    _bufferBuilder.add(chunk);
    while (true) {
      final buf = _bufferBuilder.toBytes();
      if (buf.length < 10) {
        _bufferBuilder
          ..clear()
          ..add(buf);
        return;
      }
      final cmd = buf[1];
      final seq = (buf[2] << 8) | buf[3];
      final opcode = (buf[4] << 8) | buf[5];
      final lenRaw =
          (buf[6] << 24) | (buf[7] << 16) | (buf[8] << 8) | buf[9];
      // Старший байт длины = флаг сжатия (cof): 0 нет, 0xFF zstd, >0 LZ4
      // (размер распаковки = payloadLen * cof). Источник: e1d.java/lp.java.
      final cof = (lenRaw >> 24) & 0xFF;
      final payloadLen = lenRaw & 0x00FFFFFF;
      final total = 10 + payloadLen;
      if (buf.length < total) {
        _bufferBuilder
          ..clear()
          ..add(buf);
        return;
      }

      final rawBody = Uint8List.sublistView(buf, 10, total);
      final body = _decompressBody(cof, payloadLen, rawBody);
      final decoded = MaxCodec.tryUnpack(body);
      final frame = MaxFrame(
        cmd: cmd,
        seq: seq,
        opcode: opcode,
        body: body,
        decoded: decoded,
      );

      // переложить остаток обратно в builder
      _bufferBuilder.clear();
      if (buf.length > total) {
        _bufferBuilder.add(Uint8List.sublistView(buf, total));
      }

      final waiter = _pending.remove(seq);
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete(frame);
        continue;
      }

      // Диагностика приёма: логируем КАЖДЫЙ серверный push-кадр (несматченный
      // по seq), чтобы видеть, доставляет ли сервер входящие по сокету.
      _log.i(
        '${MvTag.message} PUSH cmd=${frame.cmd} op=${frame.opcode} len=${frame.body.length} '
        'decoded=${_redact(frame.decoded)}',
      );
      onPushDebug?.call(frame);
      final msg = _parsePush(frame);
      if (msg != null && !_pushCtrl.isClosed) {
        _pushCtrl.add(msg);
      }
    }
  }

  void _onError(Object e, StackTrace st) {
    _log.w('${MvTag.socket} socket error: $e');
    _failAllPending(MaxNotConnected('socket error: $e'));
    _handleDrop();
  }

  void _onDone() {
    _log.w('${MvTag.socket} socket closed by server');
    _failAllPending(const MaxNotConnected('socket closed'));
    _handleDrop();
  }

  void _handleDrop() {
    _stopKeepalive();
    // Уже синхронно убираем подписку и сокет — без флага «навсегда».
    unawaited(_sub?.cancel() ?? Future<void>.value());
    _sub = null;
    try {
      _socket?.destroy();
    } catch (_) {}
    _socket = null;
    if (_closed) {
      _emitState(MaxConnectionState.disconnected);
      return;
    }
    _emitState(MaxConnectionState.reconnecting);
    _reconnect.start();
  }

  void _failAllPending(Object error) {
    for (final c in _pending.values) {
      if (!c.isCompleted) c.completeError(error);
    }
    _pending.clear();
  }

  Map<String, dynamic> _asMap(Object? d) {
    if (d is Map) {
      return d.map(
        (k, v) => MapEntry(k.toString(), v),
      );
    }
    return const {};
  }

  IncomingMessage? _parsePush(MaxFrame f) {
    int? chatId;
    String? text;
    int? sender;
    int? msgId;
    int? timeMs;
    var attaches = const <Map<String, dynamic>>[];
    int? cid;

    final d = f.decoded;
    if (d is Map) {
      final dm = d.map((k, v) => MapEntry(k.toString(), v));
      chatId = _toInt(dm['chatId']);
      final m = dm['message'];
      if (m is Map) {
        final mm = m.map((k, v) => MapEntry(k.toString(), v));
        text = mm['text']?.toString();
        sender = _toInt(mm['sender']);
        msgId = _toInt(mm['id']);
        timeMs = _toInt(mm['time']);
        cid = _toInt(mm['cid']);
        final at = mm['attaches'] ?? mm['attachments'];
        if (at is List) {
          attaches = at
              .whereType<Map>()
              .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
              .toList(growable: false);
        }
      } else {
        text = dm['text']?.toString();
        sender = _toInt(dm['sender']);
        msgId = _toInt(dm['id']);
        timeMs = _toInt(dm['time']);
        cid = _toInt(dm['cid']);
      }
    }

    chatId ??= RawParsers.readIntAfterKey(
      f.body,
      Uint8List.fromList([0xA6, ...'chatId'.codeUnits]),
    );
    text ??= RawParsers.readStrAfterKey(
      f.body,
      Uint8List.fromList([0xA4, ...'text'.codeUnits]),
    );
    sender ??= RawParsers.readIntAfterKey(
      f.body,
      Uint8List.fromList([0xA6, ...'sender'.codeUnits]),
    );
    msgId ??= RawParsers.readIntAfterKey(
      f.body,
      Uint8List.fromList([0xA2, ...'id'.codeUnits]),
    );
    timeMs ??= RawParsers.readIntAfterKey(
      f.body,
      Uint8List.fromList([0xA4, ...'time'.codeUnits]),
    );

    // Сообщение без текста, но с attach'ем — валидно.
    if (chatId == null) return null;
    final hasContent = (text != null && text.isNotEmpty) || attaches.isNotEmpty;
    if (!hasContent) return null;
    return IncomingMessage(
      chatId: chatId,
      messageId: msgId,
      sender: sender,
      text: text ?? '',
      timeMs: timeMs,
      raw: f.body,
      attaches: attaches,
      cid: cid,
    );
  }

  Map<String, dynamic> _parseContact(MaxFrame f) {
    final d = f.decoded;
    if (d is Map) {
      final dm = d.map((k, v) => MapEntry(k.toString(), v));
      for (final key in ('contact contacts user'.split(' '))) {
        var v = dm[key];
        if (v is List && v.isNotEmpty) v = v.first;
        if (v is Map) {
          final mm = v.map((k, v) => MapEntry(k.toString(), v));
          return {
            'id': _toInt(mm['id']),
            'name': displayContactName(mm),
            'phone': mm['phone']?.toString(),
          };
        }
      }
    }
    return {
      'id': RawParsers.readIntAfterKey(
        f.body,
        Uint8List.fromList([0xA2, ...'id'.codeUnits]),
      ),
      'name': RawParsers.readStrAfterKey(
        f.body,
        Uint8List.fromList([0xA4, ...'name'.codeUnits]),
      ),
      'phone': RawParsers.readIntAfterKey(
        f.body,
        Uint8List.fromList([0xA5, ...'phone'.codeUnits]),
      )?.toString(),
    };
  }

  List<Map<String, dynamic>> _parseMessagesRaw(Uint8List raw) {
    final marker = Uint8List.fromList([0xA8, ...'messages'.codeUnits]);
    final start = RawParsers.indexOf(raw, marker);
    if (start == -1) return [];
    final region = Uint8List.sublistView(raw, start);
    final positions = <int>[];
    // Найти повторяющиеся "id" + (D2|D3) внутри блока messages.
    for (var i = 0; i < region.length - 3; i++) {
      if (region[i] == 0xA2 &&
          region[i + 1] == 'i'.codeUnitAt(0) &&
          region[i + 2] == 'd'.codeUnitAt(0) &&
          (region[i + 3] == 0xD2 || region[i + 3] == 0xD3)) {
        positions.add(i);
      }
    }
    final result = <Map<String, dynamic>>[];
    for (var i = 0; i < positions.length; i++) {
      final p = positions[i];
      final end = i + 1 < positions.length ? positions[i + 1] : region.length;
      final chunk = Uint8List.sublistView(region, p, end);
      result.add({
        'id': RawParsers.readIntAfterKey(
          chunk,
          Uint8List.fromList([0xA2, ...'id'.codeUnits]),
        ),
        'sender': RawParsers.readIntAfterKey(
          chunk,
          Uint8List.fromList([0xA6, ...'sender'.codeUnits]),
        ),
        'text': RawParsers.readStrAfterKey(
          chunk,
          Uint8List.fromList([0xA4, ...'text'.codeUnits]),
        ),
        'time': RawParsers.readIntAfterKey(
          chunk,
          Uint8List.fromList([0xA4, ...'time'.codeUnits]),
        ),
      });
    }
    return result;
  }

  bool _contains(Uint8List data, String s) {
    final needle = Uint8List.fromList(s.codeUnits);
    return RawParsers.indexOf(data, needle) != -1;
  }

  static int? _toInt(Object? v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

/// Менеджер переподключения. Тайминги делегированы в [ReconnectPolicy]
/// (тестируется отдельно). Ключевое отличие от прежней версии: пауза НЕ
/// сбрасывается в 2с на каждый успех, а ограничивается потолком частоты LOGIN —
/// это убирает реконнект-шторм, из-за которого банили номер. Защищён от
/// двойного запуска флагом [_running].
class _ReconnectManager {
  _ReconnectManager(this._client, this._log, [ReconnectPolicy? policy])
    : _policy = policy ?? ReconnectPolicy();

  final MaxClient _client;
  final Logger _log;
  final ReconnectPolicy _policy;

  int _attempt = 0;
  bool _running = false;
  bool _cancelled = false;
  Timer? _timer;

  /// Монотонные часы + времена попыток для предохранителя (флаппинг).
  final Stopwatch _clock = Stopwatch()..start();
  final List<Duration> _attempts = <Duration>[];

  /// Запускает цикл переподключения, если он ещё не запущен.
  void start() {
    if (_running || _cancelled || _client._closed) return;
    _running = true;
    _attempt = 0;
    _schedule();
  }

  /// Останавливает цикл. Вызывается из [MaxClient.close].
  void cancel() {
    _cancelled = true;
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  /// Снять «навсегда»-отмену после успешного LOGIN. Без этого однажды
  /// поставленный мёртвым токеном [_cancelled] навсегда глушил авто-реконнект,
  /// и после повторного входа дроп сети уже не переподключался (socket null,
  /// отправки висли в очереди). Сам цикл не запускаем — следующий дроп вызовет
  /// [start]. _running не трогаем (им владеет активный цикл [_tryReconnect]).
  void rearm() {
    _cancelled = false;
  }

  void _pruneWindow() {
    final cutoff = _clock.elapsed - _policy.breakerWindow;
    _attempts.removeWhere((t) => t < cutoff);
  }

  void _schedule() {
    _timer?.cancel();
    _pruneWindow();
    final delay = _policy.nextDelay(
      attempt: _attempt,
      sinceLastLogin: _client.sinceLastLogin,
      attemptsInWindow: _attempts.length,
    );
    _log.i(
      '${MvTag.socket} reconnect через ${delay.inSeconds}s (попытка $_attempt, '
      'в окне ${_attempts.length}, с LOGIN ${_client.sinceLastLogin.inSeconds}s)',
    );
    _timer = Timer(delay, _tryReconnect);
  }

  Future<void> _tryReconnect() async {
    if (_cancelled || _client._closed) {
      _running = false;
      return;
    }
    try {
      await _client.reconnect();
      // Предохранитель считает только УСПЕШНЫЕ переавторизации (риск бана —
      // частота re-auth, а не неудачные коннекты к недоступному серверу).
      // Иначе на лежащей сети 6 неудач → 8 мин офлайна без причины.
      _attempts.add(_clock.elapsed);
      _log.i('${MvTag.socket} reconnect succeeded');
      _attempt = 0;
      _running = false;
    } catch (e) {
      _log.w('${MvTag.socket} reconnect attempt failed: $e');
      // Разлогиниваем ТОЛЬКО когда сервер явно отверг сам токен
      // (MaxTokenRejected). Прочие сбои LOGIN — транзиентные: их ретраим,
      // иначе один сетевой сбой выкидывает из рабочего аккаунта.
      if (e is MaxTokenRejected) {
        _client._token = null;
        _running = false;
        _cancelled = true;
        _client._emitState(MaxConnectionState.disconnected);
        _client._authInvalid?.call();
        return;
      }
      _attempt++;
      if (!_cancelled && !_client._closed) {
        _schedule();
      } else {
        _running = false;
      }
    }
  }
}
