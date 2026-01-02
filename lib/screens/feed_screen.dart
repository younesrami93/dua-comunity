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
  // Data
  List<Post> _posts = [];
  AppUser? _currentUser;

  // UI State
  bool _isLoading = true; // First load
  int? _selectedCategoryId;

  // ✅ Pagination State
  String? _nextCursor; // Store the weird string (e.g., "eyJpZCI6MT...")
  bool _isLoadingMore = false; // Loading next page
  bool _hasMore = true; // Are there more posts?

  @override
  void initState() {
    super.initState();
    ApiService().getStoredUser();
    _loadData();
  }

  // 1. Initial Load / Pull-to-Refresh
  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() {
      _nextCursor = null; // ✅ Reset cursor
      _hasMore = true; // Reset "has more"
      if (_posts.isEmpty) _isLoading = true; // Only show full spinner if empty
    });

    try {
      final api = ApiService();

      // Fetch Page 1 and Profile
      final results = await Future.wait([
        api.getFeed(categoryId: _selectedCategoryId, cursor: null),
        api.getUserProfile(),
      ]);

      if (mounted) {
        setState(() {
          final feedData = results[0] as Map<String, dynamic>;
          _posts = feedData['posts'] as List<Post>;
          _nextCursor =
              feedData['next_cursor'] as String?; // ✅ Store next cursor

          if (_nextCursor == null) _hasMore = false; // No more pages

          _currentUser = results[1] as AppUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 2. Load More (Infinite Scroll)

  Future<void> _loadMoreData() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;

    setState(() => _isLoadingMore = true);

    try {
      // ✅ Fetch using the stored cursor
      final result = await ApiService().getFeed(
        categoryId: _selectedCategoryId,
        cursor: _nextCursor,
      );

      if (mounted) {
        setState(() {
          final newPosts = result['posts'] as List<Post>;

          if (newPosts.isEmpty) {
            _hasMore = false;
          } else {
            _posts.addAll(newPosts);
            _nextCursor = result['next_cursor'] as String?; // ✅ Update cursor for next time

            if (_nextCursor == null) _hasMore = false;
          }
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
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
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Color textColor = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final Color surfaceColor = isDark
        ? AppColors.surface
        : AppColors.surfaceLight;

    return Scaffold(
      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: theme.scaffoldBackgroundColor,
              elevation: 0,
              pinned: true,
              floating: true,
              snap: true,
              toolbarHeight: 0,
              expandedHeight: 120.0,

              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            // Avatar
                            GestureDetector(
                              onTap: _goToProfile,
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor: surfaceColor,
                                backgroundImage: _currentUser?.avatarUrl != null
                                    ? NetworkImage(_currentUser!.avatarUrl!)
                                    : null,
                                child: _currentUser?.avatarUrl == null
                                    ? Text(
                                        _currentUser?.username[0]
                                                .toUpperCase() ??
                                            "G",
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // App Name
                            Expanded(
                              child: GestureDetector(
                                onTap: _goToProfile,
                                child: Text(
                                  l10n.appTitle,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ),

                            // Settings Button
                            IconButton(
                              icon: Icon(Icons.settings, color: textColor),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const SettingsScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: CategoryFilterBar(
                  selectedCategoryId: _selectedCategoryId,
                  onCategorySelected: (id) {
                    setState(() {
                      _selectedCategoryId = id;
                      _isLoading = true;
                    });
                    _loadData();
                  },
                ),
              ),
            ),
          ];
        },
        body: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          backgroundColor: surfaceColor,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                )
              : _posts.isEmpty
              ? _buildEmptyState(l10n, isDark)
              : MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  // ✅ Wrap with NotificationListener to detect scroll
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification scrollInfo) {
                      // Check if scrolled to bottom (with 200px buffer)
                      if (!_isLoadingMore &&
                          _hasMore &&
                          scrollInfo.metrics.pixels >=
                              scrollInfo.metrics.maxScrollExtent - 200) {
                        _loadMoreData();
                      }
                      return false;
                    },
                    child: ListView.separated(
                      // ✅ Add +1 to count if we have more posts (for the loader)
                      itemCount: _posts.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        // ✅ Show Loader at the bottom
                        if (index == _posts.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          );
                        }

                        // Normal Post
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
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
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
    final mainTextColor = isDark
        ? AppColors.textPrimary
        : AppColors.textPrimaryLight;
    final subTextColor = isDark
        ? AppColors.textSecondary
        : AppColors.textSecondaryLight;

    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.feed_outlined,
                size: 80,
                color: subTextColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noPostsFound,
                style: TextStyle(
                  color: mainTextColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _selectedCategoryId != null
                    ? l10n.noPostsCategory
                    : l10n.noPostsGeneral,
                textAlign: TextAlign.center,
                style: TextStyle(color: subTextColor, fontSize: 14),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddPostScreen(),
                    ),
                  );
                  if (result == true) {
                    _loadData();
                  }
                },
                icon: const Icon(Icons.add),
                label: Text(l10n.createPostButton),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
