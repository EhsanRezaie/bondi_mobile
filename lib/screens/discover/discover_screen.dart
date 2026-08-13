import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/discover_provider.dart';
import 'package:dating_app/services/onboarding_service.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/widgets/user_card.dart';
import 'package:dating_app/widgets/discover_action_button.dart';
import 'package:dating_app/screens/discover/profile_detail_screen.dart';
import 'package:dating_app/screens/shared/profile_detail_loader.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/widgets/action_toast.dart';

class DiscoverScreen extends StatefulWidget {
  final VoidCallback? onSwitchToChats;

  const DiscoverScreen({super.key, this.onSwitchToChats});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  Map<String, String> _interestIcons = {};
  UserCardState? _currentCardState;
  bool _isSwiping = false;

  void _onCardReady(UserCardState state) {
    _currentCardState = state;
  }

  @override
  void initState() {
    super.initState();
    _loadInterestIcons();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DiscoverProvider>(context, listen: false);
      if (provider.profiles.isEmpty) {
        provider.loadProfiles();
      }
    });
  }

  Future<void> _loadInterestIcons() async {
    final interests = await OnboardingService.getInterests();
    if (!mounted) return;
    final map = <String, String>{};
    for (final i in interests) {
      if (i.icon != null && i.icon!.isNotEmpty) {
        map[i.name] = i.icon!;
      }
    }
    setState(() {
      _interestIcons = map;
    });
  }

  Future<void> _handleSwipeRight(DiscoverProfile profile) async {
    if (!mounted) return;
    final provider = Provider.of<DiscoverProvider>(context, listen: false);
    if (provider.isLikeBlocked) {
      _showLimitReached('likes');
      return;
    }

    _isSwiping = true;
    if (mounted) setState(() {});
    try {
      final result = await provider.swipeRight(profile);
      if (!mounted) return;
      if (result == null) {
        await _waitForAnimation(_currentCardState?.snapBack());
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.error_something_wrong, isError: true);
        return;
      }
      if (result['matched'] == true) {
        _showMatchDialog(result, profile);
      } else {
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.toast_like_sent);
      }
    } finally {
      if (mounted) {
        _isSwiping = false;
        setState(() {});
      }
    }
  }

  Future<void> _handleSwipeLeft(DiscoverProfile profile) async {
    if (!mounted) return;
    final provider = Provider.of<DiscoverProvider>(context, listen: false);

    _isSwiping = true;
    if (mounted) setState(() {});
    try {
      final ok = await provider.swipeLeft(profile);
      if (!mounted) return;
      if (!ok) {
        await _waitForAnimation(_currentCardState?.snapBack());
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.error_something_wrong, isError: true);
      }
    } finally {
      if (mounted) {
        _isSwiping = false;
        setState(() {});
      }
    }
  }

  Future<void> _handleChat(DiscoverProfile profile) async {
    if (!mounted) return;
    final provider = Provider.of<DiscoverProvider>(context, listen: false);
    if (provider.isChatBlocked) {
      _showLimitReached('chats');
      return;
    }
    final message = await _showChatBottomSheet();
    if (message == null) return;
    if (!mounted) return;

    final result = await provider.swipeAndChat(profile, message: message);
    if (!mounted) return;

    final chatId = (result?['chat_id'] ?? result?['chatId'] ?? '').toString();
    if (chatId.isNotEmpty) {
      _openChat(chatId, profile);
    } else {
      final t = AppLocalizations.of(context)!;
      showActionToast(context, t.error_something_wrong, isError: true);
    }
  }

  void _openChat(String chatId, DiscoverProfile profile) {
    Navigator.push(
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
  }

  Future<void> _waitForAnimation(Future<void>? future) async {
    if (future == null) return;
    try {
      await future.timeout(const Duration(milliseconds: 600));
    } catch (_) {
      // Animation interrupted or disposed — never block the swipe state.
    }
  }

  Future<void> _onLikePressed(DiscoverProfile profile) async {
    if (_isSwiping || !mounted) return;
    final provider = Provider.of<DiscoverProvider>(context, listen: false);
    if (provider.isLikeBlocked) {
      _showLimitReached('likes');
      return;
    }

    _isSwiping = true;
    if (mounted) setState(() {});

    // Start animation immediately
    final animationFuture = _currentCardState?.swipeOut(1);

    try {
      final result = await provider.swipeRight(profile);
      if (!mounted) return;

      if (result != null) {
        // API succeeded - wait for animation to complete
        await _waitForAnimation(animationFuture);
        if (!mounted) return;
        if (result['matched'] == true) {
          _showMatchDialog(result, profile);
        } else {
          final t = AppLocalizations.of(context)!;
          showActionToast(context, t.toast_like_sent);
        }
      } else {
        // API returned null (error) - snap back
        await _waitForAnimation(_currentCardState?.snapBack());
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.error_something_wrong, isError: true);
      }
    } catch (e) {
      // API threw - snap back
      await _waitForAnimation(_currentCardState?.snapBack());
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      showActionToast(context, t.error_something_wrong, isError: true);
    } finally {
      if (mounted) {
        _isSwiping = false;
        setState(() {});
      }
    }
  }

  Future<void> _onPassPressed(DiscoverProfile profile) async {
    if (_isSwiping || !mounted) return;

    _isSwiping = true;
    if (mounted) setState(() {});

    // Start animation immediately
    final animationFuture = _currentCardState?.swipeOut(-1);

    try {
      final ok = await Provider.of<DiscoverProvider>(
        context,
        listen: false,
      ).swipeLeft(profile);
      if (!mounted) return;

      if (ok) {
        // API succeeded - wait for animation to complete
        await _waitForAnimation(animationFuture);
      } else {
        // API failed - snap back
        await _waitForAnimation(_currentCardState?.snapBack());
        if (!mounted) return;
        final t = AppLocalizations.of(context)!;
        showActionToast(context, t.error_something_wrong, isError: true);
      }
    } catch (e) {
      // API threw - snap back
      await _waitForAnimation(_currentCardState?.snapBack());
      if (!mounted) return;
      final t = AppLocalizations.of(context)!;
      showActionToast(context, t.error_something_wrong, isError: true);
    } finally {
      if (mounted) {
        _isSwiping = false;
        setState(() {});
      }
    }
  }

  Future<void> _onChatPressed(DiscoverProfile profile) async {
    if (_isSwiping || !mounted) return;
    final provider = Provider.of<DiscoverProvider>(context, listen: false);
    if (provider.isChatBlocked) {
      _showLimitReached('chats');
      return;
    }
    final message = await _showChatBottomSheet();
    if (message == null) return;
    if (!mounted) return;

    final result = await provider.swipeAndChat(profile, message: message);
    if (!mounted) return;

    final chatId = (result?['chat_id'] ?? result?['chatId'] ?? '').toString();
    if (chatId.isNotEmpty) {
      _openChat(chatId, profile);
    } else {
      final t = AppLocalizations.of(context)!;
      showActionToast(context, t.error_something_wrong, isError: true);
    }
  }

  void _showLimitReached(String type) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          t.discover_limit_reached_title,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
        content: Text(
          type == 'likes'
              ? t.discover_limit_reached_likes
              : t.discover_limit_reached_chats,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
            color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'OK',
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showChatBottomSheet() async {
    final t = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = ctx.isDarkMode;
        return StatefulBuilder(
          builder: (ctx, setState) {
            final controller = TextEditingController();
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.darkSurface : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
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
                            color: isDark
                                ? AppTheme.darkBorder
                                : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        t.discover_say_something,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppTheme.darkText
                              : AppTheme.lightText,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        maxLength: 200,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: t.discover_send_message_hint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, controller.text),
                          child: Text(t.discover_send_and_like),
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

  void _showMatchDialog(
    Map<String, dynamic> result,
    DiscoverProfile profile, {
    bool messageSent = false,
  }) {
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final heroStyle =
        (isPersian ? AppTheme.heroDisplayFa : AppTheme.heroDisplay).copyWith(
          fontSize: 30,
        );
    final bodyStyle = (isPersian ? AppTheme.bodyFa : AppTheme.body).copyWith(
      color: Colors.white.withValues(alpha: 0.85),
      fontSize: 15,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
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
                              errorBuilder: (_, _, _) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 56),
                Text(
                  t.discover_match_title,
                  textAlign: TextAlign.center,
                  style: heroStyle.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  t.discover_match_subtitle(profile.name),
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
                        t.discover_match_message_sent,
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
                      if (mounted) {
                        _switchToChatsTab();
                      }
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
                      t.discover_send_message,
                      style: (isPersian ? AppTheme.buttonFa : AppTheme.button)
                          .copyWith(color: AppTheme.primaryGradientStart),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(
                    t.discover_keep_swiping,
                    style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                        .copyWith(color: Colors.white, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProfileDetail(DiscoverProfile profile) {
    final provider = Provider.of<DiscoverProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailLoader(
          userId: profile.id,
          builder: (full) => ProfileDetailScreen(
            profile: full,
            interestIcons: _interestIcons,
            likesRemaining: provider.likesRemaining,
            chatsRemaining: provider.chatsRemaining,
            isPremium: provider.isPremium,
            onSwipeLeft: () async {
              await _handleSwipeLeft(full);
            },
            onSwipeRight: () async {
              await _handleSwipeRight(full);
            },
            onChat: () async {
              await _handleChat(full);
            },
          ),
        ),
      ),
    );
  }

  void _switchToChatsTab() {
    widget.onSwitchToChats?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<DiscoverProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.profiles.isEmpty) {
            return _buildLoadingState(t, isDark, primaryColor);
          }

          if (provider.errorMessage != null && provider.profiles.isEmpty) {
            return _buildErrorState(provider, t, isDark, primaryColor);
          }

          if (!provider.hasProfiles) {
            return _buildEmptyState(provider, t, isDark, primaryColor);
          }

          // Mode A: photo flush to the screen edges. A top scrim hosts the
          // tune filter icon; the floating circular actions hover the bottom.
          return _buildFullBleedDeck(provider, t, isDark);
        },
      ),
    );
  }

  Widget _buildFullBleedDeck(
    DiscoverProvider provider,
    AppLocalizations t,
    bool isDark,
  ) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildCardStack(provider, isDark),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildTopOverlay(provider, t, isDark),
        ),
        if (provider.visibleProfiles.isNotEmpty)
          Positioned(
            left: 0,
            right: 0,
            bottom: AppLayout.discoverActionRowBottom,
            child: _buildActionButtons(provider, t, isDark),
          ),
      ],
    );
  }

  Widget _buildTopOverlay(
    DiscoverProvider provider,
    AppLocalizations t,
    bool isDark,
  ) {
    final activeFilters = (provider.genderFilter != null ? 1 : 0) +
        (provider.ageMax != null ? 1 : 0) +
        (provider.distanceKm != null ? 1 : 0);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withValues(alpha: 0.45), Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white, size: 28),
                    onPressed: () => _openDiscoverFilters(provider),
                  ),
                  if (activeFilters > 0)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$activeFilters',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: Icon(
                  Icons.undo,
                  color: provider.canRevert
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.35),
                  size: 28,
                ),
                tooltip: t.discover_revert_pass,
                onPressed: provider.canRevert
                    ? () => _onRevertPass(provider)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onRevertPass(DiscoverProvider provider) {
    provider.revertPass();
  }

