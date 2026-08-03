import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';
import 'package:dating_app/widgets/discover_action_button.dart';
import 'package:dating_app/widgets/action_toast.dart';

class SearchProfileDetail extends StatefulWidget {
  final DiscoverProfile profile;
  final Map<String, String> interestIcons;
  final int? likesRemaining;
  final int? chatsRemaining;
  final bool isPremium;
  final Future<Map<String, dynamic>?> Function(DiscoverProfile)? onLike;
  final Future<Map<String, dynamic>?> Function(DiscoverProfile, {String? message})? onChat;

  const SearchProfileDetail({
    super.key,
    required this.profile,
    this.interestIcons = const {},
    this.likesRemaining,
    this.chatsRemaining,
    this.isPremium = false,
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

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;

    final photos = allPhotos;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildHeaderSection(
                      t, isDark, primaryColor, mutedColor, textColor, surfaceColor, borderColor, photos,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildBodySection(
                      t, isDark, primaryColor, mutedColor, textColor, surfaceColor, borderColor,
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: SizedBox(height: 80),
                  ),
                ],
              ),
            ),
            _buildBottomActionBar(t, isDark),
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
    return Column(
      children: [
        Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.42,
              width: double.infinity,
                child: photos.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photos[_currentPhotoIndex],
                      fit: BoxFit.cover,
                      placeholder: (context, url) => const ShimmerAvatar(),
                      errorWidget: (context, url, error) => Container(
                        color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                        child: Icon(Icons.person, size: 80,
                            color: isDark ? AppTheme.darkTextMuted : Colors.grey),
                      ),
                    )
                  : Container(
                      color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                      child: Icon(Icons.person, size: 80,
                          color: isDark ? AppTheme.darkTextMuted : Colors.grey),
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 22),
                ),
              ),
            ),
            if (photos.length > 1)
              Positioned(
                bottom: 60,
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
                        width: _currentPhotoIndex == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPhotoIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(4),
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
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${profile.age}',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        profile.gender == 'male' ? Icons.male : Icons.female,
                        size: 20,
                        color: profile.gender == 'male'
                            ? (isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary)
                            : (isDark ? AppTheme.darkError : AppTheme.lightError),
                      ),
                      if (profile.isPremium) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isDark ? AppTheme.darkError : AppTheme.lightError,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium, size: 12, color: Colors.white),
                              const SizedBox(width: 3),
                              Text(t.discover_premium,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (profile.distanceKm != null) ...[
                        Icon(Icons.near_me, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          t.discover_km_away(profile.distanceKm!.round()),
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (profile.locationDisplay.isNotEmpty) ...[
                        Icon(Icons.location_on, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                        const SizedBox(width: 4),
                        Text(
                          profile.locationDisplay,
                          style: TextStyle(
                            fontFamily: 'Inter',
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
                            color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.verified, size: 14, color: Colors.white),
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
            height: 64,
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
                    width: 56,
                    height: 56,
                    margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? primaryColor : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: photos[index],
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
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
            _buildBioSection(t, isDark, primaryColor, mutedColor, textColor, surfaceColor, borderColor),
          _buildChipSection(
            emoji: '💪',
            title: t.profile_section_physical,
            chips: [
              if (profile.height != null)
                _buildValueChip('📏', '${profile.height} cm', isDark, textColor, borderColor),
              if (profile.weight != null)
                _buildValueChip('⚖️', '${profile.weight} kg', isDark, textColor, borderColor),
              if (profile.bodyType != null)
                _buildValueChip('💪', _capitalize(profile.bodyType!), isDark, textColor, borderColor),
            ],
          ),
          _buildChipSection(
            emoji: '🏠',
            title: t.profile_section_lifestyle,
            chips: [
              if (profile.relationshipStatus != null)
                _buildValueChip('❤️', _capitalize(profile.relationshipStatus!), isDark, textColor, borderColor),
              if (profile.livingSituation != null)
                _buildValueChip('🏠', _formatLiving(profile.livingSituation!), isDark, textColor, borderColor),
              if (profile.childrenStatus != null)
                _buildValueChip('👶', _formatChildren(profile.childrenStatus!), isDark, textColor, borderColor),
              if (profile.smoking != null)
                _buildValueChip('🚬', _capitalize(profile.smoking!), isDark, textColor, borderColor),
              if (profile.drinking != null)
                _buildValueChip('🍷', _capitalize(profile.drinking!), isDark, textColor, borderColor),
            ],
          ),
          _buildChipSection(
            emoji: '🌍',
            title: t.profile_section_background,
            chips: [
              if (profile.education != null)
                _buildValueChip('🎓', _formatEducation(profile.education!), isDark, textColor, borderColor),
              if (profile.workplace != null && profile.workplace!.isNotEmpty)
                _buildValueChip('💼', profile.workplace!, isDark, textColor, borderColor),
              if (profile.religion != null)
                _buildValueChip('☪️', _capitalize(profile.religion!), isDark, textColor, borderColor),
              if (profile.ethnicity != null)
                _buildValueChip('🌍', _capitalize(profile.ethnicity!), isDark, textColor, borderColor),
              if (profile.politicalOrientation != null)
                _buildValueChip('🗳️', _capitalize(profile.politicalOrientation!), isDark, textColor, borderColor),
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
                fontFamily: 'Inter',
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
              fontFamily: 'Inter',
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
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: context.isDarkMode ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chips,
        ),
      ],
    );
  }

  Widget _buildValueChip(String emoji, String value, bool isDark, Color textColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : (context.isDarkMode ? AppTheme.darkPrimary : AppTheme.lightPrimary).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$emoji $value',
        style: TextStyle(
          fontFamily: 'Inter',
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
                fontFamily: 'Inter',
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
                color: isDark ? Colors.white10 : primaryColor.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                icon != null ? '$icon $item' : item,
                style: TextStyle(
                  fontFamily: 'Inter',
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
                fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
                    fontFamily: 'Inter',
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
    final isLikeBlocked = !widget.isPremium && (widget.likesRemaining ?? 0) <= 0;
    final isChatBlocked = !widget.isPremium && (widget.chatsRemaining ?? 0) <= 0;
    final alreadyLiked = profile.currentUserAction == 'liked' || profile.currentUserAction == 'matched';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
            width: 0.5,
          ),
        ),
      ),
      padding: EdgeInsets.only(
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom > 0 ? 10 : 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoverActionButton(
            icon: Icons.chat_bubble_rounded,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            iconColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            borderColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            size: 58,
            badgeCount: widget.isPremium ? null : widget.chatsRemaining,
            onPressed: isChatBlocked ? null : () => _handleChat(),
          ),
          if (!alreadyLiked) ...[
            const SizedBox(width: 24),
            DiscoverActionButton(
              icon: Icons.favorite_rounded,
              gradient: AppTheme.likeGradient(isDark: isDark),
              size: 58,
              badgeCount: widget.isPremium ? null : widget.likesRemaining,
              onPressed: isLikeBlocked ? null : () => _handleLike(),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _handleLike() async {
    final isLikeBlocked = !widget.isPremium && (widget.likesRemaining ?? 0) <= 0;
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
    }
  }

  Future<void> _handleChat() async {
    final isChatBlocked = !widget.isPremium && (widget.chatsRemaining ?? 0) <= 0;
    if (isChatBlocked) {
      _showLimitReachedDialog('chats');
      return;
    }

    final message = await _showChatBottomSheet();
    if (message != null && mounted && widget.onChat != null) {
      final result = await widget.onChat!(profile, message: message);
      if (result != null && mounted) {
        if (result['matched'] == true) {
          _showMatchDialog(result);
        } else {
          final t = AppLocalizations.of(context)!;
          showActionToast(context, t.toast_like_and_message_sent);
          Navigator.pop(context);
        }
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
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Text(
          type == 'likes' ? t.search_limit_reached_likes : t.search_limit_reached_chats,
          style: TextStyle(
            fontFamily: 'Inter',
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
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            final messageController = TextEditingController();
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
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
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    maxLength: 200,
                    style: TextStyle(fontFamily: 'Inter', color: isDark ? AppTheme.darkText : AppTheme.lightText),
                    decoration: InputDecoration(
                      hintText: t.discover_send_message_hint,
                      hintStyle: TextStyle(
                        color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                      ),
                      filled: true,
                      fillColor: isDark ? AppTheme.darkSecondary : Colors.grey.shade100,
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
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
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
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bool messageSent = result['message_sent'] == true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.likeGradient(isDark: isDark),
              ),
              child: const Icon(Icons.favorite, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              t.search_match_title,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? AppTheme.darkText : AppTheme.lightText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t.search_match_subtitle(profile.name),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 14,
                color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
              ),
            ),
            if (messageSent) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, size: 16, color: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess),
                  const SizedBox(width: 6),
                  Text(
                    t.search_match_message_sent,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: isDark ? AppTheme.darkSuccess : AppTheme.lightSuccess,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(t.search_continue_browsing),
              ),
            ),
          ],
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
      case 'alone': return 'Alone';
      case 'with_family': return 'With Family';
      case 'with_roommate': return 'With Roommates';
      case 'with_partner': return 'With Partner';
      default: return _capitalize(value);
    }
  }

  String _formatChildren(String value) {
    switch (value.toLowerCase()) {
      case 'have': return 'Have children';
      case 'dont_have': return "Don't have children";
      case 'want': return 'Want children';
      case 'dont_want': return "Don't want children";
      default: return _capitalize(value);
    }
  }

  String _formatEducation(String value) {
    switch (value.toLowerCase()) {
      case 'high_school': return 'High School';
      case 'bachelor': return 'Undergraduate Degree';
      case 'master': return 'Postgraduate Degree';
      case 'phd': return 'PhD / Doctorate';
      default: return _capitalize(value);
    }
  }
}
