import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../data/api_client.dart';
import '../data/noahgram_data.dart';
import '../data/profile_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';

DateTime? _lastShown;

/// True when today is the member's birthday (their date of birth, day and month; 29 February is kept on 28 February in other years).
bool isBirthdayToday([DateTime? now]) {
  final today = now ?? DateTime.now();
  final dob = DateTime.tryParse(profile.get('dob'));
  if (dob == null) return false;
  if (dob.month == today.month && dob.day == today.day) return true;
  final leap =
      (today.year % 4 == 0 && today.year % 100 != 0) || today.year % 400 == 0;
  return dob.month == 2 &&
      dob.day == 29 &&
      !leap &&
      today.month == 2 &&
      today.day == 28;
}

/// The name the greeting uses: the first name, but not a title or "Jr" (then the middle name: "Jr Ayush Jain" is Ayush).
String _callName() {
  const skip = {
    'jr',
    'sr',
    'mr',
    'mrs',
    'ms',
    'miss',
    'dr',
    'master',
    'rev',
    'pastor',
  };
  for (final k in ['first_name', 'middle_name', 'last_name']) {
    final v = profile.get(k).trim();
    if (v.isNotEmpty && !skip.contains(v.toLowerCase().replaceAll('.', ''))) {
      return v.split(' ').first;
    }
  }
  return noahgram.me.name.split(' ').first;
}

/// On the member's birthday, as soon as the app opens: the birthday song, falling confetti and the greeting. Shown again
/// when the app is opened again later in the day (not more often than every 20 minutes). Also asks the server to send the
/// birthday notification, if it has not been sent yet.
Future<void> maybeCelebrateBirthday(BuildContext context) async {
  // The demo (no server) has a sample profile: it never celebrates.
  if (!liveApi || !isBirthdayToday()) return;
  final last = _lastShown;
  if (last != null && DateTime.now().difference(last).inMinutes < 20) return;
  _lastShown = DateTime.now();
  if (api.signedIn) {
    api.sendBirthdayWish().catchError((_) => <String, dynamic>{});
  }
  if (!context.mounted) return;
  final name = _callName();
  await Navigator.of(context, rootNavigator: true).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (_, _, _) => _BirthdayPage(name: name),
      transitionsBuilder: (_, a, _, child) =>
          FadeTransition(opacity: a, child: child),
    ),
  );
}

class _BirthdayPage extends StatefulWidget {
  const _BirthdayPage({required this.name});

  final String name;

  @override
  State<_BirthdayPage> createState() => _BirthdayPageState();
}

class _BirthdayPageState extends State<_BirthdayPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 7),
  )..repeat();
  FlutterTts? _tts;

  @override
  void initState() {
    super.initState();
    // After the first frame, so the language of the app is known.
    WidgetsBinding.instance.addPostFrameCallback((_) => _speak());
  }

  /// The greeting is read aloud by the phone's own voice, in the language of the app (English when the phone has no voice for it):
  /// "On behalf of Karuna Sadan, we wish you a happy birthday."
  Future<void> _speak() async {
    if (!mounted) return;
    final text = tr(context, 'bday_speech', args: {'name': widget.name});
    final lang = AppLocale.of(context).lang;
    try {
      final tts = FlutterTts();
      _tts = tts;
      const codes = {
        AppLang.hi: 'hi-IN',
        AppLang.mr: 'mr-IN',
        AppLang.ta: 'ta-IN',
      };
      final code = codes[lang] ?? 'en-IN';
      final ok = await tts.isLanguageAvailable(code);
      await tts.setLanguage(ok == true ? code : 'en-IN');
      await tts.setSpeechRate(0.42);
      await tts.setVolume(1);
      await tts.speak(
        ok == true
            ? text
            : trIn(AppLang.en, 'bday_speech').replaceAll('{name}', widget.name),
      );
    } catch (_) {
      // No voice on this device: the greeting still shows.
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _tts?.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) =>
                  CustomPaint(painter: _ConfettiPainter(_c.value)),
            ),
          ),
        ),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.6, end: 1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 28),
              padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 30),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFA719C8), Color(0xFFE0409A)],
                      ),
                    ),
                    child: const Icon(
                      Icons.cake_rounded,
                      color: Colors.white,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr(context, 'bday_title', args: {'name': widget.name}),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'bday_congrats'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.magenta,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr(context, 'bday_wish'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      tr(context, 'bday_thanks'),
                      style: const TextStyle(
                        color: AppColors.magenta,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Pieces of paper falling from the top, turning as they fall. The same pieces every frame; only the time moves.
class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.t);

  final double t;

  static const _colors = [
    Color(0xFFA719C8),
    Color(0xFFE0409A),
    Color(0xFFFFC53D),
    Color(0xFF2E9D5B),
    Color(0xFF3B82F6),
    Color(0xFFFF7A45),
  ];
  static final _pieces = List.generate(110, (i) {
    final r = math.Random(i * 7919 + 13);
    return (
      x: r.nextDouble(),
      speed: 0.6 + r.nextDouble() * 0.9,
      offset: r.nextDouble(),
      sway: 10 + r.nextDouble() * 26,
      spin: (r.nextDouble() - 0.5) * 14,
      w: 6.0 + r.nextDouble() * 7,
      h: 9.0 + r.nextDouble() * 9,
      color: _colors[r.nextInt(_colors.length)],
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _pieces) {
      final f = (t * p.speed + p.offset) % 1.0;
      final y = -20 + f * (size.height + 40);
      final x =
          p.x * size.width +
          math.sin(f * 2 * math.pi * 2 + p.offset * 6) * p.sway;
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(f * p.spin);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.w, height: p.h),
          const Radius.circular(2),
        ),
        Paint()..color = p.color,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
