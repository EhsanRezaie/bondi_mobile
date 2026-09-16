// lib/services/local_notifications.dart
import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../screens/chats/chat_detail_screen.dart';
import '../screens/chats/user_notification_profile_screen.dart';
import '../utils/global_navigator.dart';

/// Renders Android notifications from data-only FCM messages (background and
/// terminated), and routes notification taps. iOS relies on the APNs alert the
/// backend sends, so local rendering is Android-only.
class LocalNotifications {
  LocalNotifications._();
  static final LocalNotifications instance = LocalNotifications._();

  static const String channelId = 'bondi_messages';
  static const String _channelName = 'Messages';
  static const String _channelDesc = 'Chat, likes and match notifications';
  static const String _defaultChannelId = 'bondi_default';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    const android = AndroidInitializationSettings('@drawable/ic_stat_bondi');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: _onResponse,
      );
      await _createChannels();
      _ready = true;
    } catch (e) {
      debugPrint('LocalNotifications init error: $e');
    }
  }

  Future<void> _createChannels() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;
    await android.createNotificationChannel(const AndroidNotificationChannel(
      channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    ));
    await android.createNotificationChannel(const AndroidNotificationChannel(
      _defaultChannelId,
      'Notifications',
      description: 'General notifications',
      importance: Importance.defaultImportance,
    ));
  }

  /// Routes the notification the app was launched from (terminated state).
  Future<void> handleLaunch() async {
    try {
      final details = await _plugin.getNotificationAppLaunchDetails();
      final response = details?.notificationResponse;
      if (details?.didNotificationLaunchApp == true && response?.payload != null) {
        _routePayload(response!.payload!);
      }
    } catch (e) {
      debugPrint('LocalNotifications handleLaunch error: $e');
    }
  }

  static void _onResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;
    instance._routePayload(payload);
  }

  void _routePayload(String payload) {
    try {
      final decoded = jsonDecode(payload);
      if (decoded is Map) {
        navigateFromData(Map<String, dynamic>.from(decoded));
      }
    } catch (e) {
      debugPrint('LocalNotifications route error: $e');
    }
  }

  /// Navigates based on the notification's `data` payload (same shape the
  /// backend sends: type, user_id / chat_id / title).
  void navigateFromData(Map<String, dynamic> data) {
    final nav = appNavigatorKey.currentState;
    final ctx = appNavigatorKey.currentContext;
    if (nav == null || ctx == null) return;

    final type = (data['type'] ?? '').toString();
    switch (type) {
      case 'like':
      case 'liked':
      case 'match':
        final userId = data['user_id']?.toString();
        if (userId != null && userId.isNotEmpty) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => UserNotificationProfileScreen(
                userId: userId,
                fallback: SwipeStubProfile(
                  id: userId,
                  name: (data['title'] ?? '').toString(),
                  age: 0,
                ),
              ),
            ),
          );
        }
        break;
      case 'message':
        final chatId = data['chat_id']?.toString();
        if (chatId != null && chatId.isNotEmpty) {
          nav.push(
            MaterialPageRoute(
              builder: (_) => ChatDetailScreen(
                identifier: chatId,
                userName:
                    (data['sender_name'] ?? data['title'] ?? '').toString(),
              ),
            ),
          );
        }
        break;
      case 'system':
        showDialog(
          context: ctx,
          builder: (dialogContext) => AlertDialog(
            title: Text((data['title'] ?? '').toString()),
            content: Text((data['body'] ?? '').toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        break;
    }
  }

  /// Pure parse of an FCM `data` map into notification content. Exposed for
  /// tests (the rest of the flow needs platform plugins).
  @visibleForTesting
  static ({String title, String body, String? imageUrl, String id}) parseContent(
    Map<String, dynamic> data, {
    String? fallbackTitle,
    String? fallbackBody,
    String? fallbackId,
  }) {
    return (
      title: (data['title'] ?? fallbackTitle ?? '').toString(),
      body: (data['body'] ?? fallbackBody ?? '').toString(),
      imageUrl: data['image_url']?.toString(),
      id: (data['notification_id'] ?? fallbackId ?? '').toString(),
    );
  }

  /// Builds and shows a notification from an FCM message (Android only).
  Future<void> showFromMessage(RemoteMessage message) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    await init();
    final data = message.data;
    final content = parseContent(
      data,
      fallbackTitle: message.notification?.title,
      fallbackBody: message.notification?.body,
      fallbackId: message.messageId,
    );
    if (content.title.isEmpty && content.body.isEmpty) return;

    final imageUrl = content.imageUrl;
    final id = content.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.remainder(0x7fffffff)
        : (content.id.hashCode & 0x7fffffff);

    AndroidBitmap<Object>? largeIcon;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final path = await _downloadToTemp(imageUrl);
      if (path != null) largeIcon = FilePathAndroidBitmap(path);
    }

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_stat_bondi',
      largeIcon: largeIcon,
      category: AndroidNotificationCategory.message,
      autoCancel: true,
    );

    try {
      await _plugin.show(
        id: id,
        title: content.title,
        body: content.body,
        notificationDetails: NotificationDetails(android: androidDetails),
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('LocalNotifications show error: $e');
    }
  }

  Future<String?> _downloadToTemp(String url) async {
    try {
      final resp =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (resp.statusCode != 200 || resp.bodyBytes.isEmpty) return null;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/notif_${url.hashCode}.img');
      await file.writeAsBytes(resp.bodyBytes, flush: true);
      return file.path;
    } catch (_) {
      return null;
    }
  }
}

/// Top-level FCM background handler. Must be registered before `runApp` and is
/// invoked in a separate isolate when a data message arrives in the background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    await LocalNotifications.instance.showFromMessage(message);
  } catch (e) {
    debugPrint('FCM background handler error: $e');
  }
}
