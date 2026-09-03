import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../../data/max/models/attach.dart';

/// Голосовое/аудио сообщение: круглая кнопка play/pause, волна с прогрессом,
/// таймер. Воспроизведение — audioplayers (AVPlayer на iOS). Источник:
/// локальный файл (если скачан) или прямая ссылка attach.downloadUrl.
class VoiceMessage extends StatefulWidget {
  const VoiceMessage({super.key, required this.attach, required this.width});

  final MaxAttach attach;
  final double width;

  @override
  State<VoiceMessage> createState() => _VoiceMessageState();
}

class _VoiceMessageState extends State<VoiceMessage> {
  final _player = AudioPlayer();
  Duration _pos = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.attach.durationMs;
    if (d != null) _total = Duration(milliseconds: d);
    _player.onPositionChanged.listen((p) {
      if (mounted) setState(() => _pos = p);
    });
    _player.onDurationChanged.listen((d) {
      if (mounted && d > Duration.zero) setState(() => _total = d);
    });
    _player.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _playing = false;
          _pos = Duration.zero;
        });
      }
    });
    _player.onPlayerStateChanged.listen((s) {
      if (mounted) setState(() => _playing = s == PlayerState.playing);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String? get _source {
    final local = widget.attach.localPath;
    if (local != null && local.isNotEmpty && File(local).existsSync()) {
      return local;
    }
    final url = widget.attach.downloadUrl;
    return (url != null && url.isNotEmpty) ? url : null;
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player.pause();
      return;
    }
    final src = _source;
    if (src == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Аудио недоступно')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final isLocal = File(src).existsSync();
      await _player.play(isLocal ? DeviceFileSource(src) : UrlSource(src));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось воспроизвести аудио')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final progress = _total.inMilliseconds == 0
        ? 0.0
        : (_pos.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0);
    final shown = _playing || _pos > Duration.zero ? _pos : _total;

    return SizedBox(
      width: widget.width,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Row(
          children: [
            InkWell(
              onTap: _loading ? null : _toggle,
              customBorder: const CircleBorder(),
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: _loading
                    ? const Padding(
                        padding: EdgeInsets.all(11),
                        child: CircularProgressIndicator(
                            strokeWidth: 2.4, color: Colors.white),
                      )
                    : Icon(_playing ? Icons.pause : Icons.play_arrow,
                        color: Colors.white, size: 26),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  LayoutBuilder(
                    builder: (_, constraints) {
                      _lastWidth = constraints.maxWidth;
                      return GestureDetector(
                        onTapDown: (d) => _seekByTap(d.localPosition.dx),
                        child: SizedBox(
                          height: 28,
                          child: CustomPaint(
                            size: Size(constraints.maxWidth, 28),
                            painter: _WaveformPainter(
                              bars: _bars(),
                              progress: progress,
                              played: scheme.primary,
                              rest: scheme.onSurfaceVariant
                                  .withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _fmt(shown),
                    style: TextStyle(
                        color: scheme.onSurfaceVariant, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _lastWidth = 200;

  void _seekByTap(double dx) {
    if (_total.inMilliseconds == 0) return;
    final frac = (dx / _lastWidth).clamp(0.0, 1.0);
    _player.seek(Duration(milliseconds: (_total.inMilliseconds * frac).round()));
  }

  /// Нормализованные высоты столбиков волны (0..1). Из waveform сервера, иначе
  /// стабильный псевдо-паттерн по длительности — визуально как в оригинале.
  List<double> _bars() {
    const count = 40;
    final wf = widget.attach.waveform;
    if (wf != null && wf.isNotEmpty) {
      final maxV = wf.reduce(math.max).clamp(1, 1 << 30);
      final step = wf.length / count;
      return List.generate(count, (i) {
        final v = wf[(i * step).floor().clamp(0, wf.length - 1)];
        return (v / maxV).clamp(0.08, 1.0);
      });
    }
    final seed = widget.attach.durationMs ?? widget.attach.fileId ?? 7;
    final rnd = math.Random(seed);
    return List.generate(count, (_) => 0.2 + rnd.nextDouble() * 0.8);
  }

  static String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.played,
    required this.rest,
  });

  final List<double> bars;
  final double progress;
  final Color played;
  final Color rest;

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    const gap = 2.0;
    final barW = (size.width - gap * (bars.length - 1)) / bars.length;
    final mid = size.height / 2;
    final playedBars = (bars.length * progress).round();
    for (var i = 0; i < bars.length; i++) {
      final h = (bars[i] * size.height).clamp(3.0, size.height);
      final x = i * (barW + gap);
      final paint = Paint()
        ..color = i < playedBars ? played : rest
        ..strokeWidth = barW
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(x + barW / 2, mid - h / 2),
          Offset(x + barW / 2, mid + h / 2), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) =>
      old.progress != progress || old.bars != bars;
}
