import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/screens/search/search_profile_detail.dart';
import 'package:dating_app/models/discover_profile.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/mock_api.dart';

DiscoverProfile _profile() => DiscoverProfile(
      id: 'user-b',
      name: 'Bob',
      age: 28,
      gender: 'female',
      bio: 'Hello there',
    );

void main() {
  setUpAll(() async {
    await initTestEnvironment(secrets: {'user_id': 'user-a'});
  });

  late ChatProvider provider;
  late MockApi api;

  setUp(() {
    provider = ChatProvider();
    api = MockApi();
  });

  tearDown(() {
    provider.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester, {bool viewOnly = false}) async {
    api.install();
    await tester.pumpWidget(
      buildTestable(
        SearchProfileDetail(
          profile: _profile(),
          interestIcons: const {},
          viewOnly: viewOnly,
        ),
        providers: [
          ChangeNotifierProvider<ChatProvider>.value(value: provider),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }

  group('SearchProfileDetail report/block menu', () {
    testWidgets('view-only menu shows Report and Block options',
        (tester) async {
      await pumpScreen(tester, viewOnly: true);

      await tester.tap(find.byIcon(Icons.flag).first);
      await tester.pumpAndSettle();

      expect(find.text('Report Profile'), findsOneWidget);
      expect(find.text('Block User'), findsOneWidget);
    });

    testWidgets('non view-only hides the Block option', (tester) async {
      await pumpScreen(tester, viewOnly: false);

      await tester.tap(find.byIcon(Icons.flag).first);
      await tester.pumpAndSettle();

      expect(find.text('Report Profile'), findsOneWidget);
      expect(find.text('Block User'), findsNothing);
    });

    testWidgets('reporting a profile posts the reason and shows success',
        (tester) async {
      api.onPost('/reports/user-b',
          statusCode: 201,
          body: {'detail': 'ok'},
          data: {'reason': 'Spam account'});
      await pumpScreen(tester);

      await tester.tap(find.byIcon(Icons.flag).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Report Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Spam account');
      await tester.tap(find.text('Send'));
      await tester.pumpAndSettle();

      expect(find.text('Reported'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('blocking a profile confirms and reports done', (tester) async {
      api.onPost('/blocks/user-b/block', statusCode: 204, body: {'detail': 'ok'});
      await pumpScreen(tester, viewOnly: true);

      await tester.tap(find.byIcon(Icons.flag).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Block User'));
      await tester.pumpAndSettle();

      expect(find.text('Block User'), findsOneWidget);
      await tester.tap(find.text('Block'));
      await tester.pumpAndSettle();

      expect(find.text('Blocked'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}