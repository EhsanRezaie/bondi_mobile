import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  // Load from .env file
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api/v1';
  static String get wsBaseUrl => dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8000/api/v1';
  static String get googleClientId => dotenv.env['GOOGLE_CLIENT_ID'] ?? '';
  static String get adminSecretKey => dotenv.env['ADMIN_SECRET_KEY'] ?? '';
  
  static const int connectTimeout = 30;
  static const int receiveTimeout = 90;
  
  // Storage keys
  static const String accessTokenKey = "access_token";
  static const String refreshTokenKey = "refresh_token";
  static const String userKey = "user";
  
  // Pagination
  static const int defaultPageSize = 20;
}