import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/services/discover_service.dart';
import 'package:dating_app/services/chat_service.dart';

class DiscoverProvider extends ChangeNotifier {
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

  List<DiscoverProfile> _profiles = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _total = 0;
  String? _nextCursor;
  bool _hasMore = true;
  final Set<String> _seenUserIds = {};

  bool _isPremium = false;
  int _likesRemaining = 0;
  int _dailyLikesLimit = 20;
  int _chatsRemaining = 0;
  int _dailyChatsLimit = 10;

  String? _genderFilter;
  int _ageMin = 18;
  int? _ageMax;
  int? _distanceKm;

  static const _keyGender = 'discover_gender';
  static const _keyAgeMin = 'discover_age_min';
  static const _keyAgeMax = 'discover_age_max';
  static const _keyDistance = 'discover_distance_km';

  /// Number of profiles fetched per request. Also caps how many passed cards
  /// can be reverted (the revert stack matches the page size).
  static const int pageSize = 20;

  final List<DiscoverProfile> _passed = [];

  List<DiscoverProfile> get profiles => _profiles;
  List<DiscoverProfile> get passedProfiles => List.unmodifiable(_passed);
  bool get canRevert => _passed.isNotEmpty;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
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

  bool get canWidenDistance => _distanceKm != null;
  bool get canWidenAge => _ageMax != null;
  bool get allFiltersMaxed => !canWidenDistance && !canWidenAge;

  bool get isLikeBlocked => !_isPremium && _likesRemaining <= 0;
  bool get isChatBlocked => !_isPremium && _chatsRemaining <= 0;

  /// Top of the deck plus the stacked cards behind it, so the next profile is
  /// already visible while the current card is being swiped (no black screen).
  List<DiscoverProfile> get visibleProfiles => _profiles.take(3).toList();

  bool get hasProfiles => _profiles.isNotEmpty;

  double get likesProgress {
    if (_isPremium || _dailyLikesLimit == 0) return 1.0;
    return _likesRemaining / _dailyLikesLimit;
  }

  double get chatsProgress {
    if (_isPremium || _dailyChatsLimit == 0) return 1.0;
    return _chatsRemaining / _dailyChatsLimit;
  }

  // ── Filter persistence ──────────────────────────────────────────────

  Future<void> _loadFilters() async {
    final prefs = await SharedPreferences.getInstance();
    final gender = prefs.getString(_keyGender);
    final ageMin = prefs.getInt(_keyAgeMin);
    final ageMax = prefs.getInt(_keyAgeMax);
    final distance = prefs.getInt(_keyDistance);

    _genderFilter = gender == 'null' ? null : gender;
    _ageMin = ageMin ?? 18;
    _ageMax = ageMax == -1 ? null : ageMax;
    _distanceKm = distance == -1 ? null : distance;
  }

