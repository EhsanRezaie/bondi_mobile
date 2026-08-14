import 'dart:async';

import 'package:flutter/material.dart';

import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/screens/chats/user_notification_profile_screen.dart';
import 'package:dating_app/utils/global_navigator.dart';

class NotificationToastService {
  static OverlayEntry? _currentNoticeEntry;
  static final Map<String, DateTime> _shownToasts = {};
  static const _dedupeWindow = Duration(seconds: 5);

  static void show({
    BuildContext? context,
    required String id,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final now = DateTime.now();
    if (_shownToasts.containsKey(id)) {
      final lastShown = _shownToasts[id]!;
      if (now.difference(lastShown) < _dedupeWindow) {
        debugPrint('Deduped toast: $id');
        return;
      }
    }
    _shownToasts[id] = now;

    _cleanupOldToasts();

    final ctx = context ?? appNavigatorKey.currentContext;
    if (ctx == null) {
      debugPrint('Toast: no navigator context available');
      return;
    }

    _showToastOverlay(
      context: ctx,
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
    );
  }

  static void _cleanupOldToasts() {
    final now = DateTime.now();
    _shownToasts.removeWhere((_, time) => now.difference(time) > _dedupeWindow);
  }

  static void _showToastOverlay({
    required BuildContext context,
    required String id,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    _currentNoticeEntry?.remove();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = AppLocalizations.of(context)!;

    final gradient = _gradientForType(type, isDark);
    final iconData = _iconForType(type);

    final entry = OverlayEntry(
      builder: (context) => _NotificationToastOverlay(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        gradient: gradient,
        iconData: iconData,
        isDark: isDark,
        t: t,
        onDismiss: () {
          _currentNoticeEntry = null;
        },
      ),
    );

    _currentNoticeEntry = entry;
    Overlay.of(context).insert(entry);
  }

  static LinearGradient _gradientForType(String type, bool isDark) {
    switch (type) {
      case 'like':
      case 'liked':
        return AppTheme.likeGradient(isDark: isDark);
      case 'match':
        return AppTheme.primaryGradient();
      case 'system':
        return AppTheme.primaryGradient();
      default:
        return AppTheme.primaryGradient();
    }
  }

  static IconData _iconForType(String type) {
    switch (type) {
      case 'like':
      case 'liked':
        return Icons.favorite_rounded;
      case 'match':
        return Icons.favorite_rounded;
      case 'system':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  static void dismiss() {
    _currentNoticeEntry?.remove();
    _currentNoticeEntry = null;
  }
}

class _NotificationToastOverlay extends StatefulWidget {
  final String id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final LinearGradient gradient;
  final IconData iconData;
  final bool isDark;
  final AppLocalizations t;
  final VoidCallback onDismiss;

  const _NotificationToastOverlay({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.gradient,
    required this.iconData,
    required this.isDark,
    required this.t,
    required this.onDismiss,
  });

  @override
  State<_NotificationToastOverlay> createState() =>
      _NotificationToastOverlayState();
}

class _NotificationToastOverlayState extends State<_NotificationToastOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();

    _autoDismissTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) _dismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _autoDismissTimer?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (!mounted) return;
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  void _onSeeDetails() {
    _dismiss();
    final context = this.context;

    if (!context.mounted) return;

    switch (widget.type) {
      case 'like':
      case 'liked':
      case 'match':
        final userId = widget.data['user_id'] as String?;
        if (userId != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserNotificationProfileScreen(
                userId: userId,
                fallback: SwipeStubProfile(
                  id: userId,
                  name: widget.title,
                  age: 0,
                ),
              ),
            ),
          );
        }
        break;
      case 'system':
        _showAnnouncementDialog(context);
        break;
      case 'message':
        final chatId = widget.data['chat_id'] as String?;
        if (chatId != null) {
          // Navigate to chat detail - handled by chat provider
        }
        break;
    }
  }

  void _showAnnouncementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusModule),
        ),
        title: Text(
          widget.title,
          style: AppTheme.h2.copyWith(
            fontFamily: AppTheme.fontFor(context.isDarkMode),
          ),
        ),
        content: Text(
          widget.body,
          style: AppTheme.body.copyWith(
            fontFamily: AppTheme.fontFor(context.isDarkMode),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              widget.t.notifications_close,
              style: AppTheme.bodyBold.copyWith(
                color: context.isDarkMode
                    ? AppTheme.darkPrimary
                    : AppTheme.lightPrimary,
                fontFamily: AppTheme.fontFor(context.isDarkMode),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Positioned(
      top: MediaQuery.of(context).padding.top + 8,
      left: 16,
      right: 16,
      child: SafeArea(
        bottom: false,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _dismiss,
                borderRadius:
                    BorderRadius.circular(AppTheme.radiusModule),
                child: Container(
                  padding:
                      const EdgeInsets.fromLTRB(16, 12, 12, 12),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusModule),
                    border:
                        Border.all(color: borderColor, width: 1),
                    boxShadow: [
                      AppTheme.shadowModule(isDark: isDark),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading icon in gradient circle
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          gradient: widget.gradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.iconData,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.title,
                              style: AppTheme.bodyBold.copyWith(
                                color: textColor,
                                fontFamily:
                                    AppTheme.fontFor(isDark),
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (widget.body.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                widget.body,
                                style: AppTheme.caption.copyWith(
                                  color: mutedColor,
                                  fontFamily:
                                      AppTheme.fontFor(isDark),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      // See details button
                      TextButton(
                        onPressed: _onSeeDetails,
                        style: TextButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          widget.t.notifications_see_details,
                          style: AppTheme.bodyBold.copyWith(
                            color: primaryColor,
                            fontFamily: AppTheme.fontFor(isDark),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}