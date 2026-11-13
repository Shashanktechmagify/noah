import 'package:flutter/material.dart';

import '../data/library_data.dart';
import '../l10n/app_strings.dart';
import 'content_card.dart' show plainPreview;
import 'event_carousel.dart';

/// The cards at the top of the home screen, as they always were (scrolling by themselves, a card tilts when touched),
/// but with what the office wrote in the console: its banners first, then its announcements. With nothing to show
/// it takes no room.
class HomeCarousel extends StatefulWidget {
  const HomeCarousel({super.key});

  /// The banners then the announcements, as carousel cards.
  static List<HomeSlide> slidesOf(BuildContext context, List<LibBanner> banners, List<LibAnnouncement> notices) => [
    for (final b in banners)
      HomeSlide(
        title: b.caption,
        image: b.picture,
        url: b.url,
        cta: tr(context, 'ann_open'),
      ),
    for (final a in notices)
      HomeSlide(
        label: tr(context, 'ann_title').toUpperCase(),
        title: a.title,
        body: a.message == null ? '' : plainPreview(a.message!),
        url: a.link,
        cta: tr(context, 'ann_open'),
      ),
  ];

  @override
  State<HomeCarousel> createState() => _HomeCarouselState();
}

class _HomeCarouselState extends State<HomeCarousel> {
  @override
  void initState() {
    super.initState();
    library.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    library.removeListener(_changed);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = HomeCarousel.slidesOf(context, library.banners, library.announcements);
    if (slides.isEmpty) return const SizedBox.shrink();
    // A new key when the cards change, so the carousel starts again on the first one.
    return EventCarousel(
      key: ValueKey(slides.map((s) => '${s.title}|${s.image}|${s.url}').join('\n')),
      slides: slides,
    );
  }
}
