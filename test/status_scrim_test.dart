import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/page_scaffold.dart';

void main() {
  testWidgets(
    'a page keeps the status bar clear: a strip in the page colour appears once the purple band has scrolled off, and goes again at the top',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(
            theme: buildTheme(),
            // A phone with a status bar of 30.
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(padding: const EdgeInsets.only(top: 30)),
              child: child!,
            ),
            home: Scaffold(
              body: PageScaffold(
                title: 'A page',
                leadingIcon: Icons.arrow_back,
                children: [
                  for (var i = 0; i < 30; i++)
                    SizedBox(height: 100, child: Text('Row $i')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      double opacity() => tester
          .widget<Opacity>(find.byKey(const ValueKey('status-bar-scrim')))
          .opacity;
      final strip = find.byKey(const ValueKey('status-bar-scrim'));

      // At the top the purple band is under the status bar: no strip.
      expect(opacity(), 0);
      expect(
        tester.getSize(strip).height,
        30,
        reason: 'as tall as the status bar',
      );
      expect(tester.getTopLeft(strip).dy, 0);

      // Scrolled well past the band: the strip is there, in the page colour.
      await tester.drag(find.text('Row 3'), const Offset(0, -700));
      await tester.pumpAndSettle();
      expect(opacity(), 1);
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(of: strip, matching: find.byType(ColoredBox)),
            )
            .color,
        AppColors.surface,
      );

      // Back at the top: gone, the band reaches the top of the screen again.
      await tester.drag(find.byType(ListView), const Offset(0, 5000));
      await tester.pumpAndSettle();
      expect(opacity(), 0);
    },
  );
}
