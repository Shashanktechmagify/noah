import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_strings.dart';
import '../screens/main_shell.dart' show ShellScope;

class _Slide {
  const _Slide(this.id, this.icon, this.colors);

  /// Prefix of the translation keys: `<id>_label`, `_title`, `_body`, `_cta`.
  final String id;
  final IconData icon;
  final List<Color> colors;
}

/// One card of the home carousel made from what the office wrote in the console: a banner (a picture and a caption) or
/// an announcement (a title, a message and a link). A card with a [url] has a button that opens it.
class HomeSlide {
  const HomeSlide({
    this.label = '',
    required this.title,
    this.body = '',
    this.cta = '',
    this.image,
    this.url,
    this.icon = Icons.campaign_outlined,
  });

  final String label;
  final String title;
  final String body;

  /// The words on the button (shown only with a [url]).
  final String cta;

  /// A picture that fills the card (a banner).
  final String? image;
  final String? url;
  final IconData icon;
}

/// Every announcement card uses the same colours.
const _cardColors = [Color(0xFF5B63F0), Color(0xFFD94FB7)];

const _slides = [
  _Slide('a0', Icons.confirmation_number_outlined, _cardColors),
  _Slide('s1', Icons.calendar_today_outlined, _cardColors),
  _Slide('s2', Icons.church_outlined, _cardColors),
  _Slide('s3', Icons.groups_outlined, _cardColors),
  _Slide('s4', Icons.volunteer_activism_outlined, _cardColors),
  _Slide('s5', Icons.favorite_border, _cardColors),
];

/// Cards sway gently on their own so they feel alive on phones too. Tests
/// switch this off because a forever-running animation never "settles".
bool enableCardIdleSway = true;

/// Banner cards that scroll horizontally on their own, looping forever.
class EventCarousel extends StatefulWidget {
  const EventCarousel({
    super.key,
    this.interval = const Duration(seconds: 4),
    this.slides,
  });

  final Duration interval;

  /// The office's banners and announcements. Without them the sample cards are shown.
  final List<HomeSlide>? slides;

  @override
  State<EventCarousel> createState() => _EventCarouselState();
}

