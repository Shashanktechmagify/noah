import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/app_strings.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
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
        home: const SplashScreen(),
      ),
    );
  }
}
