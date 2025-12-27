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

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.welcomeTitle), // Localized Title
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: [
            Tab(text: l10n.loginTab),   // Localized Tab
            Tab(text: l10n.signUpTab),  // Localized Tab
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(isRegister: false, l10n: l10n),
          _buildForm(isRegister: true, l10n: l10n),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isRegister, required AppLocalizations l10n}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (isRegister) ...[
            _buildInput(_nameController, l10n.fullNameHint, Icons.person), // Localized Hint
            const SizedBox(height: 16),
          ],
          _buildInput(_emailController, l10n.emailHint, Icons.email), // Localized Hint
          const SizedBox(height: 16),
          _buildInput(_passwordController, l10n.passwordHint, Icons.lock, isPassword: true), // Localized Hint

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                isRegister ? l10n.createAccountButton : l10n.loginButton, // Localized Button
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController controller, String hint, IconData icon, {bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.textSecondary),
        hintText: hint,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}