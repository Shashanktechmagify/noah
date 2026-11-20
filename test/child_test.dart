import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/family_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/child/child_list_screen.dart';
import 'package:noah_frontend_flutter/screens/child/child_phone_screen.dart';
import 'package:noah_frontend_flutter/screens/entry_screen.dart';
import 'package:noah_frontend_flutter/screens/me/family_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/add_child_dialog.dart';

Future<void> _app(WidgetTester tester, Widget home) async {
  final loader = FontLoader('PlusJakartaSans')
    ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
  await tester.runAsync(loader.load);
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppLocale(
      controller: LocaleController(),
      child: MaterialApp(theme: buildTheme(), home: home),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets(
    'the first page asks child or member; Child asks for the parent\'s mobile number',
    (tester) async {
      await _app(tester, const EntryScreen());
      expect(find.text('Select your login'), findsOneWidget);
      expect(find.text('Child'), findsOneWidget);
      expect(find.text('Members'), findsOneWidget);

      await tester.tap(find.text('Child'));
      await tester.pumpAndSettle();
      expect(find.text("Parent's mobile number"), findsOneWidget);
      // The line about the mother's or father's number is gone: the title says it.
      expect(find.textContaining('mother or father'), findsNothing);
      // No email and no Register link here: a parent signs in with the number they are registered with.
      expect(find.text('Email'), findsNothing);
      expect(
        find.text('New to Noah? Register', findRichText: true),
        findsNothing,
      );
    },
  );

  testWidgets('Members goes to the Login page, which has the Register link', (
    tester,
  ) async {
    await _app(tester, const EntryScreen());
    await tester.tap(find.text('Members'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Noah'), findsWidgets);
    expect(
      find.text('New to Noah? Register', findRichText: true),
      findsOneWidget,
    );
  });

  test('a child is read from the server list', () {
    final c = ChildInfo.fromJson({
      'kidId': '7',
      'name': 'Ravi Kumar Thomas',
      'firstName': 'Ravi',
      'dob': '2018-05-01',
      'age': 8,
      'gender': 'male',
      'state': 'rejected',
      'note': 'The Aadhaar picture is not clear.',
      'photoFileId': null,
    });
    expect(c.name, 'Ravi Kumar Thomas');
    expect(c.state, 'rejected');
    expect(c.note, startsWith('The Aadhaar'));
    expect(c.photoFileId, isNull);
    expect(c.age, 8);
  });

  testWidgets(
    'adding a child asks for the names, the date of birth and the gender, and waits until they are given',
    (tester) async {
      await _app(
        tester,
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => showAddChildDialog(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('Add your child'), findsOneWidget);
      for (final hint in [
        'First name',
        'Middle name (optional)',
        'Last name',
        'Date of birth',
        'Boy',
        'Girl',
      ]) {
        expect(find.text(hint), findsOneWidget, reason: hint);
      }
      // Add stays off until everything but the middle name is given.
      final addFinder = find.text('Add');
      expect(addFinder, findsOneWidget);
      await tester.tap(addFinder);
      await tester.pump();
      expect(
        find.text('Add your child'),
        findsOneWidget,
        reason: 'nothing was sent',
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'First name'),
        'Ravi',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Last name'),
        'Thomas',
      );
      await tester.tap(find.text('Boy'));
      await tester.pump();
      await tester.tap(addFinder);
      await tester.pump();
      expect(
        find.text('Add your child'),
        findsOneWidget,
        reason: 'the date of birth is still missing',
      );
    },
  );

  testWidgets(
    'a child sees the parents in Family, with their number and email',
    (tester) async {
      familyState
        ..people = [
          FamilyPerson(
            name: 'John Thomas',
            relation: 'father',
            isKid: false,
            mobile: '+919000000201',
            email: 'dad@example.com',
          ),
        ]
        ..loaded = true;
      addTearDown(familyState.clear);
      await _app(tester, const FamilyScreen());
      expect(find.text('John Thomas'), findsOneWidget);
      expect(find.textContaining('+919000000201'), findsOneWidget);
      expect(find.textContaining('dad@example.com'), findsOneWidget);
      // The sample passes are gone from this page.
      expect(find.textContaining('Sunday'), findsNothing);
    },
  );

  test('every relation a child can be shown has a name', () {
    for (final r in [
      'father',
      'mother',
      'parent',
      'grandfather',
      'grandmother',
      'grandparent',
      'uncle',
      'aunt',
      'brother',
      'sister',
      'sibling',
      'cousin',
      'relative',
    ]) {
      expect(trIn(AppLang.en, 'rel_$r'), isNot('rel_$r'), reason: r);
      expect(trIn(AppLang.hi, 'rel_$r'), isNotEmpty, reason: r);
    }
  });

  testWidgets(
    'a child of 15 or more adds an own mobile number: the number first, then Send code',
    (tester) async {
      await _app(tester, const ChildPhoneScreen());
      expect(find.text('Add your mobile number'), findsOneWidget);
      expect(find.textContaining('ignore this'), findsOneWidget);
      expect(find.text('Send code'), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '9000000555');
      await tester.pump();
      expect(find.text('Send code'), findsOneWidget);
      expect(kChildPhoneAge, 15);
    },
  );
}
