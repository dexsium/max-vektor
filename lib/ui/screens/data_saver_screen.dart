import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/media_prefs_controller.dart';

/// «Экономия батареи и сети» — автозагрузка и автовоспроизведение медиа.
///
/// Секции и опции повторяют официальное приложение MAX (Фото, Видео, Гифки,
/// Аудиосообщения). Настройки клиентские, хранятся локально с теми же
/// ключами, что в оригинале (см. [MediaPrefsController]).
class DataSaverScreen extends ConsumerWidget {
  const DataSaverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(mediaPrefsProvider);
    final ctrl = ref.read(mediaPrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Экономия батареи и сети')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          const _SectionLabel('Фото'),
          _Group(children: [
            _AutoTile(
              title: 'Автозагрузка',
              value: prefs.photoAutoload,
              onPick: ctrl.setPhotoAutoload,
            ),
          ]),
          const _SectionLabel('Видео'),
          _Group(children: [
            _QualityTile(
              title: 'Качество при отправке',
              value: prefs.videoSendQuality,
              onPick: ctrl.setVideoSendQuality,
            ),
            const _Divider(),
            _AutoTile(
              title: 'Автовоспроизведение',
              value: prefs.videoAutoplay,
              onPick: ctrl.setVideoAutoplay,
            ),
          ]),
          const _SectionLabel('Гифки'),
          _Group(children: [
            SwitchListTile(
              title: const Text('Автовоспроизведение'),
              value: prefs.gifAutoplay,
              onChanged: ctrl.setGifAutoplay,
            ),
          ]),
          const _SectionLabel('Аудиосообщения'),
          _Group(children: [
            _AutoTile(
              title: 'Автозагрузка',
              value: prefs.audioAutoload,
              onPick: ctrl.setAudioAutoload,
            ),
          ]),
        ],
      ),
    );
  }
}

/// Плитка выбора режима Всегда/По Wi-Fi/Никогда.
class _AutoTile extends StatelessWidget {
  const _AutoTile({
    required this.title,
    required this.value,
    required this.onPick,
  });

  final String title;
  final MediaAuto value;
  final ValueChanged<MediaAuto> onPick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value.label,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: scheme.outline),
        ],
      ),
      onTap: () async {
        final chosen = await showModalBottomSheet<MediaAuto>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final m in MediaAuto.values)
                  ListTile(
                    title: Text(m.label),
                    trailing: m == value
                        ? Icon(Icons.check,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(m),
                  ),
              ],
            ),
          ),
        );
        if (chosen != null && chosen != value) onPick(chosen);
      },
    );
  }
}

/// Плитка выбора качества отправки видео.
class _QualityTile extends StatelessWidget {
  const _QualityTile({
    required this.title,
    required this.value,
    required this.onPick,
  });

  final String title;
  final String value;
  final ValueChanged<String> onPick;

  static const _options = ['480', '720', '1080'];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${value}p', style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: scheme.outline),
        ],
      ),
      onTap: () async {
        final chosen = await showModalBottomSheet<String>(
          context: context,
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                for (final q in _options)
                  ListTile(
                    title: Text('${q}p'),
                    trailing: q == value
                        ? Icon(Icons.check,
                            color: Theme.of(ctx).colorScheme.primary)
                        : null,
                    onTap: () => Navigator.of(ctx).pop(q),
                  ),
              ],
            ),
          ),
        );
        if (chosen != null && chosen != value) onPick(chosen);
      },
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, indent: 16, endIndent: 12);
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 0.6)),
      );
}
