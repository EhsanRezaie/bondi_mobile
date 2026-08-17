import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/search_provider.dart';
import 'package:dating_app/services/onboarding_service.dart';
import 'package:dating_app/utils/responsive.dart';
import 'package:dating_app/widgets/search_grid_card.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';
import 'package:dating_app/screens/shared/profile_detail_loader.dart';
import 'package:dating_app/screens/chats/notifications_screen.dart';
import 'package:dating_app/widgets/notification_bell.dart';
import 'search_filter_sheet.dart';
import 'search_profile_detail.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with WidgetsBindingObserver {
  Map<String, String> _interestIcons = {};
  final ScrollController _scrollController = ScrollController();

  void refreshLimits() {
    if (!mounted) return;
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.refreshLimits();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadInterestIcons();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<SearchProvider>(context, listen: false);
      if (provider.users.isEmpty && !provider.isLoading) {
        provider.loadProfiles();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      refreshLimits();
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<SearchProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.loadMore();
      }
    }
  }

  Future<void> _loadInterestIcons() async {
    try {
      final interests = await OnboardingService.getInterests();
      if (mounted) {
        setState(() {
          _interestIcons = {
            for (var i in interests) i.name: i.icon ?? '',
          };
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          t.search_title,
          style: (isPersian ? AppTheme.h2Fa : AppTheme.h2).copyWith(
            fontSize: 20,
            color: textColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Consumer<SearchProvider>(
          builder: (context, provider, _) {
            final count = provider.activeFilterCount;
            return IconButton(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.tune, color: textColor),
                  if (count > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.accentLike,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              onPressed: () => _openFilterSheet(context),
            );
          },
        ),
        actions: [
          NotificationBell(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.users.isEmpty) {
                  return _buildLoadingGrid(isDark);
                }
                if (provider.errorMessage != null) {
                  return _buildErrorState(provider, isDark, primaryColor);
                }
                if (provider.users.isEmpty) {
                  return _buildEmptyState(provider, isDark, primaryColor);
                }
                return _buildGrid(provider, isDark, primaryColor, textColor);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGrid(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.58,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 9,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppTheme.radiusModule),
              color: isDark ? AppTheme.darkSecondary : Colors.grey.shade200,
            ),
            child: const ShimmerAvatar(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState(SearchProvider provider, bool isDark, Color primaryColor) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return RefreshIndicator(
      onRefresh: () => provider.loadProfiles(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 64,
                    color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    provider.errorMessage ?? 'Error',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(isPersian),
                      fontSize: 16,
                      color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTheme.gradientButton(
                    onPressed: () => provider.refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(SearchProvider provider, bool isDark, Color primaryColor) {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return RefreshIndicator(
      onRefresh: () => provider.loadProfiles(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 64,
                    color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.search_no_results,
                    style: (isPersian ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t.search_no_results_hint,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(isPersian),
                      fontSize: 14,
                      color: isDark ? AppTheme.darkTextMuted : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTheme.gradientButton(
                    onPressed: () => provider.refresh(),
                    child: Text(t.discover_refresh),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    SearchProvider provider,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final itemCount = provider.users.length + (provider.hasMore ? 1 : 0);
    return RefreshIndicator(
      onRefresh: () => provider.loadProfiles(),
      child: GridView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          8,
          8,
          8,
          AppLayout.floatingNavClearance,
        ),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          // Auto-switches column count with width (3 on phones -> more on
          // tablets) while keeping cards a usable size.
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 0.58,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index == provider.users.length) {
            if (!provider.isLoadingMore) {
              return const SizedBox.shrink();
            }
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            );
          }
          return SearchGridCard(
            profile: provider.users[index],
            onTap: () => _openProfileDetail(provider.users[index]),
          );
        },
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: Provider.of<SearchProvider>(context, listen: false),
        child: const SearchFilterSheet(),
      ),
    );
  }

  void _openProfileDetail(DiscoverProfile profile) {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfileDetailLoader(
          userId: profile.id,
          builder: (full) => SearchProfileDetail(
            profile: full,
            interestIcons: _interestIcons,
            likesRemaining: provider.likesRemaining,
            chatsRemaining: provider.chatsRemaining,
            isPremium: provider.isPremium,
            onLike: (p) => provider.likeUser(p),
            onChat: (p, {message}) => provider.chatWithUser(p, message: message),
          ),
        ),
      ),
    );
  }
}
