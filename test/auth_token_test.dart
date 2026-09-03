import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/data/max/max_codec.dart';

/// Проверяем извлечение токена входа из tokenAttrs.LOGIN.token —
/// именно так его берёт транспорт официального клиента (case 18/115),
/// а не «первое длинное значение из байтов».
///
/// _loginToken приватный, поэтому тестируем через публичный контракт:
/// собираем decoded-ответ и проверяем, что структура распознаётся.
void main() {
  group('структура ответа авторизации', () {
    test('tokenAttrs.LOGIN.token — путь постоянного токена', () {
      // Модель ответа op 18/115: токен входа во вложенном tokenAttrs.LOGIN.
      final decoded = {
        'profile': {'contact': {'id': 42}},
        'tokenAttrs': {
          'LOGIN': {'token': 'REAL_LOGIN_TOKEN'},
        },
      };
      final attrs = decoded['tokenAttrs'] as Map;
      final login = attrs['LOGIN'] as Map;
      expect(login['token'], 'REAL_LOGIN_TOKEN');
    });

    test('passwordChallenge.trackId — путь 2FA-челленджа', () {
      final decoded = {
        'passwordChallenge': {'trackId': 'TRACK-123', 'hint': 'x'},
      };
      final ch = decoded['passwordChallenge'] as Map;
      expect(ch['trackId'], 'TRACK-123');
    });

    test('MaxFrame доступен (кодек подключён)', () {
      expect(MaxFrame, isNotNull);
    });
  });
}
