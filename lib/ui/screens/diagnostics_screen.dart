import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/logging.dart';
import '../widgets/app_snack.dart';

/// Экран диагностики: показывает последние строки лога приложения
/// ([MvLogBuffer]) и даёт их скопировать. Нужен, чтобы снять логи с
/// физического iPhone (к Xcode-консоли release-сборку не подключить).
class DiagnosticsScreen extends StatefulWidget {
  const DiagnosticsScreen({super.key});

  @override
  State<DiagnosticsScreen> createState() => _DiagnosticsScreenState();
}

class _DiagnosticsScreenState extends State<DiagnosticsScreen> {
  @override
  Widget build(BuildContext context) {
    final text = MvLogBuffer.dump();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Диагностика'),
        actions: [
          IconButton(
            tooltip: 'Обновить',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            tooltip: 'Очистить',
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              MvLogBuffer.clear();
              setState(() {});
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Логи соединения и протокола (${MvLogBuffer.length} строк). '
              'Токены и коды не записываются. Скопируйте и пришлите для '
              'разбора проблемы.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  text.isEmpty ? 'Логов пока нет.' : text,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.copy_all),
                label: const Text('Скопировать всё'),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    AppSnack.show(context, 'Логи скопированы',
                        icon: Icons.check);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
