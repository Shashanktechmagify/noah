import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/screens/home_screen.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';

void main() {
  testWidgets(
    'the gradient tiles on Home are as tall as their text needs: no "bottom overflowed", also in Hindi and with a large phone font',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 2000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      final reported = <String>[];
      final before = FlutterError.onError;
      FlutterError.onError = (d) => reported.add(d.exceptionAsString());
      addTearDown(() => FlutterError.onError = before);

      for (final lang in [AppLang.en, AppLang.hi, AppLang.ta]) {
        for (final scale in [1.0, 1.3]) {
          reported.clear();
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          await tester.pumpWidget(
            AppLocale(
              controller: LocaleController(lang),
              child: MaterialApp(theme: buildTheme(), home: const HomeScreen()),
            ),
          );
          await tester.pump();
          // An overflow is reported as an error of the frame. Only the tiles are looked at here (the sample banners of the demo
          // mode have a row of their own that is wider in Tamil).
          expect(
            reported.where((r) => r.contains('on the bottom')),
            isEmpty,
            reason: '${lang.name} at text size $scale',
          );
        }
      }
    },
  );
}
