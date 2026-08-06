import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:intl/intl.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ChatProvider>().loadMoreConversations();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor =
        isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.conversations.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: primaryColor,
            ),
          );
        }

        if (provider.conversations.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => context.read<ChatProvider>().loadConversations(),
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
                          t.chat_empty_chats,
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
          onRefresh: () => context.read<ChatProvider>().loadConversations(),
          child: ListView.builder(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: provider.conversations.length +
                (provider.hasMoreConversations ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == provider.conversations.length) {
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
              return _buildChatItem(
                provider.conversations[index],
                isDark,
                textColor,
                mutedColor,
                borderColor,
                primaryColor,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildChatItem(
    Match match,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
    Color primaryColor,
  ) {
    final lastMsg = match.lastMessage;
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
            backgroundImage: match.user.mainPhotoUrl != null &&
                    match.user.mainPhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(match.user.mainPhotoUrl!)
                : null,
            child: match.user.mainPhotoUrl == null ||
                    match.user.mainPhotoUrl!.isEmpty
                ? Icon(Icons.person, size: 28, color: borderColor)
                : null,
          ),
          if (match.user.isOnline == true)
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
        match.user.name,
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
          if (match.unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              constraints: const BoxConstraints(minWidth: 22),
              child: Text(
                match.unreadCount > 99 ? '99+' : '${match.unreadCount}',
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
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              identifier: match.id,
              userName: match.user.name,
              avatarUrl: match.user.mainPhotoUrl,
              isOnline: match.user.isOnline ?? false,
              lastSeenAt: match.user.lastSeenAt,
            ),
          ),
        );
        if (mounted) {
          context.read<ChatProvider>().loadConversations();
        }
      },
    );
  }
}
