import 'dart:convert';
import 'package:dating_app/models/message.dart';
import 'package:dating_app/models/match.dart';
import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/models/discover_profile.dart';
import 'package:dating_app/models/user.dart';
import 'package:dating_app/models/photo.dart';
import 'package:dating_app/models/interest.dart';
import 'package:dating_app/models/prompt.dart';
import 'package:dating_app/models/chat_card.dart';

/// Canonical timestamps (fixed so formatter tests stay deterministic).
const kNowIso = '2026-08-05T12:00:00.000';
final DateTime kNow = DateTime.parse(kNowIso);

// ── JSON builders ───────────────────────────────────────────────────────────

Map<String, dynamic> jsonMessage({
  String id = 'msg-1',
  String? matchId = 'match-1',
  String senderId = 'user-a',
  String receiverId = 'user-b',
  String messageType = 'text',
  String? content = 'Hello',
  String? mediaUrl,
  int? mediaDuration,
  Map<String, dynamic>? replyTo,
  bool isSent = true,
  bool isDelivered = true,
  bool isRead = true,
  bool isAccepted = false,
  String sentAt = kNowIso,
  String? deliveredAt = kNowIso,
  String? readAt = kNowIso,
  bool isEdited = false,
  bool isDeleted = false,
}) {
  return {
    'id': id,
    'match_id': matchId,
    'sender_id': senderId,
    'receiver_id': receiverId,
    'message_type': messageType,
    'content': content,
    'media_url': mediaUrl,
    'media_duration': mediaDuration,
    'reply_to': replyTo,
    'is_sent': isSent,
    'is_delivered': isDelivered,
    'is_read': isRead,
    'is_accepted': isAccepted,
    'sent_at': sentAt,
    'delivered_at': deliveredAt,
    'read_at': readAt,
    'is_edited': isEdited,
    'is_deleted': isDeleted,
  };
}

Map<String, dynamic> jsonSwipeUser({
  String id = 'user-1',
  String name = 'Sara',
  int age = 26,
  String? mainPhotoUrl = 'https://example.com/1.jpg',
  bool isPremium = false,
  bool isVerified = true,
  String? swipedAt,
  bool? isOnline = true,
  String? lastSeenAt,
  double? distanceKm = 12.4,
}) {
  return {
    'id': id,
    'name': name,
    'age': age,
    'main_photo_url': mainPhotoUrl,
    'is_premium': isPremium,
    'is_verified': isVerified,
    'swiped_at': swipedAt,
    'is_online': isOnline,
    'last_seen_at': lastSeenAt,
    'distance_km': distanceKm,
  };
}

/// Matches the `/matches` endpoint shape.
Map<String, dynamic> jsonMatch({
  String id = 'match-1',
  String matchedAt = kNowIso,
  Map<String, dynamic>? user,
  Map<String, dynamic>? lastMessage,
  bool isActive = true,
  bool isAccepted = true,
  int unreadCount = 0,
}) {
  return {
    'id': id,
    'matched_at': matchedAt,
    'user': user ?? jsonSwipeUser(),
    'last_message': lastMessage,
    'is_active': isActive,
    'is_accepted': isAccepted,
    'unread_count': unreadCount,
  };
}

/// Matches the `/conversations` endpoint shape (kind + updated_at).
Map<String, dynamic> jsonConversation({
  String id = 'convo-1',
  String kind = 'match',
  bool isAccepted = true,
  int unreadCount = 0,
  String? updatedAt = kNowIso,
  Map<String, dynamic>? user,
  Map<String, dynamic>? lastMessage,
}) {
  return {
    'id': id,
    'kind': kind,
    'user': user ?? jsonSwipeUser(),
    'last_message': lastMessage,
    'is_accepted': isAccepted,
    'unread_count': unreadCount,
    'updated_at': updatedAt,
  };
}

