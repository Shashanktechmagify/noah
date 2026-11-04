import 'package:flutter/material.dart';

import '../data/api_client.dart' show liveApi;
import '../data/content_data.dart';
import '../data/manna_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_scaffold.dart' show GradientButton;
import '../widgets/content_card.dart';
import '../widgets/engagement_bar.dart';
import '../data/manna_engagement.dart';
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
class MannaScreen extends StatefulWidget {
  const MannaScreen({super.key});

  @override
  State<MannaScreen> createState() => _MannaScreenState();
}

class _MannaScreenState extends State<MannaScreen> {
  @override
  void initState() {
    super.initState();
    // Likes, views and comments move all day: opening the list reads them again if the copy is a few minutes old.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        contentState.ensureFresh(
          AppLocale.of(context).lang,
          maxAge: const Duration(minutes: 5),
        );
      }
    });
  }

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
                footer: liveApi ? EngagementBar(manna: m) : null,
                onTap: () => openManna(context, m),
              ),
          ],
        ),
      ),
    );
  }
}

class MannaDetailScreen extends StatefulWidget {
  const MannaDetailScreen({super.key, required this.manna});

  final Manna manna;

  @override
  State<MannaDetailScreen> createState() => _MannaDetailScreenState();
}

class _MannaDetailScreenState extends State<MannaDetailScreen> {
  Manna get manna => widget.manna;

  @override
  void initState() {
    super.initState();
    // Counts a view (once per member) and reads the comments.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => engagementOf(manna).open(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageScaffold(
        // A shorter purple band, so the date, title and reading all sit on the white page.
        bandHeight: 84,
        title: tr(context, 'manna_daily'),
        subtitle: manna.ref.isEmpty
            ? _whenText(context, manna.daysAgo)
            : '${_whenText(context, manna.daysAgo)} · ${manna.ref}',
        leadingIcon: Icons.arrow_back,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          const SizedBox(height: 4),
          // The day, the title and who wrote it.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MannaDateTitle(
              manna: manna,
              title: tr(context, manna.titleKey),
            ),
          ),
          const SizedBox(height: 16),
          // A picture the office attached to this Manna. Tap it to see it full screen.
          if (manna.image != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: EntryImage(manna.image),
            ),
          if (manna.ref.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${tr(context, 'manna_categories')} : ',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    TextSpan(
                      text: manna.ref,
                      style: const TextStyle(
                        color: AppColors.magenta,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
          if (liveApi)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: MannaStatsRow(manna: manna),
            ),
          const SizedBox(height: 18),
          // The office's Manna has the scripture inside its message; only the sample content has a separate verse.
          if (manna.verse.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding: const EdgeInsets.only(left: 14),
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: AppColors.magenta, width: 3),
                  ),
                ),
                child: Text(
                  '“${manna.verse}”',
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.45,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          // Bold, italic, lists and links written in the admin console come through as formatted text.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: RichHtml(
              manna.reflection,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
          const SizedBox(height: 18),
          if (manna.prayer.isNotEmpty) ...[
            const Divider(height: 1, indent: 20, endIndent: 20),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                tr(
                  context,
                  manna.closingConfession ? 'manna_confession' : 'manna_prayer',
                ),
                style: const TextStyle(
                  color: AppColors.magenta,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RichHtml(
                manna.prayer,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
          if (liveApi)
            ListenableBuilder(
              listenable: engagementOf(manna),
              builder: (context, _) {
                final n = engagementOf(manna).commentCount;
                return GestureDetector(
                  onTap: () => showMannaComments(context, manna),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: AppColors.magenta,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            n > 0
                                ? tr(
                                    context,
                                    'manna_view_all_comments',
                                    args: {'n': '$n'},
                                  )
                                : tr(context, 'manna_add_comment'),
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.muted),
                      ],
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GradientButton(
              label: tr(context, 'pr_add'),
              onPressed: () => showPrayerDialog(context, manna: manna),
            ),
          ),
          if (liveApi) _MostRead(current: manna),
        ],
      ),
    );
  }
}

/// The five Mannas read the most, as a bulleted list of links under the page.
class _MostRead extends StatelessWidget {
  const _MostRead({required this.current});

  final Manna current;

  @override
  Widget build(BuildContext context) {
    final top = [...contentState.mannas]
      ..sort((a, b) {
        final byViews = b.views.compareTo(a.views);
        return byViews != 0 ? byViews : a.daysAgo.compareTo(b.daysAgo);
      });
    final shown = top.where((m) => m.views > 0).take(5).toList();
    if (shown.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'manna_most_read'),
            style: const TextStyle(
              color: AppColors.magenta,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          for (final m in shown)
            InkWell(
              onTap: m.id == current.id
                  ? null
                  : () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => MannaDetailScreen(manna: m),
                      ),
                    ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7, right: 10),
                      child: Icon(Icons.circle, size: 8),
                    ),
                    Expanded(
                      child: Text(
                        tr(context, m.titleKey),
                        style: const TextStyle(
                          color: AppColors.magenta,
                          fontSize: 17,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
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
