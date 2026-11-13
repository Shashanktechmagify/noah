import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/registration_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/registration/registration_status.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

void main() {
  test(
    'a rejected registration is read from the server with the office note',
    () {
      final r = RegistrationState();
      r.loadFromServer({
        'status': 'rejected',
        'reviewNote': '  The ID proof is not readable.  ',
        'firstName': 'Ravi',
        'lastName': 'Kumar',
        'submittedAt': '2026-11-10T10:00:00.000Z',
      }, '+91 9000000001');
      expect(r.status, RegStatus.rejected);
      expect(r.reviewNote, 'The ID proof is not readable.');
      expect(
        r.completed,
        isTrue,
        reason: 'it was submitted; the status page is where it opens',
      );

      // Sent again: it waits for the office, and the old note is gone.
      r.complete();
      expect(r.status, RegStatus.pending);
      expect(r.reviewNote, '');

      // An older answer with no note still reads.
      r.loadFromServer({
        'status': 'pending',
        'firstName': 'Ravi',
      }, '+91 9000000001');
      expect(r.status, RegStatus.pending);
      expect(r.reviewNote, '');
    },
  );

  testWidgets('the status page says what to correct and offers to correct it', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    registration
      ..status = RegStatus.rejected
      ..reviewNote = 'The ID proof is not readable. Please upload it again.'
      ..completed = true;
    addTearDown(() {
      registration
        ..status = RegStatus.pending
        ..reviewNote = '';
    });
    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(
          theme: buildTheme(),
          home: const RegistrationStatusScreen(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Please correct your registration'), findsOneWidget);
    expect(find.text('NOTE FROM THE OFFICE'), findsOneWidget);
    expect(
      find.text('The ID proof is not readable. Please upload it again.'),
      findsOneWidget,
    );
    expect(find.text('Correct my details'), findsOneWidget);

    // The button opens the form again at the first step, with the office's words at the top.
    await tester.tap(find.text('Correct my details'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('The office asked you to correct some details'),
      findsOneWidget,
    );
    expect(find.textContaining('The ID proof is not readable'), findsOneWidget);
  });

  testWidgets(
    'a registration waiting for the office shows no correction card',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 2200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      registration
        ..status = RegStatus.pending
        ..reviewNote = ''
        ..completed = true;
      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            home: const RegistrationStatusScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Correct my details'), findsNothing);
      expect(find.text('NOTE FROM THE OFFICE'), findsNothing);
    },
  );
}
