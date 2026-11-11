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
  'place': {'name': 'Main Hall', 'address': '1 Church Road'},
  'passRequired': true,
  'bookingBlocked': null,
  'seats': {'total': 100, 'left': 40},
  'status': status,
  'mine': mine,
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
}
