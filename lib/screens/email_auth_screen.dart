import 'package:flutter/material.dart';
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

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in all fields")));
      return;
    }

    // Check if Registering (Tab 1) and Name is empty
    if (_tabController.index == 1 && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please enter your name")));
      return;
    }

    setState(() => _isLoading = true);

    bool success;
    if (_tabController.index == 0) {
      // Login
      success = await ApiService().login(email, password);
    } else {
      // Register
      success = await ApiService().register(name, email, password);
    }

    setState(() => _isLoading = false);

    if (success && mounted) {
      // Go to Feed and remove all previous screens from back stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const FeedScreen()),
            (route) => false,
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication Failed. Check your credentials.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Welcome"),
        bottom: TabBar(
          controller:_tabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: "Log In"),
            Tab(text: "Sign Up"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildForm(isRegister: false),
          _buildForm(isRegister: true),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isRegister}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          if (isRegister) ...[
            _buildInput(_nameController, "Full Name", Icons.person),
            const SizedBox(height: 16),
          ],
          _buildInput(_emailController, "Email Address", Icons.email),
          const SizedBox(height: 16),
          _buildInput(_passwordController, "Password", Icons.lock, isPassword: true),

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
                  : Text(isRegister ? "Create Account" : "Log In", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        // Uses the Theme defaults we set earlier, but just to be sure:
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}