import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';
import 'package:dating_app/providers/search_provider.dart';
import 'package:dating_app/services/location_service.dart';
import 'package:dating_app/services/onboarding_service.dart';
import 'package:dating_app/models/location.dart';
import 'package:dating_app/models/interest.dart';

class SearchFilterSheet extends StatefulWidget {
  const SearchFilterSheet({super.key});

  @override
  State<SearchFilterSheet> createState() => _SearchFilterSheetState();
}

class _SearchFilterSheetState extends State<SearchFilterSheet> {
  // Local filter state
  String? _gender;
  int _ageMin = 18;
  int? _ageMax;
  int? _distanceKm;
  String _sortBy = 'recent';
  String _sortOrder = 'desc';
  int? _heightMin;
  int? _heightMax;
  int? _weightMin;
  int? _weightMax;
  String? _bodyType;
  String? _relationshipStatus;
  String? _education;
  String? _smoking;
  String? _drinking;
  String? _politicalOrientation;
  String? _childrenStatus;
  String? _livingSituation;
  String? _religion;
  String? _ethnicity;
  bool? _hasPhotos;
  bool? _isVerified;
  List<String> _interests = [];
  List<String> _languages = [];

  // Location state
  List<CountryResponse> _countries = [];
  List<ProvinceResponse> _provinces = [];
  List<CityResponse> _cities = [];
  CountryResponse? _selectedCountry;
  ProvinceResponse? _selectedProvince;
  CityResponse? _selectedCity;
  bool _loadingProvinces = false;
  bool _loadingCities = false;

  // Interests
  List<Interest> _allInterests = [];
  Map<String, List<Interest>> _interestsByCategory = {};

  @override
  void initState() {
    super.initState();
    _initFromProvider();
    _loadInitialData();
  }

