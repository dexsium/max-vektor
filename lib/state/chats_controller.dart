import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/max/models/attach.dart';
import '../data/repositories/chats_repository.dart';
import '../data/max/models/chat.dart';
import '../data/max/models/message.dart';
import '../data/max/models/upload_input.dart';
import 'providers.dart';

/// Поток списка чатов, перерисовывается при любом изменении.
class ChatsListController extends AsyncNotifier<List<MaxChat>> {
  StreamSubscription? _sub;
  StreamSubscription? _syncSub;

  @override
  Future<List<MaxChat>> build() async {
    final repo = await ref.watch(chatsRepositoryProvider.future);
    final msgRepo = await ref.watch(messagesRepositoryProvider.future);
    final client = ref.watch(maxClientProvider);
    _sub?.cancel();
    _sub = msgRepo.changedChats.listen((_) => _reload());

    // Группы и каналы приходят списком в ответе LOGIN (op 19) — без этого
    // они не появлялись в списке, пока в них не придёт новое сообщение.
    _syncSub?.cancel();
    _syncSub = client.syncedChatsStream.listen((chats) async {
      await repo.ingestServerChats(chats);
      await _reload();
    });
    ref.onDispose(() {
      _sub?.cancel();
      _syncSub?.cancel();
    });

    final cached = client.lastSyncedChats;
    if (cached != null) await repo.ingestServerChats(cached);

    final local = await repo.listLocal();
    // Дозапрашиваем названия/аватары у чатов, застрявших на плейсхолдере
    // «Чат N» (обычно заведены из push без CHAT_INFO). Делаем это в фоне,
    // чтобы не задерживать первую отрисовку списка.
    unawaited(_fillMissingTitles(repo, local));
    return local;
  }

  /// Подтянуть CHAT_INFO (op 48) для чатов без нормального названия.
  Future<void> _fillMissingTitles(
    ChatsRepository repo,
    List<MaxChat> chats,
  ) async {
    final ids = <int>[
      for (final c in chats)
        if (_needsInfo(c)) (c.serverChatId ?? c.id),
    ];
    if (ids.isEmpty) return;
    try {
      // Не больше 50 за раз — щадим сервер.
      await repo.refresh(ids.take(50).toList());
      await _reload();
    } catch (_) {
      // Оффлайн/ошибка — не критично, названия подтянутся позже.
    }
  }

  static bool _needsInfo(MaxChat c) {
    final t = c.title;
    // Любой чат без нормального названия дозапрашиваем через CHAT_INFO —
    // и группы/каналы, и диалоги (у диалога ответ несёт участника, из него
    // берём имя и аватар). Раньше диалоги пропускались и застревали на
    // «Чат N», если контакт не был известен.
    return t == null || t.isEmpty || t == 'Чат ${c.id}';
  }

  Future<void> _reload() async {
    final repo = await ref.read(chatsRepositoryProvider.future);
    state = AsyncData(await repo.listLocal());
  }

  Future<void> refresh() => _reload();

  Future<void> markRead(int chatId) async {
    final repo = await ref.read(chatsRepositoryProvider.future);
    await repo.markRead(chatId);
    await _reload();
  }

  Future<void> togglePin(int chatId, bool pinned) async {
    final db = await ref.read(appDatabaseProvider.future);
    await db.setChatFlag(chatId, pinned: pinned);
    await _reload();
  }

  /// Удалить чат локально (свайп «Удалить»).
  Future<void> deleteChat(int chatId) async {
    final repo = await ref.read(chatsRepositoryProvider.future);
    await repo.deleteChat(chatId);
    await _reload();
  }

  Future<void> toggleArchive(int chatId, bool archived) async {
    final db = await ref.read(appDatabaseProvider.future);
    await db.setChatFlag(chatId, archived: archived);
    await _reload();
  }

