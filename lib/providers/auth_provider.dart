// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:dating_app/generated/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/push_service.dart';
import '../models/user.dart';

class AuthProvider extends ChangeNotifier {
  bool _disposed = false;

  final StorageService _storageService = StorageService();

  User? _user;
  String? _email;
  bool _isLoading = false;
  bool _isAuthenticated = false;
  bool _isServerHealthy = true;
  String? _serverError;
  String? _errorMessage;

  User? get user => _user;
  String? get email => _email;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  bool get isServerHealthy => _isServerHealthy;
  String? get serverError => _serverError;
  String? get errorMessage => _errorMessage;

  AuthProvider();

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

   void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  // ============================================================
  // Initialize app - check server health + auth status
  // ============================================================
  Future<bool> initializeApp() async {
    _isLoading = true;
    _isServerHealthy = true;
    _serverError = null;
    _isAuthenticated = false;
    _user = null;
    _safeNotify();

    final results = await Future.wait([
      _checkServerHealth(),
      _storageService.hasTokens(),
    ]);

    final isHealthy = results[0];
    final hasTokens = results[1];

    if (!isHealthy) {
      _isLoading = false;
      _isServerHealthy = false;
      _serverError = 'Server connection failed';
      _safeNotify();
      return false;
    }

    if (!hasTokens) {
      _isLoading = false;
      _isAuthenticated = false;
      _user = null;
      _safeNotify();
      return false;
    }

    final isValid = await _validateToken();
    if (!isValid) {
      await _storageService.clearTokens();
      _isAuthenticated = false;
      _user = null;
      _isLoading = false;
      _safeNotify();
      return false;
    }

    _isAuthenticated = true;
    _isLoading = false;
    _safeNotify();
    return true;
  }

