import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noah_frontend_flutter/data/jodie_data.dart';
import 'package:noah_frontend_flutter/data/noahgram_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/main.dart';
import 'package:noah_frontend_flutter/screens/main_shell.dart';
import 'package:noah_frontend_flutter/screens/noahgram/noahgram_widgets.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/event_carousel.dart';

void main() {
  testWidgets('splash -> login -> otp -> home -> tabs -> language',
      (tester) async {
    // Tests fall back to a blocky font unless the bundled one is loaded.
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);

    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const NoahApp());
    expect(find.text('Noah'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Noah'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your code'), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '4821');
    await tester.pump();
    await tester.tap(find.text('Verify and continue'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Karuna Sadan'), findsOneWidget);
    expect(find.text('Night of Worship'), findsOneWidget);

    // Carousel advances on its own.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Family Service'), findsOneWidget);
    expect(find.byType(EventCarousel), findsOneWidget);

    // The nav circle follows the selected tab.
    Rect circle() => tester.getRect(find.byType(AnimatedPositioned).last);
    final homeX = circle().center.dx;
    await tester.tap(find.text('Noahtube'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(circle().center.dx, greaterThan(homeX + 100));
    expect(find.text('Sermons, worship and testimonies'), findsOneWidget);

    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Open for booking'), findsOneWidget);
    expect(find.text('Sunday Second Service'), findsOneWidget);

    // Switch the whole app to Hindi from the Me tab.
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Basic information'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('हिन्दी'), 200,
        scrollable: find.byType(Scrollable).last);
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('बुनियादी जानकारी'), findsOneWidget);

    await tester.tap(find.text('होम'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('आज का पाठ'), findsOneWidget);
  });

  testWidgets('noahgram: feed, like, comment, reels, profile edit', (tester) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppLocale(
      controller: LocaleController(),
      child: MaterialApp(theme: buildTheme(), home: const MainShell()),
    ));
    await tester.pump();

    await tester.tap(find.text('Noahgram').last);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Your story'), findsOneWidget);
    expect(find.text('karunasadan'), findsWidgets);

    // Like the first post.
    final first = noahgram.posts.first;
    expect(first.liked, isFalse);
    await tester.tap(find.byIcon(Icons.favorite_border).at(1));
    await tester.pump();
    expect(first.liked, isTrue);

    // Comment on it.
    await tester.tap(find.byIcon(Icons.chat_bubble_outline).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Comments'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'Amen!');
    await tester.pump();
    await tester.tap(find.text('Post'));
    await tester.pump();
    expect(first.comments.last.text, 'Amen!');
    await tester.tapAt(const Offset(195, 40)); // dismiss the sheet
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Reels tab.
    await tester.tap(find.byIcon(Icons.smart_display_outlined).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Worship moment from last Sunday'), findsWidgets);

    // Profile tab, then edit the name.
    await tester.tap(find.byType(Avatar).first);
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Edit profile'), findsOneWidget);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField).first, 'Daniel F');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // The Me tab shows the same edited name.
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Daniel F'), findsWidgets);
  });

  testWidgets('jodie: match, paywall, payment, chat, daily reward', (tester) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(AppLocale(
      controller: LocaleController(),
      child: MaterialApp(theme: buildTheme(), home: const MainShell()),
    ));
    await tester.pump();
    Future<void> settle() => tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.text('Jodie').last);
    await settle();
    expect(find.text('Discover'), findsOneWidget);

    // Best compatible profile is on top, and is of the opposite gender.
    final top = jodie.deck.first;
    expect(top.gender, Gender.woman);
    expect(find.textContaining(top.firstName), findsWidgets);

    // Like her: she already liked us, so it is a match.
    final matchesBefore = jodie.matches.length;
    await tester.tap(find.byIcon(Icons.favorite).last);
    await settle();
    expect(find.text("It's a match!"), findsOneWidget);
    await tester.tap(find.text('Keep swiping'));
    await settle();
    expect(jodie.matches.length, matchesBefore + 1);

    // Chatting needs Premium: paywall -> demo payment -> chat.
    expect(jodie.isPremium, isFalse);
    await tester.tap(find.text('Matches'));
    await settle();
    await tester.tap(find.text('Meera Thomas'));
    await settle();
    expect(find.text('Unlock chat'), findsWidgets);
    expect(find.text('Pay ₹799'), findsOneWidget);
    final creditsBefore = jodie.credits;
    await tester.tap(find.text('Pay ₹799'));
    await settle();
    expect(find.text('Demo checkout'), findsOneWidget);
    await tester.tap(find.text('Simulate successful payment'));
    await settle();
    expect(jodie.isPremium, isTrue);
    expect(jodie.credits, creditsBefore + 100);
    expect(find.text('Active now'), findsOneWidget); // chat screen opened

    await tester.enterText(find.byType(TextField), 'Hello Meera');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(find.text('Hello Meera'), findsOneWidget);
    await tester.pump(const Duration(seconds: 3)); // demo auto-reply
    await settle();
    expect(find.text('Hello Meera'), findsOneWidget);
    await tester.pageBack();
    await settle();

    // Daily reward.
    final before = jodie.credits;
    await tester.tap(find.byIcon(Icons.stars_rounded).first);
    await settle();
    expect(find.text('Your credits'), findsOneWidget);
    await tester.tap(find.textContaining('Claim +'));
    await settle();
    expect(jodie.credits, greaterThan(before));
    expect(jodie.claimedToday, isTrue);
  });
}