class _EventCarouselState extends State<EventCarousel> {
  // Start deep into an unbounded list so the user can swipe either way.
  static const _start = 5000;
  int get _count => widget.slides?.length ?? _slides.length;
  late final PageController _controller = PageController(
    initialPage: _start - _start % _count.clamp(1, 1 << 20),
  );
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
    final live = widget.slides;
    if (_count == 0) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 218,
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
              clipBehavior: Clip.none,
              onPageChanged: (i) => setState(() => _index = i % _count),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: _Hover(
                  // A card from the office opens its link; a sample card opens the Events tab.
                  onTap: () {
                    if (live == null) {
                      ShellScope.maybeOf(context)?.selectSlot(3);
                    } else {
                      final url = live[i % live.length].url;
                      if (url != null) openHomeLink(context, url);
                    }
                  },
                  builder: (lifted, tilt) => _SlideCard(
                    slide: live == null ? _slides[i % _slides.length] : null,
                    office: live == null ? null : live[i % live.length],
                    lifted: lifted,
                    tilt: tilt,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_count, (i) {
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

/// 3D interaction: the card tilts towards the pointer (mouse hover or a touch
/// drag) with perspective, grows slightly and deepens its shadow. With no
/// pointer it sways gently. Tapping it opens the Events tab.
class _Hover extends StatefulWidget {
  const _Hover({required this.builder, required this.onTap});

  /// [tilt] is -1..1 on each axis (x right, y down).
  final Widget Function(bool lifted, Offset tilt) builder;
  final VoidCallback onTap;

  @override
  State<_Hover> createState() => _HoverState();
}

class _HoverState extends State<_Hover> with SingleTickerProviderStateMixin {
  AnimationController? _sway;
  Offset _target = Offset.zero;
  Offset _tilt = Offset.zero;
  bool _hover = false;
  bool _down = false;
  Size _size = Size.zero;

  bool get _active => _hover || _down;

  @override
  void initState() {
    super.initState();
    if (enableCardIdleSway) {
      _sway = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 7),
      )..repeat();
      _sway!.addListener(_step);
    }
  }

  /// Eases the tilt towards the pointer (or the idle sway) every frame.
  void _step() {
    final goal = _active
        ? _target
        : Offset(
            math.sin(_sway!.value * 2 * math.pi) * 0.35,
            math.cos(_sway!.value * 2 * math.pi) * 0.2,
          );
    setState(() => _tilt = Offset.lerp(_tilt, goal, 0.12)!);
  }

  @override
  void dispose() {
    _sway?.dispose();
    super.dispose();
  }

  void _point(Offset local) {
    if (_size.isEmpty) return;
    final t = Offset(
      (local.dx / _size.width * 2 - 1).clamp(-1.0, 1.0),
      (local.dy / _size.height * 2 - 1).clamp(-1.0, 1.0),
    );
    if (_sway == null) {
      setState(() => _tilt = t); // no ticker: follow the pointer directly
    }
    _target = t;
  }

  void _release() {
    setState(() {
      _down = false;
      if (!_hover) _target = Offset.zero;
      if (_sway == null && !_hover) _tilt = Offset.zero;
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      _size = box.biggest;
      final scale = _down
          ? 0.98
          : _hover
          ? 1.03
          : 1.0;
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() {
          _hover = false;
          _target = Offset.zero;
          if (_sway == null) _tilt = Offset.zero;
        }),
        onHover: (e) => _point(e.localPosition),
        child: Listener(
          onPointerDown: (e) {
            setState(() => _down = true);
            _point(e.localPosition);
          },
          onPointerMove: (e) => _point(e.localPosition),
          onPointerUp: (_) => _release(),
          onPointerCancel: (_) => _release(),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedScale(
              scale: scale,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0011) // perspective
                  ..rotateX(-_tilt.dy * 0.16)
                  ..rotateY(_tilt.dx * 0.2),
                child: widget.builder(_active, _tilt),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    this.slide,
    this.office,
    this.lifted = false,
    this.tilt = Offset.zero,
  });

  /// A sample card (its words are translation keys), or a card from the office.
  final _Slide? slide;
  final HomeSlide? office;
  final bool lifted;
  final Offset tilt;

  List<Color> get _colors => slide?.colors ?? _cardColors;
  IconData get _icon => slide?.icon ?? office!.icon;
  String _label(BuildContext c) => slide != null ? tr(c, '${slide!.id}_label') : office!.label;
  String _title(BuildContext c) => slide != null ? tr(c, '${slide!.id}_title') : office!.title;
  String _body(BuildContext c) => slide != null ? tr(c, '${slide!.id}_body') : office!.body;

  /// The words on the button; a card from the office has one only when it has a link.
  String _cta(BuildContext c) => slide != null
      ? tr(c, '${slide!.id}_cta')
      : (office!.url == null ? '' : office!.cta);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A0A55)
                .withValues(alpha: lifted ? 0.55 : 0.40),
            blurRadius: lifted ? 32 : 22,
            offset: Offset(-tilt.dx * 14, (lifted ? 16 : 10) - tilt.dy * 6),
          ),
        ],
      ),
      // Light rim so the card never melts into the purple header band.
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _colors,
            ),
          ),
          child: Stack(
            children: [
              // A banner's picture fills the card, under a shade so the words can be read.
              if (office?.image != null) ...[
                Positioned.fill(
                  child: Image.network(
                    office!.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                const Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xCC000000)],
                      ),
                    ),
                  ),
                ),
              ],
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
              if (office?.image == null)
                Positioned(
                  right: 22 - tilt.dx * 16,
                  top: 40 + tilt.dy * 10,
                  child: Icon(
                    _icon,
                    size: 52,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              // Light sheen that slides across the card as it tilts.
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment(tilt.dx, tilt.dy),
                        radius: 0.9,
                        colors: [
                          Colors.white.withValues(alpha: lifted ? 0.22 : 0.12),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_label(context).isNotEmpty)
                    Text(
                      _label(context),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: spacing(context, 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _title(context),
                      maxLines: office?.image != null ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_body(context).isNotEmpty)
                    Text(
                      _body(context),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    if (_cta(context).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _cta(context),
                            style: const TextStyle(
                              color: Color(0xFF8E1FB0),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: Color(0xFF8E1FB0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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

/// Opens a card's link in the browser (or the app it belongs to); the address itself is shown if the phone cannot.
Future<void> openHomeLink(BuildContext context, String url) async {
  var ok = false;
  try {
    ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    ok = false;
  }
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(url)));
  }
}
