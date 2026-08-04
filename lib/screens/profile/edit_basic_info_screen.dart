// lib/screens/profile/edit_basic_info_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../services/location_service.dart';
import '../../models/location.dart';
import '../../generated/app_localizations.dart';
import '../../widgets/action_toast.dart';

class EditBasicInfoScreen extends StatefulWidget {
  const EditBasicInfoScreen({super.key});

  @override
  State<EditBasicInfoScreen> createState() => _EditBasicInfoScreenState();
}

class _EditBasicInfoScreenState extends State<EditBasicInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  String? _errorMessage;

  // Controllers - pre-filled with user data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();

  // Search controllers for location
  final SearchController _countrySearchController = SearchController();
  final SearchController _provinceSearchController = SearchController();
  final SearchController _citySearchController = SearchController();

  // Selection state
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

  bool _isLoadingCountries = false;
  bool _isLoadingProvinces = false;
  bool _isLoadingCities = false;
  bool _isLoadingLocation = false;

  // Track if we've loaded saved location data
  bool _locationDataLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadCountries();
  }

  void _loadUserData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user != null) {
      // Name
      if (user.name != null) _nameController.text = user.name!;

      // Bio
      if (user.bio != null) _bioController.text = user.bio!;

      // Gender
      if (user.gender != null) _selectedGender = user.gender;

      // Birth Date
      if (user.birthDate != null && user.birthDate!.isNotEmpty) {
        try {
          _selectedBirthDate = DateTime.parse(user.birthDate!);
          _birthDateController.text = user.birthDate!;
        } catch (_) {}
      }

      // Location - store the values, will be matched after countries load
      if (user.lat != null) _lat = user.lat;
      if (user.lng != null) _lng = user.lng;
    }
  }

  Future<void> _loadCountries() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCountries = true;
      _errorMessage = null;
    });

    try {
      final countries = await LocationService.getCountries();
      if (!mounted) return;
      setState(() {
        _countries = countries;
      });

      // Now match saved location data
      _loadSavedLocationData();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load countries';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingCountries = false;
        });
      }
    }
  }

  void _loadSavedLocationData() {
    if (_locationDataLoaded) return;
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) return;

    // Match country
    if (user.country != null && _countries.isNotEmpty) {
      for (var country in _countries) {
        if (country.name == user.country) {
          if (!mounted) return;
          setState(() {
            _selectedCountry = country;
            _countrySearchController.text = country.name;
          });
          // Load states for this country
          if (user.province != null) {
            _loadStates(country.iso2, user.province!, user.city);
          }
          break;
        }
      }
    }

    _locationDataLoaded = true;
  }

  Future<void> _loadStates(String countryIso2, String? provinceName, String? cityName) async {
    if (!mounted) return;
    setState(() {
      _isLoadingProvinces = true;
      _errorMessage = null;
    });

    try {
      final states = await LocationService.getStates(
        countryIso2: countryIso2,
      );
      if (!mounted) return;
      setState(() {
        _provinces = states;
        _isLoadingProvinces = false;
      });

      // Match saved province
      if (provinceName != null && states.isNotEmpty) {
        for (var province in states) {
          if (province.name == provinceName) {
            if (!mounted) return;
            setState(() {
              _selectedProvince = province;
              _provinceSearchController.text = province.name;
            });
            if (cityName != null) {
              _loadCities(countryIso2, province.name, cityName);
            }
            break;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load states';
        _isLoadingProvinces = false;
      });
    }
  }

  Future<void> _loadCities(String countryIso2, String stateName, String? cityName) async {
    if (!mounted) return;
    setState(() {
      _isLoadingCities = true;
      _errorMessage = null;
    });

    try {
      final cities = await LocationService.getCities(
        countryIso2: countryIso2,
        stateName: stateName,
      );
      if (!mounted) return;
      setState(() {
        _cities = cities;
        _isLoadingCities = false;
      });

      // Match saved city
      if (cityName != null && cities.isNotEmpty) {
        for (var city in cities) {
          if (city.name == cityName) {
            if (!mounted) return;
            setState(() {
              _selectedCity = city;
              _citySearchController.text = city.name;
            });
            if (city.latitude != null && city.longitude != null) {
              if (!mounted) return;
              setState(() {
                _lat = city.latitude;
                _lng = city.longitude;
              });
            }
            break;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load cities';
        _isLoadingCities = false;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    if (!mounted) return;
    setState(() {
      _isLoadingLocation = true;
      _errorMessage = null;
    });

    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;
      if (position == null) {
        setState(() {
          _errorMessage = 'Could not get GPS location';
          _isLoadingLocation = false;
        });
        return;
      }

      final location = await LocationService.reverseGeocode(
        lat: position.latitude,
        lng: position.longitude,
      );
      if (!mounted) return;

      if (location == null || location.country == null) {
        setState(() {
          _errorMessage = 'Could not determine your location';
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
          _errorMessage = 'Your country is not supported';
          _isLoadingLocation = false;
        });
        return;
      }

      _resetLocationSelections();

      if (!mounted) return;
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _selectedCountry = matchedCountry;
        _countrySearchController.text = matchedCountry!.name;
      });

      await _loadStatesForGPS(matchedCountry.iso2, location);

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error getting location';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _loadStatesForGPS(String countryIso2, ReverseGeocodeResponse location) async {
    if (!mounted) return;
    try {
      final states = await LocationService.getStates(
        countryIso2: countryIso2,
      );
      if (!mounted) return;
      setState(() {
        _provinces = states;
      });

      if (location.province != null && states.isNotEmpty) {
        for (var province in states) {
          if (province.name.toLowerCase() == location.province!.toLowerCase()) {
            if (!mounted) return;
            setState(() {
              _selectedProvince = province;
              _provinceSearchController.text = province.name;
            });
            await _loadCitiesForGPS(countryIso2, province.name, location.city);
            break;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load states';
      });
    }
  }

  Future<void> _loadCitiesForGPS(String countryIso2, String stateName, String? cityName) async {
    if (!mounted) return;
    try {
      final cities = await LocationService.getCities(
        countryIso2: countryIso2,
        stateName: stateName,
      );
      if (!mounted) return;
      setState(() {
        _cities = cities;
      });

      if (cityName != null && cities.isNotEmpty) {
        for (var city in cities) {
          if (city.name.toLowerCase() == cityName.toLowerCase()) {
            if (!mounted) return;
            setState(() {
              _selectedCity = city;
              _citySearchController.text = city.name;
            });
            break;
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load cities';
      });
    }
  }

  void _resetLocationSelections() {
    if (!mounted) return;
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

  void _onCountryChanged(CountryResponse? country) {
    _resetLocationSelections();

    if (!mounted) return;
    setState(() {
      _selectedCountry = country;
      if (country != null) {
        _countrySearchController.text = country.name;
      } else {
        _countrySearchController.clear();
      }
    });

    if (country != null) {
      _loadStates(country.iso2, null, null);
    }
  }

  void _onProvinceChanged(ProvinceResponse? province) {
    if (!mounted) return;
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
      _loadCities(_selectedCountry!.iso2, province.name, null);
    }
  }

  void _onCityChanged(CityResponse? city) {
    if (!mounted) return;
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
        if (!mounted) return;
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

    if (centroid != null && mounted) {
      setState(() {
        _lat = centroid.latitude;
        _lng = centroid.longitude;
      });
    }
  }

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

    if (pickedDate != null && mounted) {
      setState(() {
        _selectedBirthDate = pickedDate;
        _birthDateController.text =
            '${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleSave() async {
    final t = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final gender = _selectedGender;
    final bio = _bioController.text.trim();
    final birthDate = _birthDateController.text.trim();

    if (gender == null) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Please select your gender');
      return;
    }

    if (_selectedCountry == null || _selectedProvince == null || _selectedCity == null) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Please select your location');
      return;
    }

    if (_lat == null || _lng == null) {
      await _getCityCentroid(_selectedCity!.name);
      if (_lat == null || _lng == null) {
        if (!mounted) return;
        setState(() => _errorMessage = 'Could not determine location coordinates');
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 1. Update basic profile fields via PUT /users/me
      final Map<String, dynamic> profileData = {
        'name': name,
        'gender': gender,
      };

      profileData['bio'] = bio.isEmpty ? null : bio;
      profileData['birth_date'] = birthDate.isEmpty ? null : birthDate;

      debugPrint('📤 1. Updating profile via PUT /users/me: $profileData');
      final profileSuccess = await authProvider.updateProfile(profileData);

      if (!profileSuccess) {
        if (!mounted) return;
        setState(() {
          _errorMessage = authProvider.errorMessage ?? 'Failed to update profile';
          _isSaving = false;
        });
        return;
      }

      // 2. Update location text via PATCH /users/me/location-text
      debugPrint('📤 2. Updating location text via PATCH /users/me/location-text');
      final locationTextSuccess = await LocationService.updateLocationText(
        country: _selectedCountry!.name,
        province: _selectedProvince!.name,
        city: _selectedCity!.name,
      );

      if (!locationTextSuccess) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to update location text';
          _isSaving = false;
        });
        return;
      }

      // 3. Update GPS location via POST /users/me/location
      debugPrint('📤 3. Updating GPS via POST /users/me/location: lat=$_lat, lng=$_lng');
      final gpsSuccess = await LocationService.updateLocationGPS(
        lat: _lat!,
        lng: _lng!,
      );

      if (!gpsSuccess) {
        if (!mounted) return;
        setState(() {
          _errorMessage = 'Failed to update GPS location';
          _isSaving = false;
        });
        return;
      }

      // 4. Refresh user data
      await authProvider.refreshUser();

      if (mounted) {
        showActionToast(context, t.profile_updated_success);
        Navigator.pop(context);
      }

    } catch (e) {
      debugPrint('❌ Save error: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isSaving = false;
      });
    }
  }

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
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isEnabled
                  ? Theme.of(context).colorScheme.onSurface
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
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
              leading: leadingIcon ??
                  Icon(
                    Icons.search,
                    color: isEnabled
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
              trailing: [
                if (selectedItem != null && isEnabled)
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 18,
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  color: isEnabled
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
                ),
              ),
            );
          },
          suggestionsBuilder: (context, searchController) {
            if (!isEnabled) {
              return [
                const ListTile(
                  title: Text(
                    'Please select a country first',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: Colors.grey,
                    ),
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
                      fontFamily: 'Inter',
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ];
            }

            return filteredItems.map((item) {
              final isSelected = item == selectedItem;
              return ListTile(
                selected: isSelected,
                selectedTileColor: primaryColor.withValues(alpha: 0.1),
                title: Text(
                  displayName(item),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                trailing: isSelected
                    ? Icon(
                        Icons.check,
                        color: primaryColor,
                        size: 20,
                      )
                    : null,
                onTap: () {
                  searchController.closeView(displayName(item));
                  onSelected(item);
                  searchController.text = displayName(item);
                },
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = context.isDarkMode;
    final primaryColor = isDark ? AppTheme.darkPrimary : AppTheme.lightPrimary;
    final bgColor = isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
    final textMutedColor = isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
    final onSurfaceColor = colors.onSurface;
    final errorColor = AppTheme.lightError;

    final bool isProvinceEnabled = _selectedCountry != null;
    final bool isCityEnabled = _selectedProvince != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: onSurfaceColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Edit Basic Info',
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_errorMessage != null) ...[
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
                              const SizedBox(height: 20),
                            ],
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: onSurfaceColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: Icon(Icons.person_outline, color: textMutedColor, size: 22),
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
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: onSurfaceColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                hintText: 'Select your birth date',
                                prefixIcon: Icon(Icons.cake_outlined, color: textMutedColor, size: 22),
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
                                      fontFamily: 'Inter',
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
                                        isSelected: _selectedGender == 'female',
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
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                color: onSurfaceColor,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Bio (optional)',
                                hintText: 'Tell others a bit about yourself...',
                                alignLabelWithHint: true,
                                prefixIcon: Padding(
                                  padding: const EdgeInsets.only(bottom: 40.0),
                                  child: Icon(Icons.notes, color: textMutedColor, size: 22),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(left: 4.0),
                                      child: Text(
                                        'Location',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: onSurfaceColor,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton.icon(
                                      onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        backgroundColor: primaryColor.withValues(alpha: 0.06),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                      icon: _isLoadingLocation
                                          ? SizedBox(
                                              height: 14,
                                              width: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: primaryColor,
                                              ),
                                            )
                                          : Icon(Icons.my_location, color: primaryColor, size: 14),
                                      label: Text(
                                        _isLoadingLocation ? 'Locating...' : 'GPS',
                                        style: TextStyle(
                                          fontFamily: 'Inter',
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
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
                                _buildSearchableDropdown<ProvinceResponse>(
                                  items: _provinces,
                                  selectedItem: _selectedProvince,
                                  hintText: isProvinceEnabled ? 'Search for a state/province...' : 'Select a country first',
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
                                _buildSearchableDropdown<CityResponse>(
                                  items: _cities,
                                  selectedItem: _selectedCity,
                                  hintText: isCityEnabled ? 'Search for a city...' : 'Select a state/province first',
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
                      padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 24.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
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
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Save',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
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
          color: isSelected ? primaryColor.withValues(alpha: 0.06) : surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryColor : borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: primaryColor.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : onSurfaceColor.withValues(alpha: 0.6),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
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