  Future<void> toggleMute(int chatId, bool muted) async {
    final db = await ref.read(appDatabaseProvider.future);
    await db.setChatFlag(chatId, muted: muted);
    await _reload();
  }
}

final chatsListProvider =
    AsyncNotifierProvider<ChatsListController, List<MaxChat>>(
  ChatsListController.new,
);

/// Строка чата по локальному id — нужна экрану чата, чтобы понимать,
/// группа это/канал (тогда рисуем имя отправителя) или диалог 1:1.
final chatByIdProvider = FutureProvider.family<MaxChat?, int>((ref, id) async {
  // Пересчитывается вместе со списком: после синка чатов тип и название
  // приходят с сервера.
  ref.watch(chatsListProvider);
  final repo = await ref.read(chatsRepositoryProvider.future);
  return repo.get(id);
});

/// Имена отправителей для группы/канала: userId → отображаемое имя.
///
/// Сначала берём то, что уже лежит локально в contacts, затем ОДНИМ
/// запросом CONTACT_INFO (op 32) добираем недостающих. Массовых
/// перечислений не делаем — только id, реально встреченные в истории
/// этого чата.
final chatSenderNamesProvider =
    FutureProvider.family<Map<int, String>, int>((ref, chatId) async {
  final messages = await ref.watch(chatHistoryProvider(chatId).future);
  final db = await ref.read(appDatabaseProvider.future);
  final ids = <int>{
    for (final m in messages)
      if (m.senderId != null) m.senderId!,
  };
  if (ids.isEmpty) return const {};

  final out = <int, String>{};
  final missing = <int>[];
  for (final id in ids) {
    final c = await db.contact(id);
    final name = c?.name;
    if (name != null && name.isNotEmpty) {
      out[id] = name;
    } else {
      missing.add(id);
    }
  }
  if (missing.isNotEmpty) {
    try {
      final contacts = await ref.read(contactsRepositoryProvider.future);
      await contacts.refresh(missing);
      for (final id in missing) {
        final c = await db.contact(id);
        final name = c?.name;
        if (name != null && name.isNotEmpty) out[id] = name;
      }
    } catch (_) {
      // Оффлайн или сервер не отдал — покажем «Участник N».
    }
  }
  return out;
});

/// Имя пользователя по id (для автора пересланного сообщения от лички).
/// Сначала локальный контакт, затем догрузка через CONTACT_INFO (op 32).
/// null, если имя так и не удалось получить.
final userDisplayNameProvider =
    FutureProvider.family<String?, int>((ref, userId) async {
  final db = await ref.read(appDatabaseProvider.future);
  var name = (await db.contact(userId))?.name;
  if (name != null && name.isNotEmpty) return name;
  try {
    final contacts = await ref.read(contactsRepositoryProvider.future);
    await contacts.refresh([userId]);
    name = (await db.contact(userId))?.name;
  } catch (_) {
    // Оффлайн или сервер не отдал — имя останется неизвестным.
  }
  return (name != null && name.isNotEmpty) ? name : null;
});

/// Подсказка «этот chatId — диалог 1:1 с этим peerUserId», выставляется
/// навигацией (ContactsScreen._openChat) ДО построения ChatHistoryController.
/// Нужна, чтобы отправка в новый диалог шла по userId, а не по chatId.
final dialogPeerHintProvider =
    StateProvider.family<int?, int>((ref, chatId) => null);

/// Сообщения конкретного чата. Если есть локальные - отдаём сразу,
/// параллельно подтягиваем свежие с сервера.
class ChatHistoryController extends FamilyAsyncNotifier<List<MaxMessage>, int> {
  StreamSubscription? _sub;
  late int _chatId;
  bool _loadingOlder = false;

  /// Истинно пока идёт догрузка более старых сообщений — UI рисует спиннер.
  bool get isLoadingOlder => _loadingOlder;

