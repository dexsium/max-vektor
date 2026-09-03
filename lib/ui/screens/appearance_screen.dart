import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/appearance_controller.dart';
import '../../state/theme_controller.dart';
import '../theme/wallpapers.dart';

/// Экран «Оформление»: размер текста, тема (Системная/Светлая/Тёмная),
/// предпросмотр чата и выбор обоев. Повторяет официальное приложение MAX;
/// обои — собственные (см. [kChatWallpapers]).
class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Оформление')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: const [
          _SectionLabel('Размер текста'),
          _TextSizeCard(),
          SizedBox(height: 8),
          _SectionLabel('Тема'),
          _ThemeSegmented(),
          SizedBox(height: 12),
          _ChatPreview(),
          SizedBox(height: 16),
          _WallpaperRow(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TextSizeCard extends ConsumerWidget {
  const _TextSizeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ts = ref.watch(textSizeProvider);
    final ctrl = ref.read(textSizeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return _Card(
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: const Text('Как в системе',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
            value: ts.system,
            onChanged: ctrl.setSystem,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 15)),
                Expanded(
                  child: Slider(
                    value: ts.step.toDouble(),
                    min: 0,
                    max: (TextSizeState.steps.length - 1).toDouble(),
                    divisions: TextSizeState.steps.length - 1,
                    onChanged: ts.system
                        ? null
                        : (v) => ctrl.setStep(v.round()),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 26)),
              ],
            ),
          ),
          if (ts.system)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Размер берётся из настроек устройства',
                style: TextStyle(
                    color: scheme.onSurfaceVariant, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThemeSegmented extends ConsumerWidget {
  const _ThemeSegmented();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final ctrl = ref.read(themeModeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    Widget seg(String label, ThemeMode m) {
      final sel = mode == m;
      return Expanded(
        child: GestureDetector(
          onTap: () => ctrl.set(m),
          child: Container(
            margin: const EdgeInsets.all(3),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: sel ? scheme.surface : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: sel ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            seg('Системная', ThemeMode.system),
            seg('Светлая', ThemeMode.light),
            seg('Тёмная', ThemeMode.dark),
          ],
        ),
      ),
    );
  }
}

/// Предпросмотр чата на выбранных обоях: пара пузырей и реакции.
class _ChatPreview extends ConsumerWidget {
  const _ChatPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wp = wallpaperById(ref.watch(chatWallpaperProvider));
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: WallpaperBackground(
          wallpaper: wp,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bubble(
                  'Выберите тему, чтобы изменить фон и цвет сообщений 🎨',
                  incoming: true,
                  scheme: scheme,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _outgoingBubble(
                          'Посмотрите, как с ней будут выглядеть ваши чаты'),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          _Reaction('❤️', 1),
                          SizedBox(width: 6),
                          _Reaction('🔥', 1),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                _bubble('Меняйте тему в любое время',
                    incoming: true, scheme: scheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bubble(String text,
      {required bool incoming, required ColorScheme scheme}) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }

  Widget _outgoingBubble(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5B6CF0), Color(0xFF9B5BF0)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text, style: const TextStyle(color: Colors.white)),
    );
  }
}

class _Reaction extends StatelessWidget {
  const _Reaction(this.emoji, this.count);
  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text('$count',
              style: const TextStyle(color: Colors.white, fontSize: 13)),
        ],
      ),
    );
  }
}

class _WallpaperRow extends ConsumerWidget {
  const _WallpaperRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(chatWallpaperProvider);
    final ctrl = ref.read(chatWallpaperProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(kChatWallpapers.first.name,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 12),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: kChatWallpapers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final w = kChatWallpapers[i];
              final sel = w.id == selected;
              return GestureDetector(
                onTap: () => ctrl.set(w.id),
                child: Container(
                  width: 96,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? scheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: WallpaperBackground(
                      wallpaper: w,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _miniBubble(Colors.white.withValues(alpha: 0.18)),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: _miniBubble(null),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _miniBubble(Color? solid) {
    return Container(
      width: 56,
      height: 22,
      decoration: BoxDecoration(
        color: solid,
        gradient: solid == null
            ? const LinearGradient(
                colors: [Color(0xFF5B6CF0), Color(0xFF9B5BF0)])
            : null,
        borderRadius: BorderRadius.circular(9),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.6)),
      );
}
