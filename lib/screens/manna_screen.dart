import 'package:flutter/material.dart';

import '../data/content_data.dart';
import '../data/manna_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart' show GradientButton;
import '../widgets/content_card.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_dialog.dart';
import '../widgets/rich_html.dart';

String _whenText(BuildContext context, int daysAgo) => switch (daysAgo) {
  0 => tr(context, 'today'),
  1 => tr(context, 'manna_yesterday'),
  _ => tr(context, 'manna_days_ago', args: {'n': '$daysAgo'}),
};

void openManna(BuildContext context, Manna manna) {
  Navigator.of(context)
      .push(MaterialPageRoute(builder: (_) => MannaDetailScreen(manna: manna)));
}

/// "View full": the last few daily Mannas, as picture cards.
class MannaScreen extends StatelessWidget {
  const MannaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: contentState,
        builder: (context, _) => PageScaffold(
          onRefresh: () => contentState.refresh(AppLocale.of(context).lang),
          title: tr(context, 'manna_daily'),
          subtitle: tr(context, 'manna_sub'),
          leadingIcon: Icons.arrow_back,
          onLeading: () => Navigator.of(context).pop(),
          children: [
            if (contentState.mannas.isEmpty)
              ContentEmpty(loading: contentState.loading),
            for (final m in contentState.mannas)
              ContentCard(
                image: m.image,
                title: tr(context, m.titleKey),
                meta:
                    '${m.ref.isEmpty ? '' : '${m.ref} · '}${m.minutes} ${tr(context, 'unit_min')}',
                badge: _whenText(context, m.daysAgo),
                onTap: () => openManna(context, m),
              ),
          ],
        ),
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
        subtitle: manna.ref.isEmpty
            ? _whenText(context, manna.daysAgo)
            : '${_whenText(context, manna.daysAgo)} · ${manna.ref}',
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
                // The office's Manna has the scripture inside its message; only the sample content has a separate verse.
                if (manna.verse.isNotEmpty) ...[
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
              ],
            ),
          ),
          if (manna.writer.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text(
                tr(context, 'manna_writer', args: {'name': manna.writer}),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 20),
          // A picture the office attached to this Manna.
          if (manna.image != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: EntryImage(manna.image),
            ),
          SectionTitle(title: tr(context, 'manna_reflection')),
          const SizedBox(height: 10),
          WhiteCard(
            padding: const EdgeInsets.all(16),
            // Bold, italic, lists and links written in the admin console come through as formatted text.
            child: RichHtml(
              manna.reflection,
              style: const TextStyle(fontSize: 14.5, height: 1.5),
            ),
          ),
          const SizedBox(height: 20),
          if (manna.prayer.isNotEmpty) ...[
            SectionTitle(
              title: tr(
                context,
                manna.closingConfession ? 'manna_confession' : 'manna_prayer',
              ),
            ),
            const SizedBox(height: 10),
            WhiteCard(
              padding: const EdgeInsets.all(16),
              child: RichHtml(
                manna.prayer,
                style: const TextStyle(
                  fontSize: 14.5,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
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

/// What a list shows while the office's content is loading, or when there is none yet.
class ContentEmpty extends StatelessWidget {
  const ContentEmpty({super.key, required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    child: Center(
      child: loading
          ? const CircularProgressIndicator()
          : Text(
              tr(context, 'content_empty'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 14,
                height: 1.4,
              ),
            ),
    ),
  );
}
