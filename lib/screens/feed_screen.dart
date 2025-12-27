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
                  backgroundColor: AppColors.surface,
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
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Settings Button
          IconButton(
            icon: const Icon(Icons.settings),
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
              backgroundColor: AppColors.surface,
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
                  : _posts.isEmpty
                  ? _buildEmptyState(l10n) // Pass localization
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

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.feed_outlined,
                  size: 80, color: AppColors.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                l10n.noPostsFound, // ✅ "No Posts Found"
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategoryId != null
                    ? l10n.noPostsCategory // ✅ "No posts for this category..."
                    : l10n.noPostsGeneral, // ✅ "The feed is empty..."
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
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