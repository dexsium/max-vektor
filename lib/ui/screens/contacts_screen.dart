import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/max/models/contact.dart';
import '../../l10n/app_localizations.dart';
import '../../data/repositories/contacts_repository.dart';
import '../../state/chats_controller.dart';
import '../../state/contacts_controller.dart';
import '../../state/providers.dart';
import 'chat_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(contactsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(L.of(context).navContacts),
        actions: [
          IconButton(
            tooltip: _showSearch ? L.of(context).contactsHideSearch : L.of(context).commonSearch,
            onPressed: _toggleSearch,
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
          ),
          IconButton(
            tooltip: L.of(context).contactsImport,
            onPressed: _runImport,
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: L.of(context).contactsAddByNumber,
            onPressed: _showAddDialog,
            icon: const Icon(Icons.person_add_alt),
          ),
        ],
        bottom: _showSearch
            ? PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: L.of(context).commonSearch,
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchCtrl.text.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref
                                    .read(contactsListProvider.notifier)
                                    .search('');
                                ref
                                    .read(contactsSearchQueryProvider.notifier)
                                    .state = '';
                                setState(() {});
                              },
                            ),
                    ),
                    onChanged: (v) {
                      ref.read(contactsListProvider.notifier).search(v);
                      ref.read(contactsSearchQueryProvider.notifier).state = v;
                      setState(() {});
                    },
                  ),
                ),
              )
            : null,
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(L.of(context).commonError('$e'))),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyState(
              onAdd: _showAddDialog,
              onImport: _runImport,
              isSearch: _searchCtrl.text.isNotEmpty,
            );
          }
          return _GroupedContactsList(
            items: items,
            onTap: _openChat,
            onDelete: _confirmDelete,
          );
        },
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        ref.read(contactsListProvider.notifier).search('');
        ref.read(contactsSearchQueryProvider.notifier).state = '';
      }
    });
  }

  void _openChat(MaxContact c) {
    // Подсказка «это диалог 1:1 с c.id» ДО навигации: чтобы отправка в новый
    // диалог шла по userId (op 64), а не по chatId — иначе user.not.found.
    ref.read(dialogPeerHintProvider(c.id).notifier).state = c.id;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(chatId: c.id, title: c.name),
      ),
    );
  }

  Future<void> _confirmDelete(MaxContact c) async {
    final messenger = ScaffoldMessenger.of(context);
    final l = L.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(L.of(context).contactsDeleteTitle),
        content: Text(c.name ?? c.phone ?? L.of(context).contactPlaceholder('${c.id}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L.of(context).commonDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(contactsListProvider.notifier).removeContact(c.id);
      messenger.showSnackBar(SnackBar(content: Text(l.contactDeleted)));
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.commonError('$e'))));
    }
  }

  Future<void> _runImport() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = L.of(context);
    final rootNav = Navigator.of(context, rootNavigator: true);

    // Массовый резолв номеров — поведенческий бан-сигнал MAX. Предупреждаем
    // и берём явное согласие, прежде чем перечислять справочник.
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.contactsImportTitle),
        content: Text(l.contactsImportWarn('${ContactsRepository.bulkLookupCap}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L.of(context).commonContinue),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;

    final progressNotifier = ValueNotifier<ImportProgress>(
      ImportProgress.idle.copyWith(running: true),
    );
    var dismissed = false;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.contactsImportTitle),
          content: ValueListenableBuilder<ImportProgress>(
            valueListenable: progressNotifier,
            builder: (_, p, __) {
              final value =
                  (p.total > 0) ? (p.done / p.total).clamp(0.0, 1.0) : null;
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LinearProgressIndicator(value: value),
                  const SizedBox(height: 12),
                  Text(
                    p.total == 0
                        ? L.of(context).contactsReadingBook
                        : L.of(context).contactsChecking('${p.done}', '${p.total}'),
                    textAlign: TextAlign.center,
                  ),
                ],
              );
            },
          ),
        );
      },
    ).then((_) => dismissed = true);

    try {
      final result = await ref
          .read(contactsListProvider.notifier)
          .importFromAddressBook(
            onProgress: (p) => progressNotifier.value = p,
          );
      if (!dismissed && mounted) {
        rootNav.pop();
      }
      final msg = StringBuffer(
        l.contactsFoundInMax('${result.found}', '${result.checked}'),
      );
      if (result.skipped > 0) {
        msg.write('. Пропущено сверх лимита: ${result.skipped}');
      }
      messenger.showSnackBar(SnackBar(content: Text(msg.toString())));
    } catch (e) {
      if (!dismissed && mounted) {
        rootNav.pop();
      }
      messenger.showSnackBar(SnackBar(content: Text(l.commonError('$e'))));
    } finally {
      progressNotifier.dispose();
    }
  }

  Future<void> _showAddDialog() async {
    final l = L.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(L.of(context).contactsFindByNumber),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+79991234567',
              labelText: L.of(context).contactsPhone,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(L.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: Text(L.of(context).commonFind),
            ),
          ],
        );
      },
    );
    if (result == null || result.isEmpty) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = await ref.read(contactsRepositoryProvider.future);
      final c = await repo.findByPhone(result);
      await ref.read(contactsListProvider.notifier).refresh();
      messenger.showSnackBar(
        SnackBar(content: Text(l.contactsFound('${c.name ?? c.phone ?? c.id}'))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.commonError('$e'))));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.onAdd,
    required this.onImport,
    required this.isSearch,
  });

  final VoidCallback onAdd;
  final VoidCallback onImport;
  final bool isSearch;

  @override
  Widget build(BuildContext context) {
    if (isSearch) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            L.of(context).commonNothingFound,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              L.of(context).contactsEmpty,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.cloud_download_outlined),
              label: Text(L.of(context).contactsImport),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_alt),
              label: Text(L.of(context).contactsAddByNumber),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedContactsList extends StatelessWidget {
  const _GroupedContactsList({
    required this.items,
    required this.onTap,
    required this.onDelete,
  });

  final List<MaxContact> items;
  final void Function(MaxContact) onTap;
  final void Function(MaxContact) onDelete;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByLetter(items);
    final keys = groups.keys.toList();
    final entries = <_ListEntry>[];
    for (final k in keys) {
      entries.add(_ListEntry.header(k));
      for (final c in groups[k]!) {
        entries.add(_ListEntry.contact(c));
      }
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (ctx, i) {
        final e = entries[i];
        if (e.isHeader) {
          return Container(
            color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Text(
              e.header!,
              style: Theme.of(ctx).textTheme.labelLarge,
            ),
          );
        }
        final c = e.contact!;
        final initial =
            (c.name?.isNotEmpty ?? false) ? c.name![0].toUpperCase() : '#';
        return Dismissible(
          key: ValueKey('contact-${c.id}'),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(ctx).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.delete,
              color: Theme.of(ctx).colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (_) async {
            onDelete(c);
            // Возвращаем false: подтверждение и удаление делаем сами,
            // чтобы ListView сам перерисовался после обновления стейта.
            return false;
          },
          child: ListTile(
            leading: CircleAvatar(child: Text(initial)),
            title: Text(c.name ?? c.phone ?? L.of(context).contactPlaceholder('${c.id}')),
            subtitle: c.phone == null ? null : Text(c.phone!),
            trailing: const Icon(Icons.chat_bubble_outline),
            onTap: () => onTap(c),
          ),
        );
      },
    );
  }

  static Map<String, List<MaxContact>> _groupByLetter(List<MaxContact> all) {
    final map = <String, List<MaxContact>>{};
    for (final c in all) {
      final n = c.name?.trim();
      final key = (n != null && n.isNotEmpty)
          ? n[0].toUpperCase()
          : '#';
      map.putIfAbsent(key, () => []).add(c);
    }
    final sortedKeys = map.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });
    return {for (final k in sortedKeys) k: map[k]!};
  }
}

class _ListEntry {
  _ListEntry.header(this.header) : contact = null;
  _ListEntry.contact(this.contact) : header = null;

  final String? header;
  final MaxContact? contact;

  bool get isHeader => header != null;
}
