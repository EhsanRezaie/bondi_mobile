import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/widgets/online_indicator.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String userName;
  final String? avatarUrl;
  final bool isOnline;
  final String? lastSeenAt;
  final VoidCallback? onBackPressed;
  final VoidCallback? onMenuPressed;

  const ChatAppBar({
    super.key,
    required this.userName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.onBackPressed,
    this.onMenuPressed,
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
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: textColor,
        ),
        onPressed: onBackPressed ?? () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: borderColor,
                backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(avatarUrl!)
                    : null,
                child: avatarUrl == null || avatarUrl!.isEmpty
                    ? Icon(Icons.person, size: 18, color: borderColor)
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppTheme.darkSuccess
                          : AppTheme.lightSuccess,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: bgColor,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: TextStyle(
                    fontFamily: 'Inter',
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
      actions: [
        if (onMenuPressed != null)
          IconButton(
            onPressed: onMenuPressed,
            icon: Icon(Icons.more_vert, color: textColor),
          ),
      ],
    );
  }
}
