import 'package:flutter/material.dart';

import '../data/prayer_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_bits.dart';
import 'me/sub_page.dart';

/// The prayer wall: other members' open requests (and the prayer warriors' own, for a warrior), one card at a time. The card
/// stays until the member presses "I prayed": only then the request leaves the wall for good and the next card comes up. There
/// is nothing else to move on with (no swipe, no skip, no previous or next, and no count). The member's own requests are not
/// here: they have their own page (My prayer requests).
class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
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
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                // The next card slides in when this one has been prayed for. The card is as wide as the page.
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 280),
                  transitionBuilder: (child, anim) => SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.25, 0),
                      end: Offset.zero,
                    ).animate(anim),
                    child: FadeTransition(opacity: anim, child: child),
                  ),
                  child: SizedBox(
                    key: ValueKey(wall.first.id),
                    width: double.infinity,
                    child: _card(context, wall.first),
                  ),
                ),
              ),
              // The only way on: "I prayed".
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  key: const ValueKey('wall-pray'),
                  onTap: () => _prayed(context, wall.first),
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppColors.buttonGradient,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x335E2CA5),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.self_improvement,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr(context, 'pw_pray'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
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
