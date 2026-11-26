import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/coming_soon.dart';

Future<void> _show(WidgetTester tester, Widget page) async {
  tester.view.physicalSize = const Size(390, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    AppLocale(
      controller: LocaleController(),
      child: MaterialApp(theme: buildTheme(), home: page),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'a tab that is not built yet says Coming soon (no sample content)',
    (tester) async {
      await _show(
        tester,
        const ComingSoonView(title: 'Jodie', icon: Icons.favorite_border),
      );
      expect(find.text('Jodie'), findsWidgets);
      expect(find.byKey(const ValueKey('coming-soon')), findsOneWidget);
      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.textContaining('future update'), findsOneWidget);
    },
  );

  testWidgets('a page opened from a menu says Coming soon too', (tester) async {
    await _show(
      tester,
      const ComingSoonPage(title: 'Store', icon: Icons.shopping_cart_outlined),
    );
    expect(find.text('Store'), findsWidgets);
    expect(find.text('Coming soon'), findsOneWidget);
  });

  test('the Coming soon words exist in every language the app shows', () {
    for (final key in ['cs_title', 'cs_body']) {
      final english = trIn(AppLang.en, key);
      expect(english, isNot(key), reason: key);
      for (final lang in AppLang.values) {
        expect(
          trIn(lang, key).trim(),
          isNotEmpty,
          reason: '$key in ${lang.name}',
        );
        if (lang != AppLang.en) {
          expect(trIn(lang, key), isNot(english), reason: '$key ${lang.name}');
        }
      }
    }
  });
}
