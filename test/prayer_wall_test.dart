import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/prayer_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
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

  testWidgets('the wall shows the requests, the warriors tag and anonymous, and my requests show their state', (
    tester,
  ) async {
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
          iPrayed: true,
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

    expect(find.text('Please pray for my mother.'), findsOneWidget);
    expect(find.textContaining('Asha Thomas'), findsOneWidget);
    expect(find.text('I prayed'), findsOneWidget, reason: 'not yet prayed for');
    expect(find.text('You prayed'), findsOneWidget, reason: 'already prayed');
    expect(find.text('Prayer warriors'), findsOneWidget);
    expect(find.textContaining('Anonymous'), findsOneWidget);
    expect(find.text('2 praying'), findsOneWidget);

    await tester.tap(find.text('My requests'));
    await tester.pump();
    expect(find.text('Thank you Lord'), findsOneWidget);
    expect(find.text('Waiting for the office'), findsOneWidget);
    expect(find.text('Please pray for my mother.'), findsNothing);
  });
}
