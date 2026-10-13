import 'package:flutter/material.dart';

import '../../data/jodie_data.dart';
import '../../data/noahgram_data.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_theme.dart';
import '../noahgram/noahgram_widgets.dart' show showShareSheet;

const kGold = Color(0xFFF2A33A);
const kPink = Color(0xFFE5334B);

String langNative(String english) => AppLang.values
    .firstWhere((l) => l.english == english, orElse: () => AppLang.en)
    .native;

String reasonText(BuildContext context, Reason r) {
  final (key, arg) = r;
  return switch (key) {
    'jd_why_lang' => tr(context, key, args: {'x': langNative(arg)}),
    'jd_why_interest' => tr(context, key, args: {'x': tr(context, 'int_$arg')}),
    'jd_why_city' => tr(context, key, args: {'x': arg}),
    _ => tr(context, key),
  };
}

String clock(DateTime t) {
  final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m ${t.hour < 12 ? 'am' : 'pm'}';
}

void toast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(16, 0, 16, 110),
  ));
}

class JodieAvatar extends StatelessWidget {
  const JodieAvatar({
    super.key,
    required this.initials,
    required this.colors,
    this.size = 48,
    this.border = false,
  });

  JodieAvatar.of(JodieProfile p, {Key? key, double size = 48, bool border = false})
      : this(
          key: key,
          initials: p.initials,
          colors: p.colors,
          size: size,
          border: border,
        );

  JodieAvatar.me({Key? key, double size = 48, bool border = false})
      : this(
          key: key,
          initials: noahgram.me.initials,
          colors: noahgram.me.colors,
          size: size,
          border: border,
        );

  final String initials;
  final List<Color> colors;
  final double size;
  final bool border;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: border ? Border.all(color: Colors.white, width: 3) : null,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Text(initials,
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.36)),
      );
}

class CreditChip extends StatelessWidget {
  const CreditChip({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: ListenableBuilder(
          listenable: jodie,
          builder: (_, _) => Container(
            padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4DD),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, color: kGold, size: 20),
                const SizedBox(width: 4),
                Text('${jodie.credits}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: Color(0xFF8A5A00))),
              ],
            ),
          ),
        ),
      );
}

// ──────────────────────────────────────────────────────────────────────────
// Sheets
// ──────────────────────────────────────────────────────────────────────────

Future<T?> _sheet<T>(BuildContext context, WidgetBuilder builder) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
      builder: builder,
    );

Widget _grabber() => Center(
      child: Container(
        width: 40,
        height: 4,
        margin: const EdgeInsets.only(top: 10, bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );

Widget _title(String text) => Text(text,
    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800));

Widget _primaryButton(String label, VoidCallback? onTap) => GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: onTap == null ? null : AppColors.buttonGradient,
          color: onTap == null ? const Color(0xFFE2DDF1) : null,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w800)),
      ),
    );

