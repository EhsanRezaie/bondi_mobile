import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t.notifications_title,
          style: (isPersian ? AppTheme.h2Fa : AppTheme.h2).copyWith(
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.notifications.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (provider.notifications.isEmpty) {
            return RefreshIndicator(
              onRefresh: () =>
                  context.read<NotificationsProvider>().loadNotifications(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: 1,
                itemBuilder: (context, index) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 64,
                          color: borderColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          t.notifications_empty,
                          style: TextStyle(
                            fontFamily: AppTheme.fontFor(
                              !Localizations.localeOf(
                                context,
                              ).languageCode.contains('en'),
                            ),
                            fontSize: 16,
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                context.read<NotificationsProvider>().loadNotifications(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
                  context.read<NotificationsProvider>().loadMoreNotifications();
                }
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount:
                    provider.notifications.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == provider.notifications.length) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                    );
                  }
                  final item = provider.notifications[index];
                  return _buildItem(context, item);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildItem(BuildContext context, AppNotification item) {
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    final time = DateFormat('HH:mm').format(item.createdAt.toLocal());

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: isDark ? AppTheme.darkError : AppTheme.lightError,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) {
        context.read<NotificationsProvider>().deleteNotification(item.id);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Material(
          color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          borderRadius: BorderRadius.circular(AppTheme.radiusModule),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: AppLayout.s(context, 22),
                  backgroundColor: borderColor,
                  child: Icon(
                    _iconFor(item.type),
                    size: AppLayout.s(context, 22),
                    color: _iconColorFor(item.type, isDark),
                  ),
                ),
                if (!item.isRead)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: AppLayout.s(context, 12),
                      height: AppLayout.s(context, 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSuccess
                            : AppTheme.lightSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkSurface
                              : AppTheme.lightSurface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              item.title,
              style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                  .copyWith(
                fontSize: 15,
                fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                color: textColor,
              ),
            ),
            subtitle: item.body != null && item.body!.isNotEmpty
                ? Text(
                    item.body!,
                    style:
                        (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
                      fontSize: 13,
                      color: mutedColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Text(
              time,
              style:
                  (isPersian ? AppTheme.captionFa : AppTheme.caption).copyWith(
                fontSize: 11,
                color: mutedColor,
              ),
            ),
            onTap: () =>
                context.read<NotificationsProvider>().markRead([item.id]),
          ),
        ),
      ),
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'message':
        return Icons.chat_bubble_outline;
      case 'match':
        return Icons.favorite_border;
      case 'system':
        return Icons.notifications_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColorFor(String type, bool isDark) {
    final primary = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    return primary;
  }
}
