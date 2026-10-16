import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';

import 'l10n/app_strings.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
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
