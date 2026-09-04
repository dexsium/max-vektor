import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
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
        title: Text(L.of(context).settingsDiagnostics),
        actions: [
          IconButton(
            tooltip: L.of(context).commonRefresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            tooltip: L.of(context).commonClear,
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
              L.of(context).diagHint('${MvLogBuffer.length}'),
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
                  text.isEmpty ? L.of(context).diagEmpty : text,
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
                label: Text(L.of(context).diagCopyAll),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    AppSnack.show(context, L.of(context).diagCopied,
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
