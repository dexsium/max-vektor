import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/core/constants.dart';
import 'package:max_vektor/data/account/account.dart';
import 'package:max_vektor/state/providers.dart';
import 'package:max_vektor/ui/widgets/code_input.dart';
import 'package:max_vektor/ui/widgets/vektor_mark.dart';
import 'package:max_vektor/ui/screens/login_screen.dart';

Widget _app(Widget child) {
  return ProviderScope(
    overrides: [
      // Активный аккаунт в приложении подставляет main() из реестра;
      // в тесте даём фиксированный, иначе провайдеры сессии не стартуют.
      accountsBootstrapProvider.overrideWithValue(
        (accounts: const [MvAccount(id: 'acc1')], activeId: 'acc1'),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('экран входа: первый шаг — ввод номера', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));

    expect(find.text(AppMeta.name), findsOneWidget);
    expect(find.byType(VektorMark), findsOneWidget);
    expect(find.text('Номер телефона'), findsOneWidget);
    expect(find.text('Получить код'), findsOneWidget);
  });

  testWidgets('экран входа: есть переход на вход по токену', (tester) async {
    await tester.pumpWidget(_app(const LoginScreen()));

    await tester.tap(find.text('У меня есть auth-token'));
    await tester.pumpAndSettle();

    expect(find.text('Вход по токену'), findsOneWidget);
    expect(find.text('Войти по токену'), findsOneWidget);
  });

  group('CodeInput', () {
    testWidgets('рисует по ячейке на каждую цифру кода', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _app(
          Scaffold(body: CodeInput(controller: controller, length: 6)),
        ),
      );

      expect(find.byType(Container), findsWidgets);
      controller.text = '1234';
      await tester.pump();
      expect(find.text('1'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('сообщает о наборе последней цифры', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      String? completed;

      await tester.pumpWidget(
        _app(
          Scaffold(
            body: CodeInput(
              controller: controller,
              length: 4,
              onCompleted: (code) => completed = code,
            ),
          ),
        ),
      );

      controller.text = '123';
      await tester.pump();
      expect(completed, isNull);

      controller.text = '1234';
      await tester.pump();
      expect(completed, '1234');
    });
  });
}
