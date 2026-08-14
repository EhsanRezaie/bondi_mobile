import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/chats/notifications_screen.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/mock_api.dart';

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  Map<String, dynamic> notif({
    required String id,
    required String type,
    required String title,
    bool isRead = false,
  }) {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': 'body',
      'created_at': '2024-01-01T00:00:00Z',
      'is_read': isRead,
    };
  }

  Future<NotificationsProvider> pumpScreen(
    WidgetTester tester, {
    required List<Map<String, dynamic>> notifications,
  }) async {
    MockApi()
      ..onGet('/notifications', body: {
        'notifications': notifications,
        'next_offset': null,
      })
      ..install();
    final provider = NotificationsProvider();
    await tester.pumpWidget(
      buildTestable(
        const NotificationsScreen(),
        providers: [
          ChangeNotifierProvider.value(value: provider),
        ],
      ),
    );
    await tester.pumpAndSettle();
    return provider;
  }

  testWidgets('renders 4 segmented tabs', (tester) async {
    await pumpScreen(tester, notifications: [
      notif(id: 'n-1', type: 'like', title: 'A liked you'),
    ]);

    expect(find.text('Liked'), findsOneWidget);
    expect(find.text('Likes'), findsOneWidget);
    expect(find.text('Matches'), findsOneWidget);
    expect(find.text('Announcements'), findsOneWidget);
  });

  testWidgets('switching tabs filters the list by type', (tester) async {
    await pumpScreen(tester, notifications: [
      notif(id: 'n-1', type: 'like', title: 'A liked you'),
      notif(id: 'n-2', type: 'liked', title: 'You liked B'),
      notif(id: 'n-3', type: 'match', title: 'You matched with C'),
      notif(id: 'n-4', type: 'system', title: 'Announcement'),
    ]);

    expect(find.text('A liked you'), findsOneWidget);
    expect(find.text('You liked B'), findsNothing);

    await tester.tap(find.text('Likes'));
    await tester.pumpAndSettle();
    expect(find.text('You liked B'), findsOneWidget);
    expect(find.text('A liked you'), findsNothing);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.text('You matched with C'), findsOneWidget);
  });

  testWidgets('shows empty section message when a tab has no items',
      (tester) async {
    await pumpScreen(tester, notifications: [
      notif(id: 'n-1', type: 'like', title: 'A liked you'),
    ]);

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    expect(find.text('Nothing here yet'), findsOneWidget);
  });

  testWidgets('shows unread badge on the first tab', (tester) async {
    await pumpScreen(tester, notifications: [
      notif(id: 'n-1', type: 'like', title: 'A liked you'),
      notif(id: 'n-2', type: 'liked', title: 'You liked B'),
    ]);

    expect(find.text('1'), findsNWidgets(2));
  });
}
