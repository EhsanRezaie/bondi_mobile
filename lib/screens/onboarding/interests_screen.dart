// lib/screens/onboarding/interests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/onboarding_service.dart';
import '../../models/interest.dart';
import '../../utils/responsive.dart';
import 'prompts_screen.dart';

class InterestsScreen extends StatefulWidget {
  const InterestsScreen({super.key});

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  List<String> _selectedInterests = [];
  bool _isLoading = true;
  final bool _isSubmitting = false;
  String? _errorMessage;

  Map<String, List<Interest>> _groupedInterests = {};
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadInterests();
    _loadSavedInterests();
  }

  void _loadSavedInterests() {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboarding.interests != null) {
      _selectedInterests = List.from(onboarding.interests!);
    }
  }

  Future<void> _loadInterests() async {
    setState(() => _isLoading = true);
    try {
      final interests = await OnboardingService.getInterests();
      setState(() {
        _groupedInterests = _groupByCategory(interests);
        if (_groupedInterests.isNotEmpty) {
          _expandedCategories.add(_groupedInterests.keys.first);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load interests';
        _isLoading = false;
      });
    }
  }

  Map<String, List<Interest>> _groupByCategory(List<Interest> interests) {
    final map = <String, List<Interest>>{};
    for (final interest in interests) {
      final category = interest.category.isNotEmpty
          ? _formatCategory(interest.category)
          : 'Other';
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(interest);
    }
    return map;
  }

  String _formatCategory(String category) {
    final parts = category.split('_');
    return parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' & ');
  }

  void _toggleInterest(Interest interest) {
    setState(() {
      if (_selectedInterests.contains(interest.name)) {
        _selectedInterests.remove(interest.name);
      } else {
        _selectedInterests.add(interest.name);
      }
      _errorMessage = null;
    });
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  bool _isSelected(String interestName) {
    return _selectedInterests.contains(interestName);
  }

  Future<void> _handleNext() async {
    if (_selectedInterests.length < 8) {
      setState(() {
        _errorMessage = 'Please select at least 8 interests';
      });
      return;
    }

    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    onboarding.setInterests(_selectedInterests);
    onboarding.setStepIndex(3);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PromptsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    final int selectedCount = _selectedInterests.length;
    final bool isEnough = selectedCount >= 8;
    final int remaining = 8 - selectedCount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 20, color: onSurfaceColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Progress Bar - 5 steps, filled for steps 0, 1, 2 (Basic Info, Profile Details, Interests)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: index <= 2
                            ? primaryColor
                            : (isDark ? Colors.white12 : Colors.black12),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text(
                'Interests',
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(
                    !Localizations.localeOf(
                      context,
                    ).languageCode.contains('en'),
                  ),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurfaceColor,
                  letterSpacing: -0.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: AppLayout.box(
            context: context,
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 16),
                              // Header
                              Text(
                                'What are your interests?',
                                style: AppTheme.headlineMedium.copyWith(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select at least 8 interests that represent you',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: textMutedColor,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Error Message
                              if (_errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: errorColor.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: errorColor.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: errorColor,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFor(
                                              !Localizations.localeOf(
                                                context,
                                              ).languageCode.contains('en'),
                                            ),
                                            fontSize: 14,
                                            color: errorColor,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (_errorMessage != null)
                                const SizedBox(height: 16),

                              // Progress indicator
                              Container(
                                width: double.infinity,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: FractionallySizedBox(
                                  widthFactor: selectedCount.clamp(0, 8) / 8,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isEnough
                                          ? Colors.green
                                          : primaryColor,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Counter text below progress bar
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Selected: $selectedCount',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFor(
                                        !Localizations.localeOf(
                                          context,
                                        ).languageCode.contains('en'),
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isEnough
                                          ? Colors.green
                                          : textMutedColor,
                                    ),
                                  ),
                                  Text(
                                    isEnough
                                        ? '✅ Great!'
                                        : '$remaining more needed',
                                    style: TextStyle(
                                      fontFamily: AppTheme.fontFor(
                                        !Localizations.localeOf(
                                          context,
                                        ).languageCode.contains('en'),
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: isEnough
                                          ? Colors.green
                                          : textMutedColor,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Interests List
                              if (_isLoading)
                                const Center(child: CircularProgressIndicator())
                              else if (_groupedInterests.isEmpty)
                                Center(
                                  child: Text(
                                    'No interests available',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: textMutedColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (!_isLoading && _groupedInterests.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Column(
                            children: _groupedInterests.keys.map((category) {
                              return _buildCategorySection(
                                category,
                                _groupedInterests[category]!,
                                primaryColor,
                                surfaceColor,
                                borderColor,
                                textMutedColor,
                                onSurfaceColor,
                                isDark,
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 16.0),
                  child: AppTheme.gradientButton(
                    enabled: isEnough && !_isSubmitting,
                    onPressed: _isSubmitting || !isEnough ? null : _handleNext,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  isEnough
                                      ? 'Continue'
                                      : 'Select ${8 - selectedCount} more',
                                  style: AppTheme.button.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                                if (isEnough) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ],
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
    String category,
    List<Interest> interests,
    Color primaryColor,
    Color surfaceColor,
    Color borderColor,
    Color textMutedColor,
    Color onSurfaceColor,
    bool isDark,
  ) {
    final isExpanded = _expandedCategories.contains(category);
    final selectedInCategory = interests
        .where((i) => _isSelected(i.name))
        .length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _toggleCategory(category),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: AppTheme.titleMedium.copyWith(
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (selectedInCategory > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$selectedInCategory',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(
                            !Localizations.localeOf(
                              context,
                            ).languageCode.contains('en'),
                          ),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: textMutedColor,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: interests.map((interest) {
                  final isSelected = _isSelected(interest.name);
                  return GestureDetector(
                    onTap: () => _toggleInterest(interest),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : surfaceColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isSelected ? primaryColor : borderColor,
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (interest.icon != null)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text(
                                interest.icon!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          Text(
                            _formatInterestName(interest.name),
                            style: TextStyle(
                              fontFamily: AppTheme.fontFor(
                                !Localizations.localeOf(
                                  context,
                                ).languageCode.contains('en'),
                              ),
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected ? Colors.white : onSurfaceColor,
                            ),
                          ),
                          if (isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _formatInterestName(String name) {
    return name
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
