import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/live_events.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/events/live_events_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:qr_flutter/qr_flutter.dart';

Map<String, dynamic> _event({
  String status = 'booking_open',
  Map<String, dynamic>? mine,
  String photo = '',
}) => {
  'id': '70',
  'name': 'Annual Gathering',
  'description': '<p>A day together</p>',
  'photo': photo,
  'start': '2026-11-15T12:30:00.000Z',
  'end': '2026-11-15T16:30:00.000Z',
  'timezone': 'Asia/Kolkata',
  'place': {
    'name': 'Main Hall',
    'address': '1 Church Road',
    'lat': '19.2183',
    'lon': '72.9781',
  },
  'passRequired': true,
  'bookingBlocked': null,
  'seats': {'total': 100, 'left': 40},
  'status': status,
  'mine': mine,
  'terms': '<p>Doors close at 6</p>',
  'organisers': ['Ps John Mathew'],
  'meetingLink': 'https://meet.example.com/abc',
  'paid': false,
};

Map<String, dynamic> _pass({String status = 'confirmed', String? qr}) => {
  'id': '9001',
  'status': status,
  'reference': 'KS-0154022-3F9',
  'qr': status == 'cancelled' ? null : (qr ?? 'KSP1.9001.${'A' * 22}'),
  'bookedAt': '2026-11-11T10:00:00.000Z',
  'attendedAt': null,
  'event': {
    'id': '70',
    'name': 'Annual Gathering',
    'start': '2026-11-15T12:30:00.000Z',
    'place': {'name': 'Main Hall', 'address': '1 Church Road'},
  },
  'member': {'id': '5', 'name': 'Ravi Kumar', 'number': 'M0311'},
};

Widget _app(Widget home) => AppLocale(
  controller: LocaleController(),
  child: MaterialApp(theme: buildTheme(), home: home),
);

