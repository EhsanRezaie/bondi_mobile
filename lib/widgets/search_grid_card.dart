import 'package:flutter/material.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';

class SearchGridCard extends StatelessWidget {
  final DiscoverProfile profile;
  final VoidCallback? onTap;

  const SearchGridCard({super.key, required this.profile, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final font = AppTheme.fontFor(isPersian);
    final photoUrl = profile.mainPhotoUrl;

    return RepaintBoundary(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: isDark ? AppTheme.darkShadow : AppTheme.lightShadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo — grid tiles are maxCrossAxisExtent(160) × 0.58 (~93),
              // so decode at that display resolution rather than full source.
              if (photoUrl != null && photoUrl.isNotEmpty)
                CachedImage.widget(
                  photoUrl,
                  width: 160,
                  height: 93,
                  fit: BoxFit.cover,
                  placeholder: const ShimmerAvatar(),
                  errorWidget: Container(
                    color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                    child: Icon(
                      Icons.person,
                      size: 32,
                      color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                    ),
                  ),
                )
              else
                Container(
                  color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                  child: Icon(
                    Icons.person,
                    size: 32,
                    color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                  ),
                ),

              // Gradient overlay
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 60,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Liked badge
              if (profile.currentUserAction == 'like')
                Positioned(
                  top: 4,
                  right: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkError
                              : AppTheme.lightError,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

              // Top-left badges
              Positioned(
                top: 4,
                left: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profile.isOnline)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppTheme.darkSuccess
                              : AppTheme.lightSuccess,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (profile.isOnline && profile.isPremium)
                      const SizedBox(width: 3),
                    if (profile.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppTheme.likeGradient(isDark: isDark),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.workspace_premium,
                          size: 8,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),

              // Bottom info
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${profile.name}, ${profile.age}',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          profile.gender == 'male' ? Icons.male : Icons.female,
                          size: 10,
                          color: profile.gender == 'male'
                              ? (isDark
                                    ? AppTheme.darkPrimary
                                    : AppTheme.lightPrimary)
                              : (isDark
                                    ? AppTheme.darkError
                                    : AppTheme.lightError),
                        ),
                      ],
                    ),
                    if (profile.distanceKm != null)
                      Row(
                        children: [
                          Text(
                            '${profile.distanceKm!.round()} km',
                            style: TextStyle(
                              fontFamily: font,
                              fontSize: 9,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.verified,
                              size: AppLayout.s(context, 12),
                              color: Colors.white,
                            ),
                          ],
                        ],
                      ),
                    if (profile.isVerified && profile.distanceKm == null)
                      Row(
                        children: [
                          Icon(
                            Icons.verified,
                            size: AppLayout.s(context, 12),
                            color: Colors.white,
                          ),
                        ],
                      ),
                    if (profile.locationDisplay.isNotEmpty)
                      Text(
                        profile.locationDisplay,
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 9,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                       ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
