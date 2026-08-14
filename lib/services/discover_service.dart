import 'package:dio/dio.dart';
import 'package:dating_app/services/api_service.dart';

class DiscoverService {
  static Future<Response> getDiscoverProfiles({
    String? gender,
    int ageMin = 18,
    int? ageMax,
    int? distanceKm,
    int limit = 20,
    int offset = 0,
    String? cursor,
  }) async {
    try {
      final params = <String, dynamic>{
        'age_min': ageMin,
        'limit': limit,
        'offset': offset,
      };
      if (cursor != null && cursor.isNotEmpty) {
        params['cursor'] = cursor;
      }
      if (ageMax != null) {
        params['age_max'] = ageMax;
      }
      if (distanceKm != null) {
        params['distance_km'] = distanceKm;
      }
      if (gender != null && gender != 'all') {
        params['gender'] = gender;
      }
      return await ApiService.get(
        '/discover',
        queryParams: params,
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> swipeUser(String userId, String direction) async {
    try {
      return await ApiService.post('/swipes', data: {
        'user_id': userId,
        'direction': direction,
      });
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> sendFirstMessage(
      String userId, String content) async {
    try {
      return await ApiService.post('/messages/$userId/text', data: {
        'content': content,
      });
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getMyLimits() async {
    try {
      return await ApiService.get('/rewards/my-limits');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }
}
