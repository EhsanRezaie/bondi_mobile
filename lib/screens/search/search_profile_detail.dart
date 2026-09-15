import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/screens/shared/profile_detail_view.dart';
import 'package:dating_app/widgets/action_toast.dart';
import 'package:dating_app/widgets/discover_action_button.dart';

/// Search / notifications detail. Uses the shared [ProfileDetailView] so the
/// layout matches discover exactly; only the bottom bar differs (chat + like,
/// or nothing when [viewOnly]).
class SearchProfileDetail extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final int? likesRemaining;
  final int? chatsRemaining;
  final bool isPremium;
  final bool viewOnly;
  final Future<Map<String, dynamic>?> Function(DiscoverProfile)? onLike;
  final Future<Map<String, dynamic>?> Function(
    DiscoverProfile, {
    String? message,
  })?
  onChat;

  const SearchProfileDetail({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.likesRemaining,
    this.chatsRemaining,
    this.isPremium = false,
    this.viewOnly = false,
    this.onLike,
    this.onChat,
  });

  @override
  State<SearchProfileDetail> createState() => _SearchProfileDetailState();
}

class _SearchProfileDetailState extends State<SearchProfileDetail> {
  DiscoverProfile get profile => widget.profile;

  @override
  Widget build(BuildContext context) {
    return ProfileDetailView(
      profile: widget.profile,
      interestIcons: widget.interestIcons,
      showBlockOption: widget.viewOnly,
      bottomBar: widget.viewOnly ? null : _buildBottomActionBar(context),
    );
  }

  Widget _buildBottomActionBar(BuildContext context) {
    final isDark = context.isDarkMode;
    final isLikeBlocked =
        !widget.isPremium && (widget.likesRemaining ?? 0) <= 0;
    final isChatBlocked =
        !widget.isPremium && (widget.chatsRemaining ?? 0) <= 0;
    final alreadyLiked =
        profile.currentUserAction == 'like' ||
        profile.currentUserAction == 'matched';

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoverActionButton(
            icon: Icons.chat_bubble_rounded,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            iconColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            borderColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            size: 64,
            badgeCount: widget.isPremium ? null : widget.chatsRemaining,
            onPressed: isChatBlocked ? null : () => _handleChat(),
          ),
          if (!alreadyLiked) ...[
            const SizedBox(width: 24),
            DiscoverActionButton(
              icon: Icons.favorite_rounded,
              gradient: AppTheme.likeGradient(isDark: isDark),
              size: 64,
              badgeCount: widget.isPremium ? null : widget.likesRemaining,
              onPressed: isLikeBlocked ? null : () => _handleLike(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLike() async {
    final isLikeBlocked =
        !widget.isPremium && (widget.likesRemaining ?? 0) <= 0;
    if (isLikeBlocked) {
      _showLimitReachedDialog('likes');
      return;
    }

    if (widget.onLike == null) return;
    final result = await widget.onLike!(profile);
    if (result != null && mounted) {
      if (result['matched'] == true) {
        _showMatchDialog(result);
      } else {
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.toast_like_sent);
        Navigator.pop(context);
      }
    } else if (mounted) {
      final t = AppLocalizations.of(context)!;
      showActionToast(context, t.error_something_wrong, isError: true);
    }
  }

  Future<void> _handleChat() async {
    final isChatBlocked =
        !widget.isPremium && (widget.chatsRemaining ?? 0) <= 0;
    if (isChatBlocked) {
      _showLimitReachedDialog('chats');
      return;
    }

    final message = await _showChatBottomSheet();
    if (message != null && mounted && widget.onChat != null) {
      final result = await widget.onChat!(profile, message: message);
      if (result != null && mounted) {
        final chatId = (result['chat_id'] ?? result['chatId'] ?? '').toString();
        if (chatId.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatDetailScreen(
                identifier: chatId,
                userName: profile.name,
                avatarUrl: profile.mainPhotoUrl,
                isOnline: profile.isOnline,
                lastSeenAt: profile.lastSeenAt,
              ),
            ),
          );
        } else {
          final t = AppLocalizations.of(context)!;
          showActionToast(context, t.error_something_wrong, isError: true);
        }
      } else if (mounted) {
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.error_something_wrong, isError: true);
      }
    }
  }

  void _showLimitReachedDialog(String type) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Daily limit reached',
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Text(
          type == 'likes'
              ? t.search_limit_reached_likes
              : t.search_limit_reached_chats,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(isPersian),
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showChatBottomSheet() async {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final messageController = TextEditingController();
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.discover_say_something,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(isPersian),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        autofocus: true,
                        maxLines: 3,
                        maxLength: 200,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(isPersian),
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: t.discover_send_message_hint,
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : Colors.grey,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkSecondary
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final msg = messageController.text.trim();
                            Navigator.pop(ctx, msg.isNotEmpty ? msg : null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            t.discover_send_and_like,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFor(isPersian),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  void _showMatchDialog(Map<String, dynamic> result) {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final bool messageSent = result['message_sent'] == true;
    final heroStyle =
        (isPersian ? AppTheme.heroDisplayFa : AppTheme.heroDisplay).copyWith(
          fontSize: 30,
          color: Colors.white,
        );
    final bodyStyle = (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 15,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: AppTheme.primaryGradient(),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGradientStart.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  if (profile.mainPhotoUrl != null &&
                      profile.mainPhotoUrl!.isNotEmpty)
                    Positioned(
                      top: -40,
                      child: ClipOval(
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Image.network(
                            profile.mainPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 56),
              Text(
                t.search_match_title,
                textAlign: TextAlign.center,
                style: heroStyle,
              ),
              const SizedBox(height: 8),
              Text(
                t.search_match_subtitle(profile.name),
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              if (messageSent) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.search_match_message_sent,
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: AppTheme.primaryButton.copyWith(
                    backgroundColor: const WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    foregroundColor: const WidgetStatePropertyAll<Color>(
                      AppTheme.primaryGradientStart,
                    ),
                    elevation: const WidgetStatePropertyAll<double>(0),
                  ),
                  child: Text(
                    t.search_continue_browsing,
                    style: (isPersian ? AppTheme.buttonFa : AppTheme.button)
                        .copyWith(color: AppTheme.primaryGradientStart),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
