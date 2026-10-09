import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/page_scaffold.dart';

class _Video {
  const _Video(this.id, this.category, this.minutes, this.views, this.colors);

  final String id; // also the translation key of the title
  final String category; // translation key
  final int minutes;
  final String views;
  final List<Color> colors;
}

const _videos = [
  _Video('v1', 'tile_sermons', 42, '3.4K', [Color(0xFF5E2CA5), Color(0xFF9B3BB8)]),
  _Video('v2', 'nt_worship', 18, '5.1K', [Color(0xFFA0267F), Color(0xFFD65AA8)]),
  _Video('v3', 'nt_testimonies', 9, '2.2K', [Color(0xFF3F3C9E), Color(0xFF7C6BD6)]),
  _Video('v4', 'nt_kids', 12, '1.8K', [Color(0xFFC2620A), Color(0xFFE79A3C)]),
  _Video('v5', 'tile_sermons', 35, '2.9K', [Color(0xFF7B35B0), Color(0xFFB05BC4)]),
  _Video('v6', 'nt_worship', 14, '4.0K', [Color(0xFF8E1FB0), Color(0xFFC13FBF)]),
];

const _shorts = [
  ('sh1', [Color(0xFF6A2DA8), Color(0xFFA43FB5)]),
  ('sh2', [Color(0xFF3F3C9E), Color(0xFF7C6BD6)]),
  ('sh3', [Color(0xFFA0267F), Color(0xFFD65AA8)]),
  ('sh4', [Color(0xFFC2620A), Color(0xFFE79A3C)]),
];

// Filter chips: translation key -> category key it matches (null = all).
const _filters = [
  ('nt_all', null),
  ('tile_sermons', 'tile_sermons'),
  ('nt_worship', 'nt_worship'),
  ('nt_testimonies', 'nt_testimonies'),
  ('nt_kids', 'nt_kids'),
];

class NoahtubeScreen extends StatefulWidget {
  const NoahtubeScreen({super.key});

  @override
  State<NoahtubeScreen> createState() => _NoahtubeScreenState();
}

class _NoahtubeScreenState extends State<NoahtubeScreen> {
  int _filter = 0;

  @override
  Widget build(BuildContext context) {
    final category = _filters[_filter].$2;
    final shown =
        _videos.where((v) => category == null || v.category == category).toList();
    return PageScaffold(
      title: 'Noahtube',
      subtitle: tr(context, 'nt_sub'),
      leadingIcon: Icons.videocam_outlined,
      children: [
        _SearchBar(hint: tr(context, 'nt_search')),
        const SizedBox(height: 14),
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final on = i == _filter;
              return GestureDetector(
                onTap: () => setState(() => _filter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: on ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: on ? const Color(0xFF1E1E1E) : AppColors.magenta),
                  ),
                  child: Text(
                    tr(context, _filters[i].$1),
                    style: TextStyle(
                      fontSize: 13.5,
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
        if (category == null) ...[
          const _LiveCard(),
          const SizedBox(height: 22),
          SectionTitle(title: tr(context, 'nt_shorts')),
          const SizedBox(height: 12),
          const _ShortsRow(),
          const SizedBox(height: 22),
        ],
        SectionTitle(title: tr(context, 'nt_latest')),
        const SizedBox(height: 12),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(tr(context, 'nt_none'),
                  style: const TextStyle(color: AppColors.muted)),
            ),
          )
        else
          for (final v in shown) _VideoCard(video: v),
      ],
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.hint});

  final String hint;

  @override
  Widget build(BuildContext context) => Container(
        height: 48,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleDeep.withValues(alpha: 0.10),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.muted, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle:
                      const TextStyle(color: AppColors.muted, fontSize: 14),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
          ],
        ),
      );
}

class _LiveCard extends StatelessWidget {
  const _LiveCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 190,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5E2CA5), Color(0xFFB62FC4)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Colors.white, size: 36),
            ),
          ),
          Positioned(
            left: 16,
            top: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFE5334B),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(tr(context, 'nt_live'),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 14,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(context, 'nt_live_title'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(tr(context, 'nt_live_meta'),
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShortsRow extends StatelessWidget {
  const _ShortsRow();

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 190,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _shorts.length,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (_, i) {
            final (id, colors) = _shorts[i];
            return Container(
              width: 115,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: colors,
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.play_circle_outline,
                      color: Colors.white.withValues(alpha: 0.9), size: 24),
                  const Spacer(),
                  Text(
                    tr(context, id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({required this.video});

  final _Video video;

  @override
  Widget build(BuildContext context) {
    final meta = '${tr(context, video.category)} · ${video.minutes} '
        '${tr(context, 'unit_min')} · ${video.views} ${tr(context, 'unit_views')}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: video.colors,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.white, size: 30),
                    ),
                  ),
                  Positioned(
                    right: 10,
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${video.minutes}:00',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(tr(context, video.id),
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(meta,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}
