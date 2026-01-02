import 'package:dua_app/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../models/Comment.dart';
import '../utils/date_utils.dart';
import '../theme/app_colors.dart';
import '../screens/profile_screen.dart';
import '../api/api_service.dart'; // Import API Service

class CommentItem extends StatefulWidget {
  final Comment comment;
  final VoidCallback? onDeleted;
  const CommentItem({super.key, required this.comment, this.onDeleted});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  String? _translatedText;
  bool _isTranslating = false;
  bool _isDeleting = false;

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: widget.comment.authorId),
      ),
    );
  }

  // ✅ Added Delete Handler
  Future<void> _handleDelete() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Comment"),
        content: const Text("Are you sure you want to delete this comment?"),
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

    final success = await ApiService().deleteComment(widget.comment.id);

    if (mounted) {
      setState(() => _isDeleting = false);
      if (success) {
        if (widget.onDeleted != null) widget.onDeleted!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to delete comment")),
        );
      }
    }
  }

  Future<void> _handleTranslate() async {
    if (_translatedText != null) {
      setState(() {
        _translatedText = null;
      });
      return;
    }

    setState(() => _isTranslating = true);

    final String currentLang = Localizations.localeOf(context).languageCode;

    final result = await ApiService().translateContent(
      id: widget.comment.id,
      type: 'comment',
      targetLang: currentLang,
    );

    if (mounted) {
      setState(() {
        _translatedText = result;
        _isTranslating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    ApiService().getStoredUser();
    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final contentColor = isDark ? Colors.grey.shade300 : Colors.black87;

    final String currentLang = Localizations.localeOf(context).languageCode;
    bool showTranslation =
        widget.comment.language != null &&
            widget.comment.language != currentLang;
    ApiService().getStoredUser();
    final bool isMine = widget.comment.authorId == ApiService().currentUser?.id;
    if (isMine) showTranslation = false;

    // ✅ Check Banned Status
    final bool isBanned = widget.comment.status == 'banned';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          GestureDetector(
            onTap: () => _openProfile(context),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: surfaceColor, // ✅ Dynamic
              backgroundImage: widget.comment.authorAvatar != null
                  ? NetworkImage(widget.comment.authorAvatar!)
                  : null,
              child: widget.comment.authorAvatar == null
                  ? Text(
                widget.comment.authorName.isNotEmpty
                    ? widget.comment.authorName[0].toUpperCase()
                    : "?",
                style: TextStyle(
                  fontSize: 12,
                  color: subTextColor, // ✅ Dynamic
                ),
              )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Name + Time + Delete Icon)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Text(
                        widget.comment.authorName,
                        style: TextStyle(
                          color: textColor, // ✅ Dynamic
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Text(
                          DateFormatter.timeAgo(context, widget.comment.createdAt),
                          style: TextStyle(
                            color: subTextColor, // ✅ Dynamic
                            fontSize: 11,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 10),
                          if (_isDeleting)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.red),
                            )
                          else
                            GestureDetector(
                              onTap: _handleDelete,
                              child: const Icon(
                                Icons.delete_outline,
                                size: 16,
                                color: Colors.redAccent,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // ✅ BANNED LOGIC
                if (isBanned)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.block, color: Colors.red, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          // Shows "Banned: HARASSMENT" or just "Banned"
                          "Banned: ${widget.comment.safetyLabel?.toUpperCase() ?? 'VIOLATION'}",
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  // ✅ Show Content ONLY if not banned
                  Text(
                    _translatedText ?? (widget.comment.content+"-"+widget.comment.authorId.toString()+"-"+ApiService().currentUser!.id.toString()+"-"+isMine.toString()),
                    style: TextStyle(color: contentColor, fontSize: 14),
                  ),

                  // TRANSLATION UI (Only if not banned)
                  if (showTranslation)
                    if (_isTranslating)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 12,
                          width: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _handleTranslate,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _translatedText == null
                                ? l10n.see_translation
                                : l10n.see_original,
                            style: TextStyle(
                              color: subTextColor.withOpacity(0.7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}