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

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor, // ✅ Dynamic
        body: const Center(
            child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor, // ✅ Dynamic
      appBar: AppBar(
        // ✅ Localized Title Logic
        title: Text(
          _isCurrentUser
              ? l10n.myProfileTitle
              : (_user?.username ?? l10n.profileTitle),
          style: TextStyle(color: textColor), // ✅ Dynamic
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor), // ✅ Dynamic
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
            _buildProfileHeader(l10n, isDark), // ✅ Pass theme state

            const SizedBox(height: 20),

            // 2. Section Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.grid_on_rounded,
                      color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    l10n.postsLabel,
                    style: TextStyle(
                      color: textColor.withOpacity(0.9), // ✅ Dynamic
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${_posts.length}",
                    style: TextStyle(color: subTextColor, fontSize: 14), // ✅ Dynamic
                  ),
                ],
              ),
            ),

            // 3. Posts List
            if (_posts.isEmpty)
              _buildEmptyState(l10n, subTextColor) // ✅ Pass color
            else
              ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _posts.length,
                separatorBuilder: (context, index) =>
                const SizedBox(height: 1), // Thin divider
                itemBuilder: (context, index) {
                  return PostItem(post: _posts[index]);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n, bool isDark) {
    // Dynamic Colors
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor, // ✅ Dynamic
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Softer shadow
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
              backgroundColor: scaffoldBg, // ✅ Match dynamic background
              backgroundImage: _user?.avatarUrl != null
                  ? NetworkImage(_user!.avatarUrl!)
                  : null,
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
            _user?.username ?? l10n.guestName,
            style: TextStyle(
              color: textColor, // ✅ Dynamic
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
                color: scaffoldBg, // ✅ Dynamic
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: subTextColor.withOpacity(0.3)), // ✅ Dynamic
              ),
              child: Text(
                l10n.guestAccountLabel,
                style: TextStyle(color: subTextColor, fontSize: 12), // ✅ Dynamic
              ),
            ),

          const SizedBox(height: 24),

          // Stats
         /* Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(l10n.postsLabel, "${_posts.length}", textColor, subTextColor),
              _buildStatItem(l10n.likesLabel, "0", textColor, subTextColor),
              _buildStatItem(l10n.savedLabel, "0", textColor, subTextColor),
            ],
          ),*/

          // Action Buttons (Only for current user)
          if (_isCurrentUser) ...[
            const SizedBox(height: 24),
            Divider(color: isDark ? Colors.white10 : Colors.black12), // ✅ Dynamic Divider
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToSettings,
                    icon: Icon(Icons.settings, size: 18, color: textColor),
                    label: Text(l10n.settingsLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor, // ✅ Dynamic
                      side: BorderSide(
                          color: subTextColor.withOpacity(0.5)), // ✅ Dynamic
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, size: 18),
                    label: Text(l10n.logoutButton),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.like,
                      side: const BorderSide(color: AppColors.like),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
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

  Widget _buildStatItem(String label, String value, Color textColor, Color subColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: textColor, // ✅ Dynamic
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: subColor, // ✅ Dynamic
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, Color subColor) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.feed_outlined,
              size: 48, color: subColor.withOpacity(0.3)), // ✅ Dynamic
          const SizedBox(height: 16),
          Text(
            _isCurrentUser
                ? l10n.noPostsYetUser
                : l10n.noPostsYetOther,
            style: TextStyle(color: subColor, fontSize: 16), // ✅ Dynamic
          ),
        ],
      ),
    );
  }
}