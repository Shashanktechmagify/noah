import 'package:flutter/material.dart';

import '../data/word_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';
import 'events/events_widgets.dart' show monthShort;
import 'jodie/jodie_widgets.dart' show toast;

String _shortDate(BuildContext context, DateTime d) =>
    '${d.day} ${monthShort(context, d.month)}';

/// Pale pill above a card title ("TODAY · 29 SEPTEMBER").
class _LabelPill extends StatelessWidget {
  const _LabelPill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF3E1F7),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text.toUpperCase(),
      style: TextStyle(
        color: AppColors.magenta,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: spacing(context, 0.6),
      ),
    ),
  );
}

/// The featured card: pill, title, text and scripture reference.
class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.pill,
    required this.title,
    required this.body,
    required this.ref,
  });

  final String pill;
  final String title;
  final String body;
  final String ref;

  @override
  Widget build(BuildContext context) => WhiteCard(
    padding: const EdgeInsets.all(18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelPill(pill),
        const SizedBox(height: 14),
        Text(
          title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          style: const TextStyle(
            color: Color(0xFF55576F),
            fontSize: 14.5,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          ref,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

/// Save and PDF buttons under the featured card.
class _SaveRow extends StatefulWidget {
  const _SaveRow();

  @override
  State<_SaveRow> createState() => _SaveRowState();
}

class _SaveRowState extends State<_SaveRow> {
  bool _saved = false;

  Widget _button({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.tint,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: const Color(0xFF555770)),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF555770),
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
    child: Row(
      children: [
        _button(
          icon: _saved ? Icons.favorite : Icons.favorite_border,
          label: tr(context, 'wf_save'),
          onTap: () {
            setState(() => _saved = !_saved);
            toast(context, tr(context, _saved ? 'wf_saved' : 'wf_unsaved'));
          },
        ),
        const SizedBox(width: 12),
        _button(
          icon: Icons.insert_drive_file_outlined,
          label: tr(context, 'wf_pdf'),
          // A real PDF needs the backend (or a PDF plugin).
          onTap: () => toast(context, tr(context, 'wf_pdf_note')),
        ),
      ],
    ),
  );
}

/// Daily prayers: today's prayer and the earlier ones this week.
class DailyPrayersScreen extends StatelessWidget {
  const DailyPrayersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = kPrayers.first;
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'dp_title'),
        subtitle: tr(context, 'dp_sub'),
        leadingIcon: Icons.chevron_left,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          _FeatureCard(
            pill: tr(
              context,
              'dp_today',
              args: {'date': '${now.day} ${tr(context, 'mo_${now.month}')}'},
            ),
            title: today.title,
            body: today.body,
            ref: today.ref,
          ),
          const _SaveRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
            child: Text(
              tr(context, 'dp_earlier'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          WhiteCard(
            child: Column(
              children: [
                for (var i = 1; i < kPrayers.length; i++) ...[
                  if (i > 1) const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.tint,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.self_improvement,
                            color: Color(0xFF55576F),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kPrayers[i].title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${_shortDate(context, now.subtract(Duration(days: kPrayers[i].daysAgo)))} · ${kPrayers[i].ref}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          text: tr(context, 'dp_read'),
                          background: const Color(0xFFDDF3E4),
                          foreground: const Color(0xFF1F8A4C),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const _themeIcons = {
  'healing': Icons.menu_book_outlined,
  'provision': Icons.menu_book_outlined,
  'family': Icons.menu_book_outlined,
  'peace': Icons.menu_book_outlined,
  'protection': Icons.menu_book_outlined,
};

/// Words of Faith: confession of the day and a list to browse by theme.
class WordsOfFaithScreen extends StatefulWidget {
  const WordsOfFaithScreen({super.key});

  @override
  State<WordsOfFaithScreen> createState() => _WordsOfFaithScreenState();
}

class _WordsOfFaithScreenState extends State<WordsOfFaithScreen> {
  String _theme = kConfessionThemes.first.$1;

  @override
  Widget build(BuildContext context) {
    final featured = kConfessions.first;
    // The chosen theme's confessions come first.
    final rest = kConfessions.skip(1).toList()
      ..sort((a, b) {
        final ai = a.theme == _theme ? 0 : 1;
        final bi = b.theme == _theme ? 0 : 1;
        return ai.compareTo(bi);
      });
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'wf_title'),
        subtitle: tr(context, 'wf_sub'),
        leadingIcon: Icons.chevron_left,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          _FeatureCard(
            pill: tr(context, 'wf_cotd'),
            title: featured.title,
            body: featured.body,
            ref: featured.ref,
          ),
          const _SaveRow(),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
            child: Text(
              tr(context, 'wf_by_theme'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: kConfessionThemes.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final (id, key) = kConfessionThemes[i];
                final on = id == _theme;
                return GestureDetector(
                  onTap: () => setState(() => _theme = id),
                  child: SizedBox(
                    width: 66,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: on ? AppColors.magenta : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: on ? AppColors.magenta : AppColors.border,
                            ),
                          ),
                          child: Icon(
                            _themeIcons[id],
                            color: on ? Colors.white : const Color(0xFF555770),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tr(context, key),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: on ? FontWeight.w800 : FontWeight.w600,
                            color: on ? AppColors.ink : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          for (final c in rest)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: WhiteCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      c.ref,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
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

/// Bible commentary for the chapter being studied.
class CommentaryScreen extends StatelessWidget {
  const CommentaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageScaffold(
        title: tr(context, 'cm_title'),
        subtitle: tr(
          context,
          'cm_sub',
          args: {'book': kCommentaryBook, 'n': '$kCommentaryChapter'},
        ),
        leadingIcon: Icons.chevron_left,
        onLeading: () => Navigator.of(context).pop(),
        children: [
          WhiteCard(
            child: Column(
              children: [
                for (var i = 0; i < kCommentary.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  InkWell(
                    onTap: () => toast(context, tr(context, 'cm_soon')),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.magenta,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${kCommentary[i].ref} · ${kCommentary[i].title}',
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tr(context, 'cm_read'),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// eBooks: the ministry's books to read.
class EbooksScreen extends StatelessWidget {
  const EbooksScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageScaffold(
      title: tr(context, 'eb_title'),
      subtitle: tr(context, 'eb_sub'),
      leadingIcon: Icons.chevron_left,
      onLeading: () => Navigator.of(context).pop(),
      children: [
        WhiteCard(
          child: Column(
            children: [
              for (final (i, b) in kEbooks.indexed) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.border),
                InkWell(
                  onTap: () => toast(context, tr(context, 'eb_soon')),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 60,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: i.isEven
                                  ? const [Color(0xFF6A2DA8), Color(0xFF9B3BC0)]
                                  : const [
                                      Color(0xFFB41FC8),
                                      Color(0xFFE766B8),
                                    ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.menu_book_outlined,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.title,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${b.author} · ${tr(context, 'eb_pages', args: {'n': '${b.pages}'})}',
                                style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusPill(
                          text: tr(context, 'eb_read'),
                          background: const Color(0xFFF1E4F8),
                          foreground: AppColors.magenta,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    ),
  );
}

/// Praises: swipe through members' testimonies.
class PraisesScreen extends StatefulWidget {
  const PraisesScreen({super.key});

  @override
  State<PraisesScreen> createState() => _PraisesScreenState();
}

class _PraisesScreenState extends State<PraisesScreen> {
  final _page = PageController();
  int _index = 0;
  bool _music = true; // demo toggle: no audio plays yet
  final _amened = <int>{};

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageScaffold(
      title: tr(context, 'pz_title'),
      subtitle: tr(context, 'pz_sub'),
      leadingIcon: Icons.chevron_left,
      onLeading: () => Navigator.of(context).pop(),
      children: [
        WhiteCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  gradient: AppColors.buttonGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'pz_music'),
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      tr(context, _music ? 'pz_playing' : 'pz_paused'),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _music = !_music),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.buttonGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _music ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr(context, _music ? 'pz_pause' : 'pz_play'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: PageView.builder(
            controller: _page,
            itemCount: kPraises.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (_, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _PraiseCard(
                praise: kPraises[i],
                amened: _amened.contains(i),
                onAmen: () => setState(() {
                  _amened.contains(i) ? _amened.remove(i) : _amened.add(i);
                }),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < kPraises.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _index ? 20 : 6,
                height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.magenta
                      : const Color(0xFFCFD2E6),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            '${_index + 1}/${kPraises.length}',
            style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const PraiseListScreen())),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insert_drive_file_outlined,
                    size: 18,
                    color: Color(0xFF555770),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tr(context, 'pz_read_all'),
                    style: const TextStyle(
                      color: Color(0xFF555770),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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

class _PraiseCard extends StatelessWidget {
  const _PraiseCard({
    required this.praise,
    required this.amened,
    required this.onAmen,
  });

  final Praise praise;
  final bool amened;
  final VoidCallback onAmen;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF6A2DA8), Color(0xFFB04ACB)],
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.favorite_border, color: Colors.white),
        ),
        const SizedBox(height: 16),
        Text(
          tr(context, 'pz_report').toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: spacing(context, 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          praise.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Text(
            praise.body,
            overflow: TextOverflow.fade,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 14.5,
              height: 1.4,
            ),
          ),
        ),
        Text(
          '${praise.author} · ${praise.place} · ${tr(context, 'pz_days_ago', args: {'n': '${praise.daysAgo}'})}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onAmen,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (amened)
                  const Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.check,
                      size: 16,
                      color: AppColors.magenta,
                    ),
                  ),
                Text(
                  tr(context, 'pz_amen'),
                  style: const TextStyle(
                    color: AppColors.magenta,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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

/// Every praise report in one list.
class PraiseListScreen extends StatelessWidget {
  const PraiseListScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: PageScaffold(
      title: tr(context, 'pz_title'),
      subtitle: tr(context, 'pz_read_all'),
      leadingIcon: Icons.chevron_left,
      onLeading: () => Navigator.of(context).pop(),
      children: [
        for (final p in kPraises)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: WhiteCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    p.body,
                    style: const TextStyle(
                      color: Color(0xFF55576F),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${p.author} · ${p.place} · ${tr(context, 'pz_days_ago', args: {'n': '${p.daysAgo}'})}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
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
