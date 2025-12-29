import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/screens/settings_screen.dart';
import 'package:flutter/material.dart';
// ✅ Import generated localizations
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/AppUser.dart';
import '../models/post.dart';
import '../theme/app_colors.dart';
import '../widgets/category_filter_bar.dart';
import 'add_post_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../widgets/post_item.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  AppUser? _currentUser;
  bool _isLoading = true;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final api = ApiService();
      // Fetch both Feed and Profile in parallel
      final results = await Future.wait([
        api.getFeed(categoryId: _selectedCategoryId),
        api.getUserProfile(),
      ]);

      if (mounted) {
        setState(() {
          _posts = results[0] as List<Post>;
          _currentUser = results[1] as AppUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
    _loadData(); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic Colors
    final Color textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final Color surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: 0,
        title: GestureDetector(
          onTap: _goToProfile,
          child: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor: surfaceColor, // ✅ Dynamic Background
                  backgroundImage: _currentUser?.avatarUrl != null
                      ? NetworkImage(_currentUser!.avatarUrl!)
                      : null,
                  child: _currentUser?.avatarUrl == null
                      ? Text(
                    _currentUser?.username[0].toUpperCase() ?? "G",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  )
                      : null,
                ),

                const SizedBox(width: 12),

                // App Name (Localized)
                Text(
                  l10n.appTitle, // ✅ "Dua Community"
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor, // ✅ Dynamic Text Color
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Settings Button
          IconButton(
            icon: Icon(Icons.settings, color: textColor), // ✅ Dynamic Icon Color
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          CategoryFilterBar(
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (id) {
              setState(() {
                _selectedCategoryId = id;
              });
              _loadData();
            },
          ),

          // Post List
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.primary,
              backgroundColor: surfaceColor, // ✅ Dynamic Background for refresh
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : _posts.isEmpty
                  ? _buildEmptyState(l10n, isDark) // ✅ Pass theme state
                  : ListView.separated(
                itemCount: _posts.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  return PostItem(
                    post: _posts[index],
                    onRefresh: () {
                      setState(() {});
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPostScreen()),
          );
          if (result == true) {
            setState(() => _isLoading = true);
            _loadData();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    // Dynamic Colors for Empty State
    final mainTextColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feed_outlined,
                  size: 80, color: subTextColor.withOpacity(0.5)), // ✅ Dynamic
              const SizedBox(height: 16),
              Text(
                l10n.noPostsFound, // ✅ "No Posts Found"
                style: TextStyle(
                    color: mainTextColor, // ✅ Dynamic
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategoryId != null
                    ? l10n.noPostsCategory // ✅ "No posts for this category..."
                    : l10n.noPostsGeneral, // ✅ "The feed is empty..."
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 14), // ✅ Dynamic
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddPostScreen()),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.createPostButton), // ✅ "Create Post"
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}