import 'package:flutter/material.dart';

import '../data/prayer_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_bits.dart';
import 'me/sub_page.dart';

/// The prayer wall: other members' open requests (and the prayer warriors' own, for a warrior) as a deck of cards, one on
/// top. Swipe the card to the right (or tap the prayer button) once you have prayed: the request leaves the wall for good and
/// the next card comes up. Swipe it to the left (or tap Skip) to leave it for later: it goes to the back of the deck.
/// Nothing moves on by itself. The member's own requests are not here: they have their own page (My prayer requests).
class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  final _deck = GlobalKey<_SwipeDeckState>();

  @override
  void initState() {
    super.initState();
    prayer.load();
  }

  void _prayed(BuildContext context, WallRequest r) {
    prayer.pray(r);
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(tr(context, 'pw_prayed')),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Widget _card(BuildContext context, WallRequest r) => WhiteCard(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PrayerChip(tr(context, 'pr_cat_${r.category}'), StatusPill.book),
            if (!r.everyone)
              PrayerChip(tr(context, 'pw_warriors_tag'), StatusPill.soon),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          [
            r.name ?? tr(context, 'pw_anonymous'),
            prayerWhen(context, r.createdAt),
          ].where((s) => s.isNotEmpty).join(' · '),
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 16),
        Text(r.text, style: const TextStyle(fontSize: 16, height: 1.5)),
        const SizedBox(height: 20),
        Text(
          tr(context, 'pw_count', args: {'n': '${r.prayedBy}'}),
          style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
        ),
      ],
    ),
  );

  /// A round button under the deck: the same as a swipe.
  Widget _round({
    required Key key,
    required IconData icon,
    required String label,
    required bool big,
    required bool filled,
    required VoidCallback onTap,
  }) {
    final size = big ? 72.0 : 58.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          key: key,
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: filled ? AppColors.buttonGradient : null,
              color: filled ? null : Colors.white,
              border: filled ? null : Border.all(color: AppColors.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A5E2CA5),
                  blurRadius: 12,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: big ? 32 : 26,
              color: filled ? Colors.white : AppColors.muted,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: filled ? AppColors.purple : AppColors.muted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prayer,
      builder: (context, _) {
        // Never the member's own requests (the server leaves them out) and never one already prayed for.
        final wall = prayer.wall.where((r) => !r.mine && !r.iPrayed).toList();
        return SubPage(
          title: tr(context, 'mn_prayer_wall'),
          subtitle: tr(context, 'pw_sub'),
          bandHeight: 96,
          children: [
            if (prayer.loading && !prayer.loaded)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (prayer.failed && !prayer.loaded)
              GestureDetector(
                onTap: prayer.load,
                child: PrayerNote(tr(context, 'pw_failed')),
              )
            else if (wall.isEmpty)
              PrayerNote(tr(context, 'pw_empty_wall'))
            else ...[
              // How many are left, in a small pill with room above it (it used to sit on the edge of the purple band).
              const SizedBox(height: 18),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    tr(context, 'pw_left', args: {'n': '${wall.length}'}),
                    style: const TextStyle(
                      color: AppColors.purple,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SwipeDeck<WallRequest>(
                key: _deck,
                items: wall,
                idOf: (r) => r.id,
                builder: _card,
                prayLabel: tr(context, 'pw_pray'),
                skipLabel: tr(context, 'pw_skip'),
                onPray: (r) => _prayed(context, r),
                onSkip: prayer.skip,
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _round(
                    key: const ValueKey('wall-skip'),
                    icon: Icons.close,
                    label: tr(context, 'pw_skip'),
                    big: false,
                    filled: false,
                    onTap: () => _deck.currentState?.swipe(right: false),
                  ),
                  const SizedBox(width: 40),
                  _round(
                    key: const ValueKey('wall-pray'),
                    icon: Icons.self_improvement,
                    label: tr(context, 'pw_pray'),
                    big: true,
                    filled: true,
                    onTap: () => _deck.currentState?.swipe(right: true),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  tr(context, 'pw_swipe_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}

/// A deck of cards, the first on top and the next peeking out behind it. The top card follows the finger (and tilts a little);
/// let go past a third of the width, or with a quick flick, and it flies off to that side; otherwise it springs back.
/// Right means "I prayed" ([onPray]), left means "skip" ([onSkip]). [swipe] does the same for the round buttons.
class _SwipeDeck<T> extends StatefulWidget {
  const _SwipeDeck({
    super.key,
    required this.items,
    required this.idOf,
    required this.builder,
    required this.onPray,
    required this.onSkip,
    required this.prayLabel,
    required this.skipLabel,
  });

  final List<T> items;
  final String Function(T item) idOf;
  final Widget Function(BuildContext context, T item) builder;
  final void Function(T item) onPray;
  final void Function(T item) onSkip;
  final String prayLabel;
  final String skipLabel;

  @override
  State<_SwipeDeck<T>> createState() => _SwipeDeckState<T>();
}

class _SwipeDeckState<T> extends State<_SwipeDeck<T>>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this);
  Offset _drag = Offset.zero;
  bool _busy = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _animateTo(
    Offset to,
    Duration duration,
    Curve curve,
    VoidCallback done,
  ) {
    final from = _drag;
    _busy = true;
    _ctrl
      ..stop()
      ..duration = duration
      ..reset();
    final curved = CurvedAnimation(parent: _ctrl, curve: curve);
    void tick() => setState(() => _drag = Offset.lerp(from, to, curved.value)!);
    _ctrl.addListener(tick);
    _ctrl.forward().whenComplete(() {
      _ctrl.removeListener(tick);
      curved.dispose();
      done();
    });
  }

  /// The top card leaves to the right (prayed) or the left (skipped), then the deck moves up.
  void swipe({required bool right}) {
    if (_busy || widget.items.isEmpty) return;
    final item = widget.items.first;
    // A single card cannot be put behind another: a skip only shakes it.
    if (!right && widget.items.length == 1) {
      _animateTo(
        const Offset(-40, 0),
        const Duration(milliseconds: 90),
        Curves.easeOut,
        () {
          _animateTo(
            Offset.zero,
            const Duration(milliseconds: 160),
            Curves.easeOut,
            () => _busy = false,
          );
        },
      );
      return;
    }
    final width = MediaQuery.of(context).size.width;
    _animateTo(
      Offset((right ? 1 : -1) * width * 1.3, _drag.dy),
      const Duration(milliseconds: 220),
      Curves.easeIn,
      () {
        if (!mounted) return;
        setState(() {
          _drag = Offset.zero;
          _busy = false;
        });
        if (right) {
          widget.onPray(item);
        } else {
          widget.onSkip(item);
        }
      },
    );
  }

  void _end(DragEndDetails d, double width) {
    if (_busy) return;
    final vx = d.primaryVelocity ?? 0;
    final far = _drag.dx.abs() > width / 3;
    final flick = vx.abs() > 900 && _drag.dx.abs() > 24;
    if (far || flick) {
      swipe(
        right: vx.abs() > 900 && _drag.dx.abs() <= width / 3
            ? vx > 0
            : _drag.dx > 0,
      );
    } else {
      _animateTo(
        Offset.zero,
        const Duration(milliseconds: 200),
        Curves.easeOut,
        () => _busy = false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items;
    if (items.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    // 0 at rest, 1 when the card is a third of the width away: the card behind comes forward and the stamp shows.
    final pull = (_drag.dx.abs() / (width / 3)).clamp(0.0, 1.0);
    final top = items.first;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (items.length > 2)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, 22 - 10 * pull),
                child: Transform.scale(
                  scale: 0.9 + 0.03 * pull,
                  child: Opacity(opacity: 0.55, child: _ghost(context)),
                ),
              ),
            ),
          if (items.length > 1)
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, 11 - 11 * pull),
                child: Transform.scale(
                  scale: 0.95 + 0.05 * pull,
                  child: Opacity(opacity: 0.8, child: _ghost(context)),
                ),
              ),
            ),
          GestureDetector(
            key: const ValueKey('wall-top'),
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) {
              if (_busy) return;
              setState(() => _drag += Offset(d.delta.dx, d.delta.dy * 0.25));
            },
            onHorizontalDragEnd: (d) => _end(d, width),
            child: Transform.translate(
              offset: _drag,
              child: Transform.rotate(
                angle: _drag.dx / width * 0.35,
                child: Stack(
                  children: [
                    KeyedSubtree(
                      key: ValueKey(widget.idOf(top)),
                      child: widget.builder(context, top),
                    ),
                    // The stamp: "I prayed" while it is pulled to the right, "Skip" to the left.
                    if (_drag.dx.abs() > 8)
                      Positioned(
                        top: 18,
                        left: _drag.dx > 0 ? 18 : null,
                        right: _drag.dx < 0 ? 18 : null,
                        child: Opacity(
                          opacity: pull,
                          child: Transform.rotate(
                            angle: _drag.dx > 0 ? -0.2 : 0.2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: _drag.dx > 0
                                      ? AppColors.purple
                                      : AppColors.muted,
                                  width: 2.5,
                                ),
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                              child: Text(
                                (_drag.dx > 0
                                        ? widget.prayLabel
                                        : widget.skipLabel)
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                  color: _drag.dx > 0
                                      ? AppColors.purple
                                      : AppColors.muted,
                                ),
                              ),
                            ),
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

  /// A card waiting behind the top one: only its shape is shown.
  Widget _ghost(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.border),
    ),
  );
}
