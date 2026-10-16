import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:noah_frontend_flutter/data/events_data.dart';
import 'package:noah_frontend_flutter/data/jodie_data.dart';
import 'package:noah_frontend_flutter/data/me_data.dart';
import 'package:noah_frontend_flutter/data/ministry_data.dart';
import 'package:noah_frontend_flutter/data/dial_data.dart';
import 'package:noah_frontend_flutter/data/prayer_data.dart';
import 'package:noah_frontend_flutter/data/profile_data.dart';
import 'package:noah_frontend_flutter/screens/me/profile_info_screen.dart';
import 'package:noah_frontend_flutter/data/world_data.dart';
import 'package:noah_frontend_flutter/data/registration_data.dart';
import 'package:noah_frontend_flutter/screens/registration/registration_flow.dart';
import 'package:noah_frontend_flutter/data/noahgram_data.dart';
import 'package:noah_frontend_flutter/l10n/app_strings.dart';
import 'package:noah_frontend_flutter/main.dart';
import 'package:noah_frontend_flutter/screens/events/events_widgets.dart';
import 'package:noah_frontend_flutter/screens/main_shell.dart';
import 'package:noah_frontend_flutter/screens/noahgram/noahgram_widgets.dart';
import 'package:noah_frontend_flutter/theme/app_theme.dart';
import 'package:noah_frontend_flutter/widgets/event_carousel.dart'
    show EventCarousel, enableCardIdleSway;