void main() {
  test('an event and a pass are read from what the server sends', () {
    final e = LiveEvent.fromJson(_event(photo: 'not a link'));
    expect(e.name, 'Annual Gathering');
    expect(e.photo, isNull, reason: 'only a real link is used as a picture');
    expect(e.seatsLeft, 40);
    expect(e.canBook, isTrue);
    expect(e.booked, isFalse);

    final booked = LiveEvent.fromJson(
      _event(mine: {'passId': '9001', 'status': 'confirmed'}),
    );
    expect(booked.booked, isTrue);
    expect(booked.canBook, isFalse, reason: 'one booking, one pass');
    expect(LiveEvent.fromJson(_event(status: 'fully_booked')).canBook, isFalse);
    expect(
      LiveEvent.fromJson({..._event(), 'bookingBlocked': 'paid'}).canBook,
      isFalse,
    );

    final p = LivePass.fromJson(_pass());
    expect(p.reference, 'KS-0154022-3F9');
    expect(p.memberName, 'Ravi Kumar');
    expect(p.isLive, isTrue);
    expect(LivePass.fromJson(_pass(status: 'cancelled')).qr, isNull);
  });

  testWidgets(
    'the events list shows status and seats, and a pass shows its QR code',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      liveEvents
        ..events = [LiveEvent.fromJson(_event())]
        ..passes = [LivePass.fromJson(_pass())]
        ..loaded = true;
      await tester.pumpWidget(_app(const LiveEventsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Annual Gathering'), findsOneWidget);
      expect(find.text('Booking Open'), findsOneWidget);
      expect(find.textContaining('Main Hall'), findsOneWidget);

      // The member's passes, then one pass: the code and its reference.
      await tester.tap(find.text('My passes · 1'));
      await tester.pumpAndSettle();
      expect(find.text('Confirmed'), findsOneWidget);
      await tester.tap(find.text('Annual Gathering'));
      await tester.pumpAndSettle();
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('KS-0154022-3F9'), findsOneWidget);
      expect(find.text('Ravi Kumar · M0311'), findsOneWidget);
      expect(find.text('Show this code at the entrance.'), findsOneWidget);
    },
  );

  testWidgets('a cancelled pass has no QR code', (tester) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      _app(LivePassScreen(pass: LivePass.fromJson(_pass(status: 'cancelled')))),
    );
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(
      find.text('This booking was cancelled. The pass is no longer valid.'),
      findsOneWidget,
    );
  });

  testWidgets('an event page offers Book, or says why not', (tester) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    liveEvents
      ..events = [LiveEvent.fromJson(_event())]
      ..passes = []
      ..loaded = true;
    await tester.pumpWidget(_app(const LiveEventScreen(eventId: '70')));
    await tester.pumpAndSettle();
    expect(find.text('Book this event'), findsOneWidget);
    expect(find.text('40 of 100 left'), findsOneWidget);

    liveEvents.events = [LiveEvent.fromJson(_event(status: 'fully_booked'))];
    liveEvents.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Book this event'), findsNothing);
    expect(find.text('This event is fully booked.'), findsOneWidget);

    liveEvents.events = [
      LiveEvent.fromJson(
        _event(mine: {'passId': '9001', 'status': 'confirmed'}),
      ),
    ];
    liveEvents.passes = [LivePass.fromJson(_pass())];
    liveEvents.notifyListeners();
    await tester.pumpAndSettle();
    expect(find.text('Show QR pass'), findsOneWidget);
    expect(find.text('Cancel booking'), findsOneWidget);
  });

  test('the event keeps its map position, host, terms and online link', () {
    final e = LiveEvent.fromJson(_event());
    expect(e.organisers, ['Ps John Mathew']);
    expect(e.terms, '<p>Doors close at 6</p>');
    expect(e.meetingLink, 'https://meet.example.com/abc');
    expect(e.paid, isFalse);
    expect(e.placeLat, '19.2183');
    // Maps opens on the position when there is one, else on the address.
    expect(mapsLink(e)!.queryParameters['query'], '19.2183,72.9781');
    final noPosition = LiveEvent.fromJson({
      ..._event(),
      'place': {
        'name': 'Main Hall',
        'address': '1 Church Road',
        'lat': null,
        'lon': null,
      },
    });
    expect(
      mapsLink(noPosition)!.queryParameters['query'],
      'Main Hall, 1 Church Road',
    );
    // Zero, zero and out-of-range positions are not real places.
    final zero = LiveEvent.fromJson({
      ..._event(),
      'place': {'name': 'Main Hall', 'address': '', 'lat': '0', 'lon': '0'},
    });
    expect(mapsLink(zero)!.queryParameters['query'], 'Main Hall');
    final nothing = LiveEvent.fromJson({
      ..._event(),
      'place': {'name': '', 'address': '', 'lat': '95', 'lon': '10'},
    });
    expect(mapsLink(nothing), isNull);
    final bare = LiveEvent.fromJson({'id': '1', 'name': 'x'});
    expect(bare.organisers, isEmpty);
    expect(bare.meetingLink, isNull);
  });

  testWidgets(
    'the event page shows every detail: about, host, entry, map, online link, terms',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      liveEvents
        ..events = [LiveEvent.fromJson(_event())]
        ..passes = []
        ..loaded = true;
      await tester.pumpWidget(_app(const LiveEventScreen(eventId: '70')));
      await tester.pumpAndSettle();
      expect(find.text('About this event'), findsOneWidget);
      // Text written in the console is drawn as formatted text, not a plain Text.
      expect(
        find.textContaining('A day together', findRichText: true),
        findsOneWidget,
      );
      expect(find.text('Hosted by'), findsOneWidget);
      expect(find.text('Ps John Mathew'), findsOneWidget);
      expect(find.text('Free · Pass needed'), findsOneWidget);
      expect(find.text('Open in Maps'), findsOneWidget);
      expect(find.text('Join online'), findsOneWidget);
      expect(find.text('Terms'), findsOneWidget);
      expect(
        find.textContaining('Doors close at 6', findRichText: true),
        findsOneWidget,
      );
      expect(find.textContaining('1 Church Road'), findsOneWidget);

      // An event with nothing more to say shows no empty boxes.
      liveEvents.events = [
        LiveEvent.fromJson({
          'id': '70',
          'name': 'Plain',
          'status': 'upcoming',
          'place': {'name': '', 'address': ''},
        }),
      ];
      liveEvents.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Open in Maps'), findsNothing);
      expect(find.text('Join online'), findsNothing);
      expect(find.text('Terms'), findsNothing);
      expect(find.text('About this event'), findsNothing);
    },
  );
}
