import 'package:flutter/material.dart';
import '../models/Comment.dart';
import '../utils/date_utils.dart';
import '../theme/app_colors.dart';
import '../screens/profile_screen.dart';

class CommentItem extends StatelessWidget {
  final Comment comment;

  const CommentItem({super.key, required this.comment});

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: comment.authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ✅ Clickable Comment Avatar
          GestureDetector(
            onTap: () => _openProfile(context),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.surface,
              backgroundImage: comment.authorAvatar != null
                  ? NetworkImage(comment.authorAvatar!)
                  : null,
              child: comment.authorAvatar == null
                  ? Text(
                comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : "?",
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ Clickable Comment Name
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Text(
                        comment.authorName,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13),
                      ),
                    ),
                    // ✅ Updated DateFormatter to use context for localization
                    Text(
                      DateFormatter.timeAgo(context, comment.createdAt),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.content,
                  style: TextStyle(color: Colors.grey.shade300, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}