import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/AppUser.dart';
import '../models/post.dart';
import '../api/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post_item.dart';
import '../widgets/shimmer_loading.dart'; // ✅ Import Shimmer
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

  // ✅ Pagination State
  String? _nextCursor;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  // Helper to check if this is the current user's profile
  bool get _isCurrentUser => widget.userId == null;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  // 1. Initial Load / Refresh
  Future<void> _loadProfileData() async {
    setState(() {
      if (_posts.isEmpty) _isLoading = true;
      _nextCursor = null; // Reset cursor on refresh
      _hasMore = true;
    });

    try {
      final api = ApiService();

      // 1. Get User Details
      AppUser user;
      if (_isCurrentUser) {
        user = await api.getUserProfile();
      } else {
        user = await api.getUserById(widget.userId!);
      }

      // 2. Get User's Posts (First Page)
      final feedResult = await api.getFeed(userId: user.id, cursor: null);

      if (mounted) {
        setState(() {
          _user = user;
          _posts = feedResult['posts'] as List<Post>;
          _nextCursor = feedResult['next_cursor'] as String?;

          if (_nextCursor == null) _hasMore = false;

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Load More (Infinite Scroll)
  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null || _user == null) return;

    setState(() => _isLoadingMore = true);

    try {
      final api = ApiService();
      final result = await api.getFeed(
          userId: _user!.id,
          cursor: _nextCursor // ✅ Fetch next page
      );

      if (mounted) {
        setState(() {
          final newPosts = result['posts'] as List<Post>;

          if (newPosts.isEmpty) {
            _hasMore = false;
          } else {
            _posts.addAll(newPosts);
            _nextCursor = result['next_cursor'] as String?;

            if (_nextCursor == null) _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _logout() async {
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

    await ApiService().logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('guest_uuid');

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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final backgroundColor = theme.scaffoldBackgroundColor;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    // ✅ USE SHIMMER LOADING
    if (_isLoading && _user == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: const ShimmerProfile(), //
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          _isCurrentUser
              ? l10n.myProfileTitle
              : (_user?.username ?? l10n.profileTitle),
          style: TextStyle(color: textColor),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: _isCurrentUser
            ? [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _goToSettings,
          ),
        ]
            : null,
      ),
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          if (!_isLoadingMore &&
              _hasMore &&
              scrollInfo.metrics.pixels >=
                  scrollInfo.metrics.maxScrollExtent - 200) {
            _loadMoreData();
          }
          return false;
        },
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 40),
            children: [
              // 1. Profile Header Card
              _buildProfileHeader(l10n, isDark),

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
                        color: textColor.withOpacity(0.9),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${_posts.length}",
                      style: TextStyle(color: subTextColor, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // 3. Posts List
              if (_posts.isEmpty && !_isLoading)
                _buildEmptyState(l10n, subTextColor)
              else
                ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: _posts.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 1),
                  itemBuilder: (context, index) {
                    return PostItem(
                      post: _posts[index],
                      onRefresh: () {
                        setState(() {});
                      },
                      // ✅ Handle Deletion Locally
                      onDelete: () {
                        setState(() {
                          _posts.removeAt(index);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.postDeleted ?? "Post deleted")),
                        );
                      },
                    );
                  },
                ),

              // ✅ 4. Bottom Loader
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AppLocalizations l10n, bool isDark) {
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final scaffoldBg = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border.all(color: subTextColor.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 45,
              backgroundColor: scaffoldBg,
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
              color: textColor,
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
                color: scaffoldBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: subTextColor.withOpacity(0.3)),
              ),
              child: Text(
                l10n.guestAccountLabel,
                style: TextStyle(color: subTextColor, fontSize: 12),
              ),
            ),

          const SizedBox(height: 24),

          // Action Buttons (Only for current user)
          if (_isCurrentUser) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _goToSettings,
                    icon: Icon(Icons.settings, size: 18, color: textColor),
                    label: Text(l10n.settingsLabel),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textColor,
                      side: BorderSide(
                          color: subTextColor.withOpacity(0.5)),
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

  Widget _buildEmptyState(AppLocalizations l10n, Color subColor) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          Icon(Icons.feed_outlined,
              size: 48, color: subColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            _isCurrentUser
                ? l10n.noPostsYetUser
                : l10n.noPostsYetOther,
            style: TextStyle(color: subColor, fontSize: 16),
          ),
        ],
      ),
    );
  }
}