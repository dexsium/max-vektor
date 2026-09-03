import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Обои чата: градиентный фон + собственный лёгкий паттерн (не арт MAX).
class ChatWallpaper {
  const ChatWallpaper({
    required this.id,
    required this.name,
    required this.colors,
    this.pattern = true,
  });

  final String id;
  final String name;

  /// Цвета вертикального градиента фона.
  final List<Color> colors;

  /// Рисовать ли лёгкий паттерн (звёздочки/точки) поверх градиента.
  final bool pattern;
}

/// Категория «Космос» — тёмные градиенты с ненавязчивым звёздным паттерном.
/// Рисунок собственный (точки, крестики, кольца), не воспроизводит обои MAX.
const List<ChatWallpaper> kChatWallpapers = [
  ChatWallpaper(
      id: 'cosmos_blue',
      name: 'Космос',
      colors: [Color(0xFF0E1330), Color(0xFF141A38)]),
  ChatWallpaper(
      id: 'cosmos_teal',
      name: 'Небула',
      colors: [Color(0xFF0A1F24), Color(0xFF0E2A2E)]),
  ChatWallpaper(
      id: 'cosmos_rose',
      name: 'Заря',
      colors: [Color(0xFF241019), Color(0xFF301322)]),
  ChatWallpaper(
      id: 'cosmos_green',
      name: 'Аврора',
      colors: [Color(0xFF0C2016), Color(0xFF102A1C)]),
  ChatWallpaper(
      id: 'cosmos_violet',
      name: 'Туманность',
      colors: [Color(0xFF1A1030), Color(0xFF241442)]),
  ChatWallpaper(
      id: 'plain',
      name: 'Без узора',
      colors: [Color(0xFF11151C), Color(0xFF11151C)],
      pattern: false),
];

ChatWallpaper wallpaperById(String id) =>
    kChatWallpapers.firstWhere((w) => w.id == id,
        orElse: () => kChatWallpapers.first);

/// Фон чата с выбранными обоями. Оборачивает содержимое ленты.
class WallpaperBackground extends StatelessWidget {
  const WallpaperBackground({
    super.key,
    required this.wallpaper,
    required this.child,
  });

  final ChatWallpaper wallpaper;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: wallpaper.colors,
        ),
      ),
      child: wallpaper.pattern
          ? CustomPaint(
              painter: _StarPatternPainter(
                color: Colors.white.withValues(alpha: 0.05),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Ненавязчивый звёздный паттерн: точки, крестики и кольца по сетке со
/// стабильным псевдослучайным смещением. Собственный рисунок.
class _StarPatternPainter extends CustomPainter {
  _StarPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final fill = Paint()..color = color;
    const cell = 64.0;
    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final seed = (r * 73856093) ^ (c * 19349663);
        final rnd = math.Random(seed);
        final cx = c * cell + rnd.nextDouble() * cell;
        final cy = r * cell + rnd.nextDouble() * cell;
        switch (seed & 3) {
          case 0: // точка
            canvas.drawCircle(Offset(cx, cy), 1.6, fill);
          case 1: // крестик
            canvas.drawLine(Offset(cx - 4, cy), Offset(cx + 4, cy), paint);
            canvas.drawLine(Offset(cx, cy - 4), Offset(cx, cy + 4), paint);
          case 2: // кольцо
            canvas.drawCircle(Offset(cx, cy), 4, paint);
          default: // маленькая точка
            canvas.drawCircle(Offset(cx, cy), 1.0, fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StarPatternPainter old) => old.color != color;
}
