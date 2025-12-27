import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// ✅ Correct import for generated localizations

import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';

// Global Key for Navigation (Required for your Banned User logic)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // 1. Check for existing Token
  final String? token = prefs.getString('auth_token');

  // 2. Check for saved Language
  final String? languageCode = prefs.getString('language_code');

  // 3. Decide where to start
  Widget startScreen;
  if (token != null) {
    print("Token found: $token");
    startScreen = const FeedScreen();
  } else {
    startScreen = const LoginScreen();
  }

  runApp(MyApp(
    startScreen: startScreen,
    initialLanguageCode: languageCode, // Pass the saved language
  ));
}

class MyApp extends StatefulWidget {
  final Widget startScreen;
  final String? initialLanguageCode;

  const MyApp({
    super.key,
    required this.startScreen,
    this.initialLanguageCode
  });

  // ✅ Static method to allow changing language from anywhere (like Settings)
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  @override
  void initState() {
    super.initState();
    // Set initial language if one was saved
    if (widget.initialLanguageCode != null) {
      _locale = Locale(widget.initialLanguageCode!);
    }
  }

  // Helper to change language and save to storage
  Future<void> setLocale(Locale newLocale) async {
    setState(() {
      _locale = newLocale;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ Keep existing key

      title: 'Dua Community',
      debugShowCheckedModeBanner: false,

      // ✅ Theme
      theme: AppTheme.darkTheme,

      // ✅ Localization Setup
      locale: _locale, // Uses the state variable

      // Use onGenerateTitle to translate the App Name
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,

      localizationsDelegates: const [
        AppLocalizations.delegate, // Generated delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      supportedLocales: const [
        Locale('en'), // English
        Locale('ar'), // Arabic
        Locale('fr'), // French
        Locale('id'), // Indonesian
      ],

      home: widget.startScreen,
    );
  }
}