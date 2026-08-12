// Responsiveness ledger for the Phase 3/4 warm-orange redesign screens.
// Pumps every redesigned Mode B screen at the §7 sizes (360x640, 390x844,
// 430x932, 768x1024, 1024x768) and asserts no overflow/exception.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/models/notification.dart';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/models/chat_card.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/providers/auth_provider.dart';
import 'package:dating_app/providers/chat_provider.dart';
import 'package:dating_app/providers/language_provider.dart';
import 'package:dating_app/providers/notifications_provider.dart';
import 'package:dating_app/providers/onboarding_provider.dart';
import 'package:dating_app/providers/search_provider.dart';
import 'package:dating_app/providers/settings_provider.dart';
import 'package:dating_app/screens/profile/settings_screen.dart';
import 'package:dating_app/screens/chats/chats_screen.dart';
import 'package:dating_app/screens/chats/chat_list_screen.dart';
import 'package:dating_app/screens/chats/chat_detail_screen.dart';
import 'package:dating_app/screens/chats/liked_me_screen.dart';
import 'package:dating_app/screens/chats/i_liked_screen.dart';
import 'package:dating_app/screens/chats/notifications_screen.dart';
import 'package:dating_app/screens/chats/user_notification_profile_screen.dart';
import 'package:dating_app/screens/shared/profile_detail_loader.dart';
import 'package:dating_app/screens/search/search_filter_sheet.dart';
import 'package:dating_app/screens/onboarding/basic_info_screen.dart';
import 'package:dating_app/screens/onboarding/interests_screen.dart';
import 'package:dating_app/screens/onboarding/profile_details_screen.dart';
import 'package:dating_app/screens/onboarding/prompts_screen.dart';
import 'package:dating_app/screens/onboarding/photo_upload_screen.dart';
import 'package:dating_app/screens/profile/edit_basic_info_screen.dart';
import 'package:dating_app/screens/profile/edit_interests_screen.dart';
import 'package:dating_app/screens/profile/edit_photos_screen.dart';
import 'package:dating_app/screens/profile/edit_profile_details_screen.dart';
import 'package:dating_app/screens/profile/edit_prompts_screen.dart';
import 'package:dating_app/services/api_service.dart';
import '../helpers/test_helpers.dart';
import '../helpers/fixtures.dart' as fixtures;

/// The §7 ledger sizes (width x height).
const kSizes = <(double, double, String)>[
  (360, 640, '360x640'),
  (390, 844, '390x844'),
  (430, 932, '430x932'),
  (768, 1024, '768x1024'),
  (1024, 768, '1024x768'),
];

class _FakeAuthProvider extends AuthProvider {
  @override
  User? get user => fixtures.user();

  @override
  bool get isLoading => false;

  @override
  bool get isAuthenticated => true;
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
  List<Message> get messages => [
        Message.fromJson(fixtures.jsonMessage(id: 'm1', senderId: 'user-a')),
        Message.fromJson(
          fixtures.jsonMessage(
            id: 'm2',
            senderId: 'user-b',
            content: 'Hey there, how is your day going so far?',
          ),
        ),
        Message.fromJson(
          fixtures.jsonMessage(
            id: 'm3',
            senderId: 'user-b',
            messageType: 'photo',
            content: null,
            mediaUrl: 'https://example.com/p.jpg',
          ),
        ),
        Message.fromJson(
          fixtures.jsonMessage(
            id: 'm4',
            senderId: 'user-a',
            messageType: 'voice',
            content: null,
            mediaUrl: 'https://example.com/v.mp3',
            mediaDuration: 12,
          ),
        ),
      ];

  @override
  bool get isLoading => false;

  @override
  bool get isLoadingMore => false;

  @override
  bool get isTyping => true;

  @override
  bool get isOtherUserOnline => true;

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
  bool get canSendMessage => true;

  @override
  bool get isChatAccepted => true;

  @override
  bool get conversationIsOver => false;

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
  Future<void> subscribeChat(String chatId) async {}
}

