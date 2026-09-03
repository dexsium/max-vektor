import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import 'qr_login_scanner_screen.dart';

/// Экран «Устройства»: активные сессии аккаунта (op 96 SESSIONS_INFO) с
/// возможностью завершить как все чужие (op 97 exceptCurrent), так и каждую
/// по отдельности. Оформление повторяет официальное приложение: карточка-шапка,
/// список сессий, «Завершить все…» и кнопка входа по QR.
class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _loading = true;
  bool _busy = false;
  String? _error;
  List<Map<String, dynamic>> _sessions = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(maxClientProvider).sessionsInfo();
      if (!mounted) return;
      // Текущая сессия — вперёд.
      final list = _extractSessions(res)
        ..sort((a, b) => (_isCurrent(b) ? 1 : 0) - (_isCurrent(a) ? 1 : 0));
      setState(() {
        _sessions = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _extractSessions(Map<String, dynamic> res) {
    for (final k in const ['sessions', 'devices', 'items', 'list', 'result']) {
      final v = res[k];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
            .toList();
      }
    }
    return const [];
  }

  int? _sessionId(Map<String, dynamic> s) {
    for (final k in const ['sessionId', 'id', 'session']) {
      final v = s[k];
      if (v is num) return v.toInt();
    }
    return null;
  }

  bool _isCurrent(Map<String, dynamic> s) {
    for (final k in const ['isCurrent', 'current', 'self', 'thisDevice']) {
      if (s[k] == true) return true;
    }
    return false;
  }

  bool _isOnline(Map<String, dynamic> s) =>
      s['online'] == true || s['isOnline'] == true;

  /// Тип устройства (IOS/ANDROID/WEB). Суффикс «(текущая)» добавляется в UI.
  String _title(Map<String, dynamic> s) {
    final head = (s['deviceType'] ?? s['type'])?.toString();
    return (head == null || head.isEmpty) ? 'Device' : head;
  }

  /// Подзаголовок: модель, версия ОС/приложения, страна, регион, IP —
  /// как в официальном приложении (склеиваем присутствующие поля).
  String _subtitle(Map<String, dynamic> s) {
    final parts = <String>[];
    void add(Object? v) {
      final str = v?.toString().trim();
      if (str != null && str.isNotEmpty) parts.add(str);
    }

    add(s['deviceName']);
    add(s['osVersion'] ?? s['appVersion']);

    String? country, region;
    final loc = s['location'];
    if (loc is Map) {
      final lm = loc.map((k, v) => MapEntry(k.toString(), v));
      country = lm['country']?.toString();
      region = (lm['region'] ?? lm['regionName'] ?? lm['city'])?.toString();
    }
    country ??= s['country']?.toString();
    region ??= (s['region'] ?? s['city'])?.toString();
    add(country);
    add(region);

    final ip = (s['ip'] ?? s['ipAddress'] ?? s['remoteIp'])?.toString();
    if (ip != null && ip.isNotEmpty) parts.add('IP $ip');

    return parts.join(', ');
  }

  /// Правый статус: «В сети» либо время последней активности.
  String _statusText(BuildContext context, Map<String, dynamic> s) {
    if (_isOnline(s)) return L.of(context).devOnline;
    for (final k in const [
      'time',
      'lastActivityTime',
      'lastActivity',
      'lastSeen',
      'updateTime',
    ]) {
      final v = s[k];
      if (v is num && v > 1000000000000) {
        final dt = DateTime.fromMillisecondsSinceEpoch(v.toInt());
        final now = DateTime.now();
        final sameDay =
            dt.year == now.year && dt.month == now.month && dt.day == now.day;
        return sameDay
            ? DateFormat.Hm().format(dt)
            : DateFormat('dd.MM.yy').format(dt);
      }
    }
    return '';
  }

  Future<bool> _confirm(String title, String body) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(L.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(L.of(ctx).devTerminate),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text('Не удалось: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _closeAllOthers() async {
    if (!await _confirm(L.of(context).devTerminateAll, '')) {
      return;
    }
    await _run(
      () => ref.read(maxClientProvider).closeSessions(exceptCurrent: true),
    );
  }

  Future<void> _closeOne(int id, String name) async {
    if (!await _confirm('${L.of(context).devTerminate} «$name»', '')) {
      return;
    }
    await _run(
      () => ref.read(maxClientProvider).closeSessions(sessionId: id),
    );
  }

  void _openQrLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrLoginScannerScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final others = _sessions.where((s) => !_isCurrent(s)).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(L.of(context).devTitle),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _errorView()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    children: [
                      _headerCard(),
                      const SizedBox(height: 12),
                      if (_sessions.isEmpty)
                        _emptyView()
                      else
                        _sessionsCard(others),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _openQrLogin,
              icon: const Icon(Icons.qr_code_scanner),
              label: Text(L.of(context).devQrLogin,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCard() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.devices_other,
                  size: 34, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Text(L.of(context).devHeaderTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              L.of(context).devHeaderSub,
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sessionsCard(int others) {
    final scheme = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < _sessions.length; i++) {
      if (i > 0) rows.add(const SizedBox(height: 4));
      rows.add(_sessionRow(_sessions[i]));
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...rows,
            if (others > 0) ...[
              const SizedBox(height: 14),
              InkWell(
                onTap: _busy ? null : _closeAllOthers,
                child: Text(
                  L.of(context).devTerminateAll,
                  style: TextStyle(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sessionRow(Map<String, dynamic> s) {
    final scheme = Theme.of(context).colorScheme;
    final current = _isCurrent(s);
    final id = _sessionId(s);
    final online = _isOnline(s);
    final l = L.of(context);
    final status = _statusText(context, s);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        current ? '${_title(s)} (${l.devCurrent})' : _title(s),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    const SizedBox(height: 3),
                    Text(_subtitle(s),
                        style: TextStyle(
                            color: scheme.onSurfaceVariant, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (status.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (online) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      status,
                      style: TextStyle(
                        color: online
                            ? const Color(0xFF34C759)
                            : scheme.onSurfaceVariant,
                        fontWeight:
                            online ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // Индивидуальное завершение сессии (кроме текущей).
          if (!current && id != null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: scheme.error,
                ),
                onPressed: _busy ? null : () => _closeOne(id, _title(s)),
                child: Text(l.devTerminate),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyView() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.devices_outlined, size: 48, color: scheme.outline),
          const SizedBox(height: 12),
          Text(L.of(context).devEmpty, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Не удалось загрузить сессии:\n$_error',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
