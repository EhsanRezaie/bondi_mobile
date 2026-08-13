import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'chat_service.dart';
import 'storage_service.dart';

class PushService {
  static final PushService _instance = PushService._internal();
  factory PushService() => _instance;
  PushService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  StreamSubscription<RemoteMessage>? _foregroundSubscription;
  StreamSubscription<RemoteMessage>? _backgroundSubscription;
  String? _currentToken;

  bool _initialized = false;
  bool _permissionGranted = false;

  static const _tokenKey = 'fcm_token';
  static const _tokenSentKey = 'fcm_token_sent';

  Future<void> initPush({
    required Function(String, Map<String, dynamic>) onNotificationTap,
    required VoidCallback onTokenRefreshed,
  }) async {
    if (_initialized) return;

    await _initFirebase();
    await _requestPermission();
    await _registerToken();
    _setupMessageHandlers(onNotificationTap);
    _initialized = true;
    onTokenRefreshed();
  }

  Future<void> _initFirebase() async {
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialize error: $e');
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      _permissionGranted = settings.authorizationStatus == AuthorizationStatus.authorized;
      debugPrint('FCM permission: ${settings.authorizationStatus}');
    } catch (e) {
      debugPrint('FCM permission error: $e');
      _permissionGranted = false;
    }
  }

  Future<void> _registerToken() async {
    try {
      _currentToken = await _messaging.getToken();
      if (_currentToken != null) {
        debugPrint('FCM token: $_currentToken');
        await _sendTokenToBackend(_currentToken!);
      }
    } catch (e) {
      debugPrint('FCM getToken error: $e');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _currentToken = newToken;
      debugPrint('FCM token refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
  }

  Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final alreadySent = prefs.getBool(_tokenSentKey) ?? false;
    final storedToken = prefs.getString(_tokenKey);

    if (alreadySent && storedToken == token) return;

    try {
      final storage = StorageService();
      final accessToken = await storage.getAccessToken();
      if (accessToken == null) {
        debugPrint('No access token, skipping FCM registration');
        return;
      }

      await ChatService.registerDeviceToken(token: token, platform: 'android');
      await prefs.setString(_tokenKey, token);
      await prefs.setBool(_tokenSentKey, true);
      debugPrint('FCM token registered with backend');
    } catch (e) {
      debugPrint('FCM token registration failed: $e');
      await prefs.setBool(_tokenSentKey, false);
    }
  }

  void _setupMessageHandlers(Function(String, Map<String, dynamic>) onNotificationTap) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM opened app from background: ${message.messageId}');
      _navigateFromMessage(message, onNotificationTap);
    });

    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint('FCM opened app from terminated: ${message.messageId}');
        _navigateFromMessage(message, onNotificationTap);
      }
    });
  }

  void _handleForegroundMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;

    if (data.isEmpty && notification == null) return;

    final notificationId = data['notification_id'] ?? message.messageId ?? '';
    final type = data['type'] ?? 'system';
    final title = notification?.title ?? data['title'] ?? '';
    final body = notification?.body ?? data['body'] ?? '';

    debugPrint('Foreground notification: type=$type, id=$notificationId, title=$title');

    NotificationToastService.show(
      id: notificationId,
      type: type,
      title: title,
      body: body,
      data: data,
    );
  }

  void _navigateFromMessage(
    RemoteMessage message,
    Function(String, Map<String, dynamic>) onNotificationTap,
  ) {
    final data = message.data;
    final type = data['type'] ?? 'system';

    switch (type) {
      case 'like':
      case 'liked':
      case 'match':
        final userId = data['user_id'];
        if (userId != null) {
          onNotificationTap('user_profile', {'user_id': userId});
        }
        break;
      case 'message':
        final chatId = data['chat_id'];
        if (chatId != null) {
          onNotificationTap('chat', {'chat_id': chatId});
        }
        break;
      case 'system':
        onNotificationTap('announcement', data);
        break;
    }
  }

  Future<void> deleteToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        await ChatService.deleteDeviceToken(token);
      }
      await prefs.remove(_tokenKey);
      await prefs.remove(_tokenSentKey);
      await _messaging.deleteToken();
      _currentToken = null;
      debugPrint('FCM token deleted');
    } catch (e) {
      debugPrint('FCM delete token error: $e');
    }
  }

  Future<void> logout() async {
    await deleteToken();
    _initialized = false;
    _permissionGranted = false;
    _foregroundSubscription?.cancel();
    _backgroundSubscription?.cancel();
  }
}

class NotificationToastService {
  static final Map<String, DateTime> _shownToasts = {};
  static const _dedupeWindow = Duration(seconds: 5);

  static void show({
    required String id,
    required String type,
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) {
    final now = DateTime.now();
    if (_shownToasts.containsKey(id)) {
      final lastShown = _shownToasts[id]!;
      if (now.difference(lastShown) < _dedupeWindow) {
        debugPrint('Deduped toast: $id');
        return;
      }
    }
    _shownToasts[id] = now;

    _cleanupOldToasts();

    // TODO: Show actual overlay toast widget (P6)
    debugPrint('TOAST [$type]: $title - $body (data: $data)');
  }

  static void _cleanupOldToasts() {
    final now = DateTime.now();
    _shownToasts.removeWhere((_, time) => now.difference(time) > _dedupeWindow);
  }
}