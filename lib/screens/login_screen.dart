import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/screens/email_auth_screen.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations
import '../api/api_service.dart';
import '../theme/app_colors.dart'; // Import AppColors
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
      // Success! Navigate to Feed and clear the back stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    } else {
      // Show Error
      if (mounted) {
        // ✅ Localized Error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.loginFailedCheckInternet)),
        );
      }
    }
  }

  // 2. Placeholder for Future Logins
  void _showComingSoon(String provider) {
    if (!mounted) return;
    // ✅ Localized Message with Parameter
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.providerLoginComingSoon(provider))),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark, // Theme Background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Logo Section ---
              const Icon(Icons.mosque, size: 100, color: AppColors.primary), // Theme Primary
              const SizedBox(height: 20),
              Text(
                l10n.appTitle, // ✅ "Dua Community" (or "Dua App" if you prefer)
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary, // Theme White
                ),
              ),
              const SizedBox(height: 10),
              Text(
                l10n.appTagline, // ✅ Localized Tagline
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: AppColors.textSecondary), // Theme Grey
              ),
              const SizedBox(height: 60),

              // --- Social Login Buttons ---
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Google"),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: Text(l10n.continueWithGoogle), // ✅ Localized Button
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppColors.textPrimary, // Theme White
                  side: BorderSide(color: AppColors.border), // Theme Border
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Facebook"),
                icon: const Icon(Icons.facebook, size: 28),
                label: Text(l10n.continueWithFacebook), // ✅ Localized Button
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  foregroundColor: AppColors.textPrimary, // Theme White
                  side: BorderSide(color: AppColors.border), // Theme Border
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: (){
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
                  );
                },
                icon: const Icon(Icons.email_outlined, size: 24),
                label: Text(l10n.continueWithEmail), // ✅ Localized Button
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
                    child: Text(l10n.orText, style: TextStyle(color: AppColors.textSecondary)), // ✅ "OR"
                  ),
                  Expanded(child: Divider(color: AppColors.border)),
                ],
              ),

              const SizedBox(height: 40),

              // --- Guest Login Button (Active) ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(
                onPressed: _handleGuestLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, // Theme Primary
                  foregroundColor: AppColors.textPrimary, // Theme White (Text)
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  l10n.continueAsGuest, // ✅ Localized Button
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}