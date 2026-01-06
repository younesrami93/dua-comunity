import 'package:dua_app/api/api_service.dart';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/services/notification_service.dart';
import 'package:dua_app/theme/app_theme.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ GLOBAL ERROR CATCHER for Black Screen Debugging
  try {
    // 1. Initialize Firebase
    await Firebase.initializeApp();

    // 2. Load Env variables
    await dotenv.load(fileName: ".env");

    // 3. Initialize App Check
    // We intentionally catch errors here so App Check failure doesn't crash the whole app
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: kDebugMode
            ? AndroidProvider.debug
            : AndroidProvider.playIntegrity,
        appleProvider: kDebugMode
            ? AppleProvider.debug
            : AppleProvider.appAttest,
      );
    } catch (e) {
      print("App Check warning: $e");
    }

    // 4. Initialize Notifications
    print("Initializing Notification Service...");
    await NotificationService().init();
    print("Notification Service Init Complete.");

    // 5. Load Preferences & Theme
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString('auth_token');
    final String? languageCode = prefs.getString('language_code');
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

    await ApiService.initAppVersion();

    // 6. Run the App
    runApp(
      MyApp(
        startScreen: startScreen,
        initialLanguageCode: languageCode,
        initialThemeMode: initialThemeMode,
      ),
    );
  } catch (e, stackTrace) {
    // ⚠️ CRITICAL: IF STARTUP FAILS, SHOW ERROR ON SCREEN
    // This prevents the "Black Screen" and tells you exactly what went wrong.
    print("STARTUP ERROR: $e");
    runApp(
      MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.white,
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "App Failed to Start",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      e.toString(),
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Divider(),
                    Text(
                      stackTrace.toString().split('\n').take(5).join('\n'),
                      // Show first 5 lines of stack
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
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

  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: analytics,
  );

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("App built, checking for pending notifications...");

      // ✅ DEBUGGING: Show visual alert if data was found
      final pendingData = NotificationService().pendingData;
      if (pendingData != null) {
        print("notification data found " + pendingData.toString());
      } else {
        print("notification data not found , it was null");
      }

      NotificationService().checkPendingNotification();
    });
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

      navigatorObservers: <NavigatorObserver>[MyApp.observer],

      // ✅ Theme Configuration
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      // Used when mode is Light or System (day)
      darkTheme: AppTheme.darkTheme,

      // Used when mode is Dark or System (night)
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
