import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/notifications_provider.dart';

class NotificationBell extends StatelessWidget {
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;

  const NotificationBell({
    super.key,
    this.onPressed,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectivePadding = padding ?? const EdgeInsets.all(8.0);

    return Consumer<NotificationsProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;

        if (count == 0) {
          return IconButton(
            padding: effectivePadding,
            onPressed: onPressed,
            icon: Icon(
              Icons.notifications_none_rounded,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
              size: 26,
            ),
          );
        }

        final displayCount = count > 99 ? '99+' : count.toString();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              padding: effectivePadding,
              onPressed: onPressed,
              icon: Icon(
                Icons.notifications_rounded,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
                size: 26,
              ),
            ),
            Positioned(
              right: effectivePadding.resolve(Directionality.of(context)).right + 2,
              top: effectivePadding.resolve(Directionality.of(context)).top + 2,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                height: 16,
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.accentLike : AppTheme.accentLike,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  displayCount,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    fontFamily: AppTheme.fontFor(isDark),
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}