import 'package:dating_app/models/swipe_user.dart';
import 'package:dating_app/models/message.dart';

class Match {
  final String id;
  final DateTime matchedAt;
  final SwipeUser user;
  final Message? lastMessage;
  final bool isActive;
  final String kind;
  final bool isAccepted;
  final int unreadCount;
  final DateTime? updatedAt;

  Match({
    required this.id,
    required this.matchedAt,
    required this.user,
    this.lastMessage,
    this.isActive = true,
    this.kind = 'match',
    this.isAccepted = true,
    this.unreadCount = 0,
    this.updatedAt,
  });

  factory Match.fromJson(Map<String, dynamic> json) {
    final kind = json['kind'] ?? 'match';
    return Match(
      id: json['id'] ?? '',
      matchedAt: DateTime.tryParse(json['matched_at'] ?? '') ?? DateTime.now(),
      user: SwipeUser.fromJson(json['user'] ?? {}),
      lastMessage: json['last_message'] != null
          ? Message.fromJson(json['last_message'])
          : null,
      isActive: json['is_active'] ?? true,
      kind: kind,
      isAccepted: json['is_accepted'] ?? (kind == 'match'),
      unreadCount: json['unread_count'] ?? 0,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matched_at': matchedAt.toIso8601String(),
      'user': user.toJson(),
      'last_message': lastMessage?.toJson(),
      'is_active': isActive,
      'kind': kind,
      'is_accepted': isAccepted,
      'unread_count': unreadCount,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
