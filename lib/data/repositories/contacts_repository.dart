import 'dart:async';
import 'dart:math';

import 'package:flutter_contacts/flutter_contacts.dart';

import '../local/database.dart';
import '../max/contact_name.dart';
import '../max/max_client.dart';
import '../max/models/contact.dart';

/// Запись адресной книги устройства: имя + номер телефона.
class AddressBookEntry {
  const AddressBookEntry({
    required this.displayName,
    required this.phone,
    required this.key,
  });

  final String displayName;

  /// Номер как в книге (для показа/приглашения).
  final String phone;

  /// Каноничный ключ для сопоставления с контактами MAX (последние 10 цифр).
  final String key;
}

class ContactsRepository {
  ContactsRepository({required this.client, required this.db});

  final MaxClient client;
  final AppDatabase db;

  Future<List<MaxContact>> listLocal() => db.contacts();
  Future<MaxContact?> get(int id) => db.contact(id);

  /// Каноничный ключ телефона для сопоставления: только цифры, последние 10
  /// (устойчиво к вариациям +7/8/код страны). null — если номер невалиден.
  static String? phoneKey(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 7) return null;
    return digits.length > 10 ? digits.substring(digits.length - 10) : digits;
  }

  /// Прочитать адресную книгу устройства (с запросом разрешения). Возвращает
  /// уникальные по номеру записи. Бросает [StateError] при отказе в доступе.
  Future<List<AddressBookEntry>> readAddressBook() async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      throw StateError('Нет доступа к контактам');
    }
    final raw = await FlutterContacts.getContacts(withProperties: true);
    final byKey = <String, AddressBookEntry>{};
    for (final c in raw) {
      for (final ph in c.phones) {
        final key = phoneKey(ph.number);
        if (key == null) continue;
        // Первое имя для номера побеждает; телефонов у контакта может быть
        // несколько — каждый номер отдельной записью.
        byKey.putIfAbsent(
          key,
          () => AddressBookEntry(
            displayName: c.displayName.trim().isEmpty
                ? ph.number
                : c.displayName.trim(),
            phone: ph.number,
            key: key,
          ),
        );
      }
    }
    final list = byKey.values.toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
    return list;
  }

  Future<Set<String>> checkedKeys() => db.checkedPhones();

  /// Фоновый резолв номеров из книги, ещё не проверенных в MAX. Anti-ban:
  /// не более [bulkLookupCap] за раз, строго последовательно с джиттером, и
  /// каждый номер помечается проверенным (повторно не резолвится). Возвращает
  /// число найденных в MAX.
  Future<int> resolveAddressBook(
    List<AddressBookEntry> book, {
    void Function(int done, int total)? onProgress,
  }) async {
    final checked = await db.checkedPhones();
    // Каноничные ключи уже известных MAX-контактов — их не резолвим.
    final known = <String>{};
    for (final c in await db.contacts()) {
      final k = c.phone == null ? null : phoneKey(c.phone!);
      if (k != null) known.add(k);
    }
    final pending = <AddressBookEntry>[];
    for (final e in book) {
      if (checked.contains(e.key) || known.contains(e.key)) continue;
      pending.add(e);
      if (pending.length >= bulkLookupCap) break;
    }
    if (pending.isEmpty) return 0;

    final total = pending.length;
    var done = 0;
    var found = 0;
    final rng = Random();
    final checkedNow = <String>[];
    onProgress?.call(done, total);
    for (final e in pending) {
      if (await _lookupOne(e.phone)) found++;
      checkedNow.add(e.key);
      done++;
      onProgress?.call(done, total);
      if (done < total) {
        final ms = 1100 + rng.nextInt(700);
        await Future<void>.delayed(Duration(milliseconds: ms));
      }
    }
    await db.markPhonesChecked(checkedNow);
    return found;
  }

  /// Найти контакт по телефону, сохранить локально, вернуть.
  /// Бросает [StateError] если сервер ничего не нашёл.
  Future<MaxContact> findByPhone(String phone) async {
    final raw = await client.findContactByPhone(phone);
    final id = (raw['id'] as num?)?.toInt();
    if (id == null) {
      throw StateError('Контакт по номеру $phone не найден');
    }
    final c = MaxContact(
      id: id,
      name: raw['name']?.toString(),
      phone: raw['phone']?.toString() ?? phone,
    );
    await db.upsertContact(c);
    return c;
  }

  Future<void> refresh(List<int> ids) async {
    if (ids.isEmpty) return;
    final info = await client.contactInfo(ids);
    final arr = info['contacts'] ?? info['items'];
    if (arr is! List) return;
    for (final m in arr) {
      if (m is! Map) continue;
      final mm = m.map((k, v) => MapEntry(k.toString(), v));
      final id = (mm['id'] as num?)?.toInt();
      if (id == null) continue;
      await db.upsertContact(MaxContact(
        id: id,
        name: displayContactName(mm),
        phone: mm['phone']?.toString(),
        avatarUrl: mm['avatar']?.toString() ?? mm['photo']?.toString(),
      ));
    }
  }

  Future<void> remove(int contactId) async {
    await db.deleteContact(contactId);
  }

  /// Чёрный список: локально заблокированные контакты.
  Future<List<MaxContact>> listBlocked() => db.blockedContacts();

  /// Заблокировать/разблокировать контакт. Сначала шлём мутацию на сервер
  /// (op 34 CONTACT_UPDATE), при успехе фиксируем локальный флаг — так список
  /// переживает перезапуск и виден офлайн. [contact] нужен, чтобы завести
  /// строку, если блокируем собеседника не из адресной книги.
  Future<void> setBlocked(int contactId, bool blocked,
      {MaxContact? contact}) async {
    await client.setContactBlocked(contactId, blocked: blocked);
    await db.setContactBlocked(
      contactId,
      blocked: blocked,
      name: contact?.name,
      phone: contact?.phone,
      avatarUrl: contact?.avatarUrl,
    );
  }

  Future<List<MaxContact>> search(String query) async {
    return db.searchContacts(query);
  }

  /// Жёсткий потолок на число резолвов номеров за один импорт. Массовое
  /// перечисление справочника через op=46 — главный поведенческий бан-сигнал
  /// (по данным антифрода MAX спам/скрейпинг — причина №1 блокировок). Так
  /// что импорт намеренно «человеческий»: мало и медленно.
  static const int bulkLookupCap = 20;

  /// Bulk-поиск контактов по списку номеров. Anti-ban профиль: строго
  /// последовательно (не пачками), по одному запросу раз в ~1.1–1.8с с
  /// джиттером, не более [bulkLookupCap] номеров за раз. Возвращает
  /// (найдено, проверено, пропущено-сверх-лимита).
  Future<({int found, int checked, int skipped})> bulkLookupByPhones(
    List<String> phones, {
    void Function(int done, int total)? onProgress,
  }) async {
    final cleaned = <String>{};
    for (final p in phones) {
      final n = _normalizePhone(p);
      if (n != null) cleaned.add(n);
    }
    final all = cleaned.toList();
    final list = all.length > bulkLookupCap
        ? all.sublist(0, bulkLookupCap)
        : all;
    final skipped = all.length - list.length;
    final total = list.length;
    var done = 0;
    var found = 0;
    final rng = Random();
    onProgress?.call(done, total);

    for (final phone in list) {
      if (await _lookupOne(phone)) found++;
      done++;
      onProgress?.call(done, total);
      if (done < total) {
        // 1.1–1.8с между запросами: темп живого человека, не сканера.
        final ms = 1100 + rng.nextInt(700);
        await Future<void>.delayed(Duration(milliseconds: ms));
      }
    }
    return (found: found, checked: total, skipped: skipped);
  }

  Future<bool> _lookupOne(String phone) async {
    try {
      final raw = await client.findContactByPhone(phone);
      final id = (raw['id'] as num?)?.toInt();
      if (id == null) return false;
      await db.upsertContact(MaxContact(
        id: id,
        name: raw['name']?.toString(),
        phone: raw['phone']?.toString() ?? phone,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Запросить разрешение, прочитать адресную книгу, найти в MAX
  /// тех, кто там зарегистрирован. Возвращает (найдено, проверено, пропущено).
  Future<({int found, int checked, int skipped})> importFromAddressBook({
    void Function(int done, int total)? onProgress,
  }) async {
    final granted = await FlutterContacts.requestPermission(readonly: true);
    if (!granted) {
      throw StateError('Нет разрешения на чтение контактов');
    }
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,
    );
    final phones = <String>{};
    for (final c in contacts) {
      for (final ph in c.phones) {
        final n = _normalizePhone(ph.number);
        if (n != null) phones.add(n);
      }
    }
    if (phones.isEmpty) {
      onProgress?.call(0, 0);
      return (found: 0, checked: 0, skipped: 0);
    }
    return bulkLookupByPhones(phones.toList(), onProgress: onProgress);
  }

  /// Оставить только цифры; если был ведущий `+`, сохранить его.
  static String? _normalizePhone(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final hasPlus = trimmed.startsWith('+');
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    return hasPlus ? '+$digits' : digits;
  }
}
