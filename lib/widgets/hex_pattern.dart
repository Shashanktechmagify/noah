import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Faint honeycomb outline used behind the purple headers.
class HexPatternPainter extends CustomPainter {
  HexPatternPainter({this.opacity = 0.10, this.radius = 34});

  final double opacity;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final w = math.sqrt(3) * radius;
    final h = 1.5 * radius;
    for (var row = -1; row * h < size.height + radius; row++) {
      for (var col = -1; col * w < size.width + w; col++) {
        final cx = col * w + (row.isOdd ? w / 2 : 0);
        final cy = row * h;
        final path = Path();
        for (var i = 0; i < 6; i++) {
          final a = math.pi / 180 * (60 * i - 30);
          final p = Offset(cx + radius * math.cos(a), cy + radius * math.sin(a));
          i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(HexPatternPainter old) =>
      old.opacity != opacity || old.radius != radius;
}

class HexPattern extends StatelessWidget {
  const HexPattern({super.key, this.opacity = 0.10});

  final double opacity;

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: CustomPaint(
          painter: HexPatternPainter(opacity: opacity),
          size: Size.infinite,
        ),
      );
}