  Future<void> _saveFilters() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGender, _genderFilter ?? 'null');
    await prefs.setInt(_keyAgeMin, _ageMin);
    await prefs.setInt(_keyAgeMax, _ageMax ?? -1);
    await prefs.setInt(_keyDistance, _distanceKm ?? -1);
  }

  // ── Profile loading ─────────────────────────────────────────────────

  bool _filtersLoaded = false;

  Future<void> loadProfiles() async {
    if (!_filtersLoaded) {
      await _loadFilters();
      _filtersLoaded = true;
    }

    _isLoading = true;
    _errorMessage = null;
    _nextCursor = null;
    _seenUserIds.clear();
    _hasMore = true;
    _safeNotify();

    try {
      final response = await DiscoverService.getDiscoverProfiles(
        gender: _genderFilter,
        ageMin: _ageMin,
        ageMax: _ageMax,
        distanceKm: _distanceKm,
        limit: pageSize,
        offset: 0,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        _profiles = (data['users'] as List)
            .map((j) => DiscoverProfile.fromJson(j as Map<String, dynamic>))
            .toList();
        _seenUserIds.addAll(_profiles.map((p) => p.id));
        _total = data['total'] ?? 0;
        final next = data['next_cursor'] as String?;
        _nextCursor = (next != null && next.isNotEmpty) ? next : null;
        _hasMore = _nextCursor != null ||
            (_profiles.isNotEmpty && _profiles.length < _total);
      } else {
        _errorMessage = 'Failed to load profiles';
      }
    } on DioException catch (e) {
      debugPrint('DiscoverProvider.loadProfiles DioError: ${e.message} (status: ${e.response?.statusCode})');
      _errorMessage = 'Network error. Please try again.';
    } catch (e) {
      debugPrint('DiscoverProvider.loadProfiles Error: $e');
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
      final response = await DiscoverService.getDiscoverProfiles(
        gender: _genderFilter,
        ageMin: _ageMin,
        ageMax: _ageMax,
        distanceKm: _distanceKm,
        limit: pageSize,
        cursor: _nextCursor,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final more = (data['users'] as List)
            .map((j) => DiscoverProfile.fromJson(j as Map<String, dynamic>))
            .where((p) => _seenUserIds.add(p.id))
            .toList();
        _profiles.addAll(more);
        _total = data['total'] ?? _total;
        final next = data['next_cursor'] as String?;
        _nextCursor = (next != null && next.isNotEmpty) ? next : null;
        _hasMore = _nextCursor != null ||
            (_profiles.isNotEmpty && _profiles.length < _total);
      }
    } catch (_) {}

    _isLoadingMore = false;
    _safeNotify();
  }

  // ── Swipe actions ───────────────────────────────────────────────────

  Future<Map<String, dynamic>?> swipeRight(DiscoverProfile profile) async {
    if (isLikeBlocked) return null;

    try {
      final response = await DiscoverService.swipeUser(profile.id, 'like');
      if (response.statusCode == 200) {
        _profiles.removeWhere((p) => p.id == profile.id);
        final data = response.data as Map<String, dynamic>;
        await _refreshLimits(notify: false);
        _safeNotify();
        _refillIfLow();
        if (data['matched'] == true) {
          return data;
        }
        return {};
      }
      // A reverted (previously passed) card was liked. The backend still had
      // the pass recorded; treat the like as accepted and advance the deck.
      if (response.statusCode == 400) {
        _profiles.removeWhere((p) => p.id == profile.id);
        _passed.removeWhere((p) => p.id == profile.id);
        _safeNotify();
        _refillIfLow();
        return {};
      }
    } catch (_) {}
    return null;
  }

  /// Returns `true` when the pass was recorded and the card advanced the deck,
  /// `false` when the API call failed (caller should snap the card back).
  Future<bool> swipeLeft(DiscoverProfile profile) async {
    try {
      final response = await DiscoverService.swipeUser(profile.id, 'pass');
      // 200 = fresh pass; 400 = the card was already passed (e.g. reverted and
      // re-passed). Either way the pass stands, so remove it and keep it in the
      // revert stack so the user can undo again.
      if (response.statusCode == 200 || response.statusCode == 400) {
        _profiles.removeWhere((p) => p.id == profile.id);
        if (!_passed.any((p) => p.id == profile.id)) {
          _passed.insert(0, profile);
          if (_passed.length > pageSize) {
            _passed.removeRange(pageSize, _passed.length);
          }
        }
        _refillIfLow();
        _safeNotify();
        return true;
      }
    } catch (_) {}
    return false;
  }

  /// Pops the most recently passed card back onto the top of the deck.
  /// Local-only: the backend keeps the original pass until re-swiped.
  void revertPass() {
    if (_passed.isEmpty) return;
    final profile = _passed.removeAt(0);
    _profiles.insert(0, profile);
    _safeNotify();
  }

  /// Pure chat start — no like is recorded. Creates or reuses the chat for the
  /// pair (POST /chats) and returns the backend response so the caller can
  /// redirect to the chat thread.
  Future<Map<String, dynamic>?> swipeAndChat(
    DiscoverProfile profile, {
    String? message,
  }) async {
    try {
      final response = await ChatService.createChat(
        profile.id,
        message ?? '',
      );
      if (response.statusCode != 200 && response.statusCode != 201) return null;

      await _refreshLimits(notify: false);
      _safeNotify();

      return response.data as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  void _refillIfLow() {
    if (_profiles.length <= 2 && _hasMore) {
      loadMore();
    }
  }

  // ── Limits ──────────────────────────────────────────────────────────

  Future<void> _refreshLimits({bool notify = true}) async {
    try {
      final response = await DiscoverService.getMyLimits();
      if (response.statusCode == 200) {
        final data = response.data;
        _isPremium = data['is_premium'] ?? false;
        _likesRemaining = data['likes_remaining_today'] ?? 0;
        _dailyLikesLimit = data['daily_likes_limit'] ?? 20;
        _chatsRemaining = data['chats_remaining_today'] ?? 0;
        _dailyChatsLimit = data['daily_chats_limit'] ?? 10;
        if (notify) _safeNotify();
      }
    } catch (_) {}
  }

  // ── Filter setters ──────────────────────────────────────────────────

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

  void widenDistance() {
    final current = _distanceKm ?? 50;
    final next = (current + 50).clamp(1, 500);
    _distanceKm = next >= 500 ? null : next;
    _saveFilters();
    loadProfiles();
  }

  void widenAge() {
    final current = _ageMax ?? 80;
    final next = (current + 2).clamp(18, 80);
    _ageMax = next >= 80 ? null : next;
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

  void resetFilters() {
    _genderFilter = null;
    _ageMin = 18;
    _ageMax = null;
    _distanceKm = null;
    _saveFilters();
    loadProfiles();
  }
}
