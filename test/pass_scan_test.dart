import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/pass_scan.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/events/pass_scanner_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

ScanOutcome _outcome(String result, {Map<String, dynamic>? extra}) =>
    ScanOutcome.fromJson({
      'result': result,
      'message': 'message for $result',
      'member': {'id': '5', 'name': 'Mr Ravi Kumar', 'number': 'M0311'},
      ...?extra,
    });

Future<void> _show(
  WidgetTester tester,
  ScanOutcome o, {
  VoidCallback? onConfirm,
  VoidCallback? onNext,
}) async {
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await tester.runAsync(loader.load);
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppLocale(
      controller: LocaleController(),
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ScanResultCard(
              outcome: o,
              onConfirm: onConfirm ?? () {},
              onNext: onNext ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  test('what the server says about a pass is read as it is', () {
    final o = _outcome(
      'already_scanned',
      extra: {
        'pass': {'attendedAt': '2026-11-15T12:40:00.000Z'},
      },
    );
    expect(o.isWarning, isTrue);
    expect(o.ok, isFalse);
    expect(o.attendedAt, isNotNull);
    expect(o.memberName, 'Mr Ravi Kumar');
    expect(_outcome('valid').isValid, isTrue);
    expect(_outcome('valid').ok, isTrue);
    expect(_outcome('admitted').ok, isTrue);
    for (final bad in [
      'invalid',
      'wrong_event',
      'cancelled',
      'not_confirmed',
      'event_closed',
    ]) {
      expect(_outcome(bad).ok, isFalse, reason: bad);
      expect(_outcome(bad).isWarning, isFalse, reason: bad);
    }
    final wrong = _outcome(
      'wrong_event',
      extra: {
        'other': {'id': '9', 'name': 'Other Event'},
      },
    );
    expect(wrong.otherEvent, 'Other Event');
    final event = ScanEvent.fromJson({
      'id': '70',
      'name': 'Annual Gathering',
      'start': '2026-11-15T12:30:00.000Z',
      'place': 'Main Hall',
    });
    expect(event.place, 'Main Hall');
  });

  testWidgets('a valid pass shows the member and asks to confirm the entry', (
    tester,
  ) async {
    var confirmed = 0;
    await _show(tester, _outcome('valid'), onConfirm: () => confirmed++);
    expect(find.text('Valid pass'), findsOneWidget);
    expect(find.textContaining('Mr Ravi Kumar · M0311'), findsOneWidget);
    expect(
      find.text('message for valid'),
      findsNothing,
      reason: 'part of one text',
    );
    await tester.tap(find.text('Confirm entry'));
    expect(confirmed, 1);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('every other answer says what is wrong and offers no entry', (
    tester,
  ) async {
    for (final (result, title) in [
      ('already_scanned', 'Already scanned'),
      ('invalid', 'Invalid QR'),
      ('wrong_event', 'Wrong event'),
      ('cancelled', 'Booking cancelled'),
      ('not_confirmed', 'Booking not confirmed'),
      ('event_closed', 'Event closed'),
    ]) {
      await _show(tester, _outcome(result));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget, reason: result);
      expect(find.text('Confirm entry'), findsNothing, reason: result);
      expect(find.text('Scan next'), findsOneWidget, reason: result);
    }
  });

  testWidgets(
    'the admitted answer needs no button to continue but can be dismissed',
    (tester) async {
      var next = 0;
      await _show(tester, _outcome('admitted'), onNext: () => next++);
      expect(find.text('Admitted'), findsOneWidget);
      expect(find.text('Confirm entry'), findsNothing);
      await tester.tap(find.text('Scan next'));
      expect(next, 1);
    },
  );
}
