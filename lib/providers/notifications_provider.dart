import 'package:flutter/foundation.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/services/chat_service.dart';

class NotificationsProvider extends ChangeNotifier {
  List<AppNotification> _notifications = [];
  int _offset = 0;
  bool _hasMore = true;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  static const _pageSize = 20;

  List<AppNotification> get notifications => _notifications;
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get unreadCount =>
      _notifications.where((n) => !n.isRead).length;

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
}