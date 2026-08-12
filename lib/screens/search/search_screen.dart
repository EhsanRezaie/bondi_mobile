import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/providers/search_provider.dart';
import 'package:dating_app/services/onboarding_service.dart';
import 'package:dating_app/widgets/search_grid_card.dart';
import 'package:dating_app/widgets/shimmer_avatar.dart';
import 'package:dating_app/screens/shared/profile_detail_loader.dart';
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
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
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
        actions: [
          Consumer<SearchProvider>(
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
        ],
      ),
      body: Column(
        children: [
          _buildQuickFilterBar(t, isDark, primaryColor, textColor, mutedColor, borderColor),
          const SizedBox(height: 8),
          Expanded(
            child: Consumer<SearchProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
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

  Widget _buildQuickFilterBar(
    AppLocalizations t,
    bool isDark,
    Color primaryColor,
    Color textColor,
    Color mutedColor,
    Color borderColor,
  ) {
    return Consumer<SearchProvider>(
      builder: (context, provider, _) {
        return Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildQuickChip(
                icon: Icons.wc,
                label: provider.genderFilter == null
                    ? t.discover_filter_all
                    : provider.genderFilter == 'male'
                        ? t.discover_filter_male
                        : t.discover_filter_female,
                isSelected: provider.genderFilter != null,
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                onTap: () => _showGenderPicker(context),
              ),
              const SizedBox(width: 8),
              _buildQuickChip(
                icon: Icons.cake_outlined,
                label: provider.ageMax != null
                    ? '${provider.ageMin}-${provider.ageMax}'
                    : '${provider.ageMin}-100+',
                isSelected: provider.ageMin != 18 || provider.ageMax != null,
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                onTap: () => _showAgePicker(context),
              ),
              const SizedBox(width: 8),
              _buildQuickChip(
                icon: Icons.near_me,
                label: provider.distanceKm != null
                    ? '${provider.distanceKm} km'
                    : '500+ km',
                isSelected: provider.distanceKm != null,
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                onTap: () => _showDistancePicker(context),
              ),
              const SizedBox(width: 8),
              _buildQuickChip(
                icon: Icons.sort,
                label: _getSortLabel(provider.sortBy, t),
                isSelected: provider.sortBy != 'recent',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                onTap: () => _showSortPicker(context),
              ),
              const SizedBox(width: 8),
              _buildQuickChip(
                icon: Icons.tune,
                label: t.search_advanced_filters,
                isSelected: provider.activeFilterCount > 0,
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                mutedColor: mutedColor,
                borderColor: borderColor,
                onTap: () => _openFilterSheet(context),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickChip({
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    required Color mutedColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    final fill = isSelected
        ? primaryColor.withValues(alpha: 0.16)
        : isDark
            ? AppTheme.darkSecondary.withValues(alpha: 0.55)
            : AppTheme.lightSecondary.withValues(alpha: 0.6);
    final fg = isSelected ? primaryColor : textColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.5)
                : borderColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? primaryColor : mutedColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                  .copyWith(
                fontSize: 13,
                color: fg,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getSortLabel(String sortBy, AppLocalizations t) {
    switch (sortBy) {
      case 'distance':
        return t.search_sort_distance;
      case 'age':
        return t.search_sort_age;
      case 'name':
        return t.search_sort_name;
      case 'last_seen':
        return t.search_sort_last_seen;
      default:
        return t.search_sort_recent;
    }
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
    return Center(
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
    );
  }

  Widget _buildEmptyState(SearchProvider provider, bool isDark, Color primaryColor) {
    final t = AppLocalizations.of(context)!;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return Center(
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
    );
  }

  Widget _buildGrid(
    SearchProvider provider,
    bool isDark,
    Color primaryColor,
    Color textColor,
  ) {
    final itemCount = provider.users.length + (provider.hasMore ? 1 : 0);
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    );
  }

  void _showGenderPicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = Provider.of<SearchProvider>(context, listen: false);
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  Text(
                    t.search_filter_gender,
                    style: (!Localizations.localeOf(context).languageCode.contains('en') ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChoiceChip(
                        label: t.discover_filter_all,
                        selected: provider.genderFilter == null,
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setGenderFilter(null);
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChoiceChip(
                        label: t.discover_filter_male,
                        selected: provider.genderFilter == 'male',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setGenderFilter('male');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChoiceChip(
                        label: t.discover_filter_female,
                        selected: provider.genderFilter == 'female',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setGenderFilter('female');
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAgePicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = Provider.of<SearchProvider>(context, listen: false);
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        double minAge = provider.ageMin.toDouble();
        double maxAge = (provider.ageMax ?? 100).toDouble();

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  Text(
                    t.search_filter_age_range,
                    style: (!Localizations.localeOf(context).languageCode.contains('en') ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t.discover_filter_years(minAge.round(), maxAge >= 100 ? 100 : maxAge.round()),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(
                        !Localizations.localeOf(
                          context,
                        ).languageCode.contains('en'),
                      ),
                      fontSize: 14,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  RangeSlider(
                    values: RangeValues(minAge, maxAge),
                    min: 18,
                    max: 100,
                    divisions: 82,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withValues(alpha: 0.2),
                    onChanged: (values) {
                      setSheetState(() {
                        minAge = values.start;
                        maxAge = values.end;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppTheme.gradientButton(
                      onPressed: () {
                        final apiMax = maxAge >= 100 ? null : maxAge.round();
                        provider.setAgeRange(minAge.round(), apiMax);
                        Navigator.pop(ctx);
                      },
                      child: Text(t.discover_filter_apply),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDistancePicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = Provider.of<SearchProvider>(context, listen: false);
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        double distance = (provider.distanceKm ?? 500).toDouble();

        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  Text(
                    t.search_filter_distance_km,
                    style: (!Localizations.localeOf(context).languageCode.contains('en') ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    distance >= 500 ? '500+ km' : t.discover_filter_km(distance.round()),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(
                        !Localizations.localeOf(
                          context,
                        ).languageCode.contains('en'),
                      ),
                      fontSize: 14,
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: distance,
                    min: 1,
                    max: 500,
                    divisions: 499,
                    activeColor: primaryColor,
                    inactiveColor: primaryColor.withValues(alpha: 0.2),
                    onChanged: (value) {
                      setSheetState(() {
                        distance = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: AppTheme.gradientButton(
                      onPressed: () {
                        final apiDistance = distance >= 500 ? null : distance.round();
                        provider.setDistance(apiDistance);
                        Navigator.pop(ctx);
                      },
                      child: Text(t.discover_filter_apply),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showSortPicker(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final provider = Provider.of<SearchProvider>(context, listen: false);
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(20),
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
                  const SizedBox(height: 16),
                  Text(
                    t.search_sort_by,
                    style: (!Localizations.localeOf(context).languageCode.contains('en') ? AppTheme.h2Fa : AppTheme.h2).copyWith(
                      color: isDark ? AppTheme.darkText : AppTheme.lightText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildChoiceChip(
                        label: t.search_sort_recent,
                        selected: provider.sortBy == 'recent',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setSortBy('recent');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChoiceChip(
                        label: t.search_sort_distance,
                        selected: provider.sortBy == 'distance',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setSortBy('distance');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChoiceChip(
                        label: t.search_sort_age,
                        selected: provider.sortBy == 'age',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setSortBy('age');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChoiceChip(
                        label: t.search_sort_name,
                        selected: provider.sortBy == 'name',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setSortBy('name');
                          Navigator.pop(ctx);
                        },
                      ),
                      _buildChoiceChip(
                        label: t.search_sort_last_seen,
                        selected: provider.sortBy == 'last_seen',
                        primaryColor: primaryColor,
                        onTap: () {
                          provider.setSortBy('last_seen');
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool selected,
    required Color primaryColor,
    required VoidCallback onTap,
  }) {
    final isDark = context.isDarkMode;
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? primaryColor
              : isDark
                  ? AppTheme.darkSecondary.withValues(alpha: 0.4)
                  : Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          border: Border.all(
            color: selected
                ? primaryColor
                : isDark
                    ? AppTheme.darkBorder
                    : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
              .copyWith(
            fontSize: 14,
            color: selected
                ? Colors.white
                : isDark
                    ? AppTheme.darkText
                    : Colors.grey.shade700,
          ),
        ),
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
