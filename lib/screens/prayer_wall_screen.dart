import 'package:flutter/material.dart';

import '../data/prayer_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_dialog.dart';
import 'me/sub_page.dart';

/// The prayer wall: other members' open requests (and the prayer warriors' own, for a warrior) with an "I prayed" button,
/// and the member's own requests with where each one stands.
class PrayerWallScreen extends StatefulWidget {
  const PrayerWallScreen({super.key});

  @override
  State<PrayerWallScreen> createState() => _PrayerWallScreenState();
}

class _PrayerWallScreenState extends State<PrayerWallScreen> {
  int _tab = 0; // 0 the wall, 1 my requests

  @override
  void initState() {
    super.initState();
    prayer.load();
  }

  String _when(BuildContext context, DateTime? at) {
    if (at == null) return '';
    final d = DateTime.now().difference(at);
    if (d.inMinutes < 1) return tr(context, 'pw_now');
    if (d.inMinutes < 60) {
      return tr(context, 'pw_min', args: {'n': '${d.inMinutes}'});
    }
    if (d.inHours < 24) {
      return tr(context, 'pw_hour', args: {'n': '${d.inHours}'});
    }
    return tr(context, 'pw_day', args: {'n': '${d.inDays}'});
  }

  Widget _tabs(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        for (final (i, key) in const [
          (0, 'pw_tab_wall'),
          (1, 'pw_tab_mine'),
        ]) ...[
          if (i == 1) const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _tab == i ? AppColors.magenta : Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(
                    color: _tab == i ? AppColors.magenta : AppColors.border,
                  ),
                ),
                child: Text(
                  tr(context, key),
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: _tab == i ? Colors.white : AppColors.ink,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );

  Widget _chip(String text, (Color, Color) c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: c.$1,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        color: c.$2,
      ),
    ),
  );

  Widget _wallCard(BuildContext context, WallRequest r) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: WhiteCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(tr(context, 'pr_cat_${r.category}'), StatusPill.book),
              if (!r.everyone)
                _chip(tr(context, 'pw_warriors_tag'), StatusPill.soon),
              Text(
                [
                  r.mine
                      ? tr(context, 'pw_you')
                      : (r.name ?? tr(context, 'pw_anonymous')),
                  _when(context, r.createdAt),
                ].where((s) => s.isNotEmpty).join(' · '),
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.text, style: const TextStyle(fontSize: 14.5, height: 1.4)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  tr(context, 'pw_count', args: {'n': '${r.prayedBy}'}),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (!r.mine)
                StatusPill(
                  text: r.iPrayed
                      ? tr(context, 'pw_prayed')
                      : tr(context, 'pw_pray'),
                  background: r.iPrayed
                      ? StatusPill.booked.$1
                      : StatusPill.book.$1,
                  foreground: r.iPrayed
                      ? StatusPill.booked.$2
                      : StatusPill.book.$2,
                  onTap: r.iPrayed ? null : () => prayer.pray(r),
                ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _mineCard(BuildContext context, MyPrayer r) {
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
                      _chip(
                        tr(context, 'pr_cat_${r.category}'),
                        StatusPill.book,
                      ),
                      Text(
                        _when(context, r.createdAt),
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _chip(pill.$1, pill.$2),
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

  Widget _empty(BuildContext context, String key) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 28, 32, 8),
    child: Text(
      tr(context, key),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.muted,
        fontSize: 13.5,
        height: 1.4,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: prayer,
      builder: (context, _) {
        final wall = prayer.wall;
        final mine = prayer.mine;
        return SubPage(
          title: tr(context, 'mn_prayer_wall'),
          subtitle: tr(context, 'pw_sub'),
          bandHeight: 120,
          children: [
            _tabs(context),
            const SizedBox(height: 14),
            if (prayer.loading && !prayer.loaded)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (prayer.failed && !prayer.loaded)
              GestureDetector(
                onTap: prayer.load,
                child: _empty(context, 'pw_failed'),
              )
            else if (_tab == 0) ...[
              if (wall.isEmpty) _empty(context, 'pw_empty_wall'),
              for (final r in wall) _wallCard(context, r),
            ] else ...[
              if (mine.isEmpty) _empty(context, 'pw_empty_mine'),
              for (final r in mine) _mineCard(context, r),
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