  void _initFromProvider() {
    final provider = Provider.of<SearchProvider>(context, listen: false);
    _gender = provider.genderFilter;
    _ageMin = provider.ageMin;
    _ageMax = provider.ageMax;
    _distanceKm = provider.distanceKm;
    _sortBy = provider.sortBy;
    _sortOrder = provider.sortOrder;
    _heightMin = provider.heightMin;
    _heightMax = provider.heightMax;
    _weightMin = provider.weightMin;
    _weightMax = provider.weightMax;
    _bodyType = provider.bodyType;
    _relationshipStatus = provider.relationshipStatus;
    _education = provider.education;
    _smoking = provider.smoking;
    _drinking = provider.drinking;
    _politicalOrientation = provider.politicalOrientation;
    _childrenStatus = provider.childrenStatus;
    _livingSituation = provider.livingSituation;
    _religion = provider.religion;
    _ethnicity = provider.ethnicity;
    _hasPhotos = provider.hasPhotos;
    _isVerified = provider.isVerified;
    _interests = List.from(provider.interests);
    _languages = List.from(provider.languages);
  }

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        LocationService.getCountries(),
        OnboardingService.getInterests(),
      ]);
      if (mounted) {
        setState(() {
          _countries = results[0] as List<CountryResponse>;
          _allInterests = results[1] as List<Interest>;
          _interestsByCategory = {};
          for (var interest in _allInterests) {
            _interestsByCategory.putIfAbsent(interest.category, () => []).add(interest);
          }
          // Restore selected country/province/city
          final provider = Provider.of<SearchProvider>(context, listen: false);
          if (provider.country != null) {
            _selectedCountry = _countries.firstWhere(
              (c) => c.name == provider.country,
              orElse: () => _countries.first,
            );
            _loadProvinces();
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProvinces() async {
    if (_selectedCountry == null) return;
    setState(() => _loadingProvinces = true);
    try {
      final provinces = await LocationService.getStates(
        countryIso2: _selectedCountry!.iso2,
      );
      if (mounted) {
        setState(() {
          _provinces = provinces;
          _loadingProvinces = false;
          // Restore selected province
          final provider = Provider.of<SearchProvider>(context, listen: false);
          if (provider.province != null) {
            _selectedProvince = _provinces.firstWhere(
              (p) => p.name == provider.province,
              orElse: () => _provinces.first,
            );
            _loadCities();
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadCities() async {
    if (_selectedCountry == null || _selectedProvince == null) return;
    setState(() => _loadingCities = true);
    try {
      final cities = await LocationService.getCities(
        countryIso2: _selectedCountry!.iso2,
        stateName: _selectedProvince!.name,
      );
      if (mounted) {
        setState(() {
          _cities = cities;
          _loadingCities = false;
          // Restore selected city
          final provider = Provider.of<SearchProvider>(context, listen: false);
          if (provider.city != null) {
            _selectedCity = _cities.firstWhere(
              (c) => c.name == provider.city,
              orElse: () => _cities.first,
            );
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingCities = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final isDark = context.isDarkMode;
    final bgColor = isDark ? AppTheme.darkSurface : Colors.white;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;
    final mutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppTheme.darkBorder
                      : Colors.grey.shade300,
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
                      t.search_advanced_filters,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFor(
                          !Localizations.localeOf(
                            context,
                          ).languageCode.contains('en'),
                        ),
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Provider.of<SearchProvider>(context, listen: false).resetFilters();
                        Navigator.pop(context);
                      },
                      child: Text(
                        t.search_reset_filters,
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(
                            !Localizations.localeOf(
                              context,
                            ).languageCode.contains('en'),
                          ),
                          color: mutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  itemCount: 9,
                  itemBuilder: (context, index) {
                    switch (index) {
                      case 0:
                        return _buildLocationSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 1:
                        return _buildBasicSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 2:
                        return _buildPhysicalSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 3:
                        return _buildLifestyleSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 4:
                        return _buildBackgroundSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 5:
                        return _buildInterestsSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 6:
                        return _buildLanguagesSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      case 7:
                        return _buildVerificationSection(t, isDark, primaryColor, textColor, mutedColor, borderColor);
                      default:
                        return const SizedBox(height: 16);
                    }
                  },
                ),
              ),
              // Apply button
              Container(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom > 0 ? 12 : 20,
                ),
                decoration: BoxDecoration(
                  color: bgColor,
                  border: Border(top: BorderSide(color: borderColor, width: 0.5)),
                ),
                child: AppTheme.gradientButton(
                  onPressed: _applyFilters,
                  child: Text(
                    t.search_apply_filters,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
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
    final provider = Provider.of<SearchProvider>(context, listen: false);
    provider.setAllFilters(
      gender: _gender,
      ageMin: _ageMin,
      ageMax: _ageMax,
      distanceKm: _distanceKm,
      heightMin: _heightMin,
      heightMax: _heightMax,
      weightMin: _weightMin,
      weightMax: _weightMax,
      bodyType: _bodyType,
      relationshipStatus: _relationshipStatus,
      education: _education,
      smoking: _smoking,
      drinking: _drinking,
      politicalOrientation: _politicalOrientation,
      childrenStatus: _childrenStatus,
      livingSituation: _livingSituation,
      country: _selectedCountry?.name,
      province: _selectedProvince?.name,
      city: _selectedCity?.name,
      religion: _religion,
      ethnicity: _ethnicity,
      interests: _interests,
      languages: _languages,
      hasPhotos: _hasPhotos,
      isVerified: _isVerified,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
    );
    Navigator.pop(context);
  }

  Widget _buildSectionHeader(String emoji, String title, bool isDark, Color primaryColor) {
    final isPersian = !Localizations.localeOf(
      context,
    ).languageCode.contains('en');
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text(
            title,
            style: (isPersian ? AppTheme.bodyBoldFa : AppTheme.bodyBold)
                .copyWith(
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
        final isSelected = selected == option;
        final label = labelBuilder != null ? labelBuilder(option) : option.replaceAll('_', ' ');
        return GestureDetector(
          onTap: () => onTap(isSelected ? null : option),
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
                  !Localizations.localeOf(
                    context,
                  ).languageCode.contains('en'),
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

  Widget _buildLocationSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('📍', t.search_filter_location, isDark, primaryColor),
        // Country
        Text(t.search_filter_country, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildDropdown<CountryResponse>(
          value: _selectedCountry,
          items: _countries,
          labelBuilder: (c) => c.name,
          onChanged: (country) {
            setState(() {
              _selectedCountry = country;
              _selectedProvince = null;
              _selectedCity = null;
              _provinces = [];
              _cities = [];
            });
            _loadProvinces();
          },
          isDark: isDark,
          borderColor: borderColor,
          textColor: textColor,
        ),
        const SizedBox(height: 12),
        // Province
        Text(t.search_filter_province, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        if (_loadingProvinces)
          const Center(child: CircularProgressIndicator())
        else
          _buildDropdown<ProvinceResponse>(
            value: _selectedProvince,
            items: _provinces,
            labelBuilder: (p) => p.name,
            onChanged: (province) {
              setState(() {
                _selectedProvince = province;
                _selectedCity = null;
                _cities = [];
              });
              _loadCities();
            },
            isDark: isDark,
            borderColor: borderColor,
            textColor: textColor,
          ),
        const SizedBox(height: 12),
        // City
        Text(t.search_filter_city, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        if (_loadingCities)
          const Center(child: CircularProgressIndicator())
        else
          _buildDropdown<CityResponse>(
            value: _selectedCity,
            items: _cities,
            labelBuilder: (c) => c.name,
            onChanged: (city) => setState(() => _selectedCity = city),
            isDark: isDark,
            borderColor: borderColor,
            textColor: textColor,
          ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<T> items,
    required String Function(T) labelBuilder,
    required ValueChanged<T?> onChanged,
    required bool isDark,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(AppTheme.radiusModule),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: isDark ? AppTheme.darkSurface : Colors.white,
        style: TextStyle(
          fontFamily: AppTheme.fontFor(
            !Localizations.localeOf(
              context,
            ).languageCode.contains('en'),
          ),
          color: textColor,
        ),
        hint: Text('Select', style: TextStyle(color: isDark ? AppTheme.darkTextMuted : Colors.grey)),
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(labelBuilder(item)),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildBasicSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('👤', t.search_filter_gender, isDark, primaryColor),
        _buildChipRow(
          options: ['all', 'male', 'female'],
          selected: _gender,
          onTap: (v) => setState(() => _gender = v),
          isDark: isDark,
          primaryColor: primaryColor,
          textColor: textColor,
          labelBuilder: (v) => v == 'all' ? t.discover_filter_all : v == 'male' ? t.discover_filter_male : t.discover_filter_female,
        ),
        _buildSectionHeader('🎂', t.search_filter_age_range, isDark, primaryColor),
        Text('${_ageMin.round()} - ${_ageMax != null ? _ageMax!.round() : '100+'}', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 14, color: textColor)),
        RangeSlider(
          values: RangeValues(_ageMin.toDouble(), (_ageMax ?? 100).toDouble()),
          min: 18, max: 100, divisions: 82,
          activeColor: primaryColor, inactiveColor: primaryColor.withValues(alpha: 0.2),
          onChanged: (v) => setState(() { _ageMin = v.start.round(); _ageMax = v.end.round() == 100 ? null : v.end.round(); }),
        ),
        _buildSectionHeader('📏', t.search_filter_distance_km, isDark, primaryColor),
        Text(_distanceKm != null ? '$_distanceKm km' : '500+ km', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 14, color: textColor)),
        Slider(
          value: (_distanceKm ?? 500).toDouble(),
          min: 1, max: 500, divisions: 499,
          activeColor: primaryColor, inactiveColor: primaryColor.withValues(alpha: 0.2),
          onChanged: (v) => setState(() => _distanceKm = v.round() >= 500 ? null : v.round()),
        ),
      ],
    );
  }

  Widget _buildPhysicalSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('💪', 'Physical', isDark, primaryColor),
        Text(t.search_filter_height, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        Text('${_heightMin ?? 50} - ${_heightMax != null ? _heightMax! : '250+'} cm', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 14, color: textColor)),
        RangeSlider(
          values: RangeValues((_heightMin ?? 50).toDouble(), (_heightMax ?? 250).toDouble()),
          min: 50, max: 250, divisions: 200,
          activeColor: primaryColor, inactiveColor: primaryColor.withValues(alpha: 0.2),
          onChanged: (v) => setState(() {
            _heightMin = v.start.round() <= 50 ? null : v.start.round();
            _heightMax = v.end.round() >= 250 ? null : v.end.round();
          }),
        ),
        Text(t.search_filter_weight, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        Text('${_weightMin ?? 30} - ${_weightMax != null ? _weightMax! : '300+'} kg', style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 14, color: textColor)),
        RangeSlider(
          values: RangeValues((_weightMin ?? 30).toDouble(), (_weightMax ?? 300).toDouble()),
          min: 30, max: 300, divisions: 270,
          activeColor: primaryColor, inactiveColor: primaryColor.withValues(alpha: 0.2),
          onChanged: (v) => setState(() {
            _weightMin = v.start.round() <= 30 ? null : v.start.round();
            _weightMax = v.end.round() >= 300 ? null : v.end.round();
          }),
        ),
        _buildChipRow(
          options: ['slim', 'average', 'athletic', 'curvy', 'muscular', 'overweight'],
          selected: _bodyType,
          onTap: (v) => setState(() => _bodyType = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildLifestyleSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('🏠', 'Lifestyle', isDark, primaryColor),
        Text(t.search_filter_relationship, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['single', 'divorced', 'widowed', 'separated'],
          selected: _relationshipStatus,
          onTap: (v) => setState(() => _relationshipStatus = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_education, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['high_school', 'bachelor', 'master', 'phd'],
          selected: _education,
          onTap: (v) => setState(() => _education = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_smoking, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['never', 'occasionally', 'regularly'],
          selected: _smoking,
          onTap: (v) => setState(() => _smoking = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_drinking, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['never', 'socially', 'regularly'],
          selected: _drinking,
          onTap: (v) => setState(() => _drinking = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_political, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['liberal', 'conservative', 'moderate', 'apolitical'],
          selected: _politicalOrientation,
          onTap: (v) => setState(() => _politicalOrientation = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_children, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['have', 'dont_have', 'want', 'dont_want'],
          selected: _childrenStatus,
          onTap: (v) => setState(() => _childrenStatus = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_living, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ['alone', 'with_family', 'with_roommate', 'with_partner'],
          selected: _livingSituation,
          onTap: (v) => setState(() => _livingSituation = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildBackgroundSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    final religions = ['islam', 'christianity', 'judaism', 'hinduism', 'buddhism', 'atheism', 'agnostic', 'other'];
    final ethnicities = ['persian', 'kurdish', 'azeri', 'arab', 'baloch', 'lur', 'turkmen', 'gilaki', 'mazandarani', 'other'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('🌍', 'Background', isDark, primaryColor),
        Text(t.search_filter_religion, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: religions,
          selected: _religion,
          onTap: (v) => setState(() => _religion = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
        const SizedBox(height: 12),
        Text(t.search_filter_ethnicity, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 13, color: mutedColor)),
        const SizedBox(height: 8),
        _buildChipRow(
          options: ethnicities,
          selected: _ethnicity,
          onTap: (v) => setState(() => _ethnicity = v),
          isDark: isDark, primaryColor: primaryColor, textColor: textColor,
        ),
      ],
    );
  }

  Widget _buildInterestsSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('❤️', t.search_filter_interests, isDark, primaryColor),
        if (_interests.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _interests.map((name) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(name, style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), fontSize: 11, color: Colors.white)),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _interests.remove(name)),
                        child: const Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ..._interestsByCategory.entries.map((entry) {
          final categorySelected = entry.value.where((i) => _interests.contains(i.name)).length;
          return ExpansionTile(
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Row(
              children: [
                Text(
                  entry.key.replaceAll('_', ' '),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (categorySelected > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('$categorySelected', style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ],
              ],
            ),
            iconColor: mutedColor,
            collapsedIconColor: mutedColor,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value.map((interest) {
                  final isSelected = _interests.contains(interest.name);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _interests.remove(interest.name);
                        } else {
                          _interests.add(interest.name);
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : isDark
                                ? AppTheme.darkSecondary.withValues(alpha: 0.4)
                                : Colors.white,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        border: Border.all(
                          color: isSelected ? primaryColor : borderColor,
                        ),
                      ),
                      child: Text(
                        '${interest.icon ?? ''} ${interest.name}'.trim(),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFor(
                            !Localizations.localeOf(
                              context,
                            ).languageCode.contains('en'),
                          ),
                          fontSize: 12,
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
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildLanguagesSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    final languages = ['fa', 'en', 'ar', 'tr', 'fr', 'de', 'es', 'ru', 'zh', 'hi'];
    final languageNames = {
      'fa': 'Persian',
      'en': 'English',
      'ar': 'Arabic',
      'tr': 'Turkish',
      'fr': 'French',
      'de': 'German',
      'es': 'Spanish',
      'ru': 'Russian',
      'zh': 'Chinese',
      'hi': 'Hindi',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('🗣️', t.search_filter_languages, isDark, primaryColor),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: languages.map((lang) {
            final isSelected = _languages.contains(lang);
            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _languages.remove(lang);
                  } else {
                    _languages.add(lang);
                  }
                });
              },
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
                    color: isSelected ? primaryColor : borderColor,
                  ),
                ),
                child: Text(
                  languageNames[lang] ?? lang,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFor(
                      !Localizations.localeOf(
                        context,
                      ).languageCode.contains('en'),
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
        ),
      ],
    );
  }

  Widget _buildVerificationSection(AppLocalizations t, bool isDark, Color primaryColor, Color textColor, Color mutedColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('✅', 'Verification', isDark, primaryColor),
        _buildToggleRow(
          label: t.search_filter_has_photos,
          value: _hasPhotos == true,
          onChanged: (v) => setState(() => _hasPhotos = v ? true : null),
          isDark: isDark,
          textColor: textColor,
          primaryColor: primaryColor,
        ),
        const SizedBox(height: 8),
        _buildToggleRow(
          label: t.search_filter_verified,
          value: _isVerified == true,
          onChanged: (v) => setState(() => _isVerified = v ? true : null),
          isDark: isDark,
          textColor: textColor,
          primaryColor: primaryColor,
        ),
      ],
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color textColor,
    required Color primaryColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTheme.fontFor(
              !Localizations.localeOf(
                context,
              ).languageCode.contains('en'),
            ),
            fontSize: 14,
            color: textColor,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: primaryColor,
        ),
      ],
    );
  }
}
