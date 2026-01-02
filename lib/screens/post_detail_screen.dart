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

  // Translation State
  String? _translatedText;
  bool _isTranslating = false;

  // Delete State
  bool _isDeleting = false;

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
      final data = await ApiService().getComments(
        _post.id,
        nextCursor: _nextCursor,
      );
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
      MaterialPageRoute(builder: (context) => ProfileScreen(userId: userId)),
    );
  }

  void _showReportModal() {
    // ✅ Dynamic Surface Color
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
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
    final String text = "${_post.content}\n\n${l10n.sharePostText}";
    Share.share(text);
  }

  Future<void> _handleTranslate() async {
    if (_translatedText != null) {
      setState(() => _translatedText = null);
      return;
    }

    setState(() => _isTranslating = true);

    final String currentLang = Localizations.localeOf(context).languageCode;

    final result = await ApiService().translateContent(
      id: _post.id,
      type: 'post',
      targetLang: currentLang,
    );

    if (mounted) {
      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
    }
  }

  Future<void> _handleDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text(
            "Are you sure you want to delete this post? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    final success = await ApiService().deletePost(_post.id);

    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete post")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    // Check Ownership
    final currentUser = ApiService().currentUser;
    final bool isMine = currentUser != null && currentUser.id == _post.authorId;

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
        title: Text(l10n.postTitle, style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor), // ✅ Dynamic Icon Color
        actions: [
          if (_isDeleting)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: textColor)),
            )
          else
            PopupMenuButton<String>(
              icon: Icon(Icons.more_horiz, color: textColor), // ✅ Dynamic
              onSelected: (value) {
                if (value == 'report') {
                  _showReportModal();
                } else if (value == 'share') {
                  _sharePost(l10n);
                } else if (value == 'delete') {
                  _handleDelete();
                }
              },
              itemBuilder: (BuildContext context) {
                final List<PopupMenuEntry<String>> items = [];

                if (isMine) {
                  items.add(
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline,
                              color: Colors.red, size: 20),
                          SizedBox(width: 10),
                          Text("Delete", style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                } else {
                  items.add(
                    PopupMenuItem<String>(
                      value: 'report',
                      child: Row(
                        children: [
                          const Icon(Icons.flag_outlined,
                              size: 20, color: Colors.grey),
                          const SizedBox(width: 10),
                          Text(l10n.reportAction),
                        ],
                      ),
                    ),
                  );
                }

                items.add(
                  PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share_outlined,
                            size: 20, color: Colors.grey),
                        const SizedBox(width: 10),
                        Text(l10n.shareAction),
                      ],
                    ),
                  ),
                );

                return items;
              },
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
                if (index == 0) return _buildHeader(l10n, isDark); // ✅ Pass theme

                if (_isLoadingComments) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    ),
                  );
                }

                if (_comments.isEmpty) {
                  return _buildEmptyState(l10n, isDark); // ✅ Pass theme
                }

                if (index == _comments.length + 1) {
                  return TextButton(
                    onPressed: _loadMoreComments,
                    child: _isLoadingMore
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : Text(
                      l10n.loadMoreComments,
                      style: const TextStyle(color: AppColors.primary),
                    ),
                  );
                }

                return Column(
                  children: [
                    CommentItem(
                      comment: _comments[index - 1],
                      onDeleted: () {
                        setState(() {
                          _comments.removeAt(index - 1);
                        });
                      },
                    ),
                    const Divider(),
                  ],
                );
              },
            ),
          ),
          _buildInputArea(l10n, isDark), // ✅ Pass theme
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n, bool isDark) {
    // Dynamic Colors
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.border : AppColors.borderLight;

    final currentUser = ApiService().currentUser;
    final bool isMine = currentUser != null && currentUser.id == _post.authorId;
    final bool isAnonymous = _post.is_anonymous;
    final bool showRealIdentity = !isAnonymous || isMine;

    // ✅ Check Banned Status
    final bool isBanned = _post.status == 'banned';

    final String currentLang = Localizations.localeOf(context).languageCode;
    bool showTranslation =
        _post.language != null && _post.language != currentLang;
    if (isMine) showTranslation = false;

    final String displayName =
    showRealIdentity ? _post.authorName : l10n.anonymousUser;


    final Widget avatar = GestureDetector(
      // ✅ Tap logic: Enabled if showing real identity
      onTap: showRealIdentity ? () => _openProfile(_post.authorId) : null,
      child: CircleAvatar(
        radius: 20,
        backgroundColor: showRealIdentity ? surfaceColor : Colors.grey, // ✅ Dynamic Surface
        // ✅ Load image ONLY if Real Identity is ON and Avatar is NOT NULL
        backgroundImage: (showRealIdentity && _post.authorAvatar != null)
            ? NetworkImage(_post.authorAvatar!)
            : null,
        child: (showRealIdentity && _post.authorAvatar != null)
            ? null // Hide child if image is showing
            : (showRealIdentity
            ? Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : "?",
          style: const TextStyle(
            color: AppColors.accent,
            fontWeight: FontWeight.bold,
          ),
        )
            : const Icon(Icons.person, color: Colors.white, size: 20)),
      ),
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
                    onTap: showRealIdentity
                        ? () => _openProfile(_post.authorId)
                        : null,
                    child: avatar,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GestureDetector(
                            onTap: showRealIdentity
                                ? () => _openProfile(_post.authorId)
                                : null,
                            child: Text(
                              displayName,
                              style: TextStyle(
                                color: textColor, // ✅ Dynamic
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (isMine && isAnonymous)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: subTextColor.withOpacity(0.2), // ✅ Dynamic
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.anonymousUser,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: subTextColor, // ✅ Dynamic
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        _post.categoryName,
                        style: TextStyle(
                            color: subTextColor, fontSize: 12), // ✅ Dynamic
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    DateFormatter.timeAgo(context, _post.createdAt),
                    style: TextStyle(
                        color: subTextColor, fontSize: 12), // ✅ Dynamic
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // ✅ NEW: Banned Flag Indicator
              if (isBanned)
                Container(
                  margin: const EdgeInsets.only(bottom: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Flagged: ${_post.safetyLabel?.toUpperCase() ?? 'VIOLATION'}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content
              Text(
                _post.content,
                style: TextStyle(
                  color: textColor, // ✅ Dynamic
                  fontSize: 16,
                  height: 1.5,
                ),
              ),

              // ✅ TRANSLATION UI
              if (showTranslation) ...[
                if (_isTranslating)
                  const Padding(
                    padding: EdgeInsets.only(top: 10.0),
                    child: SizedBox(
                      height: 15,
                      width: 15,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accent),
                    ),
                  )
                else if (_translatedText != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10.0),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: surfaceColor, // ✅ Dynamic
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: subTextColor.withOpacity(0.1))), // ✅ Dynamic
                    child: Text(
                      _translatedText!,
                      style: TextStyle(
                        color: textColor, // ✅ Dynamic
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                  ),

                // Button
                GestureDetector(
                  onTap: _handleTranslate,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10.0, bottom: 5.0),
                    child: Text(
                      _translatedText == null
                          ? l10n.see_translation
                          : l10n.see_original,
                      style: TextStyle(
                        color: subTextColor, // ✅ Dynamic
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
          decoration: BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: borderColor, width: 1), // ✅ Dynamic
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _actionButton(
                icon: _post.isLiked ? Icons.favorite : Icons.favorite_border,
                color: _post.isLiked
                    ? AppColors.like
                    : subTextColor, // ✅ Dynamic
                text: "${_post.likesCount}",
                onTap: _toggleLike,
              ),
              const SizedBox(width: 24),
              _actionButton(
                icon: Icons.chat_bubble_outline,
                color: subTextColor, // ✅ Dynamic
                text: "${_comments.length}",
                onTap: () {
                  _commentFocusNode.requestFocus();
                },
              ),
              const SizedBox(width: 24),
              _actionButton(
                icon: Icons.share_outlined,
                color: subTextColor, // ✅ Dynamic
                text: l10n.shareAction,
                onTap: () => _sharePost(l10n),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, bool isDark) {
    // Colors
    final mainTextColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 48,
            color: subTextColor.withOpacity(0.5), // ✅ Dynamic
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noCommentsYet,
            style: TextStyle(
              color: mainTextColor, // ✅ Dynamic
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.beFirstToComment,
            style: TextStyle(color: subTextColor, fontSize: 14), // ✅ Dynamic
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () {
              _commentFocusNode.requestFocus();
            },
            icon: const Icon(Icons.edit, size: 18),
            label: Text(l10n.writeCommentButton),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(AppLocalizations l10n, bool isDark) {
    // Dynamic Colors
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final borderColor = isDark ? AppColors.border : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final hintColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor, // ✅ Dynamic
        border: Border(top: BorderSide(color: borderColor)), // ✅ Dynamic
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
                  decoration: InputDecoration(
                    hintText: l10n.addCommentHint,
                    hintStyle: TextStyle(color: hintColor), // ✅ Dynamic
                  ),
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor, // ✅ Dynamic
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_upward,
                  size: 20,
                  color: Colors.white,
                ),
                onPressed: _submitComment,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required Color color,
    required String text,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}