import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_service.dart';
import '../models/AppUser.dart';
import '../models/post.dart';
import '../theme/app_colors.dart';
import '../widgets/category_filter_bar.dart';
import 'add_post_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import '../widgets/post_item.dart'; // ✅ Import the reusable widget

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<Post> _posts = [];
  AppUser? _currentUser;
  bool _isLoading = true;
  int? _selectedCategoryId; // ✅ State for selected filter

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
      // Optional: Show error
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _goToProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                // 1. Avatar
                CircleAvatar(
                  radius: 24,
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

                const SizedBox(width: 10),

                // 2. Name & Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.username ?? "Guest",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_currentUser != null && _currentUser!.isGuest)
                      Text(
                        'Guest',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Column(
        children: [
          // ✅ 1. Place the Filter Bar here
          CategoryFilterBar(
            selectedCategoryId: _selectedCategoryId,
            onCategorySelected: (id) {
              setState(() {
                _selectedCategoryId = id;
              });
              _loadData(); // Refresh feed with new filter
            },
          ),

          // ✅ 2. The List takes the remaining space
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
                  ? _buildEmptyState()
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


  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.dashboard_customize, size: 60, color: AppColors.textSecondary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              "No Posts Found",
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCategoryId != null
                  ? "No posts for this category yet. Be the first to contribute!"
                  : "The feed is empty. Share a Post with the community!",
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddPostScreen()),
                );
                if (result == true) {
                  _loadData();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text("Create Post"),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            )
          ],
        ),
      ),
    );
  }
}