/// Placeholder for the Razorpay checkout.
///
/// To go live: ask the backend to create a Razorpay order for [rupees],
/// open the Razorpay checkout with the returned order id, then send the
/// payment id + signature to the backend to verify before granting anything.
/// Return `true` only after the backend confirms the payment.
Future<bool> showPaymentSheet(
  BuildContext context, {
  required String title,
  required int rupees,
}) async {
  final ok = await _sheet<bool>(
    context,
    (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabber(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFDEBD3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(tr(context, 'jd_demo_pay'),
                  style: const TextStyle(
                      color: Color(0xFFC2620A),
                      fontWeight: FontWeight.w800,
                      fontSize: 12)),
            ),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('₹$rupees',
                style:
                    const TextStyle(fontSize: 34, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            Text(tr(context, 'jd_demo_pay_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12.5)),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(tr(context, 'jd_secure_pay'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 18),
            _primaryButton(tr(context, 'jd_simulate'),
                () => Navigator.of(context).pop(true)),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(tr(context, 'jd_cancel'),
                  style: const TextStyle(color: AppColors.muted)),
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

Future<void> showSubscribeSheet(BuildContext context) =>
    _sheet<void>(context, (_) => const _SubscribeSheet());

class _SubscribeSheet extends StatefulWidget {
  const _SubscribeSheet();

  @override
  State<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<_SubscribeSheet> {
  int _selected = 2;

  Future<void> _pay() async {
    final plan = kPlans[_selected];
    final paid = await showPaymentSheet(
      context,
      title: '${tr(context, 'jd_premium')} · ${tr(context, plan.labelKey)}',
      rupees: plan.rupees,
    );
    if (!paid || !mounted) return;
    jodie.subscribe(plan);
    final message = tr(context, 'jd_premium_on');
    toast(context, message);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final plan = kPlans[_selected];
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _grabber(),
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.buttonGradient,
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 34),
            ),
            const SizedBox(height: 12),
            _title(tr(context, 'jd_unlock_chat')),
            const SizedBox(height: 4),
            Text(tr(context, 'jd_unlock_chat_sub'),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 13)),
            const SizedBox(height: 16),
            for (final perk in [
              tr(context, 'jd_perk_chat'),
              tr(context, 'jd_perk_likes'),
              tr(context, 'jd_perk_credits', args: {'n': '${plan.bonusCredits}'}),
              tr(context, 'jd_perk_badge'),
            ])
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.magenta, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(perk, style: const TextStyle(fontSize: 14))),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (var i = 0; i < kPlans.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
                        decoration: BoxDecoration(
                          color: i == _selected ? AppColors.tint : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: i == _selected
                                ? AppColors.magenta
                                : AppColors.border,
                            width: i == _selected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(tr(context, kPlans[i].labelKey),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 6),
                            Text('₹${kPlans[i].rupees}',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 4),
                            Text(
                                tr(context, 'jd_per_month',
                                    args: {'n': '${kPlans[i].perMonth}'}),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: AppColors.muted, fontSize: 11)),
                            if (i == kPlans.length - 1) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.magenta,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(tr(context, 'jd_best_value'),
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 18),
            _primaryButton(
                tr(context, 'jd_pay', args: {'n': '${plan.rupees}'}), _pay),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(tr(context, 'jd_secure_pay'),
                    style: const TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCreditsSheet(BuildContext context) =>
    _sheet<void>(context, (_) => const _CreditsSheet());

class _CreditsSheet extends StatelessWidget {
  const _CreditsSheet();

  Future<void> _buy(BuildContext context, CreditPack pack) async {
    final paid = await showPaymentSheet(
      context,
      title: tr(context, 'jd_pack', args: {'n': '${pack.credits}'}),
      rupees: pack.rupees,
    );
    if (!paid || !context.mounted) return;
    jodie.addCredits(pack.credits);
    toast(context, tr(context, 'jd_credits_added'));
  }

  Future<void> _task(BuildContext context, String id) async {
    switch (id) {
      case 'profile':
        await showMyProfileSheet(context);
      case 'invite':
        await showShareSheet(context);
        jodie.completeTask('invite');
      case 'verify':
        jodie.completeTask('verify');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: jodie,
      builder: (context, _) {
        final claimed = jodie.claimedToday;
        final idx = jodie.rewardIndex;
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabber(),
                // Balance
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF2A33A), Color(0xFFE5334B)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded,
                          color: Colors.white, size: 44),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tr(context, 'jd_credits_title'),
                              style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13)),
                          Text('${jodie.credits}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Daily reward + streak
                Row(
                  children: [
                    Expanded(child: _title(tr(context, 'jd_daily'))),
                    const Icon(Icons.local_fire_department,
                        color: kPink, size: 20),
                    const SizedBox(width: 2),
                    Text(tr(context, 'jd_streak', args: {'n': '${jodie.streak}'}),
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 2),
                Text(tr(context, 'jd_daily_sub'),
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12.5)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < 7; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Expanded(
                        child: _DayTile(
                          day: i + 1,
                          reward: kDailyRewards[i],
                          done: claimed ? i <= idx : i < idx,
                          today: !claimed && i == idx,
                          dayLabel: tr(context, 'jd_day', args: {'n': '${i + 1}'}),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                _primaryButton(
                  claimed
                      ? tr(context, 'jd_claimed')
                      : tr(context, 'jd_claim',
                          args: {'n': '${jodie.todaysReward}'}),
                  claimed ? null : jodie.claimDaily,
                ),
                const SizedBox(height: 22),

                // Earn
                _title(tr(context, 'jd_earn')),
                const SizedBox(height: 8),
                for (final (id, icon, key) in const [
                  ('profile', Icons.person_outline, 'jd_task_profile'),
                  ('invite', Icons.group_add_outlined, 'jd_task_invite'),
                  ('verify', Icons.verified_user_outlined, 'jd_task_verify'),
                ])
                  _TaskRow(
                    icon: icon,
                    label: tr(context, key),
                    reward: kTaskRewards[id]!,
                    done: jodie.doneTasks.contains(id),
                    doneLabel: tr(context, 'jd_done'),
                    goLabel: tr(context, 'jd_go'),
                    onGo: () => _task(context, id),
                  ),
                const SizedBox(height: 20),

                // Buy
                _title(tr(context, 'jd_buy')),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (var i = 0; i < kCreditPacks.length; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _buy(context, kCreditPacks[i]),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.stars_rounded,
                                    color: kGold, size: 24),
                                const SizedBox(height: 4),
                                Text('${kCreditPacks[i].credits}',
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.tint,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('₹${kCreditPacks[i].rupees}',
                                      style: const TextStyle(
                                          color: AppColors.magenta,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 22),

                // Spend
                _title(tr(context, 'jd_use_for')),
                const SizedBox(height: 8),
                _SpendRow(
                  icon: Icons.star_rounded,
                  color: const Color(0xFF2E8BEA),
                  title: tr(context, 'jd_super_like'),
                  subtitle: tr(context, 'jd_super_like_sub'),
                  cost: kSuperLikeCost,
                ),
                _SpendRow(
                  icon: Icons.bolt,
                  color: AppColors.magenta,
                  title: tr(context, 'jd_boost'),
                  subtitle: jodie.isBoosted
                      ? tr(context, 'jd_boost_on')
                      : tr(context, 'jd_boost_sub'),
                  cost: kBoostCost,
                  action: jodie.isBoosted
                      ? null
                      : () {
                          if (!jodie.boost()) {
                            toast(context, tr(context, 'jd_not_enough'));
                          } else {
                            toast(context, tr(context, 'jd_boost_on'));
                          }
                        },
                  actionLabel: tr(context, 'jd_use'),
                ),
                _SpendRow(
                  icon: Icons.visibility_outlined,
                  color: kPink,
                  title: tr(context, 'jd_likes'),
                  subtitle: tr(context, 'jd_reveal_sub'),
                  cost: kRevealCost,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({
    required this.day,
    required this.reward,
    required this.done,
    required this.today,
    required this.dayLabel,
  });

  final int day;
  final int reward;
  final bool done;
  final bool today;
  final String dayLabel;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: done
              ? const Color(0xFFE1F3E7)
              : today
                  ? const Color(0xFFFFF4DD)
                  : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: today ? kGold : Colors.transparent, width: 1.6),
        ),
        child: Column(
          children: [
            Icon(
              done ? Icons.check_circle : Icons.stars_rounded,
              size: 18,
              color: done ? const Color(0xFF1F8A4C) : kGold,
            ),
            const SizedBox(height: 3),
            Text('+$reward',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({
    required this.icon,
    required this.label,
    required this.reward,
    required this.done,
    required this.doneLabel,
    required this.goLabel,
    required this.onGo,
  });

  final IconData icon;
  final String label;
  final int reward;
  final bool done;
  final String doneLabel;
  final String goLabel;
  final VoidCallback onGo;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.magenta, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: kGold, size: 14),
                      const SizedBox(width: 3),
                      Text('+$reward',
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: done ? null : onGo,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: done ? const Color(0xFFE1F3E7) : AppColors.magenta,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(done ? doneLabel : goLabel,
                    style: TextStyle(
                        color: done ? const Color(0xFF1F8A4C) : Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5)),
              ),
            ),
          ],
        ),
      );
}

class _SpendRow extends StatelessWidget {
  const _SpendRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.cost,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final int cost;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w700)),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 12)),
                ],
              ),
            ),
            if (action != null && actionLabel != null)
              GestureDetector(
                onTap: action,
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.tint,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(actionLabel!,
                      style: const TextStyle(
                          color: AppColors.magenta,
                          fontWeight: FontWeight.w800,
                          fontSize: 12)),
                ),
              ),
            const Icon(Icons.stars_rounded, color: kGold, size: 16),
            const SizedBox(width: 3),
            Text('$cost',
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
          ],
        ),
      );
}

Future<void> showFiltersSheet(BuildContext context) =>
    _sheet<void>(context, (_) => const _FiltersSheet());

class _FiltersSheet extends StatefulWidget {
  const _FiltersSheet();

  @override
  State<_FiltersSheet> createState() => _FiltersSheetState();
}

class _FiltersSheetState extends State<_FiltersSheet> {
  RangeValues _range = jodie.ageFilter;

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _grabber(),
              Center(child: _title(tr(context, 'jd_filters'))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(tr(context, 'jd_age_range'),
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                  ),
                  Text('${_range.start.round()} – ${_range.end.round()}',
                      style: const TextStyle(
                          color: AppColors.magenta, fontWeight: FontWeight.w800)),
                ],
              ),
              RangeSlider(
                values: _range,
                min: 18,
                max: 60,
                divisions: 42,
                activeColor: AppColors.magenta,
                onChanged: (v) => setState(() => _range = v),
              ),
              const SizedBox(height: 12),
              _primaryButton(tr(context, 'jd_apply'), () {
                jodie.setAgeFilter(_range);
                Navigator.of(context).pop();
              }),
            ],
          ),
        ),
      );
}

