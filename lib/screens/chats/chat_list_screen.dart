import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/chat_card.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatelessWidget {
  final List<ChatCard> chats;
  final bool isLoading;
  final bool hasMore;
  final String emptyText;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;
  final void Function(ChatCard chat) onChatTap;

  const ChatListScreen({
    super.key,
    required this.chats,
    required this.isLoading,
    required this.hasMore,
    required this.emptyText,
    required this.onRefresh,
    required this.onLoadMore,
    required this.onChatTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    if (isLoading && chats.isEmpty) {
      return Center(
        child: CircularProgressIndicator(color: primaryColor),
      );
    }

    if (chats.isEmpty) {
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline,
                        size: 64, color: borderColor),
                    const SizedBox(height: 16),
                    Text(
                      emptyText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
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
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final lastMsg = chat.lastMessage;
    String subtitle = '';
    if (lastMsg != null) {
      final time = DateFormat('HH:mm').format(lastMsg.sentAt);
      final prefix = lastMsg.isSent ? 'You: ' : '';
      final content = lastMsg.content ?? '';
      subtitle = '$prefix$content · $time';
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: borderColor,
            backgroundImage: chat.user.mainPhotoUrl != null &&
                    chat.user.mainPhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(chat.user.mainPhotoUrl!)
                : null,
            child: chat.user.mainPhotoUrl == null ||
                    chat.user.mainPhotoUrl!.isEmpty
                ? Icon(Icons.person, size: 28, color: borderColor)
                : null,
          ),
          if (chat.user.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: AppTheme.lightSuccess,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        chat.user.name,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: mutedColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (chat.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 22),
              child: Text(
                chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          Icon(
            Icons.chevron_right,
            color: mutedColor,
          ),
        ],
      ),
      onTap: () => onChatTap(chat),
    );
  }
}
