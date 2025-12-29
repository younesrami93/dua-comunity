import 'package:dua_app/l10n/app_localizations.dart';
import 'package:dua_app/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// ✅ Import generated localizations
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
  int? _currentUserId; // ✅ Store current user ID

  String? _translatedText;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _post = widget.post;
    _fetchCurrentUserId(); // ✅ Fetch ID
  }

  Future<void> _handleTranslate() async {
    if (_translatedText != null) {
      setState(() => _translatedText = null); // Toggle off
      return;
    }

    setState(() => _isTranslating = true);

    // Get current locale
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

  @override
  void didUpdateWidget(covariant PostItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    _post = widget.post; // Sync if parent updates
  }

  // ✅ Fetch Current User to check ownership
  Future<void> _fetchCurrentUserId() async {
    try {
      final user = await ApiService().getUserProfile();
      if (mounted) {
        setState(() {
          _currentUserId = user.id;
        });
      }
    } catch (e) {
      // Fail silently or log
      print("Error fetching user ID: $e");
    }
  }

  // ✅ Share Function (Localized)
  void _sharePost() {
    // Access localization using the current context
    final l10n = AppLocalizations.of(context)!;
    final String text =
        "${_post.content}\n\n${l10n.sharePostText}"; // "Shared via Dua Community"
    Share.share(text);
  }

  void _openProfile(BuildContext context) {
    // If it's the post author and they are anonymous (and not me), do nothing
    if (_post.authorId == 0) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileScreen(userId: _post.authorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Access Localization
    final l10n = AppLocalizations.of(context)!;

    // ✅ THEME AWARENESS
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Dynamic Colors
    final Color textColor = isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
    final Color subTextColor = isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
    final Color surfaceColor = isDark ? AppColors.surface : AppColors.surfaceLight;
    final Color backgroundColor = theme.scaffoldBackgroundColor;

    final String currentLang = Localizations.localeOf(context).languageCode;
    bool showTranslation = widget.post.language != null && widget.post.language != currentLang;

    final bool isMine = widget.post.authorId == ApiService().currentUser?.id;
    if (isMine) showTranslation = false;

    // Check if the post is anonymous
    final bool isAnonymous = _post.is_anonymous;

    // ✅ Display Logic:
    final bool showRealIdentity = !isAnonymous || isMine;

    // Localized "Anonymous" fallback
    final String displayName = showRealIdentity
        ? _post.authorName
        : l10n.anonymousUser;

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
        color: backgroundColor, // ✅ Dynamic Background
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- COLUMN 1: Avatar ---
            GestureDetector(
              // ✅ Tap logic: Enabled if showing real identity
              onTap: showRealIdentity ? () => _openProfile(context) : null,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: showRealIdentity
                    ? surfaceColor // ✅ Dynamic Surface
                    : Colors.grey,
                child: showRealIdentity
                    ? Text(
                  displayName.isNotEmpty
                      ? displayName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : const Icon(Icons.person, color: Colors.white, size: 20),
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
                      Expanded(
                        child: Row(
                          children: [
                            // ✅ Name
                            Flexible(
                              child: GestureDetector(
                                onTap: showRealIdentity
                                    ? () => _openProfile(context)
                                    : null,
                                child: Text(
                                  displayName,
                                  style: TextStyle(
                                    color: textColor, // ✅ Dynamic Text
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),

                            // ✅ Anonymous Ticker (Only if it's mine and anonymous)
                            if (isMine && isAnonymous)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: subTextColor.withOpacity(0.2), // ✅ Dynamic
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  l10n.anonymousUser, // ✅ Localized Badge
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: subTextColor, // ✅ Dynamic
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      Text(
                        // ✅ Updated DateFormatter to use context
                        DateFormatter.timeAgo(context, _post.createdAt),
                        style: TextStyle(
                          color: subTextColor, // ✅ Dynamic
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),

                  // 2. Category
                  Text(
                    _post.categoryName,
                    style: TextStyle(
                      color: subTextColor, // ✅ Dynamic
                      fontSize: 13,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // 3. Content
                  Text(
                    _translatedText == null ? _post.content : _translatedText!,
                    style: TextStyle(
                      color: textColor, // ✅ Dynamic
                      fontSize: 15,
                      height: 1.4,
                    ),
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (showTranslation)
                    if (_isTranslating)
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: SizedBox(
                          height: 15,
                          width: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accent,
                          ),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _handleTranslate,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                            : subTextColor, // ✅ Dynamic
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
                        color: subTextColor, // ✅ Dynamic
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
                        color: subTextColor, // ✅ Dynamic
                        label: '',
                        onTap: _sharePost, // ✅ Share button works
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
}