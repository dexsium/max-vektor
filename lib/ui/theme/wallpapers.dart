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
              painter: _DoodlePainter(
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: child,
            )
          : child,
    );
  }
}

/// Космические дудлы по фону: искры-звёзды, планеты с кольцами, кометы, луны,
/// атомы, ракеты, спутники, созвездия. Собственный векторный рисунок (не
/// воспроизводит обои MAX), раскладывается по сетке со стабильным сидом —
/// поэтому не «прыгает» при перерисовке.
class _DoodlePainter extends CustomPainter {
  _DoodlePainter({required this.color});

  final Color color;

  late final Paint _stroke = Paint()
    ..color = color
    ..strokeWidth = 1.5
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;
  late final Paint _fill = Paint()..color = color;

  @override
  void paint(Canvas canvas, Size size) {
    const cell = 96.0;
    final cols = (size.width / cell).ceil() + 1;
    final rows = (size.height / cell).ceil() + 1;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final seed = (r * 73856093) ^ (c * 19349663) ^ 0x9E3779B9;
        final rnd = math.Random(seed);
        final cx = c * cell + rnd.nextDouble() * cell;
        final cy = r * cell + rnd.nextDouble() * cell;
        final rot = rnd.nextDouble() * math.pi * 2;
        final scale = 0.85 + rnd.nextDouble() * 0.5;
        canvas.save();
        canvas.translate(cx, cy);
        canvas.rotate(rot);
        canvas.scale(scale);
        _glyph(canvas, seed % 9, rnd);
        canvas.restore();
      }
    }
  }

  void _glyph(Canvas canvas, int kind, math.Random rnd) {
    switch (kind) {
      case 0:
        _sparkle(canvas, 9);
      case 1:
        _planet(canvas);
      case 2:
        _comet(canvas);
      case 3:
        _moon(canvas);
      case 4:
        _atom(canvas);
      case 5:
        _rocket(canvas);
      case 6:
        _satellite(canvas);
      case 7:
        _constellation(canvas, rnd);
      default:
        // Скопление мелких звёздочек-точек.
        for (var i = 0; i < 3; i++) {
          canvas.drawCircle(
              Offset((i - 1) * 6.0, (i.isEven ? -3 : 3).toDouble()),
              1.3, _fill);
        }
    }
  }

  /// Четырёхлучевая искра (звезда-вспышка).
  void _sparkle(Canvas canvas, double r) {
    final path = Path();
    const k = 0.28;
    path.moveTo(0, -r);
    path.quadraticBezierTo(k * r, -k * r, r, 0);
    path.quadraticBezierTo(k * r, k * r, 0, r);
    path.quadraticBezierTo(-k * r, k * r, -r, 0);
    path.quadraticBezierTo(-k * r, -k * r, 0, -r);
    path.close();
    canvas.drawPath(path, _fill);
  }

  void _planet(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 6, _stroke);
    canvas.save();
    canvas.rotate(-0.5);
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 22, height: 8), _stroke);
    canvas.restore();
  }

  void _comet(Canvas canvas) {
    canvas.drawCircle(const Offset(6, 6), 3, _fill);
    canvas.drawLine(const Offset(4, 4), const Offset(-8, -8), _stroke);
    canvas.drawLine(const Offset(6, 3), const Offset(-4, -8), _stroke);
    canvas.drawLine(const Offset(3, 6), const Offset(-8, -4), _stroke);
  }

  void _moon(Canvas canvas) {
    final path = Path()
      ..addArc(Rect.fromCircle(center: Offset.zero, radius: 8), 0.6, 4.2);
    canvas.drawPath(path, _stroke);
  }

  void _atom(Canvas canvas) {
    canvas.drawCircle(Offset.zero, 1.6, _fill);
    for (var i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(i * math.pi / 3);
      canvas.drawOval(
          Rect.fromCenter(center: Offset.zero, width: 22, height: 9), _stroke);
      canvas.restore();
    }
  }

  void _rocket(Canvas canvas) {
    final body = Path()
      ..moveTo(0, -10)
      ..quadraticBezierTo(6, -2, 4, 6)
      ..lineTo(-4, 6)
      ..quadraticBezierTo(-6, -2, 0, -10)
      ..close();
    canvas.drawPath(body, _stroke);
    canvas.drawCircle(const Offset(0, -2), 2, _stroke);
    canvas.drawLine(const Offset(-4, 6), const Offset(-7, 11), _stroke);
    canvas.drawLine(const Offset(4, 6), const Offset(7, 11), _stroke);
  }

  void _satellite(Canvas canvas) {
    canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: 6, height: 6), _stroke);
    canvas.drawRect(
        Rect.fromCenter(center: const Offset(-9, 0), width: 6, height: 10),
        _stroke);
    canvas.drawRect(
        Rect.fromCenter(center: const Offset(9, 0), width: 6, height: 10),
        _stroke);
    canvas.drawLine(const Offset(-3, 0), const Offset(-6, 0), _stroke);
    canvas.drawLine(const Offset(3, 0), const Offset(6, 0), _stroke);
  }

  void _constellation(Canvas canvas, math.Random rnd) {
    final pts = List.generate(
        4,
        (_) => Offset(
            (rnd.nextDouble() - 0.5) * 24, (rnd.nextDouble() - 0.5) * 24));
    for (var i = 0; i < pts.length - 1; i++) {
      canvas.drawLine(pts[i], pts[i + 1], _stroke);
    }
    for (final p in pts) {
      canvas.drawCircle(p, 1.4, _fill);
    }
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.color != color;
}
