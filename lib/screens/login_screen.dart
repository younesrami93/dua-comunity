import 'package:dua_app/screens/email_auth_screen.dart';
import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../theme/app_colors.dart'; // Import Theme
import 'feed_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // 1. Handle Guest Login
  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);

    final token = await ApiService().loginAsGuest();

    setState(() => _isLoading = false);

    if (token != null && mounted) {
      // Success! Navigate to Feed
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    } else {
      // Show Error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login Failed. Please check your internet.')),
        );
      }
    }
  }

  // 2. Placeholder for Future Logins
  void _showComingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$provider Login is coming soon!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark, // Theme Background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Logo / Branding ---
              const Icon(
                Icons.nightlight_round,
                size: 80,
                color: AppColors.primary, // Theme Primary Color
              ),
              const SizedBox(height: 20),
              const Text(
                "Dua Community",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // Theme White
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Share and discover powerful Duas.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary, // Theme Grey
                ),
              ),

              const SizedBox(height: 60),

              // --- Social Buttons ---

              // 1. Google (Preserved)
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Google"),
                icon: const Icon(Icons.g_mobiledata, size: 24),
                label: const Text("Continue with Google"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppColors.textPrimary, // Theme White
                  side: BorderSide(color: AppColors.border), // Theme Border
                ),
              ),
              const SizedBox(height: 15),

              // 2. Facebook (Preserved - NOT Apple)
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Facebook"),
                icon: const Icon(Icons.facebook, size: 24),
                label: const Text("Continue with Facebook"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppColors.textPrimary, // Theme White
                  side: BorderSide(color: AppColors.border), // Theme Border
                ),
              ),
              const SizedBox(height: 15),

              // 3. Email (Preserved)
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
                  );
                },
                icon: const Icon(Icons.email_outlined, size: 24),
                label: const Text("Continue with Email"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppColors.textPrimary, // Theme White
                  side: BorderSide(color: AppColors.border), // Theme Border
                ),
              ),

              const SizedBox(height: 40),

              // --- Divider ---
              Row(
                children: [
                  Expanded(child: Divider(color: AppColors.border)), // Theme Divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR", style: TextStyle(color: AppColors.textSecondary)),
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 40),

              // --- Guest Login Button ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                onPressed: _handleGuestLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Theme Primary
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  'Continue as Guest',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}