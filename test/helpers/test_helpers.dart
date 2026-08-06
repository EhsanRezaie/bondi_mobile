import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dating_app/config/app_theme.dart';
import 'package:dating_app/generated/app_localizations.dart';

/// Sets up shared_preferences + flut_secure_storage for the widget under test.
///
/// Call in `setUpAll`. Pre-populates secure storage with any `secrets`
/// (e.g. `{'user_id': 'user-a'}`) that `StorageService` reads during the test.
Future<void> initTestEnvironment({
  Map<String, String> secrets = const {},
  Map<String, Object> prefs = const {},
}) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues(prefs);

  // `AppConstants.*` reads `dotenv.env`, which throws until dotenv is loaded.
  dotenv.testLoad(
    mergeWith: {
      'API_BASE_URL': 'http://localhost:8000/api/v1',
      'WS_BASE_URL': 'ws://localhost:8000/api/v1',
      'GOOGLE_CLIENT_ID': 'test-client.apps.googleusercontent.com',
      'ADMIN_SECRET_KEY': 'test-key',
    },
  );

  final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  // Mock the flutter_secure_storage method channel so StorageService() works
  // without the native plugin.
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  messenger.setMockMethodCallHandler(channel, (call) async {
    // flutter_secure_storage passes method args as a Map for most calls
    // (e.g. read/write/delete), and no args for readAll/deleteAll.
    final args = call.arguments;
    String? key;
    if (args is String) {
      key = args;
    } else if (args is Map) {
      key = args['key'] as String?;
    }
    if (call.method == 'read') return key != null ? secrets[key] : null;
    if (call.method == 'readAll') return secrets;
    if (call.method == 'delete') {
      if (key != null) (secrets as Map).remove(key);
      return null;
    }
    if (call.method == 'write') {
      if (key != null && args is Map) {
        (secrets as Map)[key] = args['value'];
      }
      return null;
    }
    if (call.method == 'deleteAll') {
      (secrets as Map).clear();
      return null;
    }
    if (call.method == 'containsKey') {
      return key != null && secrets.containsKey(key);
    }
    return null;
  });
}

/// Wraps [child] in a MaterialApp + MultiProvider so widget tests can pump a
/// screen that reads `AppLocalizations.of(context)`, `context.isDarkMode` and
/// any providers passed via [providers].
Widget buildTestable(
  Widget child, {
  List<SingleChildWidget> providers = const [],
  String locale = 'en',
}) {
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    darkTheme: AppTheme.darkTheme,
    themeMode: ThemeMode.light,
    locale: Locale(locale),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );

  if (providers.isEmpty) return app;

  return MultiProvider(
    providers: providers,
    child: app,
  );
}

/// Pump [child] using the shared test harness.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  List<SingleChildWidget> providers = const [],
}) async {
  await tester.pumpWidget(buildTestable(child, providers: providers));
  await tester.pumpAndSettle();
}