import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import 'calls_list_screen.dart';
import 'chats_list_screen.dart';
import 'contacts_screen.dart';
import 'settings_screen.dart';

/// Корневой экран после входа. Нижнее меню как в официальном приложении:
/// Контакты, Звонки, Чаты, Настройки. По умолчанию открыты Чаты.
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Порядок вкладок: 0 Контакты, 1 Звонки, 2 Чаты, 3 Настройки.
  int _index = 2;

  static const _pages = <Widget>[
    ContactsScreen(),
    CallsListScreen(),
    ChatsListScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.people_outline),
            selectedIcon: const Icon(Icons.people),
            label: l.navContacts,
          ),
          NavigationDestination(
            icon: const Icon(Icons.call_outlined),
            selectedIcon: const Icon(Icons.call),
            label: l.navCalls,
          ),
          NavigationDestination(
            icon: const Icon(Icons.chat_bubble_outline),
            selectedIcon: const Icon(Icons.chat_bubble),
            label: l.navChats,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings),
            label: l.navSettings,
          ),
        ],
      ),
    );
  }
}
