import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/max/models/contact.dart';
import '../data/repositories/contacts_repository.dart';
import 'providers.dart';

/// Прогресс импорта адресной книги. [total] = 0 означает «не запущено».
class ImportProgress {
  const ImportProgress({
    required this.done,
    required this.total,
    this.running = false,
    this.found,
    this.error,
  });

  final int done;
  final int total;
  final bool running;
  final int? found;
  final String? error;

  static const idle = ImportProgress(done: 0, total: 0);

  ImportProgress copyWith({
    int? done,
    int? total,
    bool? running,
    int? found,
    String? error,
  }) {
    return ImportProgress(
      done: done ?? this.done,
      total: total ?? this.total,
      running: running ?? this.running,
      found: found ?? this.found,
      error: error ?? this.error,
    );
  }
}

class ContactsListController extends AsyncNotifier<List<MaxContact>> {
  ContactsRepository? _repo;
  List<MaxContact> _all = const [];
  String _query = '';

  @override
  Future<List<MaxContact>> build() async {
    _repo = await ref.watch(contactsRepositoryProvider.future);
    _all = await _repo!.listLocal();
    return _applyFilter(_all, _query);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repo = await _ensureRepo();
      _all = await repo.listLocal();
      state = AsyncData(_applyFilter(_all, _query));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> removeContact(int id) async {
    final repo = await _ensureRepo();
    await repo.remove(id);
    _all = _all.where((c) => c.id != id).toList();
    state = AsyncData(_applyFilter(_all, _query));
  }

  /// Возвращает (найдено, проверено, пропущено-сверх-лимита). Прогресс
  /// пробрасывается callback'ом, итог — через возвращаемое значение.
  Future<({int found, int checked, int skipped})> importFromAddressBook({
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final repo = await _ensureRepo();
    onProgress?.call(ImportProgress.idle.copyWith(running: true));
    try {
      final result = await repo.importFromAddressBook(
        onProgress: (done, total) {
          onProgress?.call(ImportProgress(
            done: done,
            total: total,
            running: true,
          ));
        },
      );
      _all = await repo.listLocal();
      state = AsyncData(_applyFilter(_all, _query));
      onProgress?.call(ImportProgress(
        done: 0,
        total: 0,
        running: false,
        found: result.found,
      ));
      return result;
    } catch (e) {
      onProgress?.call(ImportProgress(
        done: 0,
        total: 0,
        running: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }

  void search(String query) {
    _query = query;
    state = AsyncData(_applyFilter(_all, _query));
  }

  Future<ContactsRepository> _ensureRepo() async {
    final cached = _repo;
    if (cached != null) return cached;
    final repo = await ref.read(contactsRepositoryProvider.future);
    _repo = repo;
    return repo;
  }

  static List<MaxContact> _applyFilter(List<MaxContact> all, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((c) {
      final n = (c.name ?? '').toLowerCase();
      final p = (c.phone ?? '').toLowerCase();
      return n.contains(q) || p.contains(q);
    }).toList();
  }
}

final contactsListProvider =
    AsyncNotifierProvider<ContactsListController, List<MaxContact>>(
  ContactsListController.new,
);

final contactsSearchQueryProvider = StateProvider<String>((_) => '');

/// Чёрный список — заблокированные контакты. Блокировка/разблокировка шлётся
/// на сервер (op 34 CONTACT_UPDATE) и фиксируется локально.
class BlacklistController extends AsyncNotifier<List<MaxContact>> {
  @override
  Future<List<MaxContact>> build() async {
    final repo = await ref.watch(contactsRepositoryProvider.future);
    return repo.listBlocked();
  }

  Future<void> _reload() async {
    final repo = await ref.read(contactsRepositoryProvider.future);
    state = AsyncData(await repo.listBlocked());
  }

  /// Заблокировать контакт (добавить в ЧС).
  Future<void> block(MaxContact contact) async {
    final repo = await ref.read(contactsRepositoryProvider.future);
    await repo.setBlocked(contact.id, true, contact: contact);
    await _reload();
    ref.invalidate(contactsListProvider);
  }

  /// Разблокировать контакт (убрать из ЧС).
  Future<void> unblock(int contactId) async {
    final repo = await ref.read(contactsRepositoryProvider.future);
    await repo.setBlocked(contactId, false);
    await _reload();
    ref.invalidate(contactsListProvider);
  }
}

final blacklistProvider =
    AsyncNotifierProvider<BlacklistController, List<MaxContact>>(
  BlacklistController.new,
);

/// Состояние экрана контактов в стиле MAX: записи адресной книги + признаки
/// отказа в доступе и идущего фонового резолва.
class AddressBookView {
  const AddressBookView({
    this.entries = const [],
    this.permissionDenied = false,
    this.resolving = false,
  });

  final List<AddressBookEntry> entries;
  final bool permissionDenied;
  final bool resolving;

  AddressBookView copyWith({
    List<AddressBookEntry>? entries,
    bool? permissionDenied,
    bool? resolving,
  }) {
    return AddressBookView(
      entries: entries ?? this.entries,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      resolving: resolving ?? this.resolving,
    );
  }
}

/// Читает адресную книгу и в фоне резолвит непроверенные номера в MAX
/// (троттлинг + дедуп внутри репозитория). По мере нахождения обновляет список
/// контактов, чтобы «В Максе» пополнялся сам.
class AddressBookController extends AsyncNotifier<AddressBookView> {
  @override
  Future<AddressBookView> build() async {
    final repo = await ref.watch(contactsRepositoryProvider.future);
    try {
      final entries = await repo.readAddressBook();
      // Фоновый резолв — не блокирует показ книги.
      unawaited(_resolve(repo));
      return AddressBookView(entries: entries);
    } on StateError {
      return const AddressBookView(permissionDenied: true);
    }
  }

  Future<void> _resolve(ContactsRepository repo) async {
    final current = state.valueOrNull;
    if (current == null || current.entries.isEmpty) return;
    state = AsyncData(current.copyWith(resolving: true));
    try {
      final found = await repo.resolveAddressBook(current.entries);
      if (found > 0) ref.invalidate(contactsListProvider);
    } catch (_) {
      // Оффлайн/ошибка резолва — не критично, покажем то, что уже известно.
    } finally {
      final c = state.valueOrNull;
      if (c != null) state = AsyncData(c.copyWith(resolving: false));
    }
  }

  /// Повторно запросить доступ и перечитать книгу (кнопка «Разрешить доступ»).
  void retry() {
    ref.invalidateSelf();
  }
}

final addressBookProvider =
    AsyncNotifierProvider<AddressBookController, AddressBookView>(
  AddressBookController.new,
);
