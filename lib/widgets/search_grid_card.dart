import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';

class SearchGridCard extends StatelessWidget {
  final DiscoverProfile profile;
  final VoidCallback? onTap;

  const SearchGridCard({
    super.key,
    required this.profile,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final photoUrl = profile.mainPhotoUrl;

    return GestureDetector(
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
              // Photo
              if (photoUrl != null && photoUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const ShimmerAvatar(),
                  errorWidget: (context, url, error) => Container(
                    color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                    child: Icon(Icons.person,
                        size: 32,
                        color: isDark ? AppTheme.darkTextMuted : Colors.grey),
                  ),
                )
              else
                Container(
                  color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                  child: Icon(Icons.person,
                      size: 32,
                      color: isDark ? AppTheme.darkTextMuted : Colors.grey),
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
                        Colors.black.withOpacity(0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Verified badge
              if (profile.isVerified)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, size: 10, color: Colors.white),
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
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E),
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (profile.isOnline && profile.isPremium) const SizedBox(width: 3),
                    if (profile.isPremium)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.darkError : AppTheme.lightError,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(Icons.workspace_premium, size: 8, color: Colors.white),
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
                              fontFamily: 'Inter',
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textColor,
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
                              ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                              : (isDark ? AppTheme.darkError : AppTheme.lightError),
                        ),
                      ],
                    ),
                    if (profile.distanceKm != null)
                      Text(
                        '${profile.distanceKm!.round()} km',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    if (profile.locationDisplay.isNotEmpty)
                      Text(
                        profile.locationDisplay,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          color: Colors.white.withOpacity(0.7),
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
    );
  }
}
