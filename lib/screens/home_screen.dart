import 'package:flutter/material.dart';

import '../data/manna_data.dart';
import '../data/word_data.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/event_carousel.dart';
import '../widgets/header_band.dart';
import '../widgets/page_scaffold.dart';
import '../widgets/prayer_dialog.dart';
import 'events/events_widgets.dart' show monthShort;
import 'manna_screen.dart';
import 'word_screens.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _tabKeys = [
    'tab_prayers',
    'tab_confessions',
    'tab_commentary',
    'tab_ebooks',
    'tab_praises',
  ];
  int _tab = 0;
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  /// The three tiles of the selected tab, then "View all".
  List<Widget> _tiles(BuildContext context) {
    final now = DateTime.now();
    switch (_tab) {
      case 0:
        return [
          for (var i = 0; i < 3; i++)
            _WordTile(
              icon: Icons.self_improvement,
              title: kPrayers[i].title,
              sub:
                  '${now.subtract(Duration(days: kPrayers[i].daysAgo)).day} '
                  '${monthShort(context, now.subtract(Duration(days: kPrayers[i].daysAgo)).month)}'
                  ' · ${kPrayers[i].ref}',
              colors: _tileColors[i],
              onTap: () => _push(const DailyPrayersScreen()),
            ),
          _ViewAllTile(
            label: tr(context, 'all_prayers'),
            onTap: () => _push(const DailyPrayersScreen()),
          ),
        ];
      case 1:
        return [
          for (var i = 0; i < 3; i++)
            _WordTile(
              icon: Icons.favorite_border,
              title: kConfessions[i].title,
              sub: kConfessions[i].ref,
              colors: _tileColors[i],
              onTap: () => _push(const WordsOfFaithScreen()),
            ),
          _ViewAllTile(
            label: tr(context, 'all_confessions'),
            onTap: () => _push(const WordsOfFaithScreen()),
          ),
        ];
      case 2:
        return [
          for (var i = 0; i < 3; i++)
            _WordTile(
              icon: Icons.insert_drive_file_outlined,
              title: kCommentary[i].title,
              sub: kCommentary[i].ref,
              colors: _tileColors[i],
              onTap: () => _push(const CommentaryScreen()),
            ),
          _ViewAllTile(
            label: tr(context, 'all_commentary'),
            onTap: () => _push(const CommentaryScreen()),
          ),
        ];
      case 3:
        return [
          for (var i = 0; i < 3; i++)
            _WordTile(
              icon: Icons.menu_book_outlined,
              title: kEbooks[i].title,
              sub: kEbooks[i].author,
              colors: _tileColors[i],
              onTap: () => _push(const EbooksScreen()),
            ),
          _ViewAllTile(
            label: tr(context, 'all_ebooks'),
            onTap: () => _push(const EbooksScreen()),
          ),
        ];
      default:
        return [
          for (var i = 0; i < 3; i++)
            _WordTile(
              icon: Icons.favorite_border,
              title: kPraises[i].title,
              sub: '${kPraises[i].author} · ${kPraises[i].place}',
              colors: _tileColors[i],
              onTap: () => _push(const PraisesScreen()),
            ),
          _ViewAllTile(
            label: tr(context, 'all_praises'),
            onTap: () => _push(const PraisesScreen()),
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        // Purple header band sits behind the top of the carousel.
        HeaderBand(controller: _scroll),
        ListView(
          controller: _scroll,
          padding: EdgeInsets.only(top: top + 14, bottom: 120),
          children: [
            const _Header(),
            const SizedBox(height: 18),
            const EventCarousel(),
            const SizedBox(height: 22),
            SectionTitle(
              title: tr(context, 'home_manna_title'),
              action: tr(context, 'home_view_all'),
              onAction: () => _push(const MannaScreen()),
            ),
            const SizedBox(height: 12),
            const _ReadingCard(),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _tabKeys.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final on = i == _tab;
                  return GestureDetector(
                    onTap: () => setState(() => _tab = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: on ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: on
                              ? const Color(0xFF1E1E1E)
                              : AppColors.magenta,
                        ),
                      ),
                      child: Text(
                        tr(context, _tabKeys[i]),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: on ? Colors.white : AppColors.ink,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                key: ValueKey(_tab),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                children: _tiles(context),
              ),
            ),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                tr(context, 'pr_req_title'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const _PrayerRequestCard(),
          ],
        ),
      ],
    );
  }
}

const _tileColors = [
  [Color(0xFF6A2DA8), Color(0xFF9B3BC0)],
  [Color(0xFFB41FC8), Color(0xFFE766B8)],
  [Color(0xFF5B2AA0), Color(0xFF8E3BB8)],
];

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/images/noah.png', width: 48, height: 48),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Karuna Sadan',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_none,
              color: Colors.white,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingCard extends StatelessWidget {
  const _ReadingCard();

  @override
  Widget build(BuildContext context) {
    final m = kMannas.first;
    return GestureDetector(
      onTap: () => openManna(context, m),
      child: WhiteCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.menu_book_outlined,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
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
                    tr(
                      context,
                      'home_manna_meta',
                      args: {'ref': m.ref, 'n': '${m.minutes}'},
                    ),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.tint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                tr(context, 'today'),
                style: const TextStyle(
                  color: AppColors.magenta,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gradient tile for a prayer, confession or commentary entry.
class _WordTile extends StatelessWidget {
  const _WordTile({
    required this.icon,
    required this.title,
    required this.sub,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String sub;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -28,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Dashed "View all" tile closing each grid.
class _ViewAllTile extends StatelessWidget {
  const _ViewAllTile({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: CustomPaint(
      painter: _DashedRRect(),
      child: Container(
        padding: const EdgeInsets.all(14),
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E1F7),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.magenta,
                size: 18,
              ),
            ),
            const Spacer(),
            Text(
              tr(context, 'home_view_all'),
              style: const TextStyle(
                color: AppColors.magenta,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
            ),
          ],
        ),
      ),
    ),
  );
}

class _DashedRRect extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(22),
    );
    canvas.drawRRect(r, Paint()..color = Colors.white);
    final paint = Paint()
      ..color = AppColors.magenta
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (final m in (Path()..addRRect(r)).computeMetrics()) {
      var d = 0.0;
      while (d < m.length) {
        canvas.drawPath(m.extractPath(d, d + 4), paint);
        d += 7;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRRect old) => false;
}

/// "Do you need prayers?" card: tapping the field opens the request popup.
class _PrayerRequestCard extends StatelessWidget {
  const _PrayerRequestCard();

  @override
  Widget build(BuildContext context) => WhiteCard(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          tr(context, 'pr_req_q'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          tr(context, 'pr_req_sub'),
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 13,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => showPrayerDialog(context),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.self_improvement,
                  size: 20,
                  color: AppColors.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    tr(context, 'pr_hint'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14.5),
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
