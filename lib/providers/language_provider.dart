// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  bool _disposed = false;

  static const String _languageKey = 'selected_language';
  
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  String get currentLanguageCode => _locale.languageCode;

  bool get isEnglish => _locale.languageCode == 'en';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLanguage = prefs.getString(_languageKey);
    if (savedLanguage != null && savedLanguage != _locale.languageCode) {
      _locale = Locale(savedLanguage);
      _safeNotify();
    }
  }

  void changeLanguage(String languageCode) {
    if (_locale.languageCode == languageCode) return;
    
    _locale = Locale(languageCode);
    
    // Save to SharedPreferences
    _saveLanguage(languageCode);
    
    _safeNotify();
  }

  Future<void> _saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  void setLanguage(String languageCode) {
    if (_locale.languageCode == languageCode) return;
    _locale = Locale(languageCode);
    _safeNotify();
  }
}
