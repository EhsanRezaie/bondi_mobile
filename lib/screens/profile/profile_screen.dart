// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/models/photo.dart';
import 'package:dating_app/models/profile_stats.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/profile_provider.dart';
import 'package:dating_app/screens/profile/avatar_crop_screen.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/screens/profile/edit_basic_info_screen.dart';
import 'package:dating_app/screens/profile/edit_profile_details_screen.dart';
import 'package:dating_app/screens/profile/edit_interests_screen.dart';
import 'package:dating_app/screens/profile/edit_prompts_screen.dart';
import 'package:dating_app/screens/profile/edit_photos_screen.dart';
import 'package:dating_app/screens/profile/settings_screen.dart';
import 'package:dating_app/screens/profile/tickets_screen.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/widgets/action_toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    if (!provider.isInitialized || _isFirstLoad) {
      _isFirstLoad = false;
      await provider.refreshData();
    }
  }

  Future<void> _onRefresh() async {
    if (!mounted) return;
    final provider = Provider.of<ProfileProvider>(context, listen: false);
    await provider.refreshData();
    if (mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUser();
    }
  }

  String _getPremiumDaysLeft(DateTime? premiumUntil) {
    if (premiumUntil == null) return '0';
    final now = DateTime.now();
    final difference = premiumUntil.difference(now);
    return difference.inDays.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;

    return Selector<ProfileProvider, bool>(
      selector: (_, p) => p.isLoading && p.photos.isEmpty,
      builder: (context, showLoading, _) {
        if (showLoading) {
          return Scaffold(
            backgroundColor: bgColor,
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            title: Text(
              'Profile',
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: onSurfaceColor,
                letterSpacing: 2,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.headset_mic_outlined, color: onSurfaceColor),
              tooltip: AppLocalizations.of(context)!.support,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TicketsScreen(),
                  ),
                );
              },
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: onSurfaceColor),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                24.0,
                0,
                24.0,
                AppLayout.floatingNavClearance,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Selector<AuthProvider, User?>(
                    selector: (_, a) => a.user,
                    builder: (context, user, _) {
                      return Selector<ProfileProvider, PhotoResponse?>(
                        selector: (_, p) => p.mainPhoto,
                        builder: (context, mainPhoto, _) {
                          return _buildProfileHeader(
                            user,
                            mainPhoto,
                            primaryColor,
                            onSurfaceColor,
                            textMutedColor,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                  Selector<ProfileProvider, ProfileStats?>(
                    selector: (_, p) => p.stats,
                    builder: (context, stats, _) => _buildStatsSection(
                      stats,
                      primaryColor,
                      onSurfaceColor,
                      textMutedColor,
                      isDark,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Selector<AuthProvider, User?>(
                    selector: (_, a) => a.user,
                    builder: (context, user, _) =>
                        _buildPremiumSection(user, primaryColor, isDark),
                  ),
                  const SizedBox(height: 32),
                  Selector<AuthProvider, User?>(
                    selector: (_, a) => a.user,
                    builder: (context, user, _) {
                      return Selector<ProfileProvider, PhotoResponse?>(
                        selector: (_, p) => p.mainPhoto,
                        builder: (context, mainPhoto, _) {
                          return _buildAccountSection(
                            user,
                            mainPhoto,
                            onSurfaceColor,
                            textMutedColor,
                            isDark,
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(
    User? user,
    PhotoResponse? mainPhoto,
    Color primaryColor,
    Color onSurfaceColor,
    Color textMutedColor,
  ) {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final avatarSize = AppLayout.s(context, 120);
    return Column(
      children: [
        Stack(
          children: [
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.primaryGradient(),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGradientStart.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3),
              child: ClipOval(
                child: Container(
                  color: Colors.white,
                  child: ClipOval(
                    child: mainPhoto != null && mainPhoto.url.isNotEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) {
                              final double normX = mainPhoto.cropOffsetX;
                              final double normY = mainPhoto.cropOffsetY;
                              return Transform.translate(
                                 offset: Offset(
                                   normX * avatarSize,
                                   normY * avatarSize,
                                 ),
                                 child: CachedImage.widget(
                                   mainPhoto.displayUrl,
                                   width: avatarSize,
                                   height: avatarSize,
                                   fit: BoxFit.cover,
                                   errorWidget: Container(
                                     color: Colors.grey.shade200,
                                     child: const Icon(
                                       Icons.person,
                                       color: Colors.grey,
                                       size: 50,
                                     ),
                                   ),
                                 ),
                               );
                            },
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              color: Colors.grey,
                              size: 50,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  if (mainPhoto != null && mainPhoto.url.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AvatarCropScreen(
                          photo: mainPhoto,
                          onCropSaved: (updatedPhoto) {
                            _onRefresh();
                          },
                        ),
                      ),
                    );
                  } else {
                    showActionToast(
                      context,
                      t.upload_profile_picture_first,
                      isError: true,
                    );
                  }
                },
                child: Container(
                  width: AppLayout.s(context, 36),
                  height: AppLayout.s(context, 36),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: AppLayout.s(context, 18),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          '${user?.name ?? 'Alex'}, ${user?.age ?? 28}',
          style: (isPersian ? AppTheme.h1Fa : AppTheme.h1).copyWith(
            fontWeight: FontWeight.w800,
            color: onSurfaceColor,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on, size: 14, color: textMutedColor),
            const SizedBox(width: 4),
            Text(
              user?.city != null && user!.city!.isNotEmpty
                  ? '${user.city}, ${user.country ?? ''}'
                  : 'New York, NY',
              style: (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
                fontSize: 14,
                color: textMutedColor,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsSection(
    ProfileStats? stats,
    Color primaryColor,
    Color onSurfaceColor,
    Color textMutedColor,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            '❤️',
            stats?.likesSent ?? 0,
            'Likes',
            onSurfaceColor,
            textMutedColor,
          ),
          _buildStatItem(
            '💑',
            stats?.matches ?? 0,
            'Matches',
            onSurfaceColor,
            textMutedColor,
          ),
          _buildStatItem(
            '💬',
            stats?.messages ?? 0,
            'Messages',
            onSurfaceColor,
            textMutedColor,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String icon,
    int value,
    String label,
    Color onSurfaceColor,
    Color textMutedColor,
  ) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 24)),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontSize: 12,
            color: textMutedColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPremiumSection(User? user, Color primaryColor, bool isDark) {
    final isPremium = user?.isPremium ?? false;
    final premiumUntil = user?.premiumUntil;
    final daysLeft = isPremium ? _getPremiumDaysLeft(premiumUntil) : '0';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.12),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isPremium
                        ? Icons.workspace_premium
                        : Icons.workspace_premium_outlined,
                    color: isPremium
                        ? Colors.amber.shade300
                        : Colors.white.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPremium ? 'PREMIUM' : 'BONDI PREMIUM',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isPremium
                          ? Colors.amber.shade300
                          : Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (isPremium) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$daysLeft days',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isPremium
                ? 'You have Premium access'
                : 'Unlock Exclusive Connections',
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPremium
                ? 'Enjoy unlimited likes, advanced filters, and more.'
                : 'See who liked you, advanced filters, and more.',
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isPremium
                  ? () {
                      // TODO: Manage subscription
                    }
                  : () {
                      // TODO: Navigate to premium purchase
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white,
                foregroundColor: isPremium ? Colors.white : primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                minimumSize: const Size(double.infinity, 48),
                side: isPremium
                    ? BorderSide(color: Colors.white.withValues(alpha: 0.2))
                    : BorderSide.none,
              ),
              child: Text(
                isPremium ? 'Manage Subscription' : 'Get Premium',
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPremium ? Colors.white : primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSection(
    User? user,
    PhotoResponse? mainPhoto,
    Color onSurfaceColor,
    Color textMutedColor,
    bool isDark,
  ) {
    final t = AppLocalizations.of(context)!;
    // Check if main photo is face verified
    final bool isFaceVerified = mainPhoto?.faceVerified ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ACCOUNT',
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade700,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            ),
          ),
          child: Column(
            children: [
              // 1. Verify Picture
              _buildAccountTile(
                icon: isFaceVerified ? Icons.verified : Icons.verified_outlined,
                title: 'Verify Picture',
                status: isFaceVerified ? '✅ Verified' : '',
                onSurfaceColor: onSurfaceColor,
                textMutedColor: textMutedColor,
                isDark: isDark,
                onTap: () {
                  if (!isFaceVerified) {
                    // TODO: Navigate to face verification screen
                    showActionToast(context, t.face_verification_coming_soon);
                  }
                },
                showChevron: !isFaceVerified,
              ),
              // 2. Basic Info
              _buildAccountTile(
                icon: Icons.person_outline,
                title: 'Basic Info',
                onSurfaceColor: onSurfaceColor,
                textMutedColor: textMutedColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditBasicInfoScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _onRefresh();
                    }
                  });
                },
                showChevron: true,
              ),
              // 3. Profile Details
              _buildAccountTile(
                icon: Icons.note_outlined,
                title: 'Profile Details',
                onSurfaceColor: onSurfaceColor,
                textMutedColor: textMutedColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileDetailsScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _onRefresh();
                    }
                  });
                },
                showChevron: true,
              ),
              // 4. Interests
              _buildAccountTile(
                icon: Icons.favorite_outline,
                title: 'Interests',
                onSurfaceColor: onSurfaceColor,
                textMutedColor: textMutedColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditInterestsScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _onRefresh();
                    }
                  });
                },
                showChevron: true,
              ),
              // 5. Prompts
              _buildAccountTile(
                icon: Icons.question_answer_outlined,
                title: 'Prompts',
                onSurfaceColor: onSurfaceColor,
                textMutedColor: textMutedColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditPromptsScreen(),
                    ),
                  ).then((_) {
                    if (mounted) {
                      _onRefresh();
                    }
                  });
                },
                showChevron: true,
              ),
              // 6. Edit Photos
              _buildAccountTile(
                icon: Icons.photo_library_outlined,
                title: 'Edit Photos',
                onSurfaceColor: onSurfaceColor,
                textMutedColor: textMutedColor,
                isDark: isDark,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditPhotosScreen(
                        profileProvider: Provider.of<ProfileProvider>(
                          context,
                          listen: false,
                        ),
                      ),
                    ),
                  );
                },
                showChevron: true,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    String status = '',
    required Color onSurfaceColor,
    required Color textMutedColor,
    required bool isDark,
    required VoidCallback onTap,
    bool showChevron = true,
    bool isLast = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                ),
        ),
        child: Row(
          children: [
            Container(
              width: AppLayout.s(context, 40),
              height: AppLayout.s(context, 40),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(AppLayout.s(context, 12)),
              ),
              child: Icon(
                icon,
                color: textMutedColor,
                size: AppLayout.s(context, 22),
              ),
            ),
            SizedBox(width: AppLayout.s(context, 16)),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: onSurfaceColor,
                      ),
                    ),
                  ),
                  if (status.isNotEmpty) ...[
                    SizedBox(width: AppLayout.s(context, 8)),
                    Flexible(
                      child: Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: status.contains('Verified')
                              ? Colors.green
                              : textMutedColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron) Icon(Icons.chevron_right, color: textMutedColor),
          ],
        ),
      ),
    );
  }
}
