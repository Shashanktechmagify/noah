import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/api_client.dart';
import 'package:noah_frontend_flutter/data/prayer_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/my_prayer_requests_screen.dart';
import 'package:noah_frontend_flutter/screens/prayer_wall_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

WallRequest _request(String id, String text, {bool prayed = false}) =>
    WallRequest(
      id: id,
      category: 'healing',
      text: text,
      everyone: true,
      name: 'Member $id',
      mine: false,
      prayedBy: 1,
      iPrayed: prayed,
      createdAt: DateTime.now(),
    );

Future<void> _open(WidgetTester tester, Widget screen) async {
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await tester.runAsync(loader.load);
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppLocale(
      controller: LocaleController(),
      child: MaterialApp(theme: buildTheme(), home: screen),
    ),
  );
  await tester.pump();
}

void main() {
  test('a wall request is read from the server answer', () {
    final r = WallRequest.fromJson({
      'id': '12',
      'category': 'healing',
      'text': 'For my mother',
      'everyone': false,
      'name': null,
      'anonymous': true,
      'mine': false,
      'prayedBy': 3,
      'iPrayed': true,
      'createdAt': '2026-11-19T10:00:00.000Z',
    });
    expect(r.id, '12');
    expect(r.everyone, isFalse, reason: 'meant for the prayer warriors');
    expect(r.name, isNull, reason: 'anonymous: no name');
    expect(r.prayedBy, 3);
    expect(r.iPrayed, isTrue);
    expect(r.createdAt, isNotNull);

    final m = MyPrayer.fromJson({
      'id': '5',
      'category': 'thanks',
      'text': 'Thank you',
      'everyone': true,
      'state': 'Approved',
      'prayedBy': 2,
      'createdAt': '2026-11-19T10:00:00.000Z',
    });
    expect(m.state, 'Approved');
    expect(m.prayedBy, 2);
  });

  testWidgets(
    'the wall is a deck of cards, one on top, with no Previous / Next; my requests are a separate page with their state',
    (tester) async {
      prayer
        ..loaded = true
        ..wall = [
          _request('1', 'Please pray for my mother.'),
          _request('2', 'A private matter.'),
        ]
        ..mine = [
          MyPrayer(
            id: '9',
            category: 'thanks',
            text: 'Thank you Lord',
            everyone: true,
            state: 'Pending',
            prayedBy: 0,
            createdAt: DateTime.now(),
          ),
        ];
      addTearDown(prayer.clear);

      await _open(tester, const PrayerWallScreen());

      // One card on top: the first request only. The others wait behind it.
      expect(find.text('To pray for: 2'), findsOneWidget);
      expect(find.text('Please pray for my mother.'), findsOneWidget);
      expect(find.textContaining('Member 1'), findsOneWidget);
      expect(find.text('1 praying'), findsOneWidget);
      expect(find.text('A private matter.'), findsNothing);
      expect(find.text('Previous'), findsNothing);
      expect(find.text('Next'), findsNothing);
      // What to do is told, and the two round buttons do the same as a swipe.
      expect(
        find.text('Swipe right when you have prayed, left to skip'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('wall-pray')), findsOneWidget);
      expect(find.byKey(const ValueKey('wall-skip')), findsOneWidget);
      // My requests are not on the wall.
      expect(find.text('Thank you Lord'), findsNothing);
      expect(find.text('My requests'), findsNothing);

      // The member's own requests are on their own page, waiting for approval.
      await _open(tester, const MyPrayerRequestsScreen());
      expect(find.text('Thank you Lord'), findsOneWidget);
      expect(find.text('Waiting for Approval'), findsOneWidget);
      expect(find.text('Add a prayer request'), findsOneWidget);
      expect(find.text('Please pray for my mother.'), findsNothing);
    },
  );

  testWidgets(
    'swipe right: prayed, the request leaves the wall for good and the next card comes up; swipe left: skipped, it goes to the back; a short drag does nothing; nothing moves by itself',
    (tester) async {
      final sent = <String>[];
      var refuse = false;
      prayer
        ..loaded = true
        ..wall = [
          _request('1', 'First request'),
          _request('2', 'Second request'),
          _request('3', 'Third request'),
          _request('4', 'Already prayed for', prayed: true),
        ]
        ..sendPrayer = (id) async {
          sent.add(id);
          if (refuse) throw ApiException('network', 'x');
          return {'id': id};
        };
      addTearDown(() {
        prayer.clear();
        prayer.sendPrayer = (id) => api.prayFor(id);
      });

      await _open(tester, const PrayerWallScreen());

      // One the member prayed for is not on the wall. Time passing does not move the card on.
      expect(find.text('To pray for: 3'), findsOneWidget);
      expect(find.text('First request'), findsOneWidget);
      expect(find.text('Already prayed for'), findsNothing);
      await tester.pump(const Duration(seconds: 30));
      expect(find.text('First request'), findsOneWidget);

      // A short drag springs back: nothing prayed, nothing skipped.
      await tester.drag(
        find.byKey(const ValueKey('wall-top')),
        const Offset(60, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('First request'), findsOneWidget);
      expect(sent, isEmpty);
      expect(prayer.wall.map((r) => r.id), ['1', '2', '3', '4']);

      // Swipe left: skipped. The first card goes to the back, the second is on top; the server is not told.
      await tester.drag(
        find.byKey(const ValueKey('wall-top')),
        const Offset(-300, 0),
      );
      await tester.pumpAndSettle();
      expect(sent, isEmpty);
      expect(find.text('Second request'), findsOneWidget);
      expect(find.text('First request'), findsNothing);
      expect(prayer.wall.map((r) => r.id), ['2', '3', '4', '1']);
      expect(
        find.text('To pray for: 3'),
        findsOneWidget,
        reason: 'still on the wall',
      );

      // Swipe right: prayed. The server is told, the request is gone, the next card comes up.
      await tester.drag(
        find.byKey(const ValueKey('wall-top')),
        const Offset(300, 0),
      );
      await tester.pumpAndSettle();
      expect(sent, ['2']);
      expect(find.text('Second request'), findsNothing);
      expect(find.text('Third request'), findsOneWidget);
      expect(find.text('To pray for: 2'), findsOneWidget);
      expect(
        find.text('You prayed'),
        findsOneWidget,
        reason: 'told in a message',
      );
      expect(prayer.wall.map((r) => r.id), ['3', '4', '1']);

      // The round buttons do the same: the prayer button prays for the top card.
      await tester.tap(find.byKey(const ValueKey('wall-pray')));
      await tester.pumpAndSettle();
      expect(sent, ['2', '3']);
      expect(find.text('First request'), findsOneWidget);
      expect(find.text('To pray for: 1'), findsOneWidget);

      // The last card cannot be skipped to the back (nothing is behind it): it stays.
      await tester.tap(find.byKey(const ValueKey('wall-skip')));
      await tester.pumpAndSettle();
      expect(find.text('First request'), findsOneWidget);
      expect(sent, ['2', '3']);

      // The server refuses: the request comes back where it was.
      refuse = true;
      await tester.tap(find.byKey(const ValueKey('wall-pray')));
      await tester.pumpAndSettle();
      expect(sent, ['2', '3', '1']);
      expect(find.text('First request'), findsOneWidget);
      expect(find.text('To pray for: 1'), findsOneWidget);
    },
  );

  testWidgets('a wall with nothing to pray for says so, and shows no buttons', (
    tester,
  ) async {
    prayer
      ..loaded = true
      ..wall = [_request('1', 'Prayed already', prayed: true)];
    addTearDown(prayer.clear);
    await _open(tester, const PrayerWallScreen());
    expect(find.byKey(const ValueKey('wall-pray')), findsNothing);
    expect(find.byKey(const ValueKey('wall-skip')), findsNothing);
    expect(find.text('Prayed already'), findsNothing);
  });

  test('the new wall words exist in every language the app shows', () {
    for (final key in ['pw_skip', 'pw_left', 'pw_swipe_hint']) {
      final english = trIn(AppLang.en, key);
      expect(english, isNot(key), reason: key);
      for (final lang in AppLang.values) {
        expect(
          trIn(lang, key).trim(),
          isNotEmpty,
          reason: '$key in ${lang.name}',
        );
        if (lang != AppLang.en) {
          expect(
            trIn(lang, key),
            isNot(english),
            reason: '$key in ${lang.name} is translated',
          );
        }
      }
    }
    expect(
      trIn(AppLang.hi, 'pw_left').contains('{n}'),
      isTrue,
      reason: 'the count goes in',
    );
  });
}