  @override
  Future<List<MaxMessage>> build(int chatId) async {
    _chatId = chatId;
    final repo = await ref.watch(messagesRepositoryProvider.future);
    final chatsRepo = await ref.watch(chatsRepositoryProvider.future);
    _sub?.cancel();
    _sub = repo.changedChats.where((c) => c == chatId).listen((_) => _reload());
    ref.onDispose(() => _sub?.cancel());
    final peerHint = ref.read(dialogPeerHintProvider(chatId));
    await chatsRepo.ensureExists(chatId, peerUserId: peerHint);
    final local = await repo.localHistory(chatId);
    if (local.isEmpty) {
      unawaited(repo.syncHistory(chatId, count: 50));
    } else {
      unawaited(repo.syncHistory(chatId, count: 30));
    }
    return local;
  }

  Future<void> _reload() async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    state = AsyncData(await repo.localHistory(_chatId));
  }

  Future<void> send(
    String text, {
    int? replyToId,
    String? replyToPreview,
  }) async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    await repo.sendText(
      _chatId,
      text,
      replyToId: replyToId,
      replyToPreview: replyToPreview,
    );
  }

  Future<void> syncFromServer({int count = 50}) async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    await repo.syncHistory(_chatId, count: count);
  }

  /// Подтянуть более старые сообщения. UI вызывает при скролле вверх.
  Future<void> loadOlder({int count = 50}) async {
    if (_loadingOlder) return;
    _loadingOlder = true;
    // Перерисуем, чтобы показать спиннер сверху.
    if (state is AsyncData<List<MaxMessage>>) {
      state = AsyncData(state.value ?? const []);
    }
    try {
      final repo = await ref.read(messagesRepositoryProvider.future);
      await repo.loadOlder(_chatId, count: count);
    } finally {
      _loadingOlder = false;
      if (state is AsyncData<List<MaxMessage>>) {
        state = AsyncData(state.value ?? const []);
      }
    }
  }

  Future<void> sendTyping(bool active) async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    await repo.sendTyping(_chatId, active: active);
  }

  /// Повторить отправку всех failed-сообщений этого чата. Дёргает дренаж
  /// outbox в фоне.
  Future<void> retryFailed() async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    await repo.retryFailed(_chatId);
  }

  /// Отправить сообщение с одним или несколькими вложениями. После
  /// возврата дёргает _reload() — список сообщений перерисуется.
  Future<void> sendMedia(
    List<UploadInput> inputs, {
    String text = '',
    int? replyToId,
  }) async {
    if (inputs.isEmpty) return;
    final repo = await ref.read(messagesRepositoryProvider.future);
    await repo.sendMedia(
      _chatId,
      inputs,
      text: text,
      replyToId: replyToId,
    );
    await _reload();
  }

  /// Скачать вложение в локальный кеш. Возвращает путь к файлу или null
  /// (ошибка/нет fileId). После успеха перерисовывает чат.
  Future<String?> downloadAttach(MaxAttach a, int messageServerId) async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    final path = await repo.downloadAttach(
      a,
      chatId: _chatId,
      messageId: messageServerId,
    );
    if (path != null) {
      await _reload();
    }
    return path;
  }

  /// Редактирование уже отправленного сообщения (opcode 67). Контроллер
  /// после успеха дёргает [_reload] — UI увидит новый текст и плашку «изм.».
  Future<void> editMessage(int messageId, String newText) async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    await repo.editMessage(_chatId, messageId, newText);
    await _reload();
  }

  /// Запросить расшифровку (opcode 202) у сервера и закешировать локально.
  /// Возвращает текст или null. UI рисует indicator на время запроса.
  Future<String?> transcribeAttach(MaxAttach a, int messageServerId) async {
    final repo = await ref.read(messagesRepositoryProvider.future);
    return repo.transcribeAttach(
      a,
      chatId: _chatId,
      messageId: messageServerId,
    );
  }
}

final chatHistoryProvider = AsyncNotifierProvider.family<
    ChatHistoryController, List<MaxMessage>, int>(
  ChatHistoryController.new,
);
