import 'package:flutter/material.dart';
import '../api/api_service.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Logo Section ---
              const Icon(Icons.mosque, size: 100, color: Colors.teal),
              const SizedBox(height: 20),
              const Text(
                'Dua App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Share and discover beautiful Posts.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 60),

              // --- Social Login Buttons (Placeholders) ---
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Google"),
                icon: const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Continue with Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Facebook"),
                icon: const Icon(Icons.facebook, size: 28),
                label: const Text('Continue with Facebook'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 15),
              OutlinedButton.icon(
                onPressed: () => _showComingSoon("Email"),
                icon: const Icon(Icons.email_outlined, size: 24),
                label: const Text('Continue with Email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),

              const SizedBox(height: 40),

              // --- Divider ---
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("OR"),
                  ),
                  Expanded(child: Divider()),
                ],
              ),

              const SizedBox(height: 40),

              // --- Guest Login Button (Active) ---
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _handleGuestLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
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