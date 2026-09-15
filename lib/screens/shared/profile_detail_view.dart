import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/services/interest_localizer.dart';
import 'package:dating_app/utils/profile_localization.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/utils/cached_image.dart';
import 'package:dating_app/widgets/action_toast.dart';
import 'package:dating_app/widgets/photo_gallery_page.dart';

/// The single canonical profile detail layout used from discover, search,
/// notifications and chat. Callers only vary the [bottomBar] (and whether the
/// block option is offered); everything else is identical everywhere.
class ProfileDetailView extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;

  /// Action buttons pinned to the bottom. Null renders a view-only detail.
  final Widget? bottomBar;

  /// Adds the "Block User" entry to the report menu (used for view-only).
  final bool showBlockOption;

  /// Overrides the default close behaviour (Navigator.pop).
  final VoidCallback? onClosed;

  const ProfileDetailView({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.bottomBar,
    this.showBlockOption = false,
    this.onClosed,
  });

  @override
  State<ProfileDetailView> createState() => _ProfileDetailViewState();
}

class _ProfileDetailViewState extends State<ProfileDetailView> {
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

  void _close() {
    if (widget.onClosed != null) {
      widget.onClosed!();
    } else {
      Navigator.pop(context);
    }
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
                  child: const SizedBox(height: 120),
                ),
              ],
            ),
            if (widget.bottomBar != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: widget.bottomBar!,
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
                onTap: _close,
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
                      if (profile.locationDisplay.isNotEmpty)
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 14,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  profile.locationDisplay,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: font,
                                    fontSize: 13,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
                localizedEnum(t, profile.gender),
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
                  localizedEnum(t, profile.bodyType),
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
                  localizedEnum(t, profile.relationshipStatus),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.livingSituation != null)
                _buildValueChip(
                  '🏠',
                  localizedEnum(t, profile.livingSituation),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.childrenStatus != null)
                _buildValueChip(
                  '👶',
                  localizedEnum(t, profile.childrenStatus),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.smoking != null)
                _buildValueChip(
                  '🚬',
                  localizedEnum(t, profile.smoking),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.drinking != null)
                _buildValueChip(
                  '🍷',
                  localizedEnum(t, profile.drinking),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.hereFor != null)
                _buildValueChip(
                  '🎯',
                  localizedEnum(t, profile.hereFor),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.pets != null)
                _buildValueChip(
                  '🐾',
                  localizedEnum(t, profile.pets),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.workoutFrequency != null)
                _buildValueChip(
                  '🏃',
                  localizedEnum(t, profile.workoutFrequency),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.zodiacSign != null)
                _buildValueChip(
                  '♈',
                  localizedEnum(t, profile.zodiacSign),
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
                  localizedEnum(t, profile.education),
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
                  localizedEnum(t, profile.religion),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.ethnicity != null)
                _buildValueChip(
                  '🌍',
                  localizedEnum(t, profile.ethnicity),
                  isDark,
                  textColor,
                  borderColor,
                ),
              if (profile.politicalOrientation != null)
                _buildValueChip(
                  '🗳️',
                  localizedEnum(t, profile.politicalOrientation),
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
              display: (v) => localizedLanguage(t, v),
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
              display: InterestLocalizer.instance.name,
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
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
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
              fontFamily: AppTheme.fontFor(
                !Localizations.localeOf(context).languageCode.contains('en'),
              ),
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
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
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
          fontFamily: AppTheme.fontFor(
            !Localizations.localeOf(context).languageCode.contains('en'),
          ),
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
    String Function(String)? display,
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
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
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
            final label = display?.call(item) ?? item;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white10
                    : primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                icon != null ? '$icon $label' : label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(
                    !Localizations.localeOf(context).languageCode.contains('en'),
                  ),
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
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
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
                    fontFamily: AppTheme.fontFor(
                      !Localizations.localeOf(
                        context,
                      ).languageCode.contains('en'),
                    ),
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
                    fontFamily: AppTheme.fontFor(
                      !Localizations.localeOf(
                        context,
                      ).languageCode.contains('en'),
                    ),
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

  void _openProfileMenu() {
    final isDark = context.isDarkMode;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final errorColor = isDark ? AppTheme.darkError : AppTheme.lightError;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

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
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(isPersian),
                  color: textColor,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _reportProfile();
              },
            ),
            if (widget.showBlockOption)
              ListTile(
                leading: Icon(Icons.block, color: errorColor),
                title: Text(
                  'Block User',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(isPersian),
                    color: textColor,
                  ),
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
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final controller = TextEditingController();
    final reported = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? AppTheme.darkSurface
            : AppTheme.lightSurface,
        title: Text(
          'Report Profile',
          style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
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
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().length < 5) return;
              Navigator.pop(dialogContext, true);
            },
            child: Text(
              'Send',
              style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
            ),
          ),
        ],
      ),
    );
    if (reported != true || !mounted) return;
    final ok = await provider.reportUser(profile.id, controller.text.trim());
    if (!mounted) return;
    showActionToast(
      context,
      ok ? 'Reported' : t.error_something_wrong,
      isError: !ok,
    );
  }

  Future<void> _confirmBlock() async {
    final provider = Provider.of<ChatProvider>(context, listen: false);
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Theme.of(dialogContext).brightness == Brightness.dark
            ? AppTheme.darkSurface
            : AppTheme.lightSurface,
        title: Text(
          'Block User',
          style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
        ),
        content: Text(
          'You will no longer see each other. Their messages will stop.',
          style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'Cancel',
              style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'Block',
              style: TextStyle(fontFamily: AppTheme.fontFor(isPersian)),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    final ok = await provider.blockUser(profile.id);
    if (!mounted) return;
    showActionToast(
      context,
      ok ? 'Blocked' : t.error_something_wrong,
      isError: !ok,
    );
  }
}
