import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/screens/profile/profile_screen.dart';
import 'package:dating_app/providers/profile_provider.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/models/photo.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/models/profile_stats.dart';
import '../../../helpers/test_helpers.dart';
import '../../../helpers/fixtures.dart';

class FakeProfileProvider extends ProfileProvider {
  final List<PhotoResponse> _photos;
  final ProfileStats? _stats;
  final bool _isLoading;

  // ignore: prefer_initializing_formals
  FakeProfileProvider({
    List<PhotoResponse> photos = const [],
    ProfileStats? stats,
    bool isLoading = false,
  }) : _photos = photos, // ignore: prefer_initializing_formals
       _stats = stats, // ignore: prefer_initializing_formals
       _isLoading = isLoading; // ignore: prefer_initializing_formals

  @override
  List<PhotoResponse> get photos => _photos;

  @override
  ProfileStats? get stats => _stats;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<void> loadPhotos() async {}

  @override
  Future<void> loadStats() async {}

  @override
  Future<void> refreshData() async {}
}

class FakeAuthProvider extends AuthProvider {
  final User? _user;

  // ignore: prefer_initializing_formals
  FakeAuthProvider({User? user}) : _user = user;

  @override
  User? get user => _user;
}

void main() {
  setUpAll(() async {
    await initTestEnvironment();
  });

  group('ProfileScreen', () {
    testWidgets('renders Profile title in AppBar', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ProfileScreen(),
          providers: [
            ChangeNotifierProvider<ProfileProvider>(
              create: (_) => FakeProfileProvider(),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(user: user()),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('shows settings gear icon', (tester) async {
      await tester.pumpWidget(
        buildTestable(
          const ProfileScreen(),
          providers: [
            ChangeNotifierProvider<ProfileProvider>(
              create: (_) => FakeProfileProvider(),
            ),
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => FakeAuthProvider(user: user()),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        ),
      );

      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });
  });
}
