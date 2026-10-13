import 'package:flutter/material.dart';

import '../../data/me_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/page_scaffold.dart';
import '../events/events_widgets.dart' show fullDate;
import '../jodie/jodie_widgets.dart' show toast;
import 'sub_page.dart';

/// Money earned from Noahgram activity, and what has been paid out.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: meState,
      builder: (context, _) {
        final available = meState.available;
        final rows = [
          (
            Icons.favorite_border,
            '${groupDigits(meState.likes)} · ${tr(context, 'rw_likes')}',
            '0.5',
            meState.likesEarned,
          ),
          (
            Icons.chat_bubble_outline,
            '${groupDigits(meState.comments)} · ${tr(context, 'rw_comments')}',
            '2',
            meState.commentsEarned,
          ),
          (
            Icons.grid_view_rounded,
            '${groupDigits(meState.posts)} · ${tr(context, 'rw_posts')}',
            '3',
            meState.postsEarned,
          ),
        ];
        final total =
            meState.likesEarned + meState.commentsEarned + meState.postsEarned;
        return SubPage(
          title: tr(context, 'me2_rewards'),
          subtitle: tr(context, 'rw_sub'),
          children: [
            WhiteCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, 'rw_available'),
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              rupees(available, decimals: true),
                              style: const TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: const BoxDecoration(
                              color: Color(0xFFA719C8),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tr(
                              context,
                              'rw_min',
                              args: {'n': '${MeState.minimumWithdrawal}'},
                            ),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (available / MeState.minimumWithdrawal).clamp(
                        0.0,
                        1.0,
                      ),
                      minHeight: 5,
                      backgroundColor: AppColors.tint,
                      color: AppColors.magenta,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tr(context, 'rw_to_account'),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(title: tr(context, 'rw_how')),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, r) in rows.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          IconTile(icon: r.$1),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.$2,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    height: 1.25,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  tr(context, 'rw_each', args: {'n': r.$3}),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rupees(r.$4, decimals: true),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Text(
                tr(context, 'rw_note'),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: meState.canWithdraw
                    ? () {
                        meState.withdraw();
                        toast(context, tr(context, 'rw_requested'));
                      }
                    : null,
                child: Container(
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: meState.canWithdraw
                        ? AppColors.buttonGradient
                        : null,
                    color: meState.canWithdraw ? null : const Color(0xFFE2DDF1),
                    borderRadius: BorderRadius.circular(26),
                  ),
                  child: Text(
                    meState.withdrawalPending
                        ? tr(context, 'rw_pending')
                        : tr(
                            context,
                            'rw_withdraw',
                            args: {'n': total.toStringAsFixed(2)},
                          ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 22),
            SectionTitle(title: tr(context, 'rw_payouts')),
            const SizedBox(height: 12),
            WhiteCard(
              child: Column(
                children: [
                  for (final (i, p) in meState.payouts.indexed) ...[
                    if (i > 0)
                      const Divider(height: 1, color: AppColors.border),
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
                            child: const Icon(
                              Icons.currency_rupee,
                              color: AppColors.muted,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr(
                                    context,
                                    'rw_paid_amount',
                                    args: {
                                      'amount': rupees(
                                        p.amount,
                                        decimals: true,
                                      ),
                                    },
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${fullDate(context, p.date)} · '
                                  '${tr(context, 'rw_batch', args: {'b': p.batch})}',
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusPill(
                            text: tr(
                              context,
                              p.paid ? 'rw_paid' : 'rw_pending',
                            ),
                            background: p.paid
                                ? StatusPill.booked.$1
                                : StatusPill.soon.$1,
                            foreground: p.paid
                                ? StatusPill.booked.$2
                                : StatusPill.soon.$2,
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
      },
    );
  }
}
