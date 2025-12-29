import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations
import '../api/api_service.dart';
import '../theme/app_colors.dart';
import 'feed_screen.dart';

class EmailAuthScreen extends StatefulWidget {
  const EmailAuthScreen({super.key});

  @override
  State<EmailAuthScreen> createState() => _EmailAuthScreenState();
}

class _EmailAuthScreenState extends State<EmailAuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // Only for Register
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    // 1. Basic Validation
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)), // Localized Error
      );
      return;
    }

    if (_tabController.index == 1 && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.enterNameError)), // Localized Error
      );
      return;
    }

    setState(() => _isLoading = true);

    // 2. Variable to hold potential error message (null = success)
    String? errorMessage;

    // ✅ LOGIC RESTORED
    if (_tabController.index == 0) {
      // LOGIN: Returns String? (null if success, error message if failed)
      errorMessage = await ApiService().login(email, password);
    } else {
      // REGISTER: Returns bool (true if success)
      final success = await ApiService().register(name, email, password);
      if (!success) {
        errorMessage = l10n.registrationFailed; // Localized Error
      }
    }

    setState(() => _isLoading = false);

    // 3. Handle Result
    if (errorMessage == null && mounted) {
      // Success: Navigate to Feed
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
            (route) => false,
      );
    } else if (mounted) {
      // Failure: Show the error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage ?? l10n.authFailed), // Localized Fallback
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.border : AppColors.borderLight;

    return Scaffold(
      backgroundColor: backgroundColor, // ✅ Dynamic Background
      appBar: AppBar(
        title: Text(l10n.welcomeTitle, style: TextStyle(color: textColor)), // ✅ Dynamic
        iconTheme: IconThemeData(color: textColor), // ✅ Dynamic
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: subTextColor, // ✅ Dynamic
          dividerColor: borderColor, // ✅ Dynamic
          onTap: (index) {
            setState(() {}); // Rebuild to toggle UI fields
          },
          tabs: [
            Tab(text: l10n.loginTab),   // Localized Tab
            Tab(text: l10n.signUpTab),  // Localized Tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(isRegister: false, l10n: l10n, textColor: textColor, subTextColor: subTextColor, surfaceColor: surfaceColor),
          _buildForm(isRegister: true, l10n: l10n, textColor: textColor, subTextColor: subTextColor, surfaceColor: surfaceColor),
        ],
      ),
    );
  }

  Widget _buildForm({
    required bool isRegister,
    required AppLocalizations l10n,
    required Color textColor,
    required Color subTextColor,
    required Color surfaceColor,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (isRegister) ...[
            _buildInput(_nameController, l10n.fullNameHint, Icons.person, textColor, subTextColor, surfaceColor),
            const SizedBox(height: 16),
          ],
          _buildInput(_emailController, l10n.emailHint, Icons.email, textColor, subTextColor, surfaceColor),
          const SizedBox(height: 16),
          _buildInput(_passwordController, l10n.passwordHint, Icons.lock, textColor, subTextColor, surfaceColor, isPassword: true),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white, // Keep white on primary button
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                isRegister ? l10n.createAccountButton : l10n.loginButton,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String hint,
      IconData icon,
      Color textColor,
      Color subTextColor,
      Color surfaceColor,
      {bool isPassword = false}
      ) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: textColor), // ✅ Dynamic Input Text
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: subTextColor), // ✅ Dynamic Icon
        hintText: hint,
        hintStyle: TextStyle(color: subTextColor), // ✅ Dynamic Hint
        filled: true,
        fillColor: surfaceColor, // ✅ Dynamic Fill
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}