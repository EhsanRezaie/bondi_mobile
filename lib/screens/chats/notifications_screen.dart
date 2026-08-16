import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/relative_time.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/screens/chats/user_notification_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<NotificationsProvider>(
        builder: (context, provider, _) {
          final matchItems = provider.notifications
              .where((n) => n.type == 'match')
              .toList();
          return AppLayout.box(
            context: context,
            child: Column(
              children: [
                if (matchItems.isNotEmpty) _buildMatchStrip(matchItems),
                _buildSegmentedTabs(t, isDark, primaryColor),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTab(
                        provider,
                        types: const ['like'],
                        sectionType: 'like',
                        emptyText: t.notifications_empty_section,
                      ),
                      _buildTab(
                        provider,
                        types: const ['liked'],
                        sectionType: 'liked',
                        emptyText: t.notifications_empty_section,
                      ),
                      _buildTab(
                        provider,
                        types: const ['system'],
                        sectionType: 'system',
                        emptyText: t.notifications_empty_section,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMatchStrip(List<AppNotification> matches) {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final avatarOuterDiameter = AppLayout.s(context, 64);
    final itemWidth = avatarOuterDiameter + AppLayout.s(context, 12);
    final nameLineHeight = AppLayout.s(context, 20);
    final verticalPad = AppLayout.s(context, 6);
    final stripHeight =
        avatarOuterDiameter + AppLayout.s(context, 4) + nameLineHeight + verticalPad * 2;

    return SizedBox(
      height: stripHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: AppLayout.s(context, 12),
          vertical: verticalPad,
        ),
        itemCount: matches.length,
        itemBuilder: (context, index) {
          final item = matches[index];
          return GestureDetector(
            onTap: () => _handleTap(item),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppLayout.s(context, 6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withValues(alpha: 0.5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaceColor,
                      ),
                      child: CircleAvatar(
                        radius: (avatarOuterDiameter - 8) / 2,
                        backgroundColor: borderColor,
                        backgroundImage: item.avatarUrl != null &&
                                item.avatarUrl!.isNotEmpty
                            ? CachedImage.provider(
                                item.avatarUrl!,
                                diameter: avatarOuterDiameter - 8,
                              )
                            : null,
                        child: item.avatarUrl == null ||
                                item.avatarUrl!.isEmpty
                            ? Icon(
                                Icons.person,
                                size: AppLayout.s(context, 28),
                                color: borderColor,
                              )
                            : null,
                      ),
                    ),
                  ),
                  SizedBox(height: AppLayout.s(context, 4)),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: itemWidth),
                    child: Text(
                      item.userName ?? _fallbackName(item),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(
                          !Localizations.localeOf(
                            context,
                          ).languageCode.contains('en'),
                        ),
                        fontSize: AppLayout.s(context, 11),
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppTheme.darkText
                            : AppTheme.lightText,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTab(
    NotificationsProvider provider, {
    required List<String> types,
    required String sectionType,
    required String emptyText,
  }) {
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;

    if (provider.isLoading && provider.notifications.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    final items = provider.notifications
        .where((n) => types.contains(n.type))
        .toList();

    if (items.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            context.read<NotificationsProvider>().loadNotifications(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: AppLayout.s(context, 64),
                      color: borderColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(
                          !Localizations.localeOf(
                            context,
                          ).languageCode.contains('en'),
                        ),
                        fontSize: AppLayout.s(context, 16),
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length + (provider.hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
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
            return _buildItem(items[index], sectionType);
          },
        ),
      ),
    );
  }

  Widget _buildSegmentedTabs(
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
  ) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final labels = [
      t.notifications_section_liked,
      t.notifications_section_likes,
      t.notifications_section_system,
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppLayout.s(context, 16),
        AppLayout.s(context, 4),
        AppLayout.s(context, 16),
        AppLayout.s(context, 12),
      ),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSecondary : AppTheme.lightSecondary,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: AnimatedBuilder(
          animation: _tabController,
          builder: (context, _) {
            return Row(
              children: List.generate(labels.length, (i) {
                final selected = _tabController.index == i;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        vertical: AppLayout.s(context, 10),
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusChip - 4,
                        ),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          labels[i],
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          style: (isPersian
                                  ? AppTheme.bodyBoldFa
                                  : AppTheme.bodyBold)
                              .copyWith(
                            fontSize: AppLayout.s(context, 14),
                            color: selected ? Colors.white : mutedColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  Widget _buildItem(AppNotification item, String sectionType) {
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final t = AppLocalizations.of(context)!;
    final hasAvatar =
        item.avatarUrl != null && item.avatarUrl!.isNotEmpty;

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
                  backgroundImage: hasAvatar
                      ? CachedImage.provider(
                          item.avatarUrl!,
                          diameter: AppLayout.s(context, 44),
                        )
                      : null,
                  child: hasAvatar
                      ? null
                      : Icon(
                          _iconFor(item.type),
                          size: AppLayout.s(context, 22),
                          color: _iconColorFor(item.type, isDark),
                        ),
                ),
              ],
            ),
            title: Text(
              _messageFor(item, t),
              style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                  .copyWith(
                fontSize: AppLayout.s(context, 15),
                fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                color: textColor,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: mutedColor),
            onTap: () => _handleTap(item),
          ),
        ),
      ),
    );
  }

  String _messageFor(AppNotification item, AppLocalizations t) {
    final name = item.userName ?? _fallbackName(item);
    final time = relativeTime(item.createdAt, t);
    switch (item.type) {
      case 'like':
        return '$name liked you · $time';
      case 'liked':
        return 'You liked $name · $time';
      case 'match':
        return 'You matched with $name · $time';
      case 'system':
        return '${item.title} · $time';
      default:
        return '${item.title} · $time';
    }
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
            mainPhotoUrl: item.avatarUrl,
          ),
        ),
      ),
    );
  }

  String _fallbackName(AppNotification item) {
    final name = item.userName;
    if (name != null && name.isNotEmpty) return name;
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
