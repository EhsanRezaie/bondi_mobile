import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/location_service.dart';
import '../../models/location.dart';
import '../../utils/responsive.dart';
import 'profile_details_screen.dart';

class BasicInfoScreen extends StatefulWidget {
  const BasicInfoScreen({super.key});

  @override
  State<BasicInfoScreen> createState() => _BasicInfoScreenState();
}

class _BasicInfoScreenState extends State<BasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Search controllers
  final SearchController _countrySearchController = SearchController();
  final SearchController _provinceSearchController = SearchController();
  final SearchController _citySearchController = SearchController();

  DateTime? _selectedBirthDate;
  String? _selectedGender;

  // Location data
  List<CountryResponse> _countries = [];
  List<ProvinceResponse> _provinces = [];
  List<CityResponse> _cities = [];

  CountryResponse? _selectedCountry;
  ProvinceResponse? _selectedProvince;
  CityResponse? _selectedCity;

  double? _lat;
  double? _lng;

  final bool _isLoading = false;
  bool _isLoadingCountries = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingLocation = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
    _loadCountries();
  }

  void _loadSavedData() {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);
    if (onboarding.name != null) _nameController.text = onboarding.name!;
    if (onboarding.bio != null) _bioController.text = onboarding.bio!;
    if (onboarding.gender != null) _selectedGender = onboarding.gender;
    if (onboarding.birthDate != null) {
      try {
        _selectedBirthDate = DateTime.parse(onboarding.birthDate!);
        _birthDateController.text = onboarding.birthDate!;
      } catch (_) {}
    }
    if (onboarding.lat != null) _lat = onboarding.lat;
    if (onboarding.lng != null) _lng = onboarding.lng;

    if (onboarding.country != null ||
        onboarding.province != null ||
        onboarding.city != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadSavedLocationData();
      });
    }
  }

  Future<void> _loadSavedLocationData() async {
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);

    if (onboarding.country != null) {
      for (var country in _countries) {
        if (country.name == onboarding.country) {
          setState(() {
            _selectedCountry = country;
            _countrySearchController.text = country.name;
          });
          await _loadStates(country.iso2);
          break;
        }
      }
    }

    if (onboarding.province != null && _provinces.isNotEmpty) {
      for (var province in _provinces) {
        if (province.name == onboarding.province) {
          setState(() {
            _selectedProvince = province;
            _provinceSearchController.text = province.name;
          });
          if (_selectedCountry != null) {
            await _loadCities(_selectedCountry!.iso2, province.name);
          }
          break;
        }
      }
    }

    if (onboarding.city != null && _cities.isNotEmpty) {
      for (var city in _cities) {
        if (city.name == onboarding.city) {
          setState(() {
            _selectedCity = city;
            _citySearchController.text = city.name;
          });
          break;
        }
      }
    }
  }

  // ============================================================================
  // Load Countries from API
  // ============================================================================

  Future<void> _loadCountries() async {
    setState(() {
      _isLoadingCountries = true;
      _errorMessage = null;
    });

    try {
      final countries = await LocationService.getCountries();
      setState(() {
        _countries = countries;
      });

      if (mounted) {
        _loadSavedLocationData();
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load countries. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
      }
    }
  }

  // ============================================================================
  // Load States from API
  // ============================================================================

  Future<void> _loadStates(String countryIso2) async {
    setState(() {
      _isLoadingProvinces = true;
      _errorMessage = null;
    });

    try {
      final states = await LocationService.getStates(countryIso2: countryIso2);
      setState(() {
        _provinces = states;
        _isLoadingProvinces = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load states. Please try again.';
        _isLoadingProvinces = false;
      });
    }
  }

  // ============================================================================
  // Load Cities from API
  // ============================================================================

  Future<void> _loadCities(String countryIso2, String stateName) async {
    setState(() {
      _isLoadingCities = true;
      _errorMessage = null;
    });

    try {
      final cities = await LocationService.getCities(
        countryIso2: countryIso2,
        stateName: stateName,
      );
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cities. Please try again.';
        _isLoadingCities = false;
      });
    }
  }

  // ============================================================================
  // Get Current Location (GPS)
  // ============================================================================

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        setState(() {
          _errorMessage = 'Could not get GPS location. Please select manually.';
          _isLoadingLocation = false;
        });
        return;
      }

      final location = await LocationService.reverseGeocode(
        lat: position.latitude,
        lng: position.longitude,
      );

      if (location == null || location.country == null) {
        setState(() {
          _errorMessage =
              'Could not determine your location. Please select manually.';
          _isLoadingLocation = false;
        });
        return;
      }

      CountryResponse? matchedCountry;
      for (var country in _countries) {
        if (country.iso2 == location.countryIso2) {
          matchedCountry = country;
          break;
        }
      }

      if (matchedCountry == null) {
        setState(() {
          _errorMessage =
              'Your country is not supported. Please select manually.';
          _isLoadingLocation = false;
        });
        return;
      }

      // Reset all selections first
      _resetLocationSelections();

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _selectedCountry = matchedCountry;
        _countrySearchController.text = matchedCountry!.name;
      });

      await _loadStates(matchedCountry.iso2);

      if (location.province != null && _provinces.isNotEmpty) {
        for (var province in _provinces) {
          if (province.name.toLowerCase() == location.province!.toLowerCase()) {
            setState(() {
              _selectedProvince = province;
              _provinceSearchController.text = province.name;
            });
            await _loadCities(matchedCountry.iso2, province.name);
            break;
          }
        }
      }

      if (location.city != null && _cities.isNotEmpty) {
        for (var city in _cities) {
          if (city.name.toLowerCase() == location.city!.toLowerCase()) {
            setState(() {
              _selectedCity = city;
              _citySearchController.text = city.name;
            });
            break;
          }
        }
      }

      if (_selectedCity == null) {
        setState(() {
          _errorMessage = 'Could not find your city. Please select manually.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting location. Please select manually.';
      });
      debugPrint('❌ Get location error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  // ============================================================================
  // Reset Location Selections (CRITICAL FIX)
  // ============================================================================

  void _resetLocationSelections() {
    setState(() {
      _selectedProvince = null;
      _selectedCity = null;
      _provinces = [];
      _cities = [];
      _lat = null;
      _lng = null;
      _errorMessage = null;
      _provinceSearchController.clear();
      _citySearchController.clear();
    });
  }

  // ============================================================================
  // Handlers
  // ============================================================================

  void _onCountryChanged(CountryResponse? country) {
    // Reset all dependent fields
    _resetLocationSelections();

    setState(() {
      _selectedCountry = country;
      if (country != null) {
        _countrySearchController.text = country.name;
      } else {
        _countrySearchController.clear();
      }
    });

    if (country != null) {
      _loadStates(country.iso2);
    }
  }

  void _onProvinceChanged(ProvinceResponse? province) {
    setState(() {
      _selectedProvince = province;
      _selectedCity = null;
      _cities = [];
      _lat = null;
      _lng = null;
      _errorMessage = null;
      _citySearchController.clear();
      if (province != null) {
        _provinceSearchController.text = province.name;
      } else {
        _provinceSearchController.clear();
      }
    });

    if (province != null && _selectedCountry != null) {
      _loadCities(_selectedCountry!.iso2, province.name);
    }
  }

  void _onCityChanged(CityResponse? city) {
    setState(() {
      _selectedCity = city;
      _errorMessage = null;
      if (city != null) {
        _citySearchController.text = city.name;
      } else {
        _citySearchController.clear();
      }
    });

    if (city != null) {
      if (city.latitude != null && city.longitude != null) {
        setState(() {
          _lat = city.latitude;
          _lng = city.longitude;
        });
      } else {
        _getCityCentroid(city.name);
      }
    }
  }

  Future<void> _getCityCentroid(String cityName) async {
    if (_selectedCountry == null) return;

    final centroid = await LocationService.getCityCentroid(
      countryIso2: _selectedCountry!.iso2,
      cityName: cityName,
    );

    if (centroid != null) {
      setState(() {
        _lat = centroid.latitude;
        _lng = centroid.longitude;
      });
    }
  }

  // ============================================================================
  // Birth Date Picker
  // ============================================================================

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final initialDate = DateTime(now.year - 18, now.month, now.day);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 18, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        final isDark = context.isDarkMode;
        return Theme(
          data: isDark ? ThemeData.dark() : ThemeData.light(),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedBirthDate = pickedDate;
        _birthDateController.text =
            '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  // ============================================================================
  // Handle Next
  // ============================================================================

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final gender = _selectedGender;
    final bio = _bioController.text.trim();

    if (gender == null) {
      setState(() => _errorMessage = 'Please select your gender');
      return;
    }

    if (_selectedCountry == null ||
        _selectedProvince == null ||
        _selectedCity == null) {
      setState(() => _errorMessage = 'Please select your location');
      return;
    }

    if (_lat == null || _lng == null) {
      await _getCityCentroid(_selectedCity!.name);
      if (_lat == null || _lng == null) {
        setState(
          () => _errorMessage =
              'Could not determine location coordinates. Please try again.',
        );
        return;
      }
    }

    if (!mounted) return;
    final onboarding = Provider.of<OnboardingProvider>(context, listen: false);

    onboarding.setPersonalInfo(
      name: name,
      birthDate: _birthDateController.text,
      gender: gender,
      bio: bio.isNotEmpty ? bio : null,
    );

    onboarding.setLocation(
      lat: _lat!,
      lng: _lng!,
      country: _selectedCountry!.name,
      province: _selectedProvince!.name,
      city: _selectedCity!.name,
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileDetailsScreen()),
    );
  }

  // ============================================================================
  // Searchable Dropdown Builder
  // ============================================================================

  Widget _buildSearchableDropdown<T>({
    required List<T> items,
    required T? selectedItem,
    required String hintText,
    required String labelText,
    required String Function(T item) displayName,
    required void Function(T?) onSelected,
    required bool isLoading,
    required SearchController searchController,
    Widget? leadingIcon,
    bool isEnabled = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
          child: Text(
            labelText,
            style: TextStyle(
              fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        SearchAnchor(
          searchController: searchController,
          isFullScreen: false,
          viewConstraints: const BoxConstraints(maxHeight: 300),
          builder: (context, searchController) {
            return SearchBar(
              controller: searchController,
              hintText: isEnabled ? hintText : 'Select country first',
              enabled: isEnabled,
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(
                isEnabled
                    ? (isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.grey.shade50)
                    : (isDark
                          ? Colors.white.withValues(alpha: 0.02)
                          : Colors.grey.shade100),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: selectedItem != null
                        ? primaryColor
                        : (isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                    width: selectedItem != null ? 2 : 1,
                  ),
                ),
              ),
              leading:
                  leadingIcon ??
                  Icon(
                    Icons.search,
                    color: isEnabled
                        ? Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
              trailing: [
                if (selectedItem != null && isEnabled)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    onPressed: () {
                      searchController.clear();
                      onSelected(null);
                    },
                  ),
                if (isLoading)
                  const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
              onTap: () {
                if (isEnabled) {
                  searchController.openView();
                }
              },
              onChanged: (query) {
                if (isEnabled) {
                  searchController.openView();
                }
              },
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 15,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                  fontSize: 15,
                  color: isEnabled
                      ? Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5)
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            );
          },
          suggestionsBuilder: (context, searchController) {
            if (!isEnabled) {
              return [
                ListTile(
                  title: Text(
                    'Please select a country first',
                    style: TextStyle(fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')), color: Colors.grey),
                  ),
                ),
              ];
            }

            final query = searchController.text.toLowerCase().trim();

            final filteredItems = query.isEmpty
                ? items
                : items.where((item) {
                    final name = displayName(item).toLowerCase();
                    return name.contains(query);
                  }).toList();

            if (filteredItems.isEmpty) {
              return [
                ListTile(
                  title: Text(
                    'No results found',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ];
            }

            return filteredItems.map((item) {
              final isSelected = item == selectedItem;
              return Material(
                type: MaterialType.transparency,
                child: ListTile(
                  selected: isSelected,
                  selectedTileColor: primaryColor.withValues(alpha: 0.1),
                  title: Text(
                    displayName(item),
                    style: TextStyle(
                      fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: primaryColor, size: 20)
                      : null,
                  onTap: () {
                    searchController.closeView(displayName(item));
                    onSelected(item);
                    searchController.text = displayName(item);
                  },
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _birthDateController.dispose();
    _bioController.dispose();
    _countrySearchController.dispose();
    _provinceSearchController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  // ============================================================================
  // Build
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textMutedColor = isDark
        ? AppTheme.darkTextMuted
        : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    // Determine if province and city should be enabled
    final bool isProvinceEnabled = _selectedCountry != null;
    final bool isCityEnabled = _selectedProvince != null;

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
                        color: index == 0
                            ? primaryColor
                            : isDark
                                ? AppTheme.darkSecondary
                                : AppTheme.lightSecondary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 14),
              Text(
                'Basic Info',
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
                                'Tell us about yourself',
                                style: AppTheme.headlineMedium.copyWith(
                                  color: onSurfaceColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'This information will be shown on your profile',
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
                              TextFormField(
                                controller: _nameController,
                                textInputAction: TextInputAction.next,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: onSurfaceColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Full Name',
                                  hintText: 'Enter your full name',
                                  prefixIcon: Icon(
                                    Icons.person_outline,
                                    color: textMutedColor,
                                    size: 22,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  if (value.length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _birthDateController,
                                readOnly: true,
                                onTap: _selectBirthDate,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: onSurfaceColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Date of Birth',
                                  hintText: 'Select your birth date',
                                  prefixIcon: Icon(
                                    Icons.cake_outlined,
                                    color: textMutedColor,
                                    size: 22,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please select your birth date';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4.0),
                                    child: Text(
                                      'Gender',
                                      style: TextStyle(
                                        fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: onSurfaceColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _GenderOption(
                                          label: 'Male',
                                          icon: Icons.male,
                                          isSelected: _selectedGender == 'male',
                                          onTap: () {
                                            setState(() {
                                              _selectedGender = 'male';
                                              _errorMessage = null;
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: _GenderOption(
                                          label: 'Female',
                                          icon: Icons.female,
                                          isSelected:
                                              _selectedGender == 'female',
                                          onTap: () {
                                            setState(() {
                                              _selectedGender = 'female';
                                              _errorMessage = null;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _bioController,
                                maxLines: 3,
                                maxLength: 500,
                                style: AppTheme.bodyLarge.copyWith(
                                  color: onSurfaceColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Bio (optional)',
                                  hintText:
                                      'Tell others a bit about yourself...',
                                  alignLabelWithHint: true,
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 40.0,
                                    ),
                                    child: Icon(
                                      Icons.notes,
                                      color: textMutedColor,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Location section with searchable dropdowns
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4.0,
                                        ),
                                        child: Text(
                                          'Location',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: onSurfaceColor,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: _isLoadingLocation
                                            ? null
                                            : _getCurrentLocation,
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          backgroundColor: primaryColor
                                              .withValues(alpha: 0.06),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                        ),
                                        icon: _isLoadingLocation
                                            ? SizedBox(
                                                height: 14,
                                                width: 14,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: primaryColor,
                                                    ),
                                              )
                                            : Icon(
                                                Icons.my_location,
                                                color: primaryColor,
                                                size: 14,
                                              ),
                                        label: Text(
                                          _isLoadingLocation
                                              ? 'Locating...'
                                              : 'GPS',
                                          style: TextStyle(
                                            fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Country Searchable Dropdown (always enabled)
                                  _buildSearchableDropdown<CountryResponse>(
                                    items: _countries,
                                    selectedItem: _selectedCountry,
                                    hintText: 'Search for a country...',
                                    labelText: 'Country',
                                    displayName: (country) => country.name,
                                    onSelected: _onCountryChanged,
                                    isLoading: _isLoadingCountries,
                                    searchController: _countrySearchController,
                                    leadingIcon: Icon(
                                      Icons.public,
                                      color: textMutedColor,
                                      size: 22,
                                    ),
                                    isEnabled: true,
                                  ),
                                  const SizedBox(height: 16),
                                  // State/Province Searchable Dropdown (enabled only if country selected)
                                  _buildSearchableDropdown<ProvinceResponse>(
                                    items: _provinces,
                                    selectedItem: _selectedProvince,
                                    hintText: isProvinceEnabled
                                        ? 'Search for a state/province...'
                                        : 'Select a country first',
                                    labelText: 'State/Province',
                                    displayName: (province) => province.name,
                                    onSelected: _onProvinceChanged,
                                    isLoading: _isLoadingProvinces,
                                    searchController: _provinceSearchController,
                                    leadingIcon: Icon(
                                      Icons.map_outlined,
                                      color: textMutedColor,
                                      size: 22,
                                    ),
                                    isEnabled: isProvinceEnabled,
                                  ),
                                  const SizedBox(height: 16),
                                  // City Searchable Dropdown (enabled only if province selected)
                                  _buildSearchableDropdown<CityResponse>(
                                    items: _cities,
                                    selectedItem: _selectedCity,
                                    hintText: isCityEnabled
                                        ? 'Search for a city...'
                                        : 'Select a state/province first',
                                    labelText: 'City',
                                    displayName: (city) => city.name,
                                    onSelected: _onCityChanged,
                                    isLoading: _isLoadingCities,
                                    searchController: _citySearchController,
                                    leadingIcon: Icon(
                                      Icons.location_city_outlined,
                                      color: textMutedColor,
                                      size: 22,
                                    ),
                                    isEnabled: isCityEnabled,
                                  ),
                                ],
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
                        child: SizedBox(
                          width: double.infinity,
                          child: AppTheme.gradientButton(
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
                                : Text(
                                    'Continue',
                                    style: AppTheme.button.copyWith(
                                      color: Colors.white,
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
}

class _GenderOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
    final onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.06)
              : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? primaryColor
                  : onSurfaceColor.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTheme.fontFor(!Localizations.localeOf(context).languageCode.contains('en')),
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? primaryColor : onSurfaceColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
