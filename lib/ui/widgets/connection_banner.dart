import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/max/max_client.dart';
import '../../state/connection_controller.dart';

/// Узкий баннер, который виден когда транспорт не в `connected`.
class ConnectionBanner extends ConsumerWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(connectionStateProvider);
    final state = stateAsync.value ?? MaxConnectionState.disconnected;
    if (state == MaxConnectionState.connected) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    final (label, showSpinner) = switch (state) {
      MaxConnectionState.connecting => (L.of(context).connConnecting, true),
      MaxConnectionState.reconnecting => (L.of(context).connReconnecting, true),
      MaxConnectionState.disconnected => (L.of(context).connNoConnection, false),
      MaxConnectionState.connected => ('', false),
    };
    return Material(
      color: scheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showSpinner) ...[
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(scheme.onErrorContainer),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: scheme.onErrorContainer,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
