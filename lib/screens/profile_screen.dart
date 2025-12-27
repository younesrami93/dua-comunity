import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/AppUser.dart';
import '../models/post.dart';
import '../api/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post_item.dart';
import 'settings_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId; // If null, it's "My Profile"
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  List<Post> _posts = [];
  bool _isLoading = true;

  // Helper to check if this is the current user's profile
  bool get _isCurrentUser => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final api = ApiService();

      // 1. Get User Details
      AppUser user;
      if (_isCurrentUser) {
        user = await api.getUserProfile();
      } else {
        user = await api.getUserById(widget.userId!);
      }

      // 2. Get User's Posts
      final posts = await api.getFeed(userId: user.id);

      if (mounted) {
        setState(() {
          _user = user;
          _posts = posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Reuse the secure logout logic
  Future<void> _logout() async {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logoutTitle), // ✅ "Logout"
        content: Text(l10n.logoutConfirmation), // ✅ "Are you sure..."
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancelButton), // ✅ "Cancel"
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.logoutButton), // ✅ "Logout"
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform Logout
    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('guest_uuid'); // Clear guest ID too

    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  void _goToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        // ✅ Localized Title Logic
        title: Text(_isCurrentUser
            ? l10n.myProfileTitle // "My Profile"
            : (_user?.username ?? l10n.profileTitle)), // Username or "Profile"
        centerTitle: true,
        actions: _isCurrentUser
            ? [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
        ]
            : null,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProfileData,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 40),
          children: [
            // 1. Profile Header Card
            _buildProfileHeader(l10n), // Pass l10n

            const SizedBox(height: 20),

            // 2. Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.grid_on_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.postsLabel, // ✅ "Posts"
                    style: TextStyle(
                      color: AppColors.textPrimary.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_posts.length}",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

            // 3. Posts List
            if (_posts.isEmpty)
              _buildEmptyState(l10n) // Pass l10n
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _posts.length,
                separatorBuilder: (context, index) => const SizedBox(height: 1), // Thin divider
                itemBuilder: (context, index) {
                  return PostItem(post: _posts[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(3), // Border width
            decoration: const BoxDecoration(
              color: AppColors.primary, // Border color
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: AppColors.backgroundDark,
              backgroundImage: _user?.avatarUrl != null ? NetworkImage(_user!.avatarUrl!) : null,
              child: _user?.avatarUrl == null
                  ? Text(
                _user?.username[0].toUpperCase() ?? "G",
                style: const TextStyle(
                  fontSize: 36,
                  color: AppColors.accent,
                  fontWeight: FontWeight.bold,
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(height: 16),

          // Name
          Text(
            _user?.username ?? l10n.guestName, // ✅ Localized Guest Fallback
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),

          // Guest Tag
          if (_user?.isGuest == true)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.textSecondary.withOpacity(0.3)),
              ),
              child: Text(
                l10n.guestAccountLabel, // ✅ "Guest Account"
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),

          const SizedBox(height: 24),

          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(l10n.postsLabel, "${_posts.length}"), // ✅ "Posts"
              _buildStatItem(l10n.likesLabel, "0"), // ✅ "Likes"
              _buildStatItem(l10n.savedLabel, "0"), // ✅ "Saved"
            ],
          ),

          // Action Buttons (Only for current user)
          if (_isCurrentUser) ...[
            const SizedBox(height: 24),
            const Divider(color: Colors.white10),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToSettings,
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(l10n.settingsLabel), // ✅ "Settings"
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(color: AppColors.textSecondary.withOpacity(0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.logoutButton), // ✅ "Logout"
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.like, // Red color
                      side: const BorderSide(color: AppColors.like),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.feed_outlined, size: 48, color: AppColors.textSecondary.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _isCurrentUser ? l10n.noPostsYetUser : l10n.noPostsYetOther, // ✅ Localized Empty States
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          ),
        ],
      ),
    );
  }
}