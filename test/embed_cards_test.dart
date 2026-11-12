import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/content_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/embed_cards.dart';

void main() {
  test('a Manna keeps the videos and links the office attached, and drops anything that is not a web address', () {
    final m = mannaFromJson({
      'id': '1',
      'title': 'T',
      'message': '<p>x</p>',
      'prayer': '',
      'date': '2026-11-12',
      'media': [
        {
          'kind': 'youtube',
          'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          'host': 'youtube.com',
          'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          'title': 'Sunday message',
        },
        {'kind': 'link', 'url': 'https://example.org/a', 'host': 'example.org'},
        {'kind': 'link', 'url': 'javascript:alert(1)'},
      ],
    });
    expect(m.media.length, 2);
    expect(m.media.first.kind, 'youtube');
    expect(m.media.first.thumbnail, isNotNull);
    expect(m.media.last.host, 'example.org');
    // An older answer with no media field still reads.
    expect(
      mannaFromJson({
        'id': '2',
        'title': 'T',
        'message': 'x',
        'date': '2026-11-12',
      }).media,
      isEmpty,
    );
  });

  testWidgets(
    'the cards show a video with its title and a link with its address',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      final m = mannaFromJson({
        'id': '1',
        'title': 'T',
        'message': 'x',
        'date': '2026-11-12',
        'media': [
          {
            'kind': 'youtube',
            'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
            'thumbnail': 'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
            'title': 'Sunday message',
          },
          {
            'kind': 'link',
            'url': 'https://example.org/a',
            'host': 'example.org',
          },
        ],
      });
      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: Scaffold(
              body: SingleChildScrollView(child: EmbedCards(items: m.media)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Sunday message'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_fill), findsOneWidget);
      expect(find.text('example.org'), findsOneWidget);
      expect(find.text('Tap to open'), findsOneWidget);
    },
  );
}
