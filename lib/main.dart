import 'package:dua_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/feed_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Check for existing Token
  final prefs = await SharedPreferences.getInstance();
  final String? token = prefs.getString('auth_token');

  // 2. Decide where to start
  Widget startScreen;
  if (token != null) {
    print("Token found: $token");
    startScreen = const FeedScreen();
  } else {
    startScreen = const LoginScreen();
  }

  runApp(MyApp(startScreen: startScreen));
}

class MyApp extends StatelessWidget {
  final Widget startScreen;

  const MyApp({super.key, required this.startScreen});


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dua App',
      debugShowCheckedModeBanner: false,
      // ✅ APPLY THE THEME HERE
      theme: AppTheme.darkTheme,
      home: startScreen,
    );
  }



}