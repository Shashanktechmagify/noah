import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small painted flag for [code] (IN, US, GB, AE, SG, AU). Drawn rather than
/// an emoji because Windows has no flag emoji font.
class Flag extends StatelessWidget {
  const Flag(this.code, {super.key, this.width = 26});

  final String code;
  final double width;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: width * 0.68,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(3),
      border: Border.all(color: Colors.black.withValues(alpha: 0.12)),
    ),
    clipBehavior: Clip.antiAlias,
    child: CustomPaint(painter: _FlagPainter(code)),
  );
}

class _FlagPainter extends CustomPainter {
  _FlagPainter(this.code);

  final String code;

  Paint _p(int argb) => Paint()..color = Color(argb);

  @override
  void paint(Canvas canvas, Size size) {
    switch (code) {
      case 'IN':
        _india(canvas, size);
      case 'US':
        _us(canvas, size);
      case 'GB':
        _uk(canvas, Offset.zero & size);
      case 'AE':
        _uae(canvas, size);
      case 'SG':
        _singapore(canvas, size);
      case 'AU':
        _australia(canvas, size);
      default:
        canvas.drawRect(Offset.zero & size, _p(0xFFCCCCCC));
    }
  }

  void _india(Canvas c, Size s) {
    final h = s.height / 3;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, h), _p(0xFFFF9933));
    c.drawRect(Rect.fromLTWH(0, h, s.width, h), _p(0xFFFFFFFF));
    c.drawRect(Rect.fromLTWH(0, 2 * h, s.width, h), _p(0xFF138808));
    c.drawCircle(
      Offset(s.width / 2, s.height / 2),
      h * 0.38,
      Paint()
        ..color = const Color(0xFF000080)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s.height * 0.045,
    );
  }

  void _us(Canvas c, Size s) {
    final h = s.height / 13;
    for (var i = 0; i < 13; i++) {
      c.drawRect(
        Rect.fromLTWH(0, i * h, s.width, h + 0.3),
        _p(i.isEven ? 0xFFB22234 : 0xFFFFFFFF),
      );
    }
    c.drawRect(Rect.fromLTWH(0, 0, s.width * 0.42, h * 7), _p(0xFF3C3B6E));
    final dot = _p(0xFFFFFFFF);
    for (var r = 0; r < 3; r++) {
      for (var k = 0; k < 4; k++) {
        c.drawCircle(
          Offset(s.width * (0.07 + k * 0.095), h * (1.4 + r * 2.1)),
          s.height * 0.028,
          dot,
        );
      }
    }
  }

  void _uk(Canvas c, Rect r) {
    c.save();
    c.clipRect(r);
    c.drawRect(r, _p(0xFF012169));
    final w = r.width;
    final h = r.height;
    Paint line(int argb, double width) => Paint()
      ..color = Color(argb)
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    // Diagonals: white, then thinner red.
    for (final (argb, wd) in [(0xFFFFFFFF, h * 0.2), (0xFFC8102E, h * 0.08)]) {
      c.drawLine(r.topLeft, r.bottomRight, line(argb, wd));
      c.drawLine(r.topRight, r.bottomLeft, line(argb, wd));
    }
    // Cross: white, then red.
    for (final (argb, f) in [(0xFFFFFFFF, 0.3), (0xFFC8102E, 0.17)]) {
      c.drawRect(
        Rect.fromLTWH(r.left, r.top + h * (1 - f) / 2, w, h * f),
        _p(argb),
      );
      c.drawRect(
        Rect.fromLTWH(r.left + w * (1 - f * 0.6) / 2, r.top, w * f * 0.6, h),
        _p(argb),
      );
    }
    c.restore();
  }

  void _uae(Canvas c, Size s) {
    final h = s.height / 3;
    c.drawRect(Rect.fromLTWH(0, 0, s.width, h), _p(0xFF00732F));
    c.drawRect(Rect.fromLTWH(0, h, s.width, h), _p(0xFFFFFFFF));
    c.drawRect(Rect.fromLTWH(0, 2 * h, s.width, h), _p(0xFF000000));
    c.drawRect(Rect.fromLTWH(0, 0, s.width * 0.28, s.height), _p(0xFFFF0000));
  }

  void _singapore(Canvas c, Size s) {
    c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height / 2), _p(0xFFEF3340));
    c.drawRect(
      Rect.fromLTWH(0, s.height / 2, s.width, s.height / 2),
      _p(0xFFFFFFFF),
    );
    // Crescent: a white disc with a red disc cut into it.
    final r = s.height * 0.2;
    final centre = Offset(s.width * 0.22, s.height * 0.25);
    c.drawCircle(centre, r, _p(0xFFFFFFFF));
    c.drawCircle(centre.translate(r * 0.4, 0), r * 0.85, _p(0xFFEF3340));
    final star = _p(0xFFFFFFFF);
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      c.drawCircle(
        Offset(s.width * 0.42, s.height * 0.25).translate(
          math.cos(a) * s.height * 0.12,
          math.sin(a) * s.height * 0.12,
        ),
        s.height * 0.03,
        star,
      );
    }
  }

  void _australia(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, _p(0xFF012169));
    _uk(c, Rect.fromLTWH(0, 0, s.width * 0.5, s.height * 0.5));
    final star = _p(0xFFFFFFFF);
    c.drawCircle(
      Offset(s.width * 0.25, s.height * 0.76),
      s.height * 0.09,
      star,
    );
    for (final o in const [
      Offset(0.72, 0.18),
      Offset(0.85, 0.42),
      Offset(0.62, 0.5),
      Offset(0.76, 0.82),
    ]) {
      c.drawCircle(
        Offset(s.width * o.dx, s.height * o.dy),
        s.height * 0.05,
        star,
      );
    }
  }

  @override
  bool shouldRepaint(_FlagPainter old) => old.code != code;
}
