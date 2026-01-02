import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  final String? token = prefs.getString('auth_token');
  final String? languageCode = prefs.getString('language_code');

  // 1. Load Theme Preference (Default to System)
  final String themePref = prefs.getString('theme_mode') ?? 'system';
  ThemeMode initialThemeMode;
  if (themePref == 'light') {
    initialThemeMode = ThemeMode.light;
  } else if (themePref == 'dark') {
    initialThemeMode = ThemeMode.dark;
  } else {
    initialThemeMode = ThemeMode.system;
  }

  Widget startScreen;
  if (token != null) {
    startScreen = const FeedScreen();
  } else {
    startScreen = const LoginScreen();
  }

  await dotenv.load(fileName: ".env");

  runApp(MyApp(
    startScreen: startScreen,
    initialLanguageCode: languageCode,
    initialThemeMode: initialThemeMode, // Pass loaded theme
  ));
}

class MyApp extends StatefulWidget {
  final Widget startScreen;
  final String? initialLanguageCode;
  final ThemeMode initialThemeMode;

  const MyApp({
    super.key,
    required this.startScreen,
    this.initialLanguageCode,
    required this.initialThemeMode,
  });

  // Static method to change Locale
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }

  // ✅ Static method to change Theme
  static void setTheme(BuildContext context, ThemeMode newMode) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setTheme(newMode);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  late ThemeMode _themeMode; // State variable for theme

  @override
  void initState() {
    super.initState();
    if (widget.initialLanguageCode != null) {
      _locale = Locale(widget.initialLanguageCode!);
    }
    _themeMode = widget.initialThemeMode;
  }

  Future<void> setLocale(Locale newLocale) async {
    setState(() => _locale = newLocale);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', newLocale.languageCode);
  }

  // ✅ Helper to change theme and save to storage
  Future<void> setTheme(ThemeMode newMode) async {
    setState(() => _themeMode = newMode);

    final prefs = await SharedPreferences.getInstance();
    String modeStr = 'system';
    if (newMode == ThemeMode.light) modeStr = 'light';
    if (newMode == ThemeMode.dark) modeStr = 'dark';

    await prefs.setString('theme_mode', modeStr);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Dua Community',
      debugShowCheckedModeBanner: false,

      // ✅ Theme Configuration
      themeMode: _themeMode,
      theme: AppTheme.lightTheme, // Used when mode is Light or System (day)
      darkTheme: AppTheme.darkTheme, // Used when mode is Dark or System (night)

      locale: _locale,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
        Locale('fr'),
        Locale('id'),
      ],
      home: widget.startScreen,
    );
  }
}