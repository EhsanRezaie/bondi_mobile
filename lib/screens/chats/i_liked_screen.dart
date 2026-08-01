import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/generated/app_localizations.dart';

class ILikedScreen extends StatefulWidget {
  const ILikedScreen({super.key});

  @override
  State<ILikedScreen> createState() => _ILikedScreenState();
}

class _ILikedScreenState extends State<ILikedScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadLikedUsers();
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
      context.read<ChatProvider>().loadMoreLikedUsers();
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

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.likedUsers.isEmpty) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            ),
          );
        }

        if (provider.likedUsers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.favorite_border, size: 64, color: borderColor),
                const SizedBox(height: 16),
                Text(
                  t.chat_empty_i_liked,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 16,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: provider.likedUsers.length +
              (provider.hasMoreLiked ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == provider.likedUsers.length) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                  ),
                ),
              );
            }
            return _buildLikedItem(
              provider.likedUsers[index],
              isDark,
              textColor,
              mutedColor,
              borderColor,
            );
          },
        );
      },
    );
  }

  Widget _buildLikedItem(
    SwipeUser user,
    bool isDark,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: borderColor,
            backgroundImage: user.mainPhotoUrl != null &&
                    user.mainPhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(user.mainPhotoUrl!)
                : null,
            child: user.mainPhotoUrl == null || user.mainPhotoUrl!.isEmpty
                ? Icon(Icons.person, size: 28, color: borderColor)
                : null,
          ),
          if (user.isOnline == true)
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
                    color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Text(
            '${user.name}, ${user.age}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (user.isPremium) ...[
            const SizedBox(width: 4),
            Icon(Icons.workspace_premium, size: 16, color: AppTheme.lightWarning),
          ],
          if (user.isVerified) ...[
            const SizedBox(width: 4),
            Icon(Icons.verified, size: 16, color: primaryColor),
          ],
        ],
      ),
      subtitle: user.distanceKm != null
          ? Text(
              '${user.distanceKm!.toStringAsFixed(0)} km away',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: mutedColor,
              ),
            )
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: mutedColor,
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(
              identifier: user.id,
              userName: user.name,
              avatarUrl: user.mainPhotoUrl,
              isOnline: user.isOnline ?? false,
              lastSeenAt: user.lastSeenAt,
            ),
          ),
        );
      },
    );
  }
}
