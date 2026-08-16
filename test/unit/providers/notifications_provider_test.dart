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

  group('loadNotifications', () {
    test('populates notifications and resets pagination', () async {
      api.onGet('/notifications', body: {
        'notifications': [notif(id: 'n-1'), notif(id: 'n-2')],
        'next_offset': null,
      });
      api.install();

      await provider.loadNotifications();

      expect(provider.notifications, hasLength(2));
      expect(provider.notifications.first.id, 'n-1');
      expect(provider.hasMore, isFalse);
      expect(provider.isLoading, isFalse);
      api.expectCalled('/notifications');
    });

    test('sets hasMore when next_offset present', () async {
      api.onGet('/notifications', body: {
        'notifications': [notif()],
        'next_offset': '20',
      });
      api.install();

      await provider.loadNotifications();

      expect(provider.hasMore, isTrue);
    });

    test('counts unread notifications', () async {
      api.onGet('/notifications', body: {
        'notifications': [
          notif(id: 'n-1'),
          notif(id: 'n-2', isRead: true),
          notif(id: 'n-3'),
        ],
        'next_offset': null,
      });
      api.install();

      await provider.loadNotifications();

      expect(provider.unreadCount, 2);
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
    test('appends the next page', () async {
      api.onGet('/notifications', body: {
        'notifications': [notif(id: 'n-1')],
        'next_offset': '20',
      });
      api.install();

      await provider.loadNotifications();
      expect(provider.notifications, hasLength(1));

      api.onGet('/notifications', body: {
        'notifications': [notif(id: 'n-2')],
        'next_offset': null,
      });
      await provider.loadMoreNotifications();

      expect(provider.notifications, hasLength(2));
      expect(provider.notifications.last.id, 'n-2');
      expect(provider.hasMore, isFalse);
    });
  });

  group('markRead', () {
    test('marks matching notifications as read', () async {
      api.onGet('/notifications', body: {
        'notifications': [notif(id: 'n-1'), notif(id: 'n-2')],
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

      expect(provider.notifications.first.isRead, isTrue);
      expect(provider.notifications.last.isRead, isFalse);
      expect(provider.unreadCount, 1);
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
      api.onGet('/notifications', body: {
        'notifications': [notif(id: 'n-1'), notif(id: 'n-2')],
        'next_offset': null,
      });
      api.install();
      await provider.loadNotifications();

      api.onDelete('/notifications/n-1');
      mockCounts();
      final ok = await provider.deleteNotification('n-1');

      expect(ok, isTrue);
      expect(provider.notifications, hasLength(1));
      expect(provider.notifications.first.id, 'n-2');
    });
  });
}
