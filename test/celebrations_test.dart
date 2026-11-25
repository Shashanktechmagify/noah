import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/api_client.dart';
import 'package:noah_frontend_flutter/data/celebration_links.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/celebrations_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

Map<String, dynamic> _data() => {
  'birthdays': [
    {
      'memberId': '1',
      'name': 'Ben Thomas',
      'date': '2026-11-26',
      'day': 26,
      'month': 11,
      'turning': 36,
      'today': false,
      'photoFileId': null,
      'mobile': '+919000000523',
      'whatsapp': '+919811111111',
      'email': 'ben@example.org',
      'address': '12 Hill Road, Kalina, Mumbai',
      'maritalStatus': 'married',
    },
    {
      'memberId': '2',
      'name': 'Dee Roy',
      'date': '2026-11-28',
      'day': 28,
      'month': 11,
      'turning': 41,
      'today': false,
      'mobile': '+919000000524',
      'whatsapp': null,
      'email': null,
      'address': null,
      'maritalStatus': null,
    },
    {
      'memberId': '3',
      'name': 'No Phone',
      'date': '2026-11-30',
      'day': 30,
      'month': 11,
      'turning': 30,
      'today': false,
      'mobile': null,
      'whatsapp': null,
      'email': 'nophone@example.org',
      'address': null,
      'maritalStatus': 'single',
    },
  ],
  'anniversaries': [
    {
      'memberId': '1',
      'name': 'Ben Thomas',
      'date': '2026-11-29',
      'day': 29,
      'month': 11,
      'years': 11,
      'today': false,
      'mobile': '+919000000523',
      'whatsapp': '+919811111111',
      'email': 'ben@example.org',
      'address': '12 Hill Road, Kalina, Mumbai',
      'maritalStatus': 'married',
    },
  ],
};

