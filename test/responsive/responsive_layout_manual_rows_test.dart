// Responsiveness ledger for the four §7 "manual-only" rows: splash, verify_code,
// avatar_crop and main_screen. Automates the 5-size overflow check so the rows
// can be marked [x]:
//   - splash:  async progress animation + navigation to LoginScreen
//   - verify_code: resend countdown timer (disposed on teardown)
//   - avatar_crop: load a real image via a fake dart:io HttpClient + mocked
//     path_provider channel so the crop Stack layout is exercised (no native
//     ImageCropper in the current implementation)
//   - main_screen: profile-complete user so the bottom nav + 4-tab IndexedStack
//     stay on screen (no redirect to onboarding)
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/providers/onboarding_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/screens/auth/verify_code_screen.dart';
import 'package:dating_app/screens/main_screen.dart';
import 'package:dating_app/screens/profile/avatar_crop_screen.dart';
import 'package:dating_app/screens/splash_screen.dart';
import 'package:dating_app/services/api_service.dart';

import '../helpers/fixtures.dart' as fixtures;
import '../helpers/mock_api.dart';
import '../helpers/test_helpers.dart';

/// The §7 ledger sizes (width x height).
const _kSizes = <(double, double, String)>[
  (360, 640, '360x640'),
  (390, 844, '390x844'),
  (430, 932, '430x932'),
  (768, 1024, '768x1024'),
  (1024, 768, '1024x768'),
];

// A valid 1x1 JPEG so `Image.file` decodes instead of reporting a resource
// error (which flutter_test surfaces as a test failure).
const _jpegBase64 =
    '/9j/4AAQSkZJRgABAQEAYABgAAD/2wBDAAgGBgcGBQgHBwcJCQgKDBQNDAsLDBkSEw8UHRof'
    'Hh0aHBwgJC4nICIsIxwcKDcpLDAxNDQ0Hyc5PTgyPC4zNDL/wAALCAABAAEBAREA/8QAFAAB'
    'AAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==';

class _SplashAuthProvider extends AuthProvider {
  @override
  User? get user => null;

  @override
  bool get isAuthenticated => false;

  @override
  bool get isServerHealthy => true;

  @override
  Future<bool> initializeApp() async => false;
}

class _MainAuthProvider extends AuthProvider {
  @override
  User? get user => User.fromJson({
        ...fixtures.jsonUser(),
        'is_profile_complete': true,
      });

  @override
  bool get isAuthenticated => true;

  @override
  bool get isServerHealthy => true;

  @override
  Future<bool> initializeApp() async => true;
}

class _FakeOnboardingProvider extends ChangeNotifier {
  String get email => '';
  String get password => '';
}

class _FakeChatProvider extends ChatProvider {
  @override
  List<ChatCard> get conversations => [
        fixtures.chatCard(unreadCount: 3),
        fixtures.chatCard(
          id: 'chat-4',
          name: 'Lara',
          lastMessage: 'See you tomorrow',
          unreadCount: 1,
        ),
      ];

  @override
  List<ChatCard> get pendingChats => [
        fixtures.chatCard(id: 'chat-2', status: 'pending', name: 'Sara'),
      ];

  @override
  List<ChatCard> get incomingChats => [
        fixtures.chatCard(id: 'chat-3', status: 'pending', name: 'Mina'),
      ];

  @override
  List<SwipeUser> get likedUsers => [
        fixtures.swipeUser(),
        fixtures.swipeUser(distanceKm: 3.1),
      ];

  @override
  List<SwipeUser> get likers => [
        fixtures.swipeUser(),
        fixtures.swipeUser(distanceKm: 3.1),
      ];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMoreConversations => false;

  @override
  bool get hasMorePending => false;

  @override
  bool get hasMoreIncoming => false;

  @override
  bool get hasMoreLikers => false;

  @override
  bool get hasMoreLiked => false;

  @override
  Future<void> loadConversations() async {}

  @override
  Future<void> loadMoreConversations() async {}

  @override
  Future<void> loadPendingIncoming() async {}

  @override
  Future<void> loadLikers() async {}