void main() {
  enableCardIdleSway = false; // a forever-running animation never settles
  testWidgets('splash -> login -> otp -> home -> tabs -> language', (
    tester,
  ) async {
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
    expect(
      find.text('Christmas convention booking opens 1 October'),
      findsOneWidget,
    );

    // Carousel advances on its own.
    await tester.pump(const Duration(seconds: 4));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Night of Worship'), findsOneWidget);
    expect(find.byType(EventCarousel), findsOneWidget);

    // The nav circle follows the selected tab.
    Rect circle() => tester.getRect(find.byType(AnimatedPositioned).last);
    final homeX = circle().center.dx;
    await tester.tap(find.text('Events'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(circle().center.dx, greaterThan(homeX + 100));
    expect(find.text('My passes'), findsOneWidget);
    expect(find.text('Open for booking'), findsOneWidget);
    expect(find.text('Night of Worship'), findsWidgets);

    // Noahtube now lives behind Menu: the circle jumps to Menu and a bottom
    // popup offers Noahtube.
    await tester.tap(find.text('Menu'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Noahtube'), findsOneWidget);
    expect(circle().center.dx, lessThan(homeX + 100));
    await tester.tap(find.text('Noahtube'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Sermons, worship and testimonies'), findsOneWidget);

    // Switch the whole app to Hindi from the Me tab.
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Your record'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Language'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('App text and content'), findsOneWidget);
    await tester.tap(find.text('हिन्दी · Hindi'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('भाषा'), findsWidgets); // the page title, now in Hindi

    await tester.tap(find.text('होम'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('आज का दैनिक मन्ना'), findsOneWidget);
  });

  testWidgets('noahgram: feed, like, comment, reels, profile edit', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
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

  testWidgets('jodie: match, paywall, payment, chat, daily reward', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
    await tester.pump();
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Not a member yet: the tab shows the membership page.
    jodie.isMember = false;
    await tester.tap(find.text('Jodie').last);
    await settle();
    expect(
      find.text('Find a partner within the church family'),
      findsOneWidget,
    );
    expect(find.text('Four-stage verification'), findsOneWidget);
    await tester.tap(find.text('Become a member · ₹300'));
    await settle();
    expect(find.text('Demo checkout'), findsOneWidget);
    await tester.tap(find.text('Simulate successful payment'));
    await settle();
    expect(jodie.isMember, isTrue);
    expect(
      find.text('My Jodie profile'),
      findsOneWidget,
    ); // "then create your profile"
    await tester.tapAt(const Offset(195, 20)); // close the sheet
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

  testWidgets('home: manna, menu grid, prayer request audience', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
    await tester.pump();
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 100));

    // Home no longer has a prayer section at the bottom.
    expect(find.text('Prayer requests'), findsNothing);
    expect(find.text('Add prayer request'), findsNothing);

    // Manna: list -> detail.
    expect(find.text("Today's Daily Manna"), findsOneWidget);
    await tester.tap(find.text('View all').first);
    await settle();
    expect(find.text('Daily Manna'), findsOneWidget);
    expect(find.text('Peace that guards your heart'), findsOneWidget);
    expect(find.text('Walking by faith'), findsOneWidget);
    await tester.tap(find.text('Strength for today'));
    await settle();
    expect(find.text('Reflection'), findsOneWidget);

    // Prayer request from this Manna: audience is "warriors only" by default.
    final addButton = find.text('Add prayer request');
    await tester.scrollUntilVisible(
      addButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(addButton);
    await settle();
    expect(find.text('New prayer request'), findsOneWidget);
    expect(find.text('About this Manna: Strength for today'), findsOneWidget);
    expect(
      find.text('Default. Our prayer warriors will pray for you.'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField).last, 'Strength for my week');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await settle();
    expect(prayer.requests.first.everyone, isFalse);
    expect(prayer.requests.first.mannaTitleKey, 'manna_3');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();

    // Menu grid: Prayer Request, audience switched to everyone.
    await tester.tap(find.text('Menu'));
    await settle();
    expect(find.text('My Information'), findsOneWidget);
    expect(find.text('Noahtube'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Prayer Request'),
      200,
      scrollable: find.descendant(
        of: find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(GridView),
        ),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.ensureVisible(find.text('Prayer Request'));
    await settle();
    await tester.tap(find.text('Prayer Request'));
    await settle();
    expect(find.text('New prayer request'), findsOneWidget);
    expect(find.textContaining('About this Manna'), findsNothing);
    await tester.tap(find.text('Everyone'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Pray for our church');
    await tester.pump();
    await tester.tap(find.text('Submit'));
    await settle();
    expect(prayer.requests.length, 2);
    expect(prayer.requests.first.everyone, isTrue);

    // Menu items without a screen yet say so.
    await tester.tap(find.text('Menu'));
    await settle();
    await tester.tap(find.text('Podcast'));
    // Look before the snackbar auto-dismisses (pumpAndSettle would wait it out).
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Coming soon'), findsOneWidget);
    await settle();
  });

  testWidgets('events: passes, calendar booking, search', (tester) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
    await tester.pump();
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.text('Events'));
    await settle();
    expect(find.text('My passes'), findsOneWidget);
    expect(find.text('Latest'), findsOneWidget);
    expect(find.text('Swipe to see your other passes'), findsOneWidget);
    final passesBefore = eventsState.passes.length;
    expect(passesBefore, 2);

    // Calendar: pick the day of the next special event and book it.
    final target = eventsState.open.first; // Marathi Service
    await tester.tap(find.byIcon(Icons.edit_calendar_outlined));
    await settle();
    expect(find.text('Book by date'), findsOneWidget);
    if (target.start.month != eventsState.today.month) {
      await tester.tap(find.byIcon(Icons.chevron_right).first);
      await settle();
    }
    await tester.tap(find.text('${target.start.day}').first);
    await settle();
    expect(find.text('Marathi Service'), findsOneWidget);
    expect(eventsState.isBooked(target), isFalse);
    // That day also has a cell meeting, so tap Book inside the Marathi row.
    final marathiRow = find.ancestor(
      of: find.text('Marathi Service'),
      matching: find.byType(EventRow),
    );
    await tester.tap(
      find.descendant(of: marathiRow, matching: find.text('Book')),
    );
    await settle();
    expect(eventsState.isBooked(target), isTrue);
    expect(eventsState.passes.length, passesBefore + 1);
    expect(find.text('Booked'), findsWidgets);

    // Back on the Events tab, search replaces the passes.
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();
    await tester.enterText(find.byType(TextField), 'marathi');
    await tester.pump();
    expect(find.text('My passes'), findsNothing);
    expect(find.text('Marathi Service'), findsWidgets);
    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump();
    expect(find.text('No events match your search'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    expect(find.text('My passes'), findsOneWidget);
  });

  testWidgets('me: pastor chat, messages, everything, jodie', (tester) async {
    jodie.isMember = true;
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
    await tester.pump();
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 100));

    await tester.tap(find.text('Me'));
    await settle();
    expect(find.text('Ps. Emmanuel Kumar'), findsOneWidget);
    expect(find.text('4 members linked'), findsOneWidget);
    expect(ministry.unreadTotal, 2);
    expect(find.text('2 new'), findsOneWidget);

    // Chat with the pastor.
    await tester.tap(find.text('Chat with pastor'));
    await settle();
    expect(find.text('Your pastor'), findsOneWidget);
    expect(find.textContaining('Bring her on Sunday'), findsOneWidget);
    expect(
      find.textContaining('Only you and Ps. Emmanuel Kumar'),
      findsOneWidget,
    );
    expect(ministry.unreadTotal, 0); // opening the chat marks it read
    await tester.enterText(find.byType(TextField), 'Thank you pastor');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.send_outlined));
    await tester.pump();
    expect(ministry.pastor.messages.last.text, 'Thank you pastor');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();
    expect(find.text('2 new'), findsNothing);

    // Messages list -> cell leader chat.
    await tester.tap(find.text('Pastor, cell leader and the office'));
    await settle();
    expect(find.text('Church office'), findsOneWidget);
    await tester.tap(find.text('Blessy Mathew'));
    await settle();
    expect(find.text('Your cell leader'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();

    // "Everything" opens the Menu popup.
    await tester.tap(find.text('Everything'));
    await settle();
    expect(find.text('My Information'), findsOneWidget);
    await tester.tapAt(const Offset(195, 40)); // dismiss
    await settle();

    // Jodie shortcut switches the tab.
    await tester.tap(find.text('Open'));
    await settle();
    expect(find.text('Discover'), findsOneWidget);
  });

  testWidgets('login: language dropdown and country code', (tester) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const NoahApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Noah'), findsOneWidget);
    expect(find.text('English'), findsOneWidget); // the dropdown pill
    expect(find.text('मराठी'), findsNothing); // languages live in the popup
    expect(find.text('+91'), findsOneWidget);

    // Another country: the demo number is cleared, so Continue stays off.
    await tester.tap(find.text('+91'));
    await tester.pumpAndSettle();
    expect(find.text('Choose country code'), findsOneWidget);
    await tester.enterText(find.byType(TextField).last, 'united st');
    await tester.pumpAndSettle();
    await tester.tap(find.text('United States'));
    await tester.pumpAndSettle();
    expect(find.text('+1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '5551234567');
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Sent to +1 5551234567'), findsOneWidget);
    expect(
      find.text('English'),
      findsOneWidget,
    ); // language dropdown on OTP too

    // Back, then switch language from the popup.
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Choose your language'), findsOneWidget);
    await tester.tap(find.text('हिन्दी'));
    await tester.pumpAndSettle();
    expect(find.text('Noah में आपका स्वागत है'), findsOneWidget);
  });

  testWidgets(
    'me inside pages: family, location, photo, identity, drive, store, rewards',
    (tester) async {
      final loader = FontLoader('PlusJakartaSans')
        ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
      await tester.runAsync(loader.load);
      tester.view.physicalSize = const Size(390, 2200); // every row visible
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        AppLocale(
          controller: LocaleController(),
          child: MaterialApp(theme: buildTheme(), home: const MainShell()),
        ),
      );
      await tester.pump();
      Future<void> settle() =>
          tester.pumpAndSettle(const Duration(milliseconds: 100));
      Future<void> back() async {
        await tester.tap(find.byIcon(Icons.arrow_back));
        await settle();
      }

      await tester.tap(find.text('Me'));
      await settle();

      // Family
      await tester.tap(find.text('4 linked · passes and guardianship'));
      await settle();
      final last = noahgram.me.name.split(' ').last; // earlier tests may rename
      expect(find.text('$last household'), findsOneWidget);
      expect(find.text('Linked members'), findsOneWidget);
      expect(find.text('Rebecca $last'), findsOneWidget);
      expect(find.text('Minor'), findsNWidgets(2));
      await back();

      // Location: change it, with a confirmation.
      await tester.tap(find.text('Dadar East').last);
      await settle();
      expect(find.text('YOUR LOCATION'), findsOneWidget);
      await tester.tap(find.text('Andheri West'));
      await settle();
      expect(find.text('Change location?'), findsOneWidget);
      await tester.tap(find.text('Change'));
      await settle();
      expect(meState.location.name, 'Andheri West');
      meState.setLocation(MeState.locations.first); // put the demo back
      await back();

      // Profile photo: upload adds a review entry.
      final photosBefore = meState.photos.length;
      await tester.tap(find.text('Profile photo'));
      await settle();
      expect(find.text('Review history'), findsOneWidget);
      await tester.tap(find.text('Upload a new photograph'));
      await tester.pump();
      expect(meState.photos.length, photosBefore + 1);
      await settle();
      await back();

      // Identity & consent: agree, then record the video.
      await tester.tap(find.text('Identity & consent'));
      await settle();
      expect(find.text('1 · Aadhaar'), findsOneWidget);
      expect(meState.identityDone, 1);
      await tester.tap(find.text('I agree and consent'));
      await settle();
      expect(find.text('Consent recorded'), findsOneWidget);
      await tester.tap(find.text('Record now'));
      await settle();
      expect(find.text('Video submitted'), findsOneWidget);
      expect(meState.identityDone, 3);
      await back();
      expect(find.text('3 of 3'), findsOneWidget);

      // Drive
      await tester.tap(find.text('Shared folders and study material'));
      await settle();
      expect(find.text('Study material'), findsOneWidget);
      expect(find.text('Recent files'), findsOneWidget);
      await tester.tap(find.text('Get').first);
      // The earlier toast must leave before the new one shows.
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Download started'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5)); // let the toast leave
      await settle();
      await back();

      // Store: add to cart, check out through the demo payment.
      await tester.tap(find.text('Books and resources'));
      await settle();
      expect(find.text('The Weight of Grace'), findsOneWidget);
      expect(meState.cartCount, 0);
      await tester.tap(find.text('Add').first);
      await settle();
      expect(meState.cartCount, 1);
      expect(find.text('1 in your cart'), findsOneWidget);
      await tester.tap(find.text('Checkout'));
      await settle();
      expect(find.text('Demo checkout'), findsOneWidget);
      await tester.tap(find.text('Simulate successful payment'));
      await settle();
      expect(meState.cartCount, 0);
      await tester.pump(const Duration(seconds: 5)); // let the toast leave
      await settle();
      await back();

      // Rewards: withdraw once.
      await tester.tap(find.text('Earnings from your Noahgram activity'));
      await settle();
      expect(find.text('Available to withdraw'), findsOneWidget);
      expect(find.text('₹62.40'), findsWidgets);
      expect(meState.canWithdraw, isTrue);
      await tester.tap(find.text('Withdraw ₹62.40'));
      await settle();
      expect(meState.withdrawalPending, isTrue);
      expect(find.text('Withdrawal pending'), findsWidgets);
      await tester.pump(const Duration(seconds: 5)); // let the toast leave
      await settle();
      await back();

      // Notifications and Terms
      await tester.tap(find.text('Service reminders, replies and receipts'));
      await settle();
      expect(find.text("You're all caught up"), findsOneWidget);
      expect(find.text('Earlier'), findsOneWidget);
      await back();
      await tester.tap(find.text('Community terms and how your data is held'));
      await settle();
      expect(find.text('Version 1.0'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsWidgets);
      expect(find.text('About'), findsWidgets);
      await back();

      // Log out returns to the login page (the root navigator).
      await tester.tap(find.text('Log out'));
      await settle();
      expect(find.text('Welcome to Noah'), findsOneWidget);
    },
  );

  testWidgets('registration: six steps, success popup, approval', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.runAsync(World.load); // the address step uses the world data
    registration.start('+91 90000 00001');
    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const RegistrationFlow()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Step 1 of 6 · Your details'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Back on step 1 returns to the login page (nothing is behind this page).
    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Noah'), findsOneWidget);
    registration.start('+91 90000 00001');
    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(
          key: UniqueKey(),
          theme: buildTheme(),
          home: const RegistrationFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Fill the model directly; each step's Continue unlocks when valid.
    final r = registration;
    Future<void> next(String label) async {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
    }

    r
      ..salutation = 'Mr'
      ..firstName = 'Shashank'
      ..lastName = 'Gupta'
      ..email = 'shashank@example.com'
      ..gender = 'male'
      ..dob = DateTime(1990, 5, 4)
      ..marital = 'single'
      ..touch();
    await tester.pump();
    await next('Continue');
    expect(find.text('Step 2 of 6 · Address details'), findsOneWidget);

    r
      ..address1 = '12 Church Road'
      ..state = 'Maharashtra'
      ..city = 'Mumbai'
      ..pin = '400001'
      ..touch();
    await tester.pump();
    await next('Continue');

    r
      ..idType = 'aadhaar'
      ..idNumber = '2345 6789 0123'
      ..idFile = 'id_proof.jpg'
      ..touch();
    await tester.pump();
    await next('Continue');

    r
      ..photoFile = 'photo.jpg'
      ..touch();
    await tester.pump();
    await next('Continue');

    // Ticking the agree box must show a tick (header icon + checkbox).
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.ensureVisible(
      find.text('I have read the document above and I agree to it.'),
    );
    await tester.tap(
      find.text('I have read the document above and I agree to it.'),
    );
    await tester.pump();
    expect(r.agreed, isTrue);
    expect(find.byIcon(Icons.check), findsNWidgets(2));
    r
      ..signature = 'Shashank Gupta'
      ..touch();
    await tester.pump();
    await next('Continue to video');
    expect(find.text('Camera ready'), findsOneWidget);

    // Record for the minimum length, then complete.
    await tester.tap(find.text('Start recording'));
    await tester.pump();
    for (var i = 0; i < videoLimits(AppLang.en).$1; i++) {
      await tester.pump(const Duration(seconds: 1));
    }
    await tester.tap(find.text('Stop recording'));
    await tester.pump();
    await tester.ensureVisible(find.text('Complete registration'));
    await next('Complete registration');
    expect(find.text('Successful'), findsOneWidget); // the popup
    await next('OK');
    expect(find.text('Registration successful'), findsOneWidget);
    expect(find.text('Anitha Varghese · $kOfficePhone'), findsOneWidget);

    // The office returns the video, then approves.
    await tester.ensureVisible(find.text('Simulate: admin approves'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simulate: admin approves'));
    await tester.pumpAndSettle();
    // The popup names the number used at registration.
    expect(find.text('Registration approved'), findsOneWidget);
    expect(
      find.textContaining('approved the registration for +91 90000 00001'),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(r.status, RegStatus.approved);
    expect(find.text('Karuna Sadan'), findsOneWidget);
  });

  test('married members must give an anniversary', () {
    final r = registration;
    r.start('+91 90000 00002');
    r
      ..salutation = 'Mrs'
      ..firstName = 'Anita'
      ..lastName = 'Rao'
      ..email = 'a@b.co'
      ..gender = 'female'
      ..dob = DateTime(1990, 1, 1)
      ..marital = 'single';
    expect(r.detailsValid, isTrue);
    r.marital = 'married';
    expect(r.detailsValid, isFalse); // anniversary missing
    r.anniversary = DateTime(2005, 6, 1); // before she turned 18
    expect(anniversaryError(r.anniversary, r.dob), isNotNull);
    expect(r.detailsValid, isFalse);
    r.anniversary = DateTime(2015, 6, 1);
    expect(r.detailsValid, isTrue);
    expect(r.displayName, 'Mrs Anita Rao');
    expect(r.age, greaterThan(30));
  });

  test('Emirates ID and reference contact', () {
    expect(idNumberError('emirates', '784-1990-1234567-1'), isNull);
    expect(idNumberError('emirates', '784199012345671'), isNull);
    expect(idNumberError('emirates', '123-1990-1234567-1'), isNotNull);
    expect(idNumberError('emirates', '784-1990-123456-1'), isNotNull);
    // Only UAE addresses are offered the Emirates ID.
    expect(
      idTypesFor('United Arab Emirates').map((t) => t.$1),
      contains('emirates'),
    );
    expect(idTypesFor('India').map((t) => t.$1), isNot(contains('emirates')));
    expect(phoneError('+971 50 123 4567'), isNull);
    expect(phoneError('12345'), isNotNull);
    final r = registration;
    r.start('+91 90000 00003');
    r
      ..salutation = 'Mr'
      ..firstName = 'Ravi'
      ..lastName = 'Kumar'
      ..email = 'r@k.co'
      ..gender = 'male'
      ..dob = DateTime(1990, 1, 1)
      ..marital = 'single';
    expect(r.detailsValid, isTrue); // reference is optional
    r.reference = 'Pastor John';
    expect(r.detailsValid, isFalse); // number missing
    r.referencePhone = '+91 98200 11111';
    expect(r.detailsValid, isTrue);
    r.reference = '';
    expect(r.detailsValid, isFalse); // number without a name
  });

  test('registration field validation', () {
    expect(idNumberError('aadhaar', '2345 6789 0123'), isNull);
    expect(idNumberError('aadhaar', '2345 6789 012'), isNotNull); // 11 digits
    expect(idNumberError('aadhaar', '1234 5678 9012'), isNotNull); // starts 1
    expect(idNumberError('pan', 'abcde1234f'), isNull);
    expect(idNumberError('pan', 'ABCD12345F'), isNotNull);
    expect(idNumberError('passport', 'A1234567'), isNull);
    expect(idNumberError('passport', 'A123456'), isNotNull);
    expect(idNumberError('dl', 'MH12 20110012345'), isNull);
    expect(idNumberError('dl', 'MH12 2011001'), isNotNull);
    expect(idNumberError('voter', 'ABC1234567'), isNull);
    expect(idNumberError('voter', 'AB12345678'), isNotNull);
    expect(pinError('400001'), isNull);
    expect(pinError('040001'), isNotNull);
    expect(pinError('4000'), isNotNull);
    expect(emailError('a@b.co'), isNull);
    expect(emailError('a@b'), isNotNull);
    expect(nameError('Shashank'), isNull);
    expect(nameError('R2D2'), isNotNull);
    expect(
      dobError(DateTime.now().subtract(const Duration(days: 365 * 10))),
      isNotNull,
    );
    expect(dobError(DateTime(1990, 1, 1)), isNull);
  });

  testWidgets('world data: every country with its states and cities', (
    tester,
  ) async {
    final w = await tester.runAsync(World.load);
    expect(w!.countries.length, greaterThan(240));
    expect(w.countries, containsAll(['India', 'United States', 'Japan']));
    expect(w.statesOf('India'), contains('Maharashtra'));
    expect(w.citiesOf('India', 'Maharashtra'), contains('Mumbai'));
    // Only that country's states are offered.
    expect(w.statesOf('India'), isNot(contains('California')));
    expect(w.statesOf('United States'), contains('California'));
  });

  testWidgets('home: tabs, word screens and prayer request card', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
    await tester.pump();
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('For the household'), findsOneWidget);
    expect(find.text('All prayers'), findsOneWidget);
    await tester.tap(find.text('Confessions'));
    await settle();
    expect(find.text('I am kept in perfect peace'), findsOneWidget);
    await tester.tap(find.text('Bible commentary'));
    await settle();
    expect(find.text('The day of the Lord'), findsOneWidget);
    await tester.tap(find.text('The day of the Lord'));
    await settle();
    expect(find.text('Joel · chapter 2'), findsOneWidget);
    expect(find.text('Read · 7 languages'), findsNWidgets(4));
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await settle();

    await tester.tap(find.text('Prayers'));
    await settle();
    await tester.tap(find.text('All prayers'));
    await settle();
    expect(find.text('Daily prayers'), findsOneWidget);
    expect(find.text('Earlier this week'), findsOneWidget);
    expect(find.text('Read'), findsNWidgets(3));
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await settle();

    // The prayer request card opens the popup with radio choices.
    await tester.scrollUntilVisible(
      find.text('Do you need prayers?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Start typing your prayer request'));
    await settle();
    expect(find.text('Who should pray?'), findsOneWidget);
    expect(find.text('Prayer warriors'), findsOneWidget);
  });

  testWidgets('me: details change only when the admin accepts a request', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 3600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    profile.seedDemo(); // blood group is the one required detail missing
    profile.requests.clear();

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
    Future<void> settle() => tester.pumpAndSettle();

    expect(find.text('My information'), findsOneWidget);
    expect(
      find.text(
        '1 details are missing. Please raise a request to the admin to add them.',
      ),
      findsOneWidget,
    );
    expect(find.text('Not added yet'), findsOneWidget);
    expect(find.text('Reference contact number'), findsOneWidget);
    expect(find.text('Emirates ID'), findsOneWidget);

    // 1. Tap a missing detail, choose the value and request the admin.
    await tester.tap(find.text('Not added yet'));
    await settle();
    expect(find.text('Request a change'), findsOneWidget);
    expect(find.text('Current: (empty)'), findsOneWidget);
    // Nothing chosen yet: the button is off.
    await tester.tap(find.text('O+'));
    await tester.pump();
    await tester.tap(find.text('Request admin'));
    await settle();
    // The detail itself has not changed: the admin has to accept it first.
    expect(profile.get('blood_group'), '');
    expect(profile.pendingFor('blood_group')!.newValue, 'O+');
    expect(find.text('Requested: O+'), findsOneWidget);
    expect(find.text('Pending'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5)); // let the toast leave
    await settle();

    // 2. The admin rejects: nothing changes.
    await tester.scrollUntilVisible(
      find.textContaining('My requests'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle();
    await tester.tap(find.textContaining('My requests'), warnIfMissed: false);
    await settle();
    expect(find.text('Waiting for admin'), findsOneWidget);
    await tester.tap(find.text('Simulate: admin rejects'));
    await settle();
    expect(find.text('Rejected · detail unchanged'), findsOneWidget);
    expect(profile.get('blood_group'), '');
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();

    // 3. A second request is accepted: the detail is updated.
    await tester.tap(find.text('Not added yet'));
    await settle();
    await tester.tap(find.text('A+'));
    await tester.pump();
    await tester.tap(find.text('Request admin'));
    await settle();
    await tester.pump(const Duration(seconds: 5));
    await settle();
    await tester.scrollUntilVisible(
      find.textContaining('My requests'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await settle();
    await tester.tap(find.textContaining('My requests'), warnIfMissed: false);
    await settle();
    await tester.tap(find.text('Simulate: admin accepts'));
    await settle();
    expect(find.text('Accepted · detail updated'), findsOneWidget);
    expect(profile.get('blood_group'), 'A+');
    expect(profile.missingRequired, 0);
    await tester.tap(find.byIcon(Icons.arrow_back));
    await settle();
    expect(find.text('A+'), findsOneWidget);

    // 4. Typed details are checked before they can be sent.
    await tester.tap(find.text('daniel.fernandes@example.com'));
    await settle();
    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tester.pump();
    expect(find.text('Enter a valid email address'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'daniel@new.com');
    await tester.pump();
    await tester.tap(find.text('Request admin'));
    await settle();
    expect(profile.get('email'), 'daniel.fernandes@example.com');
    expect(profile.pendingFor('email')!.newValue, 'daniel@new.com');
  });

  testWidgets('login: terms and conditions note after the button', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const NoahApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('By continuing, you agree to our'),
      findsOneWidget,
    );
  });

  testWidgets('dial codes: every country has a flag code and dial code', (
    tester,
  ) async {
    final all = await tester.runAsync(DialData.load);
    expect(all!.length, greaterThan(235));
    expect(
      all.every((c) => c.code.length == 2 && c.dial.startsWith('+')),
      isTrue,
    );
    expect(DialData.byCode('AE').dial, '+971');
    expect(DialData.byCode('JP').dial, '+81');
    expect(DialData.byCode('IN').validLength(10), isTrue);
    expect(DialData.byCode('JP').validLength(10), isTrue); // generic range
    expect(DialData.byCode('JP').validLength(3), isFalse);
  });

  test('every literal translation key used in lib/ exists', () {
    final used = <String, String>{};
    for (final f in Directory('lib').listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      if (f.path.endsWith('app_strings.dart')) continue;
      final text = f.readAsStringSync();
      final re = RegExp(
        r"tr(?:In)?\(\s*(?:[A-Za-z_.]+,\s*)?'([a-zA-Z0-9_]+)'",
      );
      for (final m in re.allMatches(text)) {
        used.putIfAbsent(m[1]!, () => f.path);
      }
    }
    final missing = [
      for (final e in used.entries)
        if (trIn(AppLang.en, e.key) == e.key) '${e.key} (${e.value})',
    ];
    expect(missing, isEmpty); // a missing key shows as raw text like "reg_h2"
    for (var i = 1; i <= 5; i++) {
      expect(trIn(AppLang.en, 'reg_h$i'), isNot('reg_h$i'));
      expect(trIn(AppLang.en, 'reg_h${i}s'), isNot('reg_h${i}s'));
    }
  });

  test('video must be between 1 and 2 minutes', () {
    for (final l in [AppLang.en, AppLang.hi, AppLang.mr]) {
      expect(videoLimits(l), (60, 120));
    }
    final r = registration;
    r.videoLang = AppLang.en;
    r.videoSeconds = 50; // under a minute
    expect(r.videoValid, isFalse);
    r.videoSeconds = 60;
    expect(r.videoValid, isTrue);
    r.videoLang = AppLang.hi;
    r.videoSeconds = 120;
    expect(r.videoValid, isTrue);
    r.videoSeconds = 121; // over two minutes
    expect(r.videoValid, isFalse);
  });

  testWidgets('home: eBooks and Praises tabs, praises page, 300-char prayer', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const MainShell()),
      ),
    );
    await tester.pump();
    Future<void> settle() =>
        tester.pumpAndSettle(const Duration(milliseconds: 100));

    // The tab chips scroll sideways: bring the last ones into view.
    await tester.drag(find.text('Bible commentary'), const Offset(-400, 0));
    await settle();
    await tester.tap(find.text('eBooks'));
    await settle();
    expect(find.text('Walking in Compassion'), findsOneWidget);
    expect(find.text('All eBooks'), findsOneWidget);
    await tester.tap(find.text('Praises'));
    await settle();
    expect(find.text('Healing after eight months'), findsOneWidget);
    expect(find.text('Anil Thomas · Pune Camp'), findsOneWidget);
    await tester.tap(find.text('All praises'));
    await settle();
    expect(find.text('Swipe to read the next testimony'), findsOneWidget);
    expect(find.text('PRAISE REPORT'), findsOneWidget);
    expect(find.text('1/6'), findsOneWidget);
    await tester.tap(find.text('Pause'));
    await settle();
    expect(find.text('Paused'), findsOneWidget);
    await tester.drag(
      find.text('Healing after eight months'),
      const Offset(-300, 0),
    );
    await settle();
    expect(find.text('2/6'), findsOneWidget);
    await tester.tap(find.text('Read all praise reports'));
    await settle();
    expect(find.text('Safe delivery'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await settle();
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await settle();

    // The Menu no longer lists David's Shields; eBooks opens its page.
    await tester.tap(find.text('Menu'));
    await settle();
    expect(find.text("David's Shields"), findsNothing);
    await tester.tap(find.text('eBooks').last);
    await settle();
    expect(find.text('Read and keep your favourites'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.chevron_left).first);
    await settle();

    // A prayer request is limited to 300 characters.
    await tester.scrollUntilVisible(
      find.text('Do you need prayers?'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Start typing your prayer request'));
    await settle();
    await tester.enterText(find.byType(TextField).last, 'x' * 350);
    await tester.pump();
    expect(find.text('300/300'), findsOneWidget);
  });

  testWidgets('dates are typed as digits and shown as dd/mm/yyyy', (
    tester,
  ) async {
    final loader = FontLoader('PlusJakartaSans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans.ttf'));
    await tester.runAsync(loader.load);
    tester.view.physicalSize = const Size(390, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    registration.start('+91 90000 00009');
    await tester.pumpWidget(
      AppLocale(
        controller: LocaleController(),
        child: MaterialApp(theme: buildTheme(), home: const RegistrationFlow()),
      ),
    );
    await tester.pumpAndSettle();
    final dob = find.widgetWithText(TextField, '').last;
    final field = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == 'dd/mm/yyyy',
    );
    await tester.ensureVisible(field);
    await tester.enterText(field, '10092005');
    await tester.pump();
    expect(find.text('10/09/2005'), findsOneWidget);
    expect(registration.dob, DateTime(2005, 9, 10));
    expect(dob, findsWidgets);

    // Not a real date: no date is stored and an error is shown.
    await tester.enterText(field, '31022005');
    await tester.pump();
    expect(find.text('31/02/2005'), findsOneWidget);
    expect(registration.dob, isNull);
    expect(
      find.text('Enter a real date as dd/mm/yyyy, not in the future'),
      findsOneWidget,
    );

    // Under 18 is still refused.
    await tester.enterText(field, '10092015');
    await tester.pump();
    expect(find.text('You must be at least 18 years old'), findsOneWidget);
  });

  test('date of joining is set automatically from the registration date', () {
    final r = registration;
    r.start('+91 90000 00007');
    r
      ..salutation = 'Mr'
      ..firstName = 'Ravi'
      ..lastName = 'Kumar'
      ..email = 'r@k.co'
      ..gender = 'male'
      ..dob = DateTime(1990, 1, 1)
      ..marital = 'single';
    expect(r.registeredOn, isNull);
    r.complete(); // the registration is submitted
    final day = r.registeredOn!;
    profile.loadFromRegistration(r); // runs when the admin approves
    final iso =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    expect(profile.get('joined'), iso);
    // It is read only: the member cannot ask to change it.
    final joined = kProfileSections
        .expand((s) => s.fields)
        .firstWhere((f) => f.id == 'joined');
    expect(joined.kind, PfKind.readOnly);
    expect(profile.isRequired(joined), isFalse);
  });
}
