import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/ministry_data.dart';
import '../../data/me_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import 'sub_page.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.confirmation_number_outlined,
        tr(context, 'nf_pass', args: {'event': tr(context, 'ev_sunday2')}),
        tr(context, 'manna_days_ago', args: {'n': '2'}),
      ),
      (
        Icons.description_outlined,
        tr(
          context,
          'nf_receipt',
          args: {'no': 'KS/26-27/04412', 'amount': rupees(1100)},
        ),
        tr(context, 'manna_days_ago', args: {'n': '15'}),
      ),
      (
        Icons.group_outlined,
        tr(
          context,
          'nf_added',
          args: {'name': ministry.leader.name, 'n': ministry.record.cell},
        ),
        tr(context, 'nf_weeks', args: {'n': '3'}),
      ),
    ];
    return SubPage(
      title: tr(context, 'me_notifications'),
      children: [
        WhiteCard(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
          child: Column(
            children: [
              const _CaughtUpArt(),
              const SizedBox(height: 14),
              Text(
                tr(context, 'nf_caught'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                tr(context, 'nf_caught_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 13.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        SectionTitle(title: tr(context, 'nf_earlier')),
        const SizedBox(height: 12),
        WhiteCard(
          child: Column(
            children: [
              for (final (i, n) in items.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: AppColors.tint,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(n.$1, color: AppColors.ink, size: 21),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.$2,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              n.$3,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Small illustration for the empty state: a bell on a mint disc with leaves.
class _CaughtUpArt extends StatelessWidget {
  const _CaughtUpArt();

  static const _mint = Color(0xFFE3F5EE);
  static const _teal = Color(0xFF2BB68F);
  static const _orange = Color(0xFFFF7A59);

  Widget _leaf(double angle, Alignment at, Color color) => Align(
    alignment: at,
    child: Transform.rotate(
      angle: angle,
      child: Container(
        width: 20,
        height: 34,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topRight: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
        ),
      ),
    ),
  );

  Widget _person(Alignment at) => Align(
    alignment: at,
    child: Container(
      width: 34,
      height: 34,
      decoration: const BoxDecoration(color: _orange, shape: BoxShape.circle),
      child: const Icon(Icons.person_outline, color: Colors.white, size: 19),
    ),
  );

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 230,
    height: 170,
    child: Stack(
      children: [
        Align(
          child: Container(
            width: 150,
            height: 150,
            decoration: const BoxDecoration(
              color: _mint,
              shape: BoxShape.circle,
            ),
          ),
        ),
        _leaf(
          -math.pi / 5,
          const Alignment(-0.78, -0.1),
          const Color(0xFF8AD9BF),
        ),
        _leaf(math.pi / 4, const Alignment(0.82, 0.05), _teal),
        _leaf(
          math.pi / 6,
          const Alignment(0.55, -0.75),
          const Color(0xFF8AD9BF),
        ),
        _person(const Alignment(-0.7, -0.75)),
        _person(const Alignment(0.72, 0.62)),
        const Align(
          alignment: Alignment(0, -0.1),
          child: Icon(Icons.notifications, color: _teal, size: 78),
        ),
        Align(
          alignment: const Alignment(0, 0.72),
          child: Container(
            width: 70,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFFBFE8D9),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    ),
  );
}
