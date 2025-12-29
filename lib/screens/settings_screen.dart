import 'dart:io';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../main.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart'; // ✅ Import Colors

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ==========================================================
  // ✅ NEW: Theme Picker Logic
  // ==========================================================

  void _showThemePicker(BuildContext context) {
    // ✅ Dynamic Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF212121) : AppColors.surfaceLight; // Matches grey[900] or light surface

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor, // ✅ Dynamic Background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final l10n = AppLocalizations.of(context)!;

        return FutureBuilder<String>(
            future: _getThemePref(),
            initialData: 'system',
            builder: (context, snapshot) {
              final selectedMode = snapshot.data ?? 'system';

              return SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey,
                            borderRadius: BorderRadius.circular(2)
                        )
                    ),
                    const SizedBox(height: 20),

                    _buildThemeItem(context, l10n.themeAuto, 'system', selectedMode, Icons.brightness_auto),
                    _buildThemeItem(context, l10n.themeDark, 'dark', selectedMode, Icons.dark_mode),
                    _buildThemeItem(context, l10n.themeLight, 'light', selectedMode, Icons.light_mode),

                    const SizedBox(height: 20),
                  ],
                ),
              );
            }
        );
      },
    );
  }

  Future<String> _getThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode') ?? 'system';
  }

  Widget _buildThemeItem(BuildContext context, String name, String modeKey, String currentMode, IconData icon) {
    final isSelected = modeKey == currentMode;

    // ✅ Dynamic Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : textColor), // ✅ Dynamic Icon
      title: Text(
          name,
          style: TextStyle(
            color: textColor, // ✅ Dynamic Text
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: AppColors.primary)
          : null,
      onTap: () {
        ThemeMode mode = ThemeMode.system;
        if (modeKey == 'dark') mode = ThemeMode.dark;
        if (modeKey == 'light') mode = ThemeMode.light;

        MyApp.setTheme(context, mode);
        Navigator.pop(context);
      },
    );
  }

  // ==========================================================
  // EXISTING: Language Picker Logic
  // ==========================================================

  void _showLanguagePicker(BuildContext context) {
    // ✅ Dynamic Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF212121) : AppColors.surfaceLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor, // ✅ Dynamic
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2)
                  )
              ),
              const SizedBox(height: 20),

              _buildLanguageItem(context, 'English', 'en'),
              _buildLanguageItem(context, 'العربية', 'ar'),
              _buildLanguageItem(context, 'Français', 'fr'),
              _buildLanguageItem(context, 'Bahasa Indonesia', 'id'),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLanguageItem(BuildContext context, String name, String code) {
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isSelected = currentLocale == code;

    // ✅ Dynamic Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;

    return ListTile(
      leading: isSelected
          ? const Icon(Icons.check_circle, color: Colors.orange)
          : Icon(Icons.radio_button_unchecked, color: textColor), // ✅ Dynamic
      title: Text(
          name,
          style: TextStyle(
            color: textColor, // ✅ Dynamic
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )
      ),
      onTap: () {
        MyApp.setLocale(context, Locale(code));
        Navigator.pop(context);
      },
    );
  }

  // ==========================================================
  // EXISTING LOGIC (Logout, Delete, etc.)
  // ==========================================================

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // Dialogs use Theme.of(context) automatically for background,
    // but we can ensure text visibility if needed.

    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logoutButton),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('guest_uuid');

    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }


  void _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final bool? initialConfirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (initialConfirm != true) return;
    if (!context.mounted) return;

    final TextEditingController passwordController = TextEditingController();

    final String? password = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Confirm Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Please enter your password to permanently delete your account."),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(),
                isDense: false,
                contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 12.0),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, passwordController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );

    if (password == null || password.trim().isEmpty) return;

    final success = await ApiService().deleteAccount(password);

    if (context.mounted) {
      if (success) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Incorrect password or failed to delete.")),
        );
      }
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch $url');
      }
    } catch (e) {
      print("Error launching URL: $e");
    }
  }

  Future<void> _openStore(BuildContext context) async {
    String url;
    if (Platform.isAndroid) {
      url = "market://details?id=com.yahya.dua_app";
    } else if (Platform.isIOS) {
      url = "https://apps.apple.com/app/idYOUR_APP_ID";
    } else {
      return;
    }
    _launchUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor, // ✅ Dynamic Background
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: TextStyle(color: textColor)), // ✅ Dynamic
        iconTheme: IconThemeData(color: textColor), // ✅ Dynamic
        backgroundColor: backgroundColor,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // Language Tile
          ListTile(
            leading: Icon(Icons.language, color: textColor),
            title: Text(l10n.languageLabel, style: TextStyle(color: textColor)), // ✅ Dynamic
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor), // ✅ Dynamic
            onTap: () => _showLanguagePicker(context),
          ),

          // Theme Tile
          ListTile(
            leading: Icon(Icons.brightness_6, color: textColor),
            title: Text(l10n.themeLabel, style: TextStyle(color: textColor)), // ✅ Dynamic
            subtitle: FutureBuilder<String>(
              future: _getThemePref(),
              initialData: 'system',
              builder: (context, snapshot) {
                final mode = snapshot.data;
                // Text widget for subtitle needs dynamic color too if not automatic
                // ListTile subtitle usually is grey, but let's ensure it's correct
                String label = l10n.themeAuto;
                if (mode == 'light') label = l10n.themeLight;
                if (mode == 'dark') label = l10n.themeDark;

                return Text(label, style: TextStyle(color: subTextColor)); // ✅ Dynamic
              },
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor), // ✅ Dynamic
            onTap: () => _showThemePicker(context),
          ),

          Divider(height: 20, color: isDark ? Colors.grey[800] : Colors.grey[300]), // ✅ Dynamic

          // Rate Us
          ListTile(
            leading: Icon(Icons.star_rate_rounded, color: textColor), // ✅ Dynamic
            title: Text(l10n.rateUsLabel, style: TextStyle(color: textColor)), // ✅ Dynamic
            subtitle: Text(l10n.rateUsSubtitle, style: TextStyle(color: subTextColor)), // ✅ Dynamic
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
            onTap: () => _openStore(context),
          ),

          // Privacy Policy
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: textColor), // ✅ Dynamic
            title: Text(l10n.privacyPolicyLabel, style: TextStyle(color: textColor)), // ✅ Dynamic
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
            onTap: () => _launchUrl("https://your-website.com/privacy-policy"),
          ),

          // Terms of Use
          ListTile(
            leading: Icon(Icons.description_outlined, color: textColor), // ✅ Dynamic
            title: Text(l10n.termsOfUseLabel, style: TextStyle(color: textColor)), // ✅ Dynamic
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: subTextColor),
            onTap: () => _launchUrl("https://your-website.com/terms-of-use"),
          ),

          Divider(height: 40, color: isDark ? Colors.grey[800] : Colors.grey[300]), // ✅ Dynamic

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: Text(l10n.logoutButton, style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
            onTap: () => _logout(context),
          ),

          // Delete Account
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(l10n.deleteAccountTitle, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }
}