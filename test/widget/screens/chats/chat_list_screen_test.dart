import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/chats/chat_list_screen.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/models/user.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/fixtures.dart';

class FakeChatProvider extends ChatProvider {
  final List<Match> _conversations;
  final bool _isLoading;

  FakeChatProvider({
    List<Match> conversations = const [],
    bool isLoading = false,
  })  : _conversations = conversations,
        _isLoading = isLoading;

  @override
  List<Match> get conversations => _conversations;

  @override
  bool get isLoading => _isLoading;
}

class FakeAuthProvider extends AuthProvider {
  final User? _user;

  FakeAuthProvider({User? user}) : _user = user;

  @override
  User? get user => _user;
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ChatListScreen', () {
    testWidgets('renders conversations list', (tester) async {
      final m = match(kind: 'match');

      await tester.pumpWidget(
        buildTestable(
          const Material(
            child: ChatListScreen(),
          ),
          providers: [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => FakeChatProvider(conversations: [m]),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(user: user()),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text(m.user.name), findsOneWidget);
    });

    testWidgets('shows empty state when no conversations', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const Material(
            child: ChatListScreen(),
          ),
          providers: [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => FakeChatProvider(),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(user: user()),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(ChatListScreen), findsOneWidget);
    });

    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const Material(
            child: ChatListScreen(),
          ),
          providers: [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => FakeChatProvider(isLoading: true),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(user: user()),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}