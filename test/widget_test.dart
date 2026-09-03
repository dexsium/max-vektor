import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:max_vektor/data/account/account.dart';
import 'package:max_vektor/state/providers.dart';
import 'package:max_vektor/ui/screens/login_screen.dart';

void main() {
  testWidgets('LoginScreen rendered', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Активный аккаунт в приложении подставляет main() из реестра;
          // в тесте даём фиксированный, иначе провайдеры сессии не стартуют.
          accountsBootstrapProvider.overrideWithValue(
            (accounts: const [MvAccount(id: 'acc1')], activeId: 'acc1'),
          ),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    expect(find.text('Вход в MAX'), findsOneWidget);
  });
}
