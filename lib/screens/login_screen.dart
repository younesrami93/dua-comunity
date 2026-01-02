import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/screens/email_auth_screen.dart';
import 'package:dua_app/utils/app_constants.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../theme/app_colors.dart';
import 'feed_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // 1. Guest Login
  Future<void> _handleGuestLogin() async {
    setState(() => _isLoading = true);
    final token = await ApiService().loginAsGuest();
    setState(() => _isLoading = false);

    if (token != null && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
      );
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.loginFailedCheckInternet),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 2. Google Login
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    final String? error = await ApiService().loginWithGoogle();

    setState(() => _isLoading = false);

    if (error == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FeedScreen()),
        );
      }
    } else {
      if (mounted && error != "Login cancelled") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      }
    }
  }

  // 3. Helper to open links
  Future<void> _launchLink(String urlString) async {
    try {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      if (mounted) {
        // ✅ Localized Error
        final errorMsg = AppLocalizations.of(context)!.errorOpenLink;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$errorMsg: $e")),
        );
      }
    }
  }

  void _showComingSoon(String provider) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.providerLoginComingSoon(provider)),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    final btnBg = isDark ? Colors.grey[900]! : Colors.white;
    final btnText = textColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 1),

              // ==========================================================
              // 1. HEADER
              // ==========================================================
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                      spreadRadius: -5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/login_icon.png',
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ✅ Localized Title
              Text(
                l10n.joinCommunityTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: textColor,
                  letterSpacing: -0.5,
                ),
              ),

              const Spacer(flex: 1),

              // ==========================================================
              // 2. AUTH BUTTONS
              // ==========================================================
              _buildProButton(
                text: l10n.continueWithGoogle,
                icon: Icons.g_mobiledata,
                iconColor: textColor,
                bgColor: btnBg,
                textColor: btnText,
                borderColor: borderColor,
                onTap: _handleGoogleLogin,
              ),

              const SizedBox(height: 12),

              _buildProButton(
                text: l10n.continueWithFacebook,
                icon: Icons.facebook,
                iconColor: const Color(0xFF1877F2),
                bgColor: btnBg,
                textColor: btnText,
                borderColor: borderColor,
                onTap: () => _showComingSoon("Facebook"),
              ),

              const SizedBox(height: 12),

              _buildProButton(
                text: l10n.continueWithEmail,
                icon: Icons.email_outlined,
                iconColor: textColor,
                bgColor: btnBg,
                textColor: btnText,
                borderColor: borderColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EmailAuthScreen()),
                  );
                },
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(child: Divider(color: borderColor)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      l10n.orText,
                      style: TextStyle(color: subTextColor, fontSize: 13),
                    ),
                  ),
                  Expanded(child: Divider(color: borderColor)),
                ],
              ),

              const SizedBox(height: 24),

              _isLoading
                  ? const CircularProgressIndicator()
                  : InkWell(
                onTap: _handleGuestLogin,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    l10n.continueAsGuest,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ==========================================================
              // 3. LEGAL FOOTER (Localized)
              // ==========================================================
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: TextStyle(color: subTextColor, fontSize: 12, height: 1.5),
                  children: [
                    TextSpan(text: l10n.agreeToTermsStart), // "By signing up..."
                    TextSpan(
                      text: l10n.termsOfService, // "Terms of Service"
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchLink(AppConstants.termsOfServiceUrl),
                    ),
                    TextSpan(text: l10n.andText), // " and "
                    TextSpan(
                      text: l10n.privacyPolicy, // "Privacy Policy"
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () => _launchLink(AppConstants.privacyPolicyUrl),
                    ),
                    TextSpan(text: l10n.cookieUseEnd), // ", including Cookie Use."
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProButton({
    required String text,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color textColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
            side: BorderSide(color: borderColor, width: 1),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Stack(
          children: [
            Positioned(
              left: 24,
              top: 0,
              bottom: 0,
              child: Icon(icon, size: 22, color: iconColor),
            ),
            Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}