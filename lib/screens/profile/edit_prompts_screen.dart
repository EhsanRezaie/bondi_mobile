// lib/screens/profile/edit_prompts_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/onboarding_service.dart';
import '../../models/prompt.dart';
import '../../generated/app_localizations.dart';
import '../../utils/responsive.dart';
import '../../widgets/action_toast.dart';

class EditPromptsScreen extends StatefulWidget {
  const EditPromptsScreen({super.key});

  @override
  State<EditPromptsScreen> createState() => _EditPromptsScreenState();
}

class _EditPromptsScreenState extends State<EditPromptsScreen> {
  List<Prompt> _allPrompts = [];
  Map<String, List<Prompt>> _groupedPrompts = {};
  List<Map<String, dynamic>> _selectedPrompts = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  final Set<String> _expandedCategories = {};
  final Map<String, TextEditingController> _answerControllers = {};

  @override
  void initState() {
    super.initState();
    _loadUserPrompts();
    _loadPrompts();
  }

  void _loadUserPrompts() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    if (user?.prompts != null && user!.prompts!.isNotEmpty) {
      _selectedPrompts = List.from(user.prompts!);
      for (final prompt in _selectedPrompts) {
        final promptId = prompt['prompt_id'] as String;
        _answerControllers[promptId] = TextEditingController(
          text: prompt['answer'] ?? '',
        );
      }
    }
  }

  Future<void> _loadPrompts() async {
    if (!mounted) return;
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

      if (!mounted) return;
      setState(() {
        _allPrompts = prompts.where((p) => p.isActive).toList();
        _groupedPrompts = _groupByCategory(_allPrompts);
        if (_groupedPrompts.isNotEmpty) {
          _expandedCategories.add(_groupedPrompts.keys.first);
        }
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
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
    if (!mounted) return;
    setState(() {
      if (_expandedCategories.contains(category)) {
        _expandedCategories.remove(category);
      } else {
        _expandedCategories.add(category);
      }
    });
  }

  void _togglePrompt(Prompt prompt) {
    if (!mounted) return;
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
    if (!mounted) return;
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

  Future<void> _handleSave() async {
    final t = AppLocalizations.of(context)!;
    if (_selectedPrompts.isNotEmpty && !_isFormValid()) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Please answer all selected prompts';
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

      debugPrint('📤 Sending prompts: $_selectedPrompts');

      final success = await authProvider.updatePrompts(_selectedPrompts);

      if (success && mounted) {
        showActionToast(context, t.prompts_updated_success);
        Navigator.pop(context);
      } else if (mounted) {
        setState(() {
          _errorMessage =
              authProvider.errorMessage ?? 'Failed to update prompts';
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurfaceColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Prompts',
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
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose prompts and write your answers',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        color: textMutedColor,
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
                          Text(
                            'Selected: $selectedCount / 3',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: selectedCount > 0
                                  ? primaryColor
                                  : textMutedColor,
                            ),
                          ),
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
                                fontFamily: 'Inter',
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
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 16,
                            color: textMutedColor,
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
                                                fontFamily: 'Inter',
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
              // Bottom Save Button - Big and full width
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isComplete
                          ? primaryColor
                          : Colors.grey.shade400,
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
                            'Save',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isComplete
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                  ),
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
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: isSelected ? primaryColor : onSurfaceColor,
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
                  hintStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: textMutedColor,
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
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: errorColor,
                  ),
                ),
                onChanged: (value) => _updateAnswer(prompt.id, value),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: onSurfaceColor,
                ),
              ),
              if (hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Please write an answer',
                    style: TextStyle(
                      fontFamily: 'Inter',
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