Future<void> showMyProfileSheet(BuildContext context) =>
    _sheet<void>(context, (_) => const _MyProfileSheet());

class _MyProfileSheet extends StatefulWidget {
  const _MyProfileSheet();

  @override
  State<_MyProfileSheet> createState() => _MyProfileSheetState();
}

class _MyProfileSheetState extends State<_MyProfileSheet> {
  late Gender _gender = jodie.me.gender;
  late double _age = jodie.me.age.toDouble();
  late final _city = TextEditingController(text: jodie.me.city);
  late final _bio = TextEditingController(text: jodie.me.bio);
  late final Set<String> _langs = {...jodie.me.languages};
  late final Set<String> _ints = {...jodie.me.interests};

  static const _interestKeys = [
    'worship', 'music', 'travel', 'cooking', 'reading',
    'volunteering', 'fitness', 'photography', 'family', 'movies',
  ];

  @override
  void dispose() {
    _city.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _save() {
    jodie.updateMe((me) {
      me.gender = _gender;
      me.age = _age.round();
      me.city = _city.text.trim().isEmpty ? me.city : _city.text.trim();
      me.bio = _bio.text.trim();
      me.languages = _langs;
      me.interests = _ints;
    });
    jodie.completeTask('profile');
    Navigator.of(context).pop();
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
      );

  Widget _chip(String label, bool on, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: on ? AppColors.magenta : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border:
                Border.all(color: on ? AppColors.magenta : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: on ? Colors.white : AppColors.ink)),
        ),
      );

  InputDecoration _field(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _grabber(),
                Center(child: _title(tr(context, 'jd_my_profile'))),
                _label(tr(context, 'jd_i_am')),
                Row(
                  children: [
                    _chip(tr(context, 'jd_man'), _gender == Gender.man,
                        () => setState(() => _gender = Gender.man)),
                    const SizedBox(width: 10),
                    _chip(tr(context, 'jd_woman'), _gender == Gender.woman,
                        () => setState(() => _gender = Gender.woman)),
                  ],
                ),
                _label('${tr(context, 'jd_age')}: ${_age.round()}'),
                Slider(
                  value: _age,
                  min: 18,
                  max: 60,
                  divisions: 42,
                  activeColor: AppColors.magenta,
                  onChanged: (v) => setState(() => _age = v),
                ),
                _label(tr(context, 'jd_city')),
                TextField(controller: _city, decoration: _field('Dadar')),
                _label(tr(context, 'jd_about')),
                TextField(
                    controller: _bio, maxLines: 3, decoration: _field('')),
                _label(tr(context, 'jd_languages')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final l in AppLang.values)
                      _chip(l.native, _langs.contains(l.english), () {
                        setState(() => _langs.contains(l.english)
                            ? _langs.remove(l.english)
                            : _langs.add(l.english));
                      }),
                  ],
                ),
                _label(tr(context, 'jd_interests')),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final k in _interestKeys)
                      _chip(tr(context, 'int_$k'), _ints.contains(k), () {
                        setState(() =>
                            _ints.contains(k) ? _ints.remove(k) : _ints.add(k));
                      }),
                  ],
                ),
                const SizedBox(height: 20),
                _primaryButton(tr(context, 'ng_save'), _save),
              ],
            ),
          ),
        ),
      );
}

/// Full-screen "It's a match!" celebration.
Future<void> showMatchDialog(
  BuildContext context,
  JodieProfile profile, {
  required VoidCallback onMessage,
}) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'match',
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, _, _) => _MatchDialog(
        profile: profile,
        onMessage: onMessage,
      ),
      transitionBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.92, end: 1.0)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
          child: child,
        ),
      ),
    );

class _MatchDialog extends StatelessWidget {
  const _MatchDialog({required this.profile, required this.onMessage});

  final JodieProfile profile;
  final VoidCallback onMessage;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(gradient: AppColors.splashGradient),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 44),
                  const SizedBox(height: 14),
                  Text(tr(context, 'jd_its_a_match'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  Text(
                      tr(context, 'jd_match_sub',
                          args: {'name': profile.firstName}),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 15)),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      JodieAvatar.me(size: 110, border: true),
                      Transform.translate(
                        offset: const Offset(-18, 0),
                        child: JodieAvatar.of(profile, size: 110, border: true),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      onMessage();
                    },
                    child: Container(
                      height: 52,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Text(tr(context, 'jd_send_message'),
                          style: const TextStyle(
                              color: AppColors.magenta,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(tr(context, 'jd_keep_swiping'),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
