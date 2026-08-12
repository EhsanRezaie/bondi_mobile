// lib/screens/onboarding/profile_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../utils/responsive.dart';
import 'interests_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _workplaceController = TextEditingController();

  double _height = 175;
  double _weight = 70;

  String? _bodyType;
  String? _relationshipStatus;
  String? _livingSituation;
  String? _childrenStatus;
  String? _smoking;
  String? _drinking;
  String? _education;
  String? _politicalOrientation;
  String? _religion;
  String? _ethnicity;
  List<String> _selectedLanguages = [];

  final bool _isLoading = false;
  String? _errorMessage;

  final List<String> _languageOptions = [
    'English',
    'Persian',
    'Turkish',
    'Arabic',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Russian',
    'Chinese',
    'Japanese',
    'Korean',
    'Hindi',
    'Urdu',
    'Kurdish',
    'Armenian',
  ];

  // ============================================================
  // BODY TYPE - Matches backend: slim, average, athletic, curvy, muscular, overweight
  // ============================================================
  final List<String> _bodyTypeOptions = [
    'Slim',
    'Average',
    'Athletic',
    'Curvy',
    'Muscular',
    'Plus Size', // maps to 'overweight'
  ];

  // ============================================================
  // RELATIONSHIP STATUS - Matches backend: single, divorced, widowed, separated
  // ============================================================
  final List<String> _relationshipOptions = [
    'Single',
    'Divorced',
    'Widowed',
    'Separated',
  ];

  // ============================================================
  // LIVING SITUATION - Matches backend: alone, with_family, with_roommate, with_partner
  // ============================================================
  final List<String> _livingSituationOptions = [
    'Alone',
    'With Family',
    'With Roommates',
    'With Partner',
  ];

  // ============================================================
  // CHILDREN STATUS - Matches backend: have, dont_have, want, dont_want
  // ============================================================
  final List<String> _childrenOptions = [
    'Have children',
    'Don\'t have children',
    'Want children',
    'Don\'t want children',
  ];

  // ============================================================
  // SMOKING - Matches backend: never, occasionally, regularly
  // ============================================================
  final List<String> _smokingOptions = [
    'Never',
    'Socially', // maps to 'occasionally'
    'Regularly',
  ];

  // ============================================================
  // DRINKING - Matches backend: never, socially, regularly
  // ============================================================
  final List<String> _drinkingOptions = ['Never', 'Socially', 'Regularly'];

  // ============================================================
  // EDUCATION - Matches backend: high_school, bachelor, master, phd
  // ============================================================
  final List<String> _educationOptions = [
    'High School',
    'Undergraduate Degree', // maps to 'bachelor'
    'Postgraduate Degree', // maps to 'master'
    'PhD / Doctorate', // maps to 'phd'
  ];

  // ============================================================
  // POLITICAL - Matches backend: liberal, conservative, moderate, apolitical
  // ============================================================
  final List<String> _politicalOptions = [
    'Liberal',
    'Conservative',
    'Moderate',
    'Apolitical',
  ];

  // ============================================================
  // RELIGION - Free text (no enum)
  // ============================================================
  final List<String> _religionOptions = [
    'Muslim',
    'Christian',
    'Jewish',
    'Zoroastrian',
    'Atheist',
    'Agnostic',
    'Spiritual',
    'Sikh',
    'Buddhist',
    'Hindu',
    'Other',
  ];

  // ============================================================
  // ETHNICITY - Free text (no enum)
  // ============================================================
  final List<String> _ethnicityOptions = [
    'Persian',
    'Azeri',
    'Kurd',
    'Lur',
    'Arab',
    'Baloch',
    'Turkmen',
    'Asian',
    'Black / African Descent',
    'Hispanic / Latino',
    'White / Caucasian',
    'Middle Eastern',
    'Mixed',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  void _loadSavedData() {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboarding.height != null) _height = onboarding.height!.toDouble();
    if (onboarding.weight != null) _weight = onboarding.weight!.toDouble();
    if (onboarding.bodyType != null) {
      _bodyType = _capitalize(onboarding.bodyType!);
    }
    if (onboarding.relationshipStatus != null) {
      _relationshipStatus = _capitalize(onboarding.relationshipStatus!);
    }
    if (onboarding.livingSituation != null) {
      _livingSituation = _capitalize(onboarding.livingSituation!);
    }
    if (onboarding.childrenStatus != null) {
      _childrenStatus = _capitalize(onboarding.childrenStatus!);
    }
    if (onboarding.smoking != null) {
      _smoking = _capitalize(onboarding.smoking!);
    }
    if (onboarding.drinking != null) {
      _drinking = _capitalize(onboarding.drinking!);
    }
    if (onboarding.education != null) {
      _education = _capitalize(onboarding.education!);
    }
    if (onboarding.workplace != null) {
      _workplaceController.text = onboarding.workplace!;
    }
    if (onboarding.religion != null) {
      _religion = _capitalize(onboarding.religion!);
    }
    if (onboarding.ethnicity != null) {
      _ethnicity = _capitalize(onboarding.ethnicity!);
    }
    if (onboarding.politicalOrientation != null) {
      _politicalOrientation = _capitalize(onboarding.politicalOrientation!);
    }
    if (onboarding.languages != null) {
      _selectedLanguages = List.from(onboarding.languages!);
    }
  }

  String _capitalize(String str) {
    if (str.isEmpty) return str;
    return str[0].toUpperCase() + str.substring(1);
  }

  String _getBackendValue(String displayValue) {
    // Body Type
    if (displayValue == 'Slim') return 'slim';
    if (displayValue == 'Average') return 'average';
    if (displayValue == 'Athletic') return 'athletic';
    if (displayValue == 'Curvy') return 'curvy';
    if (displayValue == 'Muscular') return 'muscular';
    if (displayValue == 'Plus Size') return 'overweight';

    // Relationship Status
    if (displayValue == 'Single') return 'single';
    if (displayValue == 'Divorced') return 'divorced';
    if (displayValue == 'Widowed') return 'widowed';
    if (displayValue == 'Separated') return 'separated';

    // Living Situation
    if (displayValue == 'Alone') return 'alone';
    if (displayValue == 'With Family') return 'with_family';
    if (displayValue == 'With Roommates') return 'with_roommate';
    if (displayValue == 'With Partner') return 'with_partner';

    // Children Status
    if (displayValue == 'Have children') return 'have';
    if (displayValue == 'Don\'t have children') return 'dont_have';
    if (displayValue == 'Want children') return 'want';
    if (displayValue == 'Don\'t want children') return 'dont_want';

    // Smoking
    if (displayValue == 'Never') return 'never';
    if (displayValue == 'Socially') return 'occasionally';
    if (displayValue == 'Regularly') return 'regularly';

    // Drinking
    if (displayValue == 'Never') return 'never';
    if (displayValue == 'Socially') return 'socially';
    if (displayValue == 'Regularly') return 'regularly';

    // Education
    if (displayValue == 'High School') return 'high_school';
    if (displayValue == 'Undergraduate Degree') return 'bachelor';
    if (displayValue == 'Postgraduate Degree') return 'master';
    if (displayValue == 'PhD / Doctorate') return 'phd';

    // Political Orientation
    if (displayValue == 'Liberal') return 'liberal';
    if (displayValue == 'Conservative') return 'conservative';
    if (displayValue == 'Moderate') return 'moderate';
    if (displayValue == 'Apolitical') return 'apolitical';

    // Religion - free text
    if (displayValue == 'Other') return 'other';
    return displayValue.toLowerCase();
  }

  void _toggleLanguage(String language) {
    setState(() {
      if (_selectedLanguages.contains(language)) {
        _selectedLanguages.remove(language);
      } else {
        _selectedLanguages.add(language);
      }
    });
  }

  void _selectChip(String value, Function(String?) setter, String? current) {
    setState(() {
      if (current == value) {
        setter(null);
      } else {
        setter(value);
      }
    });
  }

  Future<void> _handleNext() async {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);

    onboarding.setPhysicalAndLifestyle(
      height: _height.toInt(),
      weight: _weight.toInt(),
      bodyType: _bodyType != null ? _getBackendValue(_bodyType!) : null,
      relationshipStatus: _relationshipStatus != null
          ? _getBackendValue(_relationshipStatus!)
          : null,
      livingSituation: _livingSituation != null
          ? _getBackendValue(_livingSituation!)
          : null,
      childrenStatus: _childrenStatus != null
          ? _getBackendValue(_childrenStatus!)
          : null,
      smoking: _smoking != null ? _getBackendValue(_smoking!) : null,
      drinking: _drinking != null ? _getBackendValue(_drinking!) : null,
      education: _education != null ? _getBackendValue(_education!) : null,
      workplace: _workplaceController.text.trim().isNotEmpty
          ? _workplaceController.text.trim()
          : null,
      religion: _religion != null ? _getBackendValue(_religion!) : null,
      ethnicity: _ethnicity != null ? _getBackendValue(_ethnicity!) : null,
      politicalOrientation: _politicalOrientation != null
          ? _getBackendValue(_politicalOrientation!)
          : null,
      languages: _selectedLanguages.isNotEmpty ? _selectedLanguages : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const InterestsScreen()),
    );
  }

  @override
  void dispose() {
    _workplaceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

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
                        color: index <= 1
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
                'Profile Details',
                style: TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: onSurfaceColor,
                  letterSpacing: -0.4,
                ),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tell us more about yourself',
                                style: AppTheme.headlineMedium.copyWith(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'All fields are optional. Fill what you want to share.',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: textMutedColor,
                                ),
                              ),
                              const SizedBox(height: 28),
                              if (_errorMessage != null) ...[
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
                                const SizedBox(height: 20),
                              ],
                              // HEIGHT
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '📏 Height',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: onSurfaceColor,
                                        ),
                                      ),
                                      Text(
                                        '${_height.toInt()} cm',
                                        style: AppTheme.labelLarge.copyWith(
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _height,
                                    min: 140,
                                    max: 220,
                                    divisions: 80,
                                    activeColor: primaryColor,
                                    inactiveColor: isDark
                                        ? AppTheme.darkSecondary : AppTheme.lightSecondary,
                                    onChanged: (value) {
                                      setState(() {
                                        _height = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // WEIGHT
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '🏋️ Weight',
                                        style: TextStyle(
                                          fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: onSurfaceColor,
                                        ),
                                      ),
                                      Text(
                                        '${_weight.toInt()} kg',
                                        style: AppTheme.labelLarge.copyWith(
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Slider(
                                    value: _weight,
                                    min: 40,
                                    max: 140,
                                    divisions: 100,
                                    activeColor: primaryColor,
                                    inactiveColor: isDark
                                        ? AppTheme.darkSecondary : AppTheme.lightSecondary,
                                    onChanged: (value) {
                                      setState(() {
                                        _weight = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // BODY TYPE
                              _buildChipSection(
                                label: '💪 Body Type',
                                options: _bodyTypeOptions,
                                selected: _bodyType,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _bodyType = v,
                                  _bodyType,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // RELATIONSHIP STATUS
                              _buildChipSection(
                                label: '❤️ Relationship Status',
                                options: _relationshipOptions,
                                selected: _relationshipStatus,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _relationshipStatus = v,
                                  _relationshipStatus,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // LIVING SITUATION
                              _buildChipSection(
                                label: '🏠 Living Situation',
                                options: _livingSituationOptions,
                                selected: _livingSituation,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _livingSituation = v,
                                  _livingSituation,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // CHILDREN STATUS
                              _buildChipSection(
                                label: '👶 Children Status',
                                options: _childrenOptions,
                                selected: _childrenStatus,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _childrenStatus = v,
                                  _childrenStatus,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // SMOKING
                              _buildChipSection(
                                label: '🚬 Smoking',
                                options: _smokingOptions,
                                selected: _smoking,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _smoking = v,
                                  _smoking,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // DRINKING
                              _buildChipSection(
                                label: '🍷 Drinking',
                                options: _drinkingOptions,
                                selected: _drinking,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _drinking = v,
                                  _drinking,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // EDUCATION
                              _buildChipSection(
                                label: '🎓 Education',
                                options: _educationOptions,
                                selected: _education,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _education = v,
                                  _education,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // POLITICAL ORIENTATION
                              _buildChipSection(
                                label: '🗳️ Political Orientation',
                                options: _politicalOptions,
                                selected: _politicalOrientation,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _politicalOrientation = v,
                                  _politicalOrientation,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // RELIGION
                              _buildChipSection(
                                label: '🕌 Religion',
                                options: _religionOptions,
                                selected: _religion,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _religion = v,
                                  _religion,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // ETHNICITY
                              _buildChipSection(
                                label: '🌍 Ethnicity',
                                options: _ethnicityOptions,
                                selected: _ethnicity,
                                onTap: (value) => _selectChip(
                                  value,
                                  (v) => _ethnicity = v,
                                  _ethnicity,
                                ),
                              ),
                              const SizedBox(height: 24),
                              // LANGUAGES (Multi-select)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      '🗣️ Languages (Multi-select)',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _languageOptions.map((language) {
                                      final isSelected = _selectedLanguages
                                          .contains(language);
                                      return GestureDetector(
                                        onTap: () => _toggleLanguage(language),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? primaryColor.withValues(
                                                    alpha: 0.06,
                                                  )
                                                : surfaceColor,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? primaryColor
                                                  : borderColor,
                                              width: isSelected ? 1.5 : 1,
                                            ),
                                          ),
                                          child: Text(
                                            language,
                                            style: TextStyle(
                                              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                              fontSize: 14,
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.w500,
                                              color: isSelected
                                                  ? primaryColor
                                                  : onSurfaceColor.withValues(
                                                      alpha: 0.8,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              // WORKPLACE
                              TextFormField(
                                controller: _workplaceController,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: onSurfaceColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: '💼 Workplace (optional)',
                                  hintText: 'Your job title or company',
                                  prefixIcon: Icon(
                                    Icons.work_outline,
                                    color: textMutedColor,
                                    size: 22,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Container(
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(
                          left: 24.0,
                          right: 24.0,
                          bottom: 24.0,
                        ),
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
                                    Text(
                                      'Back',
                                      style: AppTheme.button.copyWith(
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: AppTheme.gradientButton(
                                enabled: !_isLoading,
                                onPressed: _isLoading ? null : _handleNext,
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'Continue',
                                            style: AppTheme.button.copyWith(
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
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

  Widget _buildChipSection({
    required String label,
    required List<String> options,
    required String? selected,
    required void Function(String) onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: onSurfaceColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return GestureDetector(
              onTap: () => onTap(option),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.06)
                      : surfaceColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? primaryColor : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? primaryColor
                        : onSurfaceColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
