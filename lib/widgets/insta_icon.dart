import 'package:flutter/material.dart';

/// The Noahgram glyph, drawn like Instagram's: a rounded square, a lens
/// circle and a small dot.
class InstaIcon extends StatelessWidget {
  const InstaIcon({super.key, this.size = 22, this.color = Colors.black});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _InstaPainter(color));
}

class _InstaPainter extends CustomPainter {
  _InstaPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.09;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(s * 0.07, s * 0.07, s * 0.86, s * 0.86),
        Radius.circular(s * 0.27),
      ),
      stroke,
    );
    canvas.drawCircle(Offset(s / 2, s / 2), s * 0.2, stroke);
    canvas.drawCircle(
      Offset(s * 0.745, s * 0.255),
      s * 0.055,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(_InstaPainter old) => old.color != color;
}
