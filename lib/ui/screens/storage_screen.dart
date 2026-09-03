import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/local/storage_service.dart';
import '../../state/media_prefs_controller.dart';
import '../../state/providers.dart';
import '../widgets/app_snack.dart';

/// Раздел «Память» — срок хранения кэша, размеры по категориям и очистка.
///
/// Работает по-настоящему: считает размер кэша изображений (стикеры/фото)
/// и скачанных аудио на диске и реально их удаляет (см. [StorageService]).
class StorageScreen extends ConsumerStatefulWidget {
  const StorageScreen({super.key});

  @override
  ConsumerState<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends ConsumerState<StorageScreen> {
  StorageUsage? _usage;
  bool _clearing = false;

  String get _accountId => ref.read(activeAccountProvider).id;

  @override
  void initState() {
    super.initState();
    _recalc();
  }

  Future<void> _recalc() async {
    final u = await StorageService.usage(_accountId);
    if (mounted) setState(() => _usage = u);
  }

  Future<void> _clearAll() async {
    final total = _usage?.total ?? 0;
    if (total <= 0) return;
    final ok = await _confirm(
      'Очистить кэш?',
      'Освободится ${StorageService.humanSize(total)}. Медиа можно будет '
          'загрузить снова из чатов.',
    );
    if (ok != true) return;
    setState(() => _clearing = true);
    await StorageService.clearAll(_accountId);
    await _recalc();
    if (mounted) {
      setState(() => _clearing = false);
      AppSnack.show(context, 'Кэш очищен', icon: Icons.check);
    }
  }

  Future<void> _clearCategory(StorageCategory cat, String title) async {
    final ok = await _confirm('Очистить «$title»?', 'Файлы можно загрузить снова.');
    if (ok != true) return;
    await StorageService.clearCategory(cat, _accountId);
    await _recalc();
    if (mounted) AppSnack.show(context, 'Готово', icon: Icons.check);
  }

  Future<bool?> _confirm(String title, String body) => showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Отмена')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Очистить')),
          ],
        ),
      );

  Future<void> _pickKeep() async {
    final current = ref.read(mediaPrefsProvider).cacheKeep;
    final chosen = await showModalBottomSheet<CacheKeep>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Хранить медиа в кэше устройства',
                  style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            for (final k in CacheKeep.values)
              ListTile(
                title: Text(k.label),
                trailing: k == current
                    ? Icon(Icons.check, color: Theme.of(ctx).colorScheme.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(k),
              ),
          ],
        ),
      ),
    );
    if (chosen != null && chosen != current) {
      await ref.read(mediaPrefsProvider.notifier).setCacheKeep(chosen);
      // Сразу применяем новый срок к уже скачанным медиа.
      await StorageService.pruneOlderThan(_accountId, chosen.days);
      await _recalc();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final keep = ref.watch(mediaPrefsProvider).cacheKeep;
    final u = _usage;

    return Scaffold(
      appBar: AppBar(title: const Text('Память')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // «Хранить медиа в кэше устройства».
          _Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Хранить медиа в кэше устройства'),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('После удаления медиа можно загрузить снова'),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(keep.label, style: TextStyle(color: scheme.onSurfaceVariant)),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: scheme.outline),
                ],
              ),
              onTap: _pickKeep,
            ),
          ),
          const _SectionLabel('Данные'),
          _Card(
            child: Column(
              children: [
                _dataRow('Стикеры', u?.stickers,
                    () => _clearCategory(StorageCategory.stickers, 'Стикеры')),
                const _Divider(),
                _dataRow('Фото', u?.photos,
                    () => _clearCategory(StorageCategory.photos, 'Фото')),
                const _Divider(),
                _dataRow('Аудиосообщения', u?.audio,
                    () => _clearCategory(StorageCategory.audio, 'Аудиосообщения')),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                  child: SizedBox(
                    height: 50,
                    child: FilledButton(
                      onPressed: (u == null || u.total <= 0 || _clearing)
                          ? null
                          : _clearAll,
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _clearing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.4))
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('Очистить кэш',
                                    style: TextStyle(
                                        fontSize: 16, fontWeight: FontWeight.w600)),
                                if (u != null && u.total > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: scheme.onPrimary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      StorageService.humanSize(u.total),
                                      style: TextStyle(
                                          color: scheme.primary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataRow(String title, int? bytes, VoidCallback onClear) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          bytes == null
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: scheme.outline))
              : Text(StorageService.humanSize(bytes),
                  style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: scheme.outline),
        ],
      ),
      onTap: (bytes == null || bytes <= 0) ? null : onClear,
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
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
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
