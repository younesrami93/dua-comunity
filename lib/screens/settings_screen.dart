import 'dart:io';
import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/utils/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/api_service.dart';
import '../main.dart';
import 'login_screen.dart';
import '../theme/app_colors.dart';
import '../models/AppUser.dart'; // ✅ Needed to check user provider

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ==========================================================
  // THEME PICKER LOGIC
  // ==========================================================

  void _showThemePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF212121)
        : AppColors.surfaceLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildThemeItem(
                    context,
                    l10n.themeAuto,
                    'system',
                    selectedMode,
                    Icons.brightness_auto,
                  ),
                  _buildThemeItem(
                    context,
                    l10n.themeDark,
                    'dark',
                    selectedMode,
                    Icons.dark_mode,
                  ),
                  _buildThemeItem(
                    context,
                    l10n.themeLight,
                    'light',
                    selectedMode,
                    Icons.light_mode,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<String> _getThemePref() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('theme_mode') ?? 'system';
  }

  Widget _buildThemeItem(
    BuildContext context,
    String name,
    String modeKey,
    String currentMode,
    IconData icon,
  ) {
    final isSelected = modeKey == currentMode;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : textColor),
      title: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
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
  // LANGUAGE PICKER LOGIC
  // ==========================================================

  void _showLanguagePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark
        ? const Color(0xFF212121)
        : AppColors.surfaceLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
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
                  borderRadius: BorderRadius.circular(2),
                ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;

    return ListTile(
      leading: isSelected
          ? const Icon(Icons.check_circle, color: Colors.orange)
          : Icon(Icons.radio_button_unchecked, color: textColor),
      title: Text(
        name,
        style: TextStyle(
          color: textColor,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () {
        MyApp.setLocale(context, Locale(code));
        Navigator.pop(context);
      },
    );
  }

  // ==========================================================
  // LOGOUT & DELETE ACCOUNT LOGIC
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

  // ✅ UPDATED: Handle both Social and Email account deletion
  Future<void> _deleteAccount(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    // 1. Get Current User (to check provider)
    AppUser? user = ApiService().currentUser;
    // If null, try to load from storage just in case
    user ??= await ApiService().getStoredUser();

    // 2. Identify if Social User (Google/Facebook)
    // Note: Make sure you added 'provider' to AppUser.dart
    final bool isSocialUser =
        user?.auth_provider == 'google' || user?.auth_provider == 'facebook';

    if (!context.mounted) return;

    // 3. Show Initial Confirmation (For EVERYONE)
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

    String password = "";

    // 4. If Email User -> Ask for Password
    if (!isSocialUser) {
      final TextEditingController passwordController = TextEditingController();

      final String? inputPassword = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Confirm Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Please enter your password to permanently delete your account.",
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  isDense: false,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10.0,
                    horizontal: 12.0,
                  ),
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

      // If user cancelled password dialog, stop here
      if (inputPassword == null || inputPassword.trim().isEmpty) return;
      password = inputPassword;
    }

    // 5. Perform Deletion
    // For social users, password is "" (empty), which we handled in backend to ignore.
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
          const SnackBar(
            content: Text("Incorrect password or failed to delete."),
          ),
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final subTextColor = isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(l10n.settingsTitle, style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        backgroundColor: backgroundColor,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 10),

          // Language Tile
          ListTile(
            leading: Icon(Icons.language, color: textColor),
            title: Text(l10n.languageLabel, style: TextStyle(color: textColor)),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: subTextColor,
            ),
            onTap: () => _showLanguagePicker(context),
          ),

          // Theme Tile
          ListTile(
            leading: Icon(Icons.brightness_6, color: textColor),
            title: Text(l10n.themeLabel, style: TextStyle(color: textColor)),
            subtitle: FutureBuilder<String>(
              future: _getThemePref(),
              initialData: 'system',
              builder: (context, snapshot) {
                final mode = snapshot.data;
                String label = l10n.themeAuto;
                if (mode == 'light') label = l10n.themeLight;
                if (mode == 'dark') label = l10n.themeDark;
                return Text(label, style: TextStyle(color: subTextColor));
              },
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: subTextColor,
            ),
            onTap: () => _showThemePicker(context),
          ),

          Divider(
            height: 20,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),

          // Rate Us
          ListTile(
            leading: Icon(Icons.star_rate_rounded, color: textColor),
            title: Text(l10n.rateUsLabel, style: TextStyle(color: textColor)),
            subtitle: Text(
              l10n.rateUsSubtitle,
              style: TextStyle(color: subTextColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: subTextColor,
            ),
            onTap: () => _openStore(context),
          ),

          // Privacy Policy
          ListTile(
            leading: Icon(Icons.privacy_tip_outlined, color: textColor),
            title: Text(
              l10n.privacyPolicyLabel,
              style: TextStyle(color: textColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: subTextColor,
            ),
            onTap: () => _launchUrl(AppConstants.privacyPolicyUrl),
          ),

          // Terms of Use
          ListTile(
            leading: Icon(Icons.description_outlined, color: textColor),
            title: Text(
              l10n.termsOfUseLabel,
              style: TextStyle(color: textColor),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: subTextColor,
            ),
            onTap: () => _launchUrl(AppConstants.termsOfServiceUrl),
          ),

          Divider(
            height: 40,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
          ),

          // ✅ Add the Change Password Tile here
          Builder(
            builder: (context) {
              final user = ApiService().currentUser;
              final bool canChangePassword =
                  user != null &&
                      !user.isGuest &&
                      user.auth_provider == 'email';

              final authProvider = user?.auth_provider;
              if(user == null)
                print("user is null");
              else
                print("user is not null "+authProvider!);

              return ListTile(
                leading: Icon(
                  Icons.lock_reset,
                  color: canChangePassword ? textColor : Colors.grey,
                ),
                title: Text(
                  "Change Password",
                  style: TextStyle(
                    color: canChangePassword ? textColor : Colors.grey,
                  ),
                ),
                trailing: canChangePassword
                    ? Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: subTextColor,
                )
                    : null,
                enabled: canChangePassword,
                // ✅ Disables click if false
                onTap: canChangePassword
                    ? () => _showChangePasswordDialog(context)
                    : null,
              );
            },
          ),
          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.orange),
            title: Text(
              l10n.logoutButton,
              style: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _logout(context),
          ),

          // Delete Account
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              l10n.deleteAccountTitle,
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () => _deleteAccount(context),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    // ✅ Theme & Colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final subTextColor = isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;
    final borderColor = isDark ? AppColors.border : AppColors.borderLight;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;

    // ✅ Helper for Professional Input Styling
    InputDecoration buildInputDecoration(String label) {
      return InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: subTextColor),
        floatingLabelStyle: const TextStyle(color: AppColors.primary),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
        // More padding
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), // Rounded corners
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.black12
            : Colors.grey.shade50, // Subtle background
      );
    }

    showDialog(
      context: context,
      builder: (ctx) {
        bool isLoading = false;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Change Password",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 10),
                    TextField(
                      controller: currentPassController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      cursorColor: AppColors.primary,
                      decoration: buildInputDecoration("Current Password"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPassController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      cursorColor: AppColors.primary,
                      decoration: buildInputDecoration("New Password"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPassController,
                      obscureText: true,
                      style: TextStyle(color: textColor),
                      cursorColor: AppColors.primary,
                      decoration: buildInputDecoration("Confirm New Password"),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 20.0),
                        child: LinearProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                  ],
                ),
              ),
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: subTextColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          // Validation
                          if (currentPassController.text.isEmpty ||
                              newPassController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Please fill in all fields"),
                              ),
                            );
                            return;
                          }

                          if (newPassController.text !=
                              confirmPassController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("New passwords do not match"),
                              ),
                            );
                            return;
                          }

                          if (newPassController.text.length < 8) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Password must be at least 8 characters",
                                ),
                              ),
                            );
                            return;
                          }

                          // Start Loading
                          setState(() => isLoading = true);

                          final result = await ApiService().changePassword(
                            currentPassword: currentPassController.text,
                            newPassword: newPassController.text,
                            newPasswordConfirmation: confirmPassController.text,
                          );

                          if (context.mounted) {
                            setState(() => isLoading = false);
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['success']
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("Change"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
