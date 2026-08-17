import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/services/chat_service.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/widgets/notification_toast.dart';

class NotificationsProvider extends ChangeNotifier {
  bool _disposed = false;

  void _safeNotify() {
    if (_disposed) return;
    notifyListeners();
  }

  /// Flat cache of all loaded notifications, used for the match strip,
  /// unread counts and read/delete bookkeeping.
  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  static const _pageSize = 50;

  /// Notification types that this screen displays (tabs + match strip).
  static const _types = ['like', 'liked', 'match', 'system'];

  /// Per-type pagination state. Each tab pages its own type from the API so a
  /// tab never shows a "more" spinner for items that belong to another type.
  final Map<String, int> _offsetByType = {for (final t in _types) t: 0};
  final Map<String, bool> _hasMoreByType = {for (final t in _types) t: true};
  final Map<String, bool> _isLoadingMoreByType = {
    for (final t in _types) t: false,
  };

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
  bool get hasMore => _hasMoreByType.values.any((v) => v);
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get unreadCount => _unreadTotal;

  bool hasMoreFor(String type) => _hasMoreByType[type] ?? false;

  bool isLoadingMoreFor(String type) => _isLoadingMoreByType[type] ?? false;

  int unreadFor(String type) => _unreadByType[type] ?? 0;

  Map<String, int> get unreadByType => Map.unmodifiable(_unreadByType);

  Future<void> loadNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    _notifications = [];
    for (final t in _types) {
      _offsetByType[t] = 0;
      _hasMoreByType[t] = true;
      _isLoadingMoreByType[t] = false;
    }
    _safeNotify();

    try {
      final responses = await Future.wait([
        for (final t in _types)
          ChatService.getNotifications(type: t, limit: _pageSize, offset: 0),
      ]);
      var anyOk = false;
      for (var i = 0; i < _types.length; i++) {
        final response = responses[i];
        if (response.statusCode == 200) {
          anyOk = true;
          final data = response.data;
          final items =
              (data['notifications'] ?? data['items'] ?? data ?? []) as List;
          _notifications.addAll(
            items.map((j) => AppNotification.fromJson(j)),
          );
          _offsetByType[_types[i]] = items.length;
          _hasMoreByType[_types[i]] = data['next_offset'] != null;
        }
      }
      if (!anyOk) {
        _errorMessage = 'Failed to load notifications';
      }
      _recomputeUnreadCounts();
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isLoading = false;
    _safeNotify();
  }

  Future<void> loadMoreNotifications(String type) async {
    if (!_types.contains(type)) return;
    if (_isLoadingMoreByType[type] == true) return;
    if (!_hasMoreByType[type]!) return;
    _isLoadingMoreByType[type] = true;
    _isLoadingMore = true;
    _safeNotify();

    try {
      final response = await ChatService.getNotifications(
        type: type,
        limit: _pageSize,
        offset: _offsetByType[type] ?? 0,
      );
      if (response.statusCode == 200) {
        final data = response.data;
        final items =
            (data['notifications'] ?? data['items'] ?? data ?? []) as List;
        final newItems =
            items.map((j) => AppNotification.fromJson(j)).toList();
        _notifications.addAll(newItems);
        _offsetByType[type] = (_offsetByType[type] ?? 0) + newItems.length;
        _hasMoreByType[type] = data['next_offset'] != null;
      }
    } catch (e) {
      // silent
    }

    _isLoadingMoreByType[type] = false;
    _isLoadingMore = _isLoadingMoreByType.values.any((v) => v);
    _safeNotify();
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
      _safeNotify();
      refreshUnreadCounts();
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
        _safeNotify();
        refreshUnreadCounts();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _safeNotify();
      return false;
    }
  }

  void _recomputeUnreadCounts() {
    const displayTypes = {'like', 'liked', 'match', 'system'};
    final counts = <String, int>{'like': 0, 'liked': 0, 'match': 0, 'system': 0};
    for (final n in _notifications) {
      if (!n.isRead && displayTypes.contains(n.type)) {
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
        final byType = data['by_type'] as Map<String, dynamic>? ?? {};
        _unreadByType = {
          'like': byType['like'] ?? 0,
          'liked': byType['liked'] ?? 0,
          'match': byType['match'] ?? 0,
          'system': byType['system'] ?? 0,
        };
        // Only count the 4 types shown in this screen — message notifications
        // are not displayed here and must not inflate the badge.
        _unreadTotal = _unreadByType.values.fold(0, (a, b) => a + b);
        _safeNotify();
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
    final name = data['name'] as String?;
    final avatarUrl = data['avatar_url'] as String?;

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
          'user_id': ?userId,
          'match_id': ?matchId,
          'chat_id': ?chatId,
          'name': ?name,
          'avatar_url': ?avatarUrl,
        },
      );
      _notifications.insert(0, notification);
      if (_types.contains(notifType)) {
        _offsetByType[notifType] = (_offsetByType[notifType] ?? 0) + 1;
      }
      _recomputeUnreadCounts();
      _safeNotify();
      refreshUnreadCounts();

      // Also trigger toast via NotificationToastService
      // The PushService already handles toast for foreground FCM messages.
      // WS events need to trigger toast here.
      NotificationToastService.show(
        id: notificationId,
        type: notifType,
        title: title ?? '',
        body: body ?? '',
        data: {
          'user_id': userId,
          'match_id': matchId,
          'chat_id': chatId,
          'name': name,
          'avatar_url': avatarUrl,
        },
      );
    } else {
      // Update existing if needed
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead && isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _recomputeUnreadCounts();
        _safeNotify();
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
    _disposed = true;
    detachSocket();
    super.dispose();
  }
}