  @override
  Future<void> loadMoreLikers() async {}

  @override
  Future<void> loadLikedUsers() async {}

  @override
  Future<void> loadMoreLikedUsers() async {}

  @override
  Future<void> loadMessages(
    String identifier, {
    String? initialStatus,
    String? initialInitiatorId,
  }) async {}

  @override
  Future<void> loadMoreMessages() async {}

  @override
  Future<void> refreshLimits() async {}

  @override
  Future<void> connectSessionSocket() async {}
}

class _FakeNotificationsProvider extends NotificationsProvider {
  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get hasMore => false;

  @override
  Future<void> loadNotifications() async {}

  @override
  Future<void> loadMoreNotifications() async {}
}

Future<void> _pumpAt(
  WidgetTester tester,
  double width,
  double height,
  Widget child,
  List<SingleChildWidget> providers,
) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(buildTestable(child, providers: providers));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pump(const Duration(seconds: 2));

  final exception = tester.takeException();
  expect(exception, isNull,
      reason: 'overflow/exception at ${width.toInt()}x${height.toInt()}');
}

Future<void> _pumpCropAt(
  WidgetTester tester,
  double width,
  double height,
) async {
  tester.view.physicalSize = Size(width * 3, height * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.runAsync(() async {
    await tester.pumpWidget(
      buildTestable(
        AvatarCropScreen(
          photo: fixtures.photoResponse(),
          onCropSaved: (_) {},
        ),
        providers: [ChangeNotifierProvider(create: (_) => SettingsProvider())],
      ),
    );
    // Let the real (runAsync) http + file IO complete before inspecting the
    // crop layout.
    await Future<void>.delayed(const Duration(milliseconds: 150));
  });

  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));

  final exception = tester.takeException();
  expect(exception, isNull,
      reason: 'overflow/exception at ${width.toInt()}x${height.toInt()}');
}

/// Fake dart:io HTTP stack used to make `package:http` `http.get()` return a
/// 200 with real JPEG bytes in the avatar_crop test (flutter_test's default
/// HttpOverrides returns 400 for everything).
class _FakeHttpOverrides extends HttpOverrides {
  final List<int> body;
  _FakeHttpOverrides(this.body);

  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      _FakeHttpClient(body);
}

class _FakeHttpClient implements HttpClient {
  final List<int> body;
  _FakeHttpClient(this.body);

  bool _autoUncompress = true;

  @override
  bool get autoUncompress => _autoUncompress;

  @override
  set autoUncompress(bool value) => _autoUncompress = value;

  @override
  Future<HttpClientRequest> openUrl(String method, Uri url) async =>
      _FakeHttpRequest(body);

  @override
  Future<HttpClientRequest> getUrl(Uri url) async => _FakeHttpRequest(body);

