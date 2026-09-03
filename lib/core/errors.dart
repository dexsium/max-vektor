class MaxError implements Exception {
  final String message;
  const MaxError(this.message);
  @override
  String toString() => 'MaxError: $message';
}

class MaxLoginFailed extends MaxError {
  const MaxLoginFailed(super.message);
  @override
  String toString() => 'MaxLoginFailed: $message';
}

/// Сервер отверг сам ТОКЕН входа как недействительный (login.token /
/// login.cred / FAIL_LOGIN_TOKEN). Только это — повод разлогинить и вывести
/// на экран входа. Прочие сбои LOGIN (proto.payload, временная
/// недоступность) — транзиентные: их надо ретраить, а не выкидывать
/// пользователя из рабочего аккаунта.
class MaxTokenRejected extends MaxLoginFailed {
  const MaxTokenRejected(super.message);
  @override
  String toString() => 'MaxTokenRejected: $message';
}

class MaxNotConnected extends MaxError {
  const MaxNotConnected(super.message);
  @override
  String toString() => 'MaxNotConnected: $message';
}

class MaxTimeout extends MaxError {
  const MaxTimeout(super.message);
  @override
  String toString() => 'MaxTimeout: $message';
}

/// Бизнес-отказ сервера (cmd=3). [reason] — код из payload
/// ({error, message, localizedMessage}). Повтор помогает ТОЛЬКО если причина
/// транзиентная; постоянные коды (whitelist) повторять нельзя — иначе вечный
/// долбёж сервера (а это бан-сигнал).
class MaxRejected extends MaxError {
  final int cmd;
  final String? reason;
  const MaxRejected(super.message, this.cmd, {this.reason});

  /// Постоянные отказы: получатель/чат не существует/заблокирован. Только их
  /// дропаем. Всё прочее (throttle, flood-wait, временная недоступность)
  /// считаем транзиентным и повторяем. Незнакомый код ⇒ НЕ permanent ⇒ повтор
  /// (безопаснее потери сообщения).
  bool get isPermanent => const {
    'user.not.found',
    'chat.not.found',
    'recipient.not.found',
    'user.blocked',
    // Ошибка валидации payload (например пустой текст): повтор того же
    // тела не поможет, а сервер на него РВЁТ соединение → бесконечная петля.
    'proto.payload',
  }.contains(reason);

  @override
  String toString() => 'MaxRejected(cmd=$cmd, reason=$reason): $message';
}
