import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/content_data.dart';
import 'package:noah_frontend_flutter/data/manna_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/manna_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('the content language numbers follow the console (7 is Kannada)', () {
    expect(contentLanguage(AppLang.en), 1);
    expect(contentLanguage(AppLang.hi), 2);
    expect(contentLanguage(AppLang.mr), 3);
    expect(contentLanguage(AppLang.te), 4);
    expect(contentLanguage(AppLang.ml), 5);
    expect(contentLanguage(AppLang.ta), 6);
    expect(contentLanguage(AppLang.kn), 7);
  });

  test('a phone language code finds the app language, region and all', () {
    expect(LocaleController.fromCode('kn'), AppLang.kn);
    expect(LocaleController.fromCode('ta-IN'), AppLang.ta);
    expect(LocaleController.fromCode('HI_in'), AppLang.hi);
    expect(LocaleController.fromCode('fr'), isNull);
    expect(LocaleController.fromCode(null), isNull);
  });

  test('an entry the server could not translate is marked as a fallback', () {
    final translated = mannaFromJson({
      'id': '10',
      'title': 'ದೇವರ ಶಾಂತಿ',
      'message': '<p>x</p>',
      'prayer': '',
      'date': '2026-11-23',
      'language': 7,
      'requestedLanguage': 7,
      'fallback': false,
    });
    expect(translated.fallback, isFalse);
    final english = mannaFromJson({
      'id': '11',
      'title': 'The peace of God',
      'message': '<p>x</p>',
      'prayer': '',
      'date': '2026-11-22',
      'language': 1,
      'requestedLanguage': 7,
      'fallback': true,
      'reason': 'not_translated_yet',
    });
    expect(english.fallback, isTrue);
    expect(english.id, '11', reason: 'always the original\'s id');
    expect(
      prayerFromJson({'title': 't', 'body': 'b', 'fallback': true}).fallback,
      isTrue,
    );
    expect(confessionFromJson({'title': 't', 'body': 'b'}).fallback, isFalse);
    expect(
      confessionFromJson({'title': 't', 'body': 'b', 'fallback': true})
          .fallback,
      isTrue,
    );
  });

  testWidgets(
    'the language is the saved choice, else the phone\'s, else English',
    (tester) async {
      SharedPreferences.setMockInitialValues({});

      // Nothing chosen yet: the phone's language.
      final fresh = LocaleController();
      await tester.runAsync(() => fresh.restore(phoneLanguage: 'kn'));
      expect(fresh.lang, AppLang.kn);

      // The member picks Tamil: it is remembered, and wins over the phone from then on.
      await tester.runAsync(() => fresh.choose(AppLang.ta));
      expect(fresh.lang, AppLang.ta);
      final next = LocaleController();
      await tester.runAsync(() => next.restore(phoneLanguage: 'kn'));
      expect(next.lang, AppLang.ta);

      // A phone language the app does not have, and nothing saved: English.
      SharedPreferences.setMockInitialValues({});
      final french = LocaleController();
      await tester.runAsync(() => french.restore(phoneLanguage: 'fr'));
      expect(french.lang, AppLang.en);
    },
  );

  testWidgets(
    'a Manna that is not translated yet says it is shown in English',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      Future<void> show(AppLang lang, {required bool fallback}) async {
        await tester.pumpWidget(
          AppLocale(
            controller: LocaleController(lang),
            child: MaterialApp(
              theme: buildTheme(),
              home: MannaDetailScreen(
                manna: Manna(
                  id: '77',
                  titleKey: 'The peace of God',
                  ref: '',
                  minutes: 1,
                  daysAgo: 0,
                  verse: '',
                  reflection: 'A message',
                  prayer: '',
                  fallback: fallback,
                ),
              ),
            ),
          ),
        );
        await tester.pump();
      }

      await show(AppLang.kn, fallback: true);
      expect(find.text('ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿ ತೋರಿಸಲಾಗಿದೆ'), findsOneWidget);
      await show(AppLang.kn, fallback: false);
      expect(find.text('ಇಂಗ್ಲಿಷ್‌ನಲ್ಲಿ ತೋರಿಸಲಾಗಿದೆ'), findsNothing);
      // In English the line would only say the obvious.
      await show(AppLang.en, fallback: true);
      expect(find.text('Shown in English'), findsNothing);
    },
  );
}
