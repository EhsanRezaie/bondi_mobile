// lib/services/auth_service.dart
import 'package:dio/dio.dart';
import 'package:dating_app/services/api_service.dart';

class AuthService {
  // ============================================================
  // Health Check
  // ============================================================
  static Future<Response> healthCheck() async {
    try {
      return await ApiService.healthCheck();
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Request verification code (login or signup)
  // POST /auth/request-code
  // ============================================================
  static Future<Response> requestCode(String phone) async {
    try {
      return await ApiService.post('/auth/request-code', data: {
        'phone': phone,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Verify code + login/create user
  // POST /auth/verify-code
  // ============================================================
  static Future<Response> verifyCode({
    required String phone,
    required String code,
    String? referralCode,
  }) async {
    try {
      final data = {
        'phone': phone,
        'code': code,
      };
      if (referralCode != null && referralCode.isNotEmpty) {
        data['referral_code'] = referralCode;
      }
      return await ApiService.post('/auth/verify-code', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Complete onboarding profile
  // POST /auth/register/complete
  // ============================================================
  static Future<Response> registerComplete(Map<String, dynamic> data) async {
    try {
      return await ApiService.post('/auth/register/complete', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Claim a referral code (new users only)
  // POST /referrals/claim
  // ============================================================
  static Future<Response> claimReferral(String referralCode) async {
    try {
      return await ApiService.post('/referrals/claim', data: {
        'referral_code': referralCode,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Refresh Token
  // POST /auth/refresh
  // ============================================================
  static Future<Response> refreshToken(String refreshToken) async {
    try {
      return await ApiService.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Logout
  // POST /auth/logout
  // ============================================================
  static Future<Response> logout(String refreshToken) async {
    try {
      return await ApiService.post('/auth/logout', data: {
        'refresh_token': refreshToken,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Get Current User
  // GET /users/me
  // ============================================================
  static Future<Response> getCurrentUser() async {
    try {
      return await ApiService.get('/users/me');
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Update Current User Profile
  // PUT /users/me
  // All fields are optional - only provided fields will be updated
  // ============================================================
  static Future<Response> updateProfile(Map<String, dynamic> data) async {
    try {
      return await ApiService.put('/users/me', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  // ============================================================
  // Delete Account (soft delete)
  // DELETE /users/me
  // ============================================================
  static Future<Response> deleteAccount() async {
    try {
      return await ApiService.delete('/users/me');
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  static Future<Response> updateInterests(List<String> interests) async {
    try {
      return await ApiService.put('/users/me/interests', data: {
        'interests': interests,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  /// Update user settings
  /// PUT /users/me/settings
  static Future<Response> updateSettings(Map<String, dynamic> data) async {
    try {
      return await ApiService.put('/users/me/settings', data: data);
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }

  /// Update user prompts
  /// PUT /users/me/prompts
  static Future<Response> updatePrompts(List<Map<String, dynamic>> prompts) async {
    try {
      return await ApiService.put('/users/me/prompts', data: {
        'prompts': prompts,
      });
    } on DioException catch (e) {
      if (e.response != null) {
        return e.response!;
      }
      rethrow;
    }
  }
}