import 'package:flutter/foundation.dart';

class Comment {
  final int id;
  final String content;
  final String authorName;
  final String? authorAvatar;
  final String createdAt;
  final List<Comment> replies;

  Comment({
    required this.id,
    required this.content,
    required this.authorName,
    this.authorAvatar,
    required this.createdAt,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    try {
      // 1. Safely parse Replies (Check if it exists AND is a List)
      var repliesList = <Comment>[];
      if (json['replies'] != null && json['replies'] is List) {
        json['replies'].forEach((v) {
          repliesList.add(Comment.fromJson(v));
        });
      }

      // 2. Safely parse Author (Handle nulls gracefully)
      String name = 'Anonymous';
      if (json['author'] != null && json['author'] is Map) {
        if (json['author']['username'] != null) {
          name = json['author']['username'];
        }
      }

      // 3. Return object
      return Comment(
        id: json['id'], // Assumes this is always an Integer
        content: json['content'] ?? "", // Default to empty string if null
        authorName: name,
        createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
        authorAvatar: (json['author'] != null && json['author'] is Map)
            ? json['author']['avatar_url']
            : null,
        replies: repliesList,
      );
    } catch (e) {
      if (kDebugMode) {
        print("❌ Error parsing Comment ID ${json['id']}: $e");
      }
      throw e;
    }
  }
}