import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/max/models/contact.dart';
import '../../l10n/app_localizations.dart';
import '../../data/repositories/contacts_repository.dart';
import '../../state/chats_controller.dart';
import '../../state/contacts_controller.dart';
import '../../state/providers.dart';
import 'chat_screen.dart';

/// Экран «Контакты» в стиле MAX: сверху — те, кто уже в MAX (тап открывает
/// чат), ниже — остальные из адресной книги с кнопкой «Пригласить». Кто из
/// книги уже в MAX, выясняется фоновым резолвом (op 46) с троттлингом и
/// дедупом (см. [AddressBookController]/[ContactsRepository]).
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool _showSearch = false;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L.of(context);
    final maxContacts = ref.watch(contactsListProvider);
    final book = ref.watch(addressBookProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.navContacts),
        actions: [
          IconButton(
            tooltip: _showSearch ? l.contactsHideSearch : l.commonSearch,
            onPressed: _toggleSearch,
            icon: Icon(_showSearch ? Icons.search_off : Icons.search),
          ),
          // Резолв книги в MAX — ТОЛЬКО вручную и с предупреждением:
          // автоматический запуск приводил к блокировке аккаунта.
          IconButton(
            tooltip: l.contactsImport,
            onPressed: book.valueOrNull?.resolving == true
                ? null
                : _resolveManually,
            icon: const Icon(Icons.cloud_download_outlined),
          ),
          IconButton(
            tooltip: l.contactsAddByNumber,
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
                      hintText: l.commonSearch,
                      isDense: true,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            ),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              )
            : null,
      ),
      body: maxContacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.commonError('$e'))),
        data: (contacts) => _buildBody(context, contacts, book),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    List<MaxContact> maxContacts,
    AsyncValue<AddressBookView> bookAsync,
  ) {
    final l = L.of(context);
    final view = bookAsync.valueOrNull ?? const AddressBookView();

    // Каноничные ключи телефонов контактов, уже известных в MAX.
    final registeredKeys = <String>{
      for (final c in maxContacts)
        if (c.phone != null) ...{
          if (ContactsRepository.phoneKey(c.phone!) != null)
            ContactsRepository.phoneKey(c.phone!)!,
        },
    };
    // Имя из адресной книги по ключу — для более понятной подписи MAX-контакта.
    final bookNameByKey = <String, String>{
      for (final e in view.entries) e.key: e.displayName,
    };

    // «В Максе»: контакты из БД (исключаем заблокированных из общего списка).
    final inMax = maxContacts.where((c) => !c.blocked).toList()
      ..sort((a, b) => _nameOf(a, bookNameByKey)
          .toLowerCase()
          .compareTo(_nameOf(b, bookNameByKey).toLowerCase()));

    // «Пригласить»: записи книги, которых нет в MAX.
    final invite = view.entries
        .where((e) => !registeredKeys.contains(e.key))
        .toList();

    // Фильтр поиска.
    final q = _query.trim().toLowerCase();
    final inMaxF = q.isEmpty
        ? inMax
        : inMax.where((c) {
            final n = _nameOf(c, bookNameByKey).toLowerCase();
            final p = (c.phone ?? '').toLowerCase();
            return n.contains(q) || p.contains(q);
          }).toList();
    final inviteF = q.isEmpty
        ? invite
        : invite.where((e) {
            return e.displayName.toLowerCase().contains(q) ||
                e.phone.toLowerCase().contains(q);
          }).toList();

    final rows = <Widget>[];

    if (view.resolving) {
      rows.add(_syncingBanner(context));
    }
    if (view.permissionDenied) {
      rows.add(_accessCard(context));
    }

    if (inMaxF.isNotEmpty) {
      rows.add(_sectionHeader(context, l.contactsSectionInMax));
      for (final c in inMaxF) {
        rows.add(_maxContactTile(context, c, bookNameByKey));
      }
    }
    if (inviteF.isNotEmpty) {
      rows.add(_sectionHeader(context, l.contactsSectionInvite));
      for (final e in inviteF) {
        rows.add(_inviteTile(context, e));
      }
    }

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            q.isNotEmpty ? l.commonNothingFound : l.contactsEmpty,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(addressBookProvider.notifier).retry();
        await ref.read(contactsListProvider.notifier).refresh();
      },
      child: ListView(children: rows),
    );
  }

  String _nameOf(MaxContact c, Map<String, String> bookNames) {
    final n = c.name?.trim();
    if (n != null && n.isNotEmpty && n != 'Контакт ${c.id}') return n;
    final key = c.phone == null ? null : ContactsRepository.phoneKey(c.phone!);
    if (key != null) {
      final bn = bookNames[key];
      if (bn != null && bn.isNotEmpty) return bn;
    }
    return c.phone ?? L.of(context).contactPlaceholder('${c.id}');
  }

  Widget _sectionHeader(BuildContext context, String text) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(text, style: Theme.of(context).textTheme.labelLarge),
    );
  }

  Widget _syncingBanner(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(L.of(context).contactsSyncing,
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _accessCard(BuildContext context) {
    final l = L.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.contactsNoAccessTitle,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(l.contactsNoAccessSub,
              style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => ref.read(addressBookProvider.notifier).retry(),
            child: Text(l.contactsGrantAccess),
          ),
        ],
      ),
    );
  }

  Widget _maxContactTile(
    BuildContext context,
    MaxContact c,
    Map<String, String> bookNames,
  ) {
    final name = _nameOf(c, bookNames);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '#';
    return Dismissible(
      key: ValueKey('contact-${c.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Theme.of(context).colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete,
            color: Theme.of(context).colorScheme.onErrorContainer),
      ),
      confirmDismiss: (_) async {
        _confirmDelete(c);
        return false;
      },
      child: ListTile(
        leading: CircleAvatar(child: Text(initial)),
        title: Text(name),
        subtitle: c.phone == null ? null : Text(c.phone!),
        trailing: const Icon(Icons.chat_bubble_outline),
        onTap: () => _openChat(c),
      ),
    );
  }

  Widget _inviteTile(BuildContext context, AddressBookEntry e) {
    final initial = e.displayName.isNotEmpty
        ? e.displayName[0].toUpperCase()
        : '#';
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        child: Text(initial,
            style: TextStyle(color: scheme.onSurfaceVariant)),
      ),
      title: Text(e.displayName),
      subtitle: Text(e.phone),
      trailing: OutlinedButton(
        onPressed: () => _invite(e),
        child: Text(L.of(context).contactsInviteBtn),
      ),
    );
  }

  /// Ручная проверка номеров книги в MAX. Сначала — предупреждение о риске
  /// (массовый резолв = анти-бан-сигнал), запуск только по явному согласию.
  Future<void> _resolveManually() async {
    final l = L.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.contactsImportTitle),
        content:
            Text(l.contactsImportWarn('${ContactsRepository.bulkLookupCap}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonContinue),
          ),
        ],
      ),
    );
    if (proceed != true || !mounted) return;
    var checked = 0;
    try {
      final found = await ref
          .read(addressBookProvider.notifier)
          .resolveNow(onProgress: (_, total) => checked = total);
      messenger.showSnackBar(
        SnackBar(content: Text(l.contactsFoundInMax('$found', '$checked'))),
      );
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(l.commonError('$e'))));
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearch = !_showSearch;
      if (!_showSearch) {
        _searchCtrl.clear();
        _query = '';
      }
    });
  }

  Future<void> _invite(AddressBookEntry e) async {
    final l = L.of(context);
    // Системный «Поделиться» (iOS UIActivityViewController / Android chooser):
    // пользователь сам выбирает SMS/мессенджер для приглашения.
    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      l.contactsInviteText(e.displayName),
      subject: L.of(context).contactsSectionInvite,
      // iPad требует origin для поповера — иначе краш.
      sharePositionOrigin:
          box == null ? null : box.localToGlobal(Offset.zero) & box.size,
    );
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
        title: Text(l.contactsDeleteTitle),
        content: Text(c.name ?? c.phone ?? l.contactPlaceholder('${c.id}')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.commonDelete),
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

  Future<void> _showAddDialog() async {
    final l = L.of(context);
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l.contactsFindByNumber),
          content: TextField(
            controller: ctrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: '+79991234567',
              labelText: l.contactsPhone,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
              child: Text(l.commonFind),
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
