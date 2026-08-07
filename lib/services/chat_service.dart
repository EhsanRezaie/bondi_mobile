import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dating_app/services/api_service.dart';

class ChatService {
  ChatService._();

  static Future<Response> getMatches({int limit = 20, int offset = 0}) async {
    try {
      return await ApiService.get(
        '/matches',
        queryParams: {'limit': limit, 'offset': offset},
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getMatchDetail(String matchId) async {
    try {
      return await ApiService.get('/matches/$matchId');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getChats({
    int limit = 20,
    int offset = 0,
    String? status,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit, 'offset': offset};
      if (status != null) params['status'] = status;
      return await ApiService.get(
        '/chats',
        queryParams: params,
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getChatDetail(String chatId) async {
    try {
      return await ApiService.get(
        '/chats/$chatId',
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> createChat(
    String userId,
    String content,
  ) async {
    try {
      return await ApiService.post(
        '/chats',
        data: {'user_id': userId, 'content': content},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getLikers({int limit = 20, int offset = 0}) async {
    try {
      return await ApiService.get(
        '/swipes/likers',
        queryParams: {'limit': limit, 'offset': offset},
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getLikedUsers({int limit = 20, int offset = 0}) async {
    try {
      return await ApiService.get(
        '/swipes/liked',
        queryParams: {'limit': limit, 'offset': offset},
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getSwipeStats() async {
    try {
      return await ApiService.get('/swipes/stats', cacheOptions: ApiService.noCache);
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getChatHistory(
    String identifier, {
    int limit = 30,
    String? before,
  }) async {
    try {
      final params = <String, dynamic>{'limit': limit};
      if (before != null) params['before'] = before;
      return await ApiService.get(
        '/messages/$identifier',
        queryParams: params,
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> sendText(
    String identifier,
    String content, {
    String? replyToId,
  }) async {
    try {
      final data = <String, dynamic>{'content': content};
      if (replyToId != null) data['reply_to_id'] = replyToId;
      return await ApiService.post('/messages/$identifier/text', data: data);
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> editMessage(String messageId, String content) async {
    try {
      return await ApiService.put(
        '/messages/$messageId',
        data: {'content': content},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> sendPhoto(
    String identifier,
    String imagePath, {
    String? caption,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imagePath,
          filename: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        ),
        'caption': caption,
      });
      return await ApiService.upload('/messages/$identifier/photo', formData);
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> sendVoice(
    String identifier,
    String filePath,
    int duration,
  ) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: 'voice_${DateTime.now().millisecondsSinceEpoch}.aac',
        ),
        'duration': duration,
      });
      return await ApiService.upload('/messages/$identifier/voice', formData);
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> acceptChat(String chatId) async {
    try {
      return await ApiService.post('/chats/$chatId/accept');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> deleteMessage(
    String messageId, {
    String deleteFor = 'me',
  }) async {
    try {
      return await ApiService.dio.delete(
        '/messages/$messageId',
        queryParameters: {'delete_for': deleteFor},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> forwardMessage(
    String messageId,
    String targetMatchId,
  ) async {
    try {
      return await ApiService.post(
        '/messages/$messageId/forward',
        data: {'target_match_id': targetMatchId},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getMessageStatus(String messageId) async {
    try {
      return await ApiService.get('/messages/$messageId/status');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  /// Deletes a chat for the current user (hides your side; peers see ended).
  static Future<Response> deleteChat(String chatId) async {
    try {
      return await ApiService.dio.delete('/chats/$chatId');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> blockUser(String userId) async {
    try {
      return await ApiService.post('/blocks/$userId/block');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> unblockUser(String userId) async {
    try {
      return await ApiService.post('/blocks/$userId/unblock');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getBlocks() async {
    try {
      return await ApiService.get('/blocks');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> reportUser(String userId, String reason) async {
    try {
      return await ApiService.post('/reports/$userId', data: {'reason': reason});
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> reportMessage(
    String messageId,
    String reason, {
    String? description,
  }) async {
    try {
      return await ApiService.post(
        '/reports/message/$messageId',
        data: {'reason': reason, 'description': description},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  // ── Read ─────────────────────────────────────────────────────────
  static Future<Response> markDelivered(List<String> messageIds) async {
    try {
      return await ApiService.post(
        '/messages/delivered',
        data: {'message_ids': messageIds},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> markRead(List<String> messageIds) async {
    try {
      return await ApiService.post(
        '/messages/read',
        data: {'message_ids': messageIds},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getDailyLimits() async {
    try {
      return await ApiService.get('/rewards/my-limits');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getUserProfile() async {
    try {
      return await ApiService.get('/users/me');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getPublicProfile(String userId) async {
    try {
      return await ApiService.get(
        '/users/$userId',
        cacheOptions: ApiService.makeCacheOptions(
          policy: CachePolicy.request,
          maxStale: const Duration(minutes: 5),
        ),
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getNotifications({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await ApiService.get(
        '/notifications',
        queryParams: {'limit': limit, 'offset': offset},
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> markNotificationsRead(List<String> ids) async {
    try {
      return await ApiService.post(
        '/notifications/read',
        data: {'notification_ids': ids},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> deleteNotification(String id) async {
    try {
      return await ApiService.dio.delete('/notifications/$id');
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }
}
