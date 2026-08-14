import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  final List<ChatCard> chats;
  final bool isLoading;
  final bool hasMore;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final void Function(ChatCard chat) onChatTap;
  final void Function(ChatCard chat)? onChatLongPress;

  const ChatListScreen({
    super.key,
    required this.chats,
    required this.isLoading,
    required this.hasMore,
    required this.emptyText,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onChatTap,
    this.onChatLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    if (isLoading && chats.isEmpty) {
      return Center(child: CircularProgressIndicator(color: primaryColor));
    }

    if (chats.isEmpty) {
      final isPersian = !Localizations.localeOf(
        context,
      ).languageCode.contains('en');
      return RefreshIndicator(
        onRefresh: onRefresh,
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
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: borderColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    emptyText,
                    textAlign: TextAlign.center,
                    style:
                        (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
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
      onRefresh: onRefresh,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
              notification.metrics.maxScrollExtent - 200) {
            onLoadMore();
          }
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            12,
            12,
            12,
            AppLayout.floatingNavClearance,
          ),
          itemCount: chats.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == chats.length) {
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
            return _buildChatItem(context, chats[index]);
          },
        ),
      ),
    );
  }

  Widget _buildChatItem(BuildContext context, ChatCard chat) {
    final isDark = context.isDarkMode;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final hasUnread = chat.unreadCount > 0;

    final lastMsg = chat.lastMessage;
    String subtitle = '';
    if (lastMsg != null) {
      final time = DateFormat('HH:mm').format(lastMsg.sentAt);
      final prefix = lastMsg.isSent ? 'You: ' : '';
      final content = lastMsg.content ?? '';
      subtitle = '$prefix$content · $time';
    }

return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusModule),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusModule),
          onTap: () => onChatTap(chat),
          onLongPress: onChatLongPress == null
              ? null
              : () => onChatLongPress!(chat),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: AppLayout.s(context, 28),
                  backgroundColor: borderColor,
                   backgroundImage:
                       chat.user.mainPhotoUrl != null &&
                           chat.user.mainPhotoUrl!.isNotEmpty
                       ? CachedImage.provider(
                           chat.user.mainPhotoUrl!,
                           diameter: AppLayout.s(context, 56),
                         )
                       : null,
                  child:
                      chat.user.mainPhotoUrl == null ||
                          chat.user.mainPhotoUrl!.isEmpty
                      ? Icon(
                          Icons.person,
                          size: AppLayout.s(context, 28),
                          color: borderColor,
                        )
                      : null,
                ),
                if (chat.user.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: AppLayout.s(context, 14),
                      height: AppLayout.s(context, 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSuccess
                            : AppTheme.lightSuccess,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? AppTheme.darkBackground
                              : AppTheme.lightBackground,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            title: Text(
              chat.user.name,
              style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                  .copyWith(
                fontSize: 16,
                fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                color: textColor,
              ),
            ),
            subtitle: subtitle.isNotEmpty
                ? Text(
                    subtitle,
                    style:
                        (isPersian ? AppTheme.captionFa : AppTheme.caption)
                            .copyWith(
                      fontSize: 13,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      color: hasUnread ? textColor : mutedColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasUnread)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient(),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      chat.unreadCount > 9 ? '9+' : '${chat.unreadCount}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(isPersian),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                Icon(Icons.chevron_right, color: mutedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
