import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';

class MatchedAvatarStrip extends StatelessWidget {
  final List<Match> matches;
  final Function(String matchId) onMatchTap;
  final VoidCallback? onLoadMore;

  const MatchedAvatarStrip({
    super.key,
    required this.matches,
    required this.onMatchTap,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final borderColor =
        isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    // Scale the strip and avatar sizes modestly on larger screens and
    // bound the name text so very long names can't force overflow in the
    // horizontal list.
    final avatarRadius = AppLayout.s(context, 28);
    final stripHeight = 90.0 + (avatarRadius - 28);
    final itemWidth = avatarRadius * 2 + 16;

    final displayMatches =
        matches.where((m) => m.kind == 'match').take(5).toList();

    return SizedBox(
      height: stripHeight,
      child: displayMatches.isEmpty
          ? const SizedBox.shrink()
          : NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollEndNotification &&
                    notification.metrics.pixels >=
                        notification.metrics.maxScrollExtent - 50) {
                  onLoadMore?.call();
                }
                return false;
              },
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                itemCount: displayMatches.length,
                itemBuilder: (context, index) {
                  final match = displayMatches[index];
                  return GestureDetector(
                    onTap: () => onMatchTap(match.id),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
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
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: borderColor,
                                     backgroundImage:
                                         match.user.mainPhotoUrl != null &&
                                                 match.user.mainPhotoUrl!.isNotEmpty
                                             ? CachedImage.provider(
                                                 match.user.mainPhotoUrl!,
                                                 diameter: AppLayout.s(context, 56),
                                               )
                                             : null,
                                    child: match.user.mainPhotoUrl == null ||
                                            match.user.mainPhotoUrl!.isEmpty
                                        ? Icon(
                                            Icons.person,
                                            size: avatarRadius,
                                            color: borderColor,
                                          )
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
                                          color: isDark
                                              ? AppTheme.darkSuccess
                                              : AppTheme.lightSuccess,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: surfaceColor,
                                            width: 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ConstrainedBox(
                            constraints:
                                BoxConstraints(maxWidth: itemWidth),
                            child: Text(
                              match.user.name,
                              maxLines: 1,
                              style: TextStyle(
                                fontFamily: AppTheme.fontFor(
                                  !Localizations.localeOf(
                                    context,
                                  ).languageCode.contains('en'),
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? AppTheme.darkText
                                    : AppTheme.lightText,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
