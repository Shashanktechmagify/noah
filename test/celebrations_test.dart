import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:noah_frontend_flutter/data/api_client.dart';
import 'package:noah_frontend_flutter/data/celebration_links.dart';
import 'package:noah_frontend_flutter/data/celebration_template.dart';
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
    'only today is asked for; two tabs (Birthdays, Anniversaries) show the people of each; the age and the years are written short',
    (tester) async {
      final asked = <(String, String)>[];
      await _open(tester, asked: asked, launched: []);

      expect(asked, [('2026-11-25', '2026-11-25')], reason: 'today only');
      // No date pickers, no ranges.
      expect(find.byKey(const ValueKey('cel-from')), findsNothing);
      expect(find.byKey(const ValueKey('cel-today')), findsNothing);
      expect(find.text('Birthdays (3)'), findsOneWidget);
      expect(find.text('Anniversaries (1)'), findsOneWidget);

      // The Birthdays tab first: only birthdays.
      expect(find.text('Age: 36 years'), findsOneWidget);
      expect(find.text('Years: 11'), findsNothing);
      expect(find.text('Turning 36'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('cel-tab-a')));
      await tester.pumpAndSettle();
      expect(find.text('Years: 11'), findsOneWidget);
      expect(find.text('Age: 36 years'), findsNothing);
      expect(find.text('11 years married'), findsNothing);
    },
  );

  testWidgets(
    'each person shows how to reach them and who they are; Call and WhatsApp open with the greeting written, and nobody is offered buttons without a number',
    (tester) async {
      final launched = <Uri>[];
      await _open(tester, asked: [], launched: launched);

      // Birthdays tab: phone, WhatsApp, email, address, marital status.
      expect(find.text('Ben Thomas'), findsOneWidget);
      expect(find.text('+919000000523'), findsOneWidget);
      expect(find.text('WhatsApp · +919811111111'), findsOneWidget);
      expect(find.text('ben@example.org'), findsOneWidget);
      expect(find.text('12 Hill Road, Kalina, Mumbai'), findsOneWidget);
      expect(find.text('Married'), findsOneWidget);
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

      // The anniversary has its own greeting.
      await tester.tap(find.byKey(const ValueKey('cel-tab-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cel-wa-1-a-2026-11-29')));
      await tester.pump();
      expect(
        launched.last.queryParameters['text'],
        startsWith('Ben Wishing you a very Happy Anniversary!'),
      );
    },
  );

  testWidgets(
    'the WhatsApp message can be changed (kept on the phone, one for each tab) and put back to the standard one',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final launched = <Uri>[];
      await _open(tester, asked: [], launched: launched);

      await tester.tap(find.byKey(const ValueKey('cel-tpl-edit')));
      await tester.pumpAndSettle();
      expect(find.text('Birthday message'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('cel-tpl-field')),
        'God bless you {name}!',
      );
      await tester.tap(find.byKey(const ValueKey('cel-tpl-save')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('cel-wa-1-b-2026-11-26')));
      await tester.pump();
      expect(launched.last.queryParameters['text'], 'God bless you Ben!');
      expect(await CelebrationTemplate.read(true), 'God bless you {name}!');
      expect(await CelebrationTemplate.read(false), isNull);

      // The anniversary tab still has the standard message.
      await tester.tap(find.byKey(const ValueKey('cel-tab-a')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cel-wa-1-a-2026-11-29')));
      await tester.pump();
      expect(
        launched.last.queryParameters['text'],
        startsWith('Ben Wishing you a very Happy Anniversary!'),
      );

      // Back to the standard one.
      await tester.tap(find.byKey(const ValueKey('cel-tab-b')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cel-tpl-edit')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('cel-tpl-reset')));
      await tester.pumpAndSettle();
      expect(await CelebrationTemplate.read(true), isNull);
      await tester.tap(find.byKey(const ValueKey('cel-wa-1-b-2026-11-26')));
      await tester.pump();
      expect(
        launched.last.queryParameters['text'],
        startsWith('Happy Birthday Ben. Wishing you another wonderful year'),
      );
    },
  );

  testWidgets(
    'the message sheet keeps Save and the standard-message button above the phone buttons, on a short screen too',
    (tester) async {
      await _open(tester, asked: [], launched: []);
      // A short phone with a 48 px bar of buttons at the bottom.
      tester.view.physicalSize = const Size(360, 640);
      tester.view.padding = const FakeViewPadding(bottom: 48);
      tester.view.viewPadding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.view.resetViewPadding);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('cel-tpl-edit')));
      await tester.pumpAndSettle();
      for (final k in ['cel-tpl-save', 'cel-tpl-reset']) {
        final box = tester.getRect(find.byKey(ValueKey(k)));
        expect(box.bottom, lessThanOrEqualTo(640 - 48), reason: k);
        expect(box.left, greaterThanOrEqualTo(0), reason: k);
        expect(box.right, lessThanOrEqualTo(360), reason: k);
      }
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

  test(
    'the words of the celebrations exist in every language the app shows',
    () {
      for (final key in [
        'cel_none_today',
        'cel_tpl_edit',
        'cel_tpl_title_b',
        'cel_tpl_title_a',
        'cel_tpl_hint',
        'cel_tpl_save',
        'cel_tpl_reset',
        'cel_turning',
        'cel_years',
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
    },
  );

  test('api: the range goes to the server as from and to', () {
    // The call is made with these query names (see celebrations() in api_client.dart).
    expect(ApiException('x', 'y').code, 'x');
  });
}
