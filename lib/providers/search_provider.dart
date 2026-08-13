import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/services/search_service.dart';
import 'package:dating_app/services/chat_service.dart';

class SearchProvider extends ChangeNotifier {
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool _notifyScheduled = false;

  void _safeNotify() {
    if (_disposed || _notifyScheduled) return;
    _notifyScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      if (!_disposed) notifyListeners();
    });
  }

  // ── Results state ──────────────────────────────────────────────
  List<DiscoverProfile> _users = [];
  Set<String> _seenUserIds = {};
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _total = 0;
  String? _nextCursor;
  int _currentPage = 0;
  bool _hasMore = true;
  static const int _pageSize = 9;

  // ── Basic filters (quick bar) ──────────────────────────────────
  String? _genderFilter;
  int _ageMin = 18;
  int? _ageMax;
  int? _distanceKm;
  String _sortBy = 'recent';
  String _sortOrder = 'desc';

  // ── Advanced filters ───────────────────────────────────────────
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
  String? _country;
  String? _province;
  String? _city;
  String? _religion;
  String? _ethnicity;
  bool? _hasPhotos;
  bool? _isVerified;
  List<String> _interests = [];
  List<String> _languages = [];

  // ── Limits ─────────────────────────────────────────────────────
  bool _isPremium = false;
  int _likesRemaining = 0;
  int _dailyLikesLimit = 20;
  int _chatsRemaining = 0;
  int _dailyChatsLimit = 10;

  // ── SharedPreferences keys ─────────────────────────────────────
  static const _prefix = 'search_';
  static const _keyGender = '${_prefix}gender';
  static const _keyAgeMin = '${_prefix}age_min';
  static const _keyAgeMax = '${_prefix}age_max';
  static const _keyDistance = '${_prefix}distance_km';
  static const _keySortBy = '${_prefix}sort_by';
  static const _keySortOrder = '${_prefix}sort_order';
  static const _keyHeightMin = '${_prefix}height_min';
  static const _keyHeightMax = '${_prefix}height_max';
  static const _keyWeightMin = '${_prefix}weight_min';
  static const _keyWeightMax = '${_prefix}weight_max';
  static const _keyBodyType = '${_prefix}body_type';
  static const _keyRelationship = '${_prefix}relationship';
  static const _keyEducation = '${_prefix}education';
  static const _keySmoking = '${_prefix}smoking';
  static const _keyDrinking = '${_prefix}drinking';
  static const _keyPolitical = '${_prefix}political';
  static const _keyChildren = '${_prefix}children';
  static const _keyLiving = '${_prefix}living';
  static const _keyCountry = '${_prefix}country';
  static const _keyProvince = '${_prefix}province';
  static const _keyCity = '${_prefix}city';
  static const _keyReligion = '${_prefix}religion';
  static const _keyEthnicity = '${_prefix}ethnicity';
  static const _keyHasPhotos = '${_prefix}has_photos';
  static const _keyIsVerified = '${_prefix}is_verified';
  static const _keyInterests = '${_prefix}interests';
  static const _keyLanguages = '${_prefix}languages';

  // ── Getters ────────────────────────────────────────────────────
  List<DiscoverProfile> get users => _users;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get total => _total;
  int get currentPage => _currentPage;
  bool get hasMore => _hasMore;
  bool get isPremium => _isPremium;
  int get likesRemaining => _likesRemaining;
  int get dailyLikesLimit => _dailyLikesLimit;
  int get chatsRemaining => _chatsRemaining;
  int get dailyChatsLimit => _dailyChatsLimit;
  String? get genderFilter => _genderFilter;
  int get ageMin => _ageMin;
  int? get ageMax => _ageMax;
  int? get distanceKm => _distanceKm;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  int? get heightMin => _heightMin;
  int? get heightMax => _heightMax;
  int? get weightMin => _weightMin;
  int? get weightMax => _weightMax;
  String? get bodyType => _bodyType;
  String? get relationshipStatus => _relationshipStatus;
  String? get education => _education;
  String? get smoking => _smoking;
  String? get drinking => _drinking;
  String? get politicalOrientation => _politicalOrientation;
  String? get childrenStatus => _childrenStatus;
  String? get livingSituation => _livingSituation;
  String? get country => _country;
  String? get province => _province;
  String? get city => _city;
  String? get religion => _religion;
  String? get ethnicity => _ethnicity;
  bool? get hasPhotos => _hasPhotos;
  bool? get isVerified => _isVerified;
  List<String> get interests => _interests;
  List<String> get languages => _languages;

  bool get isLikeBlocked => !_isPremium && _likesRemaining <= 0;
  bool get isChatBlocked => !_isPremium && _chatsRemaining <= 0;

  int get totalPages => _total == 0 ? 0 : (_total / _pageSize).ceil();
  bool get canLoadNext => _currentPage < totalPages - 1;
  bool get canLoadPrev => _currentPage > 0;

  bool get hasActiveFilters =>
      _genderFilter != null ||
      _ageMin != 18 ||
      _ageMax != null ||
      _distanceKm != null ||
      _heightMin != null ||
      _heightMax != null ||
      _weightMin != null ||
      _weightMax != null ||
      _bodyType != null ||
      _relationshipStatus != null ||
      _education != null ||
      _smoking != null ||
      _drinking != null ||
      _politicalOrientation != null ||
      _childrenStatus != null ||
      _livingSituation != null ||
      _country != null ||
      _province != null ||
      _city != null ||
      _religion != null ||
      _ethnicity != null ||
      _hasPhotos == true ||
      _isVerified == true ||
      _interests.isNotEmpty ||
      _languages.isNotEmpty;

  int get activeFilterCount {
    int count = 0;
    if (_genderFilter != null) count++;
    if (_ageMin != 18 || _ageMax != null) count++;
    if (_distanceKm != null) count++;
    if (_heightMin != null || _heightMax != null) count++;
    if (_weightMin != null || _weightMax != null) count++;
    if (_bodyType != null) count++;
    if (_relationshipStatus != null) count++;
    if (_education != null) count++;
    if (_smoking != null) count++;
    if (_drinking != null) count++;
    if (_politicalOrientation != null) count++;
    if (_childrenStatus != null) count++;
    if (_livingSituation != null) count++;
    if (_country != null) count++;
    if (_province != null) count++;
    if (_city != null) count++;
    if (_religion != null) count++;
    if (_ethnicity != null) count++;
    if (_hasPhotos == true) count++;
    if (_isVerified == true) count++;
    if (_interests.isNotEmpty) count++;
    if (_languages.isNotEmpty) count++;
    return count;
  }

  double get likesProgress {
    if (_isPremium || _dailyLikesLimit == 0) return 1.0;
    return _likesRemaining / _dailyLikesLimit;
  }

  double get chatsProgress {
    if (_isPremium || _dailyChatsLimit == 0) return 1.0;
    return _chatsRemaining / _dailyChatsLimit;
  }

  // ── Filter persistence ─────────────────────────────────────────

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString(_keyGender);
    final ageMin = prefs.getInt(_keyAgeMin);
    final ageMax = prefs.getInt(_keyAgeMax);
    final distance = prefs.getInt(_keyDistance);
    final sortBy = prefs.getString(_keySortBy);
    final sortOrder = prefs.getString(_keySortOrder);
    final heightMin = prefs.getInt(_keyHeightMin);
    final heightMax = prefs.getInt(_keyHeightMax);
    final weightMin = prefs.getInt(_keyWeightMin);
    final weightMax = prefs.getInt(_keyWeightMax);
    final bodyType = prefs.getString(_keyBodyType);
    final relationship = prefs.getString(_keyRelationship);
    final education = prefs.getString(_keyEducation);
    final smoking = prefs.getString(_keySmoking);
    final drinking = prefs.getString(_keyDrinking);
    final political = prefs.getString(_keyPolitical);
    final children = prefs.getString(_keyChildren);
    final living = prefs.getString(_keyLiving);
    final country = prefs.getString(_keyCountry);
    final province = prefs.getString(_keyProvince);
    final city = prefs.getString(_keyCity);
    final religion = prefs.getString(_keyReligion);
    final ethnicity = prefs.getString(_keyEthnicity);
    final hasPhotos = prefs.getBool(_keyHasPhotos);
    final isVerified = prefs.getBool(_keyIsVerified);
    final interests = prefs.getString(_keyInterests);
    final languages = prefs.getString(_keyLanguages);

    _genderFilter = gender == 'null' ? null : gender;
    _ageMin = ageMin ?? 18;
    _ageMax = ageMax == -1 ? null : ageMax;
    _distanceKm = distance == -1 ? null : distance;
    _sortBy = sortBy ?? 'recent';
    _sortOrder = sortOrder ?? 'desc';
    _heightMin = heightMin == -1 ? null : heightMin;
    _heightMax = heightMax == -1 ? null : heightMax;
    _weightMin = weightMin == -1 ? null : weightMin;
    _weightMax = weightMax == -1 ? null : weightMax;
    _bodyType = bodyType == 'null' ? null : bodyType;
    _relationshipStatus = relationship == 'null' ? null : relationship;
    _education = education == 'null' ? null : education;
    _smoking = smoking == 'null' ? null : smoking;
    _drinking = drinking == 'null' ? null : drinking;
    _politicalOrientation = political == 'null' ? null : political;
    _childrenStatus = children == 'null' ? null : children;
    _livingSituation = living == 'null' ? null : living;
    _country = country == 'null' ? null : country;
    _province = province == 'null' ? null : province;
    _city = city == 'null' ? null : city;
    _religion = religion == 'null' ? null : religion;
    _ethnicity = ethnicity == 'null' ? null : ethnicity;
    _hasPhotos = hasPhotos;
    _isVerified = isVerified;
    _interests = interests != null && interests.isNotEmpty
        ? interests.split(',').where((s) => s.isNotEmpty).toList()
        : [];
    _languages = languages != null && languages.isNotEmpty
        ? languages.split(',').where((s) => s.isNotEmpty).toList()
        : [];
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGender, _genderFilter ?? 'null');
    await prefs.setInt(_keyAgeMin, _ageMin);
    await prefs.setInt(_keyAgeMax, _ageMax ?? -1);
    await prefs.setInt(_keyDistance, _distanceKm ?? -1);
    await prefs.setString(_keySortBy, _sortBy);
    await prefs.setString(_keySortOrder, _sortOrder);
    await prefs.setInt(_keyHeightMin, _heightMin ?? -1);
    await prefs.setInt(_keyHeightMax, _heightMax ?? -1);
    await prefs.setInt(_keyWeightMin, _weightMin ?? -1);
    await prefs.setInt(_keyWeightMax, _weightMax ?? -1);
    await prefs.setString(_keyBodyType, _bodyType ?? 'null');
    await prefs.setString(_keyRelationship, _relationshipStatus ?? 'null');
    await prefs.setString(_keyEducation, _education ?? 'null');
    await prefs.setString(_keySmoking, _smoking ?? 'null');
    await prefs.setString(_keyDrinking, _drinking ?? 'null');
    await prefs.setString(_keyPolitical, _politicalOrientation ?? 'null');
    await prefs.setString(_keyChildren, _childrenStatus ?? 'null');
    await prefs.setString(_keyLiving, _livingSituation ?? 'null');
    await prefs.setString(_keyCountry, _country ?? 'null');
    await prefs.setString(_keyProvince, _province ?? 'null');
    await prefs.setString(_keyCity, _city ?? 'null');
    await prefs.setString(_keyReligion, _religion ?? 'null');
    await prefs.setString(_keyEthnicity, _ethnicity ?? 'null');
    if (_hasPhotos != null) await prefs.setBool(_keyHasPhotos, _hasPhotos!);
    if (_isVerified != null) await prefs.setBool(_keyIsVerified, _isVerified!);
    await prefs.setString(_keyInterests, _interests.join(','));
    await prefs.setString(_keyLanguages, _languages.join(','));
  }

  // ── Profile loading ────────────────────────────────────────────

  bool _filtersLoaded = false;

  Future<void> loadProfiles() async {
    if (!_filtersLoaded) {
      await _loadFilters();
      _filtersLoaded = true;
    }

    _isLoading = true;
    _errorMessage = null;
    _nextCursor = null;
    _currentPage = 0;
    _hasMore = true;
    _safeNotify();

    try {
      final response = await SearchService.search(
        gender: _genderFilter,
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
        country: _country,
        province: _province,
        city: _city,
        religion: _religion,
        ethnicity: _ethnicity,
        languages: _languages.isNotEmpty ? _languages : null,
        interests: _interests.isNotEmpty ? _interests : null,
        hasPhotos: _hasPhotos,
        isVerified: _isVerified,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        limit: _pageSize,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final usersList = data['users'] as List;
        _users = usersList
            .map((j) => DiscoverProfile.fromJson(j as Map<String, dynamic>))
            .toList();
        _seenUserIds = {for (final u in _users) u.id};
        _total = data['total'] ?? 0;
        _nextCursor = data['next_cursor'];
        _hasMore = _nextCursor != null && _nextCursor!.isNotEmpty;
      } else {
        _errorMessage = 'Failed to load profiles';
      }
    } on DioException catch (e) {
      debugPrint('SearchProvider.loadProfiles DioError: ${e.message} (status: ${e.response?.statusCode})');
      _errorMessage = 'Network error. Please try again.';
    } catch (e) {
      debugPrint('SearchProvider.loadProfiles Error: $e');
      _errorMessage = 'Something went wrong';
    }

    _isLoading = false;
    _safeNotify();

    await _refreshLimits();
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    _safeNotify();

    try {
      // Keyset (cursor) pagination from the backend prevents duplicates even
      // when the sort order shifts between pages. The dedup set + backfill loop
      // remain as a safety net for any overlapping cursor responses.
      var added = 0;
      var pagesFetched = 0;
      while (added < _pageSize && _hasMore && pagesFetched < 4) {
        pagesFetched++;
        final response = await SearchService.search(
          gender: _genderFilter,
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
          country: _country,
          province: _province,
          city: _city,
          religion: _religion,
          ethnicity: _ethnicity,
          languages: _languages.isNotEmpty ? _languages : null,
          interests: _interests.isNotEmpty ? _interests : null,
          hasPhotos: _hasPhotos,
          isVerified: _isVerified,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
          limit: _pageSize,
          cursor: _nextCursor,
        );

        if (response.statusCode != 200) break;

        final data = response.data;
        final page = (data['users'] as List)
            .map((j) => DiscoverProfile.fromJson(j as Map<String, dynamic>))
            .toList();
        _total = data['total'] ?? _total;
        _nextCursor = data['next_cursor'];
        _hasMore = _nextCursor != null && _nextCursor!.isNotEmpty;

        final fresh = page.where((u) => _seenUserIds.add(u.id)).toList();
        _users.addAll(fresh);
        added += fresh.length;
        if (page.isEmpty) break;
      }
    } catch (e) {
      debugPrint('SearchProvider.loadMore Error: $e');
    }

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Actions ────────────────────────────────────────────────────

Future<Map<String, dynamic>?> likeUser(DiscoverProfile profile) async {
    if (isLikeBlocked) return null;

    try {
      final response = await SearchService.swipeUser(profile.id, 'like');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        // Apply locally so the grid card shows the liked badge without
        // needing a full reload (no loading flash, no scroll reset).
        final index = _users.indexWhere((u) => u.id == profile.id);
        if (index != -1) {
          _users[index] = _users[index].copyWith(
            currentUserAction: data['matched'] == true ? 'matched' : 'like',
          );
          _safeNotify();
        }
        await _refreshLimits();
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Pure chat start — no like is recorded. Creates or reuses the chat for the
  /// pair (POST /chats) and returns the backend response so the caller can
  /// redirect to the chat thread.
  Future<Map<String, dynamic>?> chatWithUser(
    DiscoverProfile profile, {
    String? message,
  }) async {
    try {
      final response = await ChatService.createChat(
        profile.id,
        message ?? '',
      );
      if (response.statusCode != 200 && response.statusCode != 201) return null;

      await _refreshLimits();

      return response.data as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  // ── Limits ─────────────────────────────────────────────────────

  Future<void> refreshLimits() async {
    await _refreshLimits();
  }

  Future<void> _refreshLimits() async {
    try {
      final response = await SearchService.getMyLimits();
      if (response.statusCode == 200) {
        final data = response.data;
        _isPremium = data['is_premium'] ?? false;
        _likesRemaining = data['likes_remaining_today'] ?? 0;
        _dailyLikesLimit = data['daily_likes_limit'] ?? 20;
        _chatsRemaining = data['chats_remaining_today'] ?? 0;
        _dailyChatsLimit = data['daily_chats_limit'] ?? 10;
        _safeNotify();
      }
    } catch (_) {}
  }

  // ── Filter setters ─────────────────────────────────────────────

  void setGenderFilter(String? gender) {
    _genderFilter = gender;
    _saveFilters();
    loadProfiles();
  }

  void setAgeRange(int min, int? max) {
    _ageMin = min;
    _ageMax = max;
    _saveFilters();
    loadProfiles();
  }

  void setDistance(int? km) {
    _distanceKm = km;
    _saveFilters();
    loadProfiles();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _saveFilters();
    loadProfiles();
  }

  void setAllFilters({
    String? gender,
    int? ageMin,
    int? ageMax,
    int? distanceKm,
    int? heightMin,
    int? heightMax,
    int? weightMin,
    int? weightMax,
    String? bodyType,
    String? relationshipStatus,
    String? education,
    String? smoking,
    String? drinking,
    String? politicalOrientation,
    String? childrenStatus,
    String? livingSituation,
    String? country,
    String? province,
    String? city,
    String? religion,
    String? ethnicity,
    List<String>? interests,
    List<String>? languages,
    bool? hasPhotos,
    bool? isVerified,
    String? sortBy,
    String? sortOrder,
  }) {
    _genderFilter = gender;
    _ageMin = ageMin ?? 18;
    _ageMax = ageMax;
    _distanceKm = distanceKm;
    _heightMin = heightMin;
    _heightMax = heightMax;
    _weightMin = weightMin;
    _weightMax = weightMax;
    _bodyType = bodyType;
    _relationshipStatus = relationshipStatus;
    _education = education;
    _smoking = smoking;
    _drinking = drinking;
    _politicalOrientation = politicalOrientation;
    _childrenStatus = childrenStatus;
    _livingSituation = livingSituation;
    _country = country;
    _province = province;
    _city = city;
    _religion = religion;
    _ethnicity = ethnicity;
    _interests = interests ?? [];
    _languages = languages ?? [];
    _hasPhotos = hasPhotos;
    _isVerified = isVerified;
    if (sortBy != null) _sortBy = sortBy;
    if (sortOrder != null) _sortOrder = sortOrder;
    _saveFilters();
    loadProfiles();
  }

  void resetFilters() {
    _genderFilter = null;
    _ageMin = 18;
    _ageMax = null;
    _distanceKm = null;
    _sortBy = 'recent';
    _sortOrder = 'desc';
    _heightMin = null;
    _heightMax = null;
    _weightMin = null;
    _weightMax = null;
    _bodyType = null;
    _relationshipStatus = null;
    _education = null;
    _smoking = null;
    _drinking = null;
    _politicalOrientation = null;
    _childrenStatus = null;
    _livingSituation = null;
    _country = null;
    _province = null;
    _city = null;
    _religion = null;
    _ethnicity = null;
    _hasPhotos = null;
    _isVerified = null;
    _interests = [];
    _languages = [];
    _saveFilters();
    loadProfiles();
  }

  void refresh() {
    loadProfiles();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }
}
