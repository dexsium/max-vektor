import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants.dart';
import 'state/appearance_controller.dart';
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
