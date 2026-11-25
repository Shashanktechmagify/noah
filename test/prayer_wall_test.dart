import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/api_client.dart';
import 'package:noah_frontend_flutter/data/prayer_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/my_prayer_requests_screen.dart';
import 'package:noah_frontend_flutter/screens/prayer_wall_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

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
    'the wall goes one request at a time; my requests are a separate page with their state',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      prayer
        ..loaded = true
        ..wall = [
          WallRequest(
            id: '1',
            category: 'healing',
            text: 'Please pray for my mother.',
            everyone: true,
            name: 'Asha Thomas',
            mine: false,
            prayedBy: 2,
            iPrayed: false,
            createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          WallRequest(
            id: '2',
            category: 'family',
            text: 'A private matter.',
            everyone: false,
            name: null,
            mine: false,
            prayedBy: 0,
            iPrayed: false,
            createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
          ),
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

      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: const PrayerWallScreen(),
          ),
        ),
      );
      await tester.pump();

      // One at a time: the first request only.
      expect(find.text('1 of 2'), findsOneWidget);
      expect(find.text('Please pray for my mother.'), findsOneWidget);
      expect(find.textContaining('Asha Thomas'), findsOneWidget);
      expect(
        find.text('I prayed'),
        findsOneWidget,
        reason: 'not yet prayed for',
      );
      expect(find.text('2 praying'), findsOneWidget);
      expect(find.text('A private matter.'), findsNothing);
      expect(find.text('Previous'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 2'), findsOneWidget);
      expect(find.text('A private matter.'), findsOneWidget);
      expect(find.text('Please pray for my mother.'), findsNothing);
      expect(find.text('Prayer warriors'), findsOneWidget);
      expect(find.textContaining('Anonymous'), findsOneWidget);
      // My requests are not on the wall, and there is no tab for them here.
      expect(find.text('Thank you Lord'), findsNothing);
      expect(find.text('My requests'), findsNothing);

      // The member's own requests are on their own page, waiting for approval.
      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: const MyPrayerRequestsScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Thank you Lord'), findsOneWidget);
      expect(find.text('Waiting for Approval'), findsOneWidget);
      expect(find.text('Add a prayer request'), findsOneWidget);
      expect(find.text('Please pray for my mother.'), findsNothing);
    },
  );

  testWidgets(
    'I prayed takes the request off the wall and shows the next one; nothing moves on by itself; a refused prayer comes back',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      WallRequest request(String id, String text, {bool prayed = false}) =>
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
      final sent = <String>[];
      var refuse = false;
      prayer
        ..loaded = true
        ..wall = [
          request('1', 'First request'),
          request('2', 'Second request'),
          request('3', 'Third request'),
          request('4', 'Already prayed for', prayed: true),
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

      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: const PrayerWallScreen(),
          ),
        ),
      );
      await tester.pump();

      // One the member prayed for is not on the wall. Time passing does not move it on.
      expect(find.text('1 of 3'), findsOneWidget);
      expect(find.text('First request'), findsOneWidget);
      await tester.pump(const Duration(seconds: 30));
      expect(
        find.text('First request'),
        findsOneWidget,
        reason: 'it stays until the member acts',
      );
      expect(find.text('Already prayed for'), findsNothing);

      // Look at the second one without praying: nothing is taken off.
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('2 of 3'), findsOneWidget);
      expect(find.text('Second request'), findsOneWidget);

      // "I prayed": the second request is gone, and the third comes in at once.
      await tester.tap(find.text('I prayed'));
      await tester.pumpAndSettle();
      expect(sent, ['2']);
      expect(find.text('Second request'), findsNothing);
      expect(find.text('Third request'), findsOneWidget);
      expect(find.text('2 of 2'), findsOneWidget);
      expect(
        find.text('First request'),
        findsNothing,
        reason: 'it moved to the next, not back',
      );
      expect(prayer.wall.map((r) => r.id), ['1', '3', '4']);

      // Praying for the last one leaves the one before it (there is no next), and the wall is one shorter again.
      await tester.tap(find.text('I prayed'));
      await tester.pumpAndSettle();
      expect(sent, ['2', '3']);
      expect(find.text('First request'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);

      // The server refuses: the request comes back where it was.
      refuse = true;
      await tester.tap(find.text('I prayed'));
      await tester.pumpAndSettle();
      expect(sent, ['2', '3', '1']);
      expect(find.text('First request'), findsOneWidget);
      expect(find.text('1 of 1'), findsOneWidget);
    },
  );
}
