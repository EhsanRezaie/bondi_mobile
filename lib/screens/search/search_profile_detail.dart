import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/widgets/discover_action_button.dart';
import 'package:dating_app/widgets/action_toast.dart';
import 'package:dating_app/widgets/photo_gallery_page.dart';

class SearchProfileDetail extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final int? likesRemaining;
  final int? chatsRemaining;
  final bool isPremium;
  final bool viewOnly;
  final Future<Map<String, dynamic>?> Function(DiscoverProfile)? onLike;
  final Future<Map<String, dynamic>?> Function(
    DiscoverProfile, {
    String? message,
  })?
  onChat;

  const SearchProfileDetail({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.likesRemaining,
    this.chatsRemaining,
    this.isPremium = false,
    this.viewOnly = false,
    this.onLike,
    this.onChat,
  });

  @override
  State<SearchProfileDetail> createState() => _SearchProfileDetailState();
}

class _SearchProfileDetailState extends State<SearchProfileDetail> {
  int _currentPhotoIndex = 0;
  late ScrollController _photoStripController;

  @override
  void initState() {
    super.initState();
    _photoStripController = ScrollController();
  }

  @override
  void dispose() {
    _photoStripController.dispose();
    super.dispose();
  }

  DiscoverProfile get profile => widget.profile;

  List<String> get allPhotos {
    final photos = <String>[];
    if (profile.mainPhotoUrl != null && profile.mainPhotoUrl!.isNotEmpty) {
      photos.add(profile.mainPhotoUrl!);
    }
    photos.addAll(profile.photos.where((p) => p != profile.mainPhotoUrl));
    return photos;
  }

