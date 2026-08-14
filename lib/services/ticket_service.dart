import 'package:dio/dio.dart';
import 'package:dating_app/services/api_service.dart';

class TicketService {
  TicketService._();

  static Future<Response> createTicket(String subject, String message) async {
    try {
      return await ApiService.post(
        '/tickets',
        data: {'subject': subject, 'message': message},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getMyTickets({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      return await ApiService.get(
        '/tickets',
        queryParams: {'limit': limit, 'offset': offset},
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> getTicket(String id) async {
    try {
      return await ApiService.get(
        '/tickets/$id',
        cacheOptions: ApiService.noCache,
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }

  static Future<Response> replyToTicket(String id, String content) async {
    try {
      return await ApiService.post(
        '/tickets/$id/messages',
        data: {'content': content},
      );
    } on DioException catch (e) {
      if (e.response != null) return e.response!;
      rethrow;
    }
  }
}