Map<String, dynamic> jsonDiscoverProfile({
  String id = 'prof-1',
  String name = 'Sara',
  int age = 26,
  String gender = 'female',
  String? bio = 'Coffee and mountains',
  double? distanceKm = 12.4,
  String? mainPhotoUrl = 'https://example.com/1.jpg',
  List<String> photos = const ['https://example.com/1.jpg'],
  List<String> interests = const ['Hiking', 'Coffee'],
  List<Map<String, dynamic>> prompts = const [
    {'question': 'My simple pleasures', 'answer': 'Good coffee'},
  ],
  String? city = 'Tehran',
  String? province = 'Tehran',
  bool isOnline = true,
}) {
  return {
    'id': id,
    'name': name,
    'age': age,
    'gender': gender,
    'bio': bio,
    'distance_km': distanceKm,
    'main_photo_url': mainPhotoUrl,
    'photos': photos,
    'interests': interests,
    'prompts': prompts,
    'city': city,
    'province': province,
    'is_online': isOnline,
  };
}

Map<String, dynamic> jsonUser({
  String id = 'user-a',
  String email = 'a@example.com',
  String? name = 'Ali',
  int? age = 30,
  String createdAt = kNowIso,
  Map<String, dynamic>? settings,
}) {
  return {
    'id': id,
    'email': email,
    'name': name,
    'age': age,
    'created_at': createdAt,
    'settings': ?settings,
  };
}

// ── Typed instances ─────────────────────────────────────────────────────────

Message message({String? matchId, MessageType type = MessageType.text}) =>
    Message.fromJson(
      jsonMessage(
        matchId: matchId,
        messageType: type == MessageType.photo
            ? 'photo'
            : type == MessageType.voice
                ? 'voice'
                : 'text',
        content: type == MessageType.text ? 'Hello' : null,
        mediaUrl: type == MessageType.text ? null : 'https://example.com/m',
        mediaDuration: type == MessageType.voice ? 12 : null,
      ),
    );

SwipeUser swipeUser({double? distanceKm}) =>
    SwipeUser.fromJson(jsonSwipeUser(distanceKm: distanceKm));

Match match({String kind = 'match', int unreadCount = 0}) =>
    Match.fromJson(
      kind == 'match'
          ? jsonMatch(unreadCount: unreadCount)
          : jsonConversation(kind: 'unmatched', unreadCount: unreadCount),
    );

ChatCard chatCard({
  String id = 'chat-1',
  String status = 'accepted',
  String initiatorId = 'user-a',
  String? name,
  String? mainPhotoUrl,
  bool isOnline = false,
  String? lastMessage,
  int unreadCount = 0,
}) =>
    ChatCard.fromJson({
      'id': id,
      'status': status,
      'initiator_id': initiatorId,
      'user': {
        'id': 'user-b',
        'name': name ?? 'Bob',
        'age': 28,
        'main_photo_url': mainPhotoUrl,
        'is_online': isOnline,
        'last_seen_at': null,
      },
      'last_message': lastMessage == null
          ? null
          : {
              'content': lastMessage,
              'message_type': 'text',
              'is_sent': false,
              'is_read': false,
              'sent_at': kNowIso,
            },
      'unread_count': unreadCount,
      'updated_at': kNowIso,
    });

DiscoverProfile discoverProfile({double? distanceKm}) =>
    DiscoverProfile.fromJson(jsonDiscoverProfile(distanceKm: distanceKm));

User user() => User.fromJson(jsonUser());

Interest interest() => Interest.fromJson({'id': 'i1', 'name': 'Hiking', 'category': 'Outdoor'});

Prompt prompt() => Prompt.fromJson({'id': 'p1', 'question': 'My simple pleasures'});

PhotoResponse photoResponse() => PhotoResponse.fromJson({
  'id': 'ph1',
  'user_id': 'user-a',
  'url': 'https://example.com/1.jpg',
  'order': 1,
  'is_main': true,
  'status': 'approved',
  'face_verified': true,
});

/// Decodes a JSON string frame (used by the websocket tests).
Map<String, dynamic> decodeJson(String frame) =>
    jsonDecode(frame) as Map<String, dynamic>;
