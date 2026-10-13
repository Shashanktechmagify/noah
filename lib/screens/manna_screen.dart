import 'package:flutter/material.dart';

import '../data/manna_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart' show GradientButton;
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_dialog.dart';

String _whenText(BuildContext context, int daysAgo) => switch (daysAgo) {
  0 => tr(context, 'today'),
  1 => tr(context, 'manna_yesterday'),
  _ => tr(context, 'manna_days_ago', args: {'n': '$daysAgo'}),
};

void openManna(BuildContext context, Manna manna) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => MannaDetailScreen(manna: manna)));
}

/// "View full": the last few daily Mannas.
class MannaScreen extends StatelessWidget {
  const MannaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'manna_daily'),
        subtitle: tr(context, 'manna_sub'),
        leadingIcon: Icons.arrow_back,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          for (final m in kMannas)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GestureDetector(
                onTap: () => openManna(context, m),
                child: WhiteCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const IconTile(icon: Icons.menu_book_outlined),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tr(context, m.titleKey),
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${m.ref} · ${m.minutes} ${tr(context, 'unit_min')}',
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: m.daysAgo == 0
                              ? AppColors.tint
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _whenText(context, m.daysAgo),
                          style: TextStyle(
                            color: m.daysAgo == 0
                                ? AppColors.magenta
                                : AppColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
}

class MannaDetailScreen extends StatelessWidget {
  const MannaDetailScreen({super.key, required this.manna});

  final Manna manna;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'manna_daily'),
        subtitle: '${_whenText(context, manna.daysAgo)} · ${manna.ref}',
        leadingIcon: Icons.arrow_back,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          // Verse
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: AppColors.headerGradient,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2A0A55).withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr(context, manna.titleKey),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '“${manna.verse}”',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  manna.ref,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: tr(context, 'manna_reflection')),
          const SizedBox(height: 10),
          WhiteCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              manna.reflection,
              style: const TextStyle(fontSize: 14.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          SectionTitle(title: tr(context, 'manna_prayer')),
          const SizedBox(height: 10),
          WhiteCard(
            padding: const EdgeInsets.all(16),
            child: Text(
              manna.prayer,
              style: const TextStyle(
                fontSize: 14.5,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: tr(context, 'pr_add'),
              onPressed: () => showPrayerDialog(context, manna: manna),
            ),
          ),
        ],
      ),
    );
  }
}