  void _openGallery() {
    final photos = allPhotos;
    if (photos.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PhotoGalleryPage(
          photos: photos,
          initialIndex: _currentPhotoIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final photos = allPhotos;

    return Scaffold(
      extendBody: true,
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _buildHeaderSection(
                    t,
                    isDark,
                    primaryColor,
                    mutedColor,
                    textColor,
                    surfaceColor,
                    borderColor,
                    photos,
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildBodySection(
                    t,
                    isDark,
                    primaryColor,
                    mutedColor,
                    textColor,
                    surfaceColor,
                    borderColor,
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: SizedBox(height: 120),
                ),
              ],
            ),
            if (!widget.viewOnly)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildBottomActionBar(t, isDark),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
    Color mutedColor,
    Color textColor,
    Color surfaceColor,
    Color borderColor,
    List<String> photos,
  ) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final font = AppTheme.fontFor(isPersian);
    final screenSize = MediaQuery.of(context).size;
    final photoW = screenSize.width;
    final photoH = (screenSize.height * 0.42).clamp(220.0, 560.0);
    final photoPlaceholder = isDark
        ? AppTheme.darkSecondary
        : Colors.grey.shade200;
    final photoError = Container(
      color: photoPlaceholder,
      child: Icon(
        Icons.person,
        size: 80,
        color: isDark ? AppTheme.darkTextMuted : Colors.grey,
      ),
    );

    return Column(
      children: [
        Stack(
          children: [
            GestureDetector(
              onTap: photos.isNotEmpty ? _openGallery : null,
              child: SizedBox(
                height: photoH,
                width: double.infinity,
                child: photos.isNotEmpty
                    ? CachedImage.widget(
                        photos[_currentPhotoIndex],
                        width: photoW,
                        height: photoH,
                        fit: BoxFit.cover,
                        errorWidget: photoError,
                      )
                    : photoError,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                  stops: const [0.0, 0.2, 0.6, 1.0],
                ),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: AppLayout.s(context, 40),
                  height: AppLayout.s(context, 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: AppLayout.s(context, 22),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: _openProfileMenu,
                child: Container(
                  width: AppLayout.s(context, 40),
                  height: AppLayout.s(context, 40),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flag, color: Colors.white, size: 20),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                top: AppLayout.s(context, 56),
                left: 0,
                right: 0,
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(photos.length, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: AppLayout.s(
                          context,
                          _currentPhotoIndex == index ? 24 : 8,
                        ),
                        height: AppLayout.s(context, 8),
                        decoration: BoxDecoration(
                          color: _currentPhotoIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(
                            AppLayout.s(context, 4),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            if (photos.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: AppLayout.s(context, 64),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppLayout.s(context, 12),
                      vertical: AppLayout.s(context, 6),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.fullscreen,
                          size: AppLayout.s(context, 14),
                          color: Colors.white,
                        ),
                        SizedBox(width: AppLayout.s(context, 6)),
                        Text(
                          t.photo_fullscreen_hint,
                          style: TextStyle(
                            fontSize: AppLayout.s(context, 12),
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.age}',
                        style: TextStyle(
                          fontFamily: font,
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (profile.distanceKm != null) ...[
                        Icon(
                          Icons.near_me,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.discover_km_away(profile.distanceKm!.round()),
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (profile.locationDisplay.isNotEmpty) ...[
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          profile.locationDisplay,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                      if (profile.isVerified) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient(),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ],
                      if (profile.currentUserAction == 'like') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.all(3),
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
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (photos.length > 1)
          SizedBox(
            height: AppLayout.s(context, 64),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              controller: _photoStripController,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final isSelected = _currentPhotoIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() => _currentPhotoIndex = index);
                  },
                  child: Container(
                    width: AppLayout.s(context, 56),
                    height: AppLayout.s(context, 56),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 3,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppLayout.s(context, 10),
                      ),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: CachedImage.widget(
                      photos[index],
                      width: AppLayout.s(context, 56),
                      height: AppLayout.s(context, 56),
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(
                        AppLayout.s(context, 8),
                      ),
                      placeholder: Container(
                        color: isDark
                            ? AppTheme.darkSecondary
                            : Colors.grey.shade200,
                      ),
                      errorWidget: Container(
                        color: isDark
                            ? AppTheme.darkSecondary
                            : Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildBodySection(
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
    Color mutedColor,
    Color textColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (profile.bio != null && profile.bio!.isNotEmpty)
            _buildBioSection(
              t,
              isDark,
              primaryColor,
              mutedColor,
              textColor,
              surfaceColor,
              borderColor,
            ),
          _buildChipSection(
            emoji: '💪',
            title: t.profile_section_physical,
            chips: [
              _buildValueChip(
                profile.gender == 'male' ? '♂️' : '♀️',
                _capitalize(profile.gender),
                isDark,
                textColor,
                borderColor,
              ),
              if (profile.height != null)
                _buildValueChip(
                  '📏',
                  '${profile.height} cm',
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.weight != null)
                _buildValueChip(
                  '⚖️',
                  '${profile.weight} kg',
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.bodyType != null)
                _buildValueChip(
                  '💪',
                  _capitalize(profile.bodyType!),
                  isDark,
                  textColor,
                  borderColor,
                ),
            ],
          ),
          _buildChipSection(
            emoji: '🏠',
            title: t.profile_section_lifestyle,
            chips: [
              if (profile.relationshipStatus != null)
                _buildValueChip(
                  '❤️',
                  _capitalize(profile.relationshipStatus!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.livingSituation != null)
                _buildValueChip(
                  '🏠',
                  _formatLiving(profile.livingSituation!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.childrenStatus != null)
                _buildValueChip(
                  '👶',
                  _formatChildren(profile.childrenStatus!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.smoking != null)
                _buildValueChip(
                  '🚬',
                  _capitalize(profile.smoking!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.drinking != null)
                _buildValueChip(
                  '🍷',
                  _capitalize(profile.drinking!),
                  isDark,
                  textColor,
                  borderColor,
                ),
            ],
          ),
          _buildChipSection(
            emoji: '🌍',
            title: t.profile_section_background,
            chips: [
              if (profile.education != null)
                _buildValueChip(
                  '🎓',
                  _formatEducation(profile.education!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.workplace != null && profile.workplace!.isNotEmpty)
                _buildValueChip(
                  '💼',
                  profile.workplace!,
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.religion != null)
                _buildValueChip(
                  '☪️',
                  _capitalize(profile.religion!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.ethnicity != null)
                _buildValueChip(
                  '🌍',
                  _capitalize(profile.ethnicity!),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.politicalOrientation != null)
                _buildValueChip(
                  '🗳️',
                  _capitalize(profile.politicalOrientation!),
                  isDark,
                  textColor,
                  borderColor,
                ),
            ],
          ),
          if (profile.languages != null && profile.languages!.isNotEmpty)
            _buildChipsSection(
              emoji: '🗣️',
              title: t.profile_section_languages,
              items: profile.languages!,
              isDark: isDark,
              primaryColor: primaryColor,
              mutedColor: mutedColor,
              textColor: textColor,
              borderColor: borderColor,
            ),
          if (profile.interests.isNotEmpty)
            _buildChipsSection(
              emoji: '❤️',
              title: t.profile_section_interests,
              items: profile.interests,
              iconMap: widget.interestIcons,
              isDark: isDark,
              primaryColor: primaryColor,
              mutedColor: mutedColor,
              textColor: textColor,
              borderColor: borderColor,
            ),
          if (profile.prompts.isNotEmpty)
            _buildPromptsSection(
              t: t,
              isDark: isDark,
              mutedColor: mutedColor,
              textColor: textColor,
              surfaceColor: surfaceColor,
              borderColor: borderColor,
              primaryColor: primaryColor,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBioSection(
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
    Color mutedColor,
    Color textColor,
    Color surfaceColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              t.profile_section_about,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor.withValues(alpha: 0.5)),
          ),
          child: Text(
            profile.bio!,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 15,
              height: 1.5,
              color: textColor,
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildChipSection({
    required String emoji,
    required String title,
    required List<Widget> chips,
  }) {
    if (chips.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.isDarkMode
                    ? AppTheme.darkPrimary
                    : AppTheme.lightPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    );
  }

  Widget _buildValueChip(
    String emoji,
    String value,
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white10
            : (context.isDarkMode
                      ? AppTheme.darkPrimary
                      : AppTheme.lightPrimary)
                  .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $value',
        style: TextStyle(
          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildChipsSection({
    required String emoji,
    required String title,
    required List<String> items,
    Map<String, String> iconMap = const {},
    required bool isDark,
    required Color primaryColor,
    required Color mutedColor,
    required Color textColor,
    required Color borderColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: items.map((item) {
            final icon = iconMap[item];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                icon != null ? '$icon $item' : item,
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromptsSection({
    required AppLocalizations t,
    required bool isDark,
    required Color mutedColor,
    required Color textColor,
    required Color surfaceColor,
    required Color borderColor,
    required Color primaryColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            const Text('💬', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              t.profile_section_prompts,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...profile.prompts.map((prompt) {
          final question = prompt['question'] as String? ?? '';
          final answer = prompt['answer'] as String? ?? '';
          if (answer.isEmpty) return const SizedBox.shrink();
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor.withValues(alpha: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  question,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  answer,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 15,
                    height: 1.4,
                    color: textColor,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBottomActionBar(AppLocalizations t, bool isDark) {
    final isLikeBlocked =
        !widget.isPremium && (widget.likesRemaining ?? 0) <= 0;
    final isChatBlocked =
        !widget.isPremium && (widget.chatsRemaining ?? 0) <= 0;
    final alreadyLiked =
        profile.currentUserAction == 'like' ||
        profile.currentUserAction == 'matched';

    return Padding(
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoverActionButton(
            icon: Icons.chat_bubble_rounded,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            iconColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            borderColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            size: 64,
            badgeCount: widget.isPremium ? null : widget.chatsRemaining,
            onPressed: isChatBlocked ? null : () => _handleChat(),
          ),
          if (!alreadyLiked) ...[
            const SizedBox(width: 24),
            DiscoverActionButton(
              icon: Icons.favorite_rounded,
              gradient: AppTheme.likeGradient(isDark: isDark),
              size: 64,
              badgeCount: widget.isPremium ? null : widget.likesRemaining,
              onPressed: isLikeBlocked ? null : () => _handleLike(),
            ),
          ],
        ],
      ),
    );
  }

  void _openProfileMenu() {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;

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
              leading: Icon(Icons.flag, color: errorColor),
              title: Text(
                'Report Profile',
                style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _reportProfile();
              },
            ),
            if (widget.viewOnly)
              ListTile(
                leading: Icon(Icons.block, color: errorColor),
                title: Text(
                  'Block User',
                  style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: textColor),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmBlock();
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _reportProfile() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final reported = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? AppTheme.darkSurface
            : AppTheme.lightSurface,
        title: Text(
          'Report Profile',
          style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en'))),
        ),
        content: TextField(
          controller: controller,
          maxLines: 3,
          maxLength: 500,
          decoration: const InputDecoration(
            hintText: 'Tell us what went wrong...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().length < 5) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text('Send', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
        ],
      ),
    );
    if (reported != true || !mounted) return;
    final ok = await provider.reportUser(profile.id, controller.text.trim());
    if (!mounted) return;
    showActionToast(context, ok ? 'Reported' : t.error_something_wrong, isError: !ok);
  }

  Future<void> _confirmBlock() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? AppTheme.darkSurface
            : AppTheme.lightSurface,
        title: Text('Block User', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
        content: Text(
          'You will no longer see each other. Their messages will stop.',
          style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en'))),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Block', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')))),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await provider.blockUser(profile.id);
    if (!mounted) return;
    showActionToast(context, ok ? 'Blocked' : t.error_something_wrong, isError: !ok);
  }

  Future<void> _handleLike() async {
    final isLikeBlocked =
        !widget.isPremium && (widget.likesRemaining ?? 0) <= 0;
    if (isLikeBlocked) {
      _showLimitReachedDialog('likes');
      return;
    }

    if (widget.onLike == null) return;
    final result = await widget.onLike!(profile);
    if (result != null && mounted) {
      if (result['matched'] == true) {
        _showMatchDialog(result);
      } else {
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.toast_like_sent);
        Navigator.pop(context);
      }
    } else if (mounted) {
      final t = AppLocalizations.of(context)!;
      showActionToast(context, t.error_something_wrong, isError: true);
    }
  }

  Future<void> _handleChat() async {
    final isChatBlocked =
        !widget.isPremium && (widget.chatsRemaining ?? 0) <= 0;
    if (isChatBlocked) {
      _showLimitReachedDialog('chats');
      return;
    }

    final message = await _showChatBottomSheet();
    if (message != null && mounted && widget.onChat != null) {
      final result = await widget.onChat!(profile, message: message);
      if (result != null && mounted) {
        final chatId = (result['chat_id'] ?? result['chatId'] ?? '').toString();
        if (chatId.isNotEmpty) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute<void>(
              builder: (_) => ChatDetailScreen(
                identifier: chatId,
                userName: profile.name,
                avatarUrl: profile.mainPhotoUrl,
                isOnline: profile.isOnline,
                lastSeenAt: profile.lastSeenAt,
              ),
            ),
          );
        } else {
          final t = AppLocalizations.of(context)!;
          showActionToast(context, t.error_something_wrong, isError: true);
        }
      } else if (mounted) {
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.error_something_wrong, isError: true);
      }
    }
  }

  void _showLimitReachedDialog(String type) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Daily limit reached',
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Text(
          type == 'likes'
              ? t.search_limit_reached_likes
              : t.search_limit_reached_chats,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('OK', style: TextStyle(color: primaryColor)),
          ),
        ],
      ),
    );
  }

  Future<String?> _showChatBottomSheet() async {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final messageController = TextEditingController();
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              decoration: BoxDecoration(
                color: isDark ? AppTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t.discover_say_something,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: messageController,
                        autofocus: true,
                        maxLines: 3,
                        maxLength: 200,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                        decoration: InputDecoration(
                          hintText: t.discover_send_message_hint,
                          hintStyle: TextStyle(
                            color: isDark
                                ? AppTheme.darkTextMuted
                                : Colors.grey,
                          ),
                          filled: true,
                          fillColor: isDark
                              ? AppTheme.darkSecondary
                              : Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            final msg = messageController.text.trim();
                            Navigator.pop(ctx, msg.isNotEmpty ? msg : null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            t.discover_send_and_like,
                            style: TextStyle(
                              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    return result;
  }

  void _showMatchDialog(Map<String, dynamic> result) {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final bool messageSent = result['message_sent'] == true;
    final heroStyle =
        (isPersian ? AppTheme.heroDisplayFa : AppTheme.heroDisplay).copyWith(
          fontSize: 30,
          color: Colors.white,
        );
    final bodyStyle = (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 15,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: AppTheme.primaryGradient(),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGradientStart.withValues(alpha: 0.4),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 34,
                      color: Colors.white,
                    ),
                  ),
                  if (profile.mainPhotoUrl != null &&
                      profile.mainPhotoUrl!.isNotEmpty)
                    Positioned(
                      top: -40,
                      child: ClipOval(
                        child: SizedBox(
                          width: 56,
                          height: 56,
                          child: Image.network(
                            profile.mainPhotoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 56),
              Text(
                t.search_match_title,
                textAlign: TextAlign.center,
                style: heroStyle,
              ),
              const SizedBox(height: 8),
              Text(
                t.search_match_subtitle(profile.name),
                textAlign: TextAlign.center,
                style: bodyStyle,
              ),
              if (messageSent) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t.search_match_message_sent,
                      style: bodyStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  style: AppTheme.primaryButton.copyWith(
                    backgroundColor: const WidgetStatePropertyAll<Color>(
                      Colors.white,
                    ),
                    foregroundColor: const WidgetStatePropertyAll<Color>(
                      AppTheme.primaryGradientStart,
                    ),
                    elevation: const WidgetStatePropertyAll<double>(0),
                  ),
                  child: Text(
                    t.search_continue_browsing,
                    style: (isPersian ? AppTheme.buttonFa : AppTheme.button)
                        .copyWith(color: AppTheme.primaryGradientStart),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  String _formatLiving(String value) {
    switch (value.toLowerCase()) {
      case 'alone':
        return 'Alone';
      case 'with_family':
        return 'With Family';
      case 'with_roommate':
        return 'With Roommates';
      case 'with_partner':
        return 'With Partner';
      default:
        return _capitalize(value);
    }
  }

  String _formatChildren(String value) {
    switch (value.toLowerCase()) {
      case 'have':
        return 'Have children';
      case 'dont_have':
        return "Don't have children";
      case 'want':
        return 'Want children';
      case 'dont_want':
        return "Don't want children";
      default:
        return _capitalize(value);
    }
  }

  String _formatEducation(String value) {
    switch (value.toLowerCase()) {
      case 'high_school':
        return 'High School';
      case 'bachelor':
        return 'Undergraduate Degree';
      case 'master':
        return 'Postgraduate Degree';
      case 'phd':
        return 'PhD / Doctorate';
      default:
        return _capitalize(value);
    }
  }
}
