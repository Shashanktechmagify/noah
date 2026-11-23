import 'package:flutter/material.dart';

import '../data/prayer_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_bits.dart';
import '../widgets/prayer_dialog.dart';
import 'me/sub_page.dart';

/// The member's own prayer requests and where each one stands (waiting for approval, approved, not published), with a
/// button to write a new one. The prayer wall (other members' requests) is a separate page.
class MyPrayerRequestsScreen extends StatefulWidget {
  const MyPrayerRequestsScreen({super.key});

  @override
  State<MyPrayerRequestsScreen> createState() => _MyPrayerRequestsScreenState();
}

class _MyPrayerRequestsScreenState extends State<MyPrayerRequestsScreen> {
  @override
  void initState() {
    super.initState();
    prayer.load();
  }

  Widget _card(BuildContext context, MyPrayer r) {
    final pill = switch (r.state) {
      'Approved' => (tr(context, 'pw_st_approved'), StatusPill.booked),
      'Declined' => (tr(context, 'pw_st_declined'), StatusPill.past),
      _ => (tr(context, 'pw_st_pending'), StatusPill.soon),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: WhiteCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PrayerChip(
                        tr(context, 'pr_cat_${r.category}'),
                        StatusPill.book,
                      ),
                      Text(
                        prayerWhen(context, r.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PrayerChip(pill.$1, pill.$2),
              ],
            ),
            const SizedBox(height: 10),
            Text(r.text, style: const TextStyle(fontSize: 14.5, height: 1.4)),
            const SizedBox(height: 10),
            Text(
              tr(
                context,
                r.everyone ? 'pr_audience_all' : 'pr_audience_warriors',
              ),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            if (r.state == 'Approved') ...[
              const SizedBox(height: 4),
              Text(
                tr(context, 'pw_count', args: {'n': '${r.prayedBy}'}),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prayer,
      builder: (context, _) {
        final mine = prayer.mine;
        return SubPage(
          title: tr(context, 'mn_prayer_request'),
          subtitle: tr(context, 'pr_sub'),
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
            else ...[
              if (mine.isEmpty) PrayerNote(tr(context, 'pw_empty_mine')),
              for (final r in mine) _card(context, r),
            ],
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () async {
                  await showPrayerDialog(context);
                  prayer.load();
                },
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    tr(context, 'pw_new'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }
}
