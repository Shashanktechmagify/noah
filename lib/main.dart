import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'data/api_client.dart';
import 'data/deep_links.dart';
import 'data/live_noahgram.dart';
import 'data/ministry_data.dart';
import 'data/notifications_data.dart';
import 'data/pastor_data.dart';
import 'l10n/app_strings.dart';
import 'screens/login_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

/// Lets code outside the widget tree change page (e.g. back to sign-in when the saved sign-in expires).
final appNavigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  api.onSessionLost = () {
    ministry.stopPolling();
    pastorInbox.stop();
    notificationsState.clear();
    liveNoahgram.clear();
    appNavigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  };
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  startDeepLinks(); // a shared Noahgram link opens the app on that post
  runApp(const NoahApp());
}

class NoahApp extends StatefulWidget {
  const NoahApp({super.key});

  @override
  State<NoahApp> createState() => _NoahAppState();
}

class _NoahAppState extends State<NoahApp> {
  final _locale = LocaleController();

  @override
  void dispose() {
    _locale.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocale(
      controller: _locale,
      child: MaterialApp(
        title: 'Noah',
        navigatorKey: appNavigatorKey,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        // Dates are typed and shown day first (dd/mm/yyyy), not month first.
        locale: const Locale('en', 'GB'),
        supportedLocales: const [Locale('en', 'GB')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const SplashScreen(),
      ),
    );
  }
}
