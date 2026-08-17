// lib/screens/onboarding/prompts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/onboarding_service.dart';
import '../../models/prompt.dart';
import '../../utils/responsive.dart';
import 'photo_upload_screen.dart';

class PromptsScreen extends StatefulWidget {
  const PromptsScreen({super.key});

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen> {
  List<Prompt> _allPrompts = [];
  Map<String, List<Prompt>> _groupedPrompts = {};
  List<Map<String, dynamic>> _selectedPrompts = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  final Set<String> _expandedCategories = {};

  final Map<String, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    _loadPrompts();
    _loadSavedPrompts();
  }

  void _loadSavedPrompts() {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboarding.prompts != null && onboarding.prompts!.isNotEmpty) {
      _selectedPrompts = List.from(onboarding.prompts!);
      for (final prompt in _selectedPrompts) {
        final promptId = prompt['prompt_id'] as String;
        _answerControllers[promptId] = TextEditingController(
          text: prompt['answer'] ?? '',
        );
      }
    }
  }

  Future<void> _loadPrompts() async {
    setState(() => _isLoading = true);
    try {
      final languageProvider = Provider.of<LanguageProvider>(
        context,
        listen: false,
      );
      final languageCode = languageProvider.locale.languageCode;

      final prompts = await OnboardingService.getPrompts(
        language: languageCode,
      );

      setState(() {
        _allPrompts = prompts.where((p) => p.isActive).toList();
        _groupedPrompts = _groupByCategory(_allPrompts);
        if (_groupedPrompts.isNotEmpty) {
          _expandedCategories.add(_groupedPrompts.keys.first);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load prompts';
        _isLoading = false;
      });
    }
  }

  Map<String, List<Prompt>> _groupByCategory(List<Prompt> prompts) {
    final map = <String, List<Prompt>>{};
    for (final prompt in prompts) {
      final category = prompt.category != null && prompt.category!.isNotEmpty
          ? _formatCategory(prompt.category!)
          : 'General';
      if (!map.containsKey(category)) {
        map[category] = [];
      }
      map[category]!.add(prompt);
    }
    return map;
  }

  String _formatCategory(String category) {
    final parts = category.split('_');
    return parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
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

  void _togglePrompt(Prompt prompt) {
    setState(() {
      final exists = _selectedPrompts.any((p) => p['prompt_id'] == prompt.id);
      if (exists) {
        _selectedPrompts.removeWhere((p) => p['prompt_id'] == prompt.id);
        _answerControllers[prompt.id]?.dispose();
        _answerControllers.remove(prompt.id);
        _errorMessage = null;
      } else {
        if (_selectedPrompts.length >= 3) {
          setState(() {
            _errorMessage = 'You can select up to 3 prompts';
          });
          return;
        }
        _selectedPrompts.add({'prompt_id': prompt.id, 'answer': ''});
        _answerControllers[prompt.id] = TextEditingController();
        _errorMessage = null;
      }
    });
  }

  void _updateAnswer(String promptId, String answer) {
    setState(() {
      final index = _selectedPrompts.indexWhere(
        (p) => p['prompt_id'] == promptId,
      );
      if (index != -1) {
        _selectedPrompts[index]['answer'] = answer;
      }
    });
  }

  bool _isPromptSelected(String promptId) {
    return _selectedPrompts.any((p) => p['prompt_id'] == promptId);
  }

  String? _getAnswer(String promptId) {
    final found = _selectedPrompts.firstWhere(
      (p) => p['prompt_id'] == promptId,
      orElse: () => <String, dynamic>{},
    );
    return found['answer'] as String?;
  }

  bool _isFormValid() {
    for (final prompt in _selectedPrompts) {
      final answer = prompt['answer'] as String?;
      if (answer == null || answer.trim().isEmpty) {
        return false;
      }
      if (answer.trim().length < 2) {
        return false;
      }
    }
    return true;
  }

  Future<void> _handleSubmit() async {
    if (_selectedPrompts.isNotEmpty && !_isFormValid()) {
      setState(() {
        _errorMessage = 'Please answer all selected prompts';
      });
      return;
    }

    await _completeOnboarding();
  }

  Future<void> _completeOnboarding() async {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    onboarding.setPrompts(_selectedPrompts);

    final data = onboarding.buildCompleteRequest();

    setState(() => _isSubmitting = true);

    final success = await authProvider.registerComplete(data, context);

    setState(() => _isSubmitting = false);

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PhotoUploadScreen()),
      );
    } else if (mounted) {
      setState(() {
        _errorMessage =
            authProvider.errorMessage ?? 'Failed to complete profile';
      });
    }
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
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

    final int selectedCount = _selectedPrompts.length;
    final bool isComplete =
        selectedCount == 0 || (selectedCount > 0 && _isFormValid());

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        automaticallyImplyLeading: false,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: index <= 3
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
                'Your Prompts',
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: onSurfaceColor,
                  letterSpacing: -0.4,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: AppLayout.box(
          context: context,
          child: Column(
            children: [
              // Fixed header
              Padding(
                padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Answer up to 3 questions',
                      style: AppTheme.headlineMedium.copyWith(
                        color: onSurfaceColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose prompts and write your answers',
                      style: AppTheme.bodyLarge.copyWith(
                        color: textMutedColor,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Selected: $selectedCount / 3',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTheme.labelLarge.copyWith(
                                color: selectedCount > 0
                                    ? primaryColor
                                    : textMutedColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: selectedCount > 0
                                  ? primaryColor
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$selectedCount',
                              style: TextStyle(
                                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
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
                                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                  fontSize: 14,
                                  color: errorColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_errorMessage != null) const SizedBox(height: 8),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _groupedPrompts.isEmpty
                    ? Center(
                        child: Text(
                          'No prompts available',
                          style: AppTheme.bodyLarge.copyWith(
                            color: textMutedColor,
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Column(
                          children: _groupedPrompts.keys.map((category) {
                            final prompts = _groupedPrompts[category]!;
                            final isExpanded = _expandedCategories.contains(
                              category,
                            );
                            final selectedInCategory = prompts
                                .where((p) => _isPromptSelected(p.id))
                                .length;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onTap: () => _toggleCategory(category),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: borderColor,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            category,
                                            style: AppTheme.titleMedium
                                                .copyWith(
                                                  color: onSurfaceColor,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 18,
                                                ),
                                          ),
                                        ),
                                        if (selectedInCategory > 0)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              '$selectedInCategory',
                                              style: TextStyle(
                                                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                                color: primaryColor,
                                              ),
                                            ),
                                          ),
                                        Icon(
                                          isExpanded
                                              ? Icons.expand_less
                                              : Icons.expand_more,
                                          color: textMutedColor,
                                          size: 24,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (isExpanded)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Column(
                                      children: prompts.map((prompt) {
                                        final isSelected = _isPromptSelected(
                                          prompt.id,
                                        );
                                        final answer = _getAnswer(prompt.id);
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8,
                                          ),
                                          child: _buildPromptItem(
                                            prompt,
                                            isSelected,
                                            answer,
                                            primaryColor,
                                            surfaceColor,
                                            borderColor,
                                            textMutedColor,
                                            onSurfaceColor,
                                            isDark,
                                            errorColor,
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                const SizedBox(height: 2),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
              ),

              // Bottom buttons
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: AppTheme.outlineButton,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_back,
                              size: 20,
                              color: onSurfaceColor,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Back',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTheme.button.copyWith(
                                  color: onSurfaceColor,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AppTheme.gradientButton(
                        enabled: isComplete && !_isSubmitting,
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      'Continue',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.button.copyWith(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                      ),
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

  Widget _buildPromptItem(
    Prompt prompt,
    bool isSelected,
    String? answer,
    Color primaryColor,
    Color surfaceColor,
    Color borderColor,
    Color textMutedColor,
    Color onSurfaceColor,
    bool isDark,
    Color errorColor,
  ) {
    final controller = _answerControllers[prompt.id];
    final hasError = isSelected && (answer == null || answer.trim().isEmpty);

    return GestureDetector(
      onTap: () => _togglePrompt(prompt),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.08)
              : surfaceColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    prompt.question,
                    style: AppTheme.bodyLarge.copyWith(
                      color: isSelected ? primaryColor : onSurfaceColor,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
              ],
            ),
            if (isSelected) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                maxLines: 2,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Write your answer...',
                  hintStyle: AppTheme.bodyMedium.copyWith(
                    color: textMutedColor,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: errorColor, width: 2),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade50,
                  contentPadding: const EdgeInsets.all(12),
                  isDense: true,
                  errorStyle: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 12,
                    color: errorColor,
                  ),
                ),
                onChanged: (value) => _updateAnswer(prompt.id, value),
                style: AppTheme.bodyLarge.copyWith(
                  color: onSurfaceColor,
                  fontSize: 15,
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please write an answer',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                      fontSize: 12,
                      color: errorColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
