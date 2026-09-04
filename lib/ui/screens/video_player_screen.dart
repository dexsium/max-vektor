import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../state/media_prefs_controller.dart';

/// Полноэкранный плеер видео (нативный: AVPlayer на iOS, ExoPlayer на
/// Android). Открывается по тапу на видео-вложение.
///
/// Логика как в официальном приложении: тап по превью → плеер, тап по
/// экрану переключает play/pause, снизу — прогресс и время.
class VideoPlayerScreen extends ConsumerStatefulWidget {
  const VideoPlayerScreen({super.key, required this.url, this.title});

  /// Прямая ссылка на поток (videoUrl из attach) — MP4 или HLS.
  final String url;
  final String? title;

  @override
  ConsumerState<VideoPlayerScreen> createState() =>
      _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends ConsumerState<VideoPlayerScreen> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _ready = true);
        _maybeAutoplay();
      }).catchError((Object e) {
        if (!mounted) return;
        setState(() => _error = L.of(context).videoError);
      });
    _controller.addListener(_tick);
  }

  void _tick() {
    if (mounted) setState(() {});
  }

  /// Автозапуск с учётом режима «Экономии» и реального типа сети:
  /// «Всегда» — всегда; «По Wi-Fi» — только на Wi-Fi/Ethernet;
  /// «Никогда» — открываем на паузе (тап запускает).
  Future<void> _maybeAutoplay() async {
    final mode = ref.read(mediaPrefsProvider).videoAutoplay;
    if (mode == MediaAuto.never) return;
    final onWifi = mode == MediaAuto.wifi ? await isOnWifi() : true;
    if (!mounted) return;
    if (shouldAutoLoad(mode, onWifi: onWifi)) _controller.play();
  }

  @override
  void dispose() {
    _controller.removeListener(_tick);
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? L.of(context).videoTitle),
      ),
      body: Center(
        child: _error != null
            ? Text(_error!, style: const TextStyle(color: Colors.white70))
            : !_ready
                ? const CircularProgressIndicator()
                : GestureDetector(
                    onTap: _togglePlay,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                        if (!_controller.value.isPlaying)
                          const Icon(Icons.play_arrow,
                              size: 72, color: Colors.white70),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _Controls(controller: _controller),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.controller});

  final VideoPlayerController controller;

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final v = controller.value;
    return Container(
      color: Colors.black.withValues(alpha: 0.35),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(_fmt(v.position),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
          Expanded(
            child: VideoProgressIndicator(
              controller,
              allowScrubbing: true,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              colors: const VideoProgressColors(
                playedColor: Color(0xFF2E7DF0),
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white24,
              ),
            ),
          ),
          Text(_fmt(v.duration),
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
