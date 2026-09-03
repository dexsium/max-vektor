import 'package:flutter/material.dart';

import '../widgets/accounts_section.dart';

/// Отдельный экран переключения аккаунтов — тот же блок, что и в настройках,
/// но доступный одним тапом из шапки списка чатов.
class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Аккаунты')),
      body: ListView(
        children: [
          AccountsSection(onSwitched: () => Navigator.of(context).pop()),
        ],
      ),
    );
  }
}
