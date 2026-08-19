import 'package:dio/dio.dart';
import 'package:dating_app/services/api_service.dart';

class SearchService {
  static Future<Response> search({
    String? gender,
    int ageMin = 18,
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
    String? hereFor,
    String? pets,
    String? workoutFrequency,
    String? zodiacSign,
    String? country,
    String? province,
    String? city,
    String? religion,
    String? ethnicity,
    List<String>? languages,
    List<String>? interests,
    bool? hasPhotos,
    bool? isVerified,
    String sortBy = 'recent',
    String sortOrder = 'desc',
    int limit = 9,
    int offset = 0,
    String? cursor,
  }) async {
    try {
      final params = <String, dynamic>{
        'age_min': ageMin,
        'limit': limit,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      if (cursor != null && cursor.isNotEmpty) {
        params['cursor'] = cursor;
      } else {
        params['offset'] = offset;
      }
      if (gender != null && gender != 'all') params['gender'] = gender;
      if (ageMax != null) params['age_max'] = ageMax;
      if (distanceKm != null) params['distance_km'] = distanceKm;
      if (heightMin != null) params['height_min'] = heightMin;
      if (heightMax != null) params['height_max'] = heightMax;
      if (weightMin != null) params['weight_min'] = weightMin;
      if (weightMax != null) params['weight_max'] = weightMax;
      if (bodyType != null) params['body_type'] = bodyType;
      if (relationshipStatus != null) params['relationship_status'] = relationshipStatus;
      if (education != null) params['education'] = education;
      if (smoking != null) params['smoking'] = smoking;
      if (drinking != null) params['drinking'] = drinking;
      if (politicalOrientation != null) params['political_orientation'] = politicalOrientation;
      if (childrenStatus != null) params['children_status'] = childrenStatus;
      if (livingSituation != null) params['living_situation'] = livingSituation;
      if (hereFor != null) params['here_for'] = hereFor;
      if (pets != null) params['pets'] = pets;
      if (workoutFrequency != null) params['workout_frequency'] = workoutFrequency;
      if (zodiacSign != null) params['zodiac_sign'] = zodiacSign;
      if (country != null) params['country'] = country;
      if (province != null) params['province'] = province;
      if (city != null) params['city'] = city;
      if (religion != null) params['religion'] = religion;
      if (ethnicity != null) params['ethnicity'] = ethnicity;
      if (languages != null && languages.isNotEmpty) {
        params['languages'] = languages.join(',');
      }
      if (interests != null && interests.isNotEmpty) {
        params['interests'] = interests.join(',');
      }
      if (hasPhotos == true) params['has_photos'] = true;
      if (isVerified == true) params['is_verified'] = true;

      return await ApiService.get(
        '/search',
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

  static Future<Response> sendFirstMessage(String userId, String content) async {
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
