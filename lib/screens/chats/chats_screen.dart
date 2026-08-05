import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/auth/sign_up_screen.dart';
import 'package:dating_app/screens/chats/liked_me_screen.dart';
import 'package:dating_app/screens/chats/i_liked_screen.dart';
import 'package:dating_app/screens/chats/chat_list_screen.dart';
import 'package:dating_app/widgets/matched_avatar_strip.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isAuthenticated) {
        final chatProvider = context.read<ChatProvider>();
        chatProvider.loadConversations();
        chatProvider.refreshLimits();
      }
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
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

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
            Tab(text: t.chat_liked_me),
            Tab(text: t.chat_i_liked),
            Tab(text: t.chat_chats),
          ],
        ),
      ),
      body: Column(
        children: [
          Consumer<ChatProvider>(
            builder: (context, provider, _) {
              return MatchedAvatarStrip(
                matches: provider.conversations,
                onMatchTap: (matchId) {
                  _tabController.animateTo(2);
                },
              );
            },
          ),
          Divider(height: 1, color: borderColor),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                LikedMeScreen(),
                ILikedScreen(),
                ChatListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
