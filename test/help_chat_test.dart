import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/api_client.dart';
import 'package:noah_frontend_flutter/data/help_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/help_chat_screen.dart';
import 'package:noah_frontend_flutter/screens/menu_sheet.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

Map<String, dynamic> _answer(String text, {String id = '7'}) => {
  'id': id,
  'answered': true,
  'answer': text,
  'left': 19,
};

void main() {
  test('an answer from the FAQ is shown as the assistant\'s message under the question', () async {
    final asked = <String>[];
    final chat = HelpChat(
      ask: (q) async {
        asked.add(q);
        return _answer('You can send two prayer requests a day.');
      },
    );
    await chat.send('  How many prayer requests a day?  ');
    expect(asked, ['How many prayer requests a day?'], reason: 'trimmed');
    expect(chat.messages.map((m) => m.kind), [HelpKind.mine, HelpKind.answer]);
    expect(chat.messages.last.text, 'You can send two prayer requests a day.');
    expect(chat.messages.last.id, '7');
    expect(chat.busy, isFalse);
  });

  test(
    'nothing is sent for an empty question, nor while another one waits',
    () async {
      var calls = 0;
      final chat = HelpChat(
        ask: (q) async {
          calls += 1;
          return _answer('Fine.');
        },
      );
      await chat.send('   ');
      expect(calls, 0);
      final first = chat.send('one');
      await chat.send('two'); // while the first waits
      await first;
      expect(calls, 1);
      expect(chat.messages.where((m) => m.kind == HelpKind.mine).length, 1);
    },
  );

  test('when the FAQ has nothing the message says so (no text of the server), and the member may talk to the office', () async {
    final chat = HelpChat(
      ask: (q) async => {
        'id': '8',
        'answered': false,
        'answer': null,
        'left': 18,
      },
    );
    await chat.send('What is the weather?');
    expect(chat.messages.last.kind, HelpKind.noAnswer);
    expect(chat.messages.last.text, isEmpty);
  });

  test('a problem is told by its kind: the limit, not set up, unavailable (also when the network fails)', () async {
    Future<HelpProblem?> problemOf(Object error) async {
      final chat = HelpChat(ask: (q) async => throw error);
      await chat.send('hello');
      return chat.messages.last.problem;
    }

    expect(
      await problemOf(ApiException('too_many_questions', 'x', status: 429)),
      HelpProblem.limit,
    );
    expect(
      await problemOf(ApiException('help_not_configured', 'x', status: 503)),
      HelpProblem.notSet,
    );
    expect(
      await problemOf(ApiException('help_unavailable', 'x', status: 502)),
      HelpProblem.unavailable,
    );
    expect(
      await problemOf(ApiException('network', 'x')),
      HelpProblem.unavailable,
    );
    expect(
      await problemOf(StateError('anything else')),
      HelpProblem.unavailable,
    );
  });

  test(
    '"Try again" asks the same question again and does not show it twice',
    () async {
      var calls = 0;
      final chat = HelpChat(
        ask: (q) async {
          calls += 1;
          if (calls == 1) {
            throw ApiException('help_unavailable', 'x', status: 502);
          }
          return _answer('Now it works.');
        },
      );
      await chat.send('How do I register?');
      final failed = chat.messages.last;
      expect(failed.kind, HelpKind.error);
      await chat.retry(failed);
      expect(calls, 2);
      expect(chat.messages.map((m) => m.kind), [
        HelpKind.mine,
        HelpKind.answer,
      ]);
      expect(chat.messages.last.text, 'Now it works.');
    },
  );

  test('"was this helpful?" is said once per answer and goes to the server with the question id', () async {
    final said = <String>[];
    final chat = HelpChat(
      ask: (q) async => _answer('An answer.', id: '41'),
      feedback: (id, helpful) async => said.add('$id:$helpful'),
    );
    await chat.send('hello');
    final answer = chat.messages.last;
    await chat.rate(answer, false);
    await chat.rate(answer, true); // already said
    expect(said, ['41:false']);
    expect(answer.helpful, isFalse);
  });

  test(
    'a feedback that cannot be sent is not an error for the member',
    () async {
      final chat = HelpChat(
        ask: (q) async => _answer('Yes.'),
        feedback: (id, h) async => throw ApiException('network', 'x'),
      );
      await chat.send('hello');
      await chat.rate(chat.messages.last, true);
      expect(chat.messages.last.helpful, isTrue);
    },
  );

  test('the help words exist in every language the app shows (an empty one shows the English, never the key)', () {
    const keys = [
      'mn_help',
      'help_sub',
      'help_hello',
      'help_write',
      'help_thinking',
      'help_slow',
      'help_none',
      'help_talk',
      'help_retry',
      'help_error',
      'help_limit',
      'help_off',
      'help_helpful',
      'help_yes',
      'help_no',
      'help_thanks',
      'help_note',
      'help_ex1',
      'help_ex2',
      'help_ex3',
      'help_ex4',
    ];
    for (final key in keys) {
      final english = trIn(AppLang.en, key);
      expect(english, isNot(key), reason: key);
      for (final lang in AppLang.values) {
        expect(trIn(lang, key), isNot(key), reason: '$key in ${lang.name}');
        expect(
          trIn(lang, key).trim(),
          isNotEmpty,
          reason: '$key in ${lang.name}',
        );
      }
      // The Indian languages have their own words (Yes / No are the short ones, so compare the longer texts only).
      if (english.length > 6) {
        for (final lang in [
          AppLang.hi,
          AppLang.mr,
          AppLang.kn,
          AppLang.ml,
          AppLang.te,
          AppLang.ta,
        ]) {
          expect(
            trIn(lang, key),
            isNot(english),
            reason: '$key in ${lang.name} is not translated',
          );
        }
      }
    }
  });

  test('Help is in the Menu', () {
    expect(kMenuItems.any((i) => i.id == 'help' && i.key == 'mn_help'), isTrue);
  });

  testWidgets(
    'the screen greets, offers example questions, shows the answer and Talk to us when there is none',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final asked = <String>[];
      final chat = HelpChat(
        ask: (q) async {
          asked.add(q);
          if (q.contains('weather')) {
            return {'id': '2', 'answered': false, 'answer': null, 'left': 18};
          }
          return _answer('You can send two prayer requests a day.');
        },
        feedback: (id, helpful) async {},
      );
      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: HelpChatScreen(chat: chat),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('I can answer questions about the Noah app'),
        findsOneWidget,
      );
      expect(
        find.text('How many prayer requests can I send in a day?'),
        findsOneWidget,
        reason: 'an example question',
      );

      // Tapping an example asks it.
      await tester.tap(find.byKey(const ValueKey('help_ex2')));
      await tester.pumpAndSettle();
      expect(asked, ['How many prayer requests can I send in a day?']);
      expect(
        find.text('You can send two prayer requests a day.'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('help_ex2')),
        findsNothing,
        reason: 'the examples go once the chat has begun',
      );
      expect(find.text('Was this helpful?'), findsOneWidget);
      expect(find.byKey(const ValueKey('help-talk')), findsNothing);

      // "No" offers Talk to us; the thanks replaces the question.
      await tester.tap(find.byKey(const ValueKey('help-no')));
      await tester.pumpAndSettle();
      expect(find.text('Thank you for telling us.'), findsOneWidget);
      expect(find.byKey(const ValueKey('help-talk')), findsOneWidget);

      // A question the FAQ has nothing on: the assistant says so and offers Talk to us.
      await tester.enterText(
        find.byKey(const ValueKey('help-input')),
        'What is the weather in Mumbai?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('help-send')));
      await tester.pumpAndSettle();
      expect(asked.last, 'What is the weather in Mumbai?');
      expect(
        find.text('I do not have an answer for that. You can talk to us.'),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('help-talk')), findsNWidgets(2));
    },
  );

  testWidgets(
    'while an answer is awaited the screen says so and takes no second question; an error offers Try again',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      var attempts = 0;
      final pending = <Future<Map<String, dynamic>>>[];
      final chat = HelpChat(
        ask: (q) {
          attempts += 1;
          if (attempts == 1) {
            final slow = Future<Map<String, dynamic>>.delayed(
              const Duration(seconds: 20),
              () => throw ApiException('help_unavailable', 'x', status: 502),
            );
            pending.add(slow);
            return slow;
          }
          return Future.value(_answer('Second time lucky.'));
        },
      );
      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: HelpChatScreen(chat: chat),
          ),
        ),
      );
      await tester.pump();

      await tester.enterText(
        find.byKey(const ValueKey('help-input')),
        'How do I register?',
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('help-send')));
      await tester.pump();
      expect(find.text('Looking for the answer…'), findsOneWidget);
      expect(find.text('This can take up to half a minute.'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('help-input')))
            .enabled,
        isFalse,
      );

      await tester.pump(const Duration(seconds: 21));
      await tester.pump();
      expect(find.text('Looking for the answer…'), findsNothing);
      expect(
        find.text(
          'The help assistant is not available right now. Please try again in a moment.',
        ),
        findsOneWidget,
      );
      expect(find.text('How do I register?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('help-retry')));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(find.text('Second time lucky.'), findsOneWidget);
      expect(
        find.text('How do I register?'),
        findsOneWidget,
        reason: 'the question is not shown twice',
      );
    },
  );
}
