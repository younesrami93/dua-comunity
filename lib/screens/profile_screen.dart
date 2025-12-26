import 'package:flutter/material.dart';
import '../models/AppUser.dart';
import '../models/post.dart';
import '../api/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/post_item.dart'; // Import the new reusable widget

class ProfileScreen extends StatefulWidget {
  final int? userId; // <--- Optional: If null, it's "My Profile"
  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  List<Post> _posts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    try {
      final api = ApiService();

      // 1. Get User Details

      AppUser user;
      // ✅ LOGIC SWITCH:
      if (widget.userId == null) {
        user = await api.getUserProfile(); // Get Me
      } else {
        user = await api.getUserById(widget.userId!); // Get Them
      }

      // 2. Get User's Posts (using the new filter)
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: ListView(
        children: [
          // 1. The Sleek Profile Card
          _buildProfileHeader(),

          const SizedBox(height: 10),

          // 2. Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              "My Posts",
              style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),

          // 3. The Posts List (Reusing PostItem)
          if (_posts.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40.0),
              child: Center(child: Text("You haven't posted any Posts yet.", style: TextStyle(color: AppColors.textSecondary))),
            )
          else
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Let the outer ListView handle scrolling
              shrinkWrap: true, // Take only needed space
              itemCount: _posts.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                return PostItem(post: _posts[index]);
              },
            ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      color: AppColors.backgroundDark,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Large Avatar
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.surface,
            backgroundImage: _user?.avatarUrl != null ? NetworkImage(_user!.avatarUrl!) : null,
            child: _user?.avatarUrl == null
                ? Text(_user?.username[0].toUpperCase() ?? "G",
                style: const TextStyle(fontSize: 32, color: AppColors.accent, fontWeight: FontWeight.bold))
                : null,
          ),

          const SizedBox(height: 16),

          // Name
          Text(
            _user?.username ?? "Guest",
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
          ),

          if (_user?.isGuest == true)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                "Guest Account",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),

          const SizedBox(height: 24),

          // Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem("Posts", "${_posts.length}"),
              _buildStatItem("Likes", "0"), // Placeholder until API sends total likes received
              _buildStatItem("Saved", "0"), // Placeholder
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
      ],
    );
  }
}