void _openDiscoverFilters(DiscoverProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DiscoverFilterSheet(provider: provider),
    );
  }

  Widget _buildLoadingState(
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            t.discover_loading,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 14,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    DiscoverProvider provider,
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off,
              size: 48,
              color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
            ),
            const SizedBox(height: 16),
            Text(
              provider.errorMessage ?? t.error_something_wrong,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 14,
                color: isDark
                    ? AppTheme.darkTextMuted
                    : AppTheme.lightTextMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => provider.refresh(),
              icon: const Icon(Icons.refresh),
              label: Text(t.discover_try_again),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    DiscoverProvider provider,
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
  ) {
    final canWiden = provider.canWidenDistance || provider.canWidenAge;
    final activeFilters = (provider.genderFilter != null ? 1 : 0) +
        (provider.ageMax != null ? 1 : 0) +
        (provider.distanceKm != null ? 1 : 0);

    return Stack(
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  canWiden ? Icons.explore_off : Icons.person_search,
                  size: 64,
                  color: isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted,
                ),
                const SizedBox(height: 16),
                Text(
                  canWiden ? t.discover_widen_title : t.discover_no_profiles,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  canWiden
                      ? t.discover_widen_subtitle
                      : t.discover_no_profiles_hint,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.darkTextMuted
                        : AppTheme.lightTextMuted,
                  ),
                ),
                if (canWiden) ...[
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      if (provider.canWidenDistance)
                        _buildWidenButton(
                          label: t.discover_widen_distance(10),
                          icon: Icons.near_me,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          onTap: () => provider.widenDistance(),
                        ),
                      if (provider.canWidenAge)
                        _buildWidenButton(
                          label: t.discover_widen_age(2),
                          icon: Icons.cake_outlined,
                          isDark: isDark,
                          primaryColor: primaryColor,
                          onTap: () => provider.widenAge(),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.only(top: 8, left: 8, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(
                          Icons.tune,
                          color: isDark ? AppTheme.darkText : AppTheme.lightText,
                          size: 28,
                        ),
                        onPressed: () => _openDiscoverFilters(provider),
                      ),
                      if (activeFilters > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Center(
                              child: Text(
                                '$activeFilters',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWidenButton({
    required String label,
    required IconData icon,
    required bool isDark,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark
              ? primaryColor.withValues(alpha: 0.15)
              : primaryColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: primaryColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardStack(DiscoverProvider provider, bool isDark) {
    final cards = provider.visibleProfiles;
    if (cards.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalMargin = EdgeInsets.symmetric(
          // Mode A: photo is flush to the screen edges. On tablets the deck is
          // still capped to a comfortable card width and centered.
          horizontal: switch (constraints.maxWidth) {
            final w when w >= Breakpoints.tablet =>
              (constraints.maxWidth - 520) / 2,
            _ => 0,
          },
        );

        return Container(
          height: constraints.maxHeight,
          margin: horizontalMargin,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Build back cards first so they sit behind the top card. They
              // are full-size so the next profile is already covering the whole
              // screen the moment the current card starts moving — no black gap.
              for (var i = cards.length - 1; i >= 0; i--)
                _buildStackedCard(provider, cards[i], i),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStackedCard(
    DiscoverProvider provider,
    DiscoverProfile profile,
    int index,
  ) {
    final isTop = index == 0;
    return UserCard(
      key: ValueKey(profile.id),
      profile: profile,
      interestIcons: _interestIcons,
      isTop: isTop,
      onTap: isTop ? () => _openProfileDetail(profile) : null,
      onSwipeLeft: isTop ? () => _handleSwipeLeft(profile) : null,
      onSwipeRight: isTop ? () => _handleSwipeRight(profile) : null,
      onSwipeStarted: isTop ? _onSwipeStarted : null,
      onCardReady: isTop ? _onCardReady : null,
    );
  }

  void _onSwipeStarted(bool isRight) {
    // A finger swipe committed — lock all actions (like/pass/chat) until the
    // API responds, so a second action can't race the in-flight one.
    if (_isSwiping || !mounted) return;
    _isSwiping = true;
    setState(() {});
  }

  Widget _buildActionButtons(
    DiscoverProvider provider,
    AppLocalizations t,
    bool isDark,
  ) {
    final profile = provider.visibleProfiles.isNotEmpty
        ? provider.visibleProfiles.first
        : null;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DiscoverActionButton(
            icon: Icons.close_rounded,
            gradient: AppTheme.rejectGradient(isDark: isDark),
            size: 56,
            onPressed: _isSwiping ? null : () => _onPassPressed(profile),
          ),
          const SizedBox(width: 20),
          DiscoverActionButton(
            icon: Icons.chat_bubble_rounded,
            backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
            iconColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            borderColor: isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary,
            size: 62,
            badgeCount: provider.isPremium ? null : provider.chatsRemaining,
            onPressed: _isSwiping || provider.isChatBlocked
                ? null
                : () => _onChatPressed(profile),
          ),
          const SizedBox(width: 20),
          DiscoverActionButton(
            icon: Icons.favorite_rounded,
            gradient: AppTheme.likeGradient(isDark: isDark),
            size: 56,
            badgeCount: provider.isPremium ? null : provider.likesRemaining,
            onPressed: _isSwiping || provider.isLikeBlocked
                ? null
                : () => _onLikePressed(profile),
          ),
        ],
      ),
    );
  }
}

class _DiscoverFilterSheet extends StatefulWidget {
  final DiscoverProvider provider;

  const _DiscoverFilterSheet({required this.provider});

  @override
  State<_DiscoverFilterSheet> createState() => _DiscoverFilterSheetState();
}

class _DiscoverFilterSheetState extends State<_DiscoverFilterSheet> {
  late String? _gender;
  late int _ageMin;
  late int? _ageMax;
  late double _distance;

  @override
  void initState() {
    super.initState();
    _gender = widget.provider.genderFilter;
    _ageMin = widget.provider.ageMin;
    _ageMax = (widget.provider.ageMax ?? 80) > 80 ? null : widget.provider.ageMax;
    _distance = (widget.provider.distanceKm ?? 500).toDouble().clamp(1.0, 500.0);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final isPersian = !Localizations.localeOf(context).languageCode.contains('en');
    final font = AppTheme.fontFor(isPersian);

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Stack(
            children: [
              Column(
                children: [
                  // Drag handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.darkBorder : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          t.discover_filter_show,
                          style: TextStyle(
                            fontFamily: font,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            widget.provider.resetFilters();
                            Navigator.pop(context);
                          },
                          child: Text(
                            t.search_reset_filters,
                            style: TextStyle(fontFamily: font, color: mutedColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Content
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                      children: [
                        _buildSectionHeader('👤', t.search_filter_gender, primaryColor),
                        _buildChipRow(
                          options: ['all', 'male', 'female'],
                          selected: _gender,
                          onTap: (v) => setState(() => _gender = v),
                          isDark: isDark,
                          primaryColor: primaryColor,
                          textColor: textColor,
                          labelBuilder: (v) => v == 'all'
                              ? t.discover_filter_all
                              : v == 'male'
                                  ? t.discover_filter_male
                                  : t.discover_filter_female,
                        ),
                        _buildSectionHeader('🎂', t.search_filter_age_range, primaryColor),
                        Text(
                          '$_ageMin - ${_ageMax ?? 80}+',
                          style: TextStyle(fontFamily: font, fontSize: 14, color: textColor),
                        ),
                        RangeSlider(
                          values: RangeValues(_ageMin.toDouble(), (_ageMax ?? 80).toDouble()),
                          min: 18,
                          max: 80,
                          divisions: 62,
                          activeColor: primaryColor,
                          inactiveColor: primaryColor.withValues(alpha: 0.2),
                          onChanged: (v) => setState(() {
                            _ageMin = v.start.round();
                            _ageMax = v.end.round() == 80 ? null : v.end.round();
                          }),
                        ),
                        _buildSectionHeader('📏', t.search_filter_distance_km, primaryColor),
                        Text(
                          _distance >= 500 ? '500+ km' : '${_distance.round()} km',
                          style: TextStyle(fontFamily: font, fontSize: 14, color: textColor),
                        ),
                        Slider(
                          value: _distance,
                          min: 1,
                          max: 500,
                          divisions: 499,
                          activeColor: primaryColor,
                          inactiveColor: primaryColor.withValues(alpha: 0.2),
                          onChanged: (v) => setState(() => _distance = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Floating apply button (content scrolls behind it)
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom > 0 ? 16 : 20,
                child: AppTheme.gradientButton(
                  onPressed: _applyFilters,
                  child: Text(
                    t.discover_filter_apply,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyFilters() {
    final apiMax = _ageMax != null && _ageMax! < 80 ? _ageMax : null;
    final apiDistance = _distance >= 500 ? null : _distance.round();
    widget.provider.setGenderFilter(_gender);
    widget.provider.setAgeRange(_ageMin, apiMax);
    widget.provider.setDistance(apiDistance);
    Navigator.pop(context);
  }

  Widget _buildSectionHeader(String emoji, String title, Color primaryColor) {
    final isPersian = !Localizations.localeOf(context).languageCode.contains('en');
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold).copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChipRow({
    required List<String> options,
    required String? selected,
    required ValueChanged<String?> onTap,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    String Function(String)? labelBuilder,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected =
            selected == option || (option == 'all' && selected == null);
        final label = labelBuilder != null
            ? labelBuilder(option)
            : option.replaceAll('_', ' ');
        return GestureDetector(
          onTap: () => onTap(isSelected ? null : (option == 'all' ? null : option)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? primaryColor
                  : isDark
                      ? AppTheme.darkSecondary.withValues(alpha: 0.4)
                      : Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              border: Border.all(
                color: isSelected
                    ? primaryColor
                    : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
              ),
            ),
            child: Text(
              label[0].toUpperCase() + label.substring(1),
              style: TextStyle(
                fontFamily: AppTheme.fontFor(
                  !Localizations.localeOf(context).languageCode.contains('en'),
                ),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? AppTheme.darkText
                        : AppTheme.lightText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
