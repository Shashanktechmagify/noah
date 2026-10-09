import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../noahgram/noahgram_widgets.dart' show LookCanvas;
import 'chat_screen.dart';
import 'jodie_widgets.dart';
import 'profile_detail.dart';

enum _Swipe { pass, like, superLike }

/// Tinder-style stack: drag right to like, left to pass, up to Super Like.
class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fly = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  Offset _drag = Offset.zero;
  Offset _from = Offset.zero;
  Offset _to = Offset.zero;
  bool _flying = false;
  Size _area = const Size(360, 520);
  final _photo = <String, int>{};

  Offset get _offset => _flying
      ? Offset.lerp(_from, _to, Curves.easeOut.transform(_fly.value))!
      : _drag;

  @override
  void dispose() {
    _fly.dispose();
    super.dispose();
  }

  void _animate(Offset to, [VoidCallback? done]) {
    _from = _offset;
    _to = to;
    _flying = true;
    _fly.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      setState(() {
        _flying = false;
        _drag = Offset.zero;
      });
      done?.call();
    });
  }

  void _decide(_Swipe s) {
    if (_flying) return;
    final deck = jodie.deck;
    if (deck.isEmpty) return;
    final top = deck.first;
    if (s == _Swipe.superLike && !jodie.canAfford(kSuperLikeCost)) {
      _animate(Offset.zero);
      toast(context, tr(context, 'jd_not_enough'));
      showCreditsSheet(context);
      return;
    }
    final target = switch (s) {
      _Swipe.like => Offset(_area.width * 1.5, _drag.dy),
      _Swipe.pass => Offset(-_area.width * 1.5, _drag.dy),
      _Swipe.superLike => Offset(0, -_area.height * 1.3),
    };
    _animate(target, () => _commit(s, top));
  }

  void _commit(_Swipe s, JodieProfile top) {
    var matched = false;
    switch (s) {
      case _Swipe.pass:
        jodie.pass(top);
      case _Swipe.like:
        matched = jodie.like(top);
      case _Swipe.superLike:
        jodie.spend(kSuperLikeCost);
        matched = jodie.like(top, superLike: true);
        if (!matched && mounted) toast(context, tr(context, 'jd_sent_super'));
    }
    if (matched && mounted) {
      final match = jodie.matches.first;
      showMatchDialog(context, top,
          onMessage: () => openChat(context, match));
    }
  }

  void _onPanEnd(DragEndDetails d) {
    if (_flying) return;
    final v = d.velocity.pixelsPerSecond;
    if (_drag.dx > _area.width * 0.28 || v.dx > 900) {
      _decide(_Swipe.like);
    } else if (_drag.dx < -_area.width * 0.28 || v.dx < -900) {
      _decide(_Swipe.pass);
    } else if (_drag.dy < -_area.height * 0.22 && _drag.dx.abs() < 90) {
      _decide(_Swipe.superLike);
    } else {
      _animate(Offset.zero);
    }
  }

  void _openDetail(JodieProfile p) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => JodieProfileScreen(
        profile: p,
        onLike: () => _decide(_Swipe.like),
        onPass: () => _decide(_Swipe.pass),
      ),
    ));
  }

  void _boost() {
    if (jodie.isBoosted) {
      toast(context, tr(context, 'jd_boost_on'));
    } else if (jodie.boost()) {
      toast(context, tr(context, 'jd_boost_on'));
    } else {
      toast(context, tr(context, 'jd_not_enough'));
      showCreditsSheet(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: jodie,
      builder: (context, _) {
        final deck = jodie.deck;
        return Column(
          children: [
            Expanded(
              child: deck.isEmpty
                  ? _Empty(onFilters: () => showFiltersSheet(context))
                  : LayoutBuilder(builder: (context, c) {
                      _area = Size(c.maxWidth - 24, c.maxHeight - 12);
                      final count = deck.length < 3 ? deck.length : 3;
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (var i = count - 1; i >= 0; i--)
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                child: i == 0
                                    ? _topCard(deck.first)
                                    : Transform.translate(
                                        offset: Offset(0, 14.0 * i),
                                        child: Transform.scale(
                                          scale: 1 - 0.045 * i,
                                          child: _CardFace(profile: deck[i]),
                                        ),
                                      ),
                              ),
                            ),
                        ],
                      );
                    }),
            ),
            if (deck.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CircleButton(
                      icon: Icons.close,
                      color: kPink,
                      size: 56,
                      onTap: () => _decide(_Swipe.pass),
                    ),
                    const SizedBox(width: 14),
                    _CircleButton(
                      icon: Icons.star_rounded,
                      color: const Color(0xFF2E8BEA),
                      size: 46,
                      badge: '$kSuperLikeCost',
                      onTap: () => _decide(_Swipe.superLike),
                    ),
                    const SizedBox(width: 14),
                    _CircleButton(
                      icon: Icons.favorite,
                      color: Colors.white,
                      background: AppColors.buttonGradient,
                      size: 56,
                      onTap: () => _decide(_Swipe.like),
                    ),
                    const SizedBox(width: 14),
                    _CircleButton(
                      icon: Icons.bolt,
                      color: jodie.isBoosted ? Colors.white : AppColors.magenta,
                      background: jodie.isBoosted ? AppColors.buttonGradient : null,
                      size: 46,
                      badge: jodie.isBoosted ? null : '$kBoostCost',
                      onTap: _boost,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 96),
          ],
        );
      },
    );
  }

  Widget _topCard(JodieProfile p) {
    return AnimatedBuilder(
      animation: _fly,
      builder: (context, _) {
        final o = _offset;
        return Transform.translate(
          offset: o,
          child: Transform.rotate(
            angle: o.dx / _area.width * 0.35,
            child: GestureDetector(
              onPanUpdate: (d) {
                if (_flying) return;
                setState(() => _drag += d.delta);
              },
              onPanEnd: _onPanEnd,
              onTapUp: (d) {
                final i = _photo[p.id] ?? 0;
                final next = d.localPosition.dx > _area.width / 2 ? i + 1 : i - 1;
                setState(() => _photo[p.id] = next.clamp(0, p.photos.length - 1));
              },
              child: _CardFace(
                profile: p,
                photo: _photo[p.id] ?? 0,
                offset: o,
                onInfo: () => _openDetail(p),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.profile,
    this.photo = 0,
    this.offset = Offset.zero,
    this.onInfo,
  });

  final JodieProfile profile;
  final int photo;
  final Offset offset;
  final VoidCallback? onInfo;

  @override
  Widget build(BuildContext context) {
    final p = profile;
    final score = jodie.compat(p).score;
    final likeOpacity = (offset.dx / 110).clamp(0.0, 1.0);
    final nopeOpacity = (-offset.dx / 110).clamp(0.0, 1.0);
    final superOpacity = (-offset.dy / 110).clamp(0.0, 1.0);
    final shared = p.interests.intersection(jodie.me.interests).toList();
    final chips = [...shared, ...p.interests.where((k) => !shared.contains(k))]
        .take(3)
        .toList();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: AppColors.purpleDeep.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          fit: StackFit.expand,
          children: [
            LookCanvas(look: p.photos[photo], showText: false),
            Center(
              child: Text(p.initials,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.28),
                      fontSize: 140,
                      fontWeight: FontWeight.w800)),
            ),
            // Photo progress
            Positioned(
              left: 14,
              right: 14,
              top: 12,
              child: Row(
                children: [
                  for (var i = 0; i < p.photos.length; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == photo ? Colors.white : Colors.white38,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Match badge
            Positioned(
              top: 26,
              left: 14,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.favorite, color: Colors.white, size: 14),
                    const SizedBox(width: 5),
                    Text(tr(context, 'jd_match_pct', args: {'n': '$score'}),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
            ),
            // Bottom shade + info
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 230,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xCC000000)],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text('${p.firstName}, ${p.age}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800)),
                            ),
                            if (p.verified) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified,
                                  color: Color(0xFF59B6FF), size: 22),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('${p.profession} · ${p.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            for (final k in chips)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 5),
                                decoration: BoxDecoration(
                                  color: shared.contains(k)
                                      ? Colors.white
                                      : Colors.white24,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(tr(context, 'int_$k'),
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: shared.contains(k)
                                            ? AppColors.magenta
                                            : Colors.white)),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (onInfo != null)
                    GestureDetector(
                      onTap: onInfo,
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(left: 10),
                        decoration: const BoxDecoration(
                            color: Colors.white24, shape: BoxShape.circle),
                        child: const Icon(Icons.info_outline,
                            color: Colors.white, size: 22),
                      ),
                    ),
                ],
              ),
            ),
            // Swipe stamps
            Positioned(
              top: 70,
              left: 22,
              child: _Stamp('LIKE', const Color(0xFF3DDC84), likeOpacity, -0.25),
            ),
            Positioned(
              top: 70,
              right: 22,
              child: _Stamp('NOPE', kPink, nopeOpacity, 0.25),
            ),
            Positioned(
              top: 120,
              left: 0,
              right: 0,
              child: Center(
                child:
                    _Stamp('SUPER', const Color(0xFF59B6FF), superOpacity, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp(this.text, this.color, this.opacity, this.angle);

  final String text;
  final Color color;
  final double opacity;
  final double angle;

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 4),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(text,
                style: TextStyle(
                    color: color, fontSize: 30, fontWeight: FontWeight.w900)),
          ),
        ),
      );
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    this.background,
    this.badge,
  });

  final IconData icon;
  final Color color;
  final double size;
  final Gradient? background;
  final String? badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: background,
                color: background == null ? Colors.white : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: color, size: size * 0.52),
            ),
            if (badge != null)
              Positioned(
                right: -4,
                top: -4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: kGold,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(badge!,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800)),
                ),
              ),
          ],
        ),
      );
}

class _Empty extends StatelessWidget {
  const _Empty({required this.onFilters});

  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                    color: AppColors.tint, shape: BoxShape.circle),
                child: const Icon(Icons.favorite_border,
                    color: AppColors.magenta, size: 42),
              ),
              const SizedBox(height: 18),
              Text(tr(context, 'jd_no_more'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              Text(tr(context, 'jd_no_more_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.muted)),
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onFilters,
                child: Text(tr(context, 'jd_filters')),
              ),
            ],
          ),
        ),
      );
}
