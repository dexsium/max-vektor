import 'package:flutter/material.dart';

/// Знак Max Vektor — буква «V».
///
/// Та же геометрия, что у иконки приложения (`tool_gen_icon.py`), поэтому
/// экран входа и иконка на домашнем экране выглядят как одно целое.
/// Собственный знак, без элементов брендинга официального MAX.
class VektorMark extends StatelessWidget {
  const VektorMark({super.key, this.size = 72});

  final double size;

  /// Полигон буквы «V» в долях стороны квадрата.
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
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.2237),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10141C), Color(0xFF1A2130)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.28),
            blurRadius: size * 0.35,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: CustomPaint(painter: _GlyphPainter()),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    for (var i = 0; i < VektorMark._glyph.length; i++) {
      final p = VektorMark._glyph[i];
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
