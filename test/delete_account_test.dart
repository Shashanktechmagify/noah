import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/api_client.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/me/delete_account.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

Future<void> _open(
  WidgetTester tester, {
  required Future<void> Function() delete,
  required List<String> events,
}) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppLocale(
      controller: LocaleController(),
      child: MaterialApp(
        theme: buildTheme(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              key: const ValueKey('open'),
              onPressed: () => confirmAndDeleteAccount(
                context,
                delete: delete,
                onDeleted: () => events.add('signed out'),
              ),
              child: const Text('Delete'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'Delete my account asks first: Cancel does nothing, Delete asks the server, signs the member out and says it is done',
    (tester) async {
      final events = <String>[];
      await _open(
        tester,
        events: events,
        delete: () async => events.add('server'),
      );

      // The message says what happens.
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      expect(find.text('Delete your account?'), findsOneWidget);
      expect(find.textContaining('within 30 days'), findsOneWidget);
      expect(find.textContaining('This cannot be undone'), findsOneWidget);

      // Cancel: nothing happens.
      await tester.tap(find.byKey(const ValueKey('delete-cancel')));
      await tester.pumpAndSettle();
      expect(events, isEmpty);

      // Delete: the server first, then the sign-out, then the message.
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await tester.pumpAndSettle();
      expect(events, ['server', 'signed out']);
      expect(find.text('Your account has been deleted.'), findsOneWidget);
    },
  );

  testWidgets(
    'when the server refuses (office staff, or no network) the member stays signed in and is told why',
    (tester) async {
      final events = <String>[];
      await _open(
        tester,
        events: events,
        delete: () async => throw ApiException(
          'staff_account',
          'An office staff account is removed by the office. Please contact them.',
          status: 409,
        ),
      );
      await tester.tap(find.byKey(const ValueKey('open')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('delete-confirm')));
      await tester.pumpAndSettle();
      expect(events, isEmpty, reason: 'not signed out');
      expect(
        find.text(
          'An office staff account is removed by the office. Please contact them.',
        ),
        findsOneWidget,
      );
      expect(find.text('Your account has been deleted.'), findsNothing);
    },
  );

  test('the delete-account words exist in every language the app shows', () {
    for (final key in [
      'me2_delete',
      'me2_delete_sub',
      'del_title',
      'del_body',
      'del_confirm',
      'del_cancel',
      'del_done',
    ]) {
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
            reason: '$key in ${lang.name}',
          );
        }
      }
    }
    // The 30 days are in every language of the message.
    for (final lang in AppLang.values) {
      expect(trIn(lang, 'del_body'), contains('30'), reason: lang.name);
    }
  });
}
