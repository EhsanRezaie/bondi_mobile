import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/discover/discover_screen.dart';
import 'package:dating_app/providers/discover_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/models/discover_profile.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/fixtures.dart';

class FakeDiscoverProvider extends DiscoverProvider {
  final List<DiscoverProfile> _profiles;
  final bool _isLoading;
  final String? _errorMessage;

  FakeDiscoverProvider({
    List<DiscoverProfile> profiles = const [],
    bool isLoading = false,
    String? errorMessage,
  })  : _profiles = profiles,
        _isLoading = isLoading,
        _errorMessage = errorMessage;

  @override
  List<DiscoverProfile> get profiles => _profiles;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get errorMessage => _errorMessage;

  @override
  Future<void> loadProfiles() async {}
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('DiscoverScreen', () {
    testWidgets('renders profile card from feed', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const DiscoverScreen(),
          providers: [
            ChangeNotifierProvider<DiscoverProvider>(
              create: (_) => FakeDiscoverProvider(profiles: [discoverProfile()]),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byIcon(Icons.wc), findsOneWidget);
    });

    testWidgets('shows empty state when feed is empty', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const DiscoverScreen(),
          providers: [
            ChangeNotifierProvider<DiscoverProvider>(
              create: (_) => FakeDiscoverProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('shows error banner when feed fails', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const DiscoverScreen(),
          providers: [
            ChangeNotifierProvider<DiscoverProvider>(
              create: (_) => FakeDiscoverProvider(errorMessage: 'Failed to load profiles'),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.text('Failed to load profiles'), findsOneWidget);
    });

    testWidgets('shows loading indicator while feed is fetching', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const DiscoverScreen(),
          providers: [
            ChangeNotifierProvider<DiscoverProvider>(
              create: (_) => FakeDiscoverProvider(isLoading: true),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}