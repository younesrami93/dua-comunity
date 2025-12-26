import 'package:dua_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import '../models/post.dart';
import '../utils/date_utils.dart';
import '../theme/app_colors.dart';
import '../screens/post_detail_screen.dart';
import '../api/api_service.dart';

class PostItem extends StatefulWidget {
  final Post post;
  final VoidCallback? onRefresh; // callback if we need to reload list

  const PostItem({super.key, required this.post, this.onRefresh});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  late Post _post;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
  }

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _post = widget.post; // Sync if parent updates
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(post: _post),
          ),
        ).then((_) {
          // If we come back from details, maybe refresh to show updated likes?
          if (widget.onRefresh != null) widget.onRefresh!();
        });
      },
      child: Container(
        color: AppColors.backgroundDark,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- COLUMN 1: Avatar ---
            GestureDetector(
              onTap: () => _openProfile(context),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.surface,
                child: Text(
                  _post.authorName[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // --- COLUMN 2: Header, Content, Actions ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _post.authorName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        DateFormatter.timeAgo(_post.createdAt),
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // 2. Category
                  Text(
                    _post.categoryName,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 3. Content
                  Text(
                    _post.content,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      height: 1.4,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // 4. Action Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      _actionButton(
                        icon: _post.isLiked
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: _post.isLiked
                            ? AppColors.like
                            : AppColors.textSecondary,
                        label: '${_post.likesCount}',
                        onTap: () async {
                          setState(() {
                            _post.isLiked = !_post.isLiked;
                            _post.isLiked
                                ? _post.likesCount++
                                : _post.likesCount--;
                          });
                          await ApiService().toggleLike(_post.id);
                        },
                      ),

                      const SizedBox(width: 20),

                      _actionButton(
                        icon: Icons.chat_bubble_outline,
                        color: AppColors.textSecondary,
                        label: '${_post.commentsCount}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: _post),
                            ),
                          );
                        },
                      ),

                      const SizedBox(width: 20),

                      _actionButton(
                        icon: Icons.share_outlined,
                        color: AppColors.textSecondary,
                        label: '',
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(label, style: TextStyle(color: color, fontSize: 13)),
            ],
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: _post.authorId),
      ),
    );
  }
}
