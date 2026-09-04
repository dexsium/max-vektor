import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/max/models/contact.dart';
import '../../l10n/app_localizations.dart';
import '../../state/contacts_controller.dart';

/// Экран «Чёрный список». Показывает заблокированные контакты и позволяет
/// разблокировать их, а также заблокировать контакт из адресной книги.
/// Блокировка идёт по протоколу MAX (op 34 CONTACT_UPDATE, action=BLOCK).
class BlacklistScreen extends ConsumerWidget {
  const BlacklistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = L.of(context);
    final blocked = ref.watch(blacklistProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(l.secBlacklist)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickAndBlock(context, ref),
        tooltip: l.blAdd,
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: blocked.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState(text: l.blEmpty, hint: l.blDesc);
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length + 1,
            separatorBuilder: (_, i) =>
                i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
            itemBuilder: (context, i) {
              if (i == 0) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Text(
                    l.blDesc,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                );
              }
              final c = list[i - 1];
              return _BlockedTile(
                contact: c,
                onUnblock: () => _unblock(context, ref, c),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _unblock(
      BuildContext context, WidgetRef ref, MaxContact c) async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(blacklistProvider.notifier).unblock(c.id);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
    if (context.mounted) {
      messenger.showSnackBar(SnackBar(content: Text(l.blUnblock)));
    }
  }

  Future<void> _pickAndBlock(BuildContext context, WidgetRef ref) async {
    final chosen = await showModalBottomSheet<MaxContact>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _BlockPickerSheet(),
    );
    if (chosen == null || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(blacklistProvider.notifier).block(chosen);
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('$e')));
    }
  }
}

class _BlockedTile extends StatelessWidget {
  const _BlockedTile({required this.contact, required this.onUnblock});

  final MaxContact contact;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final name = (contact.name?.isNotEmpty ?? false)
        ? contact.name!
        : (contact.phone ?? 'ID ${contact.id}');
    final initial = name.characters.isEmpty
        ? '?'
        : name.characters.first.toUpperCase();
    return ListTile(
      leading: CircleAvatar(child: Text(initial)),
      title: Text(name),
      subtitle: contact.phone != null ? Text(contact.phone!) : null,
      trailing: OutlinedButton(
        onPressed: onUnblock,
        child: Text(L.of(context).blUnblock),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text, required this.hint});

  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block, size: 56, color: scheme.outline),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Лист выбора контакта для блокировки: все локальные контакты, кроме уже
/// заблокированных, с поиском.
class _BlockPickerSheet extends ConsumerStatefulWidget {
  const _BlockPickerSheet();

  @override
  ConsumerState<_BlockPickerSheet> createState() => _BlockPickerSheetState();
}

class _BlockPickerSheetState extends ConsumerState<_BlockPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final contacts = ref.watch(contactsListProvider);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l.blSearch,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              Expanded(
                child: contacts.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text('$e')),
                  data: (all) {
                    final q = _query.toLowerCase();
                    final list = all.where((c) {
                      if (c.blocked) return false;
                      if (q.isEmpty) return true;
                      final n = (c.name ?? '').toLowerCase();
                      final p = (c.phone ?? '').toLowerCase();
                      return n.contains(q) || p.contains(q);
                    }).toList();
                    if (list.isEmpty) {
                      return Center(child: Text(l.blNoContacts));
                    }
                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final c = list[i];
                        final name = (c.name?.isNotEmpty ?? false)
                            ? c.name!
                            : (c.phone ?? 'ID ${c.id}');
                        final initial = name.characters.isEmpty
                            ? '?'
                            : name.characters.first.toUpperCase();
                        return ListTile(
                          leading: CircleAvatar(child: Text(initial)),
                          title: Text(name),
                          subtitle: c.phone != null ? Text(c.phone!) : null,
                          onTap: () => Navigator.of(context).pop(c),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
