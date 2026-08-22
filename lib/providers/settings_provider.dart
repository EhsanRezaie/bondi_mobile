import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

class SettingsProvider extends ChangeNotifier {
  bool _disposed = false;

  static const String _darkModeKey = 'dark_mode';

  bool _darkMode = true;
  bool _hideLastSeen = false;
  bool _hideOnlineStatus = false;
  bool _pushEnabled = true;
  bool _likeNotifications = true;
  bool _matchNotifications = true;
  bool _messageNotifications = true;
  String _language = 'en';
  bool _isSaving = false;

  bool get darkMode => _darkMode;
  bool get hideLastSeen => _hideLastSeen;
  bool get hideOnlineStatus => _hideOnlineStatus;
  bool get pushEnabled => _pushEnabled;
  bool get likeNotifications => _likeNotifications;
  bool get matchNotifications => _matchNotifications;
  bool get messageNotifications => _messageNotifications;
  String get language => _language;
  bool get isSaving => _isSaving;
  bool _loaded = false;

  SettingsProvider() {
    _loadSavedDarkMode();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

   Future<void> _loadSavedDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    final darkMode = prefs.getBool(_darkModeKey) ?? true;
    if (_darkMode != darkMode) {
      _darkMode = darkMode;
      _safeNotify();
    }
  }

  Future<void> _saveDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, value);
  }

  void loadFromUser(User? user) {
    if (_loaded || user?.settings == null) return;
    _loaded = true;
    final s = user!.settings!;
    _hideLastSeen = s.hideLastSeen;
    _hideOnlineStatus = s.hideOnlineStatus;
    _pushEnabled = s.pushEnabled;
    _likeNotifications = s.likeNotifications;
    _matchNotifications = s.matchNotifications;
    _messageNotifications = s.messageNotifications;
    _language = s.language;
    // Dark mode is driven by the local preference (default: dark), not the
    // backend default, so the theme stays dark until the user changes it.
    _safeNotify();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _darkMode = value;
    _safeNotify();
    _saveDarkMode(value);
    await _updateApi({'dark_mode': value});
  }

  Future<void> toggleHideLastSeen(bool value) async {
    _hideLastSeen = value;
    _safeNotify();
    await _updateApi({'hide_last_seen': value});
  }

  Future<void> toggleHideOnlineStatus(bool value) async {
    _hideOnlineStatus = value;
    _safeNotify();
    await _updateApi({'hide_online_status': value});
  }

  Future<void> togglePushEnabled(bool value) async {
    _pushEnabled = value;
    _safeNotify();
    await _updateApi({'push_enabled': value});
  }

  Future<void> toggleLikeNotifications(bool value) async {
    _likeNotifications = value;
    _safeNotify();
    await _updateApi({'like_notifications': value});
  }

  Future<void> toggleMatchNotifications(bool value) async {
    _matchNotifications = value;
    _safeNotify();
    await _updateApi({'match_notifications': value});
  }

  Future<void> toggleMessageNotifications(bool value) async {
    _messageNotifications = value;
    _safeNotify();
    await _updateApi({'message_notifications': value});
  }

  Future<void> changeLanguage(String value) async {
    _language = value;
    _safeNotify();
    await _updateApi({'language': value});
  }

  Future<void> _updateApi(Map<String, dynamic> data) async {
    _isSaving = true;
    try {
      await AuthService.updateSettings(data);
    } catch (_) {
    } finally {
      _isSaving = false;
    }
  }
}