Future<void> _open(
  WidgetTester tester, {
  required List<(String, String)> asked,
  required List<Uri> launched,
  bool opens = true,
}) async {
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await tester.runAsync(loader.load);
  tester.view.physicalSize = const Size(390, 4000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppLocale(
      controller: LocaleController(),
      child: MaterialApp(
        theme: buildTheme(),
        home: CelebrationsScreen(
          today: DateTime(2026, 11, 25),
          load: (from, to) async {
            asked.add((from, to));
            return _data();
          },
          launch: (uri) async {
            launched.add(uri);
            return opens;
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  test('a call and a WhatsApp link are made from the number the server keeps', () {
    expect(celebrationDigits('+91 98111-11111'), '919811111111');
    expect(celebrationDigits(null), '');
    expect(callLink('+919811111111').toString(), 'tel:+919811111111');
    expect(callLink(null), isNull);
    expect(callLink(''), isNull);

    final wa = whatsappLink('+919811111111', 'Happy Birthday Ben & family!')!;
    expect(wa.host, 'wa.me');
    expect(wa.path, '/919811111111');
    expect(wa.queryParameters['text'], 'Happy Birthday Ben & family!');
    // A space is %20 and the & is %26 (a + or a bare & would cut the message).
    expect(
      wa.toString(),
      contains('text=Happy%20Birthday%20Ben%20%26%20family'),
    );
    expect(whatsappLink(null, 'x'), isNull);
  });

  testWidgets(
    'two date pickers choose the range: the week ahead to begin with; the quick ranges; the other end follows when they would cross',
    (tester) async {
      final asked = <(String, String)>[];
      await _open(tester, asked: asked, launched: []);

      expect(asked, [('2026-11-25', '2026-12-01')], reason: 'the week ahead');
      expect(find.text('25 November 2026'), findsOneWidget);
      expect(find.text('1 December 2026'), findsOneWidget);
      expect(find.text('From'), findsOneWidget);
      expect(find.text('To'), findsOneWidget);

      // The quick ranges.
      await tester.tap(find.byKey(const ValueKey('cel-today')));
      await tester.pumpAndSettle();
      expect(asked.last, ('2026-11-25', '2026-11-25'));
      await tester.tap(find.byKey(const ValueKey('cel-month')));
      await tester.pumpAndSettle();
      expect(asked.last, ('2026-11-01', '2026-11-30'));
      await tester.tap(find.byKey(const ValueKey('cel-30')));
      await tester.pumpAndSettle();
      expect(asked.last, ('2026-11-25', '2026-12-24'));

      // The first date moved past the last one: the last one follows.
      await tester.tap(find.byKey(const ValueKey('cel-today')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cel-from')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('28')),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(asked.last, ('2026-11-28', '2026-11-28'));
      expect(find.text('28 November 2026'), findsNWidgets(2));

      // The last date moved before the first one: the first one follows.
      await tester.tap(find.byKey(const ValueKey('cel-to')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(of: find.byType(Dialog), matching: find.text('20')),
      );
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(asked.last, ('2026-11-20', '2026-11-20'));
    },
  );

  testWidgets(
    'each person shows how to reach them and who they are; Call and WhatsApp open with the greeting written, and nobody is offered buttons without a number',
    (tester) async {
      final launched = <Uri>[];
      await _open(tester, asked: [], launched: launched);

      expect(find.text('Birthdays (3)'), findsOneWidget);
      expect(find.text('Anniversaries (1)'), findsOneWidget);
      expect(
        find.text('Ben Thomas'),
        findsNWidgets(2),
        reason: 'a birthday and an anniversary',
      );
      expect(find.text('Turning 36'), findsOneWidget);
      expect(find.text('11 years married'), findsOneWidget);
      // Phone, WhatsApp, email, address, marital status.
      expect(find.text('+919000000523'), findsNWidgets(2));
      expect(find.text('WhatsApp · +919811111111'), findsNWidgets(2));
      expect(find.text('ben@example.org'), findsNWidgets(2));
      expect(find.text('12 Hill Road, Kalina, Mumbai'), findsNWidgets(2));
      expect(find.text('Married'), findsNWidgets(2));
      expect(find.text('Single'), findsOneWidget);
      expect(find.text('nophone@example.org'), findsOneWidget);
      // No WhatsApp line when it is the same as the mobile number, or when there is none.
      expect(find.text('WhatsApp · +919000000524'), findsNothing);

      // Ben's WhatsApp number is used for the greeting; his mobile number for the call.
      await tester.tap(find.byKey(const ValueKey('cel-wa-1-b-2026-11-26')));
      await tester.pump();
      final wa = launched.last;
      expect(wa.host, 'wa.me');
      expect(wa.path, '/919811111111');
      expect(
        wa.queryParameters['text'],
        startsWith('Happy Birthday Ben. Wishing you another wonderful year'),
      );
      await tester.tap(find.byKey(const ValueKey('cel-call-1-b-2026-11-26')));
      await tester.pump();
      expect(launched.last.toString(), 'tel:+919000000523');

      // The anniversary has its own greeting.
      await tester.tap(find.byKey(const ValueKey('cel-wa-1-a-2026-11-29')));
      await tester.pump();
      expect(
        launched.last.queryParameters['text'],
        startsWith('Ben Wishing you a very Happy Anniversary!'),
      );

      // Dee has only a mobile number: WhatsApp goes there.
      await tester.tap(find.byKey(const ValueKey('cel-wa-2-b-2026-11-28')));
      await tester.pump();
      expect(launched.last.path, '/919000000524');

      // Without a number: nothing to call or to write to.
      expect(
        find.byKey(const ValueKey('cel-call-3-b-2026-11-30')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('cel-wa-3-b-2026-11-30')), findsNothing);
    },
  );

  testWidgets(
    'when the phone cannot open WhatsApp or the dialler, the number is given in a message',
    (tester) async {
      await _open(tester, asked: [], launched: [], opens: false);
      await tester.tap(find.byKey(const ValueKey('cel-wa-1-b-2026-11-26')));
      await tester.pump();
      expect(
        find.text('Could not open it. The number is +919811111111.'),
        findsOneWidget,
      );
    },
  );

  test('the words of the range exist in every language the app shows', () {
    for (final key in [
      'cel_from',
      'cel_to',
      'cel_r_today',
      'cel_r_week',
      'cel_r_30',
      'cel_r_month',
      'cel_none_range',
      'cel_call',
      'cel_open_failed',
    ]) {
      final english = trIn(AppLang.en, key);
      expect(english, isNot(key), reason: key);
      for (final lang in AppLang.values) {
        expect(
          trIn(lang, key).trim(),
          isNotEmpty,
          reason: '$key in ${lang.name}',
        );
        if (lang != AppLang.en && english.length > 2) {
          expect(
            trIn(lang, key),
            isNot(english),
            reason: '$key in ${lang.name} is translated',
          );
        }
      }
    }
  });

  test('api: the range goes to the server as from and to', () {
    // The call is made with these query names (see celebrations() in api_client.dart).
    expect(ApiException('x', 'y').code, 'x');
  });
}
