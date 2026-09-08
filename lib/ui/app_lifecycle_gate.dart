import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/account/account_runtime.dart';
import '../state/providers.dart';

/// Слушает жизненный цикл приложения и проверяет соединение при возврате
/// из фона.
///
/// У клиента нет `UIBackgroundModes` — на iOS, пока приложение свёрнуто,
/// Dart-таймеры (в т.ч. 15-секундный keepalive PING в [MaxClient])
/// приостанавливаются на неопределённое время. TCP-соединение при этом может
/// незаметно умереть: если сервер (или промежуточный NAT/файрвол) не пришлёт
/// явный TCP RST/FIN, `onError`/`onDone` сокета не сработают вообще — клиент
/// продолжит считать себя подключённым («зомби»-сокет), а любой запрос будет
/// молча таймаутить. Раньше это ничем не лечилось: подключение просто висело,
/// пока пользователь сам не перезапустит приложение — что и виделось как
/// «выкидывает из аккаунта» без видимой причины в диагностике.
///
/// Один явный PING при возврате в приложение ([MaxClient.probeAfterResume])
/// либо подтверждает, что соединение живо, либо запускает штатный
/// (троттленный — см. ReconnectPolicy) reconnect, вместо того чтобы ждать
/// событий, которые могут никогда не прийти.
class AppLifecycleGate extends ConsumerStatefulWidget {
  const AppLifecycleGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLifecycleGate> createState() => _AppLifecycleGateState();
}

class _AppLifecycleGateState extends ConsumerState<AppLifecycleGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final accountId = ref.read(activeAccountIdProvider);
    // Соединение аккаунта ещё не поднято (экран входа/первый запуск) —
    // проверять нечего, живого сокета нет.
    if (!AccountRuntimes.isOpen(accountId)) return;
    final client = ref.read(accountRuntimeProvider).client;
    if (!client.isConnected) return;
    unawaited(client.probeAfterResume());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
