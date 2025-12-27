import 'dart:io';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../main.dart'; // ✅ Import main.dart to access MyApp.setLocale
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ==========================================================
  // ✅ NEW: Language Picker Logic
  // ==========================================================

  void _showLanguagePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900], // Dark theme background
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              // Drag handle
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(2)
                  )
              ),
              const SizedBox(height: 20),

              // Language Options
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
    // Check if this language is currently selected
    final currentLocale = Localizations.localeOf(context).languageCode;
    final isSelected = currentLocale == code;

    return ListTile(
      leading: isSelected
          ? const Icon(Icons.check_circle, color: Colors.orange)
          : const Icon(Icons.radio_button_unchecked, color: Colors.white),
      title: Text(
          name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          )
      ),
      onTap: () {
        // ✅ 1. Change Language using the static method in main.dart
        MyApp.setLocale(context, Locale(code));
        // ✅ 2. Close the modal
        Navigator.pop(context);
      },
    );
  }

  // ==========================================================
  // EXISTING LOGIC (Logout, Delete, etc.)
  // ==========================================================

  Future<void> _logout(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

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

  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccountTitle),
        content: Text(l10n.deleteAccountConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.deleteButton),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService().deleteAccount();
      if (success) {
        if (context.mounted) _logout(context);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.deleteAccountFailed)),
          );
        }
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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // ✅ NEW: Language Tile
          ListTile(
            leading: const Icon(Icons.language, color: Colors.blue),
            title: Text(l10n.languageLabel), // "Language" or "اللغة"
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguagePicker(context),
          ),

          const Divider(height: 20),

          // Rate Us
          ListTile(
            leading: const Icon(Icons.star_rate_rounded),
            title: Text(l10n.rateUsLabel),
            subtitle: Text(l10n.rateUsSubtitle),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _openStore(context),
          ),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicyLabel),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl("https://your-website.com/privacy-policy"),
          ),

          // Terms of Use
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfUseLabel),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _launchUrl("https://your-website.com/terms-of-use"),
          ),

          const Divider(height: 40),

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