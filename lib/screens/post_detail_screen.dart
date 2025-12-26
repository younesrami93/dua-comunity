import 'package:flutter/material.dart';
import '../api/api_service.dart';
import '../models/post.dart';
import '../models/Comment.dart';
import '../utils/date_utils.dart';
import '../theme/app_colors.dart';
import 'profile_screen.dart'; // ✅ Import ProfileScreen

class PostDetailScreen extends StatefulWidget {
  final Post post;
  const PostDetailScreen({super.key, required this.post});

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Post _post;
  List<Comment> _comments = [];
  String? _nextCursor;
  bool _isLoadingComments = true;
  bool _isLoadingMore = false;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final data = await ApiService().getComments(_post.id);
      if (mounted) {
        setState(() {
          _comments = List<Comment>.from(data['comments']);
          _nextCursor = data['next_cursor'];
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingComments = false);
    }
  }

  Future<void> _loadMoreComments() async {
    if (_nextCursor == null || _isLoadingMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final data = await ApiService().getComments(_post.id, nextCursor: _nextCursor);
      if (mounted) {
        setState(() {
          _comments.addAll(List<Comment>.from(data['comments']));
          _nextCursor = data['next_cursor'];
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _toggleLike() async {
    setState(() {
      _post.isLiked = !_post.isLiked;
      _post.isLiked ? _post.likesCount++ : _post.likesCount--;
    });
    await ApiService().toggleLike(_post.id);
  }

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty) return;
    final content = _commentController.text;
    _commentController.clear();
    FocusScope.of(context).unfocus();
    final success = await ApiService().postComment(_post.id, content);
    if (success) _loadComments();
  }

  // ✅ NEW: Navigation Helper
  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: _post.authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int itemCount = 1;
    if (_isLoadingComments) {
      itemCount += 1;
    } else if (_comments.isEmpty) {
      itemCount += 1;
    } else {
      itemCount += _comments.length;
      if (_nextCursor != null) itemCount += 1;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Post'),
        actions: [IconButton(icon: const Icon(Icons.more_horiz), onPressed: () {})],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == 0) return _buildHeader();

                if (_isLoadingComments) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                if (_comments.isEmpty) {
                  return _buildEmptyState();
                }

                if (index == _comments.length + 1) {
                  return TextButton(
                    onPressed: _loadMoreComments,
                    child: _isLoadingMore
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text("Load more comments", style: TextStyle(color: AppColors.primary)),
                  );
                }

                return Column(
                  children: [
                    _buildComment(_comments[index - 1]),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            "No comments yet",
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Be the first to share your thoughts on this Post.",
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _commentFocusNode.requestFocus();
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("Write a comment"),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // 1. CLICKABLE AVATAR
                  GestureDetector(
                    onTap: _openProfile, // ✅ TAP HERE
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.surface,
                      child: Text(_post.authorName[0].toUpperCase(),
                          style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. CLICKABLE NAME
                      GestureDetector(
                        onTap: _openProfile, // ✅ TAP HERE
                        child: Text(_post.authorName,
                            style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                      Text(_post.categoryName,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text(DateFormatter.timeAgo(_post.createdAt),
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                _post.content,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: AppColors.border, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _actionButton(
                icon: _post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: _post.isLiked ? AppColors.like : AppColors.textTertiary,
                text: "${_post.likesCount}",
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _actionButton(
                icon: Icons.chat_bubble_outline,
                color: AppColors.textTertiary,
                text: "${_comments.length}",
                onTap: () {
                  // Focus the comment box? Or just scroll down?
                  // For now, let's focus the input.
                  _commentFocusNode.requestFocus();
                },
              ),
              const SizedBox(width: 24),
              _actionButton(
                icon: Icons.share_outlined,
                color: AppColors.textTertiary,
                text: "Share",
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ... _buildComment, _buildInputArea, _actionButton (unchanged) ...
  // For completeness, I'll include them so you can copy-paste the whole file easily.

  Widget _buildComment(Comment comment) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.surface,
            backgroundImage: comment.authorAvatar != null ? NetworkImage(comment.authorAvatar!) : null,
            child: comment.authorAvatar == null
                ? Text(comment.authorName[0], style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(comment.authorName,
                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(DateFormatter.timeAgo(comment.createdAt),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(comment.content, style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 45,
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  decoration: const InputDecoration(hintText: "Add a comment..."),
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: IconButton(
                icon: const Icon(Icons.arrow_upward, size: 20, color: Colors.white),
                onPressed: _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({required IconData icon, required Color color, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}