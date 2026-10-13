import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import '../widgets/event_carousel.dart';
import '../widgets/hex_pattern.dart';
import '../widgets/page_scaffold.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _chipKeys = [
    'chip_community',
    'the_word',
    'chip_media',
    'chip_church',
  ];
  int _chip = 0;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Stack(
      children: [
        // Purple header band sits behind the top of the carousel.
        Container(
          height: top + 150,
          decoration: const BoxDecoration(gradient: AppColors.headerGradient),
          child: const HexPattern(),
        ),
        ListView(
          padding: EdgeInsets.only(top: top + 14, bottom: 120),
          children: [
            const _Header(),
            const SizedBox(height: 18),
            const EventCarousel(),
            const SizedBox(height: 22),
            SectionTitle(
              title: tr(context, 'today_reading'),
              action: tr(context, 'the_word'),
            ),
            const SizedBox(height: 12),
            const _ReadingCard(),
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chipKeys.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final on = i == _chip;
                  return GestureDetector(
                    onTap: () => setState(() => _chip = i),
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
                        tr(context, _chipKeys[i]),
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
            const _FeatureGrid(),
          ],
        ),
      ],
    );
  }
}

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
            child: const Icon(Icons.notifications_none,
                color: Colors.white, size: 22),
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
    return WhiteCard(
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
            child: const Icon(Icons.menu_book_outlined,
                color: Colors.white, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr(context, 'reading_title'),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(tr(context, 'reading_meta'),
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
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
            child: Text(tr(context, 'today'),
                style: const TextStyle(
                    color: AppColors.magenta,
                    fontSize: 12,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature({
    this.brand,
    this.titleKey,
    required this.subKey,
    required this.icon,
    required this.colors,
  });

  final String? brand;
  final String? titleKey;
  final String subKey;
  final IconData icon;
  final List<Color> colors;
}

const _features = [
  _Feature(
      brand: 'Noahgram',
      subKey: 'tile_noahgram_sub',
      icon: Icons.grid_view_rounded,
      colors: [Color(0xFF6A2DA8), Color(0xFF8E3BB8)]),
  _Feature(
      titleKey: 'tile_polls',
      subKey: 'tile_polls_sub',
      icon: Icons.flag_outlined,
      colors: [Color(0xFF9B2BB8), Color(0xFFB83FC8)]),
  _Feature(
      titleKey: 'tile_giving',
      subKey: 'tile_giving_sub',
      icon: Icons.favorite_border,
      colors: [Color(0xFF55269C), Color(0xFF7B35B0)]),
  _Feature(
      titleKey: 'tile_sermons',
      subKey: 'tile_sermons_sub',
      icon: Icons.mic_none,
      colors: [Color(0xFF8E3BB8), Color(0xFFB05BC4)]),
];

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [for (final f in _features) _FeatureTile(feature: f)],
      ),
    );
  }
}

class _FeatureTile extends StatelessWidget {
  const _FeatureTile({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: feature.colors,
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
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(feature.icon, color: Colors.white, size: 19),
                  ),
                  const Spacer(),
                  Text(
                    feature.brand ?? tr(context, feature.titleKey!),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    tr(context, feature.subKey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