  @override
  void close({bool force = false}) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpRequest implements HttpClientRequest {
  final List<int> body;
  _FakeHttpRequest(this.body);

  @override
  final HttpHeaders headers = _FakeHttpHeaders();

  @override
  bool followRedirects = false;

  @override
  bool persistentConnection = false;

  @override
  Future<HttpClientResponse> close() async => _FakeHttpResponse(body);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Minimal mutable [HttpHeaders] covering what `package:http` touches
/// (`addAll`, `map`, `forEach`); everything else falls through to
/// `noSuchMethod` (throwing loudly if it is actually used).
class _FakeHttpHeaders implements HttpHeaders {
  final Map<String, List<String>> _values = <String, List<String>>{};

  @override
  void add(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = ['$value'];
  }

  void addAll(Map<String, String> headers) {
    headers.forEach((name, value) => add(name, value));
  }

  @override
  void set(String name, Object value, {bool preserveHeaderCase = false}) {
    _values[name] = ['$value'];
  }

  void setAll(String name, List<String> values) {
    _values[name] = List.of(values);
  }

  @override
  void remove(String name, Object? value) {
    if (value == null) {
      _values.remove(name);
    } else {
      _values[name]?.remove('$value');
    }
  }

  @override
  void clear() => _values.clear();

  @override
  void forEach(void Function(String name, List<String> values) action) {
    _values.forEach(action);
  }

  Map<String, List<String>> get map => _values;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHttpResponse implements HttpClientResponse {
  _FakeHttpResponse(List<int> bytes)
      : bytes = bytes,
        _inner = Stream<List<int>>.value(bytes) {
    contentLength = bytes.length;
  }

  final List<int> bytes;
  final Stream<List<int>> _inner;

  @override
  int statusCode = 200;

  @override
  HttpHeaders headers = _FakeHttpHeaders();

  @override
  int contentLength = -1;

  @override
  HttpClientResponseCompressionState compressionState =
      HttpClientResponseCompressionState.notCompressed;

  @override
  String reasonPhrase = 'OK';

  @override
  bool isRedirect = false;

  @override
  List<RedirectInfo> redirects = const [];

  @override
  bool persistentConnection = false;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _inner.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  @override
  bool get isBroadcast => _inner.isBroadcast;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final jpegBytes = base64Decode(_jpegBase64.replaceAll(RegExp(r'\s'), ''));
  final savedHttpOverrides = HttpOverrides.current;

  setUpAll(() async {
    await initTestEnvironment(secrets: {'user_id': 'user-a'});
    await ApiService.initForTest();
    // Real Inter so text metrics match production (Ahem overstates width).
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-ExtraBold.ttf'));
    await inter.load();
  });

  setUp(() {
    // Mock path_provider so avatar_crop can write its temp file and
    // flutter_cache_manager (used by CachedImage on main_screen) can open its
    // cache database.
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    final tmp = Directory.systemTemp.path;
    messenger.setMockMethodCallHandler(pathChannel, (call) async {
      switch (call.method) {
        case 'getTemporaryDirectory':
          return tmp;
        case 'getApplicationSupportDirectory':
          return '$tmp/support';
        case 'getApplicationCacheDirectory':
          return '$tmp/cache';
        case 'getApplicationDocumentsDirectory':
          return '$tmp/documents';
        case 'getLibraryDirectory':
          return '$tmp/library';
        case 'getDownloadsDirectory':
          return '$tmp/downloads';
        case 'getExternalStorageDirectory':
          return '$tmp/external';
        case 'getExternalCacheDirectories':
          return ['$tmp/external_cache'];
        case 'getExternalStorageDirectories':
          return ['$tmp/external_docs'];
      }
      return null;
    });
  });

  tearDown(() {
    HttpOverrides.global = savedHttpOverrides;
  });

  group('§7 manual rows', () {
    for (final (width, height, label) in _kSizes) {
      testWidgets('splash no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const SplashScreen(),
          [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => _SplashAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        );
      });

      testWidgets('verify_code no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const VerifyCodeScreen(
            email: 'test@example.com',
            password: 'password123',
          ),
          [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => _FakeOnboardingProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
        );
      });

      testWidgets('avatar_crop no overflow @$label', (tester) async {
        HttpOverrides.global = _FakeHttpOverrides(jpegBytes);
        await _pumpCropAt(tester, width, height);
      });

      testWidgets('main_screen no overflow @$label', (tester) async {
        MockApi()
          ..onGet('/discover', body: {'profiles': []})
          ..onGet('/search', body: {'profiles': []})
          ..onGet('/rewards/my-limits', body: {'remaining_likes': 5})
          ..onGet('/interests', body: [])
          ..onGet('/users/me/photos', body: [
            fixtures.photoResponse().toJson(),
            fixtures.photoResponse().toJson(),
            fixtures.photoResponse().toJson(),
          ])
          ..install();

        await _pumpAt(
          tester,
          width,
          height,
          const MainScreen(),
          [
            ChangeNotifierProvider<AuthProvider>(
              create: (_) => _MainAuthProvider(),
            ),
            ChangeNotifierProvider(create: (_) => OnboardingProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => _FakeChatProvider(),
            ),
            ChangeNotifierProvider<NotificationsProvider>(
              create: (_) => _FakeNotificationsProvider(),
            ),
          ],
        );
      });
    }
  });
}