  Future<bool> _checkServerHealth() async {
    try {
      final response = await AuthService.healthCheck();
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> _validateToken() async {
    try {
      final response = await AuthService.getCurrentUser();
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ============================================================
  // Step 1: Register Init - request verification code
  // POST /auth/register/init
  // ============================================================
  Future<bool> registerInit(String email, BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.registerInit(email);
      if (response.statusCode == 200) {
        _email = email;
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? t.error_something_wrong;
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        _errorMessage = t.error_email_exists;
      } else if (e.response?.statusCode == 422) {
        _errorMessage = t.error_email_invalid_format;
      } else if (e.response?.statusCode == 429) {
        _errorMessage = t.error_too_many_attempts;
      } else {
        _errorMessage = t.error_network;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = t.error_something_wrong;
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // ============================================================
  // Step 2: Register Verify - verify code + create user
  // POST /auth/register/verify
  // ============================================================
  Future<bool> registerVerify({
    required String code,
    required String password,
    String? referralCode,
    required BuildContext context,
  }) async {
    final t = AppLocalizations.of(context)!;
    if (_email == null) {
      _errorMessage = t.error_email_not_found;
      _safeNotify();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.registerVerify(
        email: _email!,
        code: code,
        password: password,
        referralCode: referralCode,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        await _storageService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: data['user_id'],
        );
        _isAuthenticated = true;
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? t.error_verification_failed;
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _errorMessage = t.error_invalid_code;
      } else if (e.response?.statusCode == 409) {
        _errorMessage = t.error_email_exists;
      } else {
        _errorMessage = t.error_network;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = t.error_something_wrong;
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // ============================================================
  // Step 3: Register Complete - complete profile
  // POST /auth/register/complete
  // ============================================================
  Future<bool> registerComplete(
    Map<String, dynamic> data,
    BuildContext context,
  ) async {
    final t = AppLocalizations.of(context)!;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.registerComplete(data);
      if (response.statusCode == 200) {
        final responseData = response.data;
        final userData = responseData['user'];

        await _storageService.saveTokens(
          accessToken: responseData['access_token'],
          refreshToken: responseData['refresh_token'],
          userId: userData['id'],
        );

        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? t.error_profile_complete_failed;
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 400) {
        _errorMessage = t.error_profile_already_complete;
      } else if (e.response?.statusCode == 401) {
        _errorMessage = t.error_session_expired;
      } else if (e.response?.statusCode == 422) {
        _errorMessage = t.error_invalid_data;
      } else {
        _errorMessage = t.error_network;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = t.error_something_wrong;
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // ============================================================
  // Login
  // POST /auth/login
  // ============================================================
  Future<bool> login({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    final t = AppLocalizations.of(context)!;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.login(
        email: email,
        password: password,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'];

        await _storageService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: userData['id'],
        );

        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? t.error_login_failed;
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = t.error_wrong_credentials;
      } else {
        _errorMessage = t.error_network;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = t.error_something_wrong;
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  // ============================================================
  // Logout
  // ============================================================
  Future<void> logout() async {
    await PushService().logout();
    final refreshToken = await _storageService.getRefreshToken();
    if (refreshToken != null) {
      try {
        await AuthService.logout(refreshToken);
      } catch (e) {
        // ignore logout errors
      }
    }
    await _storageService.clearTokens();
    _user = null;
    _email = null;
    _isAuthenticated = false;
    _safeNotify();
  }

  // ============================================================
  // Refresh user data
  // ============================================================
  Future<void> refreshUser() async {
    try {
      final response = await AuthService.getCurrentUser();
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        _safeNotify();
      }
    } catch (e) {
      // ignore
    }
  }

  // ============================================================
  // Update user profile
  // PUT /users/me
  // ============================================================
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.updateProfile(data);
      
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? 'Failed to update profile';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Session expired. Please login again.';
      } else if (e.response?.statusCode == 422) {
        _errorMessage = 'Invalid data. Please check your inputs.';
      } else {
        _errorMessage = 'Failed to update profile. Please try again.';
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  void resetServerError() {
    _serverError = null;
    _isServerHealthy = true;
    _safeNotify();
  }

  void clearError() {
    _errorMessage = null;
    _safeNotify();
  }

  Future<bool> googleLogin({
    required String idToken,
    String? name,
    String? email,
    String? picture,
    required BuildContext context,
  }) async {
    final t = AppLocalizations.of(context)!;
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.googleLogin(
        idToken: idToken,
        name: name,
        email: email,
        picture: picture,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final userData = data['user'];

        await _storageService.saveTokens(
          accessToken: data['access_token'],
          refreshToken: data['refresh_token'],
          userId: userData['id'],
        );

        _user = User.fromJson(userData);
        _isAuthenticated = true;
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? t.error_login_failed;
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = t.error_wrong_credentials;
      } else {
        _errorMessage = t.error_network;
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = t.error_something_wrong;
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

   /// Update user interests
  Future<bool> updateInterests(List<String> interests) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.updateInterests(interests);
      
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? 'Failed to update interests';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Session expired. Please login again.';
      } else if (e.response?.statusCode == 400) {
        _errorMessage = e.response?.data['detail'] ?? 'Invalid interests';
      } else {
        _errorMessage = 'Failed to update interests. Please try again.';
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }
  
  /// Update user prompts
  Future<bool> updatePrompts(List<Map<String, dynamic>> prompts) async {
    _isLoading = true;
    _errorMessage = null;
    _safeNotify();

    try {
      final response = await AuthService.updatePrompts(prompts);
      
      if (response.statusCode == 200) {
        _user = User.fromJson(response.data);
        _isLoading = false;
        _safeNotify();
        return true;
      } else {
        _errorMessage = response.data['detail'] ?? 'Failed to update prompts';
        _isLoading = false;
        _safeNotify();
        return false;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        _errorMessage = 'Session expired. Please login again.';
      } else if (e.response?.statusCode == 400) {
        _errorMessage = e.response?.data['detail'] ?? 'Invalid prompts';
      } else {
        _errorMessage = 'Failed to update prompts. Please try again.';
      }
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _errorMessage = 'An error occurred. Please try again.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

}