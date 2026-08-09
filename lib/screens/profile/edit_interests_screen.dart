// lib/screens/profile/edit_interests_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/onboarding_service.dart';
import '../../models/interest.dart';
import '../../generated/app_localizations.dart';
import '../../utils/responsive.dart';
import '../../widgets/action_toast.dart';

class EditInterestsScreen extends StatefulWidget {
  const EditInterestsScreen({super.key});

  @override
  State<EditInterestsScreen> createState() => _EditInterestsScreenState();
}

class _EditInterestsScreenState extends State<EditInterestsScreen> {
  List<String> _selectedInterestNames = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  Map<String, List<Interest>> _groupedInterests = {};
  final Set<String> _expandedCategories = {};

  @override
  void initState() {
    super.initState();
    _loadUserInterests();
    _loadInterests();
  }

  void _loadUserInterests() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.interests != null) {
      _selectedInterestNames = List.from(user!.interests!);
    }
  }

  Future<void> _loadInterests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final interests = await OnboardingService.getInterests();
      if (!mounted) return;

      setState(() {
        _groupedInterests = _groupByCategory(interests);
        if (_groupedInterests.isNotEmpty) {
          _expandedCategories.add(_groupedInterests.keys.first);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    return parts.map((part) => part[0].toUpperCase() + part.substring(1)).join(' & ');
  }

  void _toggleInterest(Interest interest) {
    if (!mounted) return;
    setState(() {
      if (_selectedInterestNames.contains(interest.name)) {
        _selectedInterestNames.remove(interest.name);
      } else {
        _selectedInterestNames.add(interest.name);
      }
      _errorMessage = null;
    });
  }

  void _toggleCategory(String category) {
    if (!mounted) return;
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  bool _isSelected(String interestName) {
    return _selectedInterestNames.contains(interestName);
  }

  Future<void> _handleSave() async {
    final t = AppLocalizations.of(context)!;
    if (_selectedInterestNames.length < 8) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please select at least 8 interests';
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      debugPrint('📤 Sending interest names: $_selectedInterestNames');

      final success = await authProvider.updateInterests(_selectedInterestNames);

      if (success && mounted) {
        showActionToast(context, t.interests_updated_success);
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Failed to update interests';
          _isSaving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    final int selectedCount = _selectedInterestNames.length;
    final bool isEnough = selectedCount >= 8;
    final int remaining = 8 - selectedCount;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurfaceColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Interests',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurfaceColor,
            letterSpacing: -0.4,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: AppLayout.box(
            context: context,
            child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          Text(
                            'What are your interests?',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: onSurfaceColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Select at least 8 interests that represent you',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              color: textMutedColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: errorColor.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: errorColor.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: errorColor, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 14,
                                        color: errorColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_errorMessage != null) const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            height: 6,
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: FractionallySizedBox(
                              widthFactor: selectedCount.clamp(0, 8) / 8,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isEnough ? Colors.green : primaryColor,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Selected: $selectedCount',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isEnough ? Colors.green : textMutedColor,
                                ),
                              ),
                              Text(
                                isEnough ? '✅ Great!' : '$remaining more needed',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isEnough ? Colors.green : textMutedColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
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
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      alignment: Alignment.bottomCenter,
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving || !isEnough ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isEnough ? primaryColor : Colors.grey.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                            minimumSize: const Size(double.infinity, 56),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isEnough ? 'Save' : 'Select ${8 - selectedCount} more',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: isEnough ? Colors.white : Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
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
    final selectedInCategory = interests.where((i) => _isSelected(i.name)).length;

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
                  bottom: BorderSide(
                    color: borderColor,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      category,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: onSurfaceColor,
                      ),
                    ),
                  ),
                  if (selectedInCategory > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$selectedInCategory',
                        style: TextStyle(
                          fontFamily: 'Inter',
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
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
    return name.replaceAll('_', ' ').split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}