import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/bible_books.dart';
import 'package:noah_frontend_flutter/data/library_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/banner_carousel.dart';
import 'package:noah_frontend_flutter/widgets/event_carousel.dart'
    show HomeSlide, enableCardIdleSway;

Widget _app(Widget home) => AppLocale(
  controller: LocaleController(),
  child: MaterialApp(
    theme: buildTheme(),
    home: Scaffold(body: SingleChildScrollView(child: home)),
  ),
);

void main() {
  test('the books of the Bible are numbered as the office numbers them', () {
    expect(kBibleBooks.length, 66);
    expect(bibleRef(1, 1), 'Genesis 1');
    expect(bibleRef(45, 8), 'Romans 8');
    expect(bibleRef(66, 22), 'Revelation 22');
    expect(bibleRef(29, 0), 'Joel');
    expect(bibleRef(0, 3), '');
    expect(bibleRef(99, 3), '');
    expect(kBibleBooks[18], ('Psalms', 150));
  });

  test(
    'banners, announcements, dictionary entries and commentary read from what the server sends',
    () {
      final b = LibBanner.fromJson({
        'id': '1',
        'caption': 'Sunday service',
        'landscapeImage': 'https://pics.example/l.jpg',
        'portraitImage': null,
        'url': 'javascript:alert(1)',
      });
      expect(
        b.picture,
        'https://pics.example/l.jpg',
        reason: 'a phone takes the portrait picture, else the other one',
      );
      expect(b.url, isNull, reason: 'only a web address opens');

      final a = LibAnnouncement.fromJson({
        'id': '2',
        'title': 'Camp',
        'message': '',
        'link': 'https://example.org/camp',
      });
      expect(a.message, isNull);
      expect(a.link, 'https://example.org/camp');

      final d = DictEntry.fromJson({
        'id': '3',
        'title': 'Water',
        'meaning': '<p>Cleansing</p>',
        'categoryId': '5',
        'featured': true,
        'media': [
          {
            'kind': 'youtube',
            'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          },
          {'kind': 'link', 'url': 'javascript:x'},
        ],
      });
      expect(d.featured, isTrue);
      expect(d.media.length, 1);

      final c = CommentaryItem.fromJson({
        'id': '4',
        'title': 'No condemnation',
        'book': 45,
        'chapter': 8,
        'body': '<p>x</p>',
        'writer': {'id': '9', 'name': 'Pastor John'},
        'youtubeId': 'dQw4w9WgXcQ',
        'media': [
          {
            'kind': 'youtube',
            'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          },
          {
            'kind': 'link',
            'url': 'https://example.org/notes',
            'host': 'example.org',
          },
        ],
      });
      expect(c.writer, 'Pastor John');
      // The entry's own video comes first, and the same video as an embed is not shown twice.
      expect(c.allMedia.map((m) => m.kind), ['youtube', 'link']);
      expect(c.allMedia.first.thumbnail, contains('dQw4w9WgXcQ'));
    },
  );

  testWidgets(
    "the home carousel shows the office's banners and announcements as the old cards, and nothing when there is none",
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      enableCardIdleSway = false; // a forever-running animation never settles
      addTearDown(() => enableCardIdleSway = true);

      library.clear();
      await tester.pumpWidget(_app(const HomeCarousel()));
      expect(
        find.byType(PageView),
        findsNothing,
        reason: 'no banners, no room taken',
      );

      library
        ..banners = const [
          LibBanner(
            id: '1',
            caption: 'Sunday service',
            landscape: 'https://pics.example/a.jpg',
            url: 'https://example.org/go',
          ),
        ]
        ..announcements = const [
          LibAnnouncement(
            id: '1',
            title: 'Office closed on Friday',
            message: '<p>Back on Monday</p>',
            link: 'https://example.org/n',
          ),
          LibAnnouncement(id: '2', title: 'Youth camp', message: 'Register soon'),
        ]
        ..notifyListeners();
      await tester.pump();
      expect(find.byType(PageView), findsOneWidget);
      // Banners come first; a card with a link has a button.
      expect(find.text('Sunday service'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      // The dots: one for each card.
      expect(find.byType(AnimatedContainer), findsNWidgets(3));

      // The next card is an announcement, drawn like the old cards (a label, a title and its message).
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(find.text('ANNOUNCEMENTS'), findsOneWidget);
      expect(find.text('Office closed on Friday'), findsOneWidget);
      expect(find.text('Back on Monday'), findsOneWidget);

      // What the cards are made of.
      final slides = HomeCarousel.slidesOf(
        tester.element(find.byType(PageView)),
        library.banners,
        library.announcements,
      );
      expect(slides.map((HomeSlide s) => s.title), [
        'Sunday service',
        'Office closed on Friday',
        'Youth camp',
      ]);
      expect(slides.map((s) => s.url), [
        'https://example.org/go',
        'https://example.org/n',
        null,
      ]);
      library.clear();
    },
  );
}
