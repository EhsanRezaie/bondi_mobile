import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:dating_app/services/api_service.dart';

/// Overrides [ApiService]'s transport with a mocked [Dio] + [DioAdapter].
///
/// Usage (in a widget/provider test):
/// ```dart
/// final api = MockApi()
///   ..onGet('/api/v1/conversations', body: [...])
///   ..install();
/// ```
class MockApi {
  final Dio dio;
  late final DioAdapter adapter;

  MockApi({String? baseUrl})
      : dio = Dio(BaseOptions(baseUrl: baseUrl ?? 'http://localhost:8000/api/v1')) {
    adapter = DioAdapter(dio: dio);
    dio.httpClientAdapter = adapter;
  }

  /// Point [ApiService] at this mocked transport.
  void install() => ApiService.setTransport(dio);

  /// Register a GET returning `body` as a JSON list/map.
  void onGet(
    String path, {
    required Object body,
    int statusCode = 200,
  }) {
    adapter.onGet(
      path,
      (server) => server.reply(statusCode, body, delay: Duration.zero),
    );
  }

  void onPost(
    String path, {
    required Object body,
    int statusCode = 200,
    Object? data,
  }) {
    adapter.onPost(
      path,
      (server) => server.reply(statusCode, body, delay: Duration.zero),
      data: data,
    );
  }

  void onPatch(
    String path, {
    required Object body,
    int statusCode = 200,
    Object? data,
  }) {
    adapter.onPatch(
      path,
      (server) => server.reply(statusCode, body, delay: Duration.zero),
      data: data,
    );
  }

  void onDelete(String path, {int statusCode = 204}) {
    adapter.onDelete(
      path,
      (server) => server.reply(statusCode, null, delay: Duration.zero),
    );
  }

  /// Assert the adapter was asked for `path`. Paths are matched as substrings
  /// (http_mock_adapter strips query strings into queryParameters).
  void expectCalled(String path, {int times = 1}) {
    final matching = adapter.history.where((req) => req.request.route == path);
    if (matching.length != times) {
      throw StateError(
        'Expected $times request(s) to $path but saw ${matching.length}. '
        'History: ${adapter.history.map((r) => r.request.route).toList()}',
      );
    }
  }

  /// Decode a raw JSON-encoded request body string.
  Map<String, dynamic> decodeBody(String raw) => jsonDecode(raw);
}