import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

class _Slide {
  const _Slide(this.id, this.icon, this.colors);

  /// Prefix of the translation keys: `<id>_label`, `_title`, `_body`, `_cta`.
  final String id;
  final IconData icon;
  final List<Color> colors;
}

const _slides = [
  _Slide('s1', Icons.calendar_today_outlined,
      [Color(0xFF8E2BB8), Color(0xFFB62FC4)]),
  _Slide('s2', Icons.church_outlined, [Color(0xFF6A2DA8), Color(0xFF9B3BB8)]),
  _Slide('s3', Icons.groups_outlined, [Color(0xFFA0267F), Color(0xFFC7459C)]),
  _Slide('s4', Icons.volunteer_activism_outlined,
      [Color(0xFF5B34B0), Color(0xFF8C49C9)]),
  _Slide('s5', Icons.favorite_border, [Color(0xFF9A1FA8), Color(0xFFC13FBF)]),
];

/// Banner cards that scroll horizontally on their own, looping forever.
class EventCarousel extends StatefulWidget {
  const EventCarousel({
    super.key,
    this.interval = const Duration(seconds: 4),
  });

  final Duration interval;

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  // Start deep into an unbounded list so the user can swipe either way.
  static const _start = 5000;
  late final PageController _controller =
      PageController(initialPage: _start - _start % _slides.length);
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!_controller.hasClients) return;
      final next = (_controller.page ?? _controller.initialPage).round() + 1;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          // Pause auto-scroll while the user is dragging, resume afterwards.
          child: NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (n is ScrollStartNotification && n.dragDetails != null) {
                _timer?.cancel();
              } else if (n is ScrollEndNotification) {
                _startAutoScroll();
              }
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _index = i % _slides.length),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _SlideCard(slide: _slides[i % _slides.length]),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: active ? 20 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFB02BC8)
                    : const Color(0xFFCFD2E6),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: slide.colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -40,
              top: -50,
              child: _Blob(size: 170, alpha: 0.10),
            ),
            Positioned(
              right: 40,
              bottom: -60,
              child: _Blob(size: 120, alpha: 0.08),
            ),
            Positioned(
              right: 22,
              top: 40,
              child: Icon(slide.icon,
                  size: 52, color: Colors.white.withValues(alpha: 0.35)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr(context, '${slide.id}_label'),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: spacing(context, 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr(context, '${slide.id}_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tr(context, '${slide.id}_body'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.95),
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          tr(context, '${slide.id}_cta'),
                          style: const TextStyle(
                            color: Color(0xFF8E1FB0),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.chevron_right,
                            size: 16, color: Color(0xFF8E1FB0)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.alpha});

  final double size;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: alpha),
        ),
      );
}
