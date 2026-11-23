import 'package:flutter/material.dart';

import '../data/prayer_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_bits.dart';
import 'me/sub_page.dart';

/// The prayer wall: other members' open requests (and the prayer warriors' own, for a warrior), one at a time, with an
/// "I prayed" button. Swipe, or use Previous / Next, to go to the next one. The member's own requests are not here: they
/// have their own page (My prayer requests).
class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  int _index = 0;
  bool _forward = true;

  @override
  void initState() {
    super.initState();
    prayer.load();
  }

  void _go(int to, int count) {
    if (to < 0 || to >= count) return;
    setState(() {
      _forward = to > _index;
      _index = to;
    });
  }

  Widget _card(BuildContext context, WallRequest r) => WhiteCard(
    key: ValueKey(r.id),
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
        Row(
          children: [
            Expanded(
              child: Text(
                tr(context, 'pw_count', args: {'n': '${r.prayedBy}'}),
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
              ),
            ),
            StatusPill(
              text: r.iPrayed
                  ? tr(context, 'pw_prayed')
                  : tr(context, 'pw_pray'),
              background: r.iPrayed ? StatusPill.booked.$1 : StatusPill.book.$1,
              foreground: r.iPrayed ? StatusPill.booked.$2 : StatusPill.book.$2,
              onTap: r.iPrayed ? null : () => prayer.pray(r),
            ),
          ],
        ),
      ],
    ),
  );

  Widget _arrow(
    BuildContext context,
    String label,
    IconData icon,
    bool on,
    VoidCallback tap, {
    bool next = false,
  }) => Expanded(
    child: GestureDetector(
      onTap: on ? tap : null,
      child: Opacity(
        opacity: on ? 1 : 0.4,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: next ? AppColors.magenta : Colors.white,
            borderRadius: BorderRadius.circular(23),
            border: Border.all(
              color: next ? AppColors.magenta : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!next) Icon(icon, size: 20, color: AppColors.ink),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: next ? Colors.white : AppColors.ink,
                ),
              ),
              if (next) Icon(icon, size: 20, color: Colors.white),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prayer,
      builder: (context, _) {
        // Never the member's own requests (the server already leaves them out).
        final wall = prayer.wall.where((r) => !r.mine).toList();
        final count = wall.length;
        if (_index >= count) _index = count == 0 ? 0 : count - 1;
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
              Center(
                child: Text(
                  tr(
                    context,
                    'pw_position',
                    args: {'n': '${_index + 1}', 'total': '$count'},
                  ),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                // A swipe left shows the next request, a swipe right the one before.
                onHorizontalDragEnd: (d) {
                  final v = d.primaryVelocity ?? 0;
                  if (v < -200) _go(_index + 1, count);
                  if (v > 200) _go(_index - 1, count);
                },
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_forward ? 0.25 : -0.25, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: _card(context, wall[_index]),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _arrow(
                      context,
                      tr(context, 'pw_prev'),
                      Icons.chevron_left,
                      _index > 0,
                      () => _go(_index - 1, count),
                    ),
                    const SizedBox(width: 12),
                    _arrow(
                      context,
                      tr(context, 'pw_next'),
                      Icons.chevron_right,
                      _index < count - 1,
                      () => _go(_index + 1, count),
                      next: true,
                    ),
                  ],
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
