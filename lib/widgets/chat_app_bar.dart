import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/widgets/online_indicator.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? avatarUrl;
  final bool isOnline;
  final String? lastSeenAt;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onAvatarTap;

  const ChatAppBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.onBackPressed,
    this.onMenuPressed,
    this.onAvatarTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: textColor,
          size: 22,
        ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onAvatarTap,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isOnline
                    ? AppTheme.primaryGradient()
                    : null,
                border: isOnline
                    ? null
                    : Border.all(color: borderColor, width: 1.5),
              ),
              child: CircleAvatar(
                radius: AppLayout.s(context, 15),
                backgroundColor: borderColor,
                backgroundImage:
                    avatarUrl != null && avatarUrl!.isNotEmpty
                        ? CachedImage.provider(
                            avatarUrl!,
                            diameter: AppLayout.s(context, 30),
                          )
                        : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Icon(Icons.person,
                        size: AppLayout.s(context, 16), color: borderColor)
                    : null,
              ),
            ),
            SizedBox(width: AppLayout.s(context, 10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(
                        !Localizations.localeOf(
                          context,
                        ).languageCode.contains('en'),
                      ),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  OnlineIndicator(
                    isOnline: isOnline,
                    lastSeenAt: lastSeenAt,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onMenuPressed != null)
          IconButton(
            onPressed: onMenuPressed,
            icon: Icon(Icons.more_horiz, color: textColor, size: 22),
          ),
      ],
    );
  }
}