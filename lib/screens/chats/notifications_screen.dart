import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/screens/chats/user_notification_profile_screen.dart';

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

          final sections = [
            _NotificationSection(
              title: t.notifications_section_liked,
              items: provider.notifications.where((n) => n.type == 'like').toList(),
            ),
            _NotificationSection(
              title: t.notifications_section_likes,
              items: provider.notifications.where((n) => n.type == 'liked').toList(),
            ),
            _NotificationSection(
              title: t.notifications_section_matches,
              items: provider.notifications.where((n) => n.type == 'match').toList(),
            ),
            _NotificationSection(
              title: t.notifications_section_announcements,
              items: provider.notifications
                  .where((n) => n.type == 'system')
                  .toList(),
            ),
          ];

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
                itemCount: sections.length + (provider.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == sections.length) {
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
                  final section = sections[index];
                  return _buildSection(context, section);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, _NotificationSection section) {
    final isDark = context.isDarkMode;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final t = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            16,
            12,
            16,
            4,
          ),
          child: Text(
            section.title.toUpperCase(),
            style: (isPersian ? AppTheme.overlineFa : AppTheme.overline)
                .copyWith(color: mutedColor),
          ),
        ),
        if (section.items.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              t.notifications_empty_section,
              style: (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
                fontSize: 13,
                color: mutedColor,
              ),
            ),
          )
        else
          for (final item in section.items) _buildItem(item),
      ],
    );
  }

  Widget _buildItem(AppNotification item) {
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

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
            trailing: Icon(Icons.chevron_right, color: mutedColor),
            onTap: () => _handleTap(item),
          ),
        ),
      ),
    );
  }

  void _handleTap(AppNotification item) {
    context.read<NotificationsProvider>().markRead([item.id]);

    if (item.type == 'system') {
      _showAnnouncement(item);
      return;
    }

    final userId = item.data?['user_id'];
    if (userId is! String || userId.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserNotificationProfileScreen(
          userId: userId,
          fallback: SwipeStubProfile(
            id: userId,
            name: _fallbackName(item),
            age: 0,
            mainPhotoUrl: null,
          ),
        ),
      ),
    );
  }

  String _fallbackName(AppNotification item) {
    final body = item.body ?? '';
    var m = RegExp(r'^(.+?)\s*\(age \d+\)').firstMatch(body);
    if (m != null && m.group(1)!.trim().isNotEmpty) {
      return m.group(1)!.trim();
    }
    m = RegExp(r"You liked (.+?)'s profile").firstMatch(body);
    if (m != null) return m.group(1)!.trim();
    m = RegExp(r'You matched with (.+?)[!.]').firstMatch(body);
    if (m != null) return m.group(1)!.trim();
    m = RegExp(r'liked public profile of (.+)').firstMatch(body);
    if (m != null) return m.group(1)!.trim();
    return item.title;
  }

  void _showAnnouncement(AppNotification item) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final t = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusModule),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: SingleChildScrollView(
                    child: Text(
                      item.body ?? '',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: mutedColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(t.notifications_close),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite;
      case 'liked':
        return Icons.favorite_border;
      case 'match':
        return Icons.favorite;
      case 'system':
        return Icons.campaign_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _iconColorFor(String type, bool isDark) {
    return isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
  }
}

class _NotificationSection {
  final String title;
  final List<AppNotification> items;

  const _NotificationSection({required this.title, required this.items});
}