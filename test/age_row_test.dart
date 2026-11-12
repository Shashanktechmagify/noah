import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/data/profile_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/me/profile_info_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

void main() {
  testWidgets('My information shows the age in years and months', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 6000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Born 27 September 2005, as the server sends it.
    profile.loadFromServer({
      'fields': {'dob': '2005-09-27', 'first_name': 'Test'},
    });
    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(
          theme: buildTheme(),
          home: const ProfileInfoScreen(),
        ),
      ),
    );
    await tester.pump();

    final parts = profile.ageParts!;
    final years = parts.years == 1
        ? '${parts.years} year'
        : '${parts.years} years';
    final months = parts.months == 0
        ? ''
        : parts.months == 1
        ? ' ${parts.months} month'
        : ' ${parts.months} months';
    expect(find.text('$years$months'), findsOneWidget);
    // Today (the test runs on the real date) the row says the same thing the numbers say.
    // ignore: avoid_print
    print('age shown today: $years$months');
  });
}
