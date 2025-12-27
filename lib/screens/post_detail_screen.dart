import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../api/api_service.dart';
import '../models/post.dart';
import '../models/Comment.dart';
import '../utils/date_utils.dart';
import '../theme/app_colors.dart';
import 'profile_screen.dart';
import '../widgets/report_modal.dart';
import '../widgets/comment_item.dart';

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
  int? _currentUserId;

  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchCurrentUserId();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentUserId() async {
    try {
      final user = await ApiService().getUserProfile();
      if (mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      print("Could not fetch current user ID: $e");
    }
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

  void _openProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: userId),
      ),
    );
  }

  void _showReportModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return ReportModal(postId: _post.id, contentType: 'post');
          },
        );
      },
    );
  }

  void _sharePost(AppLocalizations l10n) {
    // ✅ Localized Share Text
    final String text = "${_post.content}\n\n${l10n.sharePostText}";
    Share.share(text);
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

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
        title: Text(l10n.postTitle), // ✅ "Post"
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz),
            onSelected: (value) {
              if (value == 'report') {
                _showReportModal();
              } else if (value == 'share') {
                _sharePost(l10n);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'report',
                child: Row(
                  children: [
                    const Icon(Icons.flag_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(l10n.reportAction), // ✅ "Report"
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'share',
                child: Row(
                  children: [
                    const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                    const SizedBox(width: 10),
                    Text(l10n.shareAction), // ✅ "Share"
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                if (index == 0) return _buildHeader(l10n); // Pass l10n

                if (_isLoadingComments) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                        child:
                        CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                if (_comments.isEmpty) {
                  return _buildEmptyState(l10n); // Pass l10n
                }

                if (index == _comments.length + 1) {
                  return TextButton(
                    onPressed: _loadMoreComments,
                    child: _isLoadingMore
                        ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(l10n.loadMoreComments, // ✅ "Load more comments"
                        style: const TextStyle(color: AppColors.primary)),
                  );
                }

                return Column(
                  children: [
                    CommentItem(comment: _comments[index - 1]),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          _buildInputArea(l10n), // Pass l10n
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    final bool isMine = _currentUserId != null && _currentUserId == _post.authorId;
    final bool isAnonymous = _post.is_anonymous;
    final bool showRealIdentity = !isAnonymous || isMine;

    // ✅ Localized Anonymous Display Name
    final String displayName = showRealIdentity ? _post.authorName : l10n.anonymousUser;

    final Widget avatar = showRealIdentity
        ? CircleAvatar(
      radius: 20,
      backgroundColor: AppColors.surface,
      child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
          style: const TextStyle(
              color: AppColors.accent, fontWeight: FontWeight.bold)),
    )
        : const CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey,
      child: Icon(Icons.person, color: Colors.white, size: 20),
    );

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
                  GestureDetector(
                    onTap: showRealIdentity ? () => _openProfile(_post.authorId) : null,
                    child: avatar,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: showRealIdentity ? () => _openProfile(_post.authorId) : null,
                            child: Text(displayName,
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                          if (isMine && isAnonymous)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.textSecondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.anonymousUser, // ✅ Localized Tag
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(_post.categoryName,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                  const Spacer(),
                  Text(DateFormatter.timeAgo(context,_post.createdAt),
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 15),
              Text(
                _post.content,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 16, height: 1.5),
              ),
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.symmetric(
                horizontal: BorderSide(color: AppColors.border, width: 1)),
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
                  _commentFocusNode.requestFocus();
                },
              ),
              const SizedBox(width: 24),
              _actionButton(
                icon: Icons.share_outlined,
                color: AppColors.textTertiary,
                text: l10n.shareAction, // ✅ "Share"
                onTap: () => _sharePost(l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            l10n.noCommentsYet, // ✅ "No comments yet"
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beFirstToComment, // ✅ "Be the first to share..."
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _commentFocusNode.requestFocus();
            },
            icon: const Icon(Icons.edit, size: 18),
            label: Text(l10n.writeCommentButton), // ✅ "Write a comment"
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n) {
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
                  decoration: InputDecoration(hintText: l10n.addCommentHint), // ✅ "Add a comment..."
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

  Widget _actionButton(
      {required IconData icon,
        required Color color,
        required String text,
        required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(text,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}