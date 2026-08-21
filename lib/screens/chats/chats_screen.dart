import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/login_screen.dart';
import 'package:dating_app/screens/chats/chat_list_screen.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/screens/chats/notifications_screen.dart';
import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/widgets/notification_bell.dart';

class ChatsScreen extends StatefulWidget {
  const ChatsScreen({super.key});

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.loadConversations();
        chatProvider.loadPendingIncoming();
        chatProvider.refreshLimits();
      }
    });
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    final chatProvider = context.read<ChatProvider>();
    if (_tabController.index == 0) {
      chatProvider.loadConversations();
    } else if (_tabController.index == 1) {
      chatProvider.loadPendingIncoming();
    } else if (_tabController.index == 2) {
      chatProvider.loadPendingIncoming();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _openChat(ChatCard chat) {
    final chatProvider = context.read<ChatProvider>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          identifier: chat.id,
          userName: chat.user.name,
          avatarUrl: chat.user.mainPhotoUrl,
          isOnline: chat.user.isOnline,
          lastSeenAt: chat.user.lastSeenAt,
          initialStatus: chat.status,
          initialInitiatorId: chat.initiatorId,
          peerId: chat.user.id,
        ),
      ),
    ).then((_) {
      chatProvider.loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t.chat_chats,
          style: (isPersian ? AppTheme.h2Fa : AppTheme.h2).copyWith(
            color: textColor,
          ),
        ),
        actions: [
          NotificationBell(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          _buildSegmentedTabs(t, isDark, primaryColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ChatListScreen(
                  chats: context.watch<ChatProvider>().conversations,
                  isLoading: context.watch<ChatProvider>().isLoading,
                  isLoadingMore:
                      context.watch<ChatProvider>().isLoadingMore,
                  hasMore: context.watch<ChatProvider>().hasMoreConversations,
                  emptyText: t.chat_empty_chats,
                  onRefresh: () =>
                      context.read<ChatProvider>().loadConversations(),
                  onLoadMore: () =>
                      context.read<ChatProvider>().loadMoreConversations(),
                  onChatTap: _openChat,
                  onChatLongPress: _showChatActions,
                ),
                ChatListScreen(
                  chats: context.watch<ChatProvider>().pendingChats,
                  isLoading: context.watch<ChatProvider>().isLoading,
                  isLoadingMore:
                      context.watch<ChatProvider>().isLoadingMore,
                  hasMore: context.watch<ChatProvider>().hasMorePending,
                  emptyText: t.chat_empty_pending,
                  onRefresh: () =>
                      context.read<ChatProvider>().loadPendingIncoming(),
                  onLoadMore: () =>
                      context.read<ChatProvider>().loadMorePendingIncoming(),
                  onChatTap: _openChat,
                  onChatLongPress: _showChatActions,
                ),
                ChatListScreen(
                  chats: context.watch<ChatProvider>().incomingChats,
                  isLoading: context.watch<ChatProvider>().isLoading,
                  isLoadingMore:
                      context.watch<ChatProvider>().isLoadingMore,
                  hasMore: context.watch<ChatProvider>().hasMoreIncoming,
                  emptyText: t.chat_empty_incoming,
                  onRefresh: () =>
                      context.read<ChatProvider>().loadPendingIncoming(),
                  onLoadMore: () =>
                      context.read<ChatProvider>().loadMorePendingIncoming(),
                  onChatTap: _openChat,
                  onChatLongPress: _showChatActions,
                ),
              ],
            ),
          ),
        ],
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
    final labels = [t.chat_chats, t.chat_pending, t.chat_incoming];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusChip - 4,
                        ),
                      ),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: (isPersian
                                ? AppTheme.bodyBoldFa
                                : AppTheme.bodyBold)
                            .copyWith(
                          fontSize: 14,
                          color: selected ? Colors.white : mutedColor,
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

  void _showChatActions(ChatCard chat) {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(
                'Delete Chat',
                style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteChat(chat);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteChat(ChatCard chat) async {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        title: Text('Delete Chat', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
        content: Text(
          'This hides the chat on your side.',
          style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en'))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Delete', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ChatProvider>().deleteChat(chat.id);
  }
}