class _FakeNotificationsProvider extends NotificationsProvider {
  @override
  List<AppNotification> get notifications => [
        AppNotification(
          id: 'n1',
          type: 'like',
          title: 'Sara liked you',
          body: 'You have a new match',
          createdAt: DateTime.now(),
        ),
        AppNotification(
          id: 'n2',
          type: 'message',
          title: 'New message from Mina',
          body: 'Hi, how are you?',
          isRead: true,
          createdAt: DateTime.now(),
        ),
      ];

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

List<SingleChildWidget> _commonProviders() => [
      ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ChangeNotifierProvider<AuthProvider>(create: (_) => _FakeAuthProvider()),
      ChangeNotifierProvider(create: (_) => OnboardingProvider()),
    ];

void main() {
  setUpAll(() async {
    await initTestEnvironment(secrets: {'user_id': 'user-a'});
    await ApiService.initForTest();
    // Load real Inter so text metrics match production (the Ahem test font
    // renders every glyph as a 1em square and overstates text width).
    final inter = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Medium.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-Bold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/Inter/Inter-ExtraBold.ttf'));
    await inter.load();
  });

  group('Mode B screens', () {
    for (final (width, height, label) in kSizes) {
      testWidgets('settings no overflow @$label', (tester) async {
        await _pumpAt(tester, width, height, const SettingsScreen(), _commonProviders());
      });

      testWidgets('chats no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const ChatsScreen(),
          _commonProviders() +
              [
                ChangeNotifierProvider<ChatProvider>(
                  create: (_) => _FakeChatProvider(),
                ),
              ],
        );
      });

      testWidgets('chat list no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          ChatListScreen(
            chats: [
              fixtures.chatCard(unreadCount: 3),
              fixtures.chatCard(
                id: 'chat-4',
                name: 'Lara',
                lastMessage: 'See you tomorrow',
              ),
            ],
            isLoading: false,
            hasMore: false,
            emptyText: 'No chats yet',
            onRefresh: () async {},
            onLoadMore: () async {},
            onChatTap: (_) {},
          ),
          _commonProviders(),
        );
      });

      testWidgets('chat detail no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const ChatDetailScreen(
            identifier: 'chat-1',
            userName: 'Bob',
            peerId: 'user-b',
          ),
          [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => _FakeChatProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('liked me no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const LikedMeScreen(),
          [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => _FakeChatProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('i liked no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const ILikedScreen(),
          [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => _FakeChatProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('notifications no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const NotificationsScreen(),
          [
            ChangeNotifierProvider<NotificationsProvider>(
              create: (_) => _FakeNotificationsProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('search filter sheet no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          // Scaffold provides the Material ancestor that showModalBottomSheet
          // normally supplies for the dropdown widgets.
          const Scaffold(body: SearchFilterSheet()),
          [
            ChangeNotifierProvider(create: (_) => SearchProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('user notification profile no overflow @$label',
          (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          UserNotificationProfileScreen(
            userId: 'user-1',
            fallback: const SwipeStubProfile(
              id: 'user-1',
              name: 'Sara',
              age: 26,
              mainPhotoUrl: 'https://example.com/1.jpg',
              distanceKm: 12.4,
            ),
          ),
          [
            ChangeNotifierProvider<ChatProvider>(
              create: (_) => _FakeChatProvider(),
            ),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
        );
      });

      testWidgets('profile detail loader no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          ProfileDetailLoader(
            userId: 'user-1',
            builder: (profile) => const SizedBox.shrink(),
          ),
          [ChangeNotifierProvider(create: (_) => SettingsProvider())],
        );
      });

      testWidgets('onboarding basic info no overflow @$label', (tester) async {
        await _pumpAt(tester, width, height, const BasicInfoScreen(), _commonProviders());
      });

      testWidgets('onboarding interests no overflow @$label', (tester) async {
        await _pumpAt(tester, width, height, const InterestsScreen(), _commonProviders());
      });

      testWidgets('onboarding profile details no overflow @$label',
          (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const ProfileDetailsScreen(),
          _commonProviders(),
        );
      });

      testWidgets('onboarding prompts no overflow @$label', (tester) async {
        await _pumpAt(tester, width, height, const PromptsScreen(), _commonProviders());
      });

      testWidgets('onboarding photo upload no overflow @$label',
          (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const PhotoUploadScreen(),
          _commonProviders(),
        );
      });

      testWidgets('edit basic info no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const EditBasicInfoScreen(),
          _commonProviders(),
        );
      });

      testWidgets('edit interests no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const EditInterestsScreen(),
          _commonProviders(),
        );
      });

      testWidgets('edit photos no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const EditPhotosScreen(),
          _commonProviders(),
        );
      });

      testWidgets('edit profile details no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const EditProfileDetailsScreen(),
          _commonProviders(),
        );
      });

      testWidgets('edit prompts no overflow @$label', (tester) async {
        await _pumpAt(
          tester,
          width,
          height,
          const EditPromptsScreen(),
          _commonProviders(),
        );
      });
    }
  });
}
