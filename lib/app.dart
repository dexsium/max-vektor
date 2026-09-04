import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'l10n/app_localizations.dart';
import 'state/appearance_controller.dart';
import 'state/locale_controller.dart';
import 'state/theme_controller.dart';
import 'ui/screens/splash_screen.dart';
import 'ui/theme/app_theme.dart';

class MaxVektorApp extends ConsumerWidget {
  const MaxVektorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textSize = ref.watch(textSizeProvider);
    return MaterialApp(
      title: AppMeta.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      // Явно выбранный язык (глобус на экране входа / раздел «Язык»).
      // null — следовать за системным языком устройства.
      locale: ref.watch(localeProvider),
      // Локализация: интерфейс следует за системным языком устройства
      // (как в официальном приложении). Неподдержанный язык → русский.
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        for (final s in supported) {
          if (s.languageCode == locale?.languageCode) return s;
        }
        return const Locale('ru');
      },
      // Масштаб текста: системный или выбранный на экране «Оформление».
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: textScalerFor(textSize, context)),
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
