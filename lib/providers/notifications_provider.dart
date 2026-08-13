import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/services/chat_service.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/services/push_service.dart';

class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  static const _pageSize = 20;

  // Unread counts
  int _unreadTotal = 0;
  Map<String, int> _unreadByType = {
    'like': 0,
    'liked': 0,
    'match': 0,
    'system': 0,
  };

  StreamSubscription? _socketSubscription;
  bool _socketAttached = false;

  List<AppNotification> get notifications => _notifications;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadTotal;

  int unreadFor(String type) => _unreadByType[type] ?? 0;

  Map<String, int> get unreadByType => Map.unmodifiable(_unreadByType);

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final response = await ChatService.getNotifications(
        limit: _pageSize,
        offset: 0,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['notifications'] ?? data['items'] ?? data ?? []) as List;
        _notifications =
            items.map((j) => AppNotification.fromJson(j)).toList();
        _offset = _notifications.length;
        _hasMore = data['next_offset'] != null;
        _recomputeUnreadCounts();
      } else {
        _errorMessage = 'Failed to load notifications';
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadMoreNotifications() async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();

    try {
      final response = await ChatService.getNotifications(
        limit: _pageSize,
        offset: _offset,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['notifications'] ?? data['items'] ?? data ?? []) as List;
        final newItems =
            items.map((j) => AppNotification.fromJson(j)).toList();
        _notifications.addAll(newItems);
        _offset += newItems.length;
        _hasMore = data['next_offset'] != null;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> markRead(List<String> ids) async {
    if (ids.isEmpty) return;
    try {
      await ChatService.markNotificationsRead(ids);
      for (var i = 0; i < _notifications.length; i++) {
        if (ids.contains(_notifications[i].id) &&
            !_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _recomputeUnreadCounts();
      notifyListeners();
    } catch (e) {
      // silent
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await ChatService.deleteNotification(id);
      if (response.statusCode == 200 || response.statusCode == 204) {
        _notifications.removeWhere((n) => n.id == id);
        _recomputeUnreadCounts();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void _recomputeUnreadCounts() {
    final counts = <String, int>{'like': 0, 'liked': 0, 'match': 0, 'system': 0};
    for (final n in _notifications) {
      if (!n.isRead) {
        counts[n.type] = (counts[n.type] ?? 0) + 1;
      }
    }
    _unreadByType = counts;
    _unreadTotal = counts.values.fold(0, (a, b) => a + b);
  }

  Future<void> refreshUnreadCounts() async {
    try {
      final response = await ChatService.getNotificationCounts();
      if (response.statusCode == 200) {
        final data = response.data;
        _unreadTotal = data['total'] ?? 0;
        final byType = data['by_type'] as Map<String, dynamic>? ?? {};
        _unreadByType = {
          'like': byType['like'] ?? 0,
          'liked': byType['liked'] ?? 0,
          'match': byType['match'] ?? 0,
          'system': byType['system'] ?? 0,
        };
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to refresh unread counts: $e');
    }
  }

  void attachSocket(ChatProvider chatProvider) {
    if (_socketAttached) return;
    _socketAttached = true;

    _socketSubscription = chatProvider.socketEvents.listen((event) {
      final type = event['type'] as String?;
      final data = event['data'] as Map<String, dynamic>? ?? {};

      if (type == 'new_notification') {
        _handleNewNotification(data);
      }
    });
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    final notificationId = data['id'] as String?;
    final notifType = data['type'] as String?;
    final title = data['title'] as String?;
    final body = data['body'] as String?;
    final isRead = data['is_read'] as bool? ?? false;
    final createdAtStr = data['created_at'] as String?;
    final userId = data['user_id'] as String?;
    final matchId = data['match_id'] as String?;
    final chatId = data['chat_id'] as String?;

    if (notificationId == null || notifType == null) return;

    // Check if already exists
    final exists = _notifications.any((n) => n.id == notificationId);
    if (!exists) {
      final notification = AppNotification(
        id: notificationId,
        type: notifType,
        title: title ?? '',
        body: body,
        isRead: isRead,
        createdAt: createdAtStr != null
            ? DateTime.tryParse(createdAtStr) ?? DateTime.now()
            : DateTime.now(),
        data: {
          if (userId != null) 'user_id': userId,
          if (matchId != null) 'match_id': matchId,
          if (chatId != null) 'chat_id': chatId,
        },
      );
      _notifications.insert(0, notification);
      _offset++;
      _recomputeUnreadCounts();
      notifyListeners();

      // Also trigger toast via NotificationToastService
      // The PushService already handles toast for foreground FCM messages.
      // WS events need to trigger toast here.
      NotificationToastService.show(
        id: notificationId,
        type: notifType,
        title: title ?? '',
        body: body ?? '',
        data: {'user_id': userId, 'match_id': matchId, 'chat_id': chatId},
      );
    } else {
      // Update existing if needed
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead && isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _recomputeUnreadCounts();
        notifyListeners();
      }
    }
  }

  void detachSocket() {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _socketAttached = false;
  }

  @override
  void dispose() {
    detachSocket();
    super.dispose();
  }
}