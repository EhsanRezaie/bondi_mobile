import 'package:flutter_test/flutter_test.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import '../../helpers/test_helpers.dart';
import '../../helpers/mock_api.dart';
import '../../helpers/fixtures.dart';

void main() {
  late NotificationsProvider provider;
  late MockApi api;

  setUpAll(() async {
    await initTestEnvironment();
  });

  setUp(() {
    provider = NotificationsProvider();
    api = MockApi();
  });

  tearDown(() {
    provider.dispose();
  });

  Map<String, dynamic> notif({
    String id = 'n-1',
    String type = 'like',
    String title = 'New message',
    bool isRead = false,
  }) {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': 'body',
      'created_at': kNowIso,
      'is_read': isRead,
    };
  }

  Map<String, dynamic> countsBody() => {'total': 0, 'by_type': {}};

  void mockCounts() =>
      api.onGet('/notifications/counts', body: countsBody());

  /// Registers one `/notifications` handler. The provider now loads first
  /// pages for all four displayed types in parallel, so this single route
  /// answers every type with the same body.
  void mockFeed(Map<String, dynamic> body) =>
      api.onGet('/notifications', body: body);

  group('loadNotifications', () {
    test('populates notifications across types', () async {
      mockFeed({
        'notifications': [
          notif(id: 'n-1', type: 'like'),
          notif(id: 'n-2', type: 'liked'),
        ],
        'next_offset': null,
      });
      api.install();

      await provider.loadNotifications();

      // 4 types × 2 notifications each = 8 total
      expect(provider.notifications, hasLength(8));
      expect(provider.hasMore, isFalse);
      expect(provider.hasMoreFor('like'), isFalse);
      expect(provider.hasMoreFor('liked'), isFalse);
      expect(provider.hasMoreFor('match'), isFalse);
      expect(provider.hasMoreFor('system'), isFalse);
      expect(provider.isLoading, isFalse);
      expect(provider.isLoadingMore, isFalse);
      api.expectCalled('/notifications');
    });

    test('tracks hasMore per type', () async {
      mockFeed({
        'notifications': [notif(id: 'n-1', type: 'like')],
        'next_offset': '50',
      });
      api.install();

      await provider.loadNotifications();

      expect(provider.hasMore, isTrue);
      expect(provider.hasMoreFor('like'), isTrue);
      expect(provider.hasMoreFor('liked'), isTrue);
      expect(provider.hasMoreFor('match'), isTrue);
      expect(provider.hasMoreFor('system'), isTrue);
    });

    test('counts unread notifications', () async {
      mockFeed({
        'notifications': [
          notif(id: 'n-1', type: 'like'),
          notif(id: 'n-2', type: 'like', isRead: true),
          notif(id: 'n-3', type: 'liked'),
        ],
        'next_offset': null,
      });
      api.install();

      await provider.loadNotifications();

      // 4 types × 2 unread each (like:1 unread, liked:1 unread) = 8
      expect(provider.unreadCount, 8);
    });

    test('sets errorMessage when request fails', () async {
      api.onGet('/notifications', body: {'detail': 'boom'}, statusCode: 500);
      api.install();

      await provider.loadNotifications();

      expect(provider.notifications, isEmpty);
      expect(provider.errorMessage, isNotNull);
    });
  });

  group('loadMoreNotifications', () {
    test('appends the next page for a single type', () async {
      mockFeed({
        'notifications': [notif(id: 'n-1', type: 'like')],
        'next_offset': '50',
      });
      api.install();

      await provider.loadNotifications();
      expect(provider.notifications, hasLength(4));

      api.onGet('/notifications', body: {
        'notifications': [notif(id: 'n-2', type: 'like')],
        'next_offset': null,
      });
      await provider.loadMoreNotifications('like');

      expect(provider.notifications, hasLength(5));
      expect(provider.hasMoreFor('like'), isFalse);
      expect(provider.hasMoreFor('liked'), isTrue);
      expect(provider.isLoadingMore, isFalse);
    });

    test('does nothing when the type has no more pages', () async {
      mockFeed({
        'notifications': [notif(id: 'n-1', type: 'like')],
        'next_offset': null,
      });
      api.install();
      await provider.loadNotifications();

      final before = provider.notifications.length;
      await provider.loadMoreNotifications('like');
      expect(provider.notifications.length, before);
    });

    test('ignores unknown types', () async {
      api.install();
      await provider.loadMoreNotifications('nope');
      expect(provider.isLoadingMore, isFalse);
    });
  });

  group('markRead', () {
    test('marks matching notifications as read', () async {
      mockFeed({
        'notifications': [notif(id: 'n-1', type: 'like'), notif(id: 'n-2', type: 'liked')],
        'next_offset': null,
      });
      api.install();
      await provider.loadNotifications();

      api.onPost(
        '/notifications/read',
        body: {'ok': true},
        data: {'notification_ids': ['n-1']},
      );
      mockCounts();
      await provider.markRead(['n-1']);

      final firstLike =
          provider.notifications.firstWhere((n) => n.id == 'n-1');
      expect(firstLike.isRead, isTrue);
      final second =
          provider.notifications.firstWhere((n) => n.id == 'n-2');
      expect(second.isRead, isFalse);
      expect(provider.unreadCount, lessThan(8));
    });

    test('does nothing for an empty list', () async {
      api.install();
      // No route registered: markRead([]) must short-circuit before any HTTP
      // call, so this should not throw an "unmocked route" failure.
      await provider.markRead([]);
      expect(provider.notifications, isEmpty);
    });
  });

  group('deleteNotification', () {
    test('removes the notification and returns true', () async {
      mockFeed({
        'notifications': [notif(id: 'n-1', type: 'like'), notif(id: 'n-2', type: 'liked')],
        'next_offset': null,
      });
      api.install();
      await provider.loadNotifications();

      api.onDelete('/notifications/n-1');
      mockCounts();
      final ok = await provider.deleteNotification('n-1');

      expect(ok, isTrue);
      expect(provider.notifications.any((n) => n.id == 'n-1'), isFalse);
      expect(provider.notifications.any((n) => n.id == 'n-2'), isTrue);
    });
  });
}