import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_scaffold.dart' show GradientButton;
import '../../widgets/page_scaffold.dart';
import '../main_shell.dart' show ShellScope;
import 'jodie_widgets.dart' show showMyProfileSheet, showPaymentSheet;

/// Jodie landing for people who have not joined yet: what it is, what it
/// costs (₹300, once) and a button to become a member.
class JodieIntro extends StatelessWidget {
  const JodieIntro({super.key});

  Future<void> _join(BuildContext context) async {
    final paid = await showPaymentSheet(
      context,
      title: 'Jodie · ${tr(context, 'ji_f4')}',
      rupees: kJodieMembershipRupees,
    );
    if (!paid || !context.mounted) return;
    jodie.join();
    // "Then create your profile."
    await showMyProfileSheet(context);
  }

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.shield_outlined, 'ji_f1', 'ji_f1s', const Color(0xFFC13FD6)),
      (Icons.lock_outline, 'ji_f2', 'ji_f2s', const Color(0xFFD6338B)),
      (Icons.person_outline, 'ji_f3', 'ji_f3s', const Color(0xFF6A2DA8)),
      (Icons.currency_rupee, 'ji_f4', 'ji_f4s', const Color(0xFFE0508F)),
    ];
    return Scaffold(
      body: PageScaffold(
        title: 'Jodie',
        leadingIcon: Icons.favorite_border,
        bandHeight: 175,
        above: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: GestureDetector(
              onTap: () => ShellScope.maybeOf(context)?.selectSlot(0),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chevron_left, color: Colors.white, size: 20),
                    Text(
                      'Noah',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        children: [
          WhiteCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, 'ji_title'),
                  style: const TextStyle(
                    // Falls back to the platform serif when no serif is bundled.
                    fontFamily: 'serif',
                    fontFamilyFallback: ['PlusJakartaSans'],
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  tr(context, 'ji_body'),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          WhiteCard(
            child: Column(
              children: [
                for (final (i, f) in features.indexed) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: f.$4,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(f.$1, color: Colors.white, size: 21),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr(context, f.$2),
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                tr(context, f.$3),
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                  height: 1.3,
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: tr(context, 'ji_cta'),
              onPressed: () => _join(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
            child: Text(
              tr(context, 'ji_cta_note'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
