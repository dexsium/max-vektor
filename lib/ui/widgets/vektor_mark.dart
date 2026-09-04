import 'package:flutter/material.dart';

/// Знак Vektor — глянцевая буква «V» (ассет из assets/brand/v_logo.png).
///
/// Тот же логотип, что в иконке приложения. Если ассет по какой-то причине не
/// загрузился, рисуем векторный запасной знак того же силуэта.
class VektorMark extends StatelessWidget {
  const VektorMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/brand/v_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _FallbackMark(size: size),
    );
  }
}

/// Векторный запасной знак «V» (на случай отсутствия ассета).
class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.size});
  final double size;

  static const List<Offset> _glyph = [
    Offset(0.185, 0.255),
    Offset(0.350, 0.255),
    Offset(0.500, 0.605),
    Offset(0.650, 0.255),
    Offset(0.815, 0.255),
    Offset(0.500, 0.775),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GlyphPainter()),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < _FallbackMark._glyph.length; i++) {
      final p = _FallbackMark._glyph[i];
      final point = Offset(p.dx * size.width, p.dy * size.height);
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();

    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF56CDFF), Color(0xFF2563EB)],
      ).createShader(Offset.zero & size)
      ..isAntiAlias = true;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
