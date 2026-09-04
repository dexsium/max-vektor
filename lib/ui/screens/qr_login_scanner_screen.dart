import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../state/providers.dart';

/// Сканер входа по QR-коду.
///
/// Как в официальном приложении MAX: открывается на УЖЕ ЗАЛОГИНЕННОМ
/// аккаунте, сканирует QR со страницы входа другого устройства
/// (например web.max.ru) и авторизует тот вход через op 290 AUTH_QR_APPROVE.
///
/// Сам вход в Max Vektor это не заменяет — здесь мы подтверждающая сторона.
class QrLoginScannerScreen extends ConsumerStatefulWidget {
  const QrLoginScannerScreen({super.key});

  @override
  ConsumerState<QrLoginScannerScreen> createState() =>
      _QrLoginScannerScreenState();
}

class _QrLoginScannerScreenState extends ConsumerState<QrLoginScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _busy = false;
  String? _status;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_busy) return;
    final raw = capture.barcodes
        .map((b) => b.rawValue)
        .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
    if (raw == null) return;

    setState(() {
      _busy = true;
      _status = L.of(context).qrConfirming;
    });

    try {
      final client = ref.read(maxClientProvider);
      final resp = await client.approveQrLogin(raw);
      if (!mounted) return;
      setState(() => _status = L.of(context).qrDone);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) Navigator.of(context).pop(true);
      // resp намеренно не разбираем: серверный ответ уже в логах
      // ([MaxVektor][AUTH] QR approve ответ), по нему уточняется протокол.
      resp;
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _status = _humanError(e);
      });
      // Даём просканировать ещё раз после ошибки.
      await _controller.start();
    }
  }

  String _humanError(Object e) {
    final s = e.toString();
    final i = s.indexOf(': ');
    return i >= 0 ? s.substring(i + 2) : s;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L.of(context).settingsQrLogin)),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(controller: _controller, onDetect: _onDetect),
                // Рамка прицела.
                Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                if (_busy)
                  const Positioned(
                    bottom: 40,
                    child: CircularProgressIndicator(),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _status ?? L.of(context).qrHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
