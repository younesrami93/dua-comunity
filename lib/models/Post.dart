class Post {
  final int id;
  final String content;
  final String authorName;
  final String categoryName;
  final String createdAt;
  final int authorId;
  int likesCount;
  bool is_anonymous;
  int commentsCount;
  int sharesCount;
  bool isLiked;

  Post({
    required this.id,
    required this.content,
    required this.authorName,
    required this.categoryName,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.authorId,
    required this.sharesCount,
    required this.is_anonymous,
    this.isLiked = false,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      content: json['content'],
      authorName: json['author'] != null
          ? json['author']['username']
          : 'Anonymous',
      categoryName: json['category'] != null
          ? json['category']['name']
          : 'General',
      likesCount: json['likes_count'] ?? 0,
      is_anonymous: json['is_anonymous'] ?? false,
      authorId: json['author'] != null ? json['author']['id'] : 0,
      sharesCount: json['shares_count'] ?? 0,
      createdAt: json['created_at'] ?? DateTime.now().toIso8601String(),
      isLiked: json['is_liked'] ?? false,
      commentsCount: json['comments_count'] ?? 0,
    );
  }
}
