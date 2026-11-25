import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/family_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/me/make_member_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

void main() {
  testWidgets(
    'Make member: the Aadhaar already given shows with View and Remove side by side or wrapped, never overflowing, on a narrow phone and in Hindi',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final reported = <String>[];
      final before = FlutterError.onError;
      FlutterError.onError = (d) => reported.add(d.exceptionAsString());
      addTearDown(() => FlutterError.onError = before);

      const kid = FamilyPerson(
        name: 'Ttt qkkqk',
        relation: 'son',
        isKid: true,
        age: 17,
        kidId: '5',
        aadhaarNo: '643184976461',
        aadhaarFile: true,
        aadhaarAdded: true,
        canMakeMember: true,
      );
      for (final width in [320.0, 360.0, 411.0]) {
        for (final lang in [AppLang.en, AppLang.hi]) {
          reported.clear();
          tester.view.physicalSize = Size(width, 1600);
          tester.view.devicePixelRatio = 1;
          await tester.pumpWidget(
            AppLocale(
              controller: LocaleController(lang),
              child: MaterialApp(
                theme: buildTheme(),
                home: const MakeMemberScreen(child: kid),
              ),
            ),
          );
          await tester.pump();
          expect(
            reported.where((r) => r.contains('overflowed')),
            isEmpty,
            reason: '${lang.name} at $width wide',
          );
          // The Aadhaar given earlier, with both buttons.
          expect(find.text('6431 8497 6461'), findsOneWidget);
          expect(
            find.text('View Aadhaar'),
            lang == AppLang.en ? findsOneWidget : findsNothing,
          );
        }
      }
    },
  );
}
