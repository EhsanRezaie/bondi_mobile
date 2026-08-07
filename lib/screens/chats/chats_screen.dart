import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/auth/sign_up_screen.dart';
import 'package:dating_app/screens/chats/chat_list_screen.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/generated/app_localizations.dart';

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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    final authProvider = context.watch<AuthProvider>();
    if (!authProvider.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
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
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryColor,
          unselectedLabelColor:
              isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          indicatorColor: primaryColor,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: [
            Tab(text: t.chat_chats),
            Tab(text: t.chat_pending),
            Tab(text: t.chat_incoming),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ChatListScreen(
            chats: context.watch<ChatProvider>().conversations,
            isLoading: context.watch<ChatProvider>().isLoading,
            hasMore: context.watch<ChatProvider>().hasMoreConversations,
            emptyText: t.chat_empty_chats,
            onRefresh: () =>
                context.read<ChatProvider>().loadConversations(),
            onLoadMore: () =>
                context.read<ChatProvider>().loadMoreConversations(),
            onChatTap: _openChat,
          ),
          ChatListScreen(
            chats: context.watch<ChatProvider>().pendingChats,
            isLoading: context.watch<ChatProvider>().isLoading,
            hasMore: context.watch<ChatProvider>().hasMorePending,
            emptyText: t.chat_empty_pending,
            onRefresh: () =>
                context.read<ChatProvider>().loadPendingIncoming(),
            onLoadMore: () =>
                context.read<ChatProvider>().loadMorePendingIncoming(),
            onChatTap: _openChat,
          ),
          ChatListScreen(
            chats: context.watch<ChatProvider>().incomingChats,
            isLoading: context.watch<ChatProvider>().isLoading,
            hasMore: context.watch<ChatProvider>().hasMoreIncoming,
            emptyText: t.chat_empty_incoming,
            onRefresh: () =>
                context.read<ChatProvider>().loadPendingIncoming(),
            onLoadMore: () =>
                context.read<ChatProvider>().loadMorePendingIncoming(),
            onChatTap: _openChat,
          ),
        ],
      ),
    );
  